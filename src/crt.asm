; C runtime: DOS wrappers, memory, strings, I/O


; ---- function crt_realloc_down ----
crt_realloc_down:
	push	bp			; 05C12
	db	0x8B, 0xEC		; 05C13 mov bp,sp
	push	es			; 05C15
	mov	word [0x80],0x0		; 05C16
	mov	bx,[0x5f]		; 05C1C
	sub	bx,[0x5b]		; 05C20
	mov	[0x69],bx		; 05C24
	mov	dx,[bp+0x4]		; 05C28
	mov	cx,[0x5f]		; 05C2B
	mov	ax,ds			; 05C2F
	db	0x2B, 0xC8		; 05C31 sub cx,ax
	db	0x03, 0xCA		; 05C33 add cx,dx
	jc	short loc_05C51		; 05C35 jc 0x5c51
	db	0x03, 0xDA		; 05C37 add bx,dx
	push	bx			; 05C39
	les	ax,word [0x59]		; 05C3A
	mov	ah,0x4a			; 05C3E
	int	0x21			; 05C40
	pop	bx			; 05C42
	jc	short loc_05C4E		; 05C43 jc 0x5c4e
	mov	[0x69],bx		; 05C45
	db	0x33, 0xC0		; 05C49 xor ax,ax
	pop	es			; 05C4B
	pop	bp			; 05C4C
	ret				; 05C4D
loc_05C4E:
	mov	[0x80],ax		; 05C4E
loc_05C51:
	mov	ax,0xffff		; 05C51
	pop	es			; 05C54
	pop	bp			; 05C55
	ret				; 05C56

; ---- function crt_realloc_up ----
crt_realloc_up:
	push	bp			; 05C57
	db	0x8B, 0xEC		; 05C58 mov bp,sp
	push	es			; 05C5A
	mov	word [0x80],0x0		; 05C5B
	mov	bx,ds			; 05C61
	sub	bx,[0x5b]		; 05C63
	mov	ax,[0x69]		; 05C67
	db	0x2B, 0xC3		; 05C6A sub ax,bx
	add	ax,[bp+0x4]		; 05C6C
	test	ax,0xf000		; 05C6F
	jnz	short loc_05C95		; 05C72 jnz 0x5c95
	mov	bx,[0x69]		; 05C74
	add	bx,[bp+0x4]		; 05C78
	jc	short loc_05C95		; 05C7B jc 0x5c95
	les	ax,word [0x59]		; 05C7D
	push	bx			; 05C81
	mov	ah,0x4a			; 05C82
	int	0x21			; 05C84
	pop	bx			; 05C86
	jc	short loc_05C92		; 05C87 jc 0x5c92
	mov	[0x69],bx		; 05C89
	db	0x33, 0xC0		; 05C8D xor ax,ax
	pop	es			; 05C8F
	pop	bp			; 05C90
	ret				; 05C91
loc_05C92:
	mov	[0x80],ax		; 05C92
loc_05C95:
	mov	ax,0xffff		; 05C95
	pop	es			; 05C98
	pop	bp			; 05C99
	ret				; 05C9A

; ---- function dos_create_file ----
dos_create_file:
	push	bp			; 05C9B
	db	0x8B, 0xEC		; 05C9C mov bp,sp
	mov	word [0x80],0x0		; 05C9E
	mov	dx,[bp+0x4]		; 05CA4
	mov	cx,[bp+0x6]		; 05CA7
	mov	ah,0x3c			; 05CAA
	int	0x21			; 05CAC
	jnc	short loc_05CB3		; 05CAE jnc 0x5cb3
	mov	[0x80],ax		; 05CB0
loc_05CB3:
	pop	bp			; 05CB3
	ret				; 05CB4

; ---- function dos_open_file ----
dos_open_file:
	push	bp			; 05CB5
	db	0x8B, 0xEC		; 05CB6 mov bp,sp
	mov	word [0x80],0x0		; 05CB8
	mov	dx,[bp+0x4]		; 05CBE
	mov	ax,[bp+0x6]		; 05CC1
	mov	ah,0x3d			; 05CC4
	int	0x21			; 05CC6
	jnc	short loc_05CCD		; 05CC8 jnc 0x5ccd
	mov	[0x80],ax		; 05CCA
loc_05CCD:
	pop	bp			; 05CCD
	ret				; 05CCE

; ---- function dos_close_file ----
dos_close_file:
	push	bp			; 05CCF
	db	0x8B, 0xEC		; 05CD0 mov bp,sp
	mov	word [0x80],0x0		; 05CD2
	mov	bx,[bp+0x4]		; 05CD8
	mov	ah,0x3e			; 05CDB
	int	0x21			; 05CDD
	jnc	short loc_05CE4		; 05CDF jnc 0x5ce4
	mov	[0x80],ax		; 05CE1
loc_05CE4:
	pop	bp			; 05CE4
	ret				; 05CE5

; ---- function dos_read_file ----
dos_read_file:
	push	bp			; 05CE6
	db	0x8B, 0xEC		; 05CE7 mov bp,sp
	mov	word [0x80],0x0		; 05CE9
	mov	bx,[bp+0x4]		; 05CEF
	mov	cx,[bp+0x8]		; 05CF2
	mov	dx,[bp+0x6]		; 05CF5
	mov	ah,0x3f			; 05CF8
	int	0x21			; 05CFA
	jnc	short loc_05D03		; 05CFC jnc 0x5d03
	mov	[0x80],ax		; 05CFE
	db	0x33, 0xC0		; 05D01 xor ax,ax
loc_05D03:
	pop	bp			; 05D03
	ret				; 05D04

; ---- function dos_write_file ----
dos_write_file:
	push	bp			; 05D05
	db	0x8B, 0xEC		; 05D06 mov bp,sp
	mov	word [0x80],0x0		; 05D08
	mov	bx,[bp+0x4]		; 05D0E
	mov	cx,[bp+0x8]		; 05D11
	mov	dx,[bp+0x6]		; 05D14
	mov	ah,0x40			; 05D17
	int	0x21			; 05D19
	jnc	short loc_05D22		; 05D1B jnc 0x5d22
	mov	[0x80],ax		; 05D1D
	db	0x33, 0xC0		; 05D20 xor ax,ax
loc_05D22:
	pop	bp			; 05D22
	ret				; 05D23

; ---- function dos_seek_file ----
dos_seek_file:
	push	bp			; 05D24
	db	0x8B, 0xEC		; 05D25 mov bp,sp
	mov	word [0x80],0x0		; 05D27
	mov	ax,[bp+0xa]		; 05D2D
	mov	ah,0x42			; 05D30
	mov	bx,[bp+0x4]		; 05D32
	mov	cx,[bp+0x8]		; 05D35
	mov	dx,[bp+0x6]		; 05D38
	int	0x21			; 05D3B
	jnc	short loc_05D42		; 05D3D jnc 0x5d42
	mov	[0x80],ax		; 05D3F
loc_05D42:
	db	0x8B, 0xD8		; 05D42 mov bx,ax
	db	0x8B, 0xC2		; 05D44 mov ax,dx
	pop	bp			; 05D46
	ret				; 05D47

; ---- function dos_delete_file ----
dos_delete_file:
	push	bp			; 05D48
	db	0x8B, 0xEC		; 05D49 mov bp,sp
	mov	word [0x80],0x0		; 05D4B
	mov	dx,[bp+0x4]		; 05D51
	mov	ah,0x41			; 05D54
	int	0x21			; 05D56
	jnc	short loc_05D5D		; 05D58 jnc 0x5d5d
	mov	[0x80],ax		; 05D5A
loc_05D5D:
	pop	bp			; 05D5D
	ret				; 05D5E
	push	bp			; 05D5F
	db	0x8B, 0xEC		; 05D60 mov bp,sp
	mov	word [0x80],0x0		; 05D62
	mov	dx,[bp+0x4]		; 05D68
	mov	ax,[bp+0x6]		; 05D6B
	mov	ah,0x43			; 05D6E
	mov	cx,[bp+0x8]		; 05D70
	int	0x21			; 05D73
	jnc	short loc_05D7A		; 05D75 jnc 0x5d7a
	mov	[0x80],ax		; 05D77
loc_05D7A:
	db	0x8B, 0xC1		; 05D7A mov ax,cx
	pop	bp			; 05D7C
	ret				; 05D7D

; ---- function dos_ioctl ----
dos_ioctl:
	push	bp			; 05D7E
	db	0x8B, 0xEC		; 05D7F mov bp,sp
	mov	bx,[bp+0x4]		; 05D81
	mov	ax,0x4400		; 05D84
	int	0x21			; 05D87
	db	0x8B, 0xC2		; 05D89 mov ax,dx
	pop	bp			; 05D8B
	ret				; 05D8C

; ---- function dos_rename_file ----
dos_rename_file:
	push	bp			; 05D8D
	db	0x8B, 0xEC		; 05D8E mov bp,sp
	mov	word [0x80],0x0		; 05D90
	mov	dx,[bp+0x4]		; 05D96
	mov	di,[bp+0x6]		; 05D99
	mov	ah,0x56			; 05D9C
	int	0x21			; 05D9E
	jnc	short loc_05DA7		; 05DA0 jnc 0x5da7
	mov	[0x80],ax		; 05DA2
	pop	bp			; 05DA5
	ret				; 05DA6
loc_05DA7:
	db	0x33, 0xC0		; 05DA7 xor ax,ax
	pop	bp			; 05DA9
	ret				; 05DAA

; ---- function crt_init_io ----
crt_init_io:
	push	bp			; 05DAB
	db	0x8B, 0xEC		; 05DAC mov bp,sp
	push	word [bp+0x6]		; 05DAE
	push	word [bp+0x4]		; 05DB1
	call	crt_exit		; 05DB4
	db	0x8B, 0xE5		; 05DB7 mov sp,bp
	pop	bp			; 05DB9
	ret				; 05DBA
	push	bp			; 05DBB
	sub	sp,0x2			; 05DBC
	db	0x8B, 0xEC		; 05DBF mov bp,sp
	mov	ax,0x8			; 05DC1
	push	ax			; 05DC4
	call	dos_int21		; 05DC5
	db	0x8B, 0xE5		; 05DC8 mov sp,bp
	add	sp,0x2			; 05DCA
	pop	bp			; 05DCD
	ret				; 05DCE
	push	bp			; 05DCF
	sub	sp,0x2			; 05DD0
	db	0x8B, 0xEC		; 05DD3 mov bp,sp
	mov	ax,0x1			; 05DD5
	push	ax			; 05DD8
	call	dos_int21		; 05DD9
	db	0x8B, 0xE5		; 05DDC mov sp,bp
	add	sp,0x2			; 05DDE
	pop	bp			; 05DE1
	ret				; 05DE2

; ---- function dos_putchar ----
dos_putchar:
	push	bp			; 05DE3
	db	0x8B, 0xEC		; 05DE4 mov bp,sp
	push	word [bp+0x4]		; 05DE6
	mov	ax,0x2			; 05DE9
	push	ax			; 05DEC
	call	dos_int21		; 05DED
	db	0x8B, 0xE5		; 05DF0 mov sp,bp
	mov	ax,[bp+0x4]		; 05DF2
	pop	bp			; 05DF5
	ret				; 05DF6
	push	bp			; 05DF7
	sub	sp,0x2			; 05DF8
	db	0x8B, 0xEC		; 05DFB mov bp,sp
	mov	ax,0x3			; 05DFD
	push	ax			; 05E00
	call	dos_int21		; 05E01
	db	0x8B, 0xE5		; 05E04 mov sp,bp
	add	sp,0x2			; 05E06
	pop	bp			; 05E09
	ret				; 05E0A
	push	bp			; 05E0B
	db	0x8B, 0xEC		; 05E0C mov bp,sp
	push	word [bp+0x4]		; 05E0E
	mov	ax,0x4			; 05E11
	push	ax			; 05E14
	call	dos_int21		; 05E15
	db	0x8B, 0xE5		; 05E18 mov sp,bp
	mov	ax,[bp+0x4]		; 05E1A
	pop	bp			; 05E1D
	ret				; 05E1E
	push	bp			; 05E1F
	db	0x8B, 0xEC		; 05E20 mov bp,sp
	push	word [bp+0x4]		; 05E22
	mov	ax,0x5			; 05E25
	push	ax			; 05E28
	call	dos_int21		; 05E29
	db	0x8B, 0xE5		; 05E2C mov sp,bp
	mov	ax,[bp+0x4]		; 05E2E
	pop	bp			; 05E31
	ret				; 05E32

; ---- function parse_number ----
parse_number:
	push	bp			; 05E33
	sub	sp,0x1e			; 05E34
	db	0x8B, 0xEC		; 05E37 mov bp,sp
	db	0x33, 0xC0		; 05E39 xor ax,ax
	mov	si,[bp+0x22]		; 05E3B
	mov	bl,[si]			; 05E3E
	xor	bh,bh			; 05E40
	inc	bx			; 05E42
	mov	cl,[bx-0x1b3c]		; 05E43
	xor	ch,ch			; 05E47
	db	0x81, 0xE1, 0x04, 0x00	; 05E49 and cx,0x4
	mov	[bp+0xc],ax		; 05E4D
	mov	[bp+0xe],ax		; 05E50
	jz	short loc_05E85		; 05E53 jz 0x5e85
loc_05E55:
	mov	ax,[bp+0xe]		; 05E55
	mov	bx,0xa			; 05E58
	imul	bx			; 05E5B
	mov	si,[bp+0x22]		; 05E5D
	inc	word [bp+0x22]		; 05E60
	mov	bl,[si]			; 05E63
	xor	bh,bh			; 05E65
	db	0x81, 0xE3, 0x0F, 0x00	; 05E67 and bx,0xf
	db	0x03, 0xC3		; 05E6B add ax,bx
	mov	[bp+0xe],ax		; 05E6D
	mov	si,[bp+0x22]		; 05E70
	mov	al,[si]			; 05E73
	xor	ah,ah			; 05E75
	inc	ax			; 05E77
	db	0x8B, 0xF0		; 05E78 mov si,ax
	mov	al,[si-0x1b3c]		; 05E7A
	xor	ah,ah			; 05E7E
	db	0x25, 0x04, 0x00	; 05E80 and ax,0x4
	jnz	short loc_05E55		; 05E83 jnz 0x5e55
loc_05E85:
	mov	si,[bp+0x22]		; 05E85
	mov	al,[si]			; 05E88
	xor	ah,ah			; 05E8A
	db	0x3D, 0x6C, 0x00	; 05E8C cmp ax,0x6c
	jnz	short loc_05E99		; 05E8F jnz 0x5e99
	inc	word [bp+0x22]		; 05E91
	mov	word [bp+0xc],0x1	; 05E94
loc_05E99:
	call	word near [bp+0x24]	; 05E99
	mov	si,[bp+0x22]		; 05E9C
	mov	bl,[si]			; 05E9F
	xor	bh,bh			; 05EA1
	cmp	bx,0x63			; 05EA3
	mov	[bp+0x8],ax		; 05EA6
	jz	short loc_05EC1		; 05EA9 jz 0x5ec1
loc_05EAB:
	mov	si,[bp+0x8]		; 05EAB
	mov	al,[si-0x1b3b]		; 05EAE
	xor	ah,ah			; 05EB2
	db	0x25, 0x08, 0x00	; 05EB4 and ax,0x8
	jz	short loc_05EC1		; 05EB7 jz 0x5ec1
	call	word near [bp+0x24]	; 05EB9
	mov	[bp+0x8],ax		; 05EBC
	jmp	short loc_05EAB		; 05EBF jmp 0x5eab
loc_05EC1:
	mov	ax,[bp+0x8]		; 05EC1
	db	0x3D, 0xFF, 0xFF	; 05EC4 cmp ax,0xffff
	jnz	short loc_05ED5		; 05EC7 jnz 0x5ed5
	mov	si,[bp+0x26]		; 05EC9
	mov	[si],ax			; 05ECC
	db	0x33, 0xC0		; 05ECE xor ax,ax
	add	sp,0x1e			; 05ED0
	pop	bp			; 05ED3
	ret				; 05ED4
loc_05ED5:
	mov	si,[bp+0x22]		; 05ED5
	mov	al,[si]			; 05ED8
	xor	ah,ah			; 05EDA
	jmp	0x651b			; 05EDC
	db	0x33, 0xC0		; 05EDF xor ax,ax
	mov	bx,[bp+0xe]		; 05EE1
	test	bx,bx			; 05EE4
	mov	[bp+0x10],ax		; 05EE6
	jz	short loc_05EF0		; 05EE9 jz 0x5ef0
	cmp	bx,0x1			; 05EEB
	jng	short loc_05F16		; 05EEE jng 0x5f16
loc_05EF0:
	mov	ax,[bp+0x8]		; 05EF0
	db	0x3D, 0x2D, 0x00	; 05EF3 cmp ax,0x2d
	jz	short loc_05EFD		; 05EF6 jz 0x5efd
	db	0x3D, 0x2B, 0x00	; 05EF8 cmp ax,0x2b
	jnz	short loc_05F16		; 05EFB jnz 0x5f16
loc_05EFD:
	cmp	word [bp+0x8],0x2d	; 05EFD
	jnz	short loc_05F08		; 05F01 jnz 0x5f08
	mov	ax,0xffff		; 05F03
	jmp	short loc_05F0A		; 05F06 jmp 0x5f0a
loc_05F08:
	db	0x33, 0xC0		; 05F08 xor ax,ax
loc_05F0A:
	mov	[bp+0x10],ax		; 05F0A
	call	word near [bp+0x24]	; 05F0D
	dec	word [bp+0xe]		; 05F10
	mov	[bp+0x8],ax		; 05F13
loc_05F16:
	mov	si,[bp+0x8]		; 05F16
	mov	al,[si-0x1b3b]		; 05F19
	xor	ah,ah			; 05F1D
	db	0x25, 0x04, 0x00	; 05F1F and ax,0x4
	jnz	short loc_05F32		; 05F22 jnz 0x5f32
	db	0x8B, 0xC6		; 05F24 mov ax,si
	mov	si,[bp+0x26]		; 05F26
	mov	[si],ax			; 05F29
	db	0x33, 0xC0		; 05F2B xor ax,ax
	add	sp,0x1e			; 05F2D
	pop	bp			; 05F30
	ret				; 05F31
loc_05F32:
	mov	word [bp+0x14],0x0	; 05F32
	mov	word [bp+0x12],0x0	; 05F37
loc_05F3C:
	mov	ax,[bp+0x14]		; 05F3C
	mov	bx,[bp+0x12]		; 05F3F
	db	0x33, 0xC9		; 05F42 xor cx,cx
	mov	dx,0xa			; 05F44
	call	crt_mul_long		; 05F47
	mov	cx,[bp+0x8]		; 05F4A
	db	0x81, 0xE1, 0x0F, 0x00	; 05F4D and cx,0xf
	db	0x33, 0xD2		; 05F51 xor dx,dx
	test	cx,cx			; 05F53
	jns	short loc_05F58		; 05F55 jns 0x5f58
	dec	dx			; 05F57
loc_05F58:
	db	0x03, 0xD9		; 05F58 add bx,cx
	db	0x13, 0xC2		; 05F5A adc ax,dx
	mov	[bp+0x14],ax		; 05F5C
	mov	[bp+0x12],bx		; 05F5F
	call	word near [bp+0x24]	; 05F62
	mov	[bp+0x8],ax		; 05F65
	mov	ax,[bp+0xe]		; 05F68
	dec	ax			; 05F6B
	test	ax,ax			; 05F6C
	mov	[bp+0xe],ax		; 05F6E
	jz	short loc_05F81		; 05F71 jz 0x5f81
	mov	si,[bp+0x8]		; 05F73
	mov	al,[si-0x1b3b]		; 05F76
	xor	ah,ah			; 05F7A
	db	0x25, 0x04, 0x00	; 05F7C and ax,0x4
	jnz	short loc_05F3C		; 05F7F jnz 0x5f3c
loc_05F81:
	cmp	word [bp+0x28],0x0	; 05F81
	jnz	short loc_05F8A		; 05F85 jnz 0x5f8a
	jmp	0x6531			; 05F87
loc_05F8A:
	mov	ax,[bp+0x10]		; 05F8A
	test	ax,ax			; 05F8D
	jns	short loc_05F9B		; 05F8F jns 0x5f9b
	not	word [bp+0x14]		; 05F91
	neg	word [bp+0x12]		; 05F94
	sbb	word [bp+0x14],0xffffffffffffffff	; 05F97
loc_05F9B:
	cmp	word [bp+0xc],0x0	; 05F9B
	jnz	short loc_05FAE		; 05F9F jnz 0x5fae
	mov	di,[bp+0x28]		; 05FA1
	mov	si,[di]			; 05FA4
	mov	ax,[bp+0x12]		; 05FA6
	mov	[si],ax			; 05FA9
	jmp	0x6531			; 05FAB
loc_05FAE:
	mov	di,[bp+0x28]		; 05FAE
	mov	si,[di]			; 05FB1
	mov	ax,[bp+0x14]		; 05FB3
	mov	bx,[bp+0x12]		; 05FB6
	mov	[si+0x2],ax		; 05FB9
	mov	[si],bx			; 05FBC
	jmp	0x6531			; 05FBE
	mov	ax,[bp+0x8]		; 05FC1
	db	0x3D, 0x30, 0x00	; 05FC4 cmp ax,0x30
	jl	short loc_05FCE		; 05FC7 jl 0x5fce
	db	0x3D, 0x37, 0x00	; 05FC9 cmp ax,0x37
	jng	short loc_05FDD		; 05FCC jng 0x5fdd
loc_05FCE:
	mov	ax,[bp+0x8]		; 05FCE
	mov	si,[bp+0x26]		; 05FD1
	mov	[si],ax			; 05FD4
	db	0x33, 0xC0		; 05FD6 xor ax,ax
	add	sp,0x1e			; 05FD8
	pop	bp			; 05FDB
	ret				; 05FDC
loc_05FDD:
	mov	word [bp+0x14],0x0	; 05FDD
	mov	word [bp+0x12],0x0	; 05FE2
loc_05FE7:
	mov	cx,0x3			; 05FE7
	mov	ax,[bp+0x14]		; 05FEA
	mov	bx,[bp+0x12]		; 05FED
	shl	bx,1			; 05FF0
	rcl	ax,1			; 05FF2
	loop	0x5ff0			; 05FF4
	mov	cx,[bp+0x8]		; 05FF6
	db	0x81, 0xE1, 0x07, 0x00	; 05FF9 and cx,0x7
	db	0x33, 0xD2		; 05FFD xor dx,dx
	test	cx,cx			; 05FFF
	jns	short loc_06004		; 06001 jns 0x6004
	dec	dx			; 06003
loc_06004:
	db	0x03, 0xD9		; 06004 add bx,cx
	db	0x13, 0xC2		; 06006 adc ax,dx
	mov	[bp+0x14],ax		; 06008
	mov	[bp+0x12],bx		; 0600B
	call	word near [bp+0x24]	; 0600E
	mov	[bp+0x8],ax		; 06011
	mov	ax,[bp+0xe]		; 06014
	dec	ax			; 06017
	test	ax,ax			; 06018
	mov	[bp+0xe],ax		; 0601A
	jz	short loc_0602B		; 0601D jz 0x602b
	cmp	word [bp+0x8],0x30	; 0601F
	jl	short loc_0602B		; 06023 jl 0x602b
	cmp	word [bp+0x8],0x37	; 06025
	jng	short loc_05FE7		; 06029 jng 0x5fe7
loc_0602B:
	cmp	word [bp+0x28],0x0	; 0602B
	jnz	short loc_06034		; 0602F jnz 0x6034
	jmp	0x6531			; 06031
loc_06034:
	cmp	word [bp+0xc],0x0	; 06034
	jnz	short loc_06047		; 06038 jnz 0x6047
	mov	di,[bp+0x28]		; 0603A
	mov	si,[di]			; 0603D
	mov	ax,[bp+0x12]		; 0603F
	mov	[si],ax			; 06042
	jmp	0x6531			; 06044
loc_06047:
	mov	di,[bp+0x28]		; 06047
	mov	si,[di]			; 0604A
	mov	ax,[bp+0x14]		; 0604C
	mov	bx,[bp+0x12]		; 0604F
	mov	[si+0x2],ax		; 06052
	mov	[si],bx			; 06055
	jmp	0x6531			; 06057
	mov	si,[bp+0x8]		; 0605A
	mov	al,[si-0x1b3b]		; 0605D
	xor	ah,ah			; 06061
	and	ax,0x80			; 06063
	jnz	short loc_06076		; 06066 jnz 0x6076
	db	0x8B, 0xC6		; 06068 mov ax,si
	mov	si,[bp+0x26]		; 0606A
	mov	[si],ax			; 0606D
	db	0x33, 0xC0		; 0606F xor ax,ax
	add	sp,0x1e			; 06071
	pop	bp			; 06074
	ret				; 06075
loc_06076:
	mov	ax,[bp+0x8]		; 06076
	mov	[bp+0xa],ax		; 06079
	call	word near [bp+0x24]	; 0607C
	mov	bx,[bp+0xe]		; 0607F
	test	bx,bx			; 06082
	mov	[bp+0x8],ax		; 06084
	jz	short loc_0608E		; 06087 jz 0x608e
	cmp	bx,0x2			; 06089
	jng	short loc_060D0		; 0608C jng 0x60d0
loc_0608E:
	cmp	word [bp+0xa],0x30	; 0608E
	jnz	short loc_060D0		; 06092 jnz 0x60d0
	mov	ax,[bp+0x8]		; 06094
	db	0x3D, 0x78, 0x00	; 06097 cmp ax,0x78
	jz	short loc_060A1		; 0609A jz 0x60a1
	db	0x3D, 0x58, 0x00	; 0609C cmp ax,0x58
	jnz	short loc_060D0		; 0609F jnz 0x60d0
loc_060A1:
	call	word near [bp+0x24]	; 060A1
	db	0x8B, 0xF0		; 060A4 mov si,ax
	mov	bl,[si-0x1b3b]		; 060A6
	xor	bh,bh			; 060AA
	and	bx,0x80			; 060AC
	mov	[bp+0x8],ax		; 060B0
	jnz	short loc_060C1		; 060B3 jnz 0x60c1
	mov	si,[bp+0x26]		; 060B5
	mov	[si],ax			; 060B8
	db	0x33, 0xC0		; 060BA xor ax,ax
	add	sp,0x1e			; 060BC
	pop	bp			; 060BF
	ret				; 060C0
loc_060C1:
	mov	word [bp+0x14],0x0	; 060C1
	mov	word [bp+0x12],0x0	; 060C6
	dec	word [bp+0xe]		; 060CB
	jmp	short loc_06130		; 060CE jmp 0x6130
loc_060D0:
	mov	si,[bp+0xa]		; 060D0
	mov	al,[si-0x1b3b]		; 060D3
	xor	ah,ah			; 060D7
	db	0x25, 0x04, 0x00	; 060D9 and ax,0x4
	jz	short loc_060F0		; 060DC jz 0x60f0
	db	0x8B, 0xC6		; 060DE mov ax,si
	db	0x2D, 0x30, 0x00	; 060E0 sub ax,0x30
	db	0x33, 0xDB		; 060E3 xor bx,bx
	test	ax,ax			; 060E5
	jns	short loc_060EA		; 060E7 jns 0x60ea
	dec	bx			; 060E9
loc_060EA:
	mov	[bp+0x12],ax		; 060EA
	mov	[bp+0x14],bx		; 060ED
loc_060F0:
	mov	si,[bp+0xa]		; 060F0
	mov	al,[si-0x1b3b]		; 060F3
	xor	ah,ah			; 060F7
	db	0x25, 0x01, 0x00	; 060F9 and ax,0x1
	jz	short loc_06110		; 060FC jz 0x6110
	db	0x8B, 0xC6		; 060FE mov ax,si
	db	0x2D, 0x37, 0x00	; 06100 sub ax,0x37
	db	0x33, 0xDB		; 06103 xor bx,bx
	test	ax,ax			; 06105
	jns	short loc_0610A		; 06107 jns 0x610a
	dec	bx			; 06109
loc_0610A:
	mov	[bp+0x12],ax		; 0610A
	mov	[bp+0x14],bx		; 0610D
loc_06110:
	mov	si,[bp+0xa]		; 06110
	mov	al,[si-0x1b3b]		; 06113
	xor	ah,ah			; 06117
	db	0x25, 0x02, 0x00	; 06119 and ax,0x2
	jz	short loc_06130		; 0611C jz 0x6130
	db	0x8B, 0xC6		; 0611E mov ax,si
	db	0x2D, 0x57, 0x00	; 06120 sub ax,0x57
	db	0x33, 0xDB		; 06123 xor bx,bx
	test	ax,ax			; 06125
	jns	short loc_0612A		; 06127 jns 0x612a
	dec	bx			; 06129
loc_0612A:
	mov	[bp+0x12],ax		; 0612A
	mov	[bp+0x14],bx		; 0612D
loc_06130:
	mov	ax,[bp+0xe]		; 06130
	dec	ax			; 06133
	test	ax,ax			; 06134
	mov	[bp+0xe],ax		; 06136
	jnz	short loc_0613E		; 06139 jnz 0x613e
	jmp	0x63c8			; 0613B
loc_0613E:
	mov	si,[bp+0x8]		; 0613E
	mov	al,[si-0x1b3b]		; 06141
	xor	ah,ah			; 06145
	and	ax,0x80			; 06147
	jz	short loc_061C8		; 0614A jz 0x61c8
	mov	cx,0x4			; 0614C
	mov	ax,[bp+0x14]		; 0614F
	mov	bx,[bp+0x12]		; 06152
	shl	bx,1			; 06155
	rcl	ax,1			; 06157
	loop	0x6155			; 06159
	mov	cl,[si-0x1b3b]		; 0615B
	xor	ch,ch			; 0615F
	db	0x81, 0xE1, 0x04, 0x00	; 06161 and cx,0x4
	mov	[bp+0x14],ax		; 06165
	mov	[bp+0x12],bx		; 06168
	jz	short loc_0617F		; 0616B jz 0x617f
	db	0x8B, 0xCE		; 0616D mov cx,si
	sub	cx,0x30			; 0616F
	db	0x33, 0xD2		; 06172 xor dx,dx
	test	cx,cx			; 06174
	jns	short loc_06179		; 06176 jns 0x6179
	dec	dx			; 06178
loc_06179:
	or	[bp+0x14],dx		; 06179
	or	[bp+0x12],cx		; 0617C
loc_0617F:
	mov	si,[bp+0x8]		; 0617F
	mov	al,[si-0x1b3b]		; 06182
	xor	ah,ah			; 06186
	db	0x25, 0x01, 0x00	; 06188 and ax,0x1
	jz	short loc_0619F		; 0618B jz 0x619f
	db	0x8B, 0xC6		; 0618D mov ax,si
	db	0x2D, 0x37, 0x00	; 0618F sub ax,0x37
	db	0x33, 0xDB		; 06192 xor bx,bx
	test	ax,ax			; 06194
	jns	short loc_06199		; 06196 jns 0x6199
	dec	bx			; 06198
loc_06199:
	or	[bp+0x14],bx		; 06199
	or	[bp+0x12],ax		; 0619C
loc_0619F:
	mov	si,[bp+0x8]		; 0619F
	mov	al,[si-0x1b3b]		; 061A2
	xor	ah,ah			; 061A6
	db	0x25, 0x02, 0x00	; 061A8 and ax,0x2
	jz	short loc_061BF		; 061AB jz 0x61bf
	db	0x8B, 0xC6		; 061AD mov ax,si
	db	0x2D, 0x57, 0x00	; 061AF sub ax,0x57
	db	0x33, 0xDB		; 061B2 xor bx,bx
	test	ax,ax			; 061B4
	jns	short loc_061B9		; 061B6 jns 0x61b9
	dec	bx			; 061B8
loc_061B9:
	or	[bp+0x14],bx		; 061B9
	or	[bp+0x12],ax		; 061BC
loc_061BF:
	call	word near [bp+0x24]	; 061BF
	mov	[bp+0x8],ax		; 061C2
	jmp	0x6330			; 061C5
loc_061C8:
	cmp	word [bp+0x28],0x0	; 061C8
	jnz	short loc_061D1		; 061CC jnz 0x61d1
	jmp	0x6531			; 061CE
loc_061D1:
	cmp	word [bp+0xc],0x0	; 061D1
	jnz	short loc_061E4		; 061D5 jnz 0x61e4
	mov	di,[bp+0x28]		; 061D7
	mov	si,[di]			; 061DA
	mov	ax,[bp+0x12]		; 061DC
	mov	[si],ax			; 061DF
	jmp	0x6531			; 061E1
loc_061E4:
	mov	di,[bp+0x28]		; 061E4
	mov	si,[di]			; 061E7
	mov	ax,[bp+0x14]		; 061E9
	mov	bx,[bp+0x12]		; 061EC
	mov	[si+0x2],ax		; 061EF
	mov	[si],bx			; 061F2
	jmp	0x6531			; 061F4
	mov	si,[bp+0x8]		; 061F7
	mov	al,[si-0x1b3b]		; 061FA
	xor	ah,ah			; 061FE
	db	0x25, 0x04, 0x00	; 06200 and ax,0x4
	jnz	short loc_06213		; 06203 jnz 0x6213
	db	0x8B, 0xC6		; 06205 mov ax,si
	mov	si,[bp+0x26]		; 06207
	mov	[si],ax			; 0620A
	db	0x33, 0xC0		; 0620C xor ax,ax
	add	sp,0x1e			; 0620E
	pop	bp			; 06211
	ret				; 06212
loc_06213:
	mov	word [bp+0x10],0x0	; 06213
loc_06218:
	mov	ax,[bp+0x10]		; 06218
	mov	bx,0xa			; 0621B
	imul	bx			; 0621E
	mov	bx,[bp+0x8]		; 06220
	db	0x81, 0xE3, 0x0F, 0x00	; 06223 and bx,0xf
	db	0x03, 0xC3		; 06227 add ax,bx
	mov	[bp+0x10],ax		; 06229
	call	word near [bp+0x24]	; 0622C
	mov	[bp+0x8],ax		; 0622F
	mov	ax,[bp+0xe]		; 06232
	dec	ax			; 06235
	test	ax,ax			; 06236
	mov	[bp+0xe],ax		; 06238
	jz	short loc_0624B		; 0623B jz 0x624b
	mov	si,[bp+0x8]		; 0623D
	mov	al,[si-0x1b3b]		; 06240
	xor	ah,ah			; 06244
	db	0x25, 0x04, 0x00	; 06246 and ax,0x4
	jnz	short loc_06218		; 06249 jnz 0x6218
loc_0624B:
	cmp	word [bp+0x28],0x0	; 0624B
	jnz	short loc_06254		; 0624F jnz 0x6254
	jmp	0x6531			; 06251
loc_06254:
	mov	di,[bp+0x28]		; 06254
	mov	si,[di]			; 06257
	mov	ax,[bp+0x10]		; 06259
	mov	[si],ax			; 0625C
	jmp	0x6531			; 0625E
	cmp	word [bp+0x28],0x0	; 06261
	jz	short loc_06275		; 06265 jz 0x6275
	mov	si,[bp+0x28]		; 06267
	mov	ax,[si]			; 0626A
	inc	word [si]		; 0626C
	mov	bx,[bp+0x8]		; 0626E
	db	0x8B, 0xF0		; 06271 mov si,ax
	mov	[si],bl			; 06273
loc_06275:
	mov	ax,[bp+0xe]		; 06275
	dec	ax			; 06278
	test	ax,ax			; 06279
	mov	[bp+0xe],ax		; 0627B
	jng	short loc_0629F		; 0627E jng 0x629f
	call	word near [bp+0x24]	; 06280
	mov	[bp+0x8],ax		; 06283
	inc	ax			; 06286
	jz	short loc_0629F		; 06287 jz 0x629f
	cmp	word [bp+0x28],0x0	; 06289
	jz	short loc_06275		; 0628D jz 0x6275
	mov	si,[bp+0x28]		; 0628F
	mov	ax,[si]			; 06292
	inc	word [si]		; 06294
	mov	bx,[bp+0x8]		; 06296
	db	0x8B, 0xF0		; 06299 mov si,ax
	mov	[si],bl			; 0629B
	jmp	short loc_06275		; 0629D jmp 0x6275
loc_0629F:
	mov	ax,[bp+0x8]		; 0629F
	db	0x3D, 0xFF, 0xFF	; 062A2 cmp ax,0xffff
	jnz	short loc_062B3		; 062A5 jnz 0x62b3
	mov	si,[bp+0x26]		; 062A7
	mov	[si],ax			; 062AA
	db	0x33, 0xC0		; 062AC xor ax,ax
	add	sp,0x1e			; 062AE
	pop	bp			; 062B1
	ret				; 062B2
loc_062B3:
	mov	ax,[bp+0x22]		; 062B3
	inc	ax			; 062B6
	add	sp,0x1e			; 062B7
	pop	bp			; 062BA
	ret				; 062BB
loc_062BC:
	cmp	word [bp+0x28],0x0	; 062BC
	jz	short loc_062D0		; 062C0 jz 0x62d0
	mov	si,[bp+0x28]		; 062C2
	mov	ax,[si]			; 062C5
	inc	word [si]		; 062C7
	mov	bx,[bp+0x8]		; 062C9
	db	0x8B, 0xF0		; 062CC mov si,ax
	mov	[si],bl			; 062CE
loc_062D0:
	call	word near [bp+0x24]	; 062D0
	mov	[bp+0x8],ax		; 062D3
	inc	ax			; 062D6
	jz	short loc_062F2		; 062D7 jz 0x62f2
	mov	ax,[bp+0xe]		; 062D9
	dec	ax			; 062DC
	test	ax,ax			; 062DD
	mov	[bp+0xe],ax		; 062DF
	jz	short loc_062F2		; 062E2 jz 0x62f2
	mov	si,[bp+0x8]		; 062E4
	mov	al,[si-0x1b3b]		; 062E7
	xor	ah,ah			; 062EB
	db	0x25, 0x08, 0x00	; 062ED and ax,0x8
	jz	short loc_062BC		; 062F0 jz 0x62bc
loc_062F2:
	mov	di,[bp+0x28]		; 062F2
	mov	si,[di]			; 062F5
	mov	byte [si],0x0		; 062F7
	jmp	short loc_06331		; 062FA jmp 0x6331
loc_062FC:
	db	0x33, 0xC0		; 062FC xor ax,ax
	add	sp,0x1e			; 062FE
	pop	bp			; 06301
	ret				; 06302
	jnc	short loc_06305		; 06303 jnc 0x6305
loc_06305:
	mov	sp,0x6362		; 06305
	add	[bx+di+0x62],ah		; 06308
	push	word 0xf700		; 0630B
	popa				; 0630E
	js	short loc_06311		; 0630F js 0x6311
loc_06311:
	pop	dx			; 06311
	pusha				; 06312
	outsw				; 06313
	add	cl,al			; 06314
	pop	di			; 06316
	fs	add bh,bl		; 06317
	pop	si			; 0631A
	mov	si,0x14			; 0631B
loc_0631E:
	cmp	ax,[cs:si+0x6303]	; 0631E
	jnz	short loc_0632A		; 06323 jnz 0x632a
	jmp	word near [cs:si+0x6305]	; 06325
loc_0632A:
	sub	si,0x4			; 0632A
	jns	short loc_0631E		; 0632D jns 0x631e
	jmp	short loc_062FC		; 0632F jmp 0x62fc
loc_06331:
	mov	ax,[bp+0x8]		; 06331
	mov	si,[bp+0x26]		; 06334
	mov	[si],ax			; 06337
	mov	ax,[bp+0x22]		; 06339
	inc	ax			; 0633C
	add	sp,0x1e			; 0633D
	pop	bp			; 06340
	ret				; 06341

; ---- function crt_file_read_byte ----
crt_file_read_byte:
	push	bp			; 06342
	sub	sp,0x8			; 06343
	db	0x8B, 0xEC		; 06346 mov bp,sp
	mov	si,[bp+0xc]		; 06348
	mov	al,[si+0x8]		; 0634B
	xor	ah,ah			; 0634E
	db	0x25, 0x30, 0x00	; 06350 and ax,0x30
	jz	short loc_0635D		; 06353 jz 0x635d
	mov	ax,0xffff		; 06355
	add	sp,0x8			; 06358
	pop	bp			; 0635B
	ret				; 0635C
loc_0635D:
	mov	si,[bp+0xc]		; 0635D
	cmp	word [si+0xa],0x0	; 06360
	jnz	short loc_06382		; 06364 jnz 0x6382
	mov	al,[si+0x8]		; 06366
	xor	ah,ah			; 06369
	db	0x25, 0x04, 0x00	; 0636B and ax,0x4
	jnz	short loc_06382		; 0636E jnz 0x6382
	push	si			; 06370
	call	crt_alloc_file_buffer	; 06371
	db	0x8B, 0xE5		; 06374 mov sp,bp
	test	ax,ax			; 06376
	jz	short loc_06382		; 06378 jz 0x6382
	mov	ax,0xffff		; 0637A
	add	sp,0x8			; 0637D
	pop	bp			; 06380
	ret				; 06381
loc_06382:
	mov	si,[bp+0xc]		; 06382
	mov	al,[si+0x8]		; 06385
	xor	ah,ah			; 06388
	db	0x25, 0x04, 0x00	; 0638A and ax,0x4
	jz	short loc_06396		; 0638D jz 0x6396
	mov	word [bp+0x6],0x1	; 0638F
	jmp	short loc_063BF		; 06394 jmp 0x63bf
loc_06396:
	mov	si,[bp+0xc]		; 06396
	mov	al,[si+0x8]		; 06399
	xor	ah,ah			; 0639C
	db	0x25, 0x02, 0x00	; 0639E and ax,0x2
	jz	short loc_063AB		; 063A1 jz 0x63ab
	mov	ax,0xffff		; 063A3
	add	sp,0x8			; 063A6
	pop	bp			; 063A9
	ret				; 063AA
loc_063AB:
	mov	si,[bp+0xc]		; 063AB
	mov	al,[si+0x8]		; 063AE
	xor	ah,ah			; 063B1
	db	0x0D, 0x01, 0x00	; 063B3 or ax,0x1
	mov	[si+0x8],al		; 063B6
	mov	ax,[si+0xa]		; 063B9
	mov	[bp+0x6],ax		; 063BC
loc_063BF:
	mov	si,[bp+0xc]		; 063BF
	mov	al,[si+0x9]		; 063C2
	xor	ah,ah			; 063C5
	push	word [bp+0x6]		; 063C7
	push	word [si+0x6]		; 063CA
	push	ax			; 063CD
	call	load_file		; 063CE
	db	0x8B, 0xE5		; 063D1 mov sp,bp
	test	ax,ax			; 063D3
	mov	[bp+0x4],ax		; 063D5
	jns	short loc_063E8		; 063D8 jns 0x63e8
	mov	si,[bp+0xc]		; 063DA
	mov	al,[si+0x8]		; 063DD
	xor	ah,ah			; 063E0
	db	0x0D, 0x20, 0x00	; 063E2 or ax,0x20
	mov	[si+0x8],al		; 063E5
loc_063E8:
	cmp	word [bp+0x4],0x0	; 063E8
	jnz	short loc_063FC		; 063EC jnz 0x63fc
	mov	si,[bp+0xc]		; 063EE
	mov	al,[si+0x8]		; 063F1
	xor	ah,ah			; 063F4
	db	0x0D, 0x10, 0x00	; 063F6 or ax,0x10
	mov	[si+0x8],al		; 063F9
loc_063FC:
	mov	ax,[bp+0x4]		; 063FC
	test	ax,ax			; 063FF
	jng	short loc_0640E		; 06401 jng 0x640e
	mov	si,[bp+0xc]		; 06403
	mov	[si+0x2],ax		; 06406
	mov	ax,[si+0x6]		; 06409
	mov	[si],ax			; 0640C
loc_0640E:
	mov	si,[bp+0xc]		; 0640E
	mov	al,[si+0x8]		; 06411
	xor	ah,ah			; 06414
	db	0x25, 0x30, 0x00	; 06416 and ax,0x30
	jz	short loc_06423		; 06419 jz 0x6423
	mov	ax,0xffff		; 0641B
	add	sp,0x8			; 0641E
	pop	bp			; 06421
	ret				; 06422
loc_06423:
	mov	si,[bp+0xc]		; 06423
	mov	ax,[si+0x2]		; 06426
	dec	ax			; 06429
	mov	[si+0x2],ax		; 0642A
	test	ax,ax			; 0642D
	js	short loc_0643D		; 0642F js 0x643d
	mov	ax,[si]			; 06431
	inc	word [si]		; 06433
	db	0x8B, 0xF8		; 06435 mov di,ax
	mov	bl,[di]			; 06437
	xor	bh,bh			; 06439
	jmp	short loc_06447		; 0643B jmp 0x6447
loc_0643D:
	push	word [bp+0xc]		; 0643D
	call	crt_file_read_byte	; 06440
	db	0x8B, 0xE5		; 06443 mov sp,bp
	db	0x8B, 0xD8		; 06445 mov bx,ax
loc_06447:
	db	0x8B, 0xC3		; 06447 mov ax,bx
	add	sp,0x8			; 06449
	pop	bp			; 0644C
	ret				; 0644D

; ---- function crt_file_write_byte ----
crt_file_write_byte:
	push	bp			; 0644E
	sub	sp,0xc			; 0644F
	db	0x8B, 0xEC		; 06452 mov bp,sp
	mov	ax,[bp+0x10]		; 06454
	mov	si,[bp+0x12]		; 06457
	mov	bl,[si+0x8]		; 0645A
	xor	bh,bh			; 0645D
	db	0x81, 0xE3, 0x30, 0x00	; 0645F and bx,0x30
	mov	[bp+0x7],ax		; 06463
	jz	short loc_06470		; 06466 jz 0x6470
	mov	ax,0xffff		; 06468
	add	sp,0xc			; 0646B
	pop	bp			; 0646E
	ret				; 0646F
loc_06470:
	mov	si,[bp+0x12]		; 06470
	cmp	word [si+0xa],0x0	; 06473
	jnz	short loc_064E3		; 06477 jnz 0x64e3
	mov	al,[si+0x8]		; 06479
	xor	ah,ah			; 0647C
	db	0x25, 0x04, 0x00	; 0647E and ax,0x4
	jnz	short loc_064E3		; 06481 jnz 0x64e3
	cmp	word [bp+0x10],0xffffffffffffffff	; 06483
	jnz	short loc_06490		; 06487 jnz 0x6490
	db	0x33, 0xC0		; 06489 xor ax,ax
	add	sp,0xc			; 0648B
	pop	bp			; 0648E
	ret				; 0648F
loc_06490:
	push	word [bp+0x12]		; 06490
	call	crt_alloc_file_buffer	; 06493
	db	0x8B, 0xE5		; 06496 mov sp,bp
	test	ax,ax			; 06498
	jz	short loc_064A4		; 0649A jz 0x64a4
	mov	ax,0xffff		; 0649C
	add	sp,0xc			; 0649F
	pop	bp			; 064A2
	ret				; 064A3
loc_064A4:
	mov	si,[bp+0x12]		; 064A4
	mov	al,[si+0x8]		; 064A7
	xor	ah,ah			; 064AA
	db	0x0D, 0x02, 0x00	; 064AC or ax,0x2
	mov	[si+0x8],al		; 064AF
	mov	ax,[si+0xa]		; 064B2
	mov	[si+0x4],ax		; 064B5
	dec	ax			; 064B8
	mov	[si+0x4],ax		; 064B9
	test	ax,ax			; 064BC
	js	short loc_064CF		; 064BE js 0x64cf
	mov	ax,[si]			; 064C0
	inc	word [si]		; 064C2
	mov	bx,[bp+0x10]		; 064C4
	db	0x8B, 0xF8		; 064C7 mov di,ax
	mov	[di],bl			; 064C9
	xor	bh,bh			; 064CB
	jmp	short loc_064DC		; 064CD jmp 0x64dc
loc_064CF:
	push	word [bp+0x12]		; 064CF
	push	word [bp+0x10]		; 064D2
	call	crt_file_write_byte	; 064D5
	db	0x8B, 0xE5		; 064D8 mov sp,bp
	db	0x8B, 0xD8		; 064DA mov bx,ax
loc_064DC:
	db	0x8B, 0xC3		; 064DC mov ax,bx
	add	sp,0xc			; 064DE
	pop	bp			; 064E1
	ret				; 064E2
loc_064E3:
	mov	si,[bp+0x12]		; 064E3
	mov	al,[si+0x8]		; 064E6
	xor	ah,ah			; 064E9
	db	0x25, 0x04, 0x00	; 064EB and ax,0x4
	jz	short loc_06528		; 064EE jz 0x6528
	cmp	word [bp+0x10],0xffffffffffffffff	; 064F0
	jnz	short loc_064FD		; 064F4 jnz 0x64fd
	db	0x33, 0xC0		; 064F6 xor ax,ax
	add	sp,0xc			; 064F8
	pop	bp			; 064FB
	ret				; 064FC
loc_064FD:
	mov	ax,[bp+0x10]		; 064FD
	mov	si,[bp+0x12]		; 06500
	mov	bl,[si+0x9]		; 06503
	xor	bh,bh			; 06506
	mov	word [bp+0x9],0x1	; 06508
	push	word [bp+0x9]		; 0650D
	lea	cx,[bp+0x4]		; 06510
	push	cx			; 06513
	push	bx			; 06514
	mov	[bp+0x4],al		; 06515
	call	write_file_data		; 06518
	db	0x8B, 0xE5		; 0651B mov sp,bp
	mov	word [bp+0x10],0xffff	; 0651D
	mov	[bp+0x5],ax		; 06522
	jmp	0x67c9			; 06525
loc_06528:
	mov	si,[bp+0x12]		; 06528
	mov	al,[si+0x8]		; 0652B
	xor	ah,ah			; 0652E
	db	0x25, 0x01, 0x00	; 06530 and ax,0x1
	jz	short loc_0653D		; 06533 jz 0x653d
	mov	ax,0xffff		; 06535
	add	sp,0xc			; 06538
	pop	bp			; 0653B
	ret				; 0653C
loc_0653D:
	mov	si,[bp+0x12]		; 0653D
	mov	al,[si+0x8]		; 06540
	xor	ah,ah			; 06543
	db	0x0D, 0x02, 0x00	; 06545 or ax,0x2
	mov	[si+0x8],al		; 06548
	cmp	word [bp+0x10],0xffffffffffffffff	; 0654B
	jz	short loc_06583		; 0654F jz 0x6583
	cmp	word [si+0x4],0x0	; 06551
	jng	short loc_06583		; 06555 jng 0x6583
	mov	ax,[si+0x4]		; 06557
	dec	ax			; 0655A
	mov	[si+0x4],ax		; 0655B
	test	ax,ax			; 0655E
	js	short loc_06571		; 06560 js 0x6571
	mov	ax,[si]			; 06562
	inc	word [si]		; 06564
	mov	bx,[bp+0x10]		; 06566
	db	0x8B, 0xF8		; 06569 mov di,ax
	mov	[di],bl			; 0656B
	xor	bh,bh			; 0656D
	jmp	short loc_0657E		; 0656F jmp 0x657e
loc_06571:
	push	word [bp+0x12]		; 06571
	push	word [bp+0x10]		; 06574
	call	crt_file_write_byte	; 06577
	db	0x8B, 0xE5		; 0657A mov sp,bp
	db	0x8B, 0xD8		; 0657C mov bx,ax
loc_0657E:
	mov	word [bp+0x10],0xffff	; 0657E
loc_06583:
	mov	si,[bp+0x12]		; 06583
	mov	ax,[si]			; 06586
	cmp	ax,[si+0x6]		; 06588
	jz	short loc_065C1		; 0658B jz 0x65c1
	mov	ax,[si+0x4]		; 0658D
	test	ax,ax			; 06590
	jns	short loc_0659C		; 06592 jns 0x659c
	mov	ax,[si+0xa]		; 06594
	mov	[bp+0x9],ax		; 06597
	jmp	short loc_065A8		; 0659A jmp 0x65a8
loc_0659C:
	mov	si,[bp+0x12]		; 0659C
	mov	ax,[si+0xa]		; 0659F
	sub	ax,[si+0x4]		; 065A2
	mov	[bp+0x9],ax		; 065A5
loc_065A8:
	mov	si,[bp+0x12]		; 065A8
	mov	al,[si+0x9]		; 065AB
	xor	ah,ah			; 065AE
	push	word [bp+0x9]		; 065B0
	push	word [si+0x6]		; 065B3
	push	ax			; 065B6
	call	write_file_data		; 065B7
	db	0x8B, 0xE5		; 065BA mov sp,bp
	mov	[bp+0x5],ax		; 065BC
	jmp	short loc_065C9		; 065BF jmp 0x65c9
loc_065C1:
	db	0x33, 0xC0		; 065C1 xor ax,ax
	mov	[bp+0x5],ax		; 065C3
	mov	[bp+0x9],ax		; 065C6
loc_065C9:
	cmp	word [bp+0x5],0xffffffffffffffff	; 065C9
	jnz	short loc_065DF		; 065CD jnz 0x65df
	mov	si,[bp+0x12]		; 065CF
	mov	al,[si+0x8]		; 065D2
	xor	ah,ah			; 065D5
	db	0x0D, 0x20, 0x00	; 065D7 or ax,0x20
	mov	[si+0x8],al		; 065DA
	jmp	short loc_065F5		; 065DD jmp 0x65f5
loc_065DF:
	mov	ax,[bp+0x5]		; 065DF
	cmp	ax,[bp+0x9]		; 065E2
	jz	short loc_065F5		; 065E5 jz 0x65f5
	mov	si,[bp+0x12]		; 065E7
	mov	al,[si+0x8]		; 065EA
	xor	ah,ah			; 065ED
	db	0x0D, 0x10, 0x00	; 065EF or ax,0x10
	mov	[si+0x8],al		; 065F2
loc_065F5:
	mov	si,[bp+0x12]		; 065F5
	mov	ax,[si+0xa]		; 065F8
	mov	[si+0x4],ax		; 065FB
	mov	ax,[si+0x6]		; 065FE
	mov	[si],ax			; 06601
	mov	ax,[bp+0x10]		; 06603
	db	0x3D, 0xFF, 0xFF	; 06606 cmp ax,0xffff
	jz	short loc_0662B		; 06609 jz 0x662b
	mov	bx,[si+0x4]		; 0660B
	dec	bx			; 0660E
	mov	[si+0x4],bx		; 0660F
	test	bx,bx			; 06612
	js	short loc_06620		; 06614 js 0x6620
	mov	bx,[si]			; 06616
	inc	word [si]		; 06618
	mov	[bx],al			; 0661A
	xor	ah,ah			; 0661C
	jmp	short loc_0662B		; 0661E jmp 0x662b
loc_06620:
	push	word [bp+0x12]		; 06620
	push	word [bp+0x10]		; 06623
	call	crt_file_write_byte	; 06626
	db	0x8B, 0xE5		; 06629 mov sp,bp
loc_0662B:
	mov	si,[bp+0x12]		; 0662B
	mov	al,[si+0x8]		; 0662E
	xor	ah,ah			; 06631
	db	0x25, 0x30, 0x00	; 06633 and ax,0x30
	jz	short loc_06640		; 06636 jz 0x6640
	mov	ax,0xffff		; 06638
	add	sp,0xc			; 0663B
	pop	bp			; 0663E
	ret				; 0663F
loc_06640:
	cmp	word [bp+0x7],0xffffffffffffffff	; 06640
	jnz	short loc_0664D		; 06644 jnz 0x664d
	db	0x33, 0xC0		; 06646 xor ax,ax
	add	sp,0xc			; 06648
	pop	bp			; 0664B
	ret				; 0664C
loc_0664D:
	mov	ax,[bp+0x7]		; 0664D
	add	sp,0xc			; 06650
	pop	bp			; 06653
	ret				; 06654

; ---- function crt_alloc_file_buffer ----
crt_alloc_file_buffer:
	push	bp			; 06655
	sub	sp,0x2			; 06656
	db	0x8B, 0xEC		; 06659 mov bp,sp
	mov	si,[bp+0x6]		; 0665B
	cmp	word [si+0xa],0x0	; 0665E
	jz	short loc_06675		; 06662 jz 0x6675
	mov	al,[si+0x8]		; 06664
	xor	ah,ah			; 06667
	db	0x25, 0x08, 0x00	; 06669 and ax,0x8
	jnz	short loc_06675		; 0666C jnz 0x6675
	db	0x33, 0xC0		; 0666E xor ax,ax
	add	sp,0x2			; 06670
	pop	bp			; 06673
	ret				; 06674
loc_06675:
	push	word [0xe5c8]		; 06675
	call	string_copy		; 06679
	db	0x8B, 0xE5		; 0667C mov sp,bp
	mov	si,[bp+0x6]		; 0667E
	mov	[si],ax			; 06681
	mov	[si+0x6],ax		; 06683
	test	ax,ax			; 06686
	jnz	short loc_06698		; 06688 jnz 0x6698
	mov	word [0xe4be],0xc	; 0668A
	mov	ax,0xffff		; 06690
	add	sp,0x2			; 06693
	pop	bp			; 06696
	ret				; 06697
loc_06698:
	mov	ax,[0xe5c8]		; 06698
	mov	si,[bp+0x6]		; 0669B
	mov	[si+0xa],ax		; 0669E
	mov	al,[si+0x8]		; 066A1
	xor	ah,ah			; 066A4
	db	0x25, 0xF3, 0xFF	; 066A6 and ax,0xfff3
	mov	[si+0x8],al		; 066A9
	db	0x33, 0xC0		; 066AC xor ax,ax
	mov	[si+0x4],ax		; 066AE
	mov	[si+0x2],ax		; 066B1
	add	sp,0x2			; 066B4
	pop	bp			; 066B7
	ret				; 066B8

; ---- function strlen ----
strlen:
	push	bp			; 066B9
	sub	sp,0x4			; 066BA
	db	0x8B, 0xEC		; 066BD mov bp,sp
	mov	word [bp+0x2],0x0	; 066BF
loc_066C4:
	mov	si,[bp+0x8]		; 066C4
	add	si,[bp+0x2]		; 066C7
	mov	al,[si]			; 066CA
	xor	ah,ah			; 066CC
	test	ax,ax			; 066CE
	jz	short loc_066D7		; 066D0 jz 0x66d7
	inc	word [bp+0x2]		; 066D2
	jmp	short loc_066C4		; 066D5 jmp 0x66c4
loc_066D7:
	mov	ax,[bp+0x2]		; 066D7
	add	sp,0x4			; 066DA
	pop	bp			; 066DD
	ret				; 066DE

; ---- function format_string ----
format_string:
	push	bp			; 066DF
	sub	sp,0x2			; 066E0
	db	0x8B, 0xEC		; 066E3 mov bp,sp
	push	word [bp+0x6]		; 066E5
	call	crt_file_reset_buffer	; 066E8
	db	0x8B, 0xE5		; 066EB mov sp,bp
	cmp	word [bp+0x8],0x0	; 066ED
	jnz	short loc_066FA		; 066F1 jnz 0x66fa
	db	0x33, 0xC0		; 066F3 xor ax,ax
	add	sp,0x2			; 066F5
	pop	bp			; 066F8
	ret				; 066F9
loc_066FA:
	mov	si,[bp+0x6]		; 066FA
	mov	al,[si+0x8]		; 066FD
	xor	ah,ah			; 06700
	db	0x25, 0xFB, 0xFF	; 06702 and ax,0xfffb
	mov	[si+0x8],al		; 06705
	xor	ah,ah			; 06708
	db	0x0D, 0x08, 0x00	; 0670A or ax,0x8
	mov	[si+0x8],al		; 0670D
	mov	ax,[bp+0x8]		; 06710
	mov	[si],ax			; 06713
	mov	[si+0x6],ax		; 06715
	mov	ax,[0xe5c8]		; 06718
	mov	[si+0xa],ax		; 0671B
	db	0x33, 0xC0		; 0671E xor ax,ax
	add	sp,0x2			; 06720
	pop	bp			; 06723
	ret				; 06724

; ---- function dos_read_line ----
dos_read_line:
	push	bp			; 06725
	db	0x8B, 0xEC		; 06726 mov bp,sp
	mov	dx,[bp+0x4]		; 06728
	mov	ah,0xa			; 0672B
	int	0x21			; 0672D
	pop	bp			; 0672F
	ret				; 06730

; ---- function heap_init_free_list ----
heap_init_free_list:
	push	bp			; 06731
	sub	sp,0x2			; 06732
	db	0x8B, 0xEC		; 06735 mov bp,sp
	mov	ax,[0xe4b6]		; 06737
	mov	bx,[0xe4b8]		; 0673A
	test	bx,bx			; 0673E
	mov	[0xe4ba],ax		; 06740
	mov	[0xe4bc],bx		; 06743
	jnz	short loc_06751		; 06747 jnz 0x6751
	mov	ax,0xffff		; 06749
	add	sp,0x2			; 0674C
	pop	bp			; 0674F
	ret				; 06750
loc_06751:
	mov	si,[0xe4ba]		; 06751
	db	0x33, 0xC0		; 06755 xor ax,ax
	mov	[si],ax			; 06757
	mov	ax,[0xe4bc]		; 06759
	mov	[si+0x2],ax		; 0675C
	db	0x33, 0xC0		; 0675F xor ax,ax
	add	sp,0x2			; 06761
	pop	bp			; 06764
	ret				; 06765
	push	bp			; 06766
	sub	sp,0x2			; 06767
	db	0x8B, 0xEC		; 0676A mov bp,sp
	db	0x33, 0xC0		; 0676C xor ax,ax
	push	ax			; 0676E
	call	heap_expand		; 0676F
	db	0x8B, 0xE5		; 06772 mov sp,bp
	add	sp,0x2			; 06774
	pop	bp			; 06777
	ret				; 06778

; ---- function heap_expand ----
heap_expand:
	push	bp			; 06779
	sub	sp,0x6			; 0677A
	db	0x8B, 0xEC		; 0677D mov bp,sp
	mov	ax,[bp+0xa]		; 0677F
	test	ax,ax			; 06782
	jns	short loc_0678E		; 06784 jns 0x678e
	mov	ax,0xffff		; 06786
	add	sp,0x6			; 06789
	pop	bp			; 0678C
	ret				; 0678D
loc_0678E:
	mov	word [0xe4b6],0x0	; 0678E
	mov	word [0xe4b8],0x0	; 06794
	mov	word [bp+0x4],0x100	; 0679A
	db	0x33, 0xC0		; 0679F xor ax,ax
	push	ax			; 067A1
	mov	bx,0x400		; 067A2
	push	bx			; 067A5
	call	heap_alloc		; 067A6
	db	0x8B, 0xE5		; 067A9 mov sp,bp
	test	ax,ax			; 067AB
	mov	[bp+0x2],ax		; 067AD
	jnz	short loc_067BA		; 067B0 jnz 0x67ba
	mov	ax,0xffff		; 067B2
	add	sp,0x6			; 067B5
	pop	bp			; 067B8
	ret				; 067B9
loc_067BA:
	mov	ax,[bp+0x2]		; 067BA
	mov	bx,[bp+0x4]		; 067BD
	mov	[0xe4b6],ax		; 067C0
	mov	[0xe4b8],bx		; 067C3
loc_067C7:
	mov	ax,[bp+0xa]		; 067C7
	dec	ax			; 067CA
	mov	[bp+0xa],ax		; 067CB
	test	ax,ax			; 067CE
	jz	short loc_067EB		; 067D0 jz 0x67eb
	db	0x33, 0xC0		; 067D2 xor ax,ax
	push	ax			; 067D4
	mov	bx,0x400		; 067D5
	push	bx			; 067D8
	call	heap_alloc		; 067D9
	db	0x8B, 0xE5		; 067DC mov sp,bp
	test	ax,ax			; 067DE
	jz	short loc_067EB		; 067E0 jz 0x67eb
	mov	ax,[bp+0x4]		; 067E2
	add	[0xe4b8],ax		; 067E5
	jmp	short loc_067C7		; 067E9 jmp 0x67c7
loc_067EB:
	call	heap_init_free_list	; 067EB
	db	0x33, 0xC0		; 067EE xor ax,ax
	add	sp,0x6			; 067F0
	pop	bp			; 067F3
	ret				; 067F4
	push	bp			; 067F5
	sub	sp,0x8			; 067F6
	db	0x8B, 0xEC		; 067F9 mov bp,sp
	mov	ax,[0xe4bc]		; 067FB
	shl	ax,1			; 067FE
	shl	ax,1			; 06800
	db	0x33, 0xDB		; 06802 xor bx,bx
	mov	[bp+0x4],ax		; 06804
	mov	[bp+0x6],bx		; 06807
	xchg	ax,bx			; 0680A
	add	sp,0x8			; 0680B
	pop	bp			; 0680E
	ret				; 0680F

; ---- function string_copy ----
string_copy:
	push	bp			; 06810
	sub	sp,0x8			; 06811
	db	0x8B, 0xEC		; 06814 mov bp,sp
	mov	ax,[bp+0xc]		; 06816
	db	0x33, 0xDB		; 06819 xor bx,bx
	push	bx			; 0681B
	push	ax			; 0681C
	mov	[bp+0x4],ax		; 0681D
	mov	[bp+0x6],bx		; 06820
	call	crt_malloc		; 06823
	db	0x8B, 0xE5		; 06826 mov sp,bp
	add	sp,0x8			; 06828
	pop	bp			; 0682B
	ret				; 0682C

; ---- function crt_malloc ----
crt_malloc:
	push	bp			; 0682D
	sub	sp,0x10			; 0682E
	db	0x8B, 0xEC		; 06831 mov bp,sp
	mov	ax,[bp+0x16]		; 06833
	mov	bx,[bp+0x14]		; 06836
	db	0x33, 0xC9		; 06839 xor cx,cx
	db	0x33, 0xD2		; 0683B xor dx,dx
	call	crt_cmp_long		; 0683D
	jg	short loc_06849		; 06840 jg 0x6849
	db	0x33, 0xC0		; 06842 xor ax,ax
	add	sp,0x10			; 06844
	pop	bp			; 06847
	ret				; 06848
loc_06849:
	mov	ax,[bp+0x14]		; 06849
	db	0x05, 0x04, 0x00	; 0684C add ax,0x4
	mov	bx,[bp+0x16]		; 0684F
	adc	bx,0x0			; 06852
	db	0x2D, 0x01, 0x00	; 06855 sub ax,0x1
	sbb	bx,0x0			; 06858
	mov	[bp+0x0],ax		; 0685B
	db	0x8B, 0xC3		; 0685E mov ax,bx
	mov	bx,[bp+0x0]		; 06860
	db	0x33, 0xC9		; 06863 xor cx,cx
	mov	dx,0x4			; 06865
	call	crt_long_multiply	; 06868
	mov	si,0xe4ba		; 0686B
	mov	cx,[si]			; 0686E
	mov	[bp+0xe],ax		; 06870
	mov	[bp+0x6],cx		; 06873
	mov	[bp+0xc],bx		; 06876
	mov	[bp+0x8],si		; 06879
loc_0687C:
	cmp	word [bp+0x6],0x0	; 0687C
	jz	short loc_068F0		; 06880 jz 0x68f0
	mov	si,[bp+0x6]		; 06882
	mov	ax,[si+0x2]		; 06885
	db	0x33, 0xDB		; 06888 xor bx,bx
	mov	[bp+0x0],ax		; 0688A
	db	0x8B, 0xC3		; 0688D mov ax,bx
	mov	[bp+0x2],bx		; 0688F
	mov	bx,[bp+0x0]		; 06892
	mov	cx,[bp+0xe]		; 06895
	mov	dx,[bp+0xc]		; 06898
	call	crt_cmp_long		; 0689B
	jl	short loc_068E1		; 0689E jl 0x68e1
	db	0x3B, 0xC1		; 068A0 cmp ax,cx
	jnz	short loc_068A6		; 068A2 jnz 0x68a6
	db	0x3B, 0xDA		; 068A4 cmp bx,dx
loc_068A6:
	jnz	short loc_068B1		; 068A6 jnz 0x68b1
	mov	ax,[si]			; 068A8
	mov	si,[bp+0x8]		; 068AA
	mov	[si],ax			; 068AD
	jmp	short loc_068C9		; 068AF jmp 0x68c9
loc_068B1:
	mov	si,[bp+0x6]		; 068B1
	mov	ax,[si+0x2]		; 068B4
	db	0x33, 0xDB		; 068B7 xor bx,bx
	sub	ax,[bp+0xc]		; 068B9
	sbb	bx,[bp+0xe]		; 068BC
	mov	[si+0x2],ax		; 068BF
	shl	ax,1			; 068C2
	shl	ax,1			; 068C4
	add	[bp+0x6],ax		; 068C6
loc_068C9:
	mov	ax,[0xe4bc]		; 068C9
	db	0x33, 0xDB		; 068CC xor bx,bx
	sub	ax,[bp+0xc]		; 068CE
	sbb	bx,[bp+0xe]		; 068D1
	mov	bx,[bp+0x6]		; 068D4
	mov	[0xe4bc],ax		; 068D7
	db	0x8B, 0xC3		; 068DA mov ax,bx
	add	sp,0x10			; 068DC
	pop	bp			; 068DF
	ret				; 068E0
loc_068E1:
	mov	ax,[bp+0x6]		; 068E1
	db	0x8B, 0xF0		; 068E4 mov si,ax
	mov	bx,[si]			; 068E6
	mov	[bp+0x8],ax		; 068E8
	mov	[bp+0x6],bx		; 068EB
	jmp	short loc_0687C		; 068EE jmp 0x687c
loc_068F0:
	mov	cx,0x2			; 068F0
	mov	ax,[bp+0xe]		; 068F3
	mov	bx,[bp+0xc]		; 068F6
	shl	bx,1			; 068F9
	rcl	ax,1			; 068FB
	loop	0x68f9			; 068FD
	push	ax			; 068FF
	push	bx			; 06900
	call	heap_alloc		; 06901
	db	0x8B, 0xE5		; 06904 mov sp,bp
	mov	[bp+0xa],ax		; 06906
	test	ax,ax			; 06909
	jz	short loc_0694D		; 0690B jz 0x694d
	cmp	word [0xe4b8],0x0	; 0690D
	jnz	short loc_06920		; 06912 jnz 0x6920
	mov	bx,[bp+0xc]		; 06914
	mov	[0xe4b6],ax		; 06917
	mov	[0xe4b8],bx		; 0691A
	jmp	short loc_06945		; 0691E jmp 0x6945
loc_06920:
	mov	ax,[0xe4b8]		; 06920
	shl	ax,1			; 06923
	shl	ax,1			; 06925
	mov	bx,[0xe4b6]		; 06927
	db	0x03, 0xD8		; 0692B add bx,ax
	mov	ax,[bp+0xa]		; 0692D
	db	0x3B, 0xC3		; 06930 cmp ax,bx
	mov	[bp+0x6],bx		; 06932
	jnz	short loc_06945		; 06935 jnz 0x6945
	mov	ax,[0xe4b8]		; 06937
	db	0x33, 0xDB		; 0693A xor bx,bx
	add	ax,[bp+0xc]		; 0693C
	adc	bx,[bp+0xe]		; 0693F
	mov	[0xe4b8],ax		; 06942
loc_06945:
	mov	ax,[bp+0xa]		; 06945
	add	sp,0x10			; 06948
	pop	bp			; 0694B
	ret				; 0694C
loc_0694D:
	db	0x33, 0xC0		; 0694D xor ax,ax
	add	sp,0x10			; 0694F
	pop	bp			; 06952
	ret				; 06953

; ---- function crt_free_small ----
crt_free_small:
	push	bp			; 06954
	sub	sp,0x8			; 06955
	db	0x8B, 0xEC		; 06958 mov bp,sp
	mov	ax,[bp+0xe]		; 0695A
	db	0x33, 0xDB		; 0695D xor bx,bx
	push	bx			; 0695F
	push	ax			; 06960
	push	word [bp+0xc]		; 06961
	mov	[bp+0x4],ax		; 06964
	mov	[bp+0x6],bx		; 06967
	call	crt_free		; 0696A
	db	0x8B, 0xE5		; 0696D mov sp,bp
	add	sp,0x8			; 0696F
	pop	bp			; 06972
	ret				; 06973

; ---- function crt_free ----
crt_free:
	push	bp			; 06974
	sub	sp,0x14			; 06975
	db	0x8B, 0xEC		; 06978 mov bp,sp
	mov	ax,[bp+0x1c]		; 0697A
	mov	bx,[bp+0x1a]		; 0697D
	db	0x33, 0xC9		; 06980 xor cx,cx
	db	0x33, 0xD2		; 06982 xor dx,dx
	call	crt_cmp_long		; 06984
	jg	short loc_06991		; 06987 jg 0x6991
	mov	ax,0xffff		; 06989
	add	sp,0x14			; 0698C
	pop	bp			; 0698F
	ret				; 06990
loc_06991:
	mov	ax,[bp+0x18]		; 06991
	mov	bx,[bp+0x1a]		; 06994
	add	bx,0x4			; 06997
	mov	cx,[bp+0x1c]		; 0699A
	adc	cx,0x0			; 0699D
	sub	bx,0x1			; 069A0
	sbb	cx,0x0			; 069A3
	mov	[bp+0xc],ax		; 069A6
	db	0x8B, 0xC1		; 069A9 mov ax,cx
	db	0x33, 0xC9		; 069AB xor cx,cx
	mov	dx,0x4			; 069AD
	call	crt_long_multiply	; 069B0
	mov	[bp+0x10],bx		; 069B3
	shl	bx,1			; 069B6
	shl	bx,1			; 069B8
	mov	cx,[bp+0xc]		; 069BA
	db	0x03, 0xCB		; 069BD add cx,bx
	mov	bx,[0xe4bc]		; 069BF
	db	0x33, 0xD2		; 069C3 xor dx,dx
	add	bx,[bp+0x10]		; 069C5
	db	0x13, 0xD0		; 069C8 adc dx,ax
	mov	si,0xe4ba		; 069CA
	mov	dx,[si]			; 069CD
	mov	[bp+0x12],ax		; 069CF
	mov	[bp+0xe],cx		; 069D2
	mov	[bp+0x4],dx		; 069D5
	mov	[0xe4bc],bx		; 069D8
	mov	[bp+0x8],si		; 069DC
	mov	ax,[bp+0x4]		; 069DF
	test	ax,ax			; 069E2
	jnz	short loc_069E9		; 069E4 jnz 0x69e9
	jmp	0x6cd9			; 069E6
loc_069E9:
	db	0x8B, 0xF0		; 069E9 mov si,ax
	mov	bx,[si+0x2]		; 069EB
	shl	bx,1			; 069EE
	shl	bx,1			; 069F0
	db	0x03, 0xD8		; 069F2 add bx,ax
	mov	cx,[bp+0xe]		; 069F4
	db	0x3B, 0xC8		; 069F7 cmp cx,ax
	mov	[bp+0x6],bx		; 069F9
	jnc	short loc_06A17		; 069FC jnc 0x6a17
	mov	si,[bp+0xc]		; 069FE
	mov	[si],ax			; 06A01
	mov	ax,[bp+0x10]		; 06A03
	mov	[si+0x2],ax		; 06A06
	db	0x8B, 0xC6		; 06A09 mov ax,si
	mov	si,[bp+0x8]		; 06A0B
	mov	[si],ax			; 06A0E
	db	0x33, 0xC0		; 06A10 xor ax,ax
	add	sp,0x14			; 06A12
	pop	bp			; 06A15
	ret				; 06A16
loc_06A17:
	mov	ax,[bp+0x4]		; 06A17
	cmp	ax,[bp+0xe]		; 06A1A
	jnz	short loc_06A48		; 06A1D jnz 0x6a48
	db	0x8B, 0xF0		; 06A1F mov si,ax
	mov	bx,[si]			; 06A21
	mov	di,[bp+0xc]		; 06A23
	mov	[di],bx			; 06A26
	mov	ax,[si+0x2]		; 06A28
	db	0x33, 0xDB		; 06A2B xor bx,bx
	mov	cx,[bp+0x10]		; 06A2D
	db	0x03, 0xC8		; 06A30 add cx,ax
	mov	dx,[bp+0x12]		; 06A32
	db	0x13, 0xD3		; 06A35 adc dx,bx
	mov	[di+0x2],cx		; 06A37
	db	0x8B, 0xC7		; 06A3A mov ax,di
	mov	si,[bp+0x8]		; 06A3C
	mov	[si],ax			; 06A3F
	db	0x33, 0xC0		; 06A41 xor ax,ax
	add	sp,0x14			; 06A43
	pop	bp			; 06A46
	ret				; 06A47
loc_06A48:
	mov	ax,[bp+0xc]		; 06A48
	cmp	ax,[bp+0x6]		; 06A4B
	jnc	short loc_06A66		; 06A4E jnc 0x6a66
	mov	ax,[0xe4bc]		; 06A50
	db	0x33, 0xDB		; 06A53 xor bx,bx
	sub	ax,[bp+0x10]		; 06A55
	sbb	bx,[bp+0x12]		; 06A58
	mov	[0xe4bc],ax		; 06A5B
	mov	ax,0xffff		; 06A5E
	add	sp,0x14			; 06A61
	pop	bp			; 06A64
	ret				; 06A65
loc_06A66:
	mov	ax,[bp+0xc]		; 06A66
	cmp	ax,[bp+0x6]		; 06A69
	jnz	short loc_06AC3		; 06A6C jnz 0x6ac3
	mov	si,[bp+0x4]		; 06A6E
	mov	ax,[si]			; 06A71
	test	ax,ax			; 06A73
	jz	short loc_06A94		; 06A75 jz 0x6a94
	mov	bx,[bp+0xe]		; 06A77
	db	0x3B, 0xD8		; 06A7A cmp bx,ax
	jna	short loc_06A94		; 06A7C jna 0x6a94
	mov	ax,[0xe4bc]		; 06A7E
	db	0x33, 0xDB		; 06A81 xor bx,bx
	sub	ax,[bp+0x10]		; 06A83
	sbb	bx,[bp+0x12]		; 06A86
	mov	[0xe4bc],ax		; 06A89
	mov	ax,0xffff		; 06A8C
	add	sp,0x14			; 06A8F
	pop	bp			; 06A92
	ret				; 06A93
loc_06A94:
	mov	si,[bp+0x4]		; 06A94
	mov	ax,[si+0x2]		; 06A97
	db	0x33, 0xDB		; 06A9A xor bx,bx
	add	ax,[bp+0x10]		; 06A9C
	adc	bx,[bp+0x12]		; 06A9F
	mov	[si+0x2],ax		; 06AA2
	mov	ax,[si]			; 06AA5
	test	ax,ax			; 06AA7
	jz	short loc_06ABC		; 06AA9 jz 0x6abc
	mov	bx,[bp+0xe]		; 06AAB
	db	0x3B, 0xD8		; 06AAE cmp bx,ax
	jnz	short loc_06ABC		; 06AB0 jnz 0x6abc
	mov	ax,[bx+0x2]		; 06AB2
	add	[si+0x2],ax		; 06AB5
	mov	ax,[bx]			; 06AB8
	mov	[si],ax			; 06ABA
loc_06ABC:
	db	0x33, 0xC0		; 06ABC xor ax,ax
	add	sp,0x14			; 06ABE
	pop	bp			; 06AC1
	ret				; 06AC2
loc_06AC3:
	mov	ax,[bp+0x4]		; 06AC3
	mov	bx,[bp+0x6]		; 06AC6
	db	0x8B, 0xF0		; 06AC9 mov si,ax
	mov	cx,[si]			; 06ACB
	mov	[bp+0x8],ax		; 06ACD
	mov	[bp+0x4],cx		; 06AD0
	mov	[bp+0xa],bx		; 06AD3
	jmp	0x6bdf			; 06AD6
	mov	ax,[bp+0xc]		; 06AD9
	mov	si,[bp+0x8]		; 06ADC
	mov	[si],ax			; 06ADF
	db	0x33, 0xDB		; 06AE1 xor bx,bx
	db	0x8B, 0xF0		; 06AE3 mov si,ax
	mov	[si],bx			; 06AE5
	mov	ax,[bp+0x10]		; 06AE7
	mov	[si+0x2],ax		; 06AEA
	db	0x8B, 0xC3		; 06AED mov ax,bx
	add	sp,0x14			; 06AEF
	pop	bp			; 06AF2
	ret				; 06AF3

; ---- function crt_strcmp ----
crt_strcmp:
	push	bp			; 06AF4
	sub	sp,0x4			; 06AF5
	db	0x8B, 0xEC		; 06AF8 mov bp,sp
loc_06AFA:
	mov	si,[bp+0xa]		; 06AFA
	mov	al,[si]			; 06AFD
	xor	ah,ah			; 06AFF
	mov	si,[bp+0x8]		; 06B01
	mov	bl,[si]			; 06B04
	xor	bh,bh			; 06B06
	db	0x3B, 0xD8		; 06B08 cmp bx,ax
	jnz	short loc_06B23		; 06B0A jnz 0x6b23
	mov	al,[si]			; 06B0C
	xor	ah,ah			; 06B0E
	test	ax,ax			; 06B10
	jnz	short loc_06B1B		; 06B12 jnz 0x6b1b
	db	0x33, 0xC0		; 06B14 xor ax,ax
	add	sp,0x4			; 06B16
	pop	bp			; 06B19
	ret				; 06B1A
loc_06B1B:
	inc	word [bp+0x8]		; 06B1B
	inc	word [bp+0xa]		; 06B1E
	jmp	short loc_06AFA		; 06B21 jmp 0x6afa
loc_06B23:
	mov	si,[bp+0xa]		; 06B23
	mov	al,[si]			; 06B26
	xor	ah,ah			; 06B28
	mov	si,[bp+0x8]		; 06B2A
	mov	bl,[si]			; 06B2D
	xor	bh,bh			; 06B2F
	db	0x2B, 0xD8		; 06B31 sub bx,ax
	db	0x8B, 0xC3		; 06B33 mov ax,bx
	add	sp,0x4			; 06B35
	pop	bp			; 06B38
	ret				; 06B39

; ---- function crt_cmp_long ----
crt_cmp_long:
	push	ax			; 06B3A
	db	0x33, 0xC1		; 06B3B xor ax,cx
	pop	ax			; 06B3D
	push	ax			; 06B3E
	js	short loc_06B50		; 06B3F js 0x6b50
	db	0x2B, 0xC1		; 06B41 sub ax,cx
	jnz	short loc_06B53		; 06B43 jnz 0x6b53
	db	0x33, 0xC0		; 06B45 xor ax,ax
	db	0x3B, 0xDA		; 06B47 cmp bx,dx
	jz	short loc_06B53		; 06B49 jz 0x6b53
	ja	short loc_06B50		; 06B4B ja 0x6b50
	dec	ax			; 06B4D
	jmp	short loc_06B53		; 06B4E jmp 0x6b53
loc_06B50:
	or	ax,0x7fff		; 06B50
loc_06B53:
	test	ax,ax			; 06B53
	pop	ax			; 06B55
	ret				; 06B56

; ---- function crt_mul_long ----
crt_mul_long:
	push	si			; 06B57
	push	di			; 06B58
	db	0x0B, 0xC0		; 06B59 or ax,ax
	jnz	short loc_06B61		; 06B5B jnz 0x6b61
	db	0x0B, 0xDB		; 06B5D or bx,bx
	jz	short loc_06B6D		; 06B5F jz 0x6b6d
loc_06B61:
	db	0x0B, 0xC9		; 06B61 or cx,cx
	jnz	short loc_06B70		; 06B63 jnz 0x6b70
	db	0x0B, 0xD2		; 06B65 or dx,dx
	jnz	short loc_06B70		; 06B67 jnz 0x6b70
	db	0x33, 0xC0		; 06B69 xor ax,ax
	db	0x33, 0xDB		; 06B6B xor bx,bx
loc_06B6D:
	pop	di			; 06B6D
	pop	si			; 06B6E
	ret				; 06B6F
loc_06B70:
	db	0x8B, 0xF3		; 06B70 mov si,bx
	db	0x8B, 0xFA		; 06B72 mov di,dx
	mul	di			; 06B74
	xchg	ax,bx			; 06B76
	mul	cx			; 06B77
	db	0x03, 0xD8		; 06B79 add bx,ax
	db	0x8B, 0xC6		; 06B7B mov ax,si
	mul	di			; 06B7D
	db	0x03, 0xDA		; 06B7F add bx,dx
	xchg	ax,bx			; 06B81
	jmp	short loc_06B6D		; 06B82 jmp 0x6b6d

; ---- function dos_int21 ----
dos_int21:
	push	bp			; 06B84
	db	0x8B, 0xEC		; 06B85 mov bp,sp
	mov	ah,[bp+0x4]		; 06B87
	mov	al,[bp+0x8]		; 06B8A
	mov	dx,[bp+0x6]		; 06B8D
	int	0x21			; 06B90
	mov	ah,0x0			; 06B92
	pop	bp			; 06B94
	ret				; 06B95

; ---- function crt_file_reset_buffer ----
crt_file_reset_buffer:
	push	bp			; 06B96
	sub	sp,0x2			; 06B97
	db	0x8B, 0xEC		; 06B9A mov bp,sp
	mov	si,[bp+0x6]		; 06B9C
	mov	al,[si+0x8]		; 06B9F
	xor	ah,ah			; 06BA2
	db	0x25, 0x04, 0x00	; 06BA4 and ax,0x4
	jz	short loc_06BB0		; 06BA7 jz 0x6bb0
	db	0x33, 0xC0		; 06BA9 xor ax,ax
	add	sp,0x2			; 06BAB
	pop	bp			; 06BAE
	ret				; 06BAF
loc_06BB0:
	mov	si,[bp+0x6]		; 06BB0
	cmp	word [si+0xa],0x0	; 06BB3
	jz	short loc_06BCE		; 06BB7 jz 0x6bce
	mov	al,[si+0x8]		; 06BB9
	xor	ah,ah			; 06BBC
	db	0x25, 0x08, 0x00	; 06BBE and ax,0x8
	jnz	short loc_06BCE		; 06BC1 jnz 0x6bce
	push	word [si+0xa]		; 06BC3
	push	word [si+0x6]		; 06BC6
	call	crt_free_small		; 06BC9
	db	0x8B, 0xE5		; 06BCC mov sp,bp
loc_06BCE:
	mov	ax,[bp+0x6]		; 06BCE
	db	0x05, 0x0C, 0x00	; 06BD1 add ax,0xc
	mov	si,[bp+0x6]		; 06BD4
	mov	[si+0x6],ax		; 06BD7
	mov	al,[si+0x8]		; 06BDA
	xor	ah,ah			; 06BDD
	db	0x0D, 0x04, 0x00	; 06BDF or ax,0x4
	mov	[si+0x8],al		; 06BE2
	db	0x33, 0xC0		; 06BE5 xor ax,ax
	mov	[si+0xa],ax		; 06BE7
	mov	[si+0x4],ax		; 06BEA
	mov	[si+0x2],ax		; 06BED
	add	sp,0x2			; 06BF0
	pop	bp			; 06BF3
	ret				; 06BF4

; ---- function crt_long_multiply ----
crt_long_multiply:
	push	bp			; 06BF5
	sub	sp,0x4			; 06BF6
	db	0x8B, 0xEC		; 06BF9 mov bp,sp
	mov	[bp+0x0],cx		; 06BFB
	db	0x0B, 0xCA		; 06BFE or cx,dx
	jnz	short loc_06C09		; 06C00 jnz 0x6c09
	db	0x33, 0xC0		; 06C02 xor ax,ax
	db	0x33, 0xDB		; 06C04 xor bx,bx
	jmp	0x6e98			; 06C06
loc_06C09:
	mov	[bp+0x2],ax		; 06C09
	db	0x0B, 0xC3		; 06C0C or ax,bx
	jnz	short loc_06C17		; 06C0E jnz 0x6c17
	db	0x33, 0xC9		; 06C10 xor cx,cx
	db	0x33, 0xD2		; 06C12 xor dx,dx
	jmp	0x6e98			; 06C14
loc_06C17:
	mov	cx,[bp+0x0]		; 06C17
	mov	ax,[bp+0x2]		; 06C1A
	db	0x8B, 0xF0		; 06C1D mov si,ax
	test	si,si			; 06C1F
	jns	short loc_06C2A		; 06C21 jns 0x6c2a
	not	ax			; 06C23
	neg	bx			; 06C25
	db	0x1D, 0xFF, 0xFF	; 06C27 sbb ax,0xffff
loc_06C2A:
	db	0x33, 0xF1		; 06C2A xor si,cx
	mov	[bp+0x0],si		; 06C2C
	db	0x33, 0xF6		; 06C2F xor si,si
	test	cx,cx			; 06C31
	jns	short loc_06C3C		; 06C33 jns 0x6c3c
	not	cx			; 06C35
	neg	dx			; 06C37
	sbb	cx,0xffffffffffffffff	; 06C39
loc_06C3C:
	jnz	short loc_06C5B		; 06C3C jnz 0x6c5b
	test	dx,dx			; 06C3E
	js	short loc_06C5B		; 06C40 js 0x6c5b
	mov	di,0x20			; 06C42
loc_06C45:
	shl	bx,1			; 06C45
	rcl	ax,1			; 06C47
	rcl	si,1			; 06C49
	db	0x3B, 0xF2		; 06C4B cmp si,dx
	jc	short loc_06C52		; 06C4D jc 0x6c52
	db	0x2B, 0xF2		; 06C4F sub si,dx
	inc	bx			; 06C51
loc_06C52:
	dec	di			; 06C52
	jnz	short loc_06C45		; 06C53 jnz 0x6c45
	db	0x33, 0xC9		; 06C55 xor cx,cx
	db	0x8B, 0xD6		; 06C57 mov dx,si
	jmp	short loc_06C7C		; 06C59 jmp 0x6c7c
loc_06C5B:
	mov	di,0x10			; 06C5B
loc_06C5E:
	shl	bx,1			; 06C5E
	rcl	ax,1			; 06C60
	rcl	si,1			; 06C62
	db	0x3B, 0xF1		; 06C64 cmp si,cx
	jc	short loc_06C73		; 06C66 jc 0x6c73
	jnz	short loc_06C6E		; 06C68 jnz 0x6c6e
	db	0x3B, 0xC2		; 06C6A cmp ax,dx
	jc	short loc_06C73		; 06C6C jc 0x6c73
loc_06C6E:
	db	0x2B, 0xC2		; 06C6E sub ax,dx
	db	0x1B, 0xF1		; 06C70 sbb si,cx
	inc	bx			; 06C72
loc_06C73:
	dec	di			; 06C73
	jnz	short loc_06C5E		; 06C74 jnz 0x6c5e
	db	0x8B, 0xCE		; 06C76 mov cx,si
	db	0x8B, 0xD0		; 06C78 mov dx,ax
	db	0x33, 0xC0		; 06C7A xor ax,ax
loc_06C7C:
	test	word [bp+0x0],0x8000	; 06C7C
	jz	short loc_06C8A		; 06C81 jz 0x6c8a
	not	ax			; 06C83
	neg	bx			; 06C85
	db	0x1D, 0xFF, 0xFF	; 06C87 sbb ax,0xffff
loc_06C8A:
	test	word [bp+0x2],0x8000	; 06C8A
	jz	short loc_06C98		; 06C8F jz 0x6c98
	not	cx			; 06C91
	neg	dx			; 06C93
	sbb	cx,0xffffffffffffffff	; 06C95
loc_06C98:
	add	sp,0x4			; 06C98
	pop	bp			; 06C9B
	ret				; 06C9C
