; Screen drawing, sprites, backgrounds, animation display


; ---- function clear_screen ----
; Fills the offscreen buffer (DS:0x337) with zeros.
; No parameters. Preserves ES.
; Buffer size: 0x3E80 bytes (320x200 CGA, 2 bits/pixel = 16000 bytes).
clear_screen:
	push	es			; 00B4E
	push	ds			; 00B4F
	pop	es			; 00B50
	lea	di,[0x337]		; 00B51
	db	0x33, 0xC0		; 00B55 xor ax,ax
	mov	cx,0x1f40		; 00B57
	rep	stosw			; 00B5A
	pop	es			; 00B5C
	ret				; 00B5D

; ---- function advance_anim_frame ----
; Reads the next frame data from two animation sequences.
; No parameters. No stack frame.
;
; Uses globals:
;   [0x421e] = read position for sequence 1 (base 0x443c)
;   [0x4220] = read position for sequence 2 (base 0x893a, via [si-0x76c6])
;   [0x422c] = repeat counter for seq 1 (0x7B = run-length marker)
;   [0x422d] = repeat value for seq 1
;   [0x422e] = repeat counter for seq 2
;   [0x422f] = repeat value for seq 2
;
; Returns:
;   DL = frame data from sequence 1
;   AL = frame data from sequence 2
advance_anim_frame:
	cmp	byte [0x422c],0x0	; 00B5E
	jz	short loc_00B70		; 00B63 jz 0xb70
	mov	dl,[0x422d]		; 00B65
	dec	byte [0x422c]		; 00B69
	jmp	short loc_00B95		; 00B6D jmp 0xb95
	nop				; 00B6F
loc_00B70:
	mov	si,[0x421e]		; 00B70
	mov	dl,[si+0x443c]		; 00B74
	inc	si			; 00B78
	cmp	dl,0x7b			; 00B79
	jnz	short loc_00B91		; 00B7C jnz 0xb91
	mov	dl,[si+0x443d]		; 00B7E
	mov	[0x422c],dl		; 00B82
	mov	dl,[si+0x443c]		; 00B86
	mov	[0x422d],dl		; 00B8A
	add	si,0x2			; 00B8E
loc_00B91:
	mov	[0x421e],si		; 00B91
loc_00B95:
	cmp	byte [0x422e],0x0	; 00B95
	jz	short loc_00BA6		; 00B9A jz 0xba6
	mov	al,[0x422f]		; 00B9C
	dec	byte [0x422e]		; 00B9F
	jmp	short loc_00BC8		; 00BA3 jmp 0xbc8
	nop				; 00BA5
loc_00BA6:
	mov	si,[0x4220]		; 00BA6
	mov	al,[si+0x893a]		; 00BAA
	inc	si			; 00BAE
	cmp	al,0x7b			; 00BAF
	jnz	short loc_00BC4		; 00BB1 jnz 0xbc4
	mov	al,[si+0x893b]		; 00BB3
	mov	[0x422e],al		; 00BB7
	mov	al,[si+0x893a]		; 00BBA
	mov	[0x422f],al		; 00BBE
	add	si,0x2			; 00BC1
loc_00BC4:
	mov	[0x4220],si		; 00BC4
loc_00BC8:
	ret				; 00BC8

; ---- function render_figures ----
; Draws all active figures from the figure slot list to screen.
; No parameters. No stack frame.
;
; Iterates 4-byte slots starting at index 3 in the figure list.
; Each slot: [slot+0]=figure_id (0xFF=end), [slot+1..2]=position, [slot+3]=flags.
; Calls draw_sprite or draw_sprite_mirrored for each figure, then
; transfers to screen via update_display, draw_background, or blit_buffer_to_vram
; depending on render mode [0xbb31].
;
; Uses globals:
;   [0xbb2e] = current slot index (starts at 3)
;   [0xbb30] = vsync wait count
;   [0xbb31] = render mode (0=normal, nonzero=blit)
;   [0xbb32] = first figure ID (passed to prepare_screen_buffer)
;   [0xee]   = display mode (0=background copy, nonzero=buffer copy)
render_figures:
	mov	word [0xbb2e],0x3	; 00BC9
	mov	al,[0xbb32]		; 00BCF
	call	prepare_screen_buffer	; 00BD2
loc_00BD5:
	mov	si,[0xbb2e]		; 00BD5
	mov	al,[si+0xbb30]		; 00BD9
	cmp	al,0xff			; 00BDD
	jz	short loc_00C14		; 00BDF jz 0xc14
	mov	ah,0x0			; 00BE1
	mov	cl,[si+0xbb33]		; 00BE3
	mov	ch,0x0			; 00BE7
	push	cx			; 00BE9
	mov	dx,[si+0xbb31]		; 00BEA
	test	dx,0x8000		; 00BEE
	jnz	short loc_00C05		; 00BF2 jnz 0xc05
	test	dx,0x4000		; 00BF4
	jz	short loc_00C05		; 00BF8 jz 0xc05
	xor	dx,0x4000		; 00BFA
	push	dx			; 00BFE
	push	ax			; 00BFF
	call	draw_sprite		; 00C00
	jmp	short loc_00C0A		; 00C03 jmp 0xc0a
loc_00C05:
	push	dx			; 00C05
	push	ax			; 00C06
	call	draw_sprite_mirrored	; 00C07
loc_00C0A:
	add	sp,0x6			; 00C0A
	add	word [0xbb2e],0x4	; 00C0D
	jmp	short loc_00BD5		; 00C12 jmp 0xbd5
loc_00C14:
	cmp	byte [0xbb31],0x0	; 00C14
	jnz	short loc_00C42		; 00C19 jnz 0xc42
	cmp	word [0xee],0x0		; 00C1B
	jz	short loc_00C32		; 00C20 jz 0xc32
	call	update_display		; 00C22
	mov	al,[0xbb30]		; 00C25
	mov	ah,0x0			; 00C28
	push	ax			; 00C2A
	call	wait_vsync		; 00C2B
	add	sp,0x2			; 00C2E
	ret				; 00C31
loc_00C32:
	call	draw_background		; 00C32
	mov	al,[0xbb30]		; 00C35
	mov	ah,0x0			; 00C38
	push	ax			; 00C3A
	call	wait_vsync		; 00C3B
	add	sp,0x2			; 00C3E
	ret				; 00C41
loc_00C42:
	call	blit_buffer_to_vram	; 00C42
	mov	al,[0xbb30]		; 00C45
	mov	ah,0x0			; 00C48
	push	ax			; 00C4A
	call	wait_vsync		; 00C4B
	add	sp,0x2			; 00C4E
	ret				; 00C51

; ---- function prepare_screen_buffer ----
; Prepares the offscreen buffer and background for the current scene.
; Dispatches rendering based on scene state [0xea].
;
; Parameters:
;   AL = figure/render mode value (from [0xbb32])
;
; Uses globals:
;   [0xea]   = scene state (0-1: fill pattern, 2: clear, 3+: sky pattern)
;   [0xe4]   = current background ID
;   [0xbb2a] = last rendered background ID (skip redraw if same)
;   [0xbcd0] = scene transition pending flag
;
; ES = DS on entry (set internally). Preserves ES on exit.
prepare_screen_buffer:
	push	es			; 00C52
	push	ds			; 00C53
	pop	es			; 00C54
	cmp	word [0xee],0x1		; 00C55
	jnz	short loc_00C7F		; 00C5A jnz 0xc7f
	cmp	word [0xea],0x2		; 00C5C
	jnl	short loc_00C72		; 00C61 jnl 0xc72
	mov	cx,0xc80		; 00C63
	mov	ax,0x5555		; 00C66
	lea	di,[0x337]		; 00C69
	rep	stosw			; 00C6D
	jmp	short loc_00C7F		; 00C6F jmp 0xc7f
	nop				; 00C71
loc_00C72:
	call	clear_screen		; 00C72
	cmp	byte [0xbcd0],0x0	; 00C75
	jnz	short loc_00C7F		; 00C7A jnz 0xc7f
	call	scene_transition	; 00C7C
loc_00C7F:
	cmp	word [0xea],0x2		; 00C7F
	jnl	short loc_00CE6		; 00C84 jnl 0xce6
	mov	ax,[0xe4]		; 00C86
	cmp	ax,[0xbb2a]		; 00C89
	jz	short loc_00CBB		; 00C8D jz 0xcbb
	mov	cx,0xf00		; 00C8F
	mov	ax,0x5555		; 00C92
	lea	di,[0xd37]		; 00C95
	rep	stosw			; 00C99
	mov	cx,0x550		; 00C9B
	lea	si,[0xacb2]		; 00C9E
	lea	di,[0x1c37]		; 00CA2
	rep	movsw			; 00CA6
	lea	di,[0x2457]		; 00CA8
	mov	ax,0xffff		; 00CAC
	mov	cx,0x28			; 00CAF
	rep	stosw			; 00CB2
	db	0x33, 0xC0		; 00CB4 xor ax,ax
	mov	cx,0x78			; 00CB6
	rep	stosw			; 00CB9
loc_00CBB:
	call	scroll_screen		; 00CBB
	lea	di,[0x3357]		; 00CBE
	mov	bl,0xf			; 00CC2
	mov	dx,0x9999		; 00CC4
	mov	ax,[0xe4]		; 00CC7
	db	0x25, 0x01, 0x00	; 00CCA and ax,0x1
	jz	short loc_00CD2		; 00CCD jz 0xcd2
	mov	dx,0x6666		; 00CCF
loc_00CD2:
	db	0x8B, 0xC2		; 00CD2 mov ax,dx
	mov	cx,0x28			; 00CD4
	rep	stosw			; 00CD7
	not	ax			; 00CD9
	mov	cx,0x28			; 00CDB
	rep	stosw			; 00CDE
	dec	bl			; 00CE0
	jnz	short loc_00CD2		; 00CE2 jnz 0xcd2
	pop	es			; 00CE4
	ret				; 00CE5
loc_00CE6:
	push	ax			; 00CE6
	call	scroll_screen		; 00CE7
	pop	ax			; 00CEA
	cmp	word [0xea],0x3		; 00CEB
	jnl	short loc_00D39		; 00CF0 jnl 0xd39
	mov	ax,[0xe4]		; 00CF2
	cmp	ax,[0xbb2a]		; 00CF5
	jz	short loc_00D1E		; 00CF9 jz 0xd1e
	lea	di,[0xd37]		; 00CFB
	mov	cx,0xf00		; 00CFF
	db	0x33, 0xC0		; 00D02 xor ax,ax
	rep	stosw			; 00D04
	lea	si,[0xacb2]		; 00D06
	lea	di,[0x1c37]		; 00D0A
	mov	cx,0x370		; 00D0E
	rep	movsw			; 00D11
	lea	di,[0x1f57]		; 00D13
	db	0x33, 0xC0		; 00D17 xor ax,ax
	mov	cx,0x50			; 00D19
	rep	stosw			; 00D1C
loc_00D1E:
	lea	di,[0x3357]		; 00D1E
	mov	bl,0xf			; 00D22
loc_00D24:
	mov	ax,0xaaaa		; 00D24
	mov	cx,0x28			; 00D27
	rep	stosw			; 00D2A
	db	0x33, 0xC0		; 00D2C xor ax,ax
	mov	cx,0x28			; 00D2E
	rep	stosw			; 00D31
	dec	bl			; 00D33
	jnz	short loc_00D24		; 00D35 jnz 0xd24
	pop	es			; 00D37
	ret				; 00D38
loc_00D39:
	mov	ax,[0xe4]		; 00D39
	cmp	ax,[0xbb2a]		; 00D3C
	jz	short loc_00D4D		; 00D40 jz 0xd4d
	lea	di,[0x337]		; 00D42
	mov	cx,0x11d0		; 00D46
	db	0x33, 0xC0		; 00D49 xor ax,ax
	rep	stosw			; 00D4B
loc_00D4D:
	lea	di,[0x3357]		; 00D4D
	mov	bl,0xf			; 00D51
loc_00D53:
	mov	ax,0x5555		; 00D53
	mov	cx,0x28			; 00D56
	rep	stosw			; 00D59
	db	0x33, 0xC0		; 00D5B xor ax,ax
	mov	cx,0x28			; 00D5D
	rep	stosw			; 00D60
	dec	bl			; 00D62
	jnz	short loc_00D53		; 00D64 jnz 0xd53
	pop	es			; 00D66
	ret				; 00D67

; ---- function update_display ----
; Copies the offscreen buffer (DS:0x337) to CGA VRAM (B800:0000).
; No parameters. No stack frame. Preserves ES.
;
; Copies 200 scanlines, 80 bytes (40 words) each, using a scanline
; lookup table at DS:0xDF59 ([bx-0x20a7]) that maps logical line
; numbers to CGA's interleaved VRAM addresses (even lines at 0x0000,
; odd lines at 0x2000).
update_display:
	mov	bx,0x0			; 00D68
	lea	si,[0x337]		; 00D6B
	push	es			; 00D6F
	mov	ax,0xb800		; 00D70
	mov	es,ax			; 00D73
loc_00D75:
	mov	di,[bx+0xdf59]		; 00D75
	mov	cx,0x28			; 00D79
	rep	movsw			; 00D7C
	add	bx,0x2			; 00D7E
	cmp	bx,0x190		; 00D81
	jnz	short loc_00D75		; 00D85 jnz 0xd75
	pop	es			; 00D87
	ret				; 00D88

; ---- function draw_background ----
; Copies a region of the offscreen buffer directly to CGA VRAM.
; No parameters. No stack frame. Preserves ES.
;
; Selects the region based on [0xe4] vs [0xbb2a] (background changed?)
; and [0xea] (scene state >= 2 adjusts region).
; Default: 168 lines from DS:0xD37, LUT offset 0x40.
; If background unchanged: 84 lines from DS:0x2777, LUT offset 0xE8.
draw_background:
	mov	dl,0xa8			; 00D89
	lea	si,[0xd37]		; 00D8B
	mov	bx,0x40			; 00D8F
	mov	ax,[0xe4]		; 00D92
	cmp	ax,[0xbb2a]		; 00D95
	jnz	short loc_00DB5		; 00D99 jnz 0xdb5
	mov	dl,0x54			; 00D9B
	lea	si,[0x2777]		; 00D9D
	mov	bx,0xe8			; 00DA1
	cmp	word [0xea],0x2		; 00DA4
	jl	short loc_00DB5		; 00DA9 jl 0xdb5
	add	dl,0x6			; 00DAB
	sub	si,0x1e0		; 00DAE
	sub	bx,0xc			; 00DB2
loc_00DB5:
	mov	[0xbb2a],ax		; 00DB5
	push	es			; 00DB8
	mov	ax,0xb800		; 00DB9
	mov	es,ax			; 00DBC
loc_00DBE:
	mov	di,[bx+0xdf59]		; 00DBE
	mov	cx,0x28			; 00DC2
	rep	movsw			; 00DC5
	add	bx,0x2			; 00DC7
	dec	dl			; 00DCA
	jnz	short loc_00DBE		; 00DCC jnz 0xdbe
	pop	es			; 00DCE
	ret				; 00DCF

; ---- function scroll_screen ----
; Clears the bottom portion of the offscreen buffer (ground/scroll region).
; No parameters. No stack frame. Preserves ES.
;
; Default: clears 0x690 words starting at DS:0x26D7.
; If [0xea] >= 2: extends region up by 0x1E0 bytes and adds 0xF0 words.
scroll_screen:
	lea	di,[0x26d7]		; 00DD0
	mov	cx,0x690		; 00DD4
	cmp	word [0xea],0x2		; 00DD7
	jl	short loc_00DE6		; 00DDC jl 0xde6
	sub	di,0x1e0		; 00DDE
	add	cx,0xf0			; 00DE2
loc_00DE6:
	db	0x33, 0xC0		; 00DE6 xor ax,ax
	push	es			; 00DE8
	push	ds			; 00DE9
	pop	es			; 00DEA
	rep	stosw			; 00DEB
	pop	es			; 00DED
	ret				; 00DEE

; ---- function blit_buffer_to_vram ----
; Transfers offscreen buffer to CGA VRAM with a visible pixel-sweep effect.
; No parameters. Saves/restores BP and ES.
;
; Processes one pixel column at a time (BX = 0..0x4F = 80 columns).
; For each column, makes 4 passes over all 200 scanlines, copying
; 2 bits per pass (bits 7-6, 5-4, 3-2, 1-0) with a delay between passes.
; This creates a visual "dissolve" effect as the image appears.
;
; Uses the same scanline LUT at DS:0xDF59 as update_display.
blit_buffer_to_vram:
	push	bp			; 00DEF
	db	0x33, 0xDB		; 00DF0 xor bx,bx
	push	es			; 00DF2
	mov	ax,0xb800		; 00DF3
	mov	es,ax			; 00DF6
	lea	si,[0x337]		; 00DF8
	db	0x33, 0xED		; 00DFC xor bp,bp
	mov	cx,0x64			; 00DFE
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
	lea	si,[0x337]		; 00E31
	db	0x33, 0xED		; 00E35 xor bp,bp
	mov	cx,0x64			; 00E37
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
	lea	si,[0x337]		; 00E6A
	db	0x33, 0xED		; 00E6E xor bp,bp
	mov	cx,0x64			; 00E70
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
	lea	si,[0x337]		; 00EA3
	db	0x33, 0xED		; 00EA7 xor bp,bp
	mov	cx,0x64			; 00EA9
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
	inc	bx			; 00EDC
	cmp	bx,0x50			; 00EDD
	jz	short loc_00EE5		; 00EE0 jz 0xee5
	jmp	0xff8			; 00EE2
loc_00EE5:
	pop	es			; 00EE5
	pop	bp			; 00EE6
	ret				; 00EE7

; ---- function blit_column_delay ----
; Busy-wait delay: 1000 iterations of an empty loop.
; No parameters. No stack frame. Called between blit_buffer_to_vram passes.
blit_column_delay:
	mov	cx,0x3e8		; 00EE8
	loop	0xeeb			; 00EEB
	ret				; 00EED

; ---- function animate_figure ----
; Draws a single figure animation frame with background.
; No parameters. No stack frame. Preserves ES.
;
; Sequence: clear screen -> copy background (0x1040 bytes from DS:0xA6D6
; to DS:0x1917) -> update display -> delay -> animate figure at
; position (0x5C, 0x28, 0xB4) -> update display -> delay.
animate_figure:
	call	clear_screen		; 00EEE
	push	es			; 00EF1
	push	ds			; 00EF2
	pop	es			; 00EF3
	mov	cx,0x820		; 00EF4
	lea	si,[0xa6d6]		; 00EF7
	lea	di,[0x1917]		; 00EFB
	rep	movsw			; 00EFF
	call	update_display		; 00F01
	mov	ax,0x12			; 00F04
	call	delay_with_input	; 00F07
	mov	ax,0xb4			; 00F0A
	push	ax			; 00F0D
	mov	ax,0x28			; 00F0E
	push	ax			; 00F11
	mov	ax,0x5c			; 00F12
	push	ax			; 00F15
	call	draw_sprite_mirrored	; 00F16
	add	sp,0x6			; 00F19
	call	update_display		; 00F1C
	mov	ax,0x48			; 00F1F
	call	delay_with_input	; 00F22
	pop	es			; 00F25
	ret				; 00F26

; ---- function animate_step ----
; Performs a single animation step: clear, draw figure, display, wait.
; No parameters. No stack frame.
;
; Draws figure at position (0x5B, 0x6A, 0x73), enables single-step
; mode [0x168]=1 during the delay, then disables it.
animate_step:
	call	clear_screen		; 00F27
	mov	ax,0x73			; 00F2A
	push	ax			; 00F2D
	mov	ax,0x6a			; 00F2E
	push	ax			; 00F31
	mov	ax,0x5b			; 00F32
	push	ax			; 00F35
	call	draw_sprite_mirrored	; 00F36
	add	sp,0x6			; 00F39
	call	update_display		; 00F3C
	mov	word [0x168],0x1	; 00F3F
	mov	ax,0x48			; 00F45
	call	delay_with_input	; 00F48
	mov	word [0x168],0x0	; 00F4B
	ret				; 00F51

; ---- function load_resource ----
; Loads an indexed data block from a resource file.
; Opens the file, reads a 2-byte size from index table at (0xA6D6 + offset),
; then reads that many bytes of resource data. Closes the file and returns.
;
; Parameters (on stack, Lattice C convention):
;   [bp+0x12] = resource filename pointer (e.g. str_fuji_bcg)
;   [bp+0x14] = offset index into resource table at DS:0xA6D6
;
; Local variables:
;   [bp+0x6] = file slot from open_file_retry
;   [bp+0x8] = total data size (high_byte << 8 | low_byte)
;
; Returns: AX = total data size loaded
load_resource:
	push	bp			; 00F52
	sub	sp,0xe			; 00F53
	jc	short loc_00F5E		; 00F56 jc 0xf5e
	cmp	sp,[0x17]		; 00F58
	ja	short loc_00F61		; 00F5C ja 0xf61
loc_00F5E:
	jmp	0x420			; 00F5E
loc_00F61:
	db	0x8B, 0xEC		; 00F61 mov bp,sp
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
	call	load_file		; 00F7F
	db	0x8B, 0xE5		; 00F82 mov sp,bp
	mov	si,[bp+0x14]		; 00F84
	mov	al,[si+0xa6d7]		; 00F87
	xor	ah,ah			; 00F8B
	mov	cl,0x8			; 00F8D
	shl	ax,cl			; 00F8F
	mov	bl,[si+0xa6d6]		; 00F91
	xor	bh,bh			; 00F95
	db	0x03, 0xD8		; 00F97 add bx,ax
	db	0x8B, 0xC6		; 00F99 mov ax,si
	add	ax,0xa6d6		; 00F9B
	push	bx			; 00F9E
	push	ax			; 00F9F
	push	word [bp+0x6]		; 00FA0
	mov	[bp+0x8],bx		; 00FA3
	call	load_file		; 00FA6
	db	0x8B, 0xE5		; 00FA9 mov sp,bp
	push	word [bp+0x6]		; 00FAB
	call	close_file_slot		; 00FAE
	db	0x8B, 0xE5		; 00FB1 mov sp,bp
	mov	ax,[bp+0x8]		; 00FB3
	add	sp,0xe			; 00FB6
	pop	bp			; 00FB9
	ret				; 00FBA

; ---- function load_background ----
; Loads a .bcg background file, decompresses it into the offscreen buffer,
; and displays it.
;
; Parameters (on stack, Lattice C convention):
;   (none visible - uses filename from open_file_retry result)
;
; Local variables:
;   [bp+0x4] = file handle from open_file_retry
;   [bp+0x6] = total file size
;
; Loads data to DS:0x337 (offscreen buffer), calls close_file_slot to
; decompress, then update_display + wait_vsync(0x19) to show it.
load_background:
	push	bp			; 00FBB
	sub	sp,0xc			; 00FBC
	jc	short loc_00FC7		; 00FBF jc 0xfc7
	cmp	sp,[0x17]		; 00FC1
	ja	short loc_00FCA		; 00FC5 ja 0xfca
loc_00FC7:
	jmp	0x420			; 00FC7
loc_00FCA:
	db	0x8B, 0xEC		; 00FCA mov bp,sp
	call	clear_screen		; 00FCC
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
	call	load_file		; 00FE8
	db	0x8B, 0xE5		; 00FEB mov sp,bp
	mov	al,[0x338]		; 00FED
	xor	ah,ah			; 00FF0
	mov	cl,0x8			; 00FF2
	shl	ax,cl			; 00FF4
	mov	bl,[0x337]		; 00FF6
	xor	bh,bh			; 00FFA
	db	0x03, 0xD8		; 00FFC add bx,ax
	push	bx			; 00FFE
	mov	ax,0x337		; 00FFF
	push	ax			; 01002
	push	word [bp+0x4]		; 01003
	mov	[bp+0x6],bx		; 01006
	call	load_file		; 01009
	db	0x8B, 0xE5		; 0100C mov sp,bp
	push	word [bp+0x4]		; 0100E
	call	close_file_slot		; 01011
	db	0x8B, 0xE5		; 01014 mov sp,bp
	call	update_display		; 01016
	mov	ax,0x19			; 01019
	push	ax			; 0101C
	call	wait_vsync		; 0101D
	db	0x8B, 0xE5		; 01020 mov sp,bp
	add	sp,0xc			; 01022
	pop	bp			; 01025
	ret				; 01026

; ---- function load_animation ----
; Loads a complete animation set: two figure data files (.gal) and
; builds frame offset tables for both.
;
; Parameters (on stack, Lattice C convention):
;   [bp+0x2e] = animation set index (indexes into resource pointer tables
;               at [si+0x264] and [si+0x2c0])
;
; Local variables:
;   [bp+0x0]  = temp
;   [bp+0x8]  = file handle from open_file_retry
;   [bp+0xa]  = secondary data size
;   [bp+0xc]  = frame offset counter (iterates by 4, up to 0x2A8)
;   [bp+0x10] = secondary data size copy
;   [bp+0x12] = computed frame offset (16-bit)
;   [bp+0x14] = frame index byte
;   [bp+0x16..0x2D] = filename buffer (24 bytes)
;
; Loads primary data to DS:0x443C + [0x160], secondary to DS:0x893A + [0x164].
; Builds frame offset lookup tables at [0x423C] and [0x873A].
; Uses strcat to build filenames by appending extensions.
load_animation:
	push	bp			; 01027
	sub	sp,0x2a			; 01028
	jc	short loc_01033		; 0102B jc 0x1033
	cmp	sp,[0x17]		; 0102D
	ja	short loc_01036		; 01031 ja 0x1036
loc_01033:
	jmp	0x420			; 01033
loc_01036:
	db	0x8B, 0xEC		; 01036 mov bp,sp
	mov	ax,[bp+0x2e]		; 01038
	shl	ax,1			; 0103B
	db	0x8B, 0xF0		; 0103D mov si,ax
	push	word [si+0x264]		; 0103F
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
	mov	bx,[0x160]		; 01066
	add	bx,0x443c		; 0106A
	mov	cx,0x2a8		; 0106E
	push	cx			; 01071
	push	bx			; 01072
	push	ax			; 01073
	mov	[bp+0x8],ax		; 01074
	call	load_file		; 01077
	db	0x8B, 0xE5		; 0107A mov sp,bp
	push	word [bp+0x8]		; 0107C
	call	close_file_slot		; 0107F
	db	0x8B, 0xE5		; 01082 mov sp,bp
	mov	word [bp+0xc],0x0	; 01084
loc_01089:
	mov	ax,[bp+0xc]		; 01089
	cmp	ax,0x2a8		; 0108C
	jnl	short loc_010FB		; 0108F jnl 0x10fb
	mov	bx,[0x160]		; 01091
	db	0x03, 0xC3		; 01095 add ax,bx
	db	0x8B, 0xF0		; 01097 mov si,ax
	mov	cl,[si+0x443c]		; 01099
	xor	ch,ch			; 0109D
	mov	dl,[si+0x443f]		; 0109F
	xor	dh,dh			; 010A3
	mov	[bp+0x14],cx		; 010A5
	mov	cl,0x8			; 010A8
	shl	dx,cl			; 010AA
	mov	cl,[si+0x443e]		; 010AC
	xor	ch,ch			; 010B0
	db	0x03, 0xCA		; 010B2 add cx,dx
	db	0x03, 0xCB		; 010B4 add cx,bx
	mov	bx,[bp+0x14]		; 010B6
	shl	bx,1			; 010B9
	mov	[bp+0x12],cx		; 010BB
	and	cx,0xff			; 010BE
	mov	[bx+0x423c],cl		; 010C2
	mov	cl,0x8			; 010C6
	mov	dx,[bp+0x12]		; 010C8
	sar	dx,cl			; 010CB
	mov	[bx+0x423d],dl		; 010CD
	cmp	word [bp+0x14],0xff	; 010D1
	mov	[bp+0x0],ax		; 010D6
	jnz	short loc_010F5		; 010D9 jnz 0x10f5
	mov	al,[si+0x443f]		; 010DB
	xor	ah,ah			; 010DF
	mov	cl,0x8			; 010E1
	shl	ax,cl			; 010E3
	mov	bl,[si+0x443e]		; 010E5
	xor	bh,bh			; 010E9
	db	0x03, 0xD8		; 010EB add bx,ax
	mov	word [bp+0xc],0x2a8	; 010ED
	mov	[bp+0xa],bx		; 010F2
loc_010F5:
	add	word [bp+0xc],0x4	; 010F5
	jmp	short loc_01089		; 010F9 jmp 0x1089
loc_010FB:
	mov	ax,[bp+0x2e]		; 010FB
	shl	ax,1			; 010FE
	db	0x8B, 0xF0		; 01100 mov si,ax
	push	word [si+0x264]		; 01102
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
	mov	cx,[0x160]		; 0112C
	add	cx,0x443c		; 01130
	push	bx			; 01134
	push	cx			; 01135
	push	ax			; 01136
	mov	[bp+0x8],ax		; 01137
	mov	[bp+0x10],bx		; 0113A
	call	load_file		; 0113D
	db	0x8B, 0xE5		; 01140 mov sp,bp
	push	word [bp+0x8]		; 01142
	call	close_file_slot		; 01145
	db	0x8B, 0xE5		; 01148 mov sp,bp
	cmp	word [0x160],0x0	; 0114A
	jnz	short loc_01157		; 0114F jnz 0x1157
	mov	ax,[bp+0xa]		; 01151
	mov	[0x160],ax		; 01154
loc_01157:
	mov	ax,[bp+0x2e]		; 01157
	shl	ax,1			; 0115A
	db	0x8B, 0xF0		; 0115C mov si,ax
	push	word [si+0x2c0]		; 0115E
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
	mov	bx,[0x164]		; 01185
	add	bx,0x893a		; 01189
	mov	cx,0x2a8		; 0118D
	push	cx			; 01190
	push	bx			; 01191
	push	ax			; 01192
	mov	[bp+0x8],ax		; 01193
	call	load_file		; 01196
	db	0x8B, 0xE5		; 01199 mov sp,bp
	push	word [bp+0x8]		; 0119B
	call	close_file_slot		; 0119E
	db	0x8B, 0xE5		; 011A1 mov sp,bp
	mov	word [bp+0xc],0x0	; 011A3
loc_011A8:
	mov	ax,[bp+0xc]		; 011A8
	cmp	ax,0x2a8		; 011AB
	jnl	short loc_0121A		; 011AE jnl 0x121a
	mov	bx,[0x164]		; 011B0
	db	0x03, 0xC3		; 011B4 add ax,bx
	db	0x8B, 0xF0		; 011B6 mov si,ax
	mov	cl,[si+0x893a]		; 011B8
	xor	ch,ch			; 011BC
	mov	dl,[si+0x893d]		; 011BE
	xor	dh,dh			; 011C2
	mov	[bp+0x14],cx		; 011C4
	mov	cl,0x8			; 011C7
	shl	dx,cl			; 011C9
	mov	cl,[si+0x893c]		; 011CB
	xor	ch,ch			; 011CF
	db	0x03, 0xCA		; 011D1 add cx,dx
	db	0x03, 0xCB		; 011D3 add cx,bx
	mov	bx,[bp+0x14]		; 011D5
	shl	bx,1			; 011D8
	mov	[bp+0x12],cx		; 011DA
	and	cx,0xff			; 011DD
	mov	[bx+0x873a],cl		; 011E1
	mov	cl,0x8			; 011E5
	mov	dx,[bp+0x12]		; 011E7
	sar	dx,cl			; 011EA
	mov	[bx+0x873b],dl		; 011EC
	cmp	word [bp+0x14],0xff	; 011F0
	mov	[bp+0x0],ax		; 011F5
	jnz	short loc_01214		; 011F8 jnz 0x1214
	mov	al,[si+0x893d]		; 011FA
	xor	ah,ah			; 011FE
	mov	cl,0x8			; 01200
	shl	ax,cl			; 01202
	mov	bl,[si+0x893c]		; 01204
	xor	bh,bh			; 01208
	db	0x03, 0xD8		; 0120A add bx,ax
	mov	word [bp+0xc],0x2a8	; 0120C
	mov	[bp+0xa],bx		; 01211
loc_01214:
	add	word [bp+0xc],0x4	; 01214
	jmp	short loc_011A8		; 01218 jmp 0x11a8
loc_0121A:
	mov	ax,[bp+0x2e]		; 0121A
	shl	ax,1			; 0121D
	db	0x8B, 0xF0		; 0121F mov si,ax
	push	word [si+0x2c0]		; 01221
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
	mov	bx,[0x164]		; 01248
	add	bx,0x893a		; 0124C
	push	word [bp+0xa]		; 01250
	push	bx			; 01253
	push	ax			; 01254
	mov	[bp+0x8],ax		; 01255
	call	load_file		; 01258
	db	0x8B, 0xE5		; 0125B mov sp,bp
	push	word [bp+0x8]		; 0125D
	call	close_file_slot		; 01260
	db	0x8B, 0xE5		; 01263 mov sp,bp
	cmp	word [0x164],0x0	; 01265
	jnz	short loc_01272		; 0126A jnz 0x1272
	mov	ax,[bp+0xa]		; 0126C
	mov	[0x164],ax		; 0126F
loc_01272:
	add	sp,0x2a			; 01272
	pop	bp			; 01275
	ret				; 01276
