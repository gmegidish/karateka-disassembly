; Video mode, cursor, shutdown


; ---- function game_shutdown ----
; Cleans up game state before exiting.
; Restores the default palette, runs a final combat update pass with 0,
; clears the screen, and resets the input-advance flag.
; Input: none
; Output: none
; Clobbers: AX
game_shutdown:
	push	bp			; 005E5
	db	0x8B, 0xEC		; 005E6 mov bp,sp
	mov	ax,0x5dc		; 005E8  ; palette data length
	push	ax			; 005EB
	mov	ax,0x41fb		; 005EC  ; palette data offset
	push	ax			; 005EF
	call	load_palette		; 005F0  ; load_palette(data_ptr, length)
	db	0x8B, 0xE5		; 005F3 mov sp,bp
	db	0x33, 0xC0		; 005F5 xor ax,ax
	push	ax			; 005F7
	call	init_combat_level	; 005F8  ; init_combat_level(0) — final cleanup pass
	db	0x8B, 0xE5		; 005FB mov sp,bp
	call	clear_screen		; 005FD
	mov	word [0xdf44],0x0	; 00600  ; clear input_advance flag
	pop	bp			; 00606
	ret				; 00607

; ---- function set_video_mode ----
; Sets the BIOS video mode via INT 10h/00h.
; Input: [bp+4] = video mode number (byte, e.g. 0x04 for CGA 320x200)
; Output: none
set_video_mode:
	push	bp			; 00608
	db	0x8B, 0xEC		; 00609 mov bp,sp
	mov	ax,[bp+0x4]		; 0060B  ; AL = mode number
	mov	ah,0x0			; 0060E  ; AH = 0 (set video mode)
	int	0x10			; 00610  ; BIOS video interrupt
	pop	bp			; 00612
	ret				; 00613

; ---- function set_cursor_pos ----
; Sets the text cursor position via INT 10h/02h.
; Input: [bp+4] = column (byte), [bp+6] = row (byte)
; Output: none
set_cursor_pos:
	push	bp			; 00614
	db	0x8B, 0xEC		; 00615 mov bp,sp
	mov	ax,[bp+0x4]		; 00617
	db	0x8A, 0xD0		; 0061A mov dl,al  ; DL = column
	mov	ax,[bp+0x6]		; 0061C
	db	0x8A, 0xF0		; 0061F mov dh,al  ; DH = row
	db	0x32, 0xFF		; 00621 xor bh,bh  ; BH = page 0
	mov	ah,0x2			; 00623  ; AH = 2 (set cursor position)
	int	0x10			; 00625  ; BIOS video interrupt
	pop	bp			; 00627
	ret				; 00628

; ---- function rand_range ----
; Returns a pseudo-random integer in [0, max_value].
; Uses rand_next() to get a 15-bit random, then scales by (max_value+1)
; and takes the high word of the 16x16 multiply (effectively modulo).
; Input: [bp+4] = max_value (word)
; Output: AX = random value in [0, max_value]
; Clobbers: DX
rand_range:
	push	bp			; 00629
	db	0x8B, 0xEC		; 0062A mov bp,sp
	call	rand_next		; 0062C  ; AX = 16-bit random
	shl	ax,1			; 0062F  ; clear sign bit → 15-bit positive
	mov	[0x421a],ax		; 00631  ; store in rand_temp
	mov	ax,[bp+0x4]		; 00634  ; AX = max_value
	inc	ax			; 00637  ; AX = max_value + 1
	mul	word [0x421a]		; 00638  ; DX:AX = (max+1) * random
	db	0x8B, 0xC2		; 0063C mov ax,dx  ; AX = high word = scaled result
	pop	bp			; 0063E
	ret				; 0063F
