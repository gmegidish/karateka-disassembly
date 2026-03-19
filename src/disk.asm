; Disk I/O, file retry, Ctrl+Q check, copy protection sector reading


; ---- function open_file_retry ----
; Opens a file via open_file_slot, retrying on failure.
; If open_file_slot returns -1 (file not found / disk error), calls
; check_disk_prompt to show the "insert disk" message, then retries
; in a loop until the file opens successfully.
;
; Parameters (on stack, Lattice C convention):
;   [bp+0x8] = filename pointer / flags (passed through to open_file_slot)
;   [bp+0xa] = additional flags (passed through to open_file_slot)
;
; Returns: AX = file slot index (guaranteed valid, retries until success)
open_file_retry:
	push	bp			; 0166D
	sub	sp,0x4			; 0166E
	jc	short loc_01679		; 01671 jc 0x1679
	cmp	sp,[0x17]		; 01673
	ja	short loc_0167C		; 01677 ja 0x167c
loc_01679:
	jmp	0x420			; 01679
loc_0167C:
	db	0x8B, 0xEC		; 0167C mov bp,sp
loc_0167E:
	push	word [bp+0xa]		; 0167E
	push	word [bp+0x8]		; 01681
	call	open_file_slot		; 01684
	db	0x8B, 0xE5		; 01687 mov sp,bp
	mov	[bp+0x2],ax		; 01689
	inc	ax			; 0168C
	jnz	short loc_01694		; 0168D jnz 0x1694
	call	check_disk_prompt	; 0168F
	jmp	short loc_0167E		; 01692 jmp 0x167e
loc_01694:
	mov	ax,[bp+0x2]		; 01694
	add	sp,0x4			; 01697
	pop	bp			; 0169A
	ret				; 0169B

; ---- function reset_to_game_start ----
; Non-local goto (longjmp) back to game_init's stack frame.
; Restores SP from BP (which still points to game_init's frame),
; then pushes the address of loc_002B8 (the load_player_anim_data call in
; game_init) and returns to it. This effectively restarts the game
; from the animation data loading point, unwinding the entire call stack.
;
; No parameters. Does not return to caller.
reset_to_game_start:
	mov	sp,bp			; 0169C
	mov	ax,0x2b8		; 0169E
	push	ax			; 016A1
	ret				; 016A2

; ---- function check_ctrl_q ----
; Non-blocking keyboard check for Ctrl+Q (0x11) via INT 21h/06h.
; If Ctrl+Q is detected: sets video mode 3 (80x25 text), resets the
; stack pointer from [0x15], and exits to DOS with return code 1
; via INT 21h/4Ch. Otherwise returns normally (no-op).
;
; No parameters. No return value (unless Ctrl+Q exits the program).
check_ctrl_q:
	mov	dl,0xff			; 016A3
	mov	ah,0x6			; 016A5
	int	0x21			; 016A7
	jz	short loc_016AF		; 016A9 jz 0x16af
	cmp	al,0x11			; 016AB
	jz	short loc_016B0		; 016AD jz 0x16b0
loc_016AF:
	ret				; 016AF
loc_016B0:
	mov	ax,0x3			; 016B0
	int	0x10			; 016B3
	mov	ax,[0x15]		; 016B5
	db	0x2D, 0x04, 0x00	; 016B8 sub ax,0x4
	mov	sp,ax			; 016BB
	mov	ax,0x4c01		; 016BD
	int	0x21			; 016C0

; ---- function read_disk_sector ----
; Copy protection disk verification via INT 13h (BIOS disk read).
; Reads raw disk sectors to verify the original game disk is present.
;
; First read: track 10, sector 7, head 0 — reads one sector into
; the verification buffer. Retries on failure (up to DI attempts).
;
; Second read: track 10, sector 241 (0xF1) — reads into the read
; buffer. If a CRC error (AH=0x10) occurs, compares 32 bytes (16
; words) between the verification buffer and read buffer+0x8C.
;
; Parameters (from caller's stack frame):
;   [bp+0x4] = drive number
;   [bp+0x6] = verification buffer pointer
;   [bp+0x8] = read buffer pointer
;
; Returns: AX = 1 if copy protection check passed, 0 if failed
read_disk_sector:
	add	[bp+si],ax		; 016C2
	mov	bx,[bp+0x6]		; 016C4
	mov	ch,0xa			; 016C7
	mov	cl,0x7			; 016C9
	mov	dh,0x0			; 016CB
	mov	dl,[bp+0x4]		; 016CD
	push	ds			; 016D0
	pop	es			; 016D1
	nop				; 016D2
	int	0x13			; 016D3
	dec	di			; 016D5
	jz	short loc_01712		; 016D6 jz 0x1712
	db	0x72, 0xE7		; 016D8 jc 0x16c1
	mov	di,0x4			; 016DA
loc_016DD:
	mov	ax,0x201		; 016DD
	mov	bx,[bp+0x8]		; 016E0
	mov	ch,0xa			; 016E3
	mov	cl,0xf1			; 016E5
	mov	dl,[bp+0x4]		; 016E7
	mov	dh,0x0			; 016EA
	int	0x13			; 016EC
	dec	di			; 016EE
	jz	short loc_01712		; 016EF jz 0x1712
	jnc	short loc_016DD		; 016F1 jnc 0x16dd
	cmp	ah,0x10			; 016F3
	jnz	short loc_016DD		; 016F6 jnz 0x16dd
	cld				; 016F8
	mov	cx,0x10			; 016F9
	mov	si,[bp+0x6]		; 016FC
	mov	di,[bp+0x8]		; 016FF
	add	di,0x8c			; 01702
	repe	cmpsw			; 01706
	cmp	cx,0x0			; 01708
	jnz	short loc_01712		; 0170B jnz 0x1712
	mov	ax,0x1			; 0170D
	jmp	short loc_01714		; 01710 jmp 0x1714
loc_01712:
	db	0x33, 0xC0		; 01712 xor ax,ax
loc_01714:
	pop	ds			; 01714
	pop	es			; 01715
	pop	bp			; 01716
	ret				; 01717

; ---- function load_game_disk ----
; Verifies the game disk is present by comparing a signature string.
; Compares bytes at [bx-0x435C] (expected signature in data section)
; with [bx+0x7C3] (read from disk). Iterates until a null terminator
; is found or a mismatch occurs.
;
; No parameters.
; Returns: AX = 1 if signature matches (game disk present), 0 if mismatch
load_game_disk:
	db	0x33, 0xDB		; 01718 xor bx,bx
	db	0x33, 0xC0		; 0171A xor ax,ax
	mov	cl,[bx+0xbca4]		; 0171C
loc_01720:
	cmp	cl,[bx+0x7c3]		; 01720
	jnz	short loc_01733		; 01724 jnz 0x1733
	inc	bx			; 01726
	mov	cl,[bx+0xbca4]		; 01727
	cmp	cl,0x0			; 0172B
	jnz	short loc_01720		; 0172E jnz 0x1720
	mov	ax,0x1			; 01730
loc_01733:
	ret				; 01733
