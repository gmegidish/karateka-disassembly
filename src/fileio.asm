; File loading, resource management, parsing


; ---- function load_file ----
load_file:
	push	bp			; 04FDD
	sub	sp,0x16			; 04FDE
	db	0x8B, 0xEC		; 04FE1 mov bp,sp
	mov	ax,[bp+0x1e]		; 04FE3
	test	ax,ax			; 04FE6
	js	short loc_04FF9		; 04FE8 js 0x4ff9
	push	word [bp+0x1a]		; 04FEA
	call	get_file_slot		; 04FED
	db	0x8B, 0xE5		; 04FF0 mov sp,bp
	test	ax,ax			; 04FF2
	mov	[bp+0x12],ax		; 04FF4
	jnz	short loc_05007		; 04FF7 jnz 0x5007
loc_04FF9:
	mov	word [0xe4be],0x16	; 04FF9
	mov	ax,0xffff		; 04FFF
	add	sp,0x16			; 05002
	pop	bp			; 05005
	ret				; 05006
loc_05007:
	mov	si,[bp+0x12]		; 05007
	mov	al,[si+0x1]		; 0500A
	xor	ah,ah			; 0500D
	jmp	0x54c8			; 0500F
	mov	ax,[bp+0x1e]		; 05012
	db	0x3D, 0x01, 0x00	; 05015 cmp ax,0x1
	jg	short loc_0501D		; 05018 jg 0x501d
	jmp	0x52a3			; 0501A
loc_0501D:
	cmp	ax,0x80			; 0501D
	jng	short loc_05027		; 05020 jng 0x5027
	mov	ax,0x80			; 05022
	jmp	short loc_0502A		; 05025 jmp 0x502a
loc_05027:
	mov	ax,[bp+0x1e]		; 05027
loc_0502A:
	mov	bx,0xe3b8		; 0502A
	push	bx			; 0502D
	mov	[0xe3b8],al		; 0502E
	call	dos_read_line		; 05031
	db	0x8B, 0xE5		; 05034 mov sp,bp
	mov	word [bp+0x6],0x0	; 05036
	mov	word [bp+0x8],0x2	; 0503B
loc_05040:
	mov	al,[0xe3b8]		; 05040
	xor	ah,ah			; 05043
	mov	bx,[bp+0x6]		; 05045
	db	0x3B, 0xC3		; 05048 cmp ax,bx
	jng	short loc_05092		; 0504A jng 0x5092
	mov	ax,[bp+0x8]		; 0504C
	inc	word [bp+0x8]		; 0504F
	db	0x8B, 0xF0		; 05052 mov si,ax
	mov	al,[si-0x1c48]		; 05054
	mov	[bp+0x4],al		; 05058
	xor	ah,ah			; 0505B
	db	0x3D, 0x0D, 0x00	; 0505D cmp ax,0xd
	jnz	short loc_0506F		; 05060 jnz 0x506f
	inc	word [bp+0x6]		; 05062
	mov	si,[bp+0x1c]		; 05065
	db	0x03, 0xF3		; 05068 add si,bx
	mov	byte [si],0xa		; 0506A
	jmp	short loc_05092		; 0506D jmp 0x5092
loc_0506F:
	mov	al,[bp+0x4]		; 0506F
	xor	ah,ah			; 05072
	db	0x3D, 0x1A, 0x00	; 05074 cmp ax,0x1a
	jnz	short loc_05080		; 05077 jnz 0x5080
	mov	word [bp+0x6],0x0	; 05079
	jmp	short loc_05092		; 0507E jmp 0x5092
loc_05080:
	mov	ax,[bp+0x6]		; 05080
	inc	word [bp+0x6]		; 05083
	mov	si,[bp+0x1c]		; 05086
	db	0x03, 0xF0		; 05089 add si,ax
	mov	al,[bp+0x4]		; 0508B
	mov	[si],al			; 0508E
	jmp	short loc_05040		; 05090 jmp 0x5040
loc_05092:
	mov	ax,0xa			; 05092
	push	ax			; 05095
	call	dos_putchar		; 05096
	db	0x8B, 0xE5		; 05099 mov sp,bp
	mov	ax,[bp+0x6]		; 0509B
	add	sp,0x16			; 0509E
	pop	bp			; 050A1
	ret				; 050A2
	mov	ax,0x5dbb		; 050A3
	mov	bx,0x5de3		; 050A6
	mov	[bp+0xe],ax		; 050A9
	mov	[bp+0x10],bx		; 050AC
	jmp	short loc_050BD		; 050AF jmp 0x50bd
	mov	ax,0x5df7		; 050B1
	mov	bx,0x5e0b		; 050B4
	mov	[bp+0xe],ax		; 050B7
	mov	[bp+0x10],bx		; 050BA
loc_050BD:
	mov	si,[bp+0x12]		; 050BD
	mov	al,[si]			; 050C0
	xor	ah,ah			; 050C2
	db	0x25, 0x10, 0x00	; 050C4 and ax,0x10
	jz	short loc_050F6		; 050C7 jz 0x50f6
	mov	word [bp+0x6],0x0	; 050C9
loc_050CE:
	mov	ax,[bp+0x6]		; 050CE
	cmp	ax,[bp+0x1e]		; 050D1
	jnl	short loc_050EE		; 050D4 jnl 0x50ee
	mov	ax,[bp+0x6]		; 050D6
	inc	word [bp+0x6]		; 050D9
	mov	bx,[bp+0x1c]		; 050DC
	db	0x03, 0xD8		; 050DF add bx,ax
	mov	[bp+0x0],bx		; 050E1
	call	word near [bp+0xe]	; 050E4
	mov	si,[bp+0x0]		; 050E7
	mov	[si],al			; 050EA
	jmp	short loc_050CE		; 050EC jmp 0x50ce
loc_050EE:
	mov	ax,[bp+0x6]		; 050EE
	add	sp,0x16			; 050F1
	pop	bp			; 050F4
	ret				; 050F5
loc_050F6:
	mov	word [bp+0x6],0x0	; 050F6
loc_050FB:
	mov	ax,[bp+0x6]		; 050FB
	cmp	ax,[bp+0x1e]		; 050FE
	jl	short loc_05106		; 05101 jl 0x5106
	jmp	0x53dc			; 05103
loc_05106:
	call	word near [bp+0xe]	; 05106
	mov	[bp+0x4],al		; 05109
	xor	ah,ah			; 0510C
	jmp	0x53c6			; 0510E
	mov	ax,0xd			; 05111
	push	ax			; 05114
	call	word near [bp+0x10]	; 05115
	db	0x8B, 0xE5		; 05118 mov sp,bp
	mov	ax,0xa			; 0511A
	push	ax			; 0511D
	call	word near [bp+0x10]	; 0511E
	db	0x8B, 0xE5		; 05121 mov sp,bp
	mov	ax,[bp+0x6]		; 05123
	mov	[bp+0x0],ax		; 05126
	inc	ax			; 05129
	mov	si,[bp+0x1c]		; 0512A
	add	si,[bp+0x0]		; 0512D
	mov	byte [si],0xa		; 05130
	mov	[bp+0x6],ax		; 05133
	add	sp,0x16			; 05136
	pop	bp			; 05139
	ret				; 0513A
	cmp	word [bp+0x6],0x0	; 0513B
	jz	short loc_050FB		; 0513F jz 0x50fb
	mov	ax,0x8			; 05141
	push	ax			; 05144
	call	word near [bp+0x10]	; 05145
	db	0x8B, 0xE5		; 05148 mov sp,bp
	mov	ax,0x20			; 0514A
	push	ax			; 0514D
	call	word near [bp+0x10]	; 0514E
	db	0x8B, 0xE5		; 05151 mov sp,bp
	mov	ax,0x8			; 05153
	push	ax			; 05156
	call	word near [bp+0x10]	; 05157
	db	0x8B, 0xE5		; 0515A mov sp,bp
	jmp	short loc_050FB		; 0515C jmp 0x50fb
	mov	ax,0xd			; 0515E
	push	ax			; 05161
	call	word near [bp+0x10]	; 05162
	db	0x8B, 0xE5		; 05165 mov sp,bp
	mov	ax,0xa			; 05167
	push	ax			; 0516A
	call	word near [bp+0x10]	; 0516B
	db	0x8B, 0xE5		; 0516E mov sp,bp
	db	0x33, 0xC0		; 05170 xor ax,ax
	add	sp,0x16			; 05172
	pop	bp			; 05175
	ret				; 05176
loc_05177:
	mov	ax,[bp+0x6]		; 05177
	inc	word [bp+0x6]		; 0517A
	mov	si,[bp+0x1c]		; 0517D
	db	0x03, 0xF0		; 05180 add si,ax
	mov	al,[bp+0x4]		; 05182
	mov	[si],al			; 05185
	xor	ah,ah			; 05187
	db	0x3D, 0x20, 0x00	; 05189 cmp ax,0x20
	jnl	short loc_051A8		; 0518C jnl 0x51a8
	mov	ax,0x5e			; 0518E
	push	ax			; 05191
	call	word near [bp+0x10]	; 05192
	db	0x8B, 0xE5		; 05195 mov sp,bp
	mov	al,[bp+0x4]		; 05197
	xor	ah,ah			; 0519A
	db	0x05, 0x40, 0x00	; 0519C add ax,0x40
	push	ax			; 0519F
	call	word near [bp+0x10]	; 051A0
	db	0x8B, 0xE5		; 051A3 mov sp,bp
	jmp	0x52fb			; 051A5
loc_051A8:
	mov	al,[bp+0x4]		; 051A8
	xor	ah,ah			; 051AB
	push	ax			; 051AD
	call	word near [bp+0x10]	; 051AE
	db	0x8B, 0xE5		; 051B1 mov sp,bp
	jmp	0x52fb			; 051B3
	sbb	al,[bx+si]		; 051B6
	pop	si			; 051B8
	push	cx			; 051B9
	or	[bx+si],al		; 051BA
	cmp	dx,[bx+di+0xd]		; 051BC
	add	[bx+di],dl		; 051BF
	push	cx			; 051C1
	or	al,[bx+si]		; 051C2
	adc	[bx+di-0x42],dx		; 051C4
	or	al,0x0			; 051C7
loc_051C9:
	cmp	ax,[cs:si+0x51b6]	; 051C9
	jnz	short loc_051D5		; 051CE jnz 0x51d5
	jmp	word near [cs:si+0x51b8]	; 051D0
loc_051D5:
	sub	si,0x4			; 051D5
	jns	short loc_051C9		; 051D8 jns 0x51c9
	jmp	short loc_05177		; 051DA jmp 0x5177
	mov	ax,[bp+0x6]		; 051DC
	add	sp,0x16			; 051DF
	pop	bp			; 051E2
	ret				; 051E3
	db	0x33, 0xC0		; 051E4 xor ax,ax
	add	sp,0x16			; 051E6
	pop	bp			; 051E9
	ret				; 051EA
	mov	al,[0xf]		; 051EB
	xor	ah,ah			; 051EE
	db	0x3D, 0x01, 0x00	; 051F0 cmp ax,0x1
	jng	short loc_0521E		; 051F3 jng 0x521e
	push	word [bp+0x1e]		; 051F5
	push	word [bp+0x1c]		; 051F8
	mov	si,[bp+0x12]		; 051FB
	push	word [si+0x2]		; 051FE
	call	dos_read_file		; 05201
	db	0x8B, 0xE5		; 05204 mov sp,bp
	mov	[bp+0x6],ax		; 05206
	cmp	word [0x80],0x0		; 05209
	jz	short loc_0521E		; 0520E jz 0x521e
	mov	word [0xe4be],0x5	; 05210
	mov	ax,0xffff		; 05216
	add	sp,0x16			; 05219
	pop	bp			; 0521C
	ret				; 0521D
loc_0521E:
	mov	si,[bp+0x12]		; 0521E
	mov	al,[si]			; 05221
	xor	ah,ah			; 05223
	db	0x25, 0x10, 0x00	; 05225 and ax,0x10
	jz	short loc_05232		; 05228 jz 0x5232
	mov	ax,[bp+0x6]		; 0522A
	add	sp,0x16			; 0522D
	pop	bp			; 05230
	ret				; 05231
loc_05232:
	db	0x33, 0xC0		; 05232 xor ax,ax
	mov	[bp+0x8],ax		; 05234
	mov	[bp+0xa],ax		; 05237
loc_0523A:
	mov	ax,[bp+0x8]		; 0523A
	mov	bx,[bp+0x6]		; 0523D
	db	0x3B, 0xD8		; 05240 cmp bx,ax
	jng	short loc_05299		; 05242 jng 0x5299
	inc	word [bp+0x8]		; 05244
	mov	si,[bp+0x1c]		; 05247
	db	0x03, 0xF0		; 0524A add si,ax
	mov	al,[si]			; 0524C
	mov	[bp+0x4],al		; 0524E
	xor	ah,ah			; 05251
	jmp	short loc_0528D		; 05253 jmp 0x528d
loc_05255:
	mov	ax,[bp+0x8]		; 05255
	sub	ax,[bp+0x6]		; 05258
	dec	ax			; 0525B
	db	0x33, 0xDB		; 0525C xor bx,bx
	test	ax,ax			; 0525E
	jns	short loc_05263		; 05260 jns 0x5263
	dec	bx			; 05262
loc_05263:
	mov	cx,0x1			; 05263
	push	cx			; 05266
	push	bx			; 05267
	push	ax			; 05268
	push	word [bp+0x1a]		; 05269
	call	seek_and_read		; 0526C
	db	0x8B, 0xE5		; 0526F mov sp,bp
	mov	ax,[bp+0xa]		; 05271
	add	sp,0x16			; 05274
	pop	bp			; 05277
	ret				; 05278
	jmp	short loc_0523A		; 05279 jmp 0x523a
loc_0527B:
	mov	ax,[bp+0xa]		; 0527B
	inc	word [bp+0xa]		; 0527E
	mov	si,[bp+0x1c]		; 05281
	db	0x03, 0xF0		; 05284 add si,ax
	mov	al,[bp+0x4]		; 05286
	mov	[si],al			; 05289
	jmp	short loc_0523A		; 0528B jmp 0x523a
loc_0528D:
	db	0x3D, 0x0D, 0x00	; 0528D cmp ax,0xd
	jz	short loc_0523A		; 05290 jz 0x523a
	db	0x3D, 0x1A, 0x00	; 05292 cmp ax,0x1a
	jz	short loc_05255		; 05295 jz 0x5255
	jmp	short loc_0527B		; 05297 jmp 0x527b
loc_05299:
	cmp	word [bp+0xa],0x0	; 05299
	jnz	short loc_052A8		; 0529D jnz 0x52a8
	cmp	word [bp+0x6],0x0	; 0529F
	jz	short loc_052A8		; 052A3 jz 0x52a8
	jmp	0x53eb			; 052A5
loc_052A8:
	mov	ax,[bp+0xa]		; 052A8
	add	sp,0x16			; 052AB
	pop	bp			; 052AE
	ret				; 052AF
loc_052B0:
	mov	word [0xe4be],0x13	; 052B0
	mov	ax,0xffff		; 052B6
	add	sp,0x16			; 052B9
	pop	bp			; 052BC
	ret				; 052BD
	db	0xEB, 0x51		; 052BE jmp 0x5311
	adc	dl,[bx+si-0x1c]		; 052C0
	push	cx			; 052C3
	mov	cl,0x50			; 052C4
	in	al,byte 0x51		; 052C6
	db	0x8B, 0xF0		; 052C8 mov si,ax
	cmp	si,0x5			; 052CA
	jnc	short loc_052D6		; 052CD jnc 0x52d6
	shl	si,1			; 052CF
	jmp	word near [cs:si+0x52be]	; 052D1
loc_052D6:
	jmp	short loc_052B0		; 052D6 jmp 0x52b0

; ---- function write_file_data ----
write_file_data:
	push	bp			; 052D8
	sub	sp,0x14			; 052D9
	db	0x8B, 0xEC		; 052DC mov bp,sp
	mov	ax,[bp+0x1c]		; 052DE
	test	ax,ax			; 052E1
	js	short loc_052F4		; 052E3 js 0x52f4
	push	word [bp+0x18]		; 052E5
	call	get_file_slot		; 052E8
	db	0x8B, 0xE5		; 052EB mov sp,bp
	test	ax,ax			; 052ED
	mov	[bp+0x10],ax		; 052EF
	jnz	short loc_05302		; 052F2 jnz 0x5302
loc_052F4:
	mov	word [0xe4be],0x16	; 052F4
	mov	ax,0xffff		; 052FA
	add	sp,0x14			; 052FD
	pop	bp			; 05300
	ret				; 05301
loc_05302:
	mov	si,[bp+0x10]		; 05302
	mov	al,[si+0x1]		; 05305
	xor	ah,ah			; 05308
	jmp	0x56f1			; 0530A
	mov	ax,0x5de3		; 0530D
	mov	[bp+0x6],ax		; 05310
	jmp	short loc_05323		; 05313 jmp 0x5323
	mov	ax,0x5e1f		; 05315
	mov	[bp+0x6],ax		; 05318
	jmp	short loc_05323		; 0531B jmp 0x5323
	mov	ax,0x5e0b		; 0531D
	mov	[bp+0x6],ax		; 05320
loc_05323:
	mov	word [bp+0x8],0x0	; 05323
loc_05328:
	mov	ax,[bp+0x8]		; 05328
	mov	bx,[bp+0x1c]		; 0532B
	db	0x3B, 0xD8		; 0532E cmp bx,ax
	jng	short loc_05368		; 05330 jng 0x5368
	inc	word [bp+0x8]		; 05332
	mov	si,[bp+0x1a]		; 05335
	db	0x03, 0xF0		; 05338 add si,ax
	mov	al,[si]			; 0533A
	mov	[bp+0x4],al		; 0533C
	xor	ah,ah			; 0533F
	db	0x3D, 0x0A, 0x00	; 05341 cmp ax,0xa
	jnz	short loc_0535B		; 05344 jnz 0x535b
	mov	si,[bp+0x10]		; 05346
	mov	al,[si]			; 05349
	xor	ah,ah			; 0534B
	db	0x25, 0x10, 0x00	; 0534D and ax,0x10
	jnz	short loc_0535B		; 05350 jnz 0x535b
	mov	ax,0xd			; 05352
	push	ax			; 05355
	call	word near [bp+0x6]	; 05356
	db	0x8B, 0xE5		; 05359 mov sp,bp
loc_0535B:
	mov	al,[bp+0x4]		; 0535B
	xor	ah,ah			; 0535E
	push	ax			; 05360
	call	word near [bp+0x6]	; 05361
	db	0x8B, 0xE5		; 05364 mov sp,bp
	jmp	short loc_05328		; 05366 jmp 0x5328
loc_05368:
	mov	ax,[bp+0x8]		; 05368
	add	sp,0x14			; 0536B
	pop	bp			; 0536E
	ret				; 0536F
	mov	si,[bp+0x10]		; 05370
	mov	al,[si]			; 05373
	xor	ah,ah			; 05375
	db	0x25, 0x08, 0x00	; 05377 and ax,0x8
	jz	short loc_0538E		; 0537A jz 0x538e
	mov	ax,0x2			; 0537C
	push	ax			; 0537F
	db	0x33, 0xC0		; 05380 xor ax,ax
	push	ax			; 05382
	db	0x33, 0xDB		; 05383 xor bx,bx
	push	bx			; 05385
	push	word [bp+0x18]		; 05386
	call	seek_and_read		; 05389
	db	0x8B, 0xE5		; 0538C mov sp,bp
loc_0538E:
	mov	al,[0xf]		; 0538E
	xor	ah,ah			; 05391
	db	0x3D, 0x01, 0x00	; 05393 cmp ax,0x1
	jng	short loc_053D2		; 05396 jng 0x53d2
	mov	si,[bp+0x10]		; 05398
	mov	al,[si]			; 0539B
	xor	ah,ah			; 0539D
	db	0x25, 0x10, 0x00	; 0539F and ax,0x10
	jz	short loc_053D2		; 053A2 jz 0x53d2
	push	word [bp+0x1c]		; 053A4
	push	word [bp+0x1a]		; 053A7
	push	word [si+0x2]		; 053AA
	call	dos_write_file		; 053AD
	db	0x8B, 0xE5		; 053B0 mov sp,bp
	mov	[bp+0x8],ax		; 053B2
	cmp	word [0x80],0x0		; 053B5
	jz	short loc_053CA		; 053BA jz 0x53ca
	mov	word [0xe4be],0x5	; 053BC
	mov	ax,0xffff		; 053C2
	add	sp,0x14			; 053C5
	pop	bp			; 053C8
	ret				; 053C9
loc_053CA:
	mov	ax,[bp+0x8]		; 053CA
	add	sp,0x14			; 053CD
	pop	bp			; 053D0
	ret				; 053D1
loc_053D2:
	mov	byte [bp+0x5],0x0	; 053D2
	db	0x33, 0xC0		; 053D6 xor ax,ax
	mov	[bp+0x8],ax		; 053D8
	mov	[bp+0xa],ax		; 053DB
	mov	[bp+0xc],ax		; 053DE
loc_053E1:
	mov	ax,[bp+0x8]		; 053E1
	mov	bx,[bp+0x1c]		; 053E4
	db	0x3B, 0xD8		; 053E7 cmp bx,ax
	jg	short loc_053EE		; 053E9 jg 0x53ee
	jmp	0x567d			; 053EB
loc_053EE:
	inc	word [bp+0x8]		; 053EE
	mov	si,[bp+0x1a]		; 053F1
	db	0x03, 0xF0		; 053F4 add si,ax
	mov	al,[si]			; 053F6
	mov	[bp+0x4],al		; 053F8
	xor	ah,ah			; 053FB
	db	0x3D, 0x0A, 0x00	; 053FD cmp ax,0xa
	jnz	short loc_05413		; 05400 jnz 0x5413
	mov	al,[bp+0x5]		; 05402
	xor	ah,ah			; 05405
	db	0x3D, 0x0D, 0x00	; 05407 cmp ax,0xd
	jz	short loc_05413		; 0540A jz 0x5413
	mov	byte [bp+0x4],0xd	; 0540C
	dec	word [bp+0x8]		; 05410
loc_05413:
	mov	ax,[bp+0xa]		; 05413
	mov	[bp+0x0],ax		; 05416
	inc	ax			; 05419
	mov	si,[bp+0x0]		; 0541A
	mov	bl,[bp+0x4]		; 0541D
	mov	[si-0x1c48],bl		; 05420
	cmp	ax,0x80			; 05424
	mov	[bp+0xa],ax		; 05427
	mov	[bp+0x5],bl		; 0542A
	jl	short loc_053E1		; 0542D jl 0x53e1
	mov	al,[0xf]		; 0542F
	xor	ah,ah			; 05432
	db	0x3D, 0x01, 0x00	; 05434 cmp ax,0x1
	jng	short loc_05475		; 05437 jng 0x5475
	push	word [bp+0xa]		; 05439
	mov	ax,0xe3b8		; 0543C
	push	ax			; 0543F
	mov	si,[bp+0x10]		; 05440
	push	word [si+0x2]		; 05443
	call	dos_write_file		; 05446
	db	0x8B, 0xE5		; 05449 mov sp,bp
	cmp	ax,[bp+0xa]		; 0544B
	mov	[bp+0xe],ax		; 0544E
	jz	short loc_05460		; 05451 jz 0x5460
	mov	word [0xe4be],0x1c	; 05453
	db	0x33, 0xC0		; 05459 xor ax,ax
	add	sp,0x14			; 0545B
	pop	bp			; 0545E
	ret				; 0545F
loc_05460:
	cmp	word [0x80],0x0		; 05460
	jz	short loc_05475		; 05465 jz 0x5475
	mov	word [0xe4be],0x5	; 05467
	mov	ax,0xffff		; 0546D
	add	sp,0x14			; 05470
	pop	bp			; 05473
	ret				; 05474
loc_05475:
	mov	word [bp+0xa],0x0	; 05475
	jmp	0x55e1			; 0547A
	cmp	word [bp+0xa],0x0	; 0547D
	jz	short loc_054C9		; 05481 jz 0x54c9
	mov	al,[0xf]		; 05483
	xor	ah,ah			; 05486
	db	0x3D, 0x01, 0x00	; 05488 cmp ax,0x1
	jng	short loc_054C9		; 0548B jng 0x54c9
	push	word [bp+0xa]		; 0548D
	mov	ax,0xe3b8		; 05490
	push	ax			; 05493
	mov	si,[bp+0x10]		; 05494
	push	word [si+0x2]		; 05497
	call	dos_write_file		; 0549A
	db	0x8B, 0xE5		; 0549D mov sp,bp
	cmp	ax,[bp+0xa]		; 0549F
	mov	[bp+0xe],ax		; 054A2
	jz	short loc_054B4		; 054A5 jz 0x54b4
	mov	word [0xe4be],0x1c	; 054A7
	db	0x33, 0xC0		; 054AD xor ax,ax
	add	sp,0x14			; 054AF
	pop	bp			; 054B2
	ret				; 054B3
loc_054B4:
	cmp	word [0x80],0x0		; 054B4
	jz	short loc_054C9		; 054B9 jz 0x54c9
	mov	word [0xe4be],0x5	; 054BB
	mov	ax,0xffff		; 054C1
	add	sp,0x14			; 054C4
	pop	bp			; 054C7
	ret				; 054C8
loc_054C9:
	mov	ax,[bp+0x8]		; 054C9
	add	sp,0x14			; 054CC
	pop	bp			; 054CF
	ret				; 054D0
	mov	ax,[bp+0x1c]		; 054D1
	add	sp,0x14			; 054D4
	pop	bp			; 054D7
	ret				; 054D8
loc_054D9:
	mov	word [0xe4be],0x13	; 054D9
	mov	ax,0xffff		; 054DF
	add	sp,0x14			; 054E2
	pop	bp			; 054E5
	ret				; 054E6
	jo	short loc_0553C		; 054E7 jo 0x553c
	or	ax,0x1553		; 054E9
	push	bx			; 054EC
	sbb	ax,0xd153		; 054ED
	push	sp			; 054F0
	db	0x8B, 0xF0		; 054F1 mov si,ax
	cmp	si,0x5			; 054F3
	jnc	short loc_054FF		; 054F6 jnc 0x54ff
	shl	si,1			; 054F8
	jmp	word near [cs:si+0x54e7]	; 054FA
loc_054FF:
	jmp	short loc_054D9		; 054FF jmp 0x54d9

; ---- function seek_and_read ----
seek_and_read:
	push	bp			; 05501
	sub	sp,0x12			; 05502
	db	0x8B, 0xEC		; 05505 mov bp,sp
	push	word [bp+0x16]		; 05507
	call	get_file_slot		; 0550A
	db	0x8B, 0xE5		; 0550D mov sp,bp
	test	ax,ax			; 0550F
	mov	[bp+0xe],ax		; 05511
	jnz	short loc_05527		; 05514 jnz 0x5527
	mov	word [0xe4be],0x16	; 05516
	mov	ax,0xffff		; 0551C
	mov	bx,0xffff		; 0551F
	add	sp,0x12			; 05522
	pop	bp			; 05525
	ret				; 05526
loc_05527:
	mov	si,[bp+0xe]		; 05527
	mov	al,[si+0x1]		; 0552A
	xor	ah,ah			; 0552D
	test	ax,ax			; 0552F
	jz	short loc_0553C		; 05531 jz 0x553c
	db	0x33, 0xC0		; 05533 xor ax,ax
	db	0x33, 0xDB		; 05535 xor bx,bx
	add	sp,0x12			; 05537
	pop	bp			; 0553A
	ret				; 0553B
loc_0553C:
	mov	al,[0xf]		; 0553C
	xor	ah,ah			; 0553F
	db	0x3D, 0x01, 0x00	; 05541 cmp ax,0x1
	jng	short loc_05578		; 05544 jng 0x5578
	push	word [bp+0x1c]		; 05546
	push	word [bp+0x1a]		; 05549
	push	word [bp+0x18]		; 0554C
	mov	si,[bp+0xe]		; 0554F
	push	word [si+0x2]		; 05552
	call	dos_seek_file		; 05555
	db	0x8B, 0xE5		; 05558 mov sp,bp
	mov	[bp+0x7],ax		; 0555A
	mov	[bp+0x5],bx		; 0555D
	cmp	word [0x80],0x0		; 05560
	jz	short loc_05578		; 05565 jz 0x5578
	mov	word [0xe4be],0x16	; 05567
	mov	ax,0xffff		; 0556D
	mov	bx,0xffff		; 05570
	add	sp,0x12			; 05573
	pop	bp			; 05576
	ret				; 05577
loc_05578:
	cmp	word [bp+0x1c],0x2	; 05578
	jnz	short loc_055EE		; 0557C jnz 0x55ee
	mov	ax,[bp+0x7]		; 0557E
	or	ax,[bp+0x5]		; 05581
	jz	short loc_055EE		; 05584 jz 0x55ee
	mov	si,[bp+0xe]		; 05586
	mov	al,[si]			; 05589
	xor	ah,ah			; 0558B
	db	0x25, 0x10, 0x00	; 0558D and ax,0x10
	jnz	short loc_055EE		; 05590 jnz 0x55ee
	mov	ax,[bp+0x5]		; 05592
	db	0x2D, 0x01, 0x00	; 05595 sub ax,0x1
	mov	bx,[bp+0x7]		; 05598
	sbb	bx,0x0			; 0559B
	mov	[bp+0x9],ax		; 0559E
	mov	[bp+0xb],bx		; 055A1
loc_055A4:
	mov	ax,[bp+0xb]		; 055A4
	test	ax,ax			; 055A7
	js	short loc_055DC		; 055A9 js 0x55dc
	db	0x33, 0xDB		; 055AB xor bx,bx
	push	bx			; 055AD
	push	ax			; 055AE
	push	word [bp+0x9]		; 055AF
	push	word [bp+0x16]		; 055B2
	call	seek_and_read		; 055B5
	db	0x8B, 0xE5		; 055B8 mov sp,bp
	db	0x0B, 0xC3		; 055BA or ax,bx
	jz	short loc_055DC		; 055BC jz 0x55dc
	mov	ax,0x1			; 055BE
	push	ax			; 055C1
	lea	ax,[bp+0x4]		; 055C2
	push	ax			; 055C5
	push	word [bp+0x16]		; 055C6
	call	load_file		; 055C9
	db	0x8B, 0xE5		; 055CC mov sp,bp
	test	ax,ax			; 055CE
	jnz	short loc_055DC		; 055D0 jnz 0x55dc
	sub	word [bp+0x9],0x1	; 055D2
	sbb	word [bp+0xb],0x0	; 055D6
	jmp	short loc_055A4		; 055DA jmp 0x55a4
loc_055DC:
	mov	ax,[bp+0x9]		; 055DC
	db	0x05, 0x01, 0x00	; 055DF add ax,0x1
	mov	bx,[bp+0xb]		; 055E2
	adc	bx,0x0			; 055E5
	xchg	ax,bx			; 055E8
	add	sp,0x12			; 055E9
	pop	bp			; 055EC
	ret				; 055ED
loc_055EE:
	mov	ax,[bp+0x7]		; 055EE
	mov	bx,[bp+0x5]		; 055F1
	add	sp,0x12			; 055F4
	pop	bp			; 055F7
	ret				; 055F8

; ---- function close_file_slot ----
close_file_slot:
	push	bp			; 055F9
	sub	sp,0x8			; 055FA
	db	0x8B, 0xEC		; 055FD mov bp,sp
	push	word [bp+0xc]		; 055FF
	call	get_file_slot		; 05602
	db	0x8B, 0xE5		; 05605 mov sp,bp
	test	ax,ax			; 05607
	mov	[bp+0x4],ax		; 05609
	jnz	short loc_05616		; 0560C jnz 0x5616
	mov	ax,0xffff		; 0560E
	add	sp,0x8			; 05611
	pop	bp			; 05614
	ret				; 05615
loc_05616:
	db	0x33, 0xC0		; 05616 xor ax,ax
	mov	si,[bp+0x4]		; 05618
	mov	bl,[si+0x1]		; 0561B
	xor	bh,bh			; 0561E
	test	bx,bx			; 05620
	mov	[bp+0x2],ax		; 05622
	jnz	short loc_0564B		; 05625 jnz 0x564b
	mov	al,[0xf]		; 05627
	xor	ah,ah			; 0562A
	db	0x3D, 0x01, 0x00	; 0562C cmp ax,0x1
	jng	short loc_0564B		; 0562F jng 0x564b
	push	word [si+0x2]		; 05631
	call	dos_close_file		; 05634
	db	0x8B, 0xE5		; 05637 mov sp,bp
	cmp	word [0x80],0x0		; 05639
	jz	short loc_0564B		; 0563E jz 0x564b
	mov	word [0xe4be],0x5	; 05640
	mov	word [bp+0x2],0xffff	; 05646
loc_0564B:
	mov	si,[bp+0x4]		; 0564B
	mov	byte [si],0x0		; 0564E
	mov	ax,[bp+0x2]		; 05651
	add	sp,0x8			; 05654
	pop	bp			; 05657
	ret				; 05658

; ---- function delete_resource_file ----
delete_resource_file:
	push	bp			; 05659
	sub	sp,0x28			; 0565A
	db	0x8B, 0xEC		; 0565D mov bp,sp
	mov	al,[0xf]		; 0565F
	xor	ah,ah			; 05662
	db	0x3D, 0x01, 0x00	; 05664 cmp ax,0x1
	jng	short loc_0568D		; 05667 jng 0x568d
	push	word [bp+0x2c]		; 05669
	call	dos_delete_file		; 0566C
	db	0x8B, 0xE5		; 0566F mov sp,bp
	cmp	word [0x80],0x0		; 05671
	jz	short loc_05686		; 05676 jz 0x5686
	mov	word [0xe4be],0x2	; 05678
	mov	ax,0xffff		; 0567E
	add	sp,0x28			; 05681
	pop	bp			; 05684
	ret				; 05685
loc_05686:
	db	0x33, 0xC0		; 05686 xor ax,ax
	add	sp,0x28			; 05688
	pop	bp			; 0568B
	ret				; 0568C
loc_0568D:
	add	sp,0x28			; 0568D
	pop	bp			; 05690
	ret				; 05691
	push	bp			; 05692
	sub	sp,0x2			; 05693
	db	0x8B, 0xEC		; 05696 mov bp,sp
	push	word [bp+0x6]		; 05698
	call	delete_resource_file	; 0569B
	db	0x8B, 0xE5		; 0569E mov sp,bp
	add	sp,0x2			; 056A0
	pop	bp			; 056A3
	ret				; 056A4
	push	bp			; 056A5
	sub	sp,0x4e			; 056A6
	db	0x8B, 0xEC		; 056A9 mov bp,sp
	mov	al,[0xf]		; 056AB
	xor	ah,ah			; 056AE
	db	0x3D, 0x01, 0x00	; 056B0 cmp ax,0x1
	jng	short loc_056D9		; 056B3 jng 0x56d9
	push	word [bp+0x54]		; 056B5
	push	word [bp+0x52]		; 056B8
	call	dos_rename_file		; 056BB
	db	0x8B, 0xE5		; 056BE mov sp,bp
	test	ax,ax			; 056C0
	jz	short loc_056D2		; 056C2 jz 0x56d2
	mov	word [0xe4be],0x5	; 056C4
	mov	ax,0xffff		; 056CA
	add	sp,0x4e			; 056CD
	pop	bp			; 056D0
	ret				; 056D1
loc_056D2:
	db	0x33, 0xC0		; 056D2 xor ax,ax
	add	sp,0x4e			; 056D4
	pop	bp			; 056D7
	ret				; 056D8
loc_056D9:
	add	sp,0x4e			; 056D9
	pop	bp			; 056DC
	ret				; 056DD

; ---- function strcpy ----
strcpy:
	push	bp			; 056DE
	sub	sp,0x8			; 056DF
	db	0x8B, 0xEC		; 056E2 mov bp,sp
	mov	ax,[bp+0xc]		; 056E4
	mov	[bp+0x6],ax		; 056E7
loc_056EA:
	mov	si,[bp+0x6]		; 056EA
	inc	word [bp+0x6]		; 056ED
	mov	di,[bp+0xe]		; 056F0
	inc	word [bp+0xe]		; 056F3
	mov	al,[di]			; 056F6
	mov	[si],al			; 056F8
	test	al,al			; 056FA
	jnz	short loc_056EA		; 056FC jnz 0x56ea
	mov	ax,[bp+0xc]		; 056FE
	add	sp,0x8			; 05701
	pop	bp			; 05704
	ret				; 05705
	push	bp			; 05706
	sub	sp,0x6			; 05707
	db	0x8B, 0xEC		; 0570A mov bp,sp
	mov	ax,[bp+0xa]		; 0570C
	mov	[bp+0x4],ax		; 0570F
loc_05712:
	cmp	word [bp+0xe],0x0	; 05712
	jng	short loc_05733		; 05716 jng 0x5733
	mov	si,[bp+0xc]		; 05718
	inc	word [bp+0xc]		; 0571B
	mov	al,[si]			; 0571E
	mov	di,[bp+0x4]		; 05720
	mov	[di],al			; 05723
	test	al,al			; 05725
	jz	short loc_05733		; 05727 jz 0x5733
	inc	word [bp+0x4]		; 05729
	jmp	short loc_0572E		; 0572C jmp 0x572e
loc_0572E:
	dec	word [bp+0xe]		; 0572E
	jmp	short loc_05712		; 05731 jmp 0x5712
loc_05733:
	mov	si,[bp+0x4]		; 05733
	mov	byte [si],0x0		; 05736
	mov	ax,[bp+0xa]		; 05739
	add	sp,0x6			; 0573C
	pop	bp			; 0573F
	ret				; 05740

; ---- function scanf_format_parser ----
scanf_format_parser:
	push	bp			; 05741
	sub	sp,0x10			; 05742
	db	0x8B, 0xEC		; 05745 mov bp,sp
	mov	ax,[bp+0x14]		; 05747
	lea	bx,[bp+0x18]		; 0574A
	mov	word [bp+0x4],0x0	; 0574D
	mov	[0xe43a],ax		; 05752
	mov	[bp+0xc],bx		; 05755
loc_05758:
	mov	si,[bp+0x16]		; 05758
	mov	al,[si]			; 0575B
	xor	ah,ah			; 0575D
	test	ax,ax			; 0575F
	jnz	short loc_05766		; 05761 jnz 0x5766
	jmp	0x5a71			; 05763
loc_05766:
	inc	word [bp+0x16]		; 05766
	mov	al,[si]			; 05769
	xor	ah,ah			; 0576B
	db	0x8B, 0xF0		; 0576D mov si,ax
	mov	bl,[si-0x1b3b]		; 0576F
	xor	bh,bh			; 05773
	db	0x81, 0xE3, 0x08, 0x00	; 05775 and bx,0x8
	mov	[bp+0x6],ax		; 05779
	jnz	short loc_05758		; 0577C jnz 0x5758
	db	0x3D, 0x25, 0x00	; 0577E cmp ax,0x25
	jz	short loc_05786		; 05781 jz 0x5786
	jmp	0x5a3b			; 05783
loc_05786:
	mov	si,[bp+0x16]		; 05786
	mov	al,[si]			; 05789
	xor	ah,ah			; 0578B
	db	0x3D, 0x25, 0x00	; 0578D cmp ax,0x25
	jnz	short loc_057BD		; 05790 jnz 0x57bd
loc_05792:
	mov	si,[0xe43a]		; 05792
	inc	word [0xe43a]		; 05796
	mov	al,[si]			; 0579A
	xor	ah,ah			; 0579C
	mov	[bp+0x6],ax		; 0579E
	mov	si,[bp+0x6]		; 057A1
	mov	al,[si-0x1b3b]		; 057A4
	xor	ah,ah			; 057A8
	db	0x25, 0x08, 0x00	; 057AA and ax,0x8
	jnz	short loc_05792		; 057AD jnz 0x5792
	cmp	word [bp+0x6],0x25	; 057AF
	jz	short loc_05758		; 057B3 jz 0x5758
	mov	ax,[bp+0x4]		; 057B5
	add	sp,0x10			; 057B8
	pop	bp			; 057BB
	ret				; 057BC
loc_057BD:
	mov	si,[bp+0x16]		; 057BD
	mov	al,[si]			; 057C0
	xor	ah,ah			; 057C2
	db	0x3D, 0x2A, 0x00	; 057C4 cmp ax,0x2a
	jz	short loc_057D5		; 057C7 jz 0x57d5
	mov	ax,[bp+0xc]		; 057C9
	add	word [bp+0xc],0x2	; 057CC
	mov	[bp+0xe],ax		; 057D0
	jmp	short loc_057DD		; 057D3 jmp 0x57dd
loc_057D5:
	mov	word [bp+0xe],0x0	; 057D5
	inc	word [bp+0x16]		; 057DA
loc_057DD:
	mov	word [bp+0x8],0x0	; 057DD
	push	word [bp+0xe]		; 057E2
	lea	ax,[bp+0x8]		; 057E5
	push	ax			; 057E8
	db	0x8B, 0x06, 0x3C, 0xE4	; 057E9 mov ax,[0xe43c]
	push	ax			; 057ED
	push	word [bp+0x16]		; 057EE
	call	parse_number		; 057F1
	db	0x8B, 0xE5		; 057F4 mov sp,bp
	test	ax,ax			; 057F6
	mov	[bp+0xa],ax		; 057F8
	jz	short loc_05800		; 057FB jz 0x5800
	mov	[bp+0x16],ax		; 057FD
loc_05800:
	cmp	word [bp+0x8],0xffffffffffffffff	; 05800
	jnz	short loc_05823		; 05804 jnz 0x5823
	cmp	word [bp+0xa],0x0	; 05806
	jz	short loc_0580F		; 0580A jz 0x580f
	inc	word [bp+0x4]		; 0580C
loc_0580F:
	mov	ax,[bp+0x4]		; 0580F
	test	ax,ax			; 05812
	jng	short loc_0581B		; 05814 jng 0x581b
	add	sp,0x10			; 05816
	pop	bp			; 05819
	ret				; 0581A
loc_0581B:
	mov	ax,0xffff		; 0581B
	add	sp,0x10			; 0581E
	pop	bp			; 05821
	ret				; 05822
loc_05823:
	cmp	word [bp+0x8],0x0	; 05823
	jz	short loc_0582D		; 05827 jz 0x582d
	dec	word [0xe43a]		; 05829
loc_0582D:
	cmp	word [bp+0xa],0x0	; 0582D
	jnz	short loc_0586B		; 05831 jnz 0x586b
	mov	ax,[bp+0x4]		; 05833
	add	sp,0x10			; 05836
	pop	bp			; 05839
	ret				; 0583A
loc_0583B:
	mov	si,[0xe43a]		; 0583B
	inc	word [0xe43a]		; 0583F
	mov	al,[si]			; 05843
	xor	ah,ah			; 05845
	mov	[bp+0x8],ax		; 05847
	mov	si,[bp+0x8]		; 0584A
	mov	al,[si-0x1b3b]		; 0584D
	xor	ah,ah			; 05851
	db	0x25, 0x08, 0x00	; 05853 and ax,0x8
	jnz	short loc_0583B		; 05856 jnz 0x583b
	mov	ax,[bp+0x8]		; 05858
	cmp	ax,[bp+0x6]		; 0585B
	jnz	short loc_05863		; 0585E jnz 0x5863
	jmp	0x5958			; 05860
loc_05863:
	mov	ax,[bp+0x4]		; 05863
	add	sp,0x10			; 05866
	pop	bp			; 05869
	ret				; 0586A
loc_0586B:
	inc	word [bp+0x4]		; 0586B
	jmp	0x5958			; 0586E
	mov	ax,[bp+0x4]		; 05871
	add	sp,0x10			; 05874
	pop	bp			; 05877
	ret				; 05878
	push	bp			; 05879
	sub	sp,0x6			; 0587A
	db	0x8B, 0xEC		; 0587D mov bp,sp
	mov	si,[0xe43a]		; 0587F
	inc	word [0xe43a]		; 05883
	mov	al,[si]			; 05887
	xor	ah,ah			; 05889
	mov	[bp+0x4],ax		; 0588B
	test	ax,ax			; 0588E
	jnz	short loc_05895		; 05890 jnz 0x5895
	mov	ax,0xffff		; 05892
loc_05895:
	add	sp,0x6			; 05895
	pop	bp			; 05898
	ret				; 05899

; ---- function print_error ----
print_error:
	push	bp			; 0589A
	sub	sp,0x6			; 0589B
	db	0x8B, 0xEC		; 0589E mov bp,sp
loc_058A0:
	mov	si,[bp+0xa]		; 058A0
	inc	word [bp+0xa]		; 058A3
	mov	al,[si]			; 058A6
	xor	ah,ah			; 058A8
	test	ax,ax			; 058AA
	mov	[bp+0x4],ax		; 058AC
	jz	short loc_058DA		; 058AF jz 0x58da
	mov	bx,[0xe1c2]		; 058B1
	dec	bx			; 058B5
	test	bx,bx			; 058B6
	mov	[0xe1c2],bx		; 058B8
	js	short loc_058CC		; 058BC js 0x58cc
	mov	si,[0xe1be]		; 058BE
	inc	word [0xe1be]		; 058C2
	mov	[si],al			; 058C6
	xor	ah,ah			; 058C8
	jmp	short loc_058A0		; 058CA jmp 0x58a0
loc_058CC:
	mov	ax,0xe1be		; 058CC
	push	ax			; 058CF
	push	word [bp+0x4]		; 058D0
	call	crt_file_write_byte	; 058D3
	db	0x8B, 0xE5		; 058D6 mov sp,bp
	jmp	short loc_058A0		; 058D8 jmp 0x58a0
loc_058DA:
	mov	ax,[0xe1c2]		; 058DA
	dec	ax			; 058DD
	test	ax,ax			; 058DE
	mov	[0xe1c2],ax		; 058E0
	js	short loc_058F5		; 058E3 js 0x58f5
	mov	si,[0xe1be]		; 058E5
	inc	word [0xe1be]		; 058E9
	mov	al,0xa			; 058ED
	mov	[si],al			; 058EF
	xor	ah,ah			; 058F1
	jmp	short loc_05902		; 058F3 jmp 0x5902
loc_058F5:
	mov	ax,0xe1be		; 058F5
	push	ax			; 058F8
	mov	ax,0xa			; 058F9
	push	ax			; 058FC
	call	crt_file_write_byte	; 058FD
	db	0x8B, 0xE5		; 05900 mov sp,bp
loc_05902:
	add	sp,0x6			; 05902
	pop	bp			; 05905
	ret				; 05906

; ---- function init_file_system ----
init_file_system:
	push	bp			; 05907
	sub	sp,0x8			; 05908
	db	0x8B, 0xEC		; 0590B mov bp,sp
	mov	word [bp+0x6],0x0	; 0590D
loc_05912:
	mov	si,[bp+0xc]		; 05912
	inc	word [bp+0xc]		; 05915
	mov	al,[si]			; 05918
	xor	ah,ah			; 0591A
	test	ax,ax			; 0591C
	mov	[bp+0x4],ax		; 0591E
	jz	short loc_0594B		; 05921 jz 0x594b
	mov	si,[bp+0xe]		; 05923
	mov	bx,[si+0x4]		; 05926
	dec	bx			; 05929
	mov	[si+0x4],bx		; 0592A
	test	bx,bx			; 0592D
	js	short loc_0593B		; 0592F js 0x593b
	mov	bx,[si]			; 05931
	inc	word [si]		; 05933
	mov	[bx],al			; 05935
	xor	ah,ah			; 05937
	jmp	short loc_05946		; 05939 jmp 0x5946
loc_0593B:
	push	word [bp+0xe]		; 0593B
	push	word [bp+0x4]		; 0593E
	call	crt_file_write_byte	; 05941
	db	0x8B, 0xE5		; 05944 mov sp,bp
loc_05946:
	mov	[bp+0x6],ax		; 05946
	jmp	short loc_05912		; 05949 jmp 0x5912
loc_0594B:
	mov	ax,[bp+0x6]		; 0594B
	add	sp,0x8			; 0594E
	pop	bp			; 05951
	ret				; 05952
