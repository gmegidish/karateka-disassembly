; Animation data management: enemy offset table, player data loading, data compaction


; ---- function build_enemy_anim_offsets ----
; Builds the frame offset lookup table for enemy animations.
; Calls build_anim_offsets with enemy animation data base (0xCE3E)
; and offset table (0xCDEA).
;
; Input: none
; Output: populates enemy animation offset table
build_enemy_anim_offsets:
	lea	bx,[enemy_anim_frames]		; 019A2
	lea	di,[enemy_seq_offsets]		; 019A6
	call	build_anim_offsets	; 019AA
	ret				; 019AD

; ---- function load_player_anim_data ----
; Loads the player's animation script data and builds offset tables.
; Calls load_anim_script(0xD59C, 0xC428) to load player animation script,
; then build_anim_offsets_alt to build player animation offset tables.
; Resets several flags ([0x172], [0x160]-[0x164], [0x15E]) to 0.
; Finally calls load_sprite_set(5) to load animation graphics set 5.
;
; Input: none
; Output: player animation data loaded and indexed
load_player_anim_data:
	push	bp			; 019AE
	sub	sp,0x4			; 019AF
	jc	short load_player_anim_data_stack_overflow		; 019B2 jc 0x19ba
	cmp	sp,[stack_limit]		; 019B4
	ja	short load_player_anim_data_stack_ok		; 019B8 ja 0x19bd
load_player_anim_data_stack_overflow:
	jmp	near stack_overflow_handler			; 019BA
load_player_anim_data_stack_ok:
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
	mov	[player_flag_172],ax		; 019D5
	mov	[sprite_image_load_offset],ax		; 019D8
	mov	[unk_load_player_anim_data_word_b],ax		; 019DB
	mov	[sprite_mask_load_offset],ax		; 019DE
	mov	[unk_load_player_anim_data_word_a],ax		; 019E1
	call	load_sprite_set		; 019E4
	db	0x8B, 0xE5		; 019E7 mov sp,bp
	add	sp,0x4			; 019E9
	pop	bp			; 019EC
	ret				; 019ED

; ---- function compact_anim_data ----
; Compacts/reorganizes animation data by scanning animation bytecode records.
; Processes 5-byte entries terminated by 0xFF, with 0x12 as a special sync marker.
; Rebuilds animation parameter lookup tables.
;
; Input: [bp+0x10] = number of entries to process
; Processes entries from buffer at [si-0x3EFE], building tables at:
;   [-0x3C58] = start offsets
;   [-0x3C4A] = sync point offsets
;   [-0x3C3C] = end offsets
; Final block restores animation parameters from backup tables:
;   [0xC3A8/C3B6/C3C4] -> [0xC3A0/C3A2/C3A4]
; Rewrites the buffer at 0xC102 in place: each 5-byte record keeps bytes 1-4 and drops byte 0; a 0x12 is a one-byte sync prefix.
; The tables at 0xC3A8/0xC3B6/0xC3C4 hold absolute pointers per sequence; the final block copies sequence 0's pointers to 0xC3A0/0xC3A2/0xC3A4.
compact_anim_data:
	push	bp			; 019EE
	sub	sp,0xc			; 019EF
	jc	short compact_anim_data_stack_overflow		; 019F2 jc 0x19fa
	cmp	sp,[stack_limit]		; 019F4
	ja	short compact_anim_data_stack_ok		; 019F8 ja 0x19fd
compact_anim_data_stack_overflow:
	jmp	near stack_overflow_handler			; 019FA
compact_anim_data_stack_ok:
	db	0x8B, 0xEC		; 019FD mov bp,sp
	db	0x33, 0xC0		; 019FF xor ax,ax
	mov	[bp+0xa],ax		; 01A01
	mov	[bp+0x4],ax		; 01A04
	mov	[bp+0x6],ax		; 01A07
; loop over sequences; exits when index reaches [bp+0x10]
compact_anim_data_sequence_loop:
	mov	ax,[bp+0xa]		; 01A0A
	mov	bx,[bp+0x10]		; 01A0D
	db	0x3B, 0xD8		; 01A10 cmp bx,ax
	jg	short compact_anim_data_begin_sequence		; 01A12 jg 0x1a17
	jmp	near compact_anim_data_publish_first_row_pointers			; 01A14
compact_anim_data_begin_sequence:
	shl	ax,1			; 01A17
	db	0x8B, 0xF0		; 01A19 mov si,ax
	mov	ax,[bp+0x6]		; 01A1B
	add	ax,0xc102		; 01A1E
	mov	[si+scenery_row_starts],ax		; 01A21
compact_anim_data_record_loop:
	mov	si,[bp+0x4]		; 01A25
	mov	al,[si+scenery_figures]		; 01A28
	xor	ah,ah			; 01A2C
	cmp	ax,0xff			; 01A2E
	jz	short compact_anim_data_sequence_end		; 01A31 jz 0x1a8d
	mov	al,[si+scenery_figures]		; 01A33
	xor	ah,ah			; 01A37
	db	0x3D, 0x12, 0x00	; 01A39 cmp ax,0x12
	jnz	short compact_anim_data_recheck_terminator		; 01A3C jnz 0x1a52
	mov	ax,[bp+0xa]		; 01A3E
	shl	ax,1			; 01A41
	db	0x8B, 0xF8		; 01A43 mov di,ax
	mov	ax,[bp+0x6]		; 01A45
	add	ax,0xc102		; 01A48
	mov	[di+scenery_row_middles],ax		; 01A4B
	inc	word [bp+0x4]		; 01A4F
compact_anim_data_recheck_terminator:
	mov	si,[bp+0x4]		; 01A52
	mov	al,[si+scenery_figures]		; 01A55
	xor	ah,ah			; 01A59
	cmp	ax,0xff			; 01A5B
	jz	short compact_anim_data_sequence_end		; 01A5E jz 0x1a8d
	mov	word [bp+0x8],0x1	; 01A60
compact_anim_data_copy_bytes_loop:
	mov	ax,[bp+0x8]		; 01A65
	db	0x3D, 0x05, 0x00	; 01A68 cmp ax,0x5
	jnl	short compact_anim_data_next_record		; 01A6B jnl 0x1a87
	mov	bx,[bp+0x6]		; 01A6D
	inc	word [bp+0x6]		; 01A70
	mov	cx,[bp+0x4]		; 01A73
	db	0x03, 0xC8		; 01A76 add cx,ax
	db	0x8B, 0xF1		; 01A78 mov si,cx
	mov	al,[si+scenery_figures]		; 01A7A
	mov	[bx+scenery_figures],al		; 01A7E
	inc	word [bp+0x8]		; 01A82
	jmp	short compact_anim_data_copy_bytes_loop		; 01A85 jmp 0x1a65
compact_anim_data_next_record:
	add	word [bp+0x4],0x5	; 01A87
	jmp	short compact_anim_data_record_loop		; 01A8B jmp 0x1a25
compact_anim_data_sequence_end:
	mov	ax,[bp+0xa]		; 01A8D
	shl	ax,1			; 01A90
	db	0x8B, 0xF0		; 01A92 mov si,ax
	mov	ax,[bp+0x6]		; 01A94
	add	ax,0xc102		; 01A97
	mov	[si+scenery_row_ends],ax		; 01A9A
	inc	word [bp+0x4]		; 01A9E
	inc	word [bp+0xa]		; 01AA1
	jmp	near compact_anim_data_sequence_loop			; 01AA4
; all sequences done: copies row 0 start/middle/end pointers to globals and returns
compact_anim_data_publish_first_row_pointers:
	mov	ax,[scenery_row_starts]		; 01AA7
	mov	bx,[scenery_row_middles]		; 01AAA
	mov	cx,[scenery_row_ends]		; 01AAE
	mov	[scenery_row_start_ptr],ax		; 01AB2
	mov	[scenery_row_end_ptr],cx		; 01AB5
	mov	[scenery_row_mid_ptr],bx		; 01AB9
	add	sp,0xc			; 01ABD
	pop	bp			; 01AC0
	ret				; 01AC1
