; Math helpers: multiply, divide, modulo


; ---- function math_multiply ----
math_multiply:
	push	bp			; 0205E
	sub	sp,0x4			; 0205F
	jc	short loc_0206A		; 02062 jc 0x206a
	cmp	sp,[0x17]		; 02064
	ja	short loc_0206D		; 02068 ja 0x206d
loc_0206A:
	jmp	0x420			; 0206A
loc_0206D:
	db	0x8B, 0xEC		; 0206D mov bp,sp
	cmp	word [0x130],0x2	; 0206F
	jnz	short loc_02083		; 02074 jnz 0x2083
	cmp	word [0xc3a6],0x3	; 02076
	jnz	short loc_02083		; 0207B jnz 0x2083
	mov	word [0x12a],0x1	; 0207D
loc_02083:
	cmp	word [0xf8],0x1		; 02083
	jnz	short loc_020A1		; 02088 jnz 0x20a1
	cmp	word [0x10c],0x1d	; 0208A
	jnz	short loc_02099		; 0208F jnz 0x2099
	mov	ax,0x1f			; 02091
	add	sp,0x4			; 02094
	pop	bp			; 02097
	ret				; 02098
loc_02099:
	mov	ax,0x1e			; 02099
	add	sp,0x4			; 0209C
	pop	bp			; 0209F
	ret				; 020A0
loc_020A1:
	cmp	word [0x10c],0x8	; 020A1
	jnz	short loc_020D0		; 020A6 jnz 0x20d0
	cmp	word [0x170],0x0	; 020A8
	jnz	short loc_020BA		; 020AD jnz 0x20ba
	mov	ax,0xb			; 020AF
	push	ax			; 020B2
	call	wait_vsync		; 020B3
	db	0x8B, 0xE5		; 020B6 mov sp,bp
	jmp	short loc_020C3		; 020B8 jmp 0x20c3
loc_020BA:
	mov	ax,0x14			; 020BA
	push	ax			; 020BD
	call	wait_vsync		; 020BE
	db	0x8B, 0xE5		; 020C1 mov sp,bp
loc_020C3:
	db	0x33, 0xC0		; 020C3 xor ax,ax
	mov	[0xdf43],al		; 020C5
	mov	[0x174],ax		; 020C8
	mov	[0x16e],ax		; 020CB
	jmp	short loc_020E4		; 020CE jmp 0x20e4
loc_020D0:
	cmp	word [0x10c],0x44	; 020D0
	jnz	short loc_020E4		; 020D5 jnz 0x20e4
	mov	word [0xf8],0x2		; 020D7
	db	0x33, 0xC0		; 020DD xor ax,ax
	add	sp,0x4			; 020DF
	pop	bp			; 020E2
	ret				; 020E3
loc_020E4:
	cmp	word [0xfc],0x1		; 020E4
	jnz	short loc_02112		; 020E9 jnz 0x2112
	mov	word [0xfc],0x0		; 020EB
	sub	word [0xbcd5],0x8	; 020F1
	mov	ax,[0x10c]		; 020F6
	db	0x3D, 0x04, 0x00	; 020F9 cmp ax,0x4
	jng	short loc_0210B		; 020FC jng 0x210b
	db	0x3D, 0x08, 0x00	; 020FE cmp ax,0x8
	jnl	short loc_0210B		; 02101 jnl 0x210b
	mov	ax,0x1b			; 02103
	add	sp,0x4			; 02106
	pop	bp			; 02109
	ret				; 0210A
loc_0210B:
	db	0x33, 0xC0		; 0210B xor ax,ax
	add	sp,0x4			; 0210D
	pop	bp			; 02110
	ret				; 02111
loc_02112:
	cmp	word [0x16c],0x1	; 02112
	jnz	short loc_02130		; 02117 jnz 0x2130
	mov	word [0x16c],0x0	; 02119
	mov	ax,0x1			; 0211F
	push	ax			; 02122
	call	rand_range		; 02123
	db	0x8B, 0xE5		; 02126 mov sp,bp
	db	0x05, 0x11, 0x00	; 02128 add ax,0x11
	add	sp,0x4			; 0212B
	pop	bp			; 0212E
	ret				; 0212F
loc_02130:
	cmp	word [0xfa],0x0		; 02130
	jng	short loc_02145		; 02135 jng 0x2145
	cmp	word [0x174],0x1	; 02137
	jnz	short loc_02145		; 0213C jnz 0x2145
	db	0x33, 0xC0		; 0213E xor ax,ax
	add	sp,0x4			; 02140
	pop	bp			; 02143
	ret				; 02144
loc_02145:
	mov	ax,[0x10c]		; 02145
	jmp	0x248b			; 02148
	call	combat_ai		; 0214B
	mov	[bp+0x2],ax		; 0214E
	inc	ax			; 02151
	jnz	short loc_02159		; 02152 jnz 0x2159
	mov	word [bp+0x2],0x0	; 02154
loc_02159:
	mov	ax,[bp+0x2]		; 02159
	add	sp,0x4			; 0215C
	pop	bp			; 0215F
	ret				; 02160
	call	combat_ai		; 02161
	mov	[bp+0x2],ax		; 02164
	inc	ax			; 02167
	jnz	short loc_02171		; 02168 jnz 0x2171
	mov	word [bp+0x2],0x29	; 0216A
	jmp	short loc_02175		; 0216F jmp 0x2175
loc_02171:
	add	word [bp+0x2],0x22	; 02171
loc_02175:
	mov	ax,[bp+0x2]		; 02175
	add	sp,0x4			; 02178
	pop	bp			; 0217B
	ret				; 0217C
	call	combat_ai		; 0217D
	mov	[bp+0x2],ax		; 02180
	inc	ax			; 02183
	jnz	short loc_0218D		; 02184 jnz 0x218d
	mov	word [bp+0x2],0x29	; 02186
	jmp	short loc_02191		; 0218B jmp 0x2191
loc_0218D:
	add	word [bp+0x2],0x25	; 0218D
loc_02191:
	mov	ax,[bp+0x2]		; 02191
	add	sp,0x4			; 02194
	pop	bp			; 02197
	ret				; 02198
	call	combat_ai		; 02199
	db	0x3D, 0x17, 0x00	; 0219C cmp ax,0x17
	mov	[bp+0x2],ax		; 0219F
	jng	short loc_021C2		; 021A2 jng 0x21c2
	db	0x3D, 0x1B, 0x00	; 021A4 cmp ax,0x1b
	jnl	short loc_021C2		; 021A7 jnl 0x21c2
	mov	ax,[0x15a]		; 021A9
	inc	ax			; 021AC
	db	0x3D, 0x03, 0x00	; 021AD cmp ax,0x3
	mov	[0x15a],ax		; 021B0
	jnz	short loc_021C8		; 021B3 jnz 0x21c8
	mov	word [0x15a],0x0	; 021B5
	mov	word [bp+0x2],0xffff	; 021BB
	jmp	short loc_021C8		; 021C0 jmp 0x21c8
loc_021C2:
	mov	word [0x15a],0x0	; 021C2
loc_021C8:
	cmp	word [bp+0x2],0xffffffffffffffff	; 021C8
	jnz	short loc_021D3		; 021CC jnz 0x21d3
	mov	word [bp+0x2],0x1b	; 021CE
loc_021D3:
	mov	ax,[bp+0x2]		; 021D3
	add	sp,0x4			; 021D6
	pop	bp			; 021D9
	ret				; 021DA
	call	combat_ai		; 021DB
	db	0x3D, 0x0C, 0x00	; 021DE cmp ax,0xc
	mov	[bp+0x2],ax		; 021E1
	jnz	short loc_021F5		; 021E4 jnz 0x21f5
	cmp	word [0x10c],0xa	; 021E6
	jnz	short loc_021F5		; 021EB jnz 0x21f5
	mov	ax,0xc			; 021ED
	add	sp,0x4			; 021F0
	pop	bp			; 021F3
	ret				; 021F4
loc_021F5:
	cmp	word [bp+0x2],0xd	; 021F5
	jnz	short loc_0220A		; 021F9 jnz 0x220a
	cmp	word [0x10c],0xb	; 021FB
	jnz	short loc_0220A		; 02200 jnz 0x220a
	mov	ax,0xd			; 02202
	add	sp,0x4			; 02205
	pop	bp			; 02208
	ret				; 02209
loc_0220A:
	db	0x33, 0xC0		; 0220A xor ax,ax
	add	sp,0x4			; 0220C
	pop	bp			; 0220F
	ret				; 02210
	db	0x33, 0xC0		; 02211 xor ax,ax
	add	sp,0x4			; 02213
	pop	bp			; 02216
	ret				; 02217
	call	combat_ai		; 02218
	mov	[bp+0x2],ax		; 0221B
	inc	ax			; 0221E
	jnz	short loc_02229		; 0221F jnz 0x2229
	mov	ax,0x13			; 02221
	add	sp,0x4			; 02224
	pop	bp			; 02227
	ret				; 02228
loc_02229:
	mov	ax,[bp+0x2]		; 02229
	add	sp,0x4			; 0222C
	pop	bp			; 0222F
	ret				; 02230
	call	combat_ai		; 02231
	mov	[bp+0x2],ax		; 02234
	inc	ax			; 02237
	jnz	short loc_0223F		; 02238 jnz 0x223f
	mov	word [bp+0x2],0xf	; 0223A
loc_0223F:
	mov	ax,[bp+0x2]		; 0223F
	add	sp,0x4			; 02242
	pop	bp			; 02245
	ret				; 02246
	inc	si			; 02247
	add	[bx+di],dh		; 02248
	db	0x22, 0x42, 0x00	; 0224A and al,[bp+si+0x0]
	sbb	[bp+si],ah		; 0224D
	inc	cx			; 0224F
	add	[bx+si],bl		; 02250
	and	cl,[bx]			; 02252
	add	[bx+di],dl		; 02254
	and	cl,[bp+di]		; 02256
	add	bl,bl			; 02258
	and	[bp+si],cx		; 0225A
	add	bl,bl			; 0225C
	and	[bx],ax			; 0225E
	add	[bx+di+0x621],bl	; 02260
	add	[bx+di+0x521],bl	; 02264
	add	[bx+di+0x2c21],bl	; 02268
	add	[di+0x21],bh		; 0226C
	sub	ax,[bx+si]		; 0226F
	db	0x7D, 0x21		; 02271 jnl 0x2294
	sub	al,[bx+si]		; 02273
	db	0x7D, 0x21		; 02275 jnl 0x2298
	add	al,0x0			; 02277
	popa				; 02279
	and	[bp+di],ax		; 0227A
	add	[bx+di+0x21],ah		; 0227C
	add	al,[bx+si]		; 0227F
	popa				; 02281
	and	[bx+si],cx		; 02282
	add	[bp+di+0x21],cl		; 02284
	add	[bx+si],ax		; 02287
	dec	bx			; 02289
	db	0x21, 0xBE, 0x40, 0x00	; 0228A and [bp+0x40],di
loc_0228E:
	cmp	ax,[cs:si+0x2247]	; 0228E
	jnz	short loc_0229A		; 02293 jnz 0x229a
	jmp	word near [cs:si+0x2249]	; 02295
loc_0229A:
	sub	si,0x4			; 0229A
	jns	short loc_0228E		; 0229D jns 0x228e
	add	sp,0x4			; 0229F
	pop	bp			; 022A2
	ret				; 022A3

; ---- function math_divide ----
math_divide:
	push	bp			; 022A4
	db	0x8B, 0xEC		; 022A5 mov bp,sp
	mov	di,[bp+0x4]		; 022A7
	mov	si,[bp+0x6]		; 022AA
	mov	ax,[bp+0x8]		; 022AD
	db	0x2B, 0xC6		; 022B0 sub ax,si
	db	0x8B, 0xC8		; 022B2 mov cx,ax
	push	es			; 022B4
	push	ds			; 022B5
	pop	es			; 022B6
	rep	movsb			; 022B7
	pop	es			; 022B9
	pop	bp			; 022BA
	ret				; 022BB

; ---- function math_modulo ----
math_modulo:
	push	bp			; 022BC
	db	0x8B, 0xEC		; 022BD mov bp,sp
	mov	di,[bp+0x4]		; 022BF
	mov	si,[bp+0x6]		; 022C2
	mov	bx,0x3			; 022C5
loc_022C8:
	mov	al,[bx+si+0x1]		; 022C8
	mov	[bx+di],al		; 022CB
	mov	al,[bx+si+0x6]		; 022CD
	mov	[bx+di+0x4],al		; 022D0
	dec	bx			; 022D3
	jnl	short loc_022C8		; 022D4 jnl 0x22c8
	mov	ax,[bp+0x8]		; 022D6
	add	[di+0x1],ax		; 022D9
	add	[di+0x5],ax		; 022DC
	pop	bp			; 022DF
	ret				; 022E0
