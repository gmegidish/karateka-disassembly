; Scene update, animation processing, random numbers


; ---- function scene_update ----
; Main scene state update — called once per game frame.
; Processes both player (character 1) and enemy (character 2) animation frames.
;
; Algorithm:
;   1. Reset sprite update flags
;   2. Align player_x and enemy_x to 4-pixel boundaries
;   3. Copy animation data to write buffer via memcpy_block
;   4. If combat_active > 1, skip to end (combat transition)
;   5. PLAYER LOOP: Walk the player animation frame table:
;      - If end marker (0xFF), call anim_process or player_anim_select to get next anim ID
;      - Look up new frame pointer from animation table
;      - Extract anim ID, direction, facing from frame data
;      - Apply X velocity (signed byte), clamp to [player_x_min, player_x_max]
;      - Push-back: if player would overlap enemy, reduce player_x
;      - Camera follow: camera_x = player_x - 150 (or enemy_x - 170 if locked)
;      - Clamp camera to [camera_x_min, camera_x_max]
;      - Write sprite data to animation buffer
;      - Advance frame pointer by 0x11 (17 bytes per frame entry)
;   6. ENEMY LOOP: Similar processing for enemy animation frames
;      - If end marker, call enemy_ai_decide to get next animation
;      - Apply velocity, clamp to boundaries
;      - Write sprite data to buffer
;   7. Finalize: write end marker, compute total buffer size
;
; Input: none (reads global state)
; Output: updates player/enemy positions, animation buffers, camera
; Clobbers: AX, BX, CX, DX, SI, DI
; Correction to step 4: combat_active > 1 skips only the player frame processing, by jumping to 02461, where the enemy section still runs unless combat_phase > 1. combat_phase > 1 jumps to 025CD, which skips the enemy and goes straight to the finalize step. enemy_frozen jumps to 02538, skipping velocity, clamping and the frame sound but still writing the figures.
scene_update:
	mov	byte [player_sprite_cmd],0x0	; 022E1  ; reset player sprite command
	mov	word [player_anim_ctr],0x0	; 022E6  ; reset player animation counter
	mov	ax,[player_x]		; 022EC
	db	0x05, 0x03, 0x00	; 022EF add ax,0x3
	db	0x25, 0xFC, 0xFF	; 022F2 and ax,0xfffc  ; align to 4-pixel boundary
	mov	[player_x],ax		; 022F5
	mov	ax,[enemy_x]		; 022F8
	db	0x05, 0x03, 0x00	; 022FB add ax,0x3
	db	0x25, 0xFC, 0xFF	; 022FE and ax,0xfffc  ; align to 4-pixel boundary
	mov	[enemy_x],ax		; 02301
	push	word [player_anim_div_b]		; 02304
	push	word [player_anim_div_a]		; 02308
	lea	ax,[player_anim_buf]		; 0230C
	push	ax			; 02310
	call	memcpy_block		; 02311
	add	sp,0x6			; 02314
	mov	[anim_write_off],ax		; 02317
	cmp	word [combat_active],0x1		; 0231A  ; if combat_active > 1, skip animation
	jng	short scene_update_load_player_frame_ptr		; 0231F jng 0x2324
	jmp	near scene_update_player_frame_done			; 02321
scene_update_load_player_frame_ptr:
	mov	bx,[player_frame_ptr]		; 02324
scene_update_check_player_frame_end:
	cmp	byte [bx+player_anim_frames],0xff	; 02328  ; check end-of-sequence marker
	jnz	short scene_update_apply_player_frame		; 0232D jnz 0x235c
	cmp	word [anim_mode],0x0	; 0232F
	jz	short scene_update_player_anim_from_input		; 02334 jz 0x233b
	call	anim_process		; 02336
	jmp	short scene_update_validate_player_anim_index		; 02339 jmp 0x233e
; anim_mode == 0: the player is driven by input; otherwise by anim_process.
scene_update_player_anim_from_input:
	call	player_anim_select	; 0233B
; Indices >= 0x2A are out of table range and fall back to 0.
scene_update_validate_player_anim_index:
	db	0x3D, 0x2A, 0x00	; 0233E cmp ax,0x2a
	jc	short scene_update_lookup_player_anim_table		; 02341 jc 0x2345
	db	0x33, 0xC0		; 02343 xor ax,ax
scene_update_lookup_player_anim_table:
	shl	ax,1			; 02345
	db	0x8B, 0xD8		; 02347 mov bx,ax
	mov	ax,[bx+player_frame_bak]		; 02349
	mov	[player_frame_ptr],ax		; 0234D
	db	0x8B, 0xD8		; 02350 mov bx,ax
	cmp	word [combat_active],0x1		; 02352
	jng	short scene_update_check_player_frame_end		; 02357 jng 0x2328
	jmp	near scene_update_player_frame_done			; 02359
scene_update_apply_player_frame:
	mov	si,[player_frame_ptr]		; 0235C
	mov	ah,0x0			; 02360
	mov	al,[si+player_frame_anim_id]		; 02362
	mov	[player_anim_id],ax		; 02366
	mov	al,[si+player_frame_flags]		; 02369
	db	0x8A, 0xC8		; 0236D mov cl,al
	and	al,0x1			; 0236F
	shr	cl,1			; 02371
	mov	[player_dir_flag],cl		; 02373
	mov	[player_facing],ax		; 02377
	mov	cx,[player_x]		; 0237A
	cmp	word [scene_locked],0x0	; 0237E
	jnz	short scene_update_check_player_enemy_overlap		; 02383 jnz 0x23ae
	mov	al,[si+player_frame_dx]		; 02385
	cbw				; 02389
	add	[player_x],ax		; 0238A
	mov	cx,[player_x]		; 0238E
	cmp	cx,[player_x_min]		; 02392
	jg	short scene_update_clamp_player_x_max		; 02396 jg 0x23a0
	mov	cx,[player_x_min]		; 02398
	mov	[player_x],cx		; 0239C
scene_update_clamp_player_x_max:
	cmp	cx,[player_x_max]		; 023A0
	jl	short scene_update_check_player_enemy_overlap		; 023A4 jl 0x23ae
	mov	cx,[player_x_max]		; 023A6
	mov	[player_x],cx		; 023AA
scene_update_check_player_enemy_overlap:
	cmp	word [combat_phase],0x0		; 023AE
	jg	short scene_update_update_camera		; 023B3 jg 0x23f2
	add	cx,0x8			; 023B5
	cmp	word [enemy_active],0x0	; 023B8
	jz	short scene_update_check_player_charge_range		; 023BD jz 0x23c2
	sub	cx,0x4			; 023BF
; Player anim 0x0B ends and resets to frame table entry 0 once player_x+8 is within 16 pixels of enemy_x.
scene_update_check_player_charge_range:
	cmp	word [player_anim_id],0xb	; 023C2
	jnz	short scene_update_push_player_back_from_enemy		; 023C7 jnz 0x23e2
	push	cx			; 023C9
	sub	cx,[enemy_x]		; 023CA
	cmp	cx,0xfffffffffffffff0	; 023CE
	pop	cx			; 023D1
	jl	short scene_update_update_camera		; 023D2 jl 0x23f2
	mov	word [player_anim_id],0x0	; 023D4
	mov	dx,[player_frame_bak]		; 023DA
	mov	[player_frame_ptr],dx		; 023DE
scene_update_push_player_back_from_enemy:
	cmp	cx,[enemy_x]		; 023E2
	jng	short scene_update_update_camera		; 023E6 jng 0x23f2
	sub	cx,[enemy_x]		; 023E8
	sub	[player_x],cx		; 023EC
	db	0x2B, 0xC1		; 023F0 sub ax,cx
scene_update_update_camera:
	cmp	word [scene_locked],0x0	; 023F2
	jz	short scene_update_camera_follow_player		; 023F7 jz 0x2407
	mov	cx,[enemy_x]		; 023F9
	sub	cx,0xaa			; 023FD
	mov	[camera_x],cx		; 02401
	jmp	short scene_update_clamp_camera_min		; 02405 jmp 0x2413
scene_update_camera_follow_player:
	mov	cx,[player_x]		; 02407
	sub	cx,0x96			; 0240B
	mov	[camera_x],cx		; 0240F
scene_update_clamp_camera_min:
	cmp	cx,[camera_x_min]		; 02413
	jg	short scene_update_clamp_camera_max		; 02417 jg 0x2421
	mov	cx,[camera_x_min]		; 02419
	mov	[camera_x],cx		; 0241D
scene_update_clamp_camera_max:
	cmp	cx,[camera_x_max]		; 02421
	jl	short scene_update_check_player_frame_sound		; 02425 jl 0x242f
	mov	cx,[camera_x_max]		; 02427
	mov	[camera_x],cx		; 0242B
scene_update_check_player_frame_sound:
	cmp	word [scene_locked],0x0	; 0242F
	jnz	short scene_update_copy_player_figures		; 02434 jnz 0x243d
	mov	al,[si+player_frame_sound]		; 02436
	mov	[player_sprite_cmd],al		; 0243A
scene_update_copy_player_figures:
	push	word [player_x]		; 0243D
	lea	ax,[player_frame_figures]		; 02441
	db	0x03, 0xC6		; 02445 add ax,si
	push	ax			; 02447
	lea	ax,[player_anim_buf]		; 02448
	add	ax,[anim_write_off]		; 0244C
	push	ax			; 02450
	call	copy_sprite_frame		; 02451
	add	sp,0x6			; 02454
	add	word [anim_write_off],0x8	; 02457
	add	word [player_frame_ptr],0x11	; 0245C  ; advance to next frame (17 bytes per entry)
; after player frame; also the skip target when combat_active > 1
scene_update_player_frame_done:
	cmp	word [combat_phase],0x1		; 02461
	jng	short scene_update_check_enemy_frame_end		; 02466 jng 0x246b
	jmp	near scene_update_enemy_frame_done			; 02468
scene_update_check_enemy_frame_end:
	mov	si,[enemy_frame_ptr]		; 0246B
	cmp	byte [si+enemy_anim_frames],0xff	; 0246F
	jnz	short scene_update_apply_enemy_frame		; 02474 jnz 0x2491
	call	enemy_ai_decide		; 02476
	cmp	word [combat_phase],0x1		; 02479
	jng	short scene_update_lookup_enemy_anim_table		; 0247E jng 0x2483
	jmp	near scene_update_enemy_frame_done			; 02480
scene_update_lookup_enemy_anim_table:
	db	0x8B, 0xD8		; 02483 mov bx,ax
	shl	bx,1			; 02485
	mov	si,[bx+enemy_frame_bak]		; 02487
	mov	[enemy_frame_ptr],si		; 0248B
	jmp	short scene_update_check_enemy_frame_end		; 0248F jmp 0x246b
scene_update_apply_enemy_frame:
	mov	ah,0x0			; 02491
	mov	al,[si+enemy_frame_anim_id]		; 02493
	mov	[enemy_anim_id],ax		; 02497
	mov	al,[si+enemy_frame_flags]		; 0249A
	db	0x8A, 0xC8		; 0249E mov cl,al
	shr	cl,1			; 024A0
	mov	[enemy_dir_flag],cl		; 024A2
	and	al,0x1			; 024A6
	mov	[enemy_facing],ax		; 024A8
	cmp	word [enemy_frozen],0x0	; 024AB
	jz	short scene_update_apply_enemy_velocity		; 024B0 jz 0x24b5
	jmp	near scene_update_write_enemy_figures			; 024B2
scene_update_apply_enemy_velocity:
	mov	al,[si+enemy_frame_dx]		; 024B5
	cbw				; 024B9
	add	[enemy_x],ax		; 024BA
	cmp	word [scene_transition_pending],0x0	; 024BE
	jnz	short scene_update_check_enemy_player_overlap		; 024C3 jnz 0x24df
	cmp	word [game_mode],0x0		; 024C5
	jnz	short scene_update_check_enemy_player_overlap		; 024CA jnz 0x24df
	cmp	word [enemy_active],0x0	; 024CC
	jnz	short scene_update_check_enemy_player_overlap		; 024D1 jnz 0x24df
	mov	ax,[player_x_max]		; 024D3
	cmp	ax,[enemy_x]		; 024D6
	jnl	short scene_update_check_enemy_player_overlap		; 024DA jnl 0x24df
	mov	[enemy_x],ax		; 024DC
scene_update_check_enemy_player_overlap:
	cmp	word [combat_phase],0x0		; 024DF
	jg	short scene_update_clamp_enemy_x_min		; 024E4 jg 0x2521
	mov	ax,[player_x]		; 024E6
	db	0x05, 0x08, 0x00	; 024E9 add ax,0x8
	cmp	word [enemy_active],0x0	; 024EC
	jz	short scene_update_check_enemy_charge_range		; 024F1 jz 0x24f8
	db	0x2D, 0x04, 0x00	; 024F3 sub ax,0x4
	jmp	short scene_update_block_enemy_at_player		; 024F6 jmp 0x2518
; Enemy anim 0x0A ends and resets to frame table entry 0 once enemy_x is within 16 pixels of player_x+8.
scene_update_check_enemy_charge_range:
	cmp	word [enemy_anim_id],0xa	; 024F8
	jnz	short scene_update_block_enemy_at_player		; 024FD jnz 0x2518
	mov	dx,[enemy_x]		; 024FF
	db	0x2B, 0xD0		; 02503 sub dx,ax
	cmp	dx,0x10			; 02505
	jg	short scene_update_clamp_enemy_x_min		; 02508 jg 0x2521
	mov	word [enemy_anim_id],0x0	; 0250A
	mov	dx,[enemy_frame_bak]		; 02510
	mov	[enemy_frame_ptr],dx		; 02514
scene_update_block_enemy_at_player:
	cmp	[enemy_x],ax		; 02518
	jnl	short scene_update_clamp_enemy_x_min		; 0251C jnl 0x2521
	mov	[enemy_x],ax		; 0251E
scene_update_clamp_enemy_x_min:
	mov	ax,[enemy_x_min]		; 02521
	cmp	[enemy_x],ax		; 02524
	jnl	short scene_update_check_enemy_frame_sound		; 02528 jnl 0x252d
	mov	[enemy_x],ax		; 0252A
scene_update_check_enemy_frame_sound:
	mov	al,[si+enemy_frame_sound]		; 0252D
	cmp	al,0x0			; 02531
	jz	short scene_update_write_enemy_figures		; 02533 jz 0x2538
	mov	[player_sprite_cmd],al		; 02535
; Also the target of the enemy_frozen jump: a frozen enemy skips velocity, clamping and the frame sound.
scene_update_write_enemy_figures:
	mov	di,[anim_write_off]		; 02538
	mov	al,[si+enemy_frame_fig1_id]		; 0253C
	mov	[di+player_anim_buf],al		; 02540
	mov	ax,[si+enemy_frame_fig1_x]		; 02544
	cmp	word [player_faces_right],0x0		; 02548
	jz	short scene_update_enemy_fig1_check_active_offset		; 0254D jz 0x2552
	db	0x05, 0x04, 0x00	; 0254F add ax,0x4
scene_update_enemy_fig1_check_active_offset:
	cmp	word [enemy_active],0x0	; 02552
	jz	short scene_update_enemy_fig1_add_world_x		; 02557 jz 0x255c
	db	0x05, 0x0C, 0x00	; 02559 add ax,0xc
scene_update_enemy_fig1_add_world_x:
	add	ax,[enemy_x]		; 0255C
	cmp	word [player_faces_right],0x0		; 02560
	jnz	short scene_update_store_enemy_fig1_x		; 02565 jnz 0x2571
	cmp	word [enemy_active],0x0	; 02567
	jnz	short scene_update_store_enemy_fig1_x		; 0256C jnz 0x2571
	or	ax,0x4000		; 0256E  ; set flip bit (mirror sprite horizontally)
scene_update_store_enemy_fig1_x:
	mov	[di+figure_list_x],ax		; 02571
	mov	al,[si+enemy_frame_fig1_y]		; 02575
	cmp	word [enemy_active],0x0	; 02579
	jz	short scene_update_store_enemy_fig1_y		; 0257E jz 0x2584
	add	al,[enemy_y_off]		; 02580
scene_update_store_enemy_fig1_y:
	mov	[di+figure_list_y],al		; 02584
	mov	al,[si+enemy_frame_fig2_id]		; 02588
	cmp	word [enemy_active],0x0	; 0258C
	jnz	short scene_update_store_enemy_fig2_sprite		; 02591 jnz 0x2597
	add	al,[player_y_off]		; 02593
scene_update_store_enemy_fig2_sprite:
	mov	[di+figure_list_id2],al		; 02597
	mov	ax,[si+enemy_frame_fig2_x]		; 0259B
	cmp	word [player_faces_right],0x0		; 0259F
	jz	short scene_update_enemy_fig2_check_active_offset		; 025A4 jz 0x25a9
	db	0x05, 0x04, 0x00	; 025A6 add ax,0x4
scene_update_enemy_fig2_check_active_offset:
	cmp	word [enemy_active],0x0	; 025A9
	jz	short scene_update_enemy_fig2_add_world_x		; 025AE jz 0x25b3
	db	0x05, 0x0C, 0x00	; 025B0 add ax,0xc
scene_update_enemy_fig2_add_world_x:
	add	ax,[enemy_x]		; 025B3
	mov	[di+figure_list_x2],ax		; 025B7
	mov	al,[si+enemy_frame_fig2_y]		; 025BB
	mov	[di+figure_list_y2],al		; 025BF
	add	word [anim_write_off],0x8	; 025C3
	add	word [enemy_frame_ptr],0x11	; 025C8  ; advance enemy frame pointer
; after enemy frame; also the skip target when combat_phase > 1
scene_update_enemy_frame_done:
	push	word [scenery_row_end_ptr]		; 025CD
	push	word [player_anim_div_b]		; 025D1
	mov	ax,[anim_write_off]		; 025D5
	db	0x05, 0x03, 0x00	; 025D8 add ax,0x3
	mov	[anim_data_limit],ax		; 025DB
	lea	ax,[player_anim_buf]		; 025DE
	add	ax,[anim_write_off]		; 025E2
	push	ax			; 025E6
	mov	[anim_temp_ptr],ax		; 025E7
	call	memcpy_block		; 025EA
	add	sp,0x6			; 025ED
	add	[anim_write_off],ax		; 025F0
	mov	si,[anim_write_off]		; 025F4
	mov	byte [si+player_anim_buf],0xff	; 025F8  ; write end marker to animation buffer
	add	si,0x3			; 025FD
	mov	[player_anim_end],si		; 02600
	ret				; 02604

; ---- function enemy_ai_decide ----
; Enemy AI decision function — selects the next animation/action for the enemy.
; Despite its old name "math_random", this is the core enemy AI.
;
; Returns an animation table index in AX. Key return values:
;   0x00 = idle/stand          0x01 = advance/walk
;   0x02 = close advance       0x05 = retreat step
;   0x07 = attack (far)        0x08 = kick
;   0x09 = strong attack       0x0B = charge
;   0x0C = kick (far)          0x0D = counter-attack
;   0x0E = flee/run away       0x0F = block
;   0x13 = special attack      0x1B = recoil from hit
;   0x1E = approach walk       0x1F = walk (slow)
;   0x20 = stand               0x21 = transition stand
;
; Decision tree:
;   1. If enemy anim is 0x46 (death): return 0x0E (flee) if scene locked, 0 if frozen
;   2. Compute distance = enemy_x - player_x -> [bp+6]
;   3. If anim 0x1C: set combat counters
;   4. If game_mode == 1: special logic (return 0 if anim 2, advance/retreat based on distance)
;   5. If combat_phase == 1 (approach): return 0x1E
;   6. If enemy_active (enemy present):
;      a. If enemy anim 0x22: enemy defeated — set retreat, calculate health regen
;      b. If enemy_was_hit: clear flag, return 0x20 (stand)
;      c. Walking logic (anim 0x1F/0x21)
;      d. Level 3 boss: special teleport/retreat at distance > 300
;      e. Distance > 240: teleport enemy to 1920, set approach
;      f. Combat active: return special attacks (0x13, 0x09)
;      g. Enemy was hit in combat: knockback + recoil
;      h. Aggressive mode: attack decision via probability tables
;   7. Not aggressive: distance-based logic, set aggressive when close
;
; Input: none (reads global state)
; Output: AX = animation table index
; Local: [bp+6] = distance between enemy and player
; Corrections: steps 6f, 6g and 6h do not belong under enemy_active; they run when enemy_active != 1, and the enemy_active == 1 branch always returns before them. Step 6d compares the absolute enemy_x with 300, not the distance, and does not teleport: with combat_active > 0 it sets combat_phase = 2 and clears enemy_active, otherwise it re-rolls enemy_y_off and returns 0x1F; enemy_x <= 300 returns 0x20.
enemy_ai_decide:
	push	bp			; 02605
	sub	sp,0xc			; 02606
	jc	short enemy_ai_decide_stack_overflow		; 02609 jc 0x2611
	cmp	sp,[stack_limit]		; 0260B
	ja	short enemy_ai_decide_stack_ok		; 0260F ja 0x2614
enemy_ai_decide_stack_overflow:
	jmp	near stack_overflow_handler			; 02611
enemy_ai_decide_stack_ok:
	db	0x8B, 0xEC		; 02614 mov bp,sp
	cmp	word [enemy_anim_id],0x46	; 02616  ; enemy anim 0x46 = death animation
	jnz	short enemy_ai_decide_compute_distance		; 0261B jnz 0x263a
	cmp	word [scene_locked],0x0	; 0261D
	jng	short enemy_ai_decide_anim_46_check_frozen		; 02622 jng 0x262c
	mov	ax,0xe			; 02624
	add	sp,0xc			; 02627
	pop	bp			; 0262A
	ret				; 0262B
enemy_ai_decide_anim_46_check_frozen:
	cmp	word [enemy_frozen],0x0	; 0262C
	jng	short enemy_ai_decide_compute_distance		; 02631 jng 0x263a
	db	0x33, 0xC0		; 02633 xor ax,ax
	add	sp,0xc			; 02635
	pop	bp			; 02638
	ret				; 02639
enemy_ai_decide_compute_distance:
	mov	ax,[enemy_x]		; 0263A
	sub	ax,[player_x]		; 0263D
	cmp	word [enemy_anim_id],0x1c	; 02641
	mov	[bp+0x6],ax		; 02646
	jnz	short enemy_ai_decide_check_game_mode		; 02649 jnz 0x2654
	mov	ax,0x1			; 0264B
	mov	[combat_counter_b],ax		; 0264E
	mov	[combat_counter_a],ax		; 02651
enemy_ai_decide_check_game_mode:
	cmp	word [game_mode],0x1		; 02654
	jnz	short enemy_ai_decide_check_approach_phase		; 02659 jnz 0x269b
	cmp	word [enemy_anim_id],0x2	; 0265B
	jnz	short enemy_ai_decide_mode1_check_player_anim		; 02660 jnz 0x2669
	db	0x33, 0xC0		; 02662 xor ax,ax
	add	sp,0xc			; 02664
	pop	bp			; 02667
	ret				; 02668
enemy_ai_decide_mode1_check_player_anim:
	cmp	word [player_anim_id],0x3f	; 02669
	jng	short enemy_ai_decide_mode1_check_distance		; 0266E jng 0x267f
	cmp	word [combat_active],0x0		; 02670
	jnz	short enemy_ai_decide_mode1_check_distance		; 02675 jnz 0x267f
	mov	ax,0x1			; 02677
	add	sp,0xc			; 0267A
	pop	bp			; 0267D
	ret				; 0267E
enemy_ai_decide_mode1_check_distance:
	cmp	word [bp+0x6],0x38	; 0267F
	jnl	short enemy_ai_decide_mode1_return_idle		; 02683 jnl 0x2694
	cmp	word [combat_active],0x0		; 02685
	jnz	short enemy_ai_decide_mode1_return_idle		; 0268A jnz 0x2694
	mov	ax,0x2			; 0268C
	add	sp,0xc			; 0268F
	pop	bp			; 02692
	ret				; 02693
enemy_ai_decide_mode1_return_idle:
	db	0x33, 0xC0		; 02694 xor ax,ax
	add	sp,0xc			; 02696
	pop	bp			; 02699
	ret				; 0269A
enemy_ai_decide_check_approach_phase:
	cmp	word [combat_phase],0x1		; 0269B
	jnz	short enemy_ai_decide_check_enemy_active		; 026A0 jnz 0x26aa
	mov	ax,0x1e			; 026A2
	add	sp,0xc			; 026A5
	pop	bp			; 026A8
	ret				; 026A9
enemy_ai_decide_check_enemy_active:
	cmp	word [enemy_active],0x1	; 026AA
	jz	short enemy_ai_decide_active_check_defeated		; 026AF jz 0x26b4
	jmp	near enemy_ai_decide_enemy_inactive			; 026B1
enemy_ai_decide_active_check_defeated:
	cmp	word [enemy_anim_id],0x22	; 026B4  ; enemy anim 0x22 = defeated/fallen
	jnz	short enemy_ai_decide_active_check_was_hit		; 026B9 jnz 0x2701
	db	0x33, 0xC0		; 026BB xor ax,ax
	mov	word [combat_phase],0x2		; 026BD  ; set combat_phase = retreat
	mov	bx,0xffff		; 026C3
	mov	word [enemy_defeated],0x1	; 026C6  ; set enemy_defeated flag
	cmp	word [enemy_health],0x9	; 026CC
	mov	[enemy_active],ax		; 026D1
	mov	[wipe_prev_left],bx		; 026D4
	mov	[anim_state_bb2a],bx		; 026D8
	jng	short enemy_ai_decide_defeated_compute_regen		; 026DC jng 0x26e9
	mov	word [enemy_health],0x9	; 026DE
	mov	[enemy_health_regen],ax		; 026E4
	jmp	short enemy_ai_decide_defeated_return_idle		; 026E7 jmp 0x26fa
enemy_ai_decide_defeated_compute_regen:
	mov	ax,[enemy_health]		; 026E9
	db	0x3D, 0x09, 0x00	; 026EC cmp ax,0x9
	jnl	short enemy_ai_decide_defeated_return_idle		; 026EF jnl 0x26fa
	mov	bx,0x9			; 026F1
	db	0x2B, 0xD8		; 026F4 sub bx,ax
	mov	[enemy_health_regen],bx		; 026F6
enemy_ai_decide_defeated_return_idle:
	db	0x33, 0xC0		; 026FA xor ax,ax
	add	sp,0xc			; 026FC
	pop	bp			; 026FF
	ret				; 02700
enemy_ai_decide_active_check_was_hit:
	cmp	word [enemy_was_hit],0x1		; 02701
	jnz	short enemy_ai_decide_active_check_anim_1f		; 02706 jnz 0x2716
	mov	word [enemy_was_hit],0x0		; 02708
	mov	ax,0x20			; 0270E
	add	sp,0xc			; 02711
	pop	bp			; 02714
	ret				; 02715
enemy_ai_decide_active_check_anim_1f:
	cmp	word [enemy_anim_id],0x1f	; 02716
	jnz	short enemy_ai_decide_active_check_anim_21		; 0271B jnz 0x2733
	cmp	word [bp+0x6],0xc	; 0271D
	jng	short enemy_ai_decide_active_return_arrive		; 02721 jng 0x272b
	mov	ax,0x1f			; 02723
	add	sp,0xc			; 02726
	pop	bp			; 02729
	ret				; 0272A
; Enemy anim 0x1F has come within 12 pixels of the player: return 0x21.
enemy_ai_decide_active_return_arrive:
	mov	ax,0x21			; 0272B
	add	sp,0xc			; 0272E
	pop	bp			; 02731
	ret				; 02732
enemy_ai_decide_active_check_anim_21:
	cmp	word [enemy_anim_id],0x21	; 02733
	jnz	short enemy_ai_decide_active_check_level_3		; 02738 jnz 0x2742
	mov	ax,0x20			; 0273A
	add	sp,0xc			; 0273D
	pop	bp			; 02740
	ret				; 02741
enemy_ai_decide_active_check_level_3:
	cmp	word [current_level],0x3		; 02742  ; level 3 (final boss)
	jnz	short enemy_ai_decide_active_check_far_distance		; 02747 jnz 0x2789
	cmp	word [enemy_x],0x12c	; 02749
	jng	short enemy_ai_decide_level3_return_stand		; 0274F jng 0x2781
	cmp	word [combat_active],0x0		; 02751
	jng	short enemy_ai_decide_level3_reroll_y_offset		; 02756 jng 0x2768
	db	0x33, 0xC0		; 02758 xor ax,ax
	mov	word [combat_phase],0x2		; 0275A
	mov	[enemy_active],ax		; 02760
	add	sp,0xc			; 02763
	pop	bp			; 02766
	ret				; 02767
; Picks a new enemy_y_off of 0, 12 or 24 and returns 0x1F.
enemy_ai_decide_level3_reroll_y_offset:
	mov	ax,0x2			; 02768
	push	ax			; 0276B
	call	rand_range		; 0276C
	db	0x8B, 0xE5		; 0276F mov sp,bp
	mov	bx,0xc			; 02771
	imul	bx			; 02774
	mov	[enemy_y_off],ax		; 02776
	mov	ax,0x1f			; 02779
	add	sp,0xc			; 0277C
	pop	bp			; 0277F
	ret				; 02780
enemy_ai_decide_level3_return_stand:
	mov	ax,0x20			; 02781
	add	sp,0xc			; 02784
	pop	bp			; 02787
	ret				; 02788
enemy_ai_decide_active_check_far_distance:
	mov	ax,[enemy_x]		; 02789
	sub	ax,[player_x]		; 0278C
	cmp	ax,0xf0			; 02790
	jnl	short enemy_ai_decide_active_teleport_offscreen		; 02793 jnl 0x279d
	mov	ax,0x20			; 02795
	add	sp,0xc			; 02798
	pop	bp			; 0279B
	ret				; 0279C
enemy_ai_decide_active_teleport_offscreen:
	mov	word [enemy_x],0x780	; 0279D  ; teleport enemy to X=1920 (offscreen right)
	db	0x33, 0xC0		; 027A3 xor ax,ax
	mov	word [combat_phase],0x1		; 027A5
	mov	[enemy_active],ax		; 027AB
	add	sp,0xc			; 027AE
	pop	bp			; 027B1
	ret				; 027B2
; Reached from 026B1 when enemy_active != 1: combat_active handling, enemy_was_hit knockback, then enemy_aggressive check.
enemy_ai_decide_enemy_inactive:
	cmp	word [combat_active],0x0		; 027B3
	jng	short enemy_ai_decide_check_was_hit		; 027B8 jng 0x27e0
	cmp	word [enemy_anim_id],0x41	; 027BA
	jnz	short enemy_ai_decide_combat_check_anim_40		; 027BF jnz 0x27c9
	mov	ax,0x13			; 027C1
	add	sp,0xc			; 027C4
	pop	bp			; 027C7
	ret				; 027C8
enemy_ai_decide_combat_check_anim_40:
	cmp	word [enemy_anim_id],0x40	; 027C9
	jnz	short enemy_ai_decide_combat_return_strong_attack		; 027CE jnz 0x27d8
	mov	ax,0x13			; 027D0
	add	sp,0xc			; 027D3
	pop	bp			; 027D6
	ret				; 027D7
enemy_ai_decide_combat_return_strong_attack:
	mov	ax,0x9			; 027D8
	add	sp,0xc			; 027DB
	pop	bp			; 027DE
	ret				; 027DF
enemy_ai_decide_check_was_hit:
	cmp	word [enemy_was_hit],0x1		; 027E0
	jnz	short enemy_ai_decide_check_aggressive		; 027E5 jnz 0x280e
	mov	word [enemy_was_hit],0x0		; 027E7
	add	word [enemy_x],0x8	; 027ED
	mov	ax,[enemy_anim_id]		; 027F2
	db	0x3D, 0x04, 0x00	; 027F5 cmp ax,0x4
	jng	short enemy_ai_decide_hit_return_idle		; 027F8 jng 0x2807
	db	0x3D, 0x08, 0x00	; 027FA cmp ax,0x8
	jnl	short enemy_ai_decide_hit_return_idle		; 027FD jnl 0x2807
	mov	ax,0x1b			; 027FF
	add	sp,0xc			; 02802
	pop	bp			; 02805
	ret				; 02806
enemy_ai_decide_hit_return_idle:
	db	0x33, 0xC0		; 02807 xor ax,ax
	add	sp,0xc			; 02809
	pop	bp			; 0280C
	ret				; 0280D
enemy_ai_decide_check_aggressive:
	cmp	word [enemy_aggressive],0x1		; 0280E
	jz	short enemy_ai_decide_aggressive_check_player_anim		; 02813 jz 0x2818
	jmp	near enemy_ai_decide_not_aggressive			; 02815
enemy_ai_decide_aggressive_check_player_anim:
	cmp	word [player_anim_id],0x3f	; 02818
	jng	short enemy_ai_decide_aggressive_check_anim_b		; 0281D jng 0x283a
	cmp	word [bp+0x6],0x30	; 0281F
	jnl	short enemy_ai_decide_aggressive_pick_attack_at_range		; 02823 jnl 0x282d
	mov	ax,0x5			; 02825
	add	sp,0xc			; 02828
	pop	bp			; 0282B
	ret				; 0282C
enemy_ai_decide_aggressive_pick_attack_at_range:
	push	word [bp+0x6]		; 0282D
	call	combat_pick_far_attack	; 02830
	db	0x8B, 0xE5		; 02833 mov sp,bp
	add	sp,0xc			; 02835
	pop	bp			; 02838
	ret				; 02839
enemy_ai_decide_aggressive_check_anim_b:
	cmp	word [enemy_anim_id],0xb	; 0283A
	jnz	short enemy_ai_decide_aggressive_check_distance		; 0283F jnz 0x2848
	db	0x33, 0xC0		; 02841 xor ax,ax
	add	sp,0xc			; 02843
	pop	bp			; 02846
	ret				; 02847
enemy_ai_decide_aggressive_check_distance:
	cmp	word [bp+0x6],0x2c	; 02848
	jng	short enemy_ai_decide_aggressive_roll_random		; 0284C jng 0x285b
	push	word [bp+0x6]		; 0284E
	call	combat_pick_far_attack	; 02851
	db	0x8B, 0xE5		; 02854 mov sp,bp
	add	sp,0xc			; 02856
	pop	bp			; 02859
	ret				; 0285A
enemy_ai_decide_aggressive_roll_random:
	mov	ax,0xff			; 0285B
	push	ax			; 0285E
	call	rand_range		; 0285F
	db	0x8B, 0xE5		; 02862 mov sp,bp
	cmp	word [bp+0x6],0x1c	; 02864
	mov	[bp+0xa],ax		; 02868
	jnl	short enemy_ai_decide_aggressive_check_idle_tier		; 0286B jnl 0x2872
	mov	word [bp+0x6],0x1c	; 0286D
; Tables are indexed by current_level*10 + (distance-0x1C)/4*2: five distance bands per level.
enemy_ai_decide_aggressive_check_idle_tier:
	mov	ax,[current_level]		; 02872
	mov	bx,0xa			; 02875
	imul	bx			; 02878
	db	0x8B, 0xF0		; 0287A mov si,ax
	mov	ax,[bp+0x6]		; 0287C
	db	0x2D, 0x1C, 0x00	; 0287F sub ax,0x1c
	mov	bx,0x4			; 02882
	cwd				; 02885
	idiv	bx			; 02886
	shl	ax,1			; 02888
	db	0x03, 0xF0		; 0288A add si,ax
	mov	ax,[bp+0xa]		; 0288C
	cmp	ax,[si+close_tier1_thresholds]		; 0288F
	jl	short enemy_ai_decide_aggressive_check_interpolate_tier		; 02893 jl 0x289c
	db	0x33, 0xC0		; 02895 xor ax,ax
	add	sp,0xc			; 02897
	pop	bp			; 0289A
	ret				; 0289B
enemy_ai_decide_aggressive_check_interpolate_tier:
	mov	ax,[current_level]		; 0289C
	mov	bx,0xa			; 0289F
	imul	bx			; 028A2
	db	0x8B, 0xF0		; 028A4 mov si,ax
	mov	ax,[bp+0x6]		; 028A6
	db	0x2D, 0x1C, 0x00	; 028A9 sub ax,0x1c
	mov	bx,0x4			; 028AC
	cwd				; 028AF
	idiv	bx			; 028B0
	shl	ax,1			; 028B2
	db	0x03, 0xF0		; 028B4 add si,ax
	mov	ax,[bp+0xa]		; 028B6
	cmp	ax,[si+close_tier2_thresholds]		; 028B9
	jl	short enemy_ai_decide_aggressive_check_frame_update_tier		; 028BD jl 0x28df
	mov	ax,[enemy_anim_id]		; 028BF
	db	0x3D, 0x08, 0x00	; 028C2 cmp ax,0x8
	jnl	short enemy_ai_decide_aggressive_return_interpolate		; 028C5 jnl 0x28d7
	db	0x3D, 0x04, 0x00	; 028C7 cmp ax,0x4
	jng	short enemy_ai_decide_aggressive_return_interpolate		; 028CA jng 0x28d7
	call	anim_interpolate	; 028CC
	db	0x05, 0x14, 0x00	; 028CF add ax,0x14
	add	sp,0xc			; 028D2
	pop	bp			; 028D5
	ret				; 028D6
enemy_ai_decide_aggressive_return_interpolate:
	call	anim_interpolate	; 028D7
	add	sp,0xc			; 028DA
	pop	bp			; 028DD
	ret				; 028DE
enemy_ai_decide_aggressive_check_frame_update_tier:
	mov	ax,[current_level]		; 028DF
	mov	bx,0xa			; 028E2
	imul	bx			; 028E5
	db	0x8B, 0xF0		; 028E7 mov si,ax
	mov	ax,[bp+0x6]		; 028E9
	db	0x2D, 0x1C, 0x00	; 028EC sub ax,0x1c
	mov	bx,0x4			; 028EF
	cwd				; 028F2
	idiv	bx			; 028F3
	shl	ax,1			; 028F5
	db	0x03, 0xF0		; 028F7 add si,ax
	mov	ax,[bp+0xa]		; 028F9
	cmp	ax,[si+close_tier3_thresholds]		; 028FC
	jl	short enemy_ai_decide_aggressive_fallback_far_attack		; 02900 jl 0x290a
	call	anim_frame_update	; 02902
	add	sp,0xc			; 02905
	pop	bp			; 02908
	ret				; 02909
enemy_ai_decide_aggressive_fallback_far_attack:
	push	word [bp+0x6]		; 0290A
	call	combat_pick_far_attack	; 0290D
	db	0x8B, 0xE5		; 02910 mov sp,bp
	add	sp,0xc			; 02912
	pop	bp			; 02915
	ret				; 02916
; Reached from 02815 when enemy_aggressive != 1: distance > 0x6E returns 0x0B (player anim 0x42) or 0x13,
; otherwise sets enemy_aggressive = 1 and returns 0.
enemy_ai_decide_not_aggressive:
	cmp	word [bp+0x6],0x6e	; 02917
	jng	short enemy_ai_decide_set_aggressive		; 0291B jng 0x2934
	cmp	word [player_anim_id],0x42	; 0291D
	jnz	short enemy_ai_decide_not_aggressive_return_special		; 02922 jnz 0x292c
	mov	ax,0xb			; 02924
	add	sp,0xc			; 02927
	pop	bp			; 0292A
	ret				; 0292B
enemy_ai_decide_not_aggressive_return_special:
	mov	ax,0x13			; 0292C
	add	sp,0xc			; 0292F
	pop	bp			; 02932
	ret				; 02933
enemy_ai_decide_set_aggressive:
	mov	word [enemy_aggressive],0x1		; 02934
	db	0x33, 0xC0		; 0293A xor ax,ax
	add	sp,0xc			; 0293C
	pop	bp			; 0293F
	ret				; 02940

; ---- function combat_pick_far_attack ----
; Selects an attack animation when enemy is far from player.
; Uses random probability check against enemy_atk_freq.
;
; Input: [bp+0xa] = distance between enemy and player
; Output: AX = animation index (0=idle, 7=attack, 0xC=kick, 0xE=flee)
;
; Logic:
;   - Distance > 300: return 0x0E (flee)
;   - Distance > 75: threshold = enemy_atk_freq
;   - Distance <= 75: threshold = enemy_atk_freq * 3/4
;   - Random(255) > threshold -> return 0 (no attack)
;   - Level 0 boundary checks: don't attack near edges
;   - If enemy anim is 7 or 0xA and distance > 28: return 0x0C (kick)
;   - Default: return 0x07 (standard attack)
; The enemy_x < player_x_min + 15 check applies on level 0 only; the enemy_x < player_x_min + 5 check applies on every level.
combat_pick_far_attack:
	push	bp			; 02941
	sub	sp,0x6			; 02942
	jc	short combat_pick_far_attack_stack_overflow		; 02945 jc 0x294d
	cmp	sp,[stack_limit]		; 02947
	ja	short combat_pick_far_attack_stack_ok		; 0294B ja 0x2950
combat_pick_far_attack_stack_overflow:
	jmp	near stack_overflow_handler			; 0294D
combat_pick_far_attack_stack_ok:
	db	0x8B, 0xEC		; 02950 mov bp,sp
	cmp	word [bp+0xa],0x12c	; 02952
	jng	short combat_pick_far_attack_check_close_range		; 02957 jng 0x2961
	mov	ax,0xe			; 02959
	add	sp,0x6			; 0295C
	pop	bp			; 0295F
	ret				; 02960
combat_pick_far_attack_check_close_range:
	cmp	word [bp+0xa],0x4b	; 02961
	jng	short combat_pick_far_attack_reduce_threshold		; 02965 jng 0x296f
	mov	ax,[enemy_atk_freq]		; 02967
	mov	[bp+0x4],ax		; 0296A
	jmp	short combat_pick_far_attack_roll_random		; 0296D jmp 0x2980
combat_pick_far_attack_reduce_threshold:
	mov	ax,[enemy_atk_freq]		; 0296F
	mov	bx,0x3			; 02972
	imul	bx			; 02975
	mov	bx,0x4			; 02977
	cwd				; 0297A
	idiv	bx			; 0297B
	mov	[bp+0x4],ax		; 0297D
combat_pick_far_attack_roll_random:
	mov	ax,0xff			; 02980
	push	ax			; 02983
	call	rand_range		; 02984
	db	0x8B, 0xE5		; 02987 mov sp,bp
	cmp	ax,[bp+0x4]		; 02989
	jng	short combat_pick_far_attack_check_level0_edge		; 0298C jng 0x2995
	db	0x33, 0xC0		; 0298E xor ax,ax
	add	sp,0x6			; 02990
	pop	bp			; 02993
	ret				; 02994
combat_pick_far_attack_check_level0_edge:
	cmp	word [current_level],0x0		; 02995
	jnz	short combat_pick_far_attack_check_left_edge		; 0299A jnz 0x29b1
	mov	ax,[player_x_min]		; 0299C
	db	0x05, 0x0F, 0x00	; 0299F add ax,0xf
	mov	bx,[enemy_x]		; 029A2
	db	0x3B, 0xD8		; 029A6 cmp bx,ax
	jnl	short combat_pick_far_attack_check_left_edge		; 029A8 jnl 0x29b1
	db	0x33, 0xC0		; 029AA xor ax,ax
	add	sp,0x6			; 029AC
	pop	bp			; 029AF
	ret				; 029B0
combat_pick_far_attack_check_left_edge:
	mov	ax,[player_x_min]		; 029B1
	db	0x05, 0x05, 0x00	; 029B4 add ax,0x5
	mov	bx,[enemy_x]		; 029B7
	db	0x3B, 0xD8		; 029BB cmp bx,ax
	jnl	short combat_pick_far_attack_check_followup_anim		; 029BD jnl 0x29c6
	db	0x33, 0xC0		; 029BF xor ax,ax
	add	sp,0x6			; 029C1
	pop	bp			; 029C4
	ret				; 029C5
combat_pick_far_attack_check_followup_anim:
	mov	ax,[enemy_anim_id]		; 029C6
	db	0x3D, 0x07, 0x00	; 029C9 cmp ax,0x7
	jz	short combat_pick_far_attack_check_kick_distance		; 029CC jz 0x29d3
	db	0x3D, 0x0A, 0x00	; 029CE cmp ax,0xa
	jnz	short combat_pick_far_attack_return_standard		; 029D1 jnz 0x29e1
combat_pick_far_attack_check_kick_distance:
	cmp	word [bp+0xa],0x1c	; 029D3
	jng	short combat_pick_far_attack_return_standard		; 029D7 jng 0x29e1
	mov	ax,0xc			; 029D9
	add	sp,0x6			; 029DC
	pop	bp			; 029DF
	ret				; 029E0
combat_pick_far_attack_return_standard:
	mov	ax,0x7			; 029E1
	add	sp,0x6			; 029E4
	pop	bp			; 029E7
	ret				; 029E8

; ---- function anim_frame_update ----
; Returns a small random frame offset for animation variation.
; Input: none
; Output: AX = rand_range(2) + 2, i.e. random value in {2, 3, 4}
; The result is used directly as an animation table index by enemy_ai_decide and anim_process; it is not a frame offset.
anim_frame_update:
	push	bp			; 029E9
	sub	sp,0x2			; 029EA
	jc	short anim_frame_update_stack_overflow		; 029ED jc 0x29f5
	cmp	sp,[stack_limit]		; 029EF
	ja	short anim_frame_update_stack_ok		; 029F3 ja 0x29f8
anim_frame_update_stack_overflow:
	jmp	near stack_overflow_handler			; 029F5
anim_frame_update_stack_ok:
	db	0x8B, 0xEC		; 029F8 mov bp,sp
	mov	ax,0x2			; 029FA
	push	ax			; 029FD
	call	rand_range		; 029FE
	db	0x8B, 0xE5		; 02A01 mov sp,bp
	inc	ax			; 02A03
	inc	ax			; 02A04
	add	sp,0x2			; 02A05
	pop	bp			; 02A08
	ret				; 02A09

; ---- function empty_stub_02A0A ----
; Empty function: sets up and tears down a stack frame, nothing else.
; No call, jump or stored address in the binary targets it.
; Input: none
; Output: none
empty_stub_02A0A:
	push	bp			; 02A0A
	db	0x8B, 0xEC		; 02A0B mov bp,sp
	pop	bp			; 02A0D
	ret				; 02A0E

; ---- function anim_interpolate ----
; Returns a random interpolation offset for smooth animation transitions.
; Input: none
; Output: AX = rand_range(1 or 2) + 4
;   If player_faces_right: range [4, 5] (smoother)
;   Else: range [4, 5, 6]
; The result is used directly as an animation table index by enemy_ai_decide (+0x14 when the enemy is in anim 5-7) and anim_process; no interpolation happens.
anim_interpolate:
	push	bp			; 02A0F
	sub	sp,0x2			; 02A10
	jc	short anim_interpolate_stack_overflow		; 02A13 jc 0x2a1b
	cmp	sp,[stack_limit]		; 02A15
	ja	short anim_interpolate_stack_ok		; 02A19 ja 0x2a1e
anim_interpolate_stack_overflow:
	jmp	near stack_overflow_handler			; 02A1B
anim_interpolate_stack_ok:
	db	0x8B, 0xEC		; 02A1E mov bp,sp
	cmp	word [player_faces_right],0x1		; 02A20
	jnz	short anim_interpolate_not_facing_right		; 02A25 jnz 0x2a38
	mov	ax,0x1			; 02A27
	push	ax			; 02A2A
	call	rand_range		; 02A2B
	db	0x8B, 0xE5		; 02A2E mov sp,bp
	db	0x05, 0x04, 0x00	; 02A30 add ax,0x4
	add	sp,0x2			; 02A33
	pop	bp			; 02A36
	ret				; 02A37
anim_interpolate_not_facing_right:
	mov	ax,0x2			; 02A38
	push	ax			; 02A3B
	call	rand_range		; 02A3C
	db	0x8B, 0xE5		; 02A3F mov sp,bp
	db	0x05, 0x04, 0x00	; 02A41 add ax,0x4
	add	sp,0x2			; 02A44
	pop	bp			; 02A47
	ret				; 02A48

; ---- function anim_process ----
; Player-side animation state machine — decides what player anim to use.
; Mirror of enemy_ai_decide but for the player character.
;
; Input: none (reads global state)
; Output: AX = animation table index for player
; Local: [bp+4] = distance (enemy_x - player_x)
;        [bp+8] = random value
;
; Logic:
;   - combat_active: return 0x1E (approach walk)
;   - If player anim 0x08 (kick): play sound, return 0x0F (block)
;   - If combat_phase == 1 and anim < 0x3F and enemy anim 0x43: random counter
;   - combat_phase == 1: return 0x0F
;   - player_was_hit: knockback 4px, recoil if mid-attack
;   - Distance > 44: call anim_command
;   - Distance <= 44: probability table lookup (3 tiers per level)
;     - Tier 1: idle
;     - Tier 2: interpolate (mid-attack -> +0x14 offset)
;     - Tier 3: anim_frame_update
;     - Tier 4: combat_pick_far_attack (fallback)
; Called from scene_update only when anim_mode [0x156] is nonzero, in place of player_anim_select. Corrections to the tier list: the tables have no per-level component, rand >= table 1 calls anim_command rather than idling, tier 2 applies no +0x14 offset, and the fallback is anim_command rather than combat_pick_far_attack.
anim_process:
	push	bp			; 02A49
	sub	sp,0xa			; 02A4A
	jc	short anim_process_stack_overflow		; 02A4D jc 0x2a55
	cmp	sp,[stack_limit]		; 02A4F
	ja	short anim_process_stack_ok		; 02A53 ja 0x2a58
anim_process_stack_overflow:
	jmp	near stack_overflow_handler			; 02A55
anim_process_stack_ok:
	db	0x8B, 0xEC		; 02A58 mov bp,sp
	cmp	word [combat_active],0x1		; 02A5A
	jnz	short anim_process_compute_distance		; 02A5F jnz 0x2a69
	mov	ax,0x1e			; 02A61
	add	sp,0xa			; 02A64
	pop	bp			; 02A67
	ret				; 02A68
anim_process_compute_distance:
	mov	ax,[enemy_x]		; 02A69
	sub	ax,[player_x]		; 02A6C
	cmp	word [player_anim_id],0x8	; 02A70
	mov	[bp+0x4],ax		; 02A75
	jnz	short anim_process_check_approach_phase		; 02A78 jnz 0x2a8b
	mov	ax,0xb			; 02A7A
	push	ax			; 02A7D
	call	play_sound		; 02A7E
	db	0x8B, 0xE5		; 02A81 mov sp,bp
	mov	ax,0xf			; 02A83
	add	sp,0xa			; 02A86
	pop	bp			; 02A89
	ret				; 02A8A
anim_process_check_approach_phase:
	cmp	word [combat_phase],0x1		; 02A8B
	jnz	short anim_process_check_phase_return_block		; 02A90 jnz 0x2ab8
	cmp	word [player_anim_id],0x3f	; 02A92
	jnl	short anim_process_check_phase_return_block		; 02A97 jnl 0x2ab8
	cmp	word [enemy_anim_id],0x43	; 02A99
	jnz	short anim_process_approach_return_idle		; 02A9E jnz 0x2ab1
	mov	ax,0x1			; 02AA0
	push	ax			; 02AA3
	call	rand_range		; 02AA4
	db	0x8B, 0xE5		; 02AA7 mov sp,bp
	db	0x05, 0x11, 0x00	; 02AA9 add ax,0x11
	add	sp,0xa			; 02AAC
	pop	bp			; 02AAF
	ret				; 02AB0
anim_process_approach_return_idle:
	db	0x33, 0xC0		; 02AB1 xor ax,ax
	add	sp,0xa			; 02AB3
	pop	bp			; 02AB6
	ret				; 02AB7
anim_process_check_phase_return_block:
	cmp	word [combat_phase],0x1		; 02AB8
	jnz	short anim_process_check_player_hit		; 02ABD jnz 0x2ac7
	mov	ax,0xf			; 02ABF
	add	sp,0xa			; 02AC2
	pop	bp			; 02AC5
	ret				; 02AC6
anim_process_check_player_hit:
	cmp	word [player_was_hit],0x1		; 02AC7
	jnz	short anim_process_check_distance		; 02ACC jnz 0x2af5
	mov	word [player_was_hit],0x0		; 02ACE
	sub	word [player_x],0x4	; 02AD4
	mov	ax,[player_anim_id]		; 02AD9
	db	0x3D, 0x04, 0x00	; 02ADC cmp ax,0x4
	jng	short anim_process_hit_return_idle		; 02ADF jng 0x2aee
	db	0x3D, 0x08, 0x00	; 02AE1 cmp ax,0x8
	jnl	short anim_process_hit_return_idle		; 02AE4 jnl 0x2aee
	mov	ax,0x1b			; 02AE6
	add	sp,0xa			; 02AE9
	pop	bp			; 02AEC
	ret				; 02AED
anim_process_hit_return_idle:
	db	0x33, 0xC0		; 02AEE xor ax,ax
	add	sp,0xa			; 02AF0
	pop	bp			; 02AF3
	ret				; 02AF4
anim_process_check_distance:
	cmp	word [bp+0x4],0x2c	; 02AF5
	jng	short anim_process_roll_random		; 02AF9 jng 0x2b08
	push	word [bp+0x4]		; 02AFB
	call	anim_command		; 02AFE
	db	0x8B, 0xE5		; 02B01 mov sp,bp
	add	sp,0xa			; 02B03
	pop	bp			; 02B06
	ret				; 02B07
anim_process_roll_random:
	mov	ax,0xff			; 02B08
	push	ax			; 02B0B
	call	rand_range		; 02B0C
	db	0x8B, 0xE5		; 02B0F mov sp,bp
	cmp	word [bp+0x4],0x1c	; 02B11
	mov	[bp+0x8],ax		; 02B15
	jnl	short anim_process_check_command_tier		; 02B18 jnl 0x2b1f
	mov	word [bp+0x4],0x1c	; 02B1A
; Tables are indexed by (distance-0x1C)/4*2 only; unlike enemy_ai_decide there is no per-level component.
anim_process_check_command_tier:
	mov	ax,[bp+0x4]		; 02B1F
	db	0x2D, 0x1C, 0x00	; 02B22 sub ax,0x1c
	mov	bx,0x4			; 02B25
	cwd				; 02B28
	idiv	bx			; 02B29
	shl	ax,1			; 02B2B
	db	0x8B, 0xF0		; 02B2D mov si,ax
	mov	ax,[bp+0x8]		; 02B2F
	cmp	ax,[si+close_tier1_thresholds_player]		; 02B32
	jl	short anim_process_check_interpolate_tier		; 02B36 jl 0x2b45
	push	word [bp+0x4]		; 02B38
	call	anim_command		; 02B3B
	db	0x8B, 0xE5		; 02B3E mov sp,bp
	add	sp,0xa			; 02B40
	pop	bp			; 02B43
	ret				; 02B44
anim_process_check_interpolate_tier:
	mov	ax,[bp+0x4]		; 02B45
	db	0x2D, 0x1C, 0x00	; 02B48 sub ax,0x1c
	mov	bx,0x4			; 02B4B
	cwd				; 02B4E
	idiv	bx			; 02B4F
	shl	ax,1			; 02B51
	db	0x8B, 0xF0		; 02B53 mov si,ax
	mov	ax,[bp+0x8]		; 02B55
	cmp	ax,[si+close_tier2_thresholds_player]		; 02B58
	jl	short anim_process_check_frame_update_tier		; 02B5C jl 0x2b66
	call	anim_interpolate	; 02B5E
	add	sp,0xa			; 02B61
	pop	bp			; 02B64
	ret				; 02B65
anim_process_check_frame_update_tier:
	mov	ax,[bp+0x4]		; 02B66
	db	0x2D, 0x1C, 0x00	; 02B69 sub ax,0x1c
	mov	bx,0x4			; 02B6C
	cwd				; 02B6F
	idiv	bx			; 02B70
	shl	ax,1			; 02B72
	db	0x8B, 0xF0		; 02B74 mov si,ax
	mov	ax,[bp+0x8]		; 02B76
	cmp	ax,[si+close_tier3_thresholds_player]		; 02B79
	jl	short anim_process_fallback_command		; 02B7D jl 0x2b87
	call	anim_frame_update	; 02B7F
	add	sp,0xa			; 02B82
	pop	bp			; 02B85
	ret				; 02B86
anim_process_fallback_command:
	push	word [bp+0x4]		; 02B87
	call	anim_command		; 02B8A
	db	0x8B, 0xE5		; 02B8D mov sp,bp
	add	sp,0xa			; 02B8F
	pop	bp			; 02B92
	ret				; 02B93

; ---- function anim_command ----
; Final attack/advance decision for player when close to enemy.
;
; Input: [bp+6] = distance between player and enemy
; Output: AX = animation index
;
; Logic:
;   - Random(255) > 50 and distance < 75: return 0 (hesitate)
;   - If player anim is 8 (kick) or 0xB (charge): return 0x0D (counter)
;   - Default: return 0x08 (kick)
anim_command:
	push	bp			; 02B94
	sub	sp,0x2			; 02B95
	jc	short anim_command_stack_overflow		; 02B98 jc 0x2ba0
	cmp	sp,[stack_limit]		; 02B9A
	ja	short anim_command_stack_ok		; 02B9E ja 0x2ba3
anim_command_stack_overflow:
	jmp	near stack_overflow_handler			; 02BA0
anim_command_stack_ok:
	db	0x8B, 0xEC		; 02BA3 mov bp,sp
	mov	ax,0xff			; 02BA5
	push	ax			; 02BA8
	call	rand_range		; 02BA9
	db	0x8B, 0xE5		; 02BAC mov sp,bp
	db	0x3D, 0x32, 0x00	; 02BAE cmp ax,0x32
	jng	short anim_command_check_followup_anim		; 02BB1 jng 0x2bc0
	cmp	word [bp+0x6],0x4b	; 02BB3
	jnl	short anim_command_check_followup_anim		; 02BB7 jnl 0x2bc0
	db	0x33, 0xC0		; 02BB9 xor ax,ax
	add	sp,0x2			; 02BBB
	pop	bp			; 02BBE
	ret				; 02BBF
anim_command_check_followup_anim:
	mov	ax,[player_anim_id]		; 02BC0
	db	0x3D, 0x08, 0x00	; 02BC3 cmp ax,0x8
	jz	short anim_command_return_counter		; 02BC6 jz 0x2bcd
	db	0x3D, 0x0B, 0x00	; 02BC8 cmp ax,0xb
	jnz	short anim_command_return_kick		; 02BCB jnz 0x2bd5
anim_command_return_counter:
	mov	ax,0xd			; 02BCD
	add	sp,0x2			; 02BD0
	pop	bp			; 02BD3
	ret				; 02BD4
anim_command_return_kick:
	mov	ax,0x8			; 02BD5
	add	sp,0x2			; 02BD8
	pop	bp			; 02BDB
	ret				; 02BDC
