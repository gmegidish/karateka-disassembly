; Combat system: update, hit detection, damage, AI


; ---- function combat_update ----
combat_update:
	push	bp			; 01AC2
	sub	sp,0x4			; 01AC3
	jc	short loc_01ACE		; 01AC6 jc 0x1ace
	cmp	sp,[0x17]		; 01AC8
	ja	short loc_01AD1		; 01ACC ja 0x1ad1
loc_01ACE:
	jmp	0x420			; 01ACE
loc_01AD1:
	db	0x8B, 0xEC		; 01AD1 mov bp,sp
	push	word [bp+0x8]		; 01AD3
	call	load_animation		; 01AD6
	db	0x8B, 0xE5		; 01AD9 mov sp,bp
	mov	ax,[bp+0x8]		; 01ADB
	db	0x3D, 0x04, 0x00	; 01ADE cmp ax,0x4
	jnl	short loc_01B0E		; 01AE1 jnl 0x1b0e
	shl	ax,1			; 01AE3
	db	0x8B, 0xF0		; 01AE5 mov si,ax
	mov	ax,0xc102		; 01AE7
	push	ax			; 01AEA
	push	word [si+0x21c]		; 01AEB
	call	load_anim_script	; 01AEF
	db	0x8B, 0xE5		; 01AF2 mov sp,bp
	cmp	word [bp+0x8],0x2	; 01AF4
	jnl	short loc_01B05		; 01AF8 jnl 0x1b05
	mov	ax,0x1			; 01AFA
	push	ax			; 01AFD
	call	stop_sound		; 01AFE
	db	0x8B, 0xE5		; 01B01 mov sp,bp
	jmp	short loc_01B0E		; 01B03 jmp 0x1b0e
loc_01B05:
	mov	ax,0x6			; 01B05
	push	ax			; 01B08
	call	stop_sound		; 01B09
	db	0x8B, 0xE5		; 01B0C mov sp,bp
loc_01B0E:
	cmp	word [bp+0x8],0x2	; 01B0E
	jnz	short loc_01B17		; 01B12 jnz 0x1b17
	call	update_score		; 01B14
loc_01B17:
	push	word [bp+0x8]		; 01B17
	call	combat_check_hit	; 01B1A
	db	0x8B, 0xE5		; 01B1D mov sp,bp
	call	flush_keyboard		; 01B1F
	add	sp,0x4			; 01B22
	pop	bp			; 01B25
	ret				; 01B26

; ---- function combat_check_hit ----
combat_check_hit:
	push	bp			; 01B27
	sub	sp,0x6			; 01B28
	jc	short loc_01B33		; 01B2B jc 0x1b33
	cmp	sp,[0x17]		; 01B2D
	ja	short loc_01B36		; 01B31 ja 0x1b36
loc_01B33:
	jmp	0x420			; 01B33
loc_01B36:
	db	0x8B, 0xEC		; 01B36 mov bp,sp
	mov	word [0x158],0xffff	; 01B38
	db	0x33, 0xC0		; 01B3E xor ax,ax
	mov	bx,[bp+0xa]		; 01B40
	cmp	bx,0x2			; 01B43
	mov	[0x12e],ax		; 01B46
	mov	[0xe4],ax		; 01B49
	jz	short loc_01B53		; 01B4C jz 0x1b53
	cmp	bx,0x4			; 01B4E
	jnz	short loc_01B59		; 01B51 jnz 0x1b59
loc_01B53:
	mov	word [0x12e],0x1	; 01B53
loc_01B59:
	mov	word [0xee],0x1		; 01B59
	mov	word [0xbb2a],0xffff	; 01B5F
	mov	ax,[bp+0xa]		; 01B65
	shl	ax,1			; 01B68
	db	0x8B, 0xF0		; 01B6A mov si,ax
	mov	bx,[si+0x2e6]		; 01B6C
	mov	cx,[si+0x2f0]		; 01B70
	mov	dx,[si+0x2fa]		; 01B74
	mov	[0xbcd5],bx		; 01B78
	mov	bx,[si+0x304]		; 01B7C
	mov	[0x108],bx		; 01B80
	mov	bx,[si+0x30e]		; 01B84
	mov	ax,[si+0x318]		; 01B88
	push	word [bp+0xa]		; 01B8C
	mov	[0x100],ax		; 01B8F
	mov	[0x102],cx		; 01B92
	mov	[0x106],dx		; 01B96
	mov	[0x104],dx		; 01B9A
	mov	[0x10a],bx		; 01B9E
	call	combat_apply_damage	; 01BA2
	db	0x8B, 0xE5		; 01BA5 mov sp,bp
	cmp	word [bp+0xa],0x3	; 01BA7
	jnz	short loc_01BED		; 01BAB jnz 0x1bed
	mov	ax,0x1			; 01BAD
	mov	word [0x13e],0x0	; 01BB0
	mov	word [0x140],0x3	; 01BB6
	mov	word [bp+0x4],0x2	; 01BBC
	mov	[0x132],ax		; 01BC1
	mov	[0x134],ax		; 01BC4
	mov	[0x138],ax		; 01BC7
	mov	[0x13a],ax		; 01BCA
	mov	[0x13c],ax		; 01BCD
loc_01BD0:
	mov	ax,[bp+0x4]		; 01BD0
	db	0x3D, 0x07, 0x00	; 01BD3 cmp ax,0x7
	jnl	short loc_01BE7		; 01BD6 jnl 0x1be7
	shl	ax,1			; 01BD8
	db	0x8B, 0xF0		; 01BDA mov si,ax
	mov	word [si+0x142],0x0	; 01BDC
	inc	word [bp+0x4]		; 01BE2
	jmp	short loc_01BD0		; 01BE5 jmp 0x1bd0
loc_01BE7:
	mov	word [0x144],0x1	; 01BE7
loc_01BED:
	mov	ax,[bp+0xa]		; 01BED
	db	0x3D, 0x01, 0x00	; 01BF0 cmp ax,0x1
	jz	short loc_01C06		; 01BF3 jz 0x1c06
	db	0x3D, 0x04, 0x00	; 01BF5 cmp ax,0x4
	jz	short loc_01C06		; 01BF8 jz 0x1c06
	mov	ax,[0xc3fa]		; 01BFA
	mov	word [0x10c],0x41	; 01BFD
	mov	[0xc3d2],ax		; 01C03
loc_01C06:
	mov	word [0xee],0x1		; 01C06
	mov	word [0xf8],0x0		; 01C0C
	cmp	word [bp+0xa],0x2	; 01C12
	jnl	short loc_01C20		; 01C16 jnl 0x1c20
	mov	word [0x116],0xd	; 01C18
	jmp	short loc_01C3A		; 01C1E jmp 0x1c3a
loc_01C20:
	cmp	word [bp+0xa],0x2	; 01C20
	jnz	short loc_01C2E		; 01C24 jnz 0x1c2e
	mov	word [0x116],0xc	; 01C26
	jmp	short loc_01C3A		; 01C2C jmp 0x1c3a
loc_01C2E:
	cmp	word [bp+0xa],0x3	; 01C2E
	jnz	short loc_01C3A		; 01C32 jnz 0x1c3a
	mov	word [0x116],0xa	; 01C34
loc_01C3A:
	db	0x33, 0xC0		; 01C3A xor ax,ax
	mov	bx,[0x120]		; 01C3C
	cmp	word [bp+0xa],0x0	; 01C40
	mov	[0x124],ax		; 01C44
	mov	[0xd652],ax		; 01C47
	mov	[0x126],bx		; 01C4A
	jnz	short loc_01C53		; 01C4E jnz 0x1c53
	mov	[0xf6],ax		; 01C50
loc_01C53:
	add	sp,0x6			; 01C53
	pop	bp			; 01C56
	ret				; 01C57

; ---- function combat_apply_damage ----
combat_apply_damage:
	push	bp			; 01C58
	sub	sp,0x2			; 01C59
	jc	short loc_01C64		; 01C5C jc 0x1c64
	cmp	sp,[0x17]		; 01C5E
	ja	short loc_01C67		; 01C62 ja 0x1c67
loc_01C64:
	jmp	0x420			; 01C64
loc_01C67:
	db	0x8B, 0xEC		; 01C67 mov bp,sp
	mov	ax,0x1			; 01C69
	mov	bx,[bp+0x6]		; 01C6C
	shl	bx,1			; 01C6F
	mov	cx,[bx+0x2dc]		; 01C71
	cmp	word [bp+0x6],0x3	; 01C75
	mov	[0xe8],ax		; 01C79
	mov	[0x10e],cx		; 01C7C
	jnz	short loc_01C8F		; 01C80 jnz 0x1c8f
	cmp	word [0x130],0x1	; 01C82
	jng	short loc_01C8F		; 01C87 jng 0x1c8f
	sub	word [0x10e],0x140	; 01C89
loc_01C8F:
	cmp	word [bp+0x6],0x2	; 01C8F
	jnl	short loc_01CA3		; 01C93 jnl 0x1ca3
	mov	word [0x110],0x41	; 01C95
	mov	ax,[0xce10]		; 01C9B
	mov	[0xcde8],ax		; 01C9E
	jmp	short loc_01CAF		; 01CA1 jmp 0x1caf
loc_01CA3:
	mov	word [0x110],0x1	; 01CA3
	mov	ax,[0xcdea]		; 01CA9
	mov	[0xcde8],ax		; 01CAC
loc_01CAF:
	db	0x33, 0xC0		; 01CAF xor ax,ax
	cmp	word [bp+0x6],0x2	; 01CB1
	mov	[0xfa],ax		; 01CB5
	mov	[0xf2],ax		; 01CB8
	jnl	short loc_01CC5		; 01CBB jnl 0x1cc5
	mov	word [0xf4],0x78	; 01CBD
	jmp	short loc_01CCB		; 01CC3 jmp 0x1ccb
loc_01CC5:
	mov	word [0xf4],0xa0	; 01CC5
loc_01CCB:
	mov	word [0x114],0xd	; 01CCB
	cmp	word [bp+0x6],0x1	; 01CD1
	jng	short loc_01CE5		; 01CD5 jng 0x1ce5
	mov	ax,0x1a			; 01CD7
	sub	ax,[0x116]		; 01CDA
	sub	ax,[0x124]		; 01CDE
	mov	[0x114],ax		; 01CE2
loc_01CE5:
	db	0x33, 0xC0		; 01CE5 xor ax,ax
	mov	bx,[0x11c]		; 01CE7
	mov	cx,[0x158]		; 01CEB
	cmp	cx,0x4			; 01CEF
	mov	[0x11e],ax		; 01CF2
	mov	[0xd650],ax		; 01CF5
	mov	[0x128],bx		; 01CF8
	jnl	short loc_01D02		; 01CFC jnl 0x1d02
	inc	word [0x158]		; 01CFE
loc_01D02:
	add	sp,0x2			; 01D02
	pop	bp			; 01D05
	ret				; 01D06

; ---- function combat_ai ----
combat_ai:
	push	bp			; 01D07
	sub	sp,0x6			; 01D08
	jc	short loc_01D13		; 01D0B jc 0x1d13
	cmp	sp,[0x17]		; 01D0D
	ja	short loc_01D16		; 01D11 ja 0x1d16
loc_01D13:
	jmp	0x420			; 01D13
loc_01D16:
	db	0x8B, 0xEC		; 01D16 mov bp,sp
	cmp	word [0x16e],0x0	; 01D18
	jng	short loc_01D27		; 01D1D jng 0x1d27
	mov	ax,0xffff		; 01D1F
	add	sp,0x6			; 01D22
	pop	bp			; 01D25
	ret				; 01D26
loc_01D27:
	db	0x33, 0xC0		; 01D27 xor ax,ax
	push	ax			; 01D29
	call	poll_keyboard		; 01D2A
	db	0x8B, 0xE5		; 01D2D mov sp,bp
	test	ax,ax			; 01D2F
	jz	short loc_01D82		; 01D31 jz 0x1d82
	call	get_pending_key		; 01D33
	push	ax			; 01D36
	mov	[bp+0x4],ax		; 01D37
	call	key_to_move		; 01D3A
	db	0x8B, 0xE5		; 01D3D mov sp,bp
	mov	[bp+0x2],ax		; 01D3F
	inc	ax			; 01D42
	jz	short loc_01D61		; 01D43 jz 0x1d61
	push	word [bp+0x4]		; 01D45
	push	word [bp+0x2]		; 01D48
	call	combat_resolve_move	; 01D4B
	db	0x8B, 0xE5		; 01D4E mov sp,bp
	mov	[bp+0x2],ax		; 01D50
	inc	ax			; 01D53
	jnz	short loc_01D61		; 01D54 jnz 0x1d61
	mov	ax,[bp+0x4]		; 01D56
	mov	byte [0xdf43],0x1	; 01D59
	mov	[0xdf42],al		; 01D5E
loc_01D61:
	mov	ax,[bp+0x2]		; 01D61
	db	0x3D, 0xFF, 0xFF	; 01D64 cmp ax,0xffff
	jz	short loc_01D82		; 01D67 jz 0x1d82
	shl	ax,1			; 01D69
	db	0x8B, 0xF0		; 01D6B mov si,ax
	mov	ax,[si-0x3c2c]		; 01D6D
	mov	word [0xe6],0x1		; 01D71
	mov	[0xc3d2],ax		; 01D77
	mov	ax,[bp+0x2]		; 01D7A
	add	sp,0x6			; 01D7D
	pop	bp			; 01D80
	ret				; 01D81
loc_01D82:
	mov	ax,0xffff		; 01D82
	add	sp,0x6			; 01D85
	pop	bp			; 01D88
	ret				; 01D89

; ---- function get_pending_key ----
get_pending_key:
	push	bp			; 01D8A
	sub	sp,0x4			; 01D8B
	jc	short loc_01D96		; 01D8E jc 0x1d96
	cmp	sp,[0x17]		; 01D90
	ja	short loc_01D99		; 01D94 ja 0x1d99
loc_01D96:
	jmp	0x420			; 01D96
loc_01D99:
	db	0x8B, 0xEC		; 01D99 mov bp,sp
	mov	word [bp+0x2],0x0	; 01D9B
	cmp	word [0xdf46],0x1	; 01DA0
	jnz	short loc_01DBB		; 01DA5 jnz 0x1dbb
loc_01DA7:
	db	0x33, 0xC0		; 01DA7 xor ax,ax
	push	ax			; 01DA9
	call	poll_keyboard		; 01DAA
	db	0x8B, 0xE5		; 01DAD mov sp,bp
	test	ax,ax			; 01DAF
	jz	short loc_01DCD		; 01DB1 jz 0x1dcd
	call	wait_for_key		; 01DB3
	mov	[bp+0x2],ax		; 01DB6
	jmp	short loc_01DA7		; 01DB9 jmp 0x1da7
loc_01DBB:
	db	0x33, 0xC0		; 01DBB xor ax,ax
	push	ax			; 01DBD
	call	poll_keyboard		; 01DBE
	db	0x8B, 0xE5		; 01DC1 mov sp,bp
	test	ax,ax			; 01DC3
	jz	short loc_01DCD		; 01DC5 jz 0x1dcd
	call	wait_for_key		; 01DC7
	mov	[bp+0x2],ax		; 01DCA
loc_01DCD:
	mov	ax,[bp+0x2]		; 01DCD
	add	sp,0x4			; 01DD0
	pop	bp			; 01DD3
	ret				; 01DD4

; ---- function key_to_move ----
key_to_move:
	push	bp			; 01DD5
	sub	sp,0x6			; 01DD6
	jc	short loc_01DE1		; 01DD9 jc 0x1de1
	cmp	sp,[0x17]		; 01DDB
	ja	short loc_01DE4		; 01DDF ja 0x1de4
loc_01DE1:
	jmp	0x420			; 01DE1
loc_01DE4:
	db	0x8B, 0xEC		; 01DE4 mov bp,sp
	mov	ax,[bp+0xa]		; 01DE6
	db	0x3D, 0x41, 0x00	; 01DE9 cmp ax,0x41
	jl	short loc_01DF7		; 01DEC jl 0x1df7
	db	0x3D, 0x5A, 0x00	; 01DEE cmp ax,0x5a
	jg	short loc_01DF7		; 01DF1 jg 0x1df7
	add	word [bp+0xa],0x20	; 01DF3
loc_01DF7:
	cmp	word [bp+0xa],0x6a	; 01DF7
	jnz	short loc_01E0E		; 01DFB jnz 0x1e0e
	call	consume_key		; 01DFD
	mov	word [0xdf46],0x0	; 01E00
	mov	ax,0xffff		; 01E06
	add	sp,0x6			; 01E09
	pop	bp			; 01E0C
	ret				; 01E0D
loc_01E0E:
	cmp	word [bp+0xa],0x6b	; 01E0E
	jnz	short loc_01E25		; 01E12 jnz 0x1e25
	call	consume_key		; 01E14
	mov	word [0xdf46],0x1	; 01E17
	mov	ax,0xffff		; 01E1D
	add	sp,0x6			; 01E20
	pop	bp			; 01E23
	ret				; 01E24
loc_01E25:
	mov	ax,[bp+0xa]		; 01E25
	db	0x3D, 0x20, 0x00	; 01E28 cmp ax,0x20
	jl	short loc_01E30		; 01E2B jl 0x1e30
	jmp	0x20b8			; 01E2D
loc_01E30:
	db	0x3D, 0x12, 0x00	; 01E30 cmp ax,0x12
	jnz	short loc_01E3D		; 01E33 jnz 0x1e3d
	mov	word [0x16a],0x1	; 01E35
	jmp	short loc_01EB0		; 01E3B jmp 0x1eb0
loc_01E3D:
	cmp	word [bp+0xa],0x13	; 01E3D
	jnz	short loc_01E50		; 01E41 jnz 0x1e50
	mov	al,[0xd6bc]		; 01E43
	xor	ah,ah			; 01E46
	xor	ax,0xff			; 01E48
	mov	[0xd6bc],al		; 01E4B
	jmp	short loc_01EB0		; 01E4E jmp 0x1eb0
loc_01E50:
	cmp	word [bp+0xa],0x18	; 01E50
	jnz	short loc_01E63		; 01E54 jnz 0x1e63
	mov	al,[0xe1ac]		; 01E56
	xor	ah,ah			; 01E59
	xor	ax,0xff			; 01E5B
	mov	[0xe1ac],al		; 01E5E
	jmp	short loc_01EB0		; 01E61 jmp 0x1eb0
loc_01E63:
	cmp	word [bp+0xa],0x19	; 01E63
	jnz	short loc_01E76		; 01E67 jnz 0x1e76
	mov	al,[0xe1ab]		; 01E69
	xor	ah,ah			; 01E6C
	xor	ax,0xff			; 01E6E
	mov	[0xe1ab],al		; 01E71
	jmp	short loc_01EB0		; 01E74 jmp 0x1eb0
loc_01E76:
	cmp	word [bp+0xa],0x5	; 01E76
	jnz	short loc_01E89		; 01E7A jnz 0x1e89
	mov	al,[0xe1ad]		; 01E7C
	xor	ah,ah			; 01E7F
	xor	ax,0xff			; 01E81
	mov	[0xe1ad],al		; 01E84
	jmp	short loc_01EB0		; 01E87 jmp 0x1eb0
loc_01E89:
	cmp	word [bp+0xa],0x2	; 01E89
	jnz	short loc_01E9C		; 01E8D jnz 0x1e9c
	mov	al,[0xe1ae]		; 01E8F
	xor	ah,ah			; 01E92
	xor	ax,0xff			; 01E94
	mov	[0xe1ae],al		; 01E97
	jmp	short loc_01EB0		; 01E9A jmp 0x1eb0
loc_01E9C:
	cmp	word [bp+0xa],0xe	; 01E9C
	jnz	short loc_01EB0		; 01EA0 jnz 0x1eb0
	mov	al,0x0			; 01EA2
	mov	[0xe1ae],al		; 01EA4
	mov	[0xe1ad],al		; 01EA7
	mov	[0xe1ab],al		; 01EAA
	mov	[0xe1ac],al		; 01EAD
loc_01EB0:
	mov	ax,0xffff		; 01EB0
	add	sp,0x6			; 01EB3
	pop	bp			; 01EB6
	ret				; 01EB7
	cmp	word [bp+0xa],0x26	; 01EB8
	jnz	short loc_01ED3		; 01EBC jnz 0x1ed3
	cmp	word [0x10c],0x40	; 01EBE
	jnl	short loc_01ECB		; 01EC3 jnl 0x1ecb
	mov	word [0x10c],0x41	; 01EC5
loc_01ECB:
	mov	ax,0x8			; 01ECB
	add	sp,0x6			; 01ECE
	pop	bp			; 01ED1
	ret				; 01ED2
loc_01ED3:
	mov	word [bp+0x2],0x0	; 01ED3
loc_01ED8:
	mov	ax,[bp+0x2]		; 01ED8
	db	0x3D, 0x0B, 0x00	; 01EDB cmp ax,0xb
	jnl	short loc_01EF4		; 01EDE jnl 0x1ef4
	db	0x8B, 0xF0		; 01EE0 mov si,ax
	mov	al,[si+0x322]		; 01EE2
	xor	ah,ah			; 01EE6
	mov	bx,[bp+0xa]		; 01EE8
	db	0x3B, 0xD8		; 01EEB cmp bx,ax
	jz	short loc_01EF4		; 01EED jz 0x1ef4
	inc	word [bp+0x2]		; 01EEF
	jmp	short loc_01ED8		; 01EF2 jmp 0x1ed8
loc_01EF4:
	cmp	word [bp+0x2],0xb	; 01EF4
	jnz	short loc_01F02		; 01EF8 jnz 0x1f02
	mov	ax,0xffff		; 01EFA
	add	sp,0x6			; 01EFD
	pop	bp			; 01F00
	ret				; 01F01
loc_01F02:
	cmp	word [bp+0x2],0x6	; 01F02
	jnz	short loc_01F19		; 01F06 jnz 0x1f19
	mov	ax,[0xbcd5]		; 01F08
	cmp	ax,[0x102]		; 01F0B
	jnz	short loc_01F19		; 01F0F jnz 0x1f19
	mov	ax,0xffff		; 01F11
	add	sp,0x6			; 01F14
	pop	bp			; 01F17
	ret				; 01F18
loc_01F19:
	cmp	word [0x10c],0x3f	; 01F19
	jng	short loc_01F37		; 01F1E jng 0x1f37
	cmp	word [bp+0x2],0x6	; 01F20
	jnl	short loc_01F2E		; 01F24 jnl 0x1f2e
	mov	ax,0xffff		; 01F26
	add	sp,0x6			; 01F29
	pop	bp			; 01F2C
	ret				; 01F2D
loc_01F2E:
	mov	ax,[bp+0x2]		; 01F2E
	inc	ax			; 01F31
	add	sp,0x6			; 01F32
	pop	bp			; 01F35
	ret				; 01F36
loc_01F37:
	cmp	word [bp+0x2],0x8	; 01F37
	jng	short loc_01F45		; 01F3B jng 0x1f45
	mov	ax,0xffff		; 01F3D
	add	sp,0x6			; 01F40
	pop	bp			; 01F43
	ret				; 01F44
loc_01F45:
	mov	ax,[bp+0x2]		; 01F45
	inc	ax			; 01F48
	add	sp,0x6			; 01F49
	pop	bp			; 01F4C
	ret				; 01F4D

; ---- function combat_resolve_move ----
combat_resolve_move:
	push	bp			; 01F4E
	sub	sp,0x2			; 01F4F
	jc	short loc_01F5A		; 01F52 jc 0x1f5a
	cmp	sp,[0x17]		; 01F54
	ja	short loc_01F5D		; 01F58 ja 0x1f5d
loc_01F5A:
	jmp	0x420			; 01F5A
loc_01F5D:
	db	0x8B, 0xEC		; 01F5D mov bp,sp
	mov	ax,[0x10c]		; 01F5F
	jmp	0x2242			; 01F62
	mov	ax,[bp+0x6]		; 01F65
	add	sp,0x2			; 01F68
	pop	bp			; 01F6B
	ret				; 01F6C
	mov	ax,[bp+0x6]		; 01F6D
	db	0x3D, 0x04, 0x00	; 01F70 cmp ax,0x4
	jl	short loc_01F78		; 01F73 jl 0x1f78
	jmp	0x2256			; 01F75
loc_01F78:
	add	sp,0x2			; 01F78
	pop	bp			; 01F7B
	ret				; 01F7C
	mov	ax,[bp+0x6]		; 01F7D
	db	0x3D, 0x03, 0x00	; 01F80 cmp ax,0x3
	jg	short loc_01F88		; 01F83 jg 0x1f88
	jmp	0x2256			; 01F85
loc_01F88:
	db	0x3D, 0x07, 0x00	; 01F88 cmp ax,0x7
	jl	short loc_01F90		; 01F8B jl 0x1f90
	jmp	0x2256			; 01F8D
loc_01F90:
	db	0x05, 0x14, 0x00	; 01F90 add ax,0x14
	add	sp,0x2			; 01F93
	pop	bp			; 01F96
	ret				; 01F97
	mov	ax,[bp+0x6]		; 01F98
	db	0x3D, 0x07, 0x00	; 01F9B cmp ax,0x7
	jz	short loc_01FA8		; 01F9E jz 0x1fa8
	db	0x3D, 0x08, 0x00	; 01FA0 cmp ax,0x8
	jz	short loc_01FA8		; 01FA3 jz 0x1fa8
	jmp	0x2256			; 01FA5
loc_01FA8:
	mov	ax,[bp+0x6]		; 01FA8
	db	0x05, 0x05, 0x00	; 01FAB add ax,0x5
	add	sp,0x2			; 01FAE
	pop	bp			; 01FB1
	ret				; 01FB2
	cmp	word [bp+0x6],0x8	; 01FB3
	jnz	short loc_01FC1		; 01FB7 jnz 0x1fc1
	mov	ax,0x14			; 01FB9
	add	sp,0x2			; 01FBC
	pop	bp			; 01FBF
	ret				; 01FC0
loc_01FC1:
	cmp	word [bp+0x6],0x9	; 01FC1
	jnz	short loc_01FCF		; 01FC5 jnz 0x1fcf
	mov	ax,0xa			; 01FC7
	add	sp,0x2			; 01FCA
	pop	bp			; 01FCD
	ret				; 01FCE
loc_01FCF:
	cmp	word [bp+0x6],0xa	; 01FCF
	jz	short loc_01FD8		; 01FD3 jz 0x1fd8
	jmp	0x2256			; 01FD5
loc_01FD8:
	mov	ax,0xb			; 01FD8
	add	sp,0x2			; 01FDB
	pop	bp			; 01FDE
	ret				; 01FDF
	cmp	word [bp+0x6],0x7	; 01FE0
	jnz	short loc_01FEE		; 01FE4 jnz 0x1fee
	mov	ax,0x13			; 01FE6
	add	sp,0x2			; 01FE9
	pop	bp			; 01FEC
	ret				; 01FED
loc_01FEE:
	cmp	word [bp+0x6],0x9	; 01FEE
	jnz	short loc_01FFC		; 01FF2 jnz 0x1ffc
	mov	ax,0x10			; 01FF4
	add	sp,0x2			; 01FF7
	pop	bp			; 01FFA
	ret				; 01FFB
loc_01FFC:
	cmp	word [bp+0x6],0xb	; 01FFC
	jnz	short loc_02056		; 02000 jnz 0x2056
	mov	ax,0x13			; 02002
	add	sp,0x2			; 02005
	pop	bp			; 02008
	ret				; 02009
	inc	si			; 0200A
	add	al,ah			; 0200B
	pop	ds			; 0200D
	inc	cx			; 0200E
	add	[bp+di+0xb1f],dh	; 0200F
	add	[bx+si+0xa1f],bl	; 02013
	add	[bx+si+0x71f],bl	; 02017
	add	[di+0x1f],bh		; 0201B
	push	es			; 0201E
	add	[di+0x1f],bh		; 0201F
	add	ax,0x7d00		; 02022
	pop	ds			; 02025
	sub	al,0x0			; 02026
	insw				; 02028
	pop	ds			; 02029
	sub	ax,[bx+si]		; 0202A
	insw				; 0202C
	pop	ds			; 0202D
	sub	al,[bx+si]		; 0202E
	insw				; 02030
	pop	ds			; 02031
	add	al,0x0			; 02032
	insw				; 02034
	pop	ds			; 02035
	add	ax,[bx+si]		; 02036
	insw				; 02038
	pop	ds			; 02039
	add	al,[bx+si]		; 0203A
	insw				; 0203C
	pop	ds			; 0203D
	add	[bx+si],ax		; 0203E
	gs	pop ds			; 02040
	mov	si,0x34			; 02042
loc_02045:
	cmp	ax,[cs:si+0x200a]	; 02045
	jnz	short loc_02051		; 0204A jnz 0x2051
	jmp	word near [cs:si+0x200c]	; 0204C
loc_02051:
	sub	si,0x4			; 02051
	jns	short loc_02045		; 02054 jns 0x2045
loc_02056:
	mov	ax,0xffff		; 02056
	add	sp,0x2			; 02059
	pop	bp			; 0205C
	ret				; 0205D
