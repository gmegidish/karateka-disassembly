; Keyboard polling, joystick, video mode init, hit detection, figure rendering


; ---- function poll_keyboard ----
; Main keyboard polling function. Checks for input and handles special keys.
;
; Input: [bp+4] = mode (0=check joystick too, 1=keyboard only)
; Special key handling:
;   Ctrl+Q (via check_ctrl_q) = quit game
;   Ctrl+R (0x12) = set input_advance flag [0xDF44]
;   Ctrl+S (0x13) = cycle sound mode [0xD6BC] (0->1->2->0)
;   Ctrl+V (0x16) with [0x168]=1 = debug render sprite
;   ESC (0x1B) = read and discard next byte
;   Extended keys (AL=0): left arrow (0x4B)->'4', right arrow (0x4D)->'6'
; Output: AL=0 no input, AL=0xFF input pending (stored in [0xDF42]/[0xDF43])
; Joystick is polled only when [0xDF46] == 0; 1 means keyboard only (set when init_controls reports none, or by 'k' in key_to_move, cleared by 'j').
; [bp+4] is not read here but is read by check_joystick and read_joystick through the shared BP: 0 = full joystick read, non-zero = buttons only, where any button queues key 13.
poll_keyboard:
	push	bp			; 04149
	db	0x8B, 0xEC		; 0414A mov bp,sp
	call	check_ctrl_q		; 0414C
	nop				; 0414F
	nop				; 04150
	nop				; 04151
	jnz	short poll_keyboard_handle_keypress		; 04152 jnz 0x4177
	cmp	word [keyboard_only],0x0	; 04154
	jnz	short poll_keyboard_check_pending_key		; 04159 jnz 0x4169
	db	0x33, 0xC0		; 0415B xor ax,ax
	push	ax			; 0415D
	call	check_joystick		; 0415E
	pop	bx			; 04161
	cmp	al,0x0			; 04162
	jz	short poll_keyboard_check_pending_key		; 04164 jz 0x4169
	jmp	0x43e8			; 04166
poll_keyboard_check_pending_key:
	cmp	byte [key_pending],0x0	; 04169
	jnz	short poll_keyboard_return_key_pending		; 0416E jnz 0x4173
	cbw				; 04170
	pop	bp			; 04171
	ret				; 04172
poll_keyboard_return_key_pending:
	mov	al,0xff			; 04173
	pop	bp			; 04175
	ret				; 04176
poll_keyboard_handle_keypress:
	cmp	al,0x1b			; 04177
	jz	short poll_keyboard_handle_esc		; 04179 jz 0x41f4
	cmp	al,0x12			; 0417B
	jnz	short poll_keyboard_check_ctrl_s		; 0417D jnz 0x418c
	call	play_sound_5_forced		; 0417F
	mov	word [input_advance],0x1	; 04182
	db	0x33, 0xC0		; 04188 xor ax,ax
	pop	bp			; 0418A
	ret				; 0418B
poll_keyboard_check_ctrl_s:
	cmp	al,0x13			; 0418C
	jnz	short poll_keyboard_check_debug_ctrl_v		; 0418E jnz 0x41a7
	call	play_sound_5_forced		; 04190
	inc	byte [sound_mode]		; 04193
	cmp	byte [sound_mode],0x3	; 04197
	jc	short poll_keyboard_sound_mode_cycled		; 0419C jc 0x41a3
	mov	byte [sound_mode],0x0	; 0419E
poll_keyboard_sound_mode_cycled:
	db	0x33, 0xC0		; 041A3 xor ax,ax
	pop	bp			; 041A5
	ret				; 041A6
poll_keyboard_check_debug_ctrl_v:
	cmp	word [title_ctrl_v_armed],0x1	; 041A7
	jnz	short poll_keyboard_check_extended_key		; 041AC jnz 0x41ce
	cmp	al,0x16			; 041AE
	jnz	short poll_keyboard_check_extended_key		; 041B0 jnz 0x41ce
	call	play_sound_5_forced		; 041B2
	mov	ax,0xbe			; 041B5
	push	ax			; 041B8
	mov	ax,0x96			; 041B9
	push	ax			; 041BC
	mov	ax,0x5d			; 041BD
	push	ax			; 041C0
	call	draw_sprite_unflipped	; 041C1
	add	sp,0x6			; 041C4
	call	update_display		; 041C7
	db	0x33, 0xC0		; 041CA xor ax,ax
	pop	bp			; 041CC
	ret				; 041CD
poll_keyboard_check_extended_key:
	cmp	al,0x0			; 041CE
	jnz	short poll_keyboard_store_pending_key		; 041D0 jnz 0x41e8
	mov	ah,0x7			; 041D2
	int	0x21			; 041D4
	cmp	al,0x4b			; 041D6
	jnz	short poll_keyboard_check_right_arrow		; 041D8 jnz 0x41de
%ifdef HEBREW
	mov	al,0x36			; arrows swapped to match the mirrored screen
%else
	mov	al,0x34			; 041DA
%endif
	jmp	short poll_keyboard_store_pending_key		; 041DC jmp 0x41e8
poll_keyboard_check_right_arrow:
	cmp	al,0x4d			; 041DE
	jz	short poll_keyboard_map_right_arrow		; 041E0 jz 0x41e6
	db	0x33, 0xC0		; 041E2 xor ax,ax
	pop	bp			; 041E4
	ret				; 041E5
poll_keyboard_map_right_arrow:
%ifdef HEBREW
	mov	al,0x34			; arrows swapped to match the mirrored screen
%else
	mov	al,0x36			; 041E6
%endif
poll_keyboard_store_pending_key:
	mov	[pending_key],al		; 041E8
	mov	byte [key_pending],0x1	; 041EB
	mov	al,0xff			; 041F0
	pop	bp			; 041F2
	ret				; 041F3
poll_keyboard_handle_esc:
	mov	ah,0x7			; 041F4
	int	0x21			; 041F6
	db	0x33, 0xC0		; 041F8 xor ax,ax
	pop	bp			; 041FA
	ret				; 041FB

; ---- function wait_for_key ----
; Blocking key read. Checks pending key buffer [0xDF42]/[0xDF43] first,
; then falls back to INT 21h/07h for blocking read.
; Maps arrow keys: left (0x4B)->'4', right (0x4D)->'6'.
; Flushes keyboard buffer after reading.
; Output: AX = key code
wait_for_key:
; Same address as wait_for_key; re-entered after an extended key other than left/right arrow.
wait_for_key_retry:
	mov	al,[pending_key]		; 041FC
	cmp	byte [key_pending],0x0	; 041FF
	jnz	short wait_for_key_have_key		; 04204 jnz 0x420a
	mov	ah,0x7			; 04206
	int	0x21			; 04208
wait_for_key_have_key:
	mov	ah,0x0			; 0420A
	mov	byte [key_pending],0x0	; 0420C
	cmp	al,0x0			; 04211
	jz	short wait_for_key_read_extended_scancode		; 04213 jz 0x4217
	jmp	short wait_for_key_flush_and_return		; 04215 jmp 0x422d
wait_for_key_read_extended_scancode:
	mov	ah,0x7			; 04217
	int	0x21			; 04219
	cmp	al,0x4b			; 0421B
	jnz	short wait_for_key_check_right_arrow		; 0421D jnz 0x4225
%ifdef HEBREW
	mov	al,0x36			; arrows swapped to match the mirrored screen
%else
	mov	al,0x34			; 0421F
%endif
	mov	ah,0x0			; 04221
	jmp	short wait_for_key_flush_and_return		; 04223 jmp 0x422d
wait_for_key_check_right_arrow:
	cmp	al,0x4d			; 04225
	jnz	short wait_for_key_retry		; 04227 jnz 0x41fc
%ifdef HEBREW
	mov	al,0x34			; arrows swapped to match the mirrored screen
%else
	mov	al,0x36			; 04229
%endif
	mov	ah,0x0			; 0422B
wait_for_key_flush_and_return:
	push	ax			; 0422D
	call	flush_keyboard		; 0422E
	pop	ax			; 04231
	ret				; 04232

; ---- function flush_keyboard ----
; Drains all pending keystrokes by calling check_ctrl_q in a loop.
; Clears pending key flag [0xDF43] when done.
flush_keyboard:
flush_keyboard_drain_loop:
	call	check_ctrl_q		; 04233
	nop				; 04236
	nop				; 04237
	nop				; 04238
	jnz	short flush_keyboard_drain_loop		; 04239 jnz 0x4233
	mov	byte [key_pending],0x0	; 0423B
	ret				; 04240

; ---- function play_sound_5_forced ----
; Plays sound 5 (play_sound_buzz_low) with sound_mode forced to 0, so it is heard even when muted, then restores sound_mode.
; Reads no key. Callers use it as an acknowledge beep for a key already read: Ctrl+R, Ctrl+S and Ctrl+V in poll_keyboard (0x417F, 0x4190, 0x41B2), 'j' and 'k' in key_to_move (0x1DFD, 0x1E14).
play_sound_5_forced:
	push	word [sound_mode]		; 04241
	mov	byte [sound_mode],0x0	; 04245
	mov	ax,0x5			; 0424A
	push	ax			; 0424D
	call	play_sound		; 0424E
	pop	ax			; 04251
	pop	word [sound_mode]		; 04252
	ret				; 04256

; ---- function noop_stub ----
; Empty function placeholder. Single `ret` instruction.
noop_stub:
	ret				; 04257
; Not an instruction boundary: 04258-0425D are the bytes 00 B4 0E CD 21 C3.
; 00 is a stray byte of unknown purpose; the rest is mov ah,0x0E / int 0x21 / ret,
; i.e. a DOS select-disk stub at 04259 (DL = drive, AL = logical drive count).
; No call, jump or stored address reaches 04258 or 04259, so it looks dead.
	add	[si+0xcd0e],dh		; 04258
	and	bx,ax			; 0425C

; ---- function detect_hercules_vsync ----
; Probes a port for Hercules vsync bit transition (bit change detection).
; Reads port repeatedly watching for the specified bit to change state.
;
; Input: DX = port address, BL = bit mask
; Output: CF=0 if transition detected (Hercules present), CF=1 if timeout
detect_hercules_vsync:
	in	al,dx			; 0425E
	db	0x22, 0xC3		; 0425F and al,bl
	xchg	ah,al			; 04261
	mov	cx,0x7530		; 04263
; polls status bit for a transition, up to 30000 reads
detect_hercules_vsync_poll_loop:
	in	al,dx			; 04266
	db	0x22, 0xC3		; 04267 and al,bl
	db	0x3A, 0xE0		; 04269 cmp ah,al
	jnz	short detect_hercules_vsync_transition_seen		; 0426B jnz 0x4271
	loop	0x4266			; 0426D
	stc				; 0426F
	ret				; 04270
detect_hercules_vsync_transition_seen:
	clc				; 04271
	ret				; 04272

; ---- function video_set_mode_4 ----
; Sets CGA mode 4 (320x200, 4-color graphics).
; Configures Hercules compatibility register (port 0x3BF),
; sets BIOS equipment flags for CGA, calls INT 10h to set mode,
; tests video memory with pattern 0x55AA to verify hardware.
; Builds scanline lookup table at [0xDF59] (200 entries, CGA interleaved).
;
; Output: CF=0 success, CF=1 failure (no CGA hardware)
video_set_mode_4:
	mov	dx,0x3bf		; 04273
	mov	al,0x0			; 04276
	out	dx,al			; 04278
	push	ds			; 04279
	mov	ax,0x40			; 0427A
	mov	ds,ax			; 0427D
	mov	si,0x10			; 0427F
	mov	al,[si]			; 04282
	and	al,0xcf			; 04284
	or	al,0x20			; 04286
	mov	[si],al			; 04288
	pop	ds			; 0428A
	mov	ah,0x0			; 0428B
	mov	al,0x4			; 0428D
	int	0x10			; 0428F
	push	es			; 04291
	mov	es,word [video_segment]	; 04292
	mov	di,0x1f40		; 04296
	db	0x8B, 0xD7		; 04299 mov dx,di
	mov	cx,0x5a			; 0429B
	db	0x8B, 0xD9		; 0429E mov bx,cx
	cld				; 042A0
	mov	ax,0x55aa		; 042A1
	rep	stosw			; 042A4
	db	0x8B, 0xFA		; 042A6 mov di,dx
	db	0x8B, 0xCB		; 042A8 mov cx,bx
	repe	scasw			; 042AA
	pop	es			; 042AC
	jcxz	short video_set_mode_4_memory_ok_build_scanline_table		; 042AD jcxz 0x42b1
	stc				; 042AF
	ret				; 042B0
video_set_mode_4_memory_ok_build_scanline_table:
	mov	word [hercules_active],0x0	; 042B1
	mov	ax,0x0			; 042B7
	mov	dx,0x2000		; 042BA
	mov	cx,0xc8			; 042BD
	lea	bx,[scanline_offsets]		; 042C0
; 200 entries, swaps odd/even CGA bank offsets
video_set_mode_4_scanline_table_loop:
	mov	[bx],ax			; 042C4
	add	bx,0x2			; 042C6
	db	0x05, 0x50, 0x00	; 042C9 add ax,0x50
	xchg	ax,dx			; 042CC
	loop	0x42c4			; 042CD
	clc				; 042CF
	ret				; 042D0

; ---- function init_hercules_mode ----
; Initializes Hercules graphics mode. Programs CRTC registers for graphics,
; builds 4-bank scanline LUT (banks at +0x0000, +0x2000, +0x4000, +0x6000),
; clears video memory, and enables display.
;
; Output: CF=0 success, CF=1 failure (no Hercules detected)
init_hercules_mode:
	mov	dx,0x3bf		; 042D1
	mov	al,0x3			; 042D4
	out	dx,al			; 042D6
	mov	bl,[saved_equipment_byte]		; 042D7
	push	ds			; 042DB
	mov	ax,0x40			; 042DC
	mov	ds,ax			; 042DF
	mov	si,0x10			; 042E1
	mov	[si],bl			; 042E4
	pop	ds			; 042E6
	mov	dx,0x3ba		; 042E7
	mov	bl,0x80			; 042EA
	call	detect_hercules_vsync	; 042EC
	jnc	short init_hercules_mode_detected		; 042EF jnc 0x42f3
	stc				; 042F1
	ret				; 042F2
init_hercules_mode_detected:
	mov	word [hercules_active],0x1	; 042F3
	push	si			; 042F9
	push	di			; 042FA
	mov	cx,0x32			; 042FB
	lea	bx,[scanline_offsets]		; 042FE
	mov	si,0x658		; 04302
	mov	di,0x2658		; 04305
	mov	ax,0x4658		; 04308
	mov	dx,0x6658		; 0430B
; writes 4 scanline offsets per iteration
init_hercules_mode_scanline_table_loop:
	mov	[bx],si			; 0430E
	mov	[bx+0x2],di		; 04310
	mov	[bx+0x4],ax		; 04313
	mov	[bx+0x6],dx		; 04316
	add	si,0x5a			; 04319
	add	di,0x5a			; 0431C
	db	0x05, 0x5A, 0x00	; 0431F add ax,0x5a
	add	dx,0x5a			; 04322
	add	bx,0x8			; 04325
	loop	0x430e			; 04328
	call	clear_video_buffer	; 0432A
	lea	si,[hercules_crtc_regs]		; 0432D
	call	program_crtc_registers	; 04331
	mov	dx,0x3b8		; 04334
	mov	al,0x8a			; 04337
	out	dx,al			; 04339
	pop	di			; 0433A
	pop	si			; 0433B
	clc				; 0433C
	ret				; 0433D

; ---- function program_crtc_registers ----
; Programs 12 CRTC (6845) registers from a table pointed to by SI.
; Writes register index to port 0x3B4, then value to port 0x3B5.
;
; Input: SI = pointer to 12 register values, DX = 0x3B4 (CRTC index port)
program_crtc_registers:
	mov	dx,0x3b4		; 0433E
	mov	cx,0xc			; 04341
	db	0x32, 0xE4		; 04344 xor ah,ah
; outputs 12 index/value pairs to the 6845 CRTC
program_crtc_registers_loop:
	db	0x8A, 0xC4		; 04346 mov al,ah
	out	dx,al			; 04348
	inc	dx			; 04349
	lodsb				; 0434A
	out	dx,al			; 0434B
	inc	ah			; 0434C
	dec	dx			; 0434E
	loop	0x4346			; 0434F
	ret				; 04351

; ---- function check_graphics_card ----
; Detects available graphics adapter. Tries CGA mode 4 first, falls back
; to Hercules. Saves equipment flags and video mode for later restore.
;
; Output: AX = 0 if no graphics card, or 'A'+mode if found
; AL on success is a leftover value, not a mode: AX ends up 0x81 for CGA and 0xCB for Hercules.
check_graphics_card:
	int	0x11			; 04352
	mov	[saved_equipment_byte],al		; 04354
	mov	ah,0xf			; 04357
	int	0x10			; 04359
	mov	[saved_video_mode],al		; 0435B
	call	video_set_mode_4	; 0435E
	jnc	short check_graphics_card_adapter_found		; 04361 jnc 0x4368
	call	init_hercules_mode	; 04363
	jc	short check_graphics_card_no_adapter		; 04366 jc 0x436d
check_graphics_card_adapter_found:
	db	0x32, 0xE4		; 04368 xor ah,ah
	add	al,0x41			; 0436A
	ret				; 0436C
check_graphics_card_no_adapter:
	call	restore_video_mode		; 0436D
	db	0x33, 0xC0		; 04370 xor ax,ax
	ret				; 04372

; ---- function restore_video_mode ----
; Restores the original video state and selects a disk drive; initialises nothing.
; Clears the video buffer, writes saved_equipment_byte back to 0040:0010,
; sets saved_video_mode via INT 10h/00h, and selects exit_disk_drive via INT 21h/0Eh.
; Its one caller is check_graphics_card's no-adapter path at 0x436D.
restore_video_mode:
	call	clear_video_buffer	; 04373
	mov	bl,[saved_equipment_byte]		; 04376
	push	ds			; 0437A
	mov	ax,0x40			; 0437B
	mov	ds,ax			; 0437E
	mov	si,0x10			; 04380
	mov	[si],bl			; 04383
	pop	ds			; 04385
	mov	ah,0x0			; 04386
	mov	al,[saved_video_mode]		; 04388
	int	0x10			; 0438B
	mov	dl,[exit_disk_drive]		; 0438D
	mov	ah,0xe			; 04391
	int	0x21			; 04393
	ret				; 04395

; ---- function clear_video_buffer ----
; Clears 32KB of video memory to zero using REP STOSW.
; Uses the video segment stored at [0xDF48].
clear_video_buffer:
	push	di			; 04396
	push	es			; 04397
	mov	es,word [video_segment]	; 04398
	mov	cx,0x4000		; 0439C
	mov	ax,0x0			; 0439F
	db	0x8B, 0xF8		; 043A2 mov di,ax
	cld				; 043A4
	rep	stosw			; 043A5
	pop	es			; 043A7
	pop	di			; 043A8
	ret				; 043A9

; ---- function check_hit_zone ----
; Determines whether a combat move hits the enemy based on move type and distance.
; Maps move index + distance to a hit result using lookup tables.
;
; Input:
;   [bp+4] = move index (adjusted: +3 if <=2, -3 if >2 with distance tweak)
;   [bp+6] = distance between player and enemy
;   [bp+8] = direction flag (pointer to zone table base)
; Output:
;   AX = hit result: 0=miss, 1-4=hit types (4=out of range, 3=light hit)
;   Heavy/medium/close/advancing/retreating hits from lookup tables
; [bp+8] is a byte index (enemy_frame_attr from the caller) into the threshold table at 0xE0F8 and the result-index table at 0xE112.
; Distance is rounded down to a multiple of 4 after the adjustment. Result 4 is returned below the threshold, 0 above threshold + 0x11.
check_hit_zone:
	push	bp			; 043AA
	db	0x8B, 0xEC		; 043AB mov bp,sp
	cmp	byte [bp+0x4],0x2	; 043AD
	jg	short check_hit_zone_adjust_moves_above_two		; 043B1 jg 0x43b9
	add	byte [bp+0x4],0x3	; 043B3
	jmp	short check_hit_zone_lookup_threshold		; 043B7 jmp 0x43c9
check_hit_zone_adjust_moves_above_two:
	sub	byte [bp+0x4],0x3	; 043B9
	jz	short check_hit_zone_lookup_threshold		; 043BD jz 0x43c9
	sub	word [bp+0x6],0x4	; 043BF
	cmp	byte [bp+0x4],0x1	; 043C3
	jz	short check_hit_zone_lookup_threshold		; 043C7 jz 0x43c9
check_hit_zone_lookup_threshold:
	mov	si,[bp+0x8]		; 043C9
	db	0x81, 0x66, 0x06, 0xFC, 0xFF	; 043CC and word [bp+0x6],0xfffc
	db	0x33, 0xDB		; 043D1 xor bx,bx
	db	0x33, 0xD2		; 043D3 xor dx,dx
	db	0x33, 0xC0		; 043D5 xor ax,ax
	mov	bl,[si+hit_zone_classes]		; 043D7
	mov	dl,[si+hit_zone_thresholds]		; 043DB
	cmp	[bp+0x6],dx		; 043DF
	jl	short check_hit_zone_below_threshold		; 043E2 jl 0x443d
	jnz	short check_hit_zone_above_threshold		; 043E4 jnz 0x4402
check_hit_zone_near_band_by_move:
	cmp	word [bp+0x4],0x4	; 043E6
	jng	short check_hit_zone_near_band_moves_below_five		; 043EA jng 0x43f2
	mov	al,[bx+hit_result_near_anim_4]		; 043EC
	jmp	short check_hit_zone_return		; 043F0 jmp 0x443f
check_hit_zone_near_band_moves_below_five:
	cmp	word [bp+0x4],0x3	; 043F2
	jl	short check_hit_zone_near_band_moves_below_three		; 043F6 jl 0x43fe
	mov	al,[bx+hit_result_near_anim_2_3]		; 043F8
	jmp	short check_hit_zone_return		; 043FC jmp 0x443f
check_hit_zone_near_band_moves_below_three:
	mov	al,0x3			; 043FE
	jmp	short check_hit_zone_return		; 04400 jmp 0x443f
check_hit_zone_above_threshold:
	add	dx,0x11			; 04402
	cmp	[bp+0x6],dx		; 04405
	jg	short check_hit_zone_return		; 04408 jg 0x443f
	cmp	word [bp+0x4],0x1	; 0440A
	jnz	short check_hit_zone_far_band_move_not_one		; 0440E jnz 0x4416
	mov	al,[bx+hit_result_far_anim_6]		; 04410
	jmp	short check_hit_zone_return		; 04414 jmp 0x443f
check_hit_zone_far_band_move_not_one:
	cmp	word [bp+0x4],0x2	; 04416
	jg	short check_hit_zone_far_band_moves_above_two		; 0441A jg 0x442f
	mov	al,[bx+hit_result_far_anim_5_7]		; 0441C
	cmp	bl,0x1			; 04420
	jnz	short check_hit_zone_return		; 04423 jnz 0x443f
	cmp	byte [bp+0x4],0x2	; 04425
	jnz	short check_hit_zone_return		; 04429 jnz 0x443f
	mov	al,0x0			; 0442B
	jmp	short check_hit_zone_return		; 0442D jmp 0x443f
check_hit_zone_far_band_moves_above_two:
	sub	dx,0x4			; 0442F
	cmp	[bp+0x6],dx		; 04432
	jl	short check_hit_zone_near_band_by_move		; 04435 jl 0x43e6
	mov	al,[bx+hit_result_far_edge]		; 04437
	jmp	short check_hit_zone_return		; 0443B jmp 0x443f
check_hit_zone_below_threshold:
	mov	al,0x4			; 0443D
check_hit_zone_return:
	pop	bp			; 0443F
	ret				; 04440

; ---- function add_figure_to_scene ----
; Adds a figure entry to the scene animation list buffer at [0xBB2E].
; Shifts existing entries up by 4 bytes, then writes a new 4-byte entry
; containing the figure's screen X position and character code.
;
; Input:
;   [bp+4] = character type (0=player, 1=enemy)
;   [bp+6] = figure/pose index
; Character codes: 0x61-0x62 for player, 0x63-0x64 for enemy
; Special: scene_index 7 (level 3 boss) adjusts X by -0x23 and Y by +8
add_figure_to_scene:
	push	bp			; 04441
	db	0x8B, 0xEC		; 04442 mov bp,sp
	mov	bx,[bp+0x6]		; 04444
	shl	bx,1			; 04447
	cmp	word [player_faces_right],0x1		; 04449
	jnz	short add_figure_to_scene_select_character		; 0444E jnz 0x4458
	cmp	bx,0xc			; 04450
	jl	short add_figure_to_scene_select_character		; 04453 jl 0x4458
	add	bx,0xc			; 04455
add_figure_to_scene_select_character:
	cmp	word [bp+0x4],0x0	; 04458
	jnz	short add_figure_to_scene_enemy		; 0445C jnz 0x446d
	mov	ax,[player_x]		; 0445E
	mov	cl,0x61			; 04461
	cmp	word [bp+0x6],0x3	; 04463
	jnl	short add_figure_to_scene_prepare_shift		; 04467 jnl 0x4483
	inc	cl			; 04469
	jmp	short add_figure_to_scene_prepare_shift		; 0446B jmp 0x4483
add_figure_to_scene_enemy:
	mov	ax,[enemy_x]		; 0446D
	mov	cl,0x63			; 04470
	cmp	word [special_enemy_active],0x0	; 04472
	jz	short add_figure_to_scene_enemy_pick_code		; 04477 jz 0x447c
	mov	bx,0xe			; 04479
add_figure_to_scene_enemy_pick_code:
	cmp	bx,0x12			; 0447C
	jnl	short add_figure_to_scene_prepare_shift		; 0447F jnl 0x4483
	inc	cl			; 04481
add_figure_to_scene_prepare_shift:
	mov	si,[figure_list_cursor]		; 04483
	db	0x8B, 0xFE		; 04487 mov di,si
	add	di,0x4			; 04489
add_figure_to_scene_shift_entries_loop:
	mov	dl,[si+frame_sound_id]		; 0448C
	mov	[di+frame_sound_id],dl		; 04490
	dec	si			; 04494
	dec	di			; 04495
	cmp	si,[anim_data_limit]		; 04496
	jnc	short add_figure_to_scene_shift_entries_loop		; 0449A jnc 0x448c
	inc	si			; 0449C
	add	ax,[bx+figure_x_offsets]		; 0449D
	cmp	word [scene_index],0x7	; 044A1
	jnz	short add_figure_to_scene_store_code_and_x		; 044A6 jnz 0x44ab
	db	0x2D, 0x23, 0x00	; 044A8 sub ax,0x23
add_figure_to_scene_store_code_and_x:
	mov	[si+screen_wipe_flag],ax		; 044AB
	mov	[si+frame_sound_id],cl		; 044AF
	shr	bx,1			; 044B3
	mov	cl,[bx+figure_screen_y]		; 044B5
	cmp	word [scene_index],0x7	; 044B9
	jnz	short add_figure_to_scene_store_y_and_advance		; 044BE jnz 0x44c3
	add	cl,0x8			; 044C0
add_figure_to_scene_store_y_and_advance:
	mov	[si+figure_list],cl		; 044C3
	add	word [figure_list_cursor],0x4	; 044C7
	add	word [anim_data_limit],0x4	; 044CC
	pop	bp			; 044D1
	ret				; 044D2

; ---- function check_joystick ----
; Reads joystick input and maps to key codes for combat controls.
;
; Input: [bp+4] = mode (0=full check with direction mapping, non-0=just read buttons)
; Handles debug axis swaps via flags [0xE1AB]-[0xE1AE].
; Direction+button mapping:
;   Right+Up+Button1 = '&' (0x26, special attack)
;   Button1+Up = 'w', Button1+Down = 'x', Button1 alone = 's'
;   Button2+Up = 'q', Button2+Down = 'z', Button2 alone = 'a'
;   Left = '4', Right = '6'
;   Up alone (certain anims) = '0' or space
; Output: AX = mapped key code, or 0 if no input
; Has no frame of its own, so [bp+4] is the caller's (poll_keyboard's) argument; the value pushed just before the call is unused.
; Right+Up alone gives '&' (no button needed). The button tested at 0xE1A6 with anim >= 0x40 gives 'b'.
check_joystick:
	call	read_joystick		; 044D3
	cmp	word [bp+0x4],0x0	; 044D6
	jz	short check_joystick_map_input		; 044DA jz 0x44dd
	ret				; 044DC
check_joystick_map_input:
	cmp	al,0x0			; 044DD
	jnz	short check_joystick_maybe_swap_left_right		; 044DF jnz 0x44ef
	cmp	word [player_anim_id],0x40	; 044E1
	jnc	short check_joystick_no_input_return_space		; 044E6 jnc 0x44eb
	db	0x33, 0xC0		; 044E8 xor ax,ax
	ret				; 044EA
check_joystick_no_input_return_space:
	mov	ax,0x20			; 044EB
	ret				; 044EE
check_joystick_maybe_swap_left_right:
	cmp	byte [joy_swap_left_right],0x0	; 044EF
	jz	short check_joystick_maybe_swap_up_down		; 044F4 jz 0x4500
	mov	al,[joy_axis_left]		; 044F6
	xchg	al,[joy_axis_right]		; 044F9
	mov	[joy_axis_left],al		; 044FD
check_joystick_maybe_swap_up_down:
	cmp	byte [joy_swap_up_down],0x0	; 04500
	jz	short check_joystick_maybe_swap_axes		; 04505 jz 0x4511
	mov	al,[joy_axis_up]		; 04507
	xchg	al,[joy_axis_down]		; 0450A
	mov	[joy_axis_up],al		; 0450E
check_joystick_maybe_swap_axes:
	cmp	byte [joy_swap_axes],0x0	; 04511
	jz	short check_joystick_maybe_swap_buttons		; 04516 jz 0x452c
	mov	al,[joy_axis_left]		; 04518
	xchg	al,[joy_axis_up]		; 0451B
	mov	[joy_axis_left],al		; 0451F
	mov	al,[joy_axis_right]		; 04522
	xchg	al,[joy_axis_down]		; 04525
	mov	[joy_axis_right],al		; 04529
check_joystick_maybe_swap_buttons:
	cmp	byte [joy_swap_buttons],0x0	; 0452C
	jz	short check_joystick_check_right_up_combo		; 04531 jz 0x453d
	mov	al,[joy_btn_bit4]		; 04533
	xchg	al,[joy_btn_bit5]		; 04536
	mov	[joy_btn_bit4],al		; 0453A
check_joystick_check_right_up_combo:
	cmp	byte [joy_axis_right],0x1	; 0453D
	jnz	short check_joystick_check_b_key_button		; 04542 jnz 0x456d
	cmp	byte [joy_axis_up],0x1	; 04544
	jnz	short check_joystick_check_b_key_button		; 04549 jnz 0x456d
	cmp	word [combat_phase],0x0		; 0454B
	jnz	short check_joystick_return_ampersand_key		; 04550 jnz 0x4569
	cmp	word [special_enemy_active],0x0	; 04552
	jnz	short check_joystick_right_up_return_none		; 04557 jnz 0x4566
	mov	dx,[enemy_x]		; 04559
	sub	dx,[player_x]		; 0455D
	cmp	dx,0x64			; 04561
	jnc	short check_joystick_return_ampersand_key		; 04564 jnc 0x4569
check_joystick_right_up_return_none:
	jmp	near check_joystick_return_none			; 04566
check_joystick_return_ampersand_key:
	mov	ax,0x26			; 04569
	ret				; 0456C
check_joystick_check_b_key_button:
	cmp	word [player_anim_id],0x3f	; 0456D
	jng	short check_joystick_check_left		; 04572 jng 0x457f
	cmp	byte [joy_btn_bit5],0x1	; 04574
	jnz	short check_joystick_check_left		; 04579 jnz 0x457f
	mov	ax,0x62			; 0457B
	ret				; 0457E
check_joystick_check_left:
	cmp	byte [joy_axis_left],0x1	; 0457F
	jnz	short check_joystick_check_right		; 04584 jnz 0x458a
	mov	ax,0x34			; 04586
	ret				; 04589
check_joystick_check_right:
	cmp	byte [joy_axis_right],0x1	; 0458A
	jnz	short check_joystick_check_wxs_button		; 0458F jnz 0x4595
	mov	ax,0x36			; 04591
	ret				; 04594
check_joystick_check_wxs_button:
	cmp	byte [joy_btn_bit4],0x1	; 04595
	jnz	short check_joystick_check_qza_button		; 0459A jnz 0x45b6
	cmp	byte [joy_axis_up],0x1	; 0459C
	jnz	short check_joystick_wxs_button_check_down		; 045A1 jnz 0x45a7
	mov	ax,0x77			; 045A3
	ret				; 045A6
check_joystick_wxs_button_check_down:
	cmp	byte [joy_axis_down],0x1	; 045A7
	jnz	short check_joystick_wxs_button_alone		; 045AC jnz 0x45b2
	mov	ax,0x78			; 045AE
	ret				; 045B1
check_joystick_wxs_button_alone:
	mov	ax,0x73			; 045B2
	ret				; 045B5
check_joystick_check_qza_button:
	cmp	byte [joy_btn_bit5],0x1	; 045B6
	jnz	short check_joystick_check_up_alone		; 045BB jnz 0x45d7
	cmp	byte [joy_axis_up],0x1	; 045BD
	jnz	short check_joystick_qza_button_check_down		; 045C2 jnz 0x45c8
	mov	ax,0x71			; 045C4
	ret				; 045C7
check_joystick_qza_button_check_down:
	cmp	byte [joy_axis_down],0x1	; 045C8
	jnz	short check_joystick_qza_button_alone		; 045CD jnz 0x45d3
	mov	ax,0x7a			; 045CF
	ret				; 045D2
check_joystick_qza_button_alone:
	mov	ax,0x61			; 045D3
	ret				; 045D6
check_joystick_check_up_alone:
	cmp	byte [joy_axis_up],0x0	; 045D7
	jz	short check_joystick_return_none		; 045DC jz 0x4616
	cmp	word [player_anim_id],0x41	; 045DE
	jz	short check_joystick_return_none		; 045E3 jz 0x4616
	cmp	word [player_anim_id],0x42	; 045E5
	jz	short check_joystick_return_none		; 045EA jz 0x4616
	cmp	word [player_anim_id],0x46	; 045EC
	jnz	short check_joystick_up_check_enemy_range		; 045F1 jnz 0x45f7
	mov	ax,0x30			; 045F3
	ret				; 045F6
check_joystick_up_check_enemy_range:
	cmp	word [special_enemy_active],0x0	; 045F7
	jnz	short check_joystick_return_none		; 045FC jnz 0x4616
	cmp	word [combat_phase],0x0		; 045FE
	jnz	short check_joystick_return_space_key		; 04603 jnz 0x4612
	mov	dx,[enemy_x]		; 04605
	sub	dx,[player_x]		; 04609
	cmp	dx,0x64			; 0460D
	jc	short check_joystick_return_none		; 04610 jc 0x4616
check_joystick_return_space_key:
	mov	ax,0x20			; 04612
	ret				; 04615
check_joystick_return_none:
	db	0x33, 0xC0		; 04616 xor ax,ax
	ret				; 04618
