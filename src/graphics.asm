; Screen drawing, sprites, backgrounds, animation display


; ---- function clear_screen ----
; Fills the whole offscreen buffer (DS:0x337) with zeros, i.e. pixel value 0.
; No parameters. Preserves ES (sets ES=DS while filling). Clobbers AX, CX, DI.
;
; Offscreen buffer layout (used by everything in this file): 200 scanlines of
; 80 bytes, top to bottom with NO interlacing, at DS:0x337..0x41B6. That is
; 0x3E80 = 16000 bytes (0x1F40 words). Each byte is 4 pixels at 2 bits/pixel,
; bits 7-6 being the leftmost pixel. Scanline N starts at 0x337 + N*80.
; The CGA interlace is only applied when copying to VRAM, via the LUT at
; DS:0xDF59 (see update_display).
clear_screen:
	push	es			; 00B4E
	push	ds			; 00B4F
	pop	es			; 00B50
	lea	di,[offscreen_buffer]		; 00B51
	db	0x33, 0xC0		; 00B55 xor ax,ax
	mov	cx,0x1f40		; 00B57
	rep	stosw			; 00B5A
	pop	es			; 00B5C
	ret				; 00B5D

; ---- function next_sprite_bytes ----
; Returns the next decoded byte of a sprite from each of its two parallel
; RLE-compressed streams (image and mask). Called once per sprite byte by
; draw_sprite_flipped / draw_sprite_unflipped / draw_sprite_unflipped_columns, which set up the
; read positions and zero both repeat counters for each sprite.
; No parameters. No stack frame. Clobbers SI.
;
; Uses globals:
;   [0x421e] = read position in stream 1 (image, relative to DS:0x443C)
;   [0x4220] = read position in stream 2 (mask, relative to DS:0x893A)
;   [0x422c] = repeats still owed for stream 1 (byte)
;   [0x422d] = value being repeated for stream 1 (byte)
;   [0x422e] = repeats still owed for stream 2 (byte)
;   [0x422f] = value being repeated for stream 2 (byte)
;
; RLE encoding (identical for both streams):
;   0x7B, value, count  = run of (count + 1) copies of value
;   any other byte      = one literal byte
; On a run, the value is returned immediately and count is stored as the
; number of further calls that return it without consuming stream bytes.
; 0x7B has no escape, so a 0x7B data byte has to be stored as a run.
;
; Returns:
;   DL = next byte from stream 1 (image: pixels from the ks*.dat file)
;   AL = next byte from stream 2 (mask from the km*.dat file; the renderers
;        skip the byte when it is 0 and clear the destination bits set in it)
next_sprite_bytes:
	cmp	byte [sprite_image_run_left],0x0	; 00B5E
	jz	short next_sprite_bytes_stream1_fetch		; 00B63 jz 0xb70
	mov	dl,[sprite_image_run_value]		; 00B65
	dec	byte [sprite_image_run_left]		; 00B69
	jmp	short next_sprite_bytes_stream2		; 00B6D jmp 0xb95
	nop				; 00B6F
next_sprite_bytes_stream1_fetch:
; -- stream 1: no run pending, fetch next byte (0x7B starts a run) --
	mov	si,[sprite_image_pos]		; 00B70
	mov	dl,[si+sprite_image_bank]		; 00B74
	inc	si			; 00B78
	cmp	dl,0x7b			; 00B79
	jnz	short next_sprite_bytes_stream1_store_pos		; 00B7C jnz 0xb91
	mov	dl,[si+sprite_image_bank_byte1]		; 00B7E
	mov	[sprite_image_run_left],dl		; 00B82
	mov	dl,[si+sprite_image_bank]		; 00B86
	mov	[sprite_image_run_value],dl		; 00B8A
	add	si,0x2			; 00B8E
next_sprite_bytes_stream1_store_pos:
	mov	[sprite_image_pos],si		; 00B91
next_sprite_bytes_stream2:
; -- stream 2: same decoding as stream 1 --
	cmp	byte [sprite_mask_run_left],0x0	; 00B95
	jz	short next_sprite_bytes_stream2_fetch		; 00B9A jz 0xba6
	mov	al,[sprite_mask_run_value]		; 00B9C
	dec	byte [sprite_mask_run_left]		; 00B9F
	jmp	short next_sprite_bytes_return		; 00BA3 jmp 0xbc8
	nop				; 00BA5
next_sprite_bytes_stream2_fetch:
; -- stream 2: no run pending, fetch next byte (0x7B starts a run) --
	mov	si,[sprite_mask_pos]		; 00BA6
	mov	al,[si+sprite_mask_bank]		; 00BAA
	inc	si			; 00BAE
	cmp	al,0x7b			; 00BAF
	jnz	short next_sprite_bytes_stream2_store_pos		; 00BB1 jnz 0xbc4
	mov	al,[si+sprite_mask_bank_byte1]		; 00BB3
	mov	[sprite_mask_run_left],al		; 00BB7
	mov	al,[si+sprite_mask_bank]		; 00BBA
	mov	[sprite_mask_run_value],al		; 00BBE
	add	si,0x2			; 00BC1
next_sprite_bytes_stream2_store_pos:
	mov	[sprite_mask_pos],si		; 00BC4
next_sprite_bytes_return:
	ret				; 00BC8

; ---- function render_figures ----
; Renders one complete frame: rebuilds the offscreen background, draws every
; figure in the figure list on top, copies the result to VRAM, then calls the
; sound dispatcher. Called from the gameplay loop and the anim_cmd_do_scr
; script opcode. No parameters. No stack frame.
;
; Frame record at DS:0xBB30:
;   [0xbb30] byte = sound id, passed to play_sound (0 = no-op there).
;                   Set by the set_tune script opcode and scene_update.
;   [0xbb31] byte = wipe flag (set_wipe = 1, set_nowipe = 0). Nonzero presents
;                   the frame with blit_buffer_to_vram.
;   [0xbb32] byte = set by the set_bg script opcode. Passed in AL to
;                   prepare_screen_buffer, which never reads it.
;   [0xbb33...]   = figure list, 4-byte slots, ended by a 0xFF sprite id:
;       +0      sprite id (0xFF = end of list)
;       +1..+2  X position word; see flag bit 14 below
;       +3      Y position byte
;
; Uses globals:
;   [0xbb2e] = offset into the record at 0xBB30 (starts at 3, the first slot).
;              Left at the 0xFF terminator, which is also where the set_fig
;              script opcode appends the next slot.
;   [0xee]   = anim_render_mode; 0 = partial copy via update_display_partial,
;              nonzero = full copy via update_display
;
; Sprite routing: if the X word has bit 15 clear and bit 14 set, bit 14 is
; removed and the slot goes to draw_sprite_flipped; every other slot goes to
; draw_sprite_unflipped with X unchanged. Bit 15 set is a negative X, so bit 14
; is only a flag for non-negative X. scene.asm sets bit 14 as its flip bit, and
; draw_sprite_flipped is the path that bit-reverses the sprite data, so draw_sprite_flipped
; is likely the horizontally flipped renderer despite the function names.
render_figures:
	mov	word [figure_list_cursor],0x3	; 00BC9
	mov	al,[anim_fig_bg]		; 00BCF
	call	prepare_screen_buffer	; 00BD2
render_figures_next_slot:
; -- walk the figure list until the 0xFF sprite id --
	mov	si,[figure_list_cursor]		; 00BD5
	mov	al,[si+frame_sound_id]		; 00BD9
	cmp	al,0xff			; 00BDD
	jz	short render_figures_present_frame		; 00BDF jz 0xc14
; slot fields: AX = sprite id, DX = X word, CX = Y
	mov	ah,0x0			; 00BE1
	mov	cl,[si+figure_list]		; 00BE3
	mov	ch,0x0			; 00BE7
	push	cx			; 00BE9
	mov	dx,[si+screen_wipe_flag]		; 00BEA
; -- bit 15 clear and bit 14 set: flagged slot goes to draw_sprite_flipped --
	test	dx,0x8000		; 00BEE
	jnz	short render_figures_draw_default		; 00BF2 jnz 0xc05
	test	dx,0x4000		; 00BF4
	jz	short render_figures_draw_default		; 00BF8 jz 0xc05
	xor	dx,0x4000		; 00BFA
	push	dx			; 00BFE
	push	ax			; 00BFF
	call	draw_sprite_flipped		; 00C00
	jmp	short render_figures_slot_done		; 00C03 jmp 0xc0a
; Reached when X has bit 15 set or bit 14 clear
render_figures_draw_default:
; -- default path: X word passed unchanged --
	push	dx			; 00C05
	push	ax			; 00C06
	call	draw_sprite_unflipped	; 00C07
render_figures_slot_done:
	add	sp,0x6			; 00C0A
	add	word [figure_list_cursor],0x4	; 00C0D
	jmp	short render_figures_next_slot		; 00C12 jmp 0xbd5
render_figures_present_frame:
; -- list done: present the frame, then call the sound dispatcher --
	cmp	byte [screen_wipe_flag],0x0	; 00C14
	jnz	short render_figures_wipe_reveal		; 00C19 jnz 0xc42
	cmp	word [anim_render_mode],0x0		; 00C1B
	jz	short render_figures_partial_copy		; 00C20 jz 0xc32
; -- [0xee] nonzero: full copy --
	call	update_display		; 00C22
	mov	al,[frame_sound_id]		; 00C25
	mov	ah,0x0			; 00C28
	push	ax			; 00C2A
	call	play_sound		; 00C2B
	add	sp,0x2			; 00C2E
	ret				; 00C31
render_figures_partial_copy:
; -- [0xee] == 0: partial copy --
	call	update_display_partial		; 00C32
	mov	al,[frame_sound_id]		; 00C35
	mov	ah,0x0			; 00C38
	push	ax			; 00C3A
	call	play_sound		; 00C3B
	add	sp,0x2			; 00C3E
	ret				; 00C41
render_figures_wipe_reveal:
; -- wipe flag set: reveal with the column wipe --
	call	blit_buffer_to_vram	; 00C42
	mov	al,[frame_sound_id]		; 00C45
	mov	ah,0x0			; 00C48
	push	ax			; 00C4A
	call	play_sound		; 00C4B
	add	sp,0x2			; 00C4E
	ret				; 00C51

; ---- function prepare_screen_buffer ----
; Redraws the background layers of the offscreen buffer for the current frame,
; ready for render_figures to draw sprites over them. Nothing here touches
; VRAM. Sets ES=DS for the string instructions and restores ES on exit.
;
; Parameters:
;   AL = [0xbb32] from render_figures; not actually used (overwritten below)
;
; Uses globals:
;   [0xee]   = anim_render_mode; the top-of-screen step only runs when it is 1
;   [0xea]   = current_level; picks one of three layouts: <2, ==2, >=3
;   [0xe4]   = camera_x
;   [0xbb2a] = camera_x at the last update_display_partial (0xFFFF forces a redraw).
;              The mid-screen scenery is only rebuilt when camera_x differs,
;              matching the smaller region update_display_partial copies otherwise.
;   [0xbcd0] = script_running; draw_health_bars is skipped while it is set
;
; Screen regions written (scanline numbers; pixel value = 2-bit colour index):
;   Top step, only when [0xee] == 1:
;     level < 2 : lines 0-79 filled with pixel value 1 (0x5555)
;     level >= 2: entire buffer cleared; draw_health_bars if no script running
;   Level < 2:
;     if camera moved: lines 32-127 filled with value 1, 34 lines of fuji.bcg
;       (DS:0xACB2) copied to lines 80-113, then line 106 set to value 3 and
;       lines 107-109 cleared
;     always: clear_above_ground clears lines 114-155, then lines 154-183 become
;       a dither of 2-line pairs, 0x9999/0x6666. Bit 0 of camera_x swaps the
;       pair (0x6666/0x9999), likely so the ground appears to move on scroll.
;   Level == 2:
;     always: clear_above_ground clears lines 108-155
;     if camera moved: lines 32-127 cleared, 22 lines of fuji.bcg copied to
;       lines 80-101, then lines 90-91 cleared
;     always: lines 154-183 = 15 pairs of a value-2 line and a cleared line
;   Level >= 3:
;     always: clear_above_ground clears lines 108-155
;     if camera moved: lines 0-113 cleared
;     always: lines 154-183 = 15 pairs of a value-1 line and a cleared line
;   Lines 184-199 are never written here except by the clear_screen above
;   (likely the status/health bar area).
prepare_screen_buffer:
	push	es			; 00C52
	push	ds			; 00C53
	pop	es			; 00C54
; -- top step, only when anim_render_mode == 1 --
	cmp	word [anim_render_mode],0x1		; 00C55
	jnz	short prepare_screen_buffer_layer_dispatch		; 00C5A jnz 0xc7f
	cmp	word [current_level],0x2		; 00C5C
	jnl	short prepare_screen_buffer_top_clear_all		; 00C61 jnl 0xc72
; level < 2: lines 0-79 filled with pixel value 1
	mov	cx,0xc80		; 00C63
	mov	ax,0x5555		; 00C66
	lea	di,[offscreen_buffer]		; 00C69
	rep	stosw			; 00C6D
	jmp	short prepare_screen_buffer_layer_dispatch		; 00C6F jmp 0xc7f
	nop				; 00C71
prepare_screen_buffer_top_clear_all:
; -- top step, level >= 2: blank everything --
	call	clear_screen		; 00C72
	cmp	byte [script_running],0x0	; 00C75
	jnz	short prepare_screen_buffer_layer_dispatch		; 00C7A jnz 0xc7f
	call	draw_health_bars	; 00C7C
prepare_screen_buffer_layer_dispatch:
; -- layer dispatch on current_level --
	cmp	word [current_level],0x2		; 00C7F
	jnl	short prepare_screen_buffer_level_2_and_up		; 00C84 jnl 0xce6
; -- level < 2 layout: rebuild scenery only if the camera moved --
	mov	ax,[camera_x]		; 00C86
	cmp	ax,[last_drawn_camera_x]		; 00C89
	jz	short prepare_screen_buffer_low_levels_ground		; 00C8D jz 0xcbb
; lines 32-127 = value 1
	mov	cx,0xf00		; 00C8F
	mov	ax,0x5555		; 00C92
	lea	di,[offscreen_scenery_top]		; 00C95
	rep	stosw			; 00C99
; 34 lines of fuji.bcg to lines 80-113
	mov	cx,0x550		; 00C9B
	lea	si,[fuji_picture]		; 00C9E
	lea	di,[offscreen_fuji_band]		; 00CA2
	rep	movsw			; 00CA6
; line 106 = value 3, lines 107-109 cleared
	lea	di,[offscreen_solid_line]		; 00CA8
	mov	ax,0xffff		; 00CAC
	mov	cx,0x28			; 00CAF
	rep	stosw			; 00CB2
	db	0x33, 0xC0		; 00CB4 xor ax,ax
	mov	cx,0x78			; 00CB6
	rep	stosw			; 00CB9
prepare_screen_buffer_low_levels_ground:
; -- level < 2: ground band, redrawn every frame --
	call	clear_above_ground		; 00CBB
; 15 pairs of dither lines at lines 154-183; camera X parity selects phase
	lea	di,[offscreen_ground_stripes]		; 00CBE
	mov	bl,0xf			; 00CC2
	mov	dx,0x9999		; 00CC4
	mov	ax,[camera_x]		; 00CC7
	db	0x25, 0x01, 0x00	; 00CCA and ax,0x1
	jz	short prepare_screen_buffer_dither_pair_loop		; 00CCD jz 0xcd2
	mov	dx,0x6666		; 00CCF
prepare_screen_buffer_dither_pair_loop:
; one dither pair: line of AX, then line of NOT AX
	db	0x8B, 0xC2		; 00CD2 mov ax,dx
	mov	cx,0x28			; 00CD4
	rep	stosw			; 00CD7
	not	ax			; 00CD9
	mov	cx,0x28			; 00CDB
	rep	stosw			; 00CDE
	dec	bl			; 00CE0
	jnz	short prepare_screen_buffer_dither_pair_loop		; 00CE2 jnz 0xcd2
	pop	es			; 00CE4
	ret				; 00CE5
prepare_screen_buffer_level_2_and_up:
; -- level >= 2 layouts --
	push	ax			; 00CE6
	call	clear_above_ground		; 00CE7
	pop	ax			; 00CEA
	cmp	word [current_level],0x3		; 00CEB
	jnl	short prepare_screen_buffer_level_3_and_up		; 00CF0 jnl 0xd39
; -- level 2: rebuild scenery only if the camera moved --
	mov	ax,[camera_x]		; 00CF2
	cmp	ax,[last_drawn_camera_x]		; 00CF5
	jz	short prepare_screen_buffer_level_2_stripes		; 00CF9 jz 0xd1e
; lines 32-127 cleared
	lea	di,[offscreen_scenery_top]		; 00CFB
	mov	cx,0xf00		; 00CFF
	db	0x33, 0xC0		; 00D02 xor ax,ax
	rep	stosw			; 00D04
; 22 lines of fuji.bcg to lines 80-101, then lines 90-91 cleared
	lea	si,[fuji_picture]		; 00D06
	lea	di,[offscreen_fuji_band]		; 00D0A
	mov	cx,0x370		; 00D0E
	rep	movsw			; 00D11
	lea	di,[offscreen_fuji_band_gap]		; 00D13
	db	0x33, 0xC0		; 00D17 xor ax,ax
	mov	cx,0x50			; 00D19
	rep	stosw			; 00D1C
prepare_screen_buffer_level_2_stripes:
; -- level 2: stripes in lines 154-183 --
	lea	di,[offscreen_ground_stripes]		; 00D1E
	mov	bl,0xf			; 00D22
prepare_screen_buffer_level_2_stripe_loop:
	mov	ax,0xaaaa		; 00D24
	mov	cx,0x28			; 00D27
	rep	stosw			; 00D2A
	db	0x33, 0xC0		; 00D2C xor ax,ax
	mov	cx,0x28			; 00D2E
	rep	stosw			; 00D31
	dec	bl			; 00D33
	jnz	short prepare_screen_buffer_level_2_stripe_loop		; 00D35 jnz 0xd24
	pop	es			; 00D37
	ret				; 00D38
prepare_screen_buffer_level_3_and_up:
; -- level >= 3 layout --
	mov	ax,[camera_x]		; 00D39
	cmp	ax,[last_drawn_camera_x]		; 00D3C
	jz	short prepare_screen_buffer_level_3_stripes		; 00D40 jz 0xd4d
; lines 0-113 cleared
	lea	di,[offscreen_buffer]		; 00D42
	mov	cx,0x11d0		; 00D46
	db	0x33, 0xC0		; 00D49 xor ax,ax
	rep	stosw			; 00D4B
prepare_screen_buffer_level_3_stripes:
; -- level >= 3: stripes in lines 154-183 --
	lea	di,[offscreen_ground_stripes]		; 00D4D
	mov	bl,0xf			; 00D51
prepare_screen_buffer_level_3_stripe_loop:
	mov	ax,0x5555		; 00D53
	mov	cx,0x28			; 00D56
	rep	stosw			; 00D59
	db	0x33, 0xC0		; 00D5B xor ax,ax
	mov	cx,0x28			; 00D5D
	rep	stosw			; 00D60
	dec	bl			; 00D62
	jnz	short prepare_screen_buffer_level_3_stripe_loop		; 00D64 jnz 0xd53
	pop	es			; 00D66
	ret				; 00D67

; ---- function update_display ----
; Copies the whole offscreen buffer (DS:0x337) to video memory at B800:0000.
; No parameters. No stack frame. Preserves ES. Clobbers AX, BX, CX, SI, DI.
;
; Copies 200 scanlines of 80 bytes (40 words). The target of each line comes
; from the scanline LUT at DS:0xDF59 (one word per line, indexed by line*2).
; The LUT is what handles the display's interlacing. It is built at video
; init in input.asm: for CGA, even lines at 0x0000 + 0x50*(line/2) and odd
; lines at 0x2000 + 0x50*(line/2); init_hercules_mode instead fills in a
; 4-bank table (+0x0000/+0x2000/+0x4000/+0x6000).
update_display:
	mov	bx,0x0			; 00D68
	lea	si,[offscreen_buffer]		; 00D6B
	push	es			; 00D6F
	mov	ax,0xb800		; 00D70
	mov	es,ax			; 00D73
update_display_line_loop:
	mov	di,[bx+scanline_offsets]		; 00D75
%ifdef HEBREW
	call	mirror_line
	nop
	nop
%else
	mov	cx,0x28			; 00D79
	rep	movsw			; 00D7C
%endif
	add	bx,0x2			; 00D7E
	cmp	bx,0x190		; 00D81
	jnz	short update_display_line_loop		; 00D85 jnz 0xd75
	pop	es			; 00D87
	ret				; 00D88

; ---- function update_display_partial ----
; Copies only the part of the offscreen buffer that can have changed to VRAM.
; It is the partial-copy twin of
; update_display, used by render_figures when [0xee] == 0.
; No parameters. No stack frame. Preserves ES.
;
; Region, chosen from camera_x [0xe4] vs the last value presented [0xbb2a]:
;   camera moved          : 168 lines from DS:0xD37, i.e. lines 32-199
;                           (LUT offset 0x40 = line 32)
;   unchanged, level < 2  : 84 lines from DS:0x2777, i.e. lines 116-199
;                           (LUT offset 0xE8 = line 116)
;   unchanged, level >= 2 : 90 lines from DS:0x2597, i.e. lines 110-199
;                           (LUT offset 0xDC = line 110)
; Writes: [0xbb2a] = camera_x (the latch prepare_screen_buffer compares to).
; Uses the scanline LUT at DS:0xDF59 as update_display does.
update_display_partial:
	mov	dl,0xa8			; 00D89
	lea	si,[offscreen_scenery_top]		; 00D8B
	mov	bx,0x40			; 00D8F
	mov	ax,[camera_x]		; 00D92
	cmp	ax,[last_drawn_camera_x]		; 00D95
	jnz	short update_display_partial_copy_region		; 00D99 jnz 0xdb5
; camera unchanged: copy only the bottom region
	mov	dl,0x54			; 00D9B
	lea	si,[offscreen_partial_update_band]		; 00D9D
	mov	bx,0xe8			; 00DA1
	cmp	word [current_level],0x2		; 00DA4
	jl	short update_display_partial_copy_region		; 00DA9 jl 0xdb5
; level >= 2: start 6 lines higher
	add	dl,0x6			; 00DAB
	sub	si,0x1e0		; 00DAE
	sub	bx,0xc			; 00DB2
update_display_partial_copy_region:
; -- record the camera position, then copy the chosen lines --
	mov	[last_drawn_camera_x],ax		; 00DB5
	push	es			; 00DB8
	mov	ax,0xb800		; 00DB9
	mov	es,ax			; 00DBC
update_display_partial_line_loop:
	mov	di,[bx+scanline_offsets]		; 00DBE
%ifdef HEBREW
	call	mirror_line
	nop
	nop
%else
	mov	cx,0x28			; 00DC2
	rep	movsw			; 00DC5
%endif
	add	bx,0x2			; 00DC7
	dec	dl			; 00DCA
	jnz	short update_display_partial_line_loop		; 00DCC jnz 0xdbe
	pop	es			; 00DCE
	ret				; 00DCF

; ---- function clear_above_ground ----
; Clears the band of the offscreen buffer above the ground stripes. Called only by prepare_screen_buffer.
; No parameters. No stack frame. Preserves ES. Clobbers AX, CX, DI.
;
; [0xea] (current_level) < 2 : clears 0x690 words from DS:0x26D7 = lines 114-155
; [0xea] >= 2                : also clears the 6 lines above = lines 108-155
clear_above_ground:
	lea	di,[offscreen_above_ground_band]		; 00DD0
	mov	cx,0x690		; 00DD4
	cmp	word [current_level],0x2		; 00DD7
	jl	short clear_above_ground_fill		; 00DDC jl 0xde6
	sub	di,0x1e0		; 00DDE
	add	cx,0xf0			; 00DE2
clear_above_ground_fill:
	db	0x33, 0xC0		; 00DE6 xor ax,ax
	push	es			; 00DE8
	push	ds			; 00DE9
	pop	es			; 00DEA
	rep	stosw			; 00DEB
	pop	es			; 00DED
	ret				; 00DEE

; ---- function blit_buffer_to_vram ----
; Copies the offscreen buffer to VRAM as a visible left-to-right wipe, one
; pixel column at a time. Selected by render_figures when the wipe flag
; [0xbb31] is set (set_wipe script opcode).
; No parameters. Saves/restores BP and ES. Clobbers AX, BX, CX, SI, DI.
;
; Outer loop: BX = byte column 0..0x4F (80 columns of 4 pixels). For each byte
; column there are 4 passes, one per pixel, leftmost first:
;   pass 1 mask 0xC0 (bits 7-6), pass 2 mask 0x30, pass 3 mask 0x0C,
;   pass 4 mask 0x03
; Each pass walks all 200 scanlines (CX = 100 iterations of 2 lines), clears
; the pixel in VRAM, ORs in the matching source pixel, then calls
; blit_column_delay. The result is 320 visible steps, one per pixel column.
;
; Registers inside a pass:
;   SI = offscreen address of the current line pair (steps by 0xA0 = 2 lines)
;   [bx+si] / [bx+si+0x50] = source bytes for the line pair
;   BP = index into the scanline LUT at DS:0xDF59 (needs the DS override,
;        because BP addressing defaults to SS)
;   DI = VRAM offset of the line from the LUT; [es:bx+di] is the target byte
;
; The tail `jmp 0xff8` targets code offset 0x0DF8 (the operand is a file
; offset, including the 0x200-byte MZ header): the start of the next column.
blit_buffer_to_vram:
%ifdef HEBREW
; Mirrored wipe: same pixel-column order as the original, drawn from the right.
	push	bp
	push	dx
	push	es
	mov	ax,0xb800
	mov	es,ax
	xor	bx,bx
blit_hebrew_column_loop:
	mov	dl,6			; source pixel shift: 6, 4, 2, 0
blit_hebrew_pixel_loop:
	lea	si,[offscreen_buffer]
	xor	bp,bp
blit_hebrew_row_loop:
	mov	di,[ds:bp+scanline_offsets]
	add	di,0x4f
	sub	di,bx
	mov	al,[bx+si]
	mov	cl,dl
	shr	al,cl
	and	al,0x3
	mov	cl,6
	sub	cl,dl			; destination pixel shift
	shl	al,cl
	mov	ah,0x3
	shl	ah,cl
	not	ah
	and	[es:di],ah
	or	[es:di],al
	add	si,0x50
	add	bp,0x2
	cmp	bp,0x190
	jnz	blit_hebrew_row_loop
	call	blit_column_delay
	sub	dl,2
	jns	blit_hebrew_pixel_loop
	inc	bx
	cmp	bx,0x50
	jnz	blit_hebrew_column_loop
	pop	es
	pop	dx
	pop	bp
	ret
	times 249-($-blit_buffer_to_vram) nop
%else
	push	bp			; 00DEF
	db	0x33, 0xDB		; 00DF0 xor bx,bx
	push	es			; 00DF2
	mov	ax,0xb800		; 00DF3
	mov	es,ax			; 00DF6
; -- pass 1: leftmost pixel of column BX (mask 0xC0) --
; one iteration per byte column BX (0..0x4F), four pixel passes each
blit_buffer_to_vram_column_loop:
	lea	si,[offscreen_buffer]		; 00DF8
	db	0x33, 0xED		; 00DFC xor bp,bp
	mov	cx,0x64			; 00DFE
; mask 0xC0; handles two scanlines per iteration, 100 iterations
blit_buffer_to_vram_pass1_row_loop:
	mov	di,[ds:bp+0xdf59]	; 00E01
	mov	al,[bx+si]		; 00E06
	and	al,0xc0			; 00E08
	and	byte [es:bx+di],0x3f	; 00E0A
	or	[es:bx+di],al		; 00E0E
	mov	al,[bx+si+0x50]		; 00E11
	and	al,0xc0			; 00E14
	add	bp,0x2			; 00E16
	mov	di,[ds:bp+0xdf59]	; 00E19
	and	byte [es:bx+di],0x3f	; 00E1E
	or	[es:bx+di],al		; 00E22
	add	si,0xa0			; 00E25
	add	bp,0x2			; 00E29
	loop	0xe01			; 00E2C
	call	blit_column_delay	; 00E2E
; -- pass 2: mask 0x30 --
	lea	si,[offscreen_buffer]		; 00E31
	db	0x33, 0xED		; 00E35 xor bp,bp
	mov	cx,0x64			; 00E37
; mask 0x30
blit_buffer_to_vram_pass2_row_loop:
	mov	di,[ds:bp+0xdf59]	; 00E3A
	mov	al,[bx+si]		; 00E3F
	and	al,0x30			; 00E41
	and	byte [es:bx+di],0xcf	; 00E43
	or	[es:bx+di],al		; 00E47
	mov	al,[bx+si+0x50]		; 00E4A
	and	al,0x30			; 00E4D
	add	bp,0x2			; 00E4F
	mov	di,[ds:bp+0xdf59]	; 00E52
	and	byte [es:bx+di],0xcf	; 00E57
	or	[es:bx+di],al		; 00E5B
	add	si,0xa0			; 00E5E
	add	bp,0x2			; 00E62
	loop	0xe3a			; 00E65
	call	blit_column_delay	; 00E67
; -- pass 3: mask 0x0C --
	lea	si,[offscreen_buffer]		; 00E6A
	db	0x33, 0xED		; 00E6E xor bp,bp
	mov	cx,0x64			; 00E70
; mask 0x0C
blit_buffer_to_vram_pass3_row_loop:
	mov	di,[ds:bp+0xdf59]	; 00E73
	mov	al,[bx+si]		; 00E78
	and	al,0xc			; 00E7A
	and	byte [es:bx+di],0xf3	; 00E7C
	or	[es:bx+di],al		; 00E80
	mov	al,[bx+si+0x50]		; 00E83
	and	al,0xc			; 00E86
	add	bp,0x2			; 00E88
	mov	di,[ds:bp+0xdf59]	; 00E8B
	and	byte [es:bx+di],0xf3	; 00E90
	or	[es:bx+di],al		; 00E94
	add	si,0xa0			; 00E97
	add	bp,0x2			; 00E9B
	loop	0xe73			; 00E9E
	call	blit_column_delay	; 00EA0
; -- pass 4: rightmost pixel of column BX (mask 0x03) --
	lea	si,[offscreen_buffer]		; 00EA3
	db	0x33, 0xED		; 00EA7 xor bp,bp
	mov	cx,0x64			; 00EA9
; mask 0x03
blit_buffer_to_vram_pass4_row_loop:
	mov	di,[ds:bp+0xdf59]	; 00EAC
	mov	al,[bx+si]		; 00EB1
	and	al,0x3			; 00EB3
	and	byte [es:bx+di],0xfc	; 00EB5
	or	[es:bx+di],al		; 00EB9
	mov	al,[bx+si+0x50]		; 00EBC
	and	al,0x3			; 00EBF
	add	bp,0x2			; 00EC1
	mov	di,[ds:bp+0xdf59]	; 00EC4
	and	byte [es:bx+di],0xfc	; 00EC9
	or	[es:bx+di],al		; 00ECD
	add	si,0xa0			; 00ED0
	add	bp,0x2			; 00ED4
	loop	0xeac			; 00ED7
	call	blit_column_delay	; 00ED9
; -- next byte column --
	inc	bx			; 00EDC
	cmp	bx,0x50			; 00EDD
	jz	short blit_buffer_to_vram_done		; 00EE0 jz 0xee5
	jmp	near blit_buffer_to_vram_column_loop			; 00EE2
blit_buffer_to_vram_done:
; -- all 80 byte columns done --
	pop	es			; 00EE5
	pop	bp			; 00EE6
	ret				; 00EE7
%endif

; ---- function blit_column_delay ----
; Busy-wait: spins CX from 1000 down to 0 on a single LOOP instruction, so the
; duration depends on CPU speed. Called once after every pixel-column pass of
; blit_buffer_to_vram, which is what paces the wipe.
; No parameters. No stack frame. Clobbers CX.
blit_column_delay:
	mov	cx,0x3e8		; 00EE8
; loop-to-self busy wait, 1000 iterations
blit_column_delay_spin:
	loop	0xeeb			; 00EEB
	ret				; 00EED

; ---- function title_step_picture ----
; Title-sequence step from game_main_loop: shows the picture stored at
; DS:0xA6D6, waits, then adds one sprite and waits again. Draws a single
; static sprite.
; No parameters. No stack frame. Preserves ES.
;
; Sequence:
;   1. clear_screen
;   2. copy 0x820 words (0x1040 bytes = 52 scanlines) from DS:0xA6D6 to
;      DS:0x1917 (line 70). game_main_loop has already loaded title.bcg at
;      buffer offset 0 (DS:0xA6D6).
;   3. update_display, delay_with_input(0x12)
;   4. draw_sprite_unflipped(sprite 0x5C, x 0x28, y 0xB4)
;   5. update_display, delay_with_input(0x48)
;
; Returns: AX from the last delay_with_input: nonzero if a key ended the
;          wait, else 0 (game_main_loop aborts the sequence when nonzero).
;          A key during the first delay only shortens that delay.
title_step_picture:
	call	clear_screen		; 00EEE
	push	es			; 00EF1
	push	ds			; 00EF2
	pop	es			; 00EF3
; copy 52 lines of the DS:0xA6D6 picture to line 70
%ifdef HEBREW
; The logo is too tall for resource_buffer, so load it straight into the framebuffer at
; line 70: load_resource adds this offset to resource_buffer modulo 0x10000.
	mov	ax,(offscreen_title_picture - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,str_title_bcg - DS_BASE
	push	ax
	call	load_resource
	pop	cx
	pop	cx
%else
	mov	cx,0x820		; 00EF4
	lea	si,[resource_buffer]		; 00EF7
	lea	di,[offscreen_title_picture]		; 00EFB
	rep	movsw			; 00EFF
%endif
	call	update_display		; 00F01
	mov	ax,0x12			; 00F04
	call	delay_with_input	; 00F07
; add the sprite on top of the picture
%ifdef HEBREW
; The Hebrew copyright line replaces sprite 0x5C: 16 rows loaded straight to line 180.
	mov	ax,(offscreen_buffer + 180*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,intro_text+11	; "hcopy.bcg", see the intro_text slot in data.asm
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 5 nop
%else
	mov	ax,0xb4			; 00F0A
	push	ax			; 00F0D
	mov	ax,0x28			; 00F0E
	push	ax			; 00F11
	mov	ax,0x5c			; 00F12
	push	ax			; 00F15
	call	draw_sprite_unflipped	; 00F16
	add	sp,0x6			; 00F19
%endif
	call	update_display		; 00F1C
	mov	ax,0x48			; 00F1F
	call	delay_with_input	; 00F22
	pop	es			; 00F25
	ret				; 00F26

; ---- function title_step_sprite ----
; Title-sequence step from game_main_loop: shows one sprite on a blank screen
; and waits. No parameters. No stack frame.
;
; Sequence: clear_screen, draw_sprite_unflipped(sprite 0x5B, x 0x6A, y 0x73),
; update_display, delay_with_input(0x48). game_main_loop calls
; load_sprite_set(0xD) (the ksi/kmi set) first, and that index contains 0x5B.
;
; [0x168] is set to 1 only during the delay. It is not single-step mode (that
; is [0xbcd8]): poll_keyboard tests it to enable a hidden Ctrl+V, which draws
; sprite 0x5D at (0x96, 0xBE) and calls update_display.
;
; Returns: AX from delay_with_input: nonzero if a key ended the wait, else 0.
title_step_sprite:
	call	clear_screen		; 00F27
; The Hebrew publisher credit replaces sprite 0x5B (crowns kept), loaded straight to line 66.
%ifdef HEBREW
	mov	ax,(offscreen_buffer + 66*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,intro_text+26	; "hpres.bcg", see the intro_text slot in data.asm
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 5 nop
%else
	mov	ax,0x73			; 00F2A
	push	ax			; 00F2D
	mov	ax,0x6a			; 00F2E
	push	ax			; 00F31
	mov	ax,0x5b			; 00F32
	push	ax			; 00F35
	call	draw_sprite_unflipped	; 00F36
	add	sp,0x6			; 00F39
%endif
	call	update_display		; 00F3C
	mov	word [title_ctrl_v_armed],0x1	; 00F3F
	mov	ax,0x48			; 00F45
	call	delay_with_input	; 00F48
	mov	word [title_ctrl_v_armed],0x0	; 00F4B
	ret				; 00F51

; ---- function load_resource ----
; Loads a .bcg-format resource file into the buffer at DS:0xA6D6 + offset.
;
; Parameters (on stack, Lattice C convention; frame is sub sp,0xe):
;   [bp+0x12] = filename pointer (e.g. str_fuji_bcg, str_title_bcg)
;   [bp+0x14] = byte offset into the DS:0xA6D6 buffer
;
; Local variables:
;   [bp+0x6] = file slot from open_file_retry
;   [bp+0x8] = data length read from the file header
;
; Returns: AX = data length loaded
;
; .bcg file format, as far as this loader shows:
;   +0  u16 little-endian data length N
;   +2  N bytes of raw data, no decompression step
; (Files on the disk are longer than N + 2: unused trailing padding.)
; The length prefix is first read into the destination itself, then the data
; is read over the same address, so the prefix is not kept.
; The data is plain offscreen-format pixels, 80 bytes per scanline.
;
; Known uses: title.bcg at offset 0 and fuji.bcg at offset 0x5DC (= DS:0xACB2,
; used by prepare_screen_buffer). title.bcg (0x1090 bytes) overruns 0x5DC, so
; it destroys fuji.bcg, and game_main_loop reloads fuji.bcg afterwards.
load_resource:
	push	bp			; 00F52
	sub	sp,0xe			; 00F53
	jc	short load_resource_stack_overflow		; 00F56 jc 0xf5e
	cmp	sp,[stack_limit]		; 00F58
	ja	short load_resource_stack_ok		; 00F5C ja 0xf61
load_resource_stack_overflow:
	jmp	near stack_overflow_handler			; 00F5E
load_resource_stack_ok:
	db	0x8B, 0xEC		; 00F61 mov bp,sp
; -- open the file and read the 2-byte length prefix into the buffer --
	mov	ax,0x8000		; 00F63
	push	ax			; 00F66
	push	word [bp+0x12]		; 00F67
	call	open_file_retry		; 00F6A
	db	0x8B, 0xE5		; 00F6D mov sp,bp
	mov	bx,[bp+0x14]		; 00F6F
	add	bx,0xa6d6		; 00F72
	mov	cx,0x2			; 00F76
	push	cx			; 00F79
	push	bx			; 00F7A
	push	ax			; 00F7B
	mov	[bp+0x6],ax		; 00F7C
	call	file_read		; 00F7F
	db	0x8B, 0xE5		; 00F82 mov sp,bp
; -- length = prefix bytes, little-endian --
	mov	si,[bp+0x14]		; 00F84
	mov	al,[si+resource_buffer_byte1]		; 00F87
	xor	ah,ah			; 00F8B
	mov	cl,0x8			; 00F8D
	shl	ax,cl			; 00F8F
	mov	bl,[si+resource_buffer]		; 00F91
	xor	bh,bh			; 00F95
	db	0x03, 0xD8		; 00F97 add bx,ax
; -- read the data over the same address, then close --
	db	0x8B, 0xC6		; 00F99 mov ax,si
	add	ax,0xa6d6		; 00F9B
	push	bx			; 00F9E
	push	ax			; 00F9F
	push	word [bp+0x6]		; 00FA0
	mov	[bp+0x8],bx		; 00FA3
	call	file_read		; 00FA6
	db	0x8B, 0xE5		; 00FA9 mov sp,bp
	push	word [bp+0x6]		; 00FAB
	call	close_file_slot		; 00FAE
	db	0x8B, 0xE5		; 00FB1 mov sp,bp
	mov	ax,[bp+0x8]		; 00FB3
	add	sp,0xe			; 00FB6
	pop	bp			; 00FB9
	ret				; 00FBA

; ---- function load_background ----
; Loads castle.bcg straight into the offscreen buffer and displays it.
; No parameters: the filename (str_castle_bcg) is hard-coded.
;
; Local variables (frame is sub sp,0xc):
;   [bp+0x4] = file slot from open_file_retry
;   [bp+0x6] = data length read from the file header
;
; Same .bcg format as load_resource: u16 little-endian length, then raw data,
; with no decompression. The length prefix is read into DS:0x337/0x338, then
; the data is read over it, so the file holds offscreen-format scanlines from
; line 0 onward. (castle.bcg holds 0x3BB0 bytes = 191 lines; clear_screen has
; already blanked the remainder.)
;
; Then: update_display, play_sound(0x19).
load_background:
	push	bp			; 00FBB
	sub	sp,0xc			; 00FBC
	jc	short load_background_stack_overflow		; 00FBF jc 0xfc7
	cmp	sp,[stack_limit]		; 00FC1
	ja	short load_background_stack_ok		; 00FC5 ja 0xfca
load_background_stack_overflow:
	jmp	near stack_overflow_handler			; 00FC7
load_background_stack_ok:
	db	0x8B, 0xEC		; 00FCA mov bp,sp
	call	clear_screen		; 00FCC
; -- open castle.bcg and read the 2-byte length prefix --
	mov	ax,0x8000		; 00FCF
	push	ax			; 00FD2
	mov	ax,str_castle_bcg - DS_BASE	; 00FD3
	push	ax			; 00FD6
	call	open_file_retry		; 00FD7
	db	0x8B, 0xE5		; 00FDA mov sp,bp
	mov	bx,0x2			; 00FDC
	push	bx			; 00FDF
	mov	bx,0x337		; 00FE0
	push	bx			; 00FE3
	push	ax			; 00FE4
	mov	[bp+0x4],ax		; 00FE5
	call	file_read		; 00FE8
	db	0x8B, 0xE5		; 00FEB mov sp,bp
; -- length = prefix bytes; read the raw image over the prefix, then close --
	mov	al,[offscreen_length_prefix_hi]		; 00FED
	xor	ah,ah			; 00FF0
	mov	cl,0x8			; 00FF2
	shl	ax,cl			; 00FF4
	mov	bl,[offscreen_buffer]		; 00FF6
	xor	bh,bh			; 00FFA
	db	0x03, 0xD8		; 00FFC add bx,ax
	push	bx			; 00FFE
	mov	ax,0x337		; 00FFF
	push	ax			; 01002
	push	word [bp+0x4]		; 01003
	mov	[bp+0x6],bx		; 01006
	call	file_read		; 01009
	db	0x8B, 0xE5		; 0100C mov sp,bp
	push	word [bp+0x4]		; 0100E
	call	close_file_slot		; 01011
	db	0x8B, 0xE5		; 01014 mov sp,bp
; -- show it --
	call	update_display		; 01016
	mov	ax,0x19			; 01019
	push	ax			; 0101C
	call	play_sound		; 0101D
	db	0x8B, 0xE5		; 01020 mov sp,bp
	add	sp,0xc			; 01022
	pop	bp			; 01025
	ret				; 01026

; ---- function load_sprite_set ----
; Loads one sprite set: an index + data file pair for the image bank and
; another pair for the mask bank, and fills in the sprite lookup tables.
;
; Parameters (on stack, Lattice C convention; frame is sub sp,0x2a):
;   [bp+0x2e] = set index 0..13, into two tables of filename-stem pointers:
;               DS:0x264 image stems: ks0 ks1 ks2 ks3 ks4 ksc ksi0 ksi1 ksi2
;                                     ksj2 ksi3 ksi4 ksj4 ksi
;               DS:0x2C0 mask stems:  km0 km1 km2 km3 km4 kmc kmi0 kmi1 kmi2
;                                     kmj2 kmi3 kmi4 kmj4 kmi
;
; Local variables:
;   [bp+0x0]      = copy of the record offset (written, never read)
;   [bp+0x8]      = file slot from open_file_retry
;   [bp+0xa]      = .dat length from the index's 0xFF record (stays
;                   uninitialized if an index had no terminator)
;   [bp+0xc]      = index record byte offset, steps by 4 up to 0x2A8
;   [bp+0x10]     = copy of the image .dat length (written, never read)
;   [bp+0x12]     = computed sprite offset (16-bit)
;   [bp+0x14]     = sprite id of the current record
;   [bp+0x16..29] = filename buffer (20 bytes), stem + ".ind" or ".dat"
;
; Uses globals (word-sized byte offsets into the banks; both reset to 0 by
; load_player_anim_data before it loads set 5, ksc/kmc):
;   [0x160] = where the next image data goes, relative to DS:0x443C
;   [0x164] = where the next mask data goes, relative to DS:0x893A
; Both are set only when they were 0, to the size of the first load. So the
; first set stays resident at the bank start, and every later set is loaded
; at the same position right after it, replacing the previous later set.
; Writes: the lookup tables below. Returns nothing meaningful.
;
; .ind file format (at most 0x2A8 bytes = 170 records are examined, and the
; file is read into the bank as a scratch area), 4-byte records:
;   +0      sprite id; 0xFF marks the last record
;   +1      not read here
;   +2..+3  u16 little-endian offset of the sprite in the matching .dat;
;           in the 0xFF record it is the total .dat length to read
; Each record stores (bank start offset + sprite offset), one byte at a time,
; at table[id*2], where the tables are 256 words each and sit directly before
; their banks:
;   DS:0x423C (image) .. DS:0x443C      DS:0x873A (mask) .. DS:0x893A
;
; .dat format (one sprite at each index offset; layout as read by draw_sprite_flipped):
;   +0 width in bytes (4-pixel columns)
;   +1 height in scanlines
;   +2 skipped by draw_sprite_flipped (it starts reading at +3)
;   +3 RLE stream (see next_sprite_bytes) of width*height bytes in column
;      order: each column top to bottom, columns left to right
; Image and mask of a sprite decode in lock step, one byte from each stream.
load_sprite_set:
	push	bp			; 01027
	sub	sp,0x2a			; 01028
	jc	short load_sprite_set_stack_overflow		; 0102B jc 0x1033
	cmp	sp,[stack_limit]		; 0102D
	ja	short load_sprite_set_stack_ok		; 01031 ja 0x1036
load_sprite_set_stack_overflow:
	jmp	near stack_overflow_handler			; 01033
load_sprite_set_stack_ok:
	db	0x8B, 0xEC		; 01036 mov bp,sp
; -- image index: build "<ks stem>.ind", read it into the image bank --
	mov	ax,[bp+0x2e]		; 01038
	shl	ax,1			; 0103B
	db	0x8B, 0xF0		; 0103D mov si,ax
	push	word [si+sprite_image_stem_ptrs]		; 0103F
	lea	ax,[bp+0x16]		; 01043
	push	ax			; 01046
	call	strcpy			; 01047
	db	0x8B, 0xE5		; 0104A mov sp,bp
	mov	ax,0x32d		; 0104C
	push	ax			; 0104F
	lea	ax,[bp+0x16]		; 01050
	push	ax			; 01053
	call	strcat			; 01054
	db	0x8B, 0xE5		; 01057 mov sp,bp
	mov	ax,0x8000		; 01059
	push	ax			; 0105C
	lea	ax,[bp+0x16]		; 0105D
	push	ax			; 01060
	call	open_file_retry		; 01061
	db	0x8B, 0xE5		; 01064 mov sp,bp
	mov	bx,[sprite_image_load_offset]		; 01066
	add	bx,0x443c		; 0106A
	mov	cx,0x2a8		; 0106E
	push	cx			; 01071
	push	bx			; 01072
	push	ax			; 01073
	mov	[bp+0x8],ax		; 01074
	call	file_read		; 01077
	db	0x8B, 0xE5		; 0107A mov sp,bp
	push	word [bp+0x8]		; 0107C
	call	close_file_slot		; 0107F
	db	0x8B, 0xE5		; 01082 mov sp,bp
	mov	word [bp+0xc],0x0	; 01084
load_sprite_set_image_index_scan:
; -- scan image index: fill sprite id -> offset table at DS:0x423C --
	mov	ax,[bp+0xc]		; 01089
	cmp	ax,0x2a8		; 0108C
	jnl	short load_sprite_set_load_image_data		; 0108F jnl 0x10fb
	mov	bx,[sprite_image_load_offset]		; 01091
	db	0x03, 0xC3		; 01095 add ax,bx
	db	0x8B, 0xF0		; 01097 mov si,ax
	mov	cl,[si+sprite_image_bank]		; 01099
	xor	ch,ch			; 0109D
	mov	dl,[si+sprite_image_bank_byte3]		; 0109F
	xor	dh,dh			; 010A3
	mov	[bp+0x14],cx		; 010A5
	mov	cl,0x8			; 010A8
	shl	dx,cl			; 010AA
	mov	cl,[si+sprite_image_bank_byte2]		; 010AC
	xor	ch,ch			; 010B0
	db	0x03, 0xCA		; 010B2 add cx,dx
	db	0x03, 0xCB		; 010B4 add cx,bx
	mov	bx,[bp+0x14]		; 010B6
	shl	bx,1			; 010B9
	mov	[bp+0x12],cx		; 010BB
	and	cx,0xff			; 010BE
	mov	[bx+sprite_image_offsets],cl		; 010C2
	mov	cl,0x8			; 010C6
	mov	dx,[bp+0x12]		; 010C8
	sar	dx,cl			; 010CB
	mov	[bx+sprite_image_offsets_hi],dl		; 010CD
	cmp	word [bp+0x14],0xff	; 010D1
	mov	[bp+0x0],ax		; 010D6
	jnz	short load_sprite_set_image_next_record		; 010D9 jnz 0x10f5
; id 0xFF: bytes 2-3 are the .dat length; force the scan to stop
	mov	al,[si+sprite_image_bank_byte3]		; 010DB
	xor	ah,ah			; 010DF
	mov	cl,0x8			; 010E1
	shl	ax,cl			; 010E3
	mov	bl,[si+sprite_image_bank_byte2]		; 010E5
	xor	bh,bh			; 010E9
	db	0x03, 0xD8		; 010EB add bx,ax
	mov	word [bp+0xc],0x2a8	; 010ED
	mov	[bp+0xa],bx		; 010F2
load_sprite_set_image_next_record:
; advance to the next record (the 0xFF case forces the loop to end)
	add	word [bp+0xc],0x4	; 010F5
	jmp	short load_sprite_set_image_index_scan		; 010F9 jmp 0x1089
load_sprite_set_load_image_data:
; -- image data: read <stem>.dat over the index scratch area --
	mov	ax,[bp+0x2e]		; 010FB
	shl	ax,1			; 010FE
	db	0x8B, 0xF0		; 01100 mov si,ax
	push	word [si+sprite_image_stem_ptrs]		; 01102
	lea	ax,[bp+0x16]		; 01106
	push	ax			; 01109
	call	strcpy			; 0110A
	db	0x8B, 0xE5		; 0110D mov sp,bp
	mov	ax,0x332		; 0110F
	push	ax			; 01112
	lea	ax,[bp+0x16]		; 01113
	push	ax			; 01116
	call	strcat			; 01117
	db	0x8B, 0xE5		; 0111A mov sp,bp
	mov	ax,0x8000		; 0111C
	push	ax			; 0111F
	lea	ax,[bp+0x16]		; 01120
	push	ax			; 01123
	call	open_file_retry		; 01124
	db	0x8B, 0xE5		; 01127 mov sp,bp
	mov	bx,[bp+0xa]		; 01129
	mov	cx,[sprite_image_load_offset]		; 0112C
	add	cx,0x443c		; 01130
	push	bx			; 01134
	push	cx			; 01135
	push	ax			; 01136
	mov	[bp+0x8],ax		; 01137
	mov	[bp+0x10],bx		; 0113A
	call	file_read		; 0113D
	db	0x8B, 0xE5		; 01140 mov sp,bp
	push	word [bp+0x8]		; 01142
	call	close_file_slot		; 01145
	db	0x8B, 0xE5		; 01148 mov sp,bp
; -- first set loaded: next sets go right after it --
	cmp	word [sprite_image_load_offset],0x0	; 0114A
	jnz	short load_sprite_set_load_mask_index		; 0114F jnz 0x1157
	mov	ax,[bp+0xa]		; 01151
	mov	[sprite_image_load_offset],ax		; 01154
load_sprite_set_load_mask_index:
; -- mask index: read km*.ind into the mask bank --
	mov	ax,[bp+0x2e]		; 01157
	shl	ax,1			; 0115A
	db	0x8B, 0xF0		; 0115C mov si,ax
	push	word [si+sprite_mask_stem_ptrs]		; 0115E
	lea	ax,[bp+0x16]		; 01162
	push	ax			; 01165
	call	strcpy			; 01166
	db	0x8B, 0xE5		; 01169 mov sp,bp
	mov	ax,0x32d		; 0116B
	push	ax			; 0116E
	lea	ax,[bp+0x16]		; 0116F
	push	ax			; 01172
	call	strcat			; 01173
	db	0x8B, 0xE5		; 01176 mov sp,bp
	mov	ax,0x8000		; 01178
	push	ax			; 0117B
	lea	ax,[bp+0x16]		; 0117C
	push	ax			; 0117F
	call	open_file_retry		; 01180
	db	0x8B, 0xE5		; 01183 mov sp,bp
	mov	bx,[sprite_mask_load_offset]		; 01185
	add	bx,0x893a		; 01189
	mov	cx,0x2a8		; 0118D
	push	cx			; 01190
	push	bx			; 01191
	push	ax			; 01192
	mov	[bp+0x8],ax		; 01193
	call	file_read		; 01196
	db	0x8B, 0xE5		; 01199 mov sp,bp
	push	word [bp+0x8]		; 0119B
	call	close_file_slot		; 0119E
	db	0x8B, 0xE5		; 011A1 mov sp,bp
	mov	word [bp+0xc],0x0	; 011A3
load_sprite_set_mask_index_scan:
; -- scan mask index: fill sprite id -> offset table at DS:0x873A --
	mov	ax,[bp+0xc]		; 011A8
	cmp	ax,0x2a8		; 011AB
	jnl	short load_sprite_set_load_mask_data		; 011AE jnl 0x121a
	mov	bx,[sprite_mask_load_offset]		; 011B0
	db	0x03, 0xC3		; 011B4 add ax,bx
	db	0x8B, 0xF0		; 011B6 mov si,ax
	mov	cl,[si+sprite_mask_bank]		; 011B8
	xor	ch,ch			; 011BC
	mov	dl,[si+sprite_mask_bank_byte3]		; 011BE
	xor	dh,dh			; 011C2
	mov	[bp+0x14],cx		; 011C4
	mov	cl,0x8			; 011C7
	shl	dx,cl			; 011C9
	mov	cl,[si+sprite_mask_bank_byte2]		; 011CB
	xor	ch,ch			; 011CF
	db	0x03, 0xCA		; 011D1 add cx,dx
	db	0x03, 0xCB		; 011D3 add cx,bx
	mov	bx,[bp+0x14]		; 011D5
	shl	bx,1			; 011D8
	mov	[bp+0x12],cx		; 011DA
	and	cx,0xff			; 011DD
	mov	[bx+sprite_mask_offsets],cl		; 011E1
	mov	cl,0x8			; 011E5
	mov	dx,[bp+0x12]		; 011E7
	sar	dx,cl			; 011EA
	mov	[bx+sprite_mask_offsets_hi],dl		; 011EC
; (0xFF handling matches the image scan above)
	cmp	word [bp+0x14],0xff	; 011F0
	mov	[bp+0x0],ax		; 011F5
	jnz	short load_sprite_set_mask_next_record		; 011F8 jnz 0x1214
	mov	al,[si+sprite_mask_bank_byte3]		; 011FA
	xor	ah,ah			; 011FE
	mov	cl,0x8			; 01200
	shl	ax,cl			; 01202
	mov	bl,[si+sprite_mask_bank_byte2]		; 01204
	xor	bh,bh			; 01208
	db	0x03, 0xD8		; 0120A add bx,ax
	mov	word [bp+0xc],0x2a8	; 0120C
	mov	[bp+0xa],bx		; 01211
load_sprite_set_mask_next_record:
; advance to the next record (the 0xFF case forces the loop to end)
	add	word [bp+0xc],0x4	; 01214
	jmp	short load_sprite_set_mask_index_scan		; 01218 jmp 0x11a8
load_sprite_set_load_mask_data:
; -- mask data: read <stem>.dat over the index scratch area --
	mov	ax,[bp+0x2e]		; 0121A
	shl	ax,1			; 0121D
	db	0x8B, 0xF0		; 0121F mov si,ax
	push	word [si+sprite_mask_stem_ptrs]		; 01221
	lea	ax,[bp+0x16]		; 01225
	push	ax			; 01228
	call	strcpy			; 01229
	db	0x8B, 0xE5		; 0122C mov sp,bp
	mov	ax,0x332		; 0122E
	push	ax			; 01231
	lea	ax,[bp+0x16]		; 01232
	push	ax			; 01235
	call	strcat			; 01236
	db	0x8B, 0xE5		; 01239 mov sp,bp
	mov	ax,0x8000		; 0123B
	push	ax			; 0123E
	lea	ax,[bp+0x16]		; 0123F
	push	ax			; 01242
	call	open_file_retry		; 01243
	db	0x8B, 0xE5		; 01246 mov sp,bp
	mov	bx,[sprite_mask_load_offset]		; 01248
	add	bx,0x893a		; 0124C
	push	word [bp+0xa]		; 01250
	push	bx			; 01253
	push	ax			; 01254
	mov	[bp+0x8],ax		; 01255
	call	file_read		; 01258
	db	0x8B, 0xE5		; 0125B mov sp,bp
	push	word [bp+0x8]		; 0125D
	call	close_file_slot		; 01260
	db	0x8B, 0xE5		; 01263 mov sp,bp
; -- first set loaded: next sets go right after it --
	cmp	word [sprite_mask_load_offset],0x0	; 01265
	jnz	short load_sprite_set_return		; 0126A jnz 0x1272
	mov	ax,[bp+0xa]		; 0126C
	mov	[sprite_mask_load_offset],ax		; 0126F
load_sprite_set_return:
; restore frame and return
	add	sp,0x2a			; 01272
	pop	bp			; 01275
	ret				; 01276
