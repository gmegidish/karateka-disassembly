; Sprite rendering: draws sprites to offscreen buffer at DS:0x337
; (CGA 320x200, 80 bytes per scanline)
;
; Three entry points handle different clipping cases:
;   draw_sprite_flipped          — normal case + right-edge clipping
;   draw_sprite_unflipped — left-edge entry (sprite X < camera)
;   draw_sprite_unflipped_columns — right-edge clipping (sprite X + width > 320)


; ---- function draw_sprite_flipped ----
; Draws a sprite horizontally flipped into the offscreen buffer at DS:0x337.
; Called only by render_figures, for a figure whose X has bit 15 clear and bit 14 set.
;
; Parameters:
;   [bp+0x4] = sprite index (word)
;   [bp+0x6] = world X (word); camera_x is subtracted
;   [bp+0x8] = Y of the line below the sprite; the row count is subtracted
;
; 1. Image and mask stream offsets come from sprite_image_offsets and sprite_mask_offsets. Image byte 0 is the column count (4 pixels each), byte 1 the row count; pixel data starts at +3 in both streams.
; 2. If the sprite crosses the right edge: exit when X >= 320, otherwise consume the columns past the edge and, at a sub-pixel X, draw the partial column in byte column 79.
; 3. Exit when X + width < 0. Note a partial left column when X < 0.
; 4. Walk columns from right to left. For each row next_sprite_bytes returns AL = mask, DL = image; mask 0 skips the byte, and otherwise the 8 bits of both are reversed before masking, rotating by sprite_bit_shift and ORing in.
; 5. Draw the partial left column, if any.
draw_sprite_flipped:
	push	bp			; 00640
	db	0x8B, 0xEC		; 00641 mov bp,sp
	mov	byte [sprite_image_run_left],0x0	; 00643
	mov	byte [sprite_mask_run_left],0x0	; 00648
	mov	si,[bp+0x4]		; 0064D
	shl	si,1			; 00650
	mov	bx,[si+sprite_image_offsets]		; 00652
	mov	[sprite_image_pos],bx		; 00656
	mov	ax,[si+sprite_mask_offsets]		; 0065A
	mov	[sprite_mask_pos],ax		; 0065E
	mov	al,[bx+sprite_image_bank]		; 00661
	mov	[sprite_columns_left],al		; 00665
	cbw				; 00668
	shl	ax,1			; 00669
	shl	ax,1			; 0066B
	mov	[sprite_visible_width],ax		; 0066D
	mov	al,[bx+sprite_image_bank_byte1]		; 00670
	mov	[sprite_rows],al		; 00674
	cbw				; 00677
	sub	[bp+0x8],ax		; 00678
	mov	ax,[bp+0x8]		; 0067B
	mul	byte [sprite_line_stride]		; 0067E
	mov	[sprite_top_line_offset],ax		; 00682
	add	word [sprite_image_pos],0x3	; 00685
	add	word [sprite_mask_pos],0x3	; 0068A
	mov	ax,[bp+0x6]		; 0068F
	sub	ax,[camera_x]		; 00692
	mov	[bp+0x6],ax		; 00696
	db	0x8B, 0xD8		; 00699 mov bx,ax
	and	al,0x3			; 0069B
	mov	[sprite_subpixel_x],al		; 0069D
	shl	al,1			; 006A0
	mov	[sprite_bit_shift],al		; 006A2
	sub	bx,0x140		; 006A5
	add	bx,[sprite_visible_width]		; 006A9
	jnl	short draw_sprite_flipped_crosses_right_edge		; 006AD jnl 0x6b2
	jmp	short draw_sprite_flipped_check_off_left_edge		; 006AF jmp 0x72d
	nop				; 006B1
draw_sprite_flipped_crosses_right_edge:
	cmp	word [bp+0x6],0x140	; 006B2
	jl	short draw_sprite_flipped_skip_offscreen_columns		; 006B7 jl 0x6bc
	jmp	near draw_sprite_flipped_exit			; 006B9
draw_sprite_flipped_skip_offscreen_columns:
	shr	bx,1			; 006BC
	shr	bx,1			; 006BE
	jz	short draw_sprite_flipped_check_right_partial_column		; 006C0 jz 0x6d5
draw_sprite_flipped_skip_column_loop:
	mov	al,[sprite_rows]		; 006C2
	cbw				; 006C5
	db	0x8B, 0xF8		; 006C6 mov di,ax
draw_sprite_flipped_skip_column_bytes_loop:
	call	next_sprite_bytes	; 006C8
	dec	di			; 006CB
	jnz	short draw_sprite_flipped_skip_column_bytes_loop		; 006CC jnz 0x6c8
	dec	byte [sprite_columns_left]		; 006CE
	dec	bx			; 006D2
	jnz	short draw_sprite_flipped_skip_column_loop		; 006D3 jnz 0x6c2
draw_sprite_flipped_check_right_partial_column:
	cmp	byte [sprite_subpixel_x],0x0	; 006D5
	jz	short draw_sprite_flipped_check_off_left_edge		; 006DA jz 0x72d
	mov	al,[sprite_rows]		; 006DC
	mov	[sprite_rows_left],al		; 006DF
	mov	di,[sprite_top_line_offset]		; 006E2
	add	di,0x4f			; 006E6
draw_sprite_flipped_right_partial_row_loop:
	call	next_sprite_bytes	; 006E9
	cmp	al,0x0			; 006EC
	jz	short draw_sprite_flipped_right_partial_next_row		; 006EE jz 0x71b
	mov	cx,0x8			; 006F0
; reverses the 8 bits of AL and DL into AH and DH
draw_sprite_flipped_right_partial_reverse_bits_loop:
	shr	al,1			; 006F3
	rcl	ah,1			; 006F5
	shr	dl,1			; 006F7
	rcl	dh,1			; 006F9
	loop	0x6f3			; 006FB
	xchg	al,ah			; 006FD
	db	0x8A, 0xD6		; 006FF mov dl,dh
	not	ax			; 00701
	mov	cl,[sprite_bit_shift]		; 00703
	ror	ax,cl			; 00707
	and	al,[di+offscreen_buffer]		; 00709
	mov	cl,[sprite_bit_shift]		; 0070D
	mov	dh,0x0			; 00711
	ror	dx,cl			; 00713
	db	0x0A, 0xC2		; 00715 or al,dl
	mov	[di+offscreen_buffer],al		; 00717
draw_sprite_flipped_right_partial_next_row:
	add	di,0x50			; 0071B
	dec	byte [sprite_rows_left]		; 0071E
	jnz	short draw_sprite_flipped_right_partial_row_loop		; 00722 jnz 0x6e9
	dec	byte [sprite_columns_left]		; 00724
	jnz	short draw_sprite_flipped_check_off_left_edge		; 00728 jnz 0x72d
	jmp	near draw_sprite_flipped_exit			; 0072A
draw_sprite_flipped_check_off_left_edge:
	mov	ax,[bp+0x6]		; 0072D
	add	ax,[sprite_visible_width]		; 00730
	jnl	short draw_sprite_flipped_set_left_clip_flag		; 00734 jnl 0x739
	jmp	near draw_sprite_flipped_exit			; 00736
draw_sprite_flipped_set_left_clip_flag:
	mov	word [sprite_partial_edge_column],0x0	; 00739
	cmp	word [bp+0x6],0x0	; 0073F
	jnl	short draw_sprite_flipped_clamp_left_x		; 00743 jnl 0x74b
	mov	word [sprite_partial_edge_column],0x1	; 00745
draw_sprite_flipped_clamp_left_x:
	mov	ax,[bp+0x6]		; 0074B
	db	0x3D, 0x00, 0x00	; 0074E cmp ax,0x0
	jnl	short draw_sprite_flipped_clamp_right_x		; 00751 jnl 0x755
	db	0x33, 0xC0		; 00753 xor ax,ax
draw_sprite_flipped_clamp_right_x:
	mov	dx,[bp+0x6]		; 00755
	add	dx,[sprite_visible_width]		; 00758
	cmp	dx,0x140		; 0075C
	jl	short draw_sprite_flipped_compute_column_span		; 00760 jl 0x76d
	mov	dx,0x140		; 00762
	mov	bh,0x0			; 00765
	mov	bl,[sprite_subpixel_x]		; 00767
	db	0x2B, 0xD3		; 0076B sub dx,bx
draw_sprite_flipped_compute_column_span:
	shr	ax,1			; 0076D
	shr	ax,1			; 0076F
	shr	dx,1			; 00771
	shr	dx,1			; 00773
	mov	[sprite_column_offset_rtl],dx		; 00775
	db	0x2B, 0xD0		; 00779 sub dx,ax
	db	0x8A, 0xDA		; 0077B mov bl,dl
	jng	short draw_sprite_flipped_check_left_partial_column		; 0077D jng 0x7ec
	mov	ax,[sprite_top_line_offset]		; 0077F
	add	[sprite_column_offset_rtl],ax		; 00782
	dec	word [sprite_column_offset_rtl]		; 00786
draw_sprite_flipped_column_loop:
	mov	al,[sprite_rows]		; 0078A
	mov	[sprite_rows_left],al		; 0078D
	mov	di,[sprite_column_offset_rtl]		; 00790
draw_sprite_flipped_row_loop:
	call	next_sprite_bytes	; 00794
	cmp	al,0x0			; 00797
	jz	short draw_sprite_flipped_next_row		; 00799 jz 0x7db
	mov	cx,0x8			; 0079B
; reverses the 8 bits of AL and DL into AH and DH
draw_sprite_flipped_reverse_bits_loop:
	shr	al,1			; 0079E
	rcl	ah,1			; 007A0
	shr	dl,1			; 007A2
	rcl	dh,1			; 007A4
	loop	0x79e			; 007A6
	xchg	al,ah			; 007A8
	db	0x8A, 0xD6		; 007AA mov dl,dh
	cmp	byte [sprite_subpixel_x],0x0	; 007AC
	jz	short draw_sprite_flipped_write_aligned_byte		; 007B1 jz 0x7cf
	not	ax			; 007B3
	mov	cl,[sprite_bit_shift]		; 007B5
	ror	ax,cl			; 007B9
	and	ax,[di+offscreen_buffer]		; 007BB
	mov	cl,[sprite_bit_shift]		; 007BF
	mov	dh,0x0			; 007C3
	ror	dx,cl			; 007C5
	db	0x0B, 0xC2		; 007C7 or ax,dx
	mov	[di+offscreen_buffer],ax		; 007C9
	jmp	short draw_sprite_flipped_next_row		; 007CD jmp 0x7db
draw_sprite_flipped_write_aligned_byte:
	xor	al,0xff			; 007CF
	and	al,[di+offscreen_buffer]		; 007D1
	db	0x0A, 0xC2		; 007D5 or al,dl
	mov	[di+offscreen_buffer],al		; 007D7
draw_sprite_flipped_next_row:
	add	di,0x50			; 007DB
	dec	byte [sprite_rows_left]		; 007DE
	jnz	short draw_sprite_flipped_row_loop		; 007E2 jnz 0x794
	dec	word [sprite_column_offset_rtl]		; 007E4
	dec	bl			; 007E8
	jnz	short draw_sprite_flipped_column_loop		; 007EA jnz 0x78a
draw_sprite_flipped_check_left_partial_column:
	cmp	word [sprite_partial_edge_column],0x0	; 007EC
	jz	short draw_sprite_flipped_exit		; 007F1 jz 0x83a
	mov	al,[sprite_rows]		; 007F3
	mov	[sprite_rows_left],al		; 007F6
	mov	di,[sprite_top_line_offset]		; 007F9
draw_sprite_flipped_left_partial_row_loop:
	call	next_sprite_bytes	; 007FD
	cmp	al,0x0			; 00800
	jz	short draw_sprite_flipped_left_partial_next_row		; 00802 jz 0x831
	mov	cx,0x8			; 00804
; reverses the 8 bits of AL and DL into AH and DH
draw_sprite_flipped_left_partial_reverse_bits_loop:
	shr	al,1			; 00807
	rcl	ah,1			; 00809
	shr	dl,1			; 0080B
	rcl	dh,1			; 0080D
	loop	0x807			; 0080F
	db	0x8A, 0xC4		; 00811 mov al,ah
	db	0x8A, 0xD6		; 00813 mov dl,dh
	mov	ah,0x0			; 00815
	not	ax			; 00817
	mov	cl,[sprite_bit_shift]		; 00819
	ror	ax,cl			; 0081D
	and	ah,[di+offscreen_buffer]		; 0081F
	mov	cl,[sprite_bit_shift]		; 00823
	mov	dh,0x0			; 00827
	ror	dx,cl			; 00829
	db	0x0A, 0xE6		; 0082B or ah,dh
	mov	[di+offscreen_buffer],ah		; 0082D
draw_sprite_flipped_left_partial_next_row:
	add	di,0x50			; 00831
	dec	byte [sprite_rows_left]		; 00834
	jnz	short draw_sprite_flipped_left_partial_row_loop		; 00838 jnz 0x7fd
draw_sprite_flipped_exit:
	pop	bp			; 0083A
	ret				; 0083B

; ---- function draw_sprite_unflipped ----
; Draws a sprite unflipped, left to right. Despite the old name nothing is mirrored and no bits are reversed.
; Called by render_figures for every figure not sent to draw_sprite_flipped, and directly for screen elements (00F16, 00F36, 041C1).
; This part does the setup and left-edge clipping, then jumps into draw_sprite_unflipped_columns.
;
; Parameters: same as draw_sprite_flipped. A low byte of [bp+0x4] >= 0xC8 selects an opaque sprite with no mask stream.
;
; X >= 0 after subtracting camera_x: jump straight to 00957 in draw_sprite_unflipped_columns.
; X < 0: exit when X + width <= 0. Otherwise skip the columns wholly left of the screen (opaque sprites just advance sprite_image_pos), draw the partial column at a sub-pixel X, and continue at 0094C.
draw_sprite_unflipped:
	push	bp			; 0083C
	db	0x8B, 0xEC		; 0083D mov bp,sp
	mov	byte [sprite_image_run_left],0x0	; 0083F
	mov	byte [sprite_mask_run_left],0x0	; 00844
	mov	si,[bp+0x4]		; 00849
	shl	si,1			; 0084C
	mov	bx,[si+sprite_image_offsets]		; 0084E
	mov	[sprite_image_pos],bx		; 00852
	mov	ax,[si+sprite_mask_offsets]		; 00856
	mov	[sprite_mask_pos],ax		; 0085A
	mov	al,[bx+sprite_image_bank]		; 0085D
	mov	[sprite_columns_left],al		; 00861
	cbw				; 00864
	shl	ax,1			; 00865
	shl	ax,1			; 00867
	mov	[sprite_visible_width],ax		; 00869
	mov	al,[bx+sprite_image_bank_byte1]		; 0086C
	mov	[sprite_rows],al		; 00870
	cbw				; 00873
	sub	[bp+0x8],ax		; 00874
	mov	ax,[bp+0x8]		; 00877
	mul	byte [sprite_line_stride]		; 0087A
	mov	[sprite_top_line_offset],ax		; 0087E
	add	word [sprite_image_pos],0x3	; 00881
	add	word [sprite_mask_pos],0x3	; 00886
	mov	ax,[bp+0x6]		; 0088B
	sub	ax,[camera_x]		; 0088E
	mov	[bp+0x6],ax		; 00892
	jl	short draw_sprite_unflipped_left_of_screen		; 00895 jl 0x89a
	jmp	near draw_sprite_unflipped_columns_compute_subpixel			; 00897
draw_sprite_unflipped_left_of_screen:
	db	0x8B, 0xD8		; 0089A mov bx,ax
	add	bx,[sprite_visible_width]		; 0089C
	jg	short draw_sprite_unflipped_clip_left_columns		; 008A0 jg 0x8a5
	jmp	near draw_sprite_unflipped_columns_exit			; 008A2
draw_sprite_unflipped_clip_left_columns:
	db	0x33, 0xDB		; 008A5 xor bx,bx
	db	0x2B, 0xD8		; 008A7 sub bx,ax
	db	0x8A, 0xC3		; 008A9 mov al,bl
	and	al,0x3			; 008AB
	mov	ah,0x4			; 008AD
	db	0x2A, 0xE0		; 008AF sub ah,al
	and	ah,0x3			; 008B1
	mov	[sprite_subpixel_x],ah		; 008B4
	shl	ah,1			; 008B8
	mov	[sprite_bit_shift],ah		; 008BA
	shr	bx,1			; 008BE
	shr	bx,1			; 008C0
	jz	short draw_sprite_unflipped_check_left_partial_column		; 008C2 jz 0x8f7
	cmp	byte [bp+0x4],0xc8	; 008C4
	jc	short draw_sprite_unflipped_skip_column_loop		; 008C8 jc 0x8e0
	mov	al,[sprite_rows]		; 008CA
	mul	bl			; 008CD
	add	[sprite_image_pos],ax		; 008CF
	sub	[sprite_columns_left],bl		; 008D3
	shl	bx,1			; 008D7
	shl	bx,1			; 008D9
	add	[bp+0x6],bx		; 008DB
	jmp	short draw_sprite_unflipped_check_left_partial_column		; 008DE jmp 0x8f7
draw_sprite_unflipped_skip_column_loop:
	mov	al,[sprite_rows]		; 008E0
	cbw				; 008E3
	db	0x8B, 0xF8		; 008E4 mov di,ax
draw_sprite_unflipped_skip_column_bytes_loop:
	call	next_sprite_bytes	; 008E6
	dec	di			; 008E9
	jnz	short draw_sprite_unflipped_skip_column_bytes_loop		; 008EA jnz 0x8e6
	add	word [bp+0x6],0x4	; 008EC
	dec	byte [sprite_columns_left]		; 008F0
	dec	bx			; 008F4
	jnz	short draw_sprite_unflipped_skip_column_loop		; 008F5 jnz 0x8e0
draw_sprite_unflipped_check_left_partial_column:
	cmp	byte [sprite_subpixel_x],0x0	; 008F7
	jz	short draw_sprite_unflipped_columns_recompute_clip		; 008FC jz 0x94c
	mov	al,[sprite_rows]		; 008FE
	mov	[sprite_rows_left],al		; 00901
	mov	di,[sprite_top_line_offset]		; 00904
	cmp	byte [bp+0x4],0xc8	; 00908
	jc	short draw_sprite_unflipped_left_partial_row_loop		; 0090C jc 0x911
	jmp	near draw_sprite_unflipped_columns_opaque_left_partial			; 0090E
draw_sprite_unflipped_left_partial_row_loop:
	call	next_sprite_bytes	; 00911
	cmp	al,0x0			; 00914
	jz	short draw_sprite_unflipped_left_partial_next_row		; 00916 jz 0x936
	mov	ah,0x0			; 00918
	db	0x23, 0xD0		; 0091A and dx,ax
	not	ax			; 0091C
	mov	cl,[sprite_bit_shift]		; 0091E
	ror	ax,cl			; 00922
	and	ah,[di+offscreen_buffer]		; 00924
	mov	cl,[sprite_bit_shift]		; 00928
	mov	dh,0x0			; 0092C
	ror	dx,cl			; 0092E
	db	0x0A, 0xE6		; 00930 or ah,dh
	mov	[di+offscreen_buffer],ah		; 00932
draw_sprite_unflipped_left_partial_next_row:
	add	di,0x50			; 00936
	dec	byte [sprite_rows_left]		; 00939
	jnz	short draw_sprite_unflipped_left_partial_row_loop		; 0093D jnz 0x911
; advance X by 4 and drop a column; also reached from the opaque left-partial path
draw_sprite_unflipped_left_partial_column_done:
	add	word [bp+0x6],0x4	; 0093F
	dec	byte [sprite_columns_left]		; 00943
	jnz	short draw_sprite_unflipped_columns_recompute_clip		; 00947 jnz 0x94c
	jmp	near draw_sprite_unflipped_columns_exit			; 00949

; ---- function draw_sprite_unflipped_columns ----
; The column loop of draw_sprite_unflipped: draws unflipped columns left to right using its stack frame.
; Reached only by jumps from draw_sprite_unflipped (008FC and 00947 to 0094C, 00897 to 00957), never from draw_sprite_flipped and never by fall-through. It handles every on-screen sprite on this path, not only right-edge cases.
;
; Exits when X > 320. When the sprite crosses the right edge it clamps the width and, at a sub-pixel X, draws a partial last column in byte column 79.
; Sprites with a low index byte < 0xC8 use next_sprite_bytes (AL = mask, DL = image; mask 0 skips the byte).
; Sprites >= 0xC8 use the opaque paths at the end of this function: raw bytes from sprite_image_bank, with no mask stream.
draw_sprite_unflipped_columns:
draw_sprite_unflipped_columns_recompute_clip:
	mov	al,[sprite_columns_left]		; 0094C
	cbw				; 0094F
	shl	ax,1			; 00950
	shl	ax,1			; 00952
	mov	[sprite_visible_width],ax		; 00954
; entered from draw_sprite_unflipped when X >= 0
draw_sprite_unflipped_columns_compute_subpixel:
	mov	ax,[bp+0x6]		; 00957
	and	al,0x3			; 0095A
	mov	[sprite_subpixel_x],al		; 0095C
	shl	al,1			; 0095F
	mov	[sprite_bit_shift],al		; 00961
	mov	ax,[bp+0x6]		; 00964
	sub	ax,0x140		; 00967
	jng	short draw_sprite_unflipped_columns_check_right_overhang		; 0096A jng 0x96f
	jmp	near draw_sprite_unflipped_columns_exit			; 0096C
draw_sprite_unflipped_columns_check_right_overhang:
	mov	word [sprite_partial_edge_column],0x0	; 0096F
	add	ax,[sprite_visible_width]		; 00975
	jng	short draw_sprite_unflipped_columns_compute_columns		; 00979 jng 0x995
	cmp	byte [sprite_subpixel_x],0x0	; 0097B
	jz	short draw_sprite_unflipped_columns_clamp_width		; 00980 jz 0x988
	mov	word [sprite_partial_edge_column],0x1	; 00982
draw_sprite_unflipped_columns_clamp_width:
	mov	al,[sprite_subpixel_x]		; 00988
	cbw				; 0098B
	add	ax,0x140		; 0098C
	sub	ax,[bp+0x6]		; 0098F
	mov	[sprite_visible_width],ax		; 00992
draw_sprite_unflipped_columns_compute_columns:
	mov	ax,[bp+0x6]		; 00995
	db	0x8B, 0xD0		; 00998 mov dx,ax
	add	ax,[sprite_visible_width]		; 0099A
	shr	ax,1			; 0099E
	shr	ax,1			; 009A0
	shr	dx,1			; 009A2
	shr	dx,1			; 009A4
	db	0x2B, 0xC2		; 009A6 sub ax,dx
	sub	ax,[sprite_partial_edge_column]		; 009A8
	db	0x8A, 0xE8		; 009AC mov ch,al
	jz	short draw_sprite_unflipped_columns_check_right_partial_column		; 009AE jz 0xa1e
	mov	di,[sprite_top_line_offset]		; 009B0
	mov	dx,[bp+0x6]		; 009B4
	shr	dx,1			; 009B7
	shr	dx,1			; 009B9
	db	0x03, 0xFA		; 009BB add di,dx
	mov	[sprite_column_offset],di		; 009BD
	cmp	byte [bp+0x4],0xc8	; 009C1
	jc	short draw_sprite_unflipped_columns_column_loop		; 009C5 jc 0x9ca
	jmp	near draw_sprite_unflipped_columns_opaque_columns			; 009C7
draw_sprite_unflipped_columns_column_loop:
	mov	al,[sprite_rows]		; 009CA
	db	0x8A, 0xD8		; 009CD mov bl,al
	mov	di,[sprite_column_offset]		; 009CF
draw_sprite_unflipped_columns_row_loop:
	call	next_sprite_bytes	; 009D3
	cmp	al,0x0			; 009D6
	jz	short draw_sprite_unflipped_columns_next_row		; 009D8 jz 0xa0b
	cmp	byte [sprite_subpixel_x],0x0	; 009DA
	jz	short draw_sprite_unflipped_columns_write_aligned_byte		; 009DF jz 0x9ff
	mov	ah,0x0			; 009E1
	not	ax			; 009E3
	mov	cl,[sprite_bit_shift]		; 009E5
	ror	ax,cl			; 009E9
	and	ax,[di+offscreen_buffer]		; 009EB
	mov	cl,[sprite_bit_shift]		; 009EF
	mov	dh,0x0			; 009F3
	ror	dx,cl			; 009F5
	db	0x0B, 0xC2		; 009F7 or ax,dx
	mov	[di+offscreen_buffer],ax		; 009F9
	jmp	short draw_sprite_unflipped_columns_next_row		; 009FD jmp 0xa0b
draw_sprite_unflipped_columns_write_aligned_byte:
	not	al			; 009FF
	and	al,[di+offscreen_buffer]		; 00A01
	db	0x0A, 0xC2		; 00A05 or al,dl
	mov	[di+offscreen_buffer],al		; 00A07
draw_sprite_unflipped_columns_next_row:
	add	di,0x50			; 00A0B
	dec	bl			; 00A0E
	jnz	short draw_sprite_unflipped_columns_row_loop		; 00A10 jnz 0x9d3
	add	word [bp+0x6],0x4	; 00A12
	inc	word [sprite_column_offset]		; 00A16
	dec	ch			; 00A1A
	jnz	short draw_sprite_unflipped_columns_column_loop		; 00A1C jnz 0x9ca
draw_sprite_unflipped_columns_check_right_partial_column:
	cmp	word [sprite_partial_edge_column],0x0	; 00A1E
	jz	short draw_sprite_unflipped_columns_exit		; 00A23 jz 0xa69
	mov	al,[sprite_rows]		; 00A25
	mov	[sprite_rows_left],al		; 00A28
	mov	di,[sprite_top_line_offset]		; 00A2B
	add	di,0x4f			; 00A2F
	cmp	byte [bp+0x4],0xc8	; 00A32
	jc	short draw_sprite_unflipped_columns_right_partial_row_loop		; 00A36 jc 0xa3b
	jmp	near draw_sprite_unflipped_columns_opaque_right_partial			; 00A38
draw_sprite_unflipped_columns_right_partial_row_loop:
	call	next_sprite_bytes	; 00A3B
	cmp	al,0x0			; 00A3E
	jz	short draw_sprite_unflipped_columns_right_partial_next_row		; 00A40 jz 0xa60
	mov	ah,0x0			; 00A42
	db	0x23, 0xD0		; 00A44 and dx,ax
	not	ax			; 00A46
	mov	cl,[sprite_bit_shift]		; 00A48
	ror	ax,cl			; 00A4C
	and	al,[di+offscreen_buffer]		; 00A4E
	mov	cl,[sprite_bit_shift]		; 00A52
	mov	dh,0x0			; 00A56
	ror	dx,cl			; 00A58
	db	0x0A, 0xC2		; 00A5A or al,dl
	mov	[di+offscreen_buffer],al		; 00A5C
draw_sprite_unflipped_columns_right_partial_next_row:
	add	di,0x50			; 00A60
	dec	byte [sprite_rows_left]		; 00A63
	jnz	short draw_sprite_unflipped_columns_right_partial_row_loop		; 00A67 jnz 0xa3b
draw_sprite_unflipped_columns_exit:
	pop	bp			; 00A69
	ret				; 00A6A
; Fast-path renderers: reached via jumps when [bp+0x4] >= 0xC8.
; These skip the bit rotation loop and write sprite data directly,
; which is faster for large/aligned sprites.
; fast path taken from draw_sprite_unflipped when [bp+4] >= 0xC8
draw_sprite_unflipped_columns_opaque_left_partial:
	mov	si,[sprite_image_pos]		; 00A6B
draw_sprite_unflipped_columns_opaque_left_partial_row_loop:
	mov	dl,[si+sprite_image_bank]		; 00A6F
	mov	ax,0xff00		; 00A73
	inc	si			; 00A76
	mov	cl,[sprite_bit_shift]		; 00A77
	ror	ax,cl			; 00A7B
	and	ah,[di+offscreen_buffer]		; 00A7D
	mov	cl,[sprite_bit_shift]		; 00A81
	mov	dh,0x0			; 00A85
	ror	dx,cl			; 00A87
	db	0x0A, 0xE6		; 00A89 or ah,dh
	mov	[di+offscreen_buffer],ah		; 00A8B
	add	di,0x50			; 00A8F
	dec	byte [sprite_rows_left]		; 00A92
	jnz	short draw_sprite_unflipped_columns_opaque_left_partial_row_loop		; 00A96 jnz 0xa6f
	mov	[sprite_image_pos],si		; 00A98
	jmp	near draw_sprite_unflipped_left_partial_column_done			; 00A9C
; fast path taken when [bp+4] >= 0xC8; picks aligned or shifted column loop
draw_sprite_unflipped_columns_opaque_columns:
	mov	bl,[sprite_bit_shift]		; 00A9F
	db	0x32, 0xFF		; 00AA3 xor bh,bh
	mov	si,[sprite_image_pos]		; 00AA5
	cmp	bx,0x0			; 00AA9
	jnz	short draw_sprite_unflipped_columns_opaque_shifted_column_loop		; 00AAC jnz 0xadd
draw_sprite_unflipped_columns_opaque_aligned_column_loop:
	mov	al,[sprite_rows]		; 00AAE
	mov	[sprite_rows_left],al		; 00AB1
	mov	di,[sprite_column_offset]		; 00AB4
draw_sprite_unflipped_columns_opaque_aligned_row_loop:
	mov	dl,[si+sprite_image_bank]		; 00AB8
	inc	si			; 00ABC
	mov	[di+offscreen_buffer],dl		; 00ABD
	add	di,0x50			; 00AC1
	dec	byte [sprite_rows_left]		; 00AC4
	jnz	short draw_sprite_unflipped_columns_opaque_aligned_row_loop		; 00AC8 jnz 0xab8
	add	word [bp+0x6],0x4	; 00ACA
	inc	word [sprite_column_offset]		; 00ACE
	dec	ch			; 00AD2
	jnz	short draw_sprite_unflipped_columns_opaque_aligned_column_loop		; 00AD4 jnz 0xaae
	mov	[sprite_image_pos],si		; 00AD6
	jmp	near draw_sprite_unflipped_columns_check_right_partial_column			; 00ADA
draw_sprite_unflipped_columns_opaque_shifted_column_loop:
	mov	al,[sprite_rows]		; 00ADD
	mov	[sprite_rows_left],al		; 00AE0
	mov	di,[sprite_column_offset]		; 00AE3
draw_sprite_unflipped_columns_opaque_shifted_row_loop:
	mov	dl,[si+sprite_image_bank]		; 00AE7
	inc	si			; 00AEB
	mov	ax,[bx+sprite_opaque_keep_masks]		; 00AEC
	and	ax,[di+offscreen_buffer]		; 00AF0
	mov	cl,[sprite_bit_shift]		; 00AF4
	db	0x32, 0xF6		; 00AF8 xor dh,dh
	ror	dx,cl			; 00AFA
	db	0x0B, 0xC2		; 00AFC or ax,dx
	mov	[di+offscreen_buffer],ax		; 00AFE
	add	di,0x50			; 00B02
	dec	byte [sprite_rows_left]		; 00B05
	jnz	short draw_sprite_unflipped_columns_opaque_shifted_row_loop		; 00B09 jnz 0xae7
	add	word [bp+0x6],0x4	; 00B0B
	inc	word [sprite_column_offset]		; 00B0F
	dec	ch			; 00B13
	jnz	short draw_sprite_unflipped_columns_opaque_shifted_column_loop		; 00B15 jnz 0xadd
	mov	[sprite_image_pos],si		; 00B17
	jmp	near draw_sprite_unflipped_columns_check_right_partial_column			; 00B1B
; fast path taken when [bp+4] >= 0xC8
draw_sprite_unflipped_columns_opaque_right_partial:
	mov	si,[sprite_image_pos]		; 00B1E
draw_sprite_unflipped_columns_opaque_right_partial_row_loop:
	mov	dl,[si+sprite_image_bank]		; 00B22
	inc	si			; 00B26
	mov	ax,0xff00		; 00B27
	mov	cl,[sprite_bit_shift]		; 00B2A
	ror	ax,cl			; 00B2E
	and	al,[di+offscreen_buffer]		; 00B30
	mov	cl,[sprite_bit_shift]		; 00B34
	mov	dh,0x0			; 00B38
	ror	dx,cl			; 00B3A
	db	0x0A, 0xC2		; 00B3C or al,dl
	mov	[di+offscreen_buffer],al		; 00B3E
	add	di,0x50			; 00B42
	dec	byte [sprite_rows_left]		; 00B45
	jnz	short draw_sprite_unflipped_columns_opaque_right_partial_row_loop		; 00B49 jnz 0xb22
	jmp	near draw_sprite_unflipped_columns_exit			; 00B4B
