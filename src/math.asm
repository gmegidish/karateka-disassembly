; Player animation selection, memory copy, sprite frame copy


; ---- function player_anim_select ----
; Selects the next animation ID for the player character.
; Mirror of enemy_ai_decide in scene.asm but for the player.
; Based on current player animation state, combat state, and input flags,
; determines which animation to play next.
;
; Key behaviors:
;   - scene_index==2 && anim_bg_counter==3: sets scene advance flag [0x12A]=1
;   - combat_active: returns 0x1E (approach) or 0x1F (walk)
;   - Player anim 0x08 (kick): plays sound via play_sound, clears flags
;   - Player anim 0x44: sets combat_active=2 (victory), returns 0
;   - Player was hit [0xFC]: knockback 8px, returns 0x1B if mid-attack else 0
;   - [0x16C] trigger: returns rand_range(1)+0x11
;   - Falls through to jump table at 0x2247 for pose-specific dispatch
;
; Input: reads globals (player_anim_id [0x10C], combat_active [0xF8], etc.)
; Output: AX = animation table index for player
player_anim_select:
	push	bp			; 0205E
	sub	sp,0x4			; 0205F
	jc	short player_anim_select_stack_overflow		; 02062 jc 0x206a
	cmp	sp,[stack_limit]		; 02064
	ja	short player_anim_select_stack_ok		; 02068 ja 0x206d
player_anim_select_stack_overflow:
	jmp	near stack_overflow_handler			; 0206A
player_anim_select_stack_ok:
	db	0x8B, 0xEC		; 0206D mov bp,sp
	cmp	word [scene_index],0x2	; 0206F
	jnz	short player_anim_select_check_combat_active		; 02074 jnz 0x2083
	cmp	word [anim_bg_counter],0x3	; 02076
	jnz	short player_anim_select_check_combat_active		; 0207B jnz 0x2083
	mov	word [anim_row_reload_state],0x1	; 0207D
player_anim_select_check_combat_active:
	cmp	word [combat_active],0x1		; 02083
	jnz	short player_anim_select_check_kick_finished		; 02088 jnz 0x20a1
	cmp	word [player_anim_id],0x1d	; 0208A
	jnz	short player_anim_select_return_approach		; 0208F jnz 0x2099
	mov	ax,0x1f			; 02091
	add	sp,0x4			; 02094
	pop	bp			; 02097
	ret				; 02098
player_anim_select_return_approach:
	mov	ax,0x1e			; 02099
	add	sp,0x4			; 0209C
	pop	bp			; 0209F
	ret				; 020A0
player_anim_select_check_kick_finished:
	cmp	word [player_anim_id],0x8	; 020A1
	jnz	short player_anim_select_check_combat_end_anim		; 020A6 jnz 0x20d0
	cmp	word [player_flag_170],0x0	; 020A8
	jnz	short player_anim_select_kick_alternate_sound		; 020AD jnz 0x20ba
	mov	ax,0xb			; 020AF
	push	ax			; 020B2
	call	play_sound		; 020B3
	db	0x8B, 0xE5		; 020B6 mov sp,bp
	jmp	short player_anim_select_clear_kick_flags		; 020B8 jmp 0x20c3
player_anim_select_kick_alternate_sound:
	mov	ax,0x14			; 020BA
	push	ax			; 020BD
	call	play_sound		; 020BE
	db	0x8B, 0xE5		; 020C1 mov sp,bp
player_anim_select_clear_kick_flags:
	db	0x33, 0xC0		; 020C3 xor ax,ax
	mov	[key_pending],al		; 020C5
	mov	[player_flag_174],ax		; 020C8
	mov	[combat_counter_b],ax		; 020CB
	jmp	short player_anim_select_check_player_hit		; 020CE jmp 0x20e4
player_anim_select_check_combat_end_anim:
	cmp	word [player_anim_id],0x44	; 020D0
	jnz	short player_anim_select_check_player_hit		; 020D5 jnz 0x20e4
	mov	word [combat_active],0x2		; 020D7
	db	0x33, 0xC0		; 020DD xor ax,ax
	add	sp,0x4			; 020DF
	pop	bp			; 020E2
	ret				; 020E3
player_anim_select_check_player_hit:
	cmp	word [player_was_hit],0x1		; 020E4
	jnz	short player_anim_select_check_combat_counter_a		; 020E9 jnz 0x2112
	mov	word [player_was_hit],0x0		; 020EB
	sub	word [player_x],0x8	; 020F1
	mov	ax,[player_anim_id]		; 020F6
	db	0x3D, 0x04, 0x00	; 020F9 cmp ax,0x4
	jng	short player_anim_select_hit_return_idle		; 020FC jng 0x210b
	db	0x3D, 0x08, 0x00	; 020FE cmp ax,0x8
	jnl	short player_anim_select_hit_return_idle		; 02101 jnl 0x210b
	mov	ax,0x1b			; 02103
	add	sp,0x4			; 02106
	pop	bp			; 02109
	ret				; 0210A
player_anim_select_hit_return_idle:
	db	0x33, 0xC0		; 0210B xor ax,ax
	add	sp,0x4			; 0210D
	pop	bp			; 02110
	ret				; 02111
player_anim_select_check_combat_counter_a:
	cmp	word [combat_counter_a],0x1	; 02112
	jnz	short player_anim_select_check_phase_and_flag_174		; 02117 jnz 0x2130
	mov	word [combat_counter_a],0x0	; 02119
	mov	ax,0x1			; 0211F
	push	ax			; 02122
	call	rand_range		; 02123
	db	0x8B, 0xE5		; 02126 mov sp,bp
	db	0x05, 0x11, 0x00	; 02128 add ax,0x11
	add	sp,0x4			; 0212B
	pop	bp			; 0212E
	ret				; 0212F
player_anim_select_check_phase_and_flag_174:
	cmp	word [combat_phase],0x0		; 02130
	jng	short player_anim_select_dispatch_by_anim		; 02135 jng 0x2145
	cmp	word [player_flag_174],0x1	; 02137
	jnz	short player_anim_select_dispatch_by_anim		; 0213C jnz 0x2145
	db	0x33, 0xC0		; 0213E xor ax,ax
	add	sp,0x4			; 02140
	pop	bp			; 02143
	ret				; 02144
player_anim_select_dispatch_by_anim:
	mov	ax,[player_anim_id]		; 02145
	jmp	0x248b			; 02148
; Jump table case, player_anim_id 0x01 and 0x08: return read_player_input, or 0 when it returns -1.
player_anim_select_input_default_0:
	call	read_player_input	; 0214B
	mov	[bp+0x2],ax		; 0214E
	inc	ax			; 02151
	jnz	short player_anim_select_return_input_or_0		; 02152 jnz 0x2159
	mov	word [bp+0x2],0x0	; 02154
player_anim_select_return_input_or_0:
	mov	ax,[bp+0x2]		; 02159
	add	sp,0x4			; 0215C
	pop	bp			; 0215F
	ret				; 02160
; Jump table case, player_anim_id 0x02-0x04: return input + 0x22, or 0x29 when input is -1.
player_anim_select_input_plus_22:
	call	read_player_input	; 02161
	mov	[bp+0x2],ax		; 02164
	inc	ax			; 02167
	jnz	short player_anim_select_add_22_to_input		; 02168 jnz 0x2171
	mov	word [bp+0x2],0x29	; 0216A
	jmp	short player_anim_select_return_plus_22_result		; 0216F jmp 0x2175
player_anim_select_add_22_to_input:
	add	word [bp+0x2],0x22	; 02171
player_anim_select_return_plus_22_result:
	mov	ax,[bp+0x2]		; 02175
	add	sp,0x4			; 02178
	pop	bp			; 0217B
	ret				; 0217C
; Jump table case, player_anim_id 0x2A-0x2C: return input + 0x25, or 0x29 when input is -1.
player_anim_select_input_plus_25:
	call	read_player_input	; 0217D
	mov	[bp+0x2],ax		; 02180
	inc	ax			; 02183
	jnz	short player_anim_select_add_25_to_input		; 02184 jnz 0x218d
	mov	word [bp+0x2],0x29	; 02186
	jmp	short player_anim_select_return_plus_25_result		; 0218B jmp 0x2191
player_anim_select_add_25_to_input:
	add	word [bp+0x2],0x25	; 0218D
player_anim_select_return_plus_25_result:
	mov	ax,[bp+0x2]		; 02191
	add	sp,0x4			; 02194
	pop	bp			; 02197
	ret				; 02198
; Jump table case, player_anim_id 0x05-0x07: counts inputs 0x18-0x1A in [0x15A]; the third in a row, or input -1, returns 0x1B.
player_anim_select_input_limit_repeats:
	call	read_player_input	; 02199
	db	0x3D, 0x17, 0x00	; 0219C cmp ax,0x17
	mov	[bp+0x2],ax		; 0219F
	jng	short player_anim_select_reset_repeat_count		; 021A2 jng 0x21c2
	db	0x3D, 0x1B, 0x00	; 021A4 cmp ax,0x1b
	jnl	short player_anim_select_reset_repeat_count		; 021A7 jnl 0x21c2
	mov	ax,[player_input_repeat_count]		; 021A9
	inc	ax			; 021AC
	db	0x3D, 0x03, 0x00	; 021AD cmp ax,0x3
	mov	[player_input_repeat_count],ax		; 021B0
	jnz	short player_anim_select_map_no_input_to_recoil		; 021B3 jnz 0x21c8
	mov	word [player_input_repeat_count],0x0	; 021B5
	mov	word [bp+0x2],0xffff	; 021BB
	jmp	short player_anim_select_map_no_input_to_recoil		; 021C0 jmp 0x21c8
player_anim_select_reset_repeat_count:
	mov	word [player_input_repeat_count],0x0	; 021C2
player_anim_select_map_no_input_to_recoil:
	cmp	word [bp+0x2],0xffffffffffffffff	; 021C8
	jnz	short player_anim_select_return_limited_input		; 021CC jnz 0x21d3
	mov	word [bp+0x2],0x1b	; 021CE
player_anim_select_return_limited_input:
	mov	ax,[bp+0x2]		; 021D3
	add	sp,0x4			; 021D6
	pop	bp			; 021D9
	ret				; 021DA
; Jump table case, player_anim_id 0x0A-0x0B: return input 0x0C only from anim 0x0A, 0x0D only from anim 0x0B, else 0.
player_anim_select_input_chain:
	call	read_player_input	; 021DB
	db	0x3D, 0x0C, 0x00	; 021DE cmp ax,0xc
	mov	[bp+0x2],ax		; 021E1
	jnz	short player_anim_select_check_chain_from_anim_b		; 021E4 jnz 0x21f5
	cmp	word [player_anim_id],0xa	; 021E6
	jnz	short player_anim_select_check_chain_from_anim_b		; 021EB jnz 0x21f5
	mov	ax,0xc			; 021ED
	add	sp,0x4			; 021F0
	pop	bp			; 021F3
	ret				; 021F4
player_anim_select_check_chain_from_anim_b:
	cmp	word [bp+0x2],0xd	; 021F5
	jnz	short player_anim_select_chain_return_idle		; 021F9 jnz 0x220a
	cmp	word [player_anim_id],0xb	; 021FB
	jnz	short player_anim_select_chain_return_idle		; 02200 jnz 0x220a
	mov	ax,0xd			; 02202
	add	sp,0x4			; 02205
	pop	bp			; 02208
	ret				; 02209
player_anim_select_chain_return_idle:
	db	0x33, 0xC0		; 0220A xor ax,ax
	add	sp,0x4			; 0220C
	pop	bp			; 0220F
	ret				; 02210
; Jump table case, player_anim_id 0x0F: return 0 without reading input.
player_anim_select_return_0:
	db	0x33, 0xC0		; 02211 xor ax,ax
	add	sp,0x4			; 02213
	pop	bp			; 02216
	ret				; 02217
; Jump table case, player_anim_id 0x41-0x42: return read_player_input, or 0x13 when it returns -1.
player_anim_select_input_default_13:
	call	read_player_input	; 02218
	mov	[bp+0x2],ax		; 0221B
	inc	ax			; 0221E
	jnz	short player_anim_select_return_input_or_13		; 0221F jnz 0x2229
	mov	ax,0x13			; 02221
	add	sp,0x4			; 02224
	pop	bp			; 02227
	ret				; 02228
player_anim_select_return_input_or_13:
	mov	ax,[bp+0x2]		; 02229
	add	sp,0x4			; 0222C
	pop	bp			; 0222F
	ret				; 02230
; Jump table case, player_anim_id 0x46: return read_player_input, or 0x0F when it returns -1.
player_anim_select_input_default_f:
	call	read_player_input	; 02231
	mov	[bp+0x2],ax		; 02234
	inc	ax			; 02237
	jnz	short player_anim_select_return_input_or_f		; 02238 jnz 0x223f
	mov	word [bp+0x2],0xf	; 0223A
player_anim_select_return_input_or_f:
	mov	ax,[bp+0x2]		; 0223F
	add	sp,0x4			; 02242
	pop	bp			; 02245
	ret				; 02246
; Data, not code: 17 {player_anim_id, handler} word pairs, scanned last to first by the dispatch at 0228B.
; An animation with no entry returns with AX still holding player_anim_id.
player_anim_select_jump_table:
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
player_anim_select_scan_jump_table:
	cmp	ax,[cs:si+0x2247]	; 0228E
	jnz	short player_anim_select_scan_prev_entry		; 02293 jnz 0x229a
	jmp	word near [cs:si+0x2249]	; 02295
player_anim_select_scan_prev_entry:
	sub	si,0x4			; 0229A
	jns	short player_anim_select_scan_jump_table		; 0229D jns 0x228e
	add	sp,0x4			; 0229F
	pop	bp			; 022A2
	ret				; 022A3

; ---- function memcpy_block ----
; Copies a block of bytes from source to destination using REP MOVSB.
;
; Input:
;   [bp+4] = dest pointer
;   [bp+6] = source pointer
;   [bp+8] = end pointer (copy count = end - source)
; Output: none
memcpy_block:
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

; ---- function copy_sprite_frame ----
; Copies sprite frame data (two 4-byte sub-blocks) from source to dest,
; and adds an X offset to the position words.
;
; Input:
;   [bp+4] = dest pointer
;   [bp+6] = source pointer
;   [bp+8] = X offset to add to position words
; Copies src[1..4] -> dst[0..3] (first sub-block)
; Copies src[6..9] -> dst[4..7] (second sub-block)
; Adds X offset to dst[1] (word) and dst[5] (word)
; Output: none
copy_sprite_frame:
	push	bp			; 022BC
	db	0x8B, 0xEC		; 022BD mov bp,sp
	mov	di,[bp+0x4]		; 022BF
	mov	si,[bp+0x6]		; 022C2
	mov	bx,0x3			; 022C5
copy_sprite_frame_copy_loop:
	mov	al,[bx+si+0x1]		; 022C8
	mov	[bx+di],al		; 022CB
	mov	al,[bx+si+0x6]		; 022CD
	mov	[bx+di+0x4],al		; 022D0
	dec	bx			; 022D3
	jnl	short copy_sprite_frame_copy_loop		; 022D4 jnl 0x22c8
	mov	ax,[bp+0x8]		; 022D6
	add	[di+0x1],ax		; 022D9
	add	[di+0x5],ax		; 022DC
	pop	bp			; 022DF
	ret				; 022E0
