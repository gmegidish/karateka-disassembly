; Sound system: init, play, stop, music callback


; ---- function play_sound ----
play_sound:
	lea	bx,[0xce3e]		; 019A2
	lea	di,[0xcdea]		; 019A6
	call	build_anim_offsets	; 019AA
	ret				; 019AD

; ---- function init_sound ----
init_sound:
	push	bp			; 019AE
	sub	sp,0x4			; 019AF
	jc	short loc_019BA		; 019B2 jc 0x19ba
	cmp	sp,[0x17]		; 019B4
	ja	short loc_019BD		; 019B8 ja 0x19bd
loc_019BA:
	jmp	0x420			; 019BA
loc_019BD:
	db	0x8B, 0xEC		; 019BD mov bp,sp
	mov	ax,0xc428		; 019BF
	push	ax			; 019C2
	mov	ax,0xd59c		; 019C3
	push	ax			; 019C6
	call	load_anim_script	; 019C7
	db	0x8B, 0xE5		; 019CA mov sp,bp
	call	build_anim_offsets_alt	; 019CC
	db	0x33, 0xC0		; 019CF xor ax,ax
	mov	bx,0x5			; 019D1
	push	bx			; 019D4
	mov	[0x172],ax		; 019D5
	mov	[0x160],ax		; 019D8
	mov	[0x162],ax		; 019DB
	mov	[0x164],ax		; 019DE
	mov	[0x15e],ax		; 019E1
	call	load_animation		; 019E4
	db	0x8B, 0xE5		; 019E7 mov sp,bp
	add	sp,0x4			; 019E9
	pop	bp			; 019EC
	ret				; 019ED

; ---- function stop_sound ----
stop_sound:
	push	bp			; 019EE
	sub	sp,0xc			; 019EF
	jc	short loc_019FA		; 019F2 jc 0x19fa
	cmp	sp,[0x17]		; 019F4
	ja	short loc_019FD		; 019F8 ja 0x19fd
loc_019FA:
	jmp	0x420			; 019FA
loc_019FD:
	db	0x8B, 0xEC		; 019FD mov bp,sp
	db	0x33, 0xC0		; 019FF xor ax,ax
	mov	[bp+0xa],ax		; 01A01
	mov	[bp+0x4],ax		; 01A04
	mov	[bp+0x6],ax		; 01A07
	mov	ax,[bp+0xa]		; 01A0A
	mov	bx,[bp+0x10]		; 01A0D
	db	0x3B, 0xD8		; 01A10 cmp bx,ax
	jg	short loc_01A17		; 01A12 jg 0x1a17
	jmp	0x1ca7			; 01A14
loc_01A17:
	shl	ax,1			; 01A17
	db	0x8B, 0xF0		; 01A19 mov si,ax
	mov	ax,[bp+0x6]		; 01A1B
	add	ax,0xc102		; 01A1E
	mov	[si-0x3c58],ax		; 01A21
loc_01A25:
	mov	si,[bp+0x4]		; 01A25
	mov	al,[si-0x3efe]		; 01A28
	xor	ah,ah			; 01A2C
	cmp	ax,0xff			; 01A2E
	jz	short loc_01A8D		; 01A31 jz 0x1a8d
	mov	al,[si-0x3efe]		; 01A33
	xor	ah,ah			; 01A37
	db	0x3D, 0x12, 0x00	; 01A39 cmp ax,0x12
	jnz	short loc_01A52		; 01A3C jnz 0x1a52
	mov	ax,[bp+0xa]		; 01A3E
	shl	ax,1			; 01A41
	db	0x8B, 0xF8		; 01A43 mov di,ax
	mov	ax,[bp+0x6]		; 01A45
	add	ax,0xc102		; 01A48
	mov	[di-0x3c4a],ax		; 01A4B
	inc	word [bp+0x4]		; 01A4F
loc_01A52:
	mov	si,[bp+0x4]		; 01A52
	mov	al,[si-0x3efe]		; 01A55
	xor	ah,ah			; 01A59
	cmp	ax,0xff			; 01A5B
	jz	short loc_01A8D		; 01A5E jz 0x1a8d
	mov	word [bp+0x8],0x1	; 01A60
loc_01A65:
	mov	ax,[bp+0x8]		; 01A65
	db	0x3D, 0x05, 0x00	; 01A68 cmp ax,0x5
	jnl	short loc_01A87		; 01A6B jnl 0x1a87
	mov	bx,[bp+0x6]		; 01A6D
	inc	word [bp+0x6]		; 01A70
	mov	cx,[bp+0x4]		; 01A73
	db	0x03, 0xC8		; 01A76 add cx,ax
	db	0x8B, 0xF1		; 01A78 mov si,cx
	mov	al,[si-0x3efe]		; 01A7A
	mov	[bx-0x3efe],al		; 01A7E
	inc	word [bp+0x8]		; 01A82
	jmp	short loc_01A65		; 01A85 jmp 0x1a65
loc_01A87:
	add	word [bp+0x4],0x5	; 01A87
	jmp	short loc_01A25		; 01A8B jmp 0x1a25
loc_01A8D:
	mov	ax,[bp+0xa]		; 01A8D
	shl	ax,1			; 01A90
	db	0x8B, 0xF0		; 01A92 mov si,ax
	mov	ax,[bp+0x6]		; 01A94
	add	ax,0xc102		; 01A97
	mov	[si-0x3c3c],ax		; 01A9A
	inc	word [bp+0x4]		; 01A9E
	inc	word [bp+0xa]		; 01AA1
	jmp	0x1c0a			; 01AA4
	mov	ax,[0xc3a8]		; 01AA7
	mov	bx,[0xc3b6]		; 01AAA
	mov	cx,[0xc3c4]		; 01AAE
	mov	[0xc3a0],ax		; 01AB2
	mov	[0xc3a4],cx		; 01AB5
	mov	[0xc3a2],bx		; 01AB9
	add	sp,0xc			; 01ABD
	pop	bp			; 01AC0
	ret				; 01AC1
