; Level setup, cutscenes, scene transitions
;
; This is the largest game logic module.  It manages combat encounters,
; level transitions, cutscene state machines, and door/gate wipe effects.
;
; Key functions:
;   resolve_hits        - Per-frame combat encounter management
;   anim_set_bg        - Advance to next background/scene area
;   player_strike_special_enemy    - Trigger figure change (enemy entering/leaving)
;   draw_health_bars   - Door-opening wipe effect with gate animation
;   clear_health_pip      - Clear a 7-row column in transition buffer
;   blit_column_data   - Copy 7 words with CGA scanline stride
;   blit_transition_col_left/right - Compute screen position and blit
;   cutscene_play      - Main cutscene/level-progression state machine


; ---- function resolve_hits ----
; Per-frame hit resolution, called once per frame after scene_update (00333, 00500).
; Variable note: [0x114] is the enemy's hit points and [0x116] the player's. [0x11e]/[0x128]/[0x11c] are the enemy's pending regen, timer and rate; [0x124]/[0x126]/[0x120] the player's, with [0x122] the player's normal rate.
;
; Flow (no meaningful return value; the frame loops ignore AX):
; 1. combat_active > 0: return at once.
; 2. [bp+4] = enemy_x - player_x. Step 3 runs only when player_facing == 1.
; 3. Player side:
;    - special_enemy_active == 1: enemy anim 0x1F, distance 0x14..0x1B and a stance matching enemy_y_off (anim 4/7 at 0x18, 3/6 at 0x0C, 2/5 at 0) call player_strike_special_enemy.
;    - else combat_phase > 0 (no live enemy): with no exit already pending, player_x > 0xEC and level > 2, anim < 5 only sets approach_flag = 1; otherwise anim_set_bg opens the exit. At scene_index 5 that also calls activate_enemy, sets [0x114] = 5, enemy_x = player_x_max + 16, and [0x120] = [0x122].
;    - else check_hit_zone(player anim - 2, distance, [0xd5b0]). Result 4 recoils the enemy unless scene_index is 6. Result 2 or 3 is a landed strike: --[0x114]. At 0 the enemy gets its death sequence (table entry 28), combat_phase = 1, approach_flag = 2 and [0x11e] = 0, and any player regen speeds up ([0x126] = [0x120] = 2). Otherwise enemy anims 0x0C..0x11 recoil unless scene_index is 6, [0x128] += 3, ++[0x11e], enemy_was_hit = 1.
; 4. Enemy regen: while [0x11e] > 0 and [0x114] + [0x116] < 0x1A, count [0x128] down; at 0, ++[0x114], --[0x11e], [0x128] = [0x11c].
; 5. Enemy side, only when enemy_facing == 1. scene_index 7 forces [0x116] = 1 and a landed strike. Otherwise check_hit_zone(enemy anim - 2, distance, [0xd5ae]), with distance - 4 for enemy anim 7; result 4 recoils the player if player_x > player_x_min. A strike lands on result 2 or 3, enemy anim 0x21, or player anim > 0x3F: --[0x116]. At 0, or with player anim > 0x3F, combat_active = 1 and the player gets anim 0x44 and the death sequence, unless already in anim 0x44. Otherwise player anims 0x0F..0x11 (or enemy anim 0x21) recoil, [0x126] += 3, ++[0x124], player_was_hit = 1.
; 6. combat_active > 0 now: return 0. Otherwise player regen, as step 4 with [0x124]/[0x126]/[0x120]; when [0x124] reaches 0, [0x120] = [0x122].
resolve_hits:
	push	bp			; 02BDD
	sub	sp,0x8			; 02BDE
	jc	short resolve_hits_stack_overflow		; 02BE1 jc 0x2be9
	cmp	sp,[stack_limit]		; 02BE3  stack overflow check
	ja	short resolve_hits_stack_ok		; 02BE7 ja 0x2bec
resolve_hits_stack_overflow:
	jmp	near stack_overflow_handler			; 02BE9  stack overflow handler
resolve_hits_stack_ok:
	db	0x8B, 0xEC		; 02BEC mov bp,sp
	cmp	word [combat_active],0x0		; 02BEE  combat_active?
	jng	short resolve_hits_compute_distance		; 02BF3 jng 0x2bfc
	db	0x33, 0xC0		; 02BF5 xor ax,ax  return 0
	add	sp,0x8			; 02BF7
	pop	bp			; 02BFA
	ret				; 02BFB

resolve_hits_compute_distance:
; Compute distance = enemy_x - player_x
	mov	ax,[enemy_x]		; 02BFC  ax = enemy_x
	sub	ax,[player_x]		; 02BFF  ax -= player_x
	cmp	word [player_facing],0x1		; 02C03  player_facing right?
	mov	[bp+0x4],ax		; 02C08  [bp+4] = distance
	jz	short resolve_hits_player_facing_right		; 02C0B jz 0x2c10  yes, handle player-facing-right
	jmp	near resolve_hits_regen_player_health			; 02C0D  jump to enemy-facing-player section

; --- Player facing right: active enemy encounter ---
resolve_hits_player_facing_right:
	cmp	word [special_enemy_active],0x1	; 02C10  special_enemy_active?
	jnz	short resolve_hits_no_eagle_active		; 02C15 jnz 0x2c85  no active enemy

; Check if enemy is at specific animation states to trigger figure change
	cmp	word [enemy_anim_id],0x1f	; 02C17  enemy_anim_id == 0x1F?
	jz	short resolve_hits_eagle_check_min_range		; 02C1C jz 0x2c21
	jmp	near resolve_hits_regen_player_health			; 02C1E

resolve_hits_eagle_check_min_range:
; Distance check: must be in range [0x14..0x1B]
	db	0x3D, 0x13, 0x00	; 02C21 cmp ax,0x13
	jg	short resolve_hits_eagle_check_max_range		; 02C24 jg 0x2c29
	jmp	near resolve_hits_regen_player_health			; 02C26
resolve_hits_eagle_check_max_range:
	db	0x3D, 0x1C, 0x00	; 02C29 cmp ax,0x1c
	jl	short resolve_hits_eagle_in_range_check_stance		; 02C2C jl 0x2c31
	jmp	near resolve_hits_regen_player_health			; 02C2E

resolve_hits_eagle_in_range_check_stance:
; Check player animation state: standing (4) or crouching (7)
	mov	ax,[player_anim_id]		; 02C31  player_anim_id
	db	0x3D, 0x04, 0x00	; 02C34 cmp ax,0x4
	jz	short resolve_hits_stance_matches_eagle_height_24		; 02C37 jz 0x2c3e
	db	0x3D, 0x07, 0x00	; 02C39 cmp ax,0x7
	jnz	short resolve_hits_try_eagle_height_12		; 02C3C jnz 0x2c4b
resolve_hits_stance_matches_eagle_height_24:
	cmp	word [enemy_y_off],0x18	; 02C3E  enemy_y_off == 0x18?
	jnz	short resolve_hits_try_eagle_height_12		; 02C43 jnz 0x2c4b
	call	player_strike_special_enemy		; 02C45  trigger figure change
	jmp	near resolve_hits_regen_player_health			; 02C48
resolve_hits_try_eagle_height_12:
; Check player anim: walking (3) or retreating (6)
	mov	ax,[player_anim_id]		; 02C4B
	db	0x3D, 0x03, 0x00	; 02C4E cmp ax,0x3
	jz	short resolve_hits_stance_matches_eagle_height_12		; 02C51 jz 0x2c58
	db	0x3D, 0x06, 0x00	; 02C53 cmp ax,0x6
	jnz	short resolve_hits_try_eagle_height_0		; 02C56 jnz 0x2c65
resolve_hits_stance_matches_eagle_height_12:
	cmp	word [enemy_y_off],0xc	; 02C58  enemy_y_off == 0x0C?
	jnz	short resolve_hits_try_eagle_height_0		; 02C5D jnz 0x2c65
	call	player_strike_special_enemy		; 02C5F
	jmp	near resolve_hits_regen_player_health			; 02C62
resolve_hits_try_eagle_height_0:
; Check player anim: attacking (2) or kicking (5)
	mov	ax,[player_anim_id]		; 02C65
	db	0x3D, 0x02, 0x00	; 02C68 cmp ax,0x2
	jz	short resolve_hits_stance_matches_eagle_height_0		; 02C6B jz 0x2c75
	db	0x3D, 0x05, 0x00	; 02C6D cmp ax,0x5
	jz	short resolve_hits_stance_matches_eagle_height_0		; 02C70 jz 0x2c75
	jmp	near resolve_hits_regen_player_health			; 02C72
resolve_hits_stance_matches_eagle_height_0:
	cmp	word [enemy_y_off],0x0	; 02C75  enemy_y_off == 0?
	jz	short resolve_hits_eagle_struck_at_height_0		; 02C7A jz 0x2c7f
	jmp	near resolve_hits_regen_player_health			; 02C7C
resolve_hits_eagle_struck_at_height_0:
	call	player_strike_special_enemy		; 02C7F
	jmp	near resolve_hits_regen_player_health			; 02C82

; --- No active enemy: handle combat_phase and approach ---
resolve_hits_no_eagle_active:
	cmp	word [combat_phase],0x0		; 02C85  combat_phase > 0?
	jng	short resolve_hits_check_player_strike		; 02C8A jng 0x2cfb  no, handle hit detection
	cmp	word [draw_health_bars_pending],0x0	; 02C8C  draw_health_bars_pending?
	jz	short resolve_hits_exit_closed_check_player_x		; 02C91 jz 0x2c96
	jmp	near resolve_hits_regen_player_health			; 02C93

resolve_hits_exit_closed_check_player_x:
; Gate opening / approach: player must be past X=0xEC and level > 2
	cmp	word [player_x],0xec	; 02C96  player_x > 0xEC?
	jg	short resolve_hits_at_right_edge_check_level		; 02C9C jg 0x2ca1
	jmp	near resolve_hits_regen_player_health			; 02C9E
resolve_hits_at_right_edge_check_level:
	cmp	word [current_level],0x2		; 02CA1  current_level > 2?
	jg	short resolve_hits_at_right_edge_check_anim		; 02CA6 jg 0x2cab
	jmp	near resolve_hits_regen_player_health			; 02CA8

resolve_hits_at_right_edge_check_anim:
; Check if player is in approach animation (< 5)
	cmp	word [player_anim_id],0x5	; 02CAB  player_anim_id < 5?
	jnl	short resolve_hits_open_exit_advance_background		; 02CB0 jnl 0x2cbb
	mov	word [approach_flag],0x1	; 02CB2  approach_flag = 1 (approaching)
	jmp	near resolve_hits_regen_player_health			; 02CB8

resolve_hits_open_exit_advance_background:
; Advance background and update position
	call	anim_set_bg		; 02CBB
	mov	ax,[player_anim_id]		; 02CBE  player_anim_id
	dec	ax			; 02CC1
	dec	ax			; 02CC2  anim_id - 2
	push	ax			; 02CC3
	db	0x33, 0xC0		; 02CC4 xor ax,ax
	push	ax			; 02CC6  actor=0 (player)
	call	add_figure_to_scene		; 02CC7
	db	0x8B, 0xE5		; 02CCA mov sp,bp

; If scene_index == 5: scroll right and set up encounter
	cmp	word [scene_index],0x5	; 02CCC  scene_index == 5?
	jz	short resolve_hits_scene_5_spawn_eagle		; 02CD1 jz 0x2cd6
	jmp	near resolve_hits_regen_player_health			; 02CD3
resolve_hits_scene_5_spawn_eagle:
	call	activate_enemy	; 02CD6
	mov	word [enemy_hit_points],0x5	; 02CD9  enemy_hit_points = 5
	mov	ax,[player_regen_rate_init]		; 02CDF  player_regen_rate_init
	mov	bx,[player_x_max]		; 02CE2  player_x_max
	add	bx,0x10			; 02CE6  enemy spawns 16 pixels past max
	mov	cx,[player_seq_long_recoil]		; 02CE9  animation lookup
	mov	[player_regen_rate],ax		; 02CED  player_regen_rate = initial rate
	mov	[player_frame_ptr],cx		; 02CF0  player_frame_ptr
	mov	[enemy_x],bx		; 02CF4  enemy_x = player_x_max + 16
	jmp	near resolve_hits_regen_player_health			; 02CF8

; --- Apply gravity / hit detection for player ---
resolve_hits_check_player_strike:
	mov	ax,[player_anim_id]		; 02CFB  player_anim_id
	dec	ax			; 02CFE
	dec	ax			; 02CFF  anim_id - 2
	push	word [enemy_frame_attr]		; 02D00  enemy_frame_attr
	push	word [bp+0x4]		; 02D04  distance
	push	ax			; 02D07  adjusted anim_id
	call	check_hit_zone		; 02D08
	db	0x8B, 0xE5		; 02D0B mov sp,bp
	db	0x3D, 0x04, 0x00	; 02D0D cmp ax,0x4  hit result == 4?
	mov	[bp+0x6],ax		; 02D10  save result
	jnz	short resolve_hits_test_player_strike_landed		; 02D13 jnz 0x2d22
	cmp	word [scene_index],0x6	; 02D15  scene_index != 6?
	jz	short resolve_hits_test_player_strike_landed		; 02D1A jz 0x2d22
	mov	ax,[enemy_seq_recoil]		; 02D1C  update enemy frame pointer
	mov	[enemy_frame_ptr],ax		; 02D1F
resolve_hits_test_player_strike_landed:
	mov	ax,[bp+0x6]		; 02D22  gravity result
	db	0x3D, 0x02, 0x00	; 02D25 cmp ax,0x2  player hit?
	jz	short resolve_hits_enemy_struck		; 02D28 jz 0x2d32
	db	0x3D, 0x03, 0x00	; 02D2A cmp ax,0x3  player hit (alternate)?
	jz	short resolve_hits_enemy_struck		; 02D2D jz 0x2d32
	jmp	0x2fb0			; 02D2F

; --- Player was hit: decrement hits, manage approach state ---
resolve_hits_enemy_struck:
	mov	ax,0x1			; 02D32
	mov	bx,[enemy_hit_points]		; 02D35  enemy_hit_points
	dec	bx			; 02D39
	test	bx,bx			; 02D3A
	mov	[approach_flag],ax		; 02D3C  approach_flag = 1
	mov	[enemy_hit_points],bx		; 02D3F  --enemy_hit_points
	jnz	short resolve_hits_enemy_survived_strike		; 02D43 jnz 0x2d79  still has hits

; Player hits exhausted: transition to retreat
	mov	word [approach_flag],0x2	; 02D45  approach_flag = 2 (retreat)
	mov	word [enemy_regen_pending],0x0	; 02D4B  enemy_regen_pending = 0
	cmp	word [player_faces_right],0x1		; 02D51  player_faces_right?
	mov	[player_flag_174],ax		; 02D56  player_flag_174 = 1
	mov	[combat_phase],ax		; 02D59  combat_phase = 1
	jnz	short resolve_hits_enemy_defeated_check_player_regen		; 02D5C jnz 0x2d61
	mov	[player_flag_170],ax		; 02D5E  player_flag_170 = 1 (if facing right)
resolve_hits_enemy_defeated_check_player_regen:
; Set up health regen for enemy if recovering
	cmp	word [player_regen_pending],0x0	; 02D61  player_regen_pending > 0?
	jng	short resolve_hits_enemy_defeated_set_frame		; 02D66 jng 0x2d71
	mov	ax,0x2			; 02D68
	mov	[player_regen_timer],ax		; 02D6B  player_regen_timer = 2
	mov	[player_regen_rate],ax		; 02D6E  player_regen_rate = 2
resolve_hits_enemy_defeated_set_frame:
	mov	ax,[enemy_seq_death]		; 02D71  animation frame for retreat
	mov	[enemy_frame_ptr],ax		; 02D74  enemy_frame_ptr = retreat frame
	jmp	short resolve_hits_add_player_strike_figure		; 02D77 jmp 0x2da2

resolve_hits_enemy_survived_strike:
; Player still has hits: check if enemy is in recoil animation
	mov	ax,[enemy_anim_id]		; 02D79  enemy_anim_id
	db	0x3D, 0x0B, 0x00	; 02D7C cmp ax,0xb
	jng	short resolve_hits_queue_enemy_regen		; 02D7F jng 0x2d93
	db	0x3D, 0x12, 0x00	; 02D81 cmp ax,0x12
	jnl	short resolve_hits_queue_enemy_regen		; 02D84 jnl 0x2d93
	cmp	word [scene_index],0x6	; 02D86  scene_index != 6?
	jz	short resolve_hits_queue_enemy_regen		; 02D8B jz 0x2d93
	mov	ax,[enemy_seq_recoil]		; 02D8D  update enemy frame
	mov	[enemy_frame_ptr],ax		; 02D90

resolve_hits_queue_enemy_regen:
; Advance player health regen timer
	add	word [enemy_regen_timer],0x3	; 02D93  enemy_regen_timer += 3
	inc	word [enemy_regen_pending]		; 02D98  ++enemy_regen_pending
	mov	word [enemy_was_hit],0x1		; 02D9C  enemy_was_hit = 1

resolve_hits_add_player_strike_figure:
; Update player position after hit
	mov	ax,[player_anim_id]		; 02DA2  player_anim_id
	dec	ax			; 02DA5
	dec	ax			; 02DA6
	push	ax			; 02DA7
	db	0x33, 0xC0		; 02DA8 xor ax,ax
	push	ax			; 02DAA  actor=0 (player)
	call	add_figure_to_scene		; 02DAB
	db	0x8B, 0xE5		; 02DAE mov sp,bp

; --- Player health regeneration ---
; common join after the player-facing block; existing comment confirms player regen
resolve_hits_regen_player_health:
	mov	ax,[enemy_regen_pending]		; 02DB0  enemy_regen_pending
	test	ax,ax			; 02DB3
	jng	short resolve_hits_check_enemy_facing		; 02DB5 jng 0x2de1  no hits to regenerate
	mov	bx,[enemy_hit_points]		; 02DB7  enemy_hit_points
	mov	cx,[player_hit_points]		; 02DBB  player_hit_points
	db	0x03, 0xCB		; 02DBF add cx,bx  total health remaining
	cmp	cx,0x1a			; 02DC1  max total health cap?
	jnl	short resolve_hits_check_enemy_facing		; 02DC4 jnl 0x2de1  at cap, no regen
	mov	cx,[enemy_regen_timer]		; 02DC6  enemy_regen_timer
	dec	cx			; 02DCA
	test	cx,cx			; 02DCB
	mov	[enemy_regen_timer],cx		; 02DCD  --timer
	jnz	short resolve_hits_check_enemy_facing		; 02DD1 jnz 0x2de1  timer not expired
; Regenerate one hit point for player
	inc	word [enemy_hit_points]		; 02DD3  ++enemy_hit_points
	dec	word [enemy_regen_pending]		; 02DD7  --enemy_regen_pending
	mov	ax,[enemy_regen_rate]		; 02DDB  enemy_regen_rate
	mov	[enemy_regen_timer],ax		; 02DDE  reset timer to rate
resolve_hits_check_enemy_facing:

; --- Enemy facing player: hit detection ---
	cmp	word [enemy_facing],0x1	; 02DE1  enemy_facing == 1?
	jz	short resolve_hits_enemy_facing_player		; 02DE6 jz 0x2deb
	jmp	near resolve_hits_check_combat_over			; 02DE8  skip to return section

resolve_hits_enemy_facing_player:
; Special case: scene_index == 7 (final encounter)
	cmp	word [scene_index],0x7	; 02DEB
	jnz	short resolve_hits_check_enemy_strike		; 02DF0 jnz 0x2dff
	mov	word [player_hit_points],0x1	; 02DF2  player_hit_points = 1
	mov	word [bp+0x6],0x3	; 02DF8  force hit result
	jmp	short resolve_hits_resolve_enemy_strike		; 02DFD jmp 0x2e39

resolve_hits_check_enemy_strike:
; Check enemy animation for hit conditions
	mov	ax,[enemy_anim_id]		; 02DFF  enemy_anim_id
	db	0x3D, 0x21, 0x00	; 02E02 cmp ax,0x21  special anim?
	jz	short resolve_hits_resolve_enemy_strike		; 02E05 jz 0x2e39
	db	0x3D, 0x07, 0x00	; 02E07 cmp ax,0x7  retreating?
	jnz	short resolve_hits_test_enemy_strike		; 02E0A jnz 0x2e10
	sub	word [bp+0x4],0x4	; 02E0C  adjust distance for retreat
resolve_hits_test_enemy_strike:
; Apply gravity for enemy
	mov	ax,[enemy_anim_id]		; 02E10  enemy_anim_id
	dec	ax			; 02E13
	dec	ax			; 02E14
	push	word [player_frame_attr]		; 02E15  player_frame_attr
	push	word [bp+0x4]		; 02E19  distance
	push	ax			; 02E1C  adjusted anim_id
	call	check_hit_zone		; 02E1D
	db	0x8B, 0xE5		; 02E20 mov sp,bp
	db	0x3D, 0x04, 0x00	; 02E22 cmp ax,0x4  hit result == 4?
	mov	[bp+0x6],ax		; 02E25
	jnz	short resolve_hits_resolve_enemy_strike		; 02E28 jnz 0x2e39
; Update animation when player is past boundary
	mov	ax,[player_x]		; 02E2A  player_x
	cmp	ax,[player_x_min]		; 02E2D  player_x_min?
	jng	short resolve_hits_resolve_enemy_strike		; 02E31 jng 0x2e39
	mov	ax,[player_seq_recoil]		; 02E33
	mov	[player_frame_ptr],ax		; 02E36  update player_frame_ptr

resolve_hits_resolve_enemy_strike:
; Check if enemy died or was hit
	cmp	word [enemy_anim_id],0x21	; 02E39  enemy_anim_id == 0x21 (death)?
	jz	short resolve_hits_player_struck		; 02E3E jz 0x2e56
	cmp	word [bp+0x6],0x2	; 02E40  hit result == 2?
	jz	short resolve_hits_player_struck		; 02E44 jz 0x2e56
	cmp	word [bp+0x6],0x3	; 02E46  hit result == 3?
	jz	short resolve_hits_player_struck		; 02E4A jz 0x2e56
	cmp	word [player_anim_id],0x3f	; 02E4C  player_anim_id > 0x3F (dead)?
	jg	short resolve_hits_player_struck		; 02E51 jg 0x2e56
	jmp	near resolve_hits_check_combat_over			; 02E53

resolve_hits_player_struck:
; Set approach flag if not already set
	cmp	word [approach_flag],0x0	; 02E56  approach_flag == 0?
	jnz	short resolve_hits_decrement_player_health		; 02E5B jnz 0x2e63
	mov	word [approach_flag],0x1	; 02E5D  approach_flag = 1

resolve_hits_decrement_player_health:
; Decrement enemy health
	mov	ax,[player_hit_points]		; 02E63  player_hit_points
	dec	ax			; 02E66
	test	ax,ax			; 02E67
	mov	[player_hit_points],ax		; 02E69
	jz	short resolve_hits_player_killed		; 02E6C jz 0x2e75  enemy health reached 0
	cmp	word [player_anim_id],0x3f	; 02E6E  player alive?
	jng	short resolve_hits_player_survived_strike		; 02E73 jng 0x2e90

resolve_hits_player_killed:
; Enemy defeated or player dead
	cmp	word [player_anim_id],0x44	; 02E75  already in death anim?
	jz	short resolve_hits_player_survived_strike		; 02E7A jz 0x2e90
	mov	word [combat_active],0x1		; 02E7C  combat_active = 1 (combat over)
	mov	ax,[player_seq_death]		; 02E82  death animation frame
	mov	word [player_anim_id],0x44	; 02E85  player_anim_id = death
	mov	[player_frame_ptr],ax		; 02E8B  player_frame_ptr = death frame
	jmp	short resolve_hits_add_enemy_strike_figure		; 02E8E jmp 0x2eb9

resolve_hits_player_survived_strike:
; Enemy still alive: check for recoil animations
	mov	ax,[player_anim_id]		; 02E90  player_anim_id
	db	0x3D, 0x0E, 0x00	; 02E93 cmp ax,0xe  mid-kick?
	jng	short resolve_hits_check_enemy_forced_hit_anim		; 02E96 jng 0x2e9d
	db	0x3D, 0x12, 0x00	; 02E98 cmp ax,0x12
	jl	short resolve_hits_set_player_recoil_frame		; 02E9B jl 0x2ea4
resolve_hits_check_enemy_forced_hit_anim:
	cmp	word [enemy_anim_id],0x21	; 02E9D  enemy death anim?
	jnz	short resolve_hits_queue_player_regen		; 02EA2 jnz 0x2eaa
resolve_hits_set_player_recoil_frame:
	mov	ax,[player_seq_recoil]		; 02EA4
	mov	[player_frame_ptr],ax		; 02EA7  update player frame

resolve_hits_queue_player_regen:
; Advance enemy health regen timer
	add	word [player_regen_timer],0x3	; 02EAA  player_regen_timer += 3
	inc	word [player_regen_pending]		; 02EAF  ++player_regen_pending
	mov	word [player_was_hit],0x1		; 02EB3  player_was_hit = 1

resolve_hits_add_enemy_strike_figure:
; Update enemy position after combat resolution
	cmp	word [scene_index],0x7	; 02EB9  scene_index == 7 (final)?
	jnz	short resolve_hits_add_enemy_recoil_figure		; 02EBE jnz 0x2ecf
	mov	ax,0x9			; 02EC0  special anim for final encounter
	push	ax			; 02EC3
	mov	ax,0x1			; 02EC4  actor=1 (enemy)
	push	ax			; 02EC7
	call	add_figure_to_scene		; 02EC8
	db	0x8B, 0xE5		; 02ECB mov sp,bp
	jmp	short resolve_hits_check_combat_over		; 02ECD jmp 0x2edf
resolve_hits_add_enemy_recoil_figure:
	mov	ax,[enemy_anim_id]		; 02ECF  enemy_anim_id
	db	0x05, 0x04, 0x00	; 02ED2 add ax,0x4  offset for recoil
	push	ax			; 02ED5
	mov	ax,0x1			; 02ED6  actor=1 (enemy)
	push	ax			; 02ED9
	call	add_figure_to_scene		; 02EDA
	db	0x8B, 0xE5		; 02EDD mov sp,bp

resolve_hits_check_combat_over:
; If combat just ended, return 0
	cmp	word [combat_active],0x0		; 02EDF  combat_active?
	jng	short resolve_hits_player_regen		; 02EE4 jng 0x2eed
	db	0x33, 0xC0		; 02EE6 xor ax,ax
	add	sp,0x8			; 02EE8
	pop	bp			; 02EEB
	ret				; 02EEC

resolve_hits_player_regen:
; --- Enemy health regeneration ---
	mov	ax,[player_regen_pending]		; 02EED  player_regen_pending
	test	ax,ax			; 02EF0
	jng	short resolve_hits_exit		; 02EF2 jng 0x2f28  nothing to regen
	mov	bx,[player_hit_points]		; 02EF4  player_hit_points
	mov	cx,[enemy_hit_points]		; 02EF8  enemy_hit_points
	db	0x03, 0xCB		; 02EFC add cx,bx  total health
	cmp	cx,0x1a			; 02EFE  health cap
	jnl	short resolve_hits_exit		; 02F01 jnl 0x2f28  at cap
	mov	cx,[player_regen_timer]		; 02F03  player_regen_timer
	dec	cx			; 02F07
	test	cx,cx			; 02F08
	mov	[player_regen_timer],cx		; 02F0A  --timer
	jnz	short resolve_hits_exit		; 02F0E jnz 0x2f28  timer not expired
; Regenerate one hit point for enemy
	inc	word [player_hit_points]		; 02F10  ++player_hit_points
	dec	ax			; 02F14  --player_regen_pending
	test	ax,ax			; 02F15
	mov	[player_regen_pending],ax		; 02F17
	jnz	short resolve_hits_reset_player_regen_timer		; 02F1A jnz 0x2f22
	mov	ax,[player_regen_rate_init]		; 02F1C  player_regen_rate_init
	mov	[player_regen_rate],ax		; 02F1F  reset rate to initial
resolve_hits_reset_player_regen_timer:
	mov	ax,[player_regen_rate]		; 02F22  player_regen_rate
	mov	[player_regen_timer],ax		; 02F25  reset timer

resolve_hits_exit:
	add	sp,0x8			; 02F28
	pop	bp			; 02F2B
	ret				; 02F2C

; ---- function anim_set_bg ----
; Advance to the next background/scene area.
; Increments background scene counter, loads new animation divisors
; from lookup tables, sets draw_health_bars_pending=1, and marks
; the current scene slot as active.
anim_set_bg:
	push	bp			; 02F2D
	sub	sp,0x4			; 02F2E
	jc	short anim_set_bg_stack_overflow		; 02F31 jc 0x2f39
	cmp	sp,[stack_limit]		; 02F33  stack overflow check
	ja	short anim_set_bg_stack_ok		; 02F37 ja 0x2f3c
anim_set_bg_stack_overflow:
	jmp	near stack_overflow_handler			; 02F39
anim_set_bg_stack_ok:
	db	0x8B, 0xEC		; 02F3C mov bp,sp
	add	word [player_x_max],0x14	; 02F3E  player_x_max += 20
	mov	ax,[scene_index]		; 02F43  scene_index
	shl	ax,1			; 02F46  * 2 for word index
	db	0x8B, 0xF0		; 02F48 mov si,ax
	mov	ax,0x1			; 02F4A
	mov	[si+scene_slot_flags],ax		; 02F4D  scene_slot_flags[scene_index] = 1
	mov	bx,[anim_bg_counter]		; 02F51  anim_bg_counter
	inc	bx			; 02F55
	mov	[anim_bg_counter],bx		; 02F56  ++anim_bg_counter
	shl	bx,1			; 02F5A  * 2 for word index
	mov	cx,[bx+scenery_row_middles]		; 02F5C  lookup table A (animation divisor)
	mov	bx,[anim_bg_counter]		; 02F60  anim_bg_counter (reload)
	shl	bx,1			; 02F64
	mov	dx,[bx+scenery_row_starts]		; 02F66  lookup table B
	mov	[draw_health_bars_pending],ax		; 02F6A  draw_health_bars_pending = 1
	mov	ax,[bx+scenery_row_ends]		; 02F6D  lookup table C
	mov	word [approach_flag],0x1	; 02F71  approach_flag = 1
	mov	word [anim_render_mode],0x2		; 02F77  anim_render_mode = transition
	mov	bx,0xffff		; 02F7D
	mov	[scenery_row_end_ptr],ax		; 02F80  store animation param C
	mov	[scenery_row_mid_ptr],cx		; 02F83  scenery_row_mid_ptr = table A value
	mov	[scenery_row_start_ptr],dx		; 02F87  scenery_row_start_ptr = table B value
	mov	[wipe_prev_left],bx		; 02F8B  wipe_prev_left = 0xFFFF (force redraw)
	mov	[last_drawn_camera_x],bx		; 02F8F  anim_state = no animation
	add	sp,0x4			; 02F93
	pop	bp			; 02F96
	ret				; 02F97

; ---- function player_strike_special_enemy ----
; The player's strike on the special enemy (the one activate_enemy starts in anim 0x1F).
; Called only from resolve_hits, when that enemy is in range and the player's stance matches enemy_y_off.
; Sets approach_flag = 3, a selector the frame loops act on.
; Level 3 only: --[0x114] (the special enemy's hits, set to 5 in resolve_hits). When it reaches 0: approach_flag = 4, enemy_frame_ptr = sequence table entry 34, enemy_y_off 0 becomes 12, and the player's health [0x116] is capped at 10 with [0x124] = any deficit below 10 (0 if it was capped).
; Otherwise, on any level, enemy_was_hit = 1.
; Always ends with add_figure_to_scene(0, player anim - 2), the same call a normal landed strike makes.
player_strike_special_enemy:
	push	bp			; 02F98
	sub	sp,0x2			; 02F99
	jc	short player_strike_special_enemy_stack_overflow		; 02F9C jc 0x2fa4
	cmp	sp,[stack_limit]		; 02F9E  stack overflow check
	ja	short player_strike_special_enemy_stack_ok		; 02FA2 ja 0x2fa7
player_strike_special_enemy_stack_overflow:
	jmp	near stack_overflow_handler			; 02FA4
player_strike_special_enemy_stack_ok:
	db	0x8B, 0xEC		; 02FA7 mov bp,sp
	mov	ax,0x3			; 02FA9
	cmp	word [current_level],0x3		; 02FAC  current_level == 3 (final boss)?
	mov	[approach_flag],ax		; 02FB1  approach_flag = 3 (trigger)
	jnz	short player_strike_special_enemy_other_level_mark_hit		; 02FB4 jnz 0x3003  not level 3

; --- Level 3 specific: countdown hits and cap health ---
	mov	ax,[enemy_hit_points]		; 02FB6  enemy_hit_points
	dec	ax			; 02FB9
	test	ax,ax			; 02FBA
	mov	[enemy_hit_points],ax		; 02FBC
	jnz	short player_strike_special_enemy_level_3_eagle_survives		; 02FBF jnz 0x2ffb  still has hits

; All hits used: transition to done state
	mov	word [approach_flag],0x4	; 02FC1  approach_flag = 4 (done)
	mov	ax,[enemy_seq_eagle_death]		; 02FC7  animation frame for done state
	cmp	word [enemy_y_off],0x0	; 02FCA  enemy_y_off == 0?
	mov	[enemy_frame_ptr],ax		; 02FCF  enemy_frame_ptr
	jnz	short player_strike_special_enemy_cap_player_health		; 02FD2 jnz 0x2fda
	mov	word [enemy_y_off],0xc	; 02FD4  set enemy_y_off = 12

player_strike_special_enemy_cap_player_health:
; Cap enemy health at 10
	cmp	word [player_hit_points],0xa	; 02FDA  player_hit_points > 10?
	jng	short player_strike_special_enemy_queue_player_regen_to_cap		; 02FDF jng 0x2fef
	mov	word [player_hit_points],0xa	; 02FE1  cap at 10
	mov	word [player_regen_pending],0x0	; 02FE7  player_regen_pending = 0
	jmp	short player_strike_special_enemy_add_player_figure		; 02FED jmp 0x3009
player_strike_special_enemy_queue_player_regen_to_cap:
; Health below cap: compute regen needed
	mov	ax,0xa			; 02FEF
	sub	ax,[player_hit_points]		; 02FF2  10 - player_hit_points
	mov	[player_regen_pending],ax		; 02FF6  player_regen_pending = deficit
	jmp	short player_strike_special_enemy_add_player_figure		; 02FF9 jmp 0x3009

player_strike_special_enemy_level_3_eagle_survives:
; Level 3 but still has hits: just set enemy_was_hit
	mov	word [enemy_was_hit],0x1		; 02FFB  enemy_was_hit = 1
	jmp	short player_strike_special_enemy_add_player_figure		; 03001 jmp 0x3009

player_strike_special_enemy_other_level_mark_hit:
; Non-level-3: set enemy_was_hit
	mov	word [enemy_was_hit],0x1		; 03003  enemy_was_hit = 1

player_strike_special_enemy_add_player_figure:
; Update player position
	mov	ax,[player_anim_id]		; 03009  player_anim_id
	dec	ax			; 0300C
	dec	ax			; 0300D
	push	ax			; 0300E
	db	0x33, 0xC0		; 0300F xor ax,ax
	push	ax			; 03011  actor=0 (player)
	call	add_figure_to_scene		; 03012
	db	0x8B, 0xE5		; 03015 mov sp,bp
	add	sp,0x2			; 03017
	pop	bp			; 0301A
	ret				; 0301B

; ---- function draw_health_bars ----
; Draws the two health bars into the offscreen buffer. Runs every frame from both frame loops (003C1, 0052C) and from prepare_screen_buffer unless script_running is set.
; Left pip count = player health [0x116], right = enemy health [0x114]. Pip N is written by blit_transition_col_left/right.
; combat_active zeroes [0x116] for good. For this drawing only, player_flag_170 and scene_locked zero the left count, and enemy_frozen the right; the saved values are restored on exit. scene_locked and enemy_frozen force a full redraw.
; Left delta against wipe_prev_left: +1 blits one pip; anything else, including no change, takes the full redraw, because an unconditional jmp at 0306F makes the shrink-by-one code at 03072-0308D dead. So the right bar's delta code (03096) runs only after the left bar grew by exactly 1.
; Right delta against wipe_prev_right: +1 blits one pip, -1 clears one with clear_health_pip, 0 does nothing, anything else redraws fully.
; Full redraw: zero the 1280-byte bar area, then blit every pip of both bars.
; Low-health blink, per bar: with its cooldown byte at 0 and a count of 2 or less, clear pips 1 and 2, set the cooldown to 1 and zero the previous count so the bar is redrawn next frame. A nonzero cooldown is just decremented, so the blink runs on alternate frames.
draw_health_bars:
	cmp	word [combat_active],0x0		; 0301C  combat_active?
	jz	short draw_health_bars_save_health		; 03021 jz 0x3029
	mov	word [player_hit_points],0x0	; 03023  clear player_hit_points during combat end

draw_health_bars_save_health:
	push	word [player_hit_points]		; 03029  save player_hit_points (left wipe)
	push	word [enemy_hit_points]		; 0302D  save enemy_hit_points (right wipe)

; Override wipe counts based on state flags
	cmp	word [player_flag_170],0x0	; 03031  player_flag_170?
	jz	short draw_health_bars_check_right_bar_hidden		; 03036 jz 0x303e
	mov	word [player_hit_points],0x0	; 03038  block left wipe
draw_health_bars_check_right_bar_hidden:
	cmp	word [enemy_frozen],0x0	; 0303E  enemy_frozen?
	jz	short draw_health_bars_check_left_bar_hidden		; 03043 jz 0x304e
	mov	word [enemy_hit_points],0x0	; 03045  block right wipe
	jmp	short draw_health_bars_full_redraw		; 0304B jmp 0x30ca  full redraw
	nop				; 0304D

draw_health_bars_check_left_bar_hidden:
	cmp	word [scene_locked],0x0	; 0304E  scene_locked?
	jz	short draw_health_bars_left_bar_delta		; 03053 jz 0x305e
	mov	word [player_hit_points],0x0	; 03055  block left wipe
	jmp	short draw_health_bars_full_redraw		; 0305B jmp 0x30ca
	nop				; 0305D

; --- Delta detection for left wipe column ---
draw_health_bars_left_bar_delta:
	mov	ax,[player_hit_points]		; 0305E  current left wipe count
	sub	ax,[wipe_prev_left]		; 03061  delta = current - previous
	db	0x3D, 0x01, 0x00	; 03065 cmp ax,0x1  grew by exactly 1?
	jz	short draw_health_bars_left_bar_grew		; 03068 jz 0x308f  blit one new column
	jg	short draw_health_bars_full_redraw		; 0306A jg 0x30ca  grew by more: full redraw
	db	0x3D, 0xFF, 0xFF	; 0306C cmp ax,0xffff  shrunk by 1?
	jmp	short draw_health_bars_full_redraw		; 0306F jmp 0x30ca
	nop				; 03071
	jl	short draw_health_bars_full_redraw		; 03072 jl 0x30ca  shrunk more: full redraw
	jnz	short draw_health_bars_right_bar_delta		; 03074 jnz 0x3096

; Left wipe shrunk by 1: clear the removed column with gate frame
	mov	bx,[player_hit_points]		; 03076
	inc	bx			; 0307A
	db	0x8B, 0xC3		; 0307B mov ax,bx
	shl	ax,1			; 0307D
	db	0x03, 0xC3		; 0307F add ax,bx  ax = bx * 3
	db	0x2D, 0x02, 0x00	; 03081 sub ax,0x2
	lea	di,[health_bar_left_base]		; 03084  transition buffer base (left)
	db	0x03, 0xF8		; 03088 add di,ax
	call	clear_health_pip	; 0308A  clear 7-row column
	jmp	short draw_health_bars_right_bar_delta		; 0308D jmp 0x3096

draw_health_bars_left_bar_grew:
; Left wipe grew by 1: blit one column
	mov	bx,[player_hit_points]		; 0308F
	call	blit_transition_col_left	; 03093

; --- Delta detection for right wipe column ---
draw_health_bars_right_bar_delta:
	mov	ax,[enemy_hit_points]		; 03096  current right wipe count
	sub	ax,[wipe_prev_right]		; 03099  delta = current - previous
	db	0x3D, 0x01, 0x00	; 0309D cmp ax,0x1
	jz	short draw_health_bars_right_bar_grew		; 030A0 jz 0x30c1  grew by 1
	jg	short draw_health_bars_full_redraw		; 030A2 jg 0x30ca  full redraw
	db	0x3D, 0xFF, 0xFF	; 030A4 cmp ax,0xffff
	jl	short draw_health_bars_full_redraw		; 030A7 jl 0x30ca
	jnz	short draw_health_bars_save_prev_counts		; 030A9 jnz 0x30f3

; Right wipe shrunk by 1: clear the removed column
	mov	bx,[enemy_hit_points]		; 030AB
	inc	bx			; 030AF
	db	0x8B, 0xC3		; 030B0 mov ax,bx
	shl	ax,1			; 030B2
	db	0x03, 0xC3		; 030B4 add ax,bx
	lea	di,[health_bar_right_end]		; 030B6  transition buffer base (right)
	db	0x2B, 0xF8		; 030BA sub di,ax
	call	clear_health_pip	; 030BC
	jmp	short draw_health_bars_save_prev_counts		; 030BF jmp 0x30f3

draw_health_bars_right_bar_grew:
; Right wipe grew by 1: blit one column
	mov	bx,[enemy_hit_points]		; 030C1
	call	blit_transition_col_right	; 030C5
	jmp	short draw_health_bars_save_prev_counts		; 030C8 jmp 0x30f3

; --- Full redraw: clear entire transition buffer and redraw all columns ---
draw_health_bars_full_redraw:
	lea	di,[offscreen_health_bar_area]		; 030CA  transition buffer start
	db	0x33, 0xC0		; 030CE xor ax,ax
	mov	cx,0x280		; 030D0  640 words = 1280 bytes
	rep	stosw			; 030D3  zero fill

; Redraw all left wipe columns
	mov	bx,[player_hit_points]		; 030D5
	cmp	bx,0x0			; 030D9
	jz	short draw_health_bars_redraw_right_pips		; 030DC jz 0x30e4
draw_health_bars_redraw_left_pips_loop:
	call	blit_transition_col_left	; 030DE
	dec	bx			; 030E1
	jg	short draw_health_bars_redraw_left_pips_loop		; 030E2 jg 0x30de

draw_health_bars_redraw_right_pips:
; Redraw all right wipe columns
	mov	bx,[enemy_hit_points]		; 030E4
	cmp	bx,0x0			; 030E8
	jz	short draw_health_bars_save_prev_counts		; 030EB jz 0x30f3
draw_health_bars_redraw_right_pips_loop:
	call	blit_transition_col_right	; 030ED
	dec	bx			; 030F0
	jg	short draw_health_bars_redraw_right_pips_loop		; 030F1 jg 0x30ed

draw_health_bars_save_prev_counts:
; Save current wipe counts as previous values
	mov	ax,[player_hit_points]		; 030F3
	mov	[wipe_prev_left],ax		; 030F6  wipe_prev_left = current left
	mov	ax,[enemy_hit_points]		; 030F9
	mov	[wipe_prev_right],ax		; 030FC  wipe_prev_right = current right

; --- Left gate animation ---
	cmp	byte [gate_anim_left],0x0	; 030FF  gate_anim_left cooldown active?
	jz	short draw_health_bars_check_left_low_health_blink		; 03104 jz 0x310c
	dec	byte [gate_anim_left]		; 03106  --cooldown
	jmp	short draw_health_bars_right_blink		; 0310A jmp 0x312c  skip gate draw
draw_health_bars_check_left_low_health_blink:
	cmp	word [player_hit_points],0x2	; 0310C  left wipe <= 2 columns?
	jg	short draw_health_bars_right_blink		; 03111 jg 0x312c  too many columns, skip
	mov	byte [gate_anim_left],0x1	; 03113  set cooldown = 1
	lea	di,[health_bar_left_pip_1]		; 03118  gate frame column 1
	call	clear_health_pip	; 0311C  clear gate column
	lea	di,[health_bar_left_pip_2]		; 0311F  gate frame column 2
	call	clear_health_pip	; 03123  clear gate column
	mov	word [wipe_prev_left],0x0	; 03126  force left wipe redraw next frame

draw_health_bars_right_blink:
; --- Right gate animation ---
	cmp	byte [gate_anim_right],0x0	; 0312C  gate_anim_right cooldown active?
	jz	short draw_health_bars_check_right_low_health_blink		; 03131 jz 0x3139
	dec	byte [gate_anim_right]		; 03133  --cooldown
	jmp	short draw_health_bars_restore_health		; 03137 jmp 0x3159

draw_health_bars_check_right_low_health_blink:
	cmp	word [enemy_hit_points],0x2	; 03139  right wipe <= 2 columns?
	jg	short draw_health_bars_restore_health		; 0313E jg 0x3159
	mov	byte [gate_anim_right],0x1	; 03140  set cooldown = 1
	lea	di,[health_bar_right_pip_1]		; 03145  gate frame column 1
	call	clear_health_pip	; 03149
	lea	di,[health_bar_right_pip_2]		; 0314C  gate frame column 2
	call	clear_health_pip	; 03150
	mov	word [wipe_prev_right],0x0	; 03153  force right wipe redraw next frame

draw_health_bars_restore_health:
; Restore saved wipe counts
	pop	word [enemy_hit_points]		; 03159  restore enemy_hit_points
	pop	word [player_hit_points]		; 0315D  restore player_hit_points
	ret				; 03161

; ---- function clear_health_pip ----
; Clears one health bar pip: 7 rows of one zero word each at DI, 0x50-byte stride.
; Input: DI = offscreen position. Called only by draw_health_bars.
clear_health_pip:
	mov	cx,0x7			; 03162  7 rows
; 7 rows, 0x50-byte stride
clear_health_pip_row_loop:
	mov	word [di],0x0		; 03165  clear word
	add	di,0x50			; 03169  next scanline (80 bytes)
	loop	0x3165			; 0316C
	ret				; 0316E

; ---- function blit_column_data ----
; Copies 7 words from SI to DI with 0x50-byte stride (CGA scanline).
; Used for rendering transition column pixel data.
; Input: SI = source data, DI = destination screen position.
blit_column_data:
	mov	cx,0x7			; 0316F  7 rows
; 7 rows, 0x50-byte stride
blit_column_data_row_loop:
	mov	ax,[si]			; 03172  read source word
	mov	[di],ax			; 03174  write to destination
	add	si,0x2			; 03176  next source word
	add	di,0x50			; 03179  next scanline
	loop	0x3172			; 0317C
	ret				; 0317E

; ---- function blit_transition_col_left ----
; Compute screen position from left-side column index BX and blit
; transition column data from buffer at [0xD654].
; Input: BX = column index (1-based).
blit_transition_col_left:
	db	0x8B, 0xC3		; 0317F mov ax,bx
	shl	ax,1			; 03181  ax = bx * 2
	db	0x03, 0xC3		; 03183 add ax,bx  ax = bx * 3
	db	0x2D, 0x02, 0x00	; 03185 sub ax,0x2  screen offset
	lea	di,[health_bar_left_base]		; 03188  left transition buffer base
	db	0x03, 0xF8		; 0318C add di,ax  di = base + offset
	lea	si,[trans_buf_left]		; 0318E  source: left transition data
	call	blit_column_data	; 03192
	ret				; 03195

; ---- function blit_transition_col_right ----
; Compute screen position from right-side column index BX and blit
; transition column data from buffer at [0xD662].
; Input: BX = column index (1-based).
blit_transition_col_right:
	db	0x8B, 0xC3		; 03196 mov ax,bx
	shl	ax,1			; 03198  ax = bx * 2
	db	0x03, 0xC3		; 0319A add ax,bx  ax = bx * 3
	lea	di,[health_bar_right_end]		; 0319C  right transition buffer base
	db	0x2B, 0xF8		; 031A0 sub di,ax  di = base - offset (grows left)
	lea	si,[trans_buf_right]		; 031A2  source: right transition data
	call	blit_column_data	; 031A6
	ret				; 031A9

; ---- function cutscene_play ----
; Main cutscene/level-progression state machine.
; Handles ALL level transitions, boss introductions, gate openings,
; music cues, and the endgame sequence.
;
; Key state variables:
;   scene_index [0x130]  - current scene/encounter index within a level
;   cutscene_state [0xD672] - cutscene sub-state counter
;   the_end_pending [0xD674] - 1 if UI element needs to be displayed
;
; The function uses large switch-like blocks for each level:
;   Level 1 ([0xEA]=1): jump table at 0x3715 (5 entries)
;   Level 2 ([0xEA]=2): eagle encounter, gate sequences, approach timers
;   Level 3 ([0xEA]=3): final boss, princess rescue, endgame
; The jump table at 0x3715 is not level 1 only. On reaching player_x_max (0x33CB path), it dispatches on current_level + level_advance, 0-4: 0 -> 03426, 1 -> 0346C, 2 -> 034AC, 3 -> 0350C, 4 -> 03674.
; The 'eagle' block for level 2 is the falling portcullis: scroll_counter is the gate row, eagle_trigger drops it, it kills the player at distance 32..62, and while down it pulls player_x_max back 68 pixels so walking into it costs health (034AC). The real eagle is started at 0386B via eagle_active/activate_enemy.
; The 'level 2 block' is skipped on other levels only as far as 0334F, which is shared; 'approach' combat_phase 1 means no live enemy, waiting to spawn the next one.
cutscene_play:
	push	bp			; 031AA
	sub	sp,0x6			; 031AB
	jc	short cutscene_play_stack_overflow		; 031AE jc 0x31b6
	cmp	sp,[stack_limit]		; 031B0  stack overflow check
	ja	short cutscene_play_stack_ok		; 031B4 ja 0x31b9
cutscene_play_stack_overflow:
	jmp	near stack_overflow_handler			; 031B6
cutscene_play_stack_ok:
	db	0x8B, 0xEC		; 031B9 mov bp,sp

; --- Cutscene state machine: delay/cooldown ---
	cmp	word [cutscene_state],0x6	; 031BB  cutscene_state == 6?
	jnz	short cutscene_play_tick_state		; 031C0 jnz 0x31d1
	mov	ax,0xc			; 031C2  12 vsync frames delay
	push	ax			; 031C5
	call	play_sound		; 031C6
	db	0x8B, 0xE5		; 031C9 mov sp,bp
	mov	word [cutscene_state],0x0	; 031CB  reset cutscene_state

cutscene_play_tick_state:
; Increment cutscene_state if > 2
	mov	ax,[cutscene_state]		; 031D1  cutscene_state
	db	0x3D, 0x02, 0x00	; 031D4 cmp ax,0x2
	jng	short cutscene_play_check_state_2		; 031D7 jng 0x31dd
	inc	word [cutscene_state]		; 031D9  ++cutscene_state

cutscene_play_check_state_2:
; If cutscene_state == 2 and player_anim_id == 1, advance to 3
	cmp	word [cutscene_state],0x2	; 031DD
	jnz	short cutscene_play_check_the_end_pending		; 031E2 jnz 0x31f1
	cmp	word [player_anim_id],0x1	; 031E4  player standing idle?
	jnz	short cutscene_play_check_the_end_pending		; 031E9 jnz 0x31f1
	mov	word [cutscene_state],0x3	; 031EB  advance state

cutscene_play_check_the_end_pending:
; --- UI element display ---
	cmp	word [the_end_pending],0x0	; 031F1  the_end_pending?
	jng	short cutscene_play_check_space_key_restart		; 031F6 jng 0x322e  no pending UI
	cmp	word [special_enemy_active],0x0	; 031F8  special_enemy_active?
	jnz	short cutscene_play_the_end_wait_enemy_inactive		; 031FD jnz 0x3227  enemy active, skip UI
	cmp	word [player_anim_id],0x1c	; 031FF  specific animation?
	jnz	short cutscene_play_show_the_end		; 03204 jnz 0x320d
	db	0x33, 0xC0		; 03206 xor ax,ax  return 0
	add	sp,0x6			; 03208
	pop	bp			; 0320B
	ret				; 0320C

cutscene_play_show_the_end:
; Wait then draw UI element
	mov	ax,0xa			; 0320D  10 vsync frames
	push	ax			; 03210
	call	play_sound		; 03211
	db	0x8B, 0xE5		; 03214 mov sp,bp
	call	show_the_end		; 03216  display the UI element
	mov	word [the_end_pending],0x0	; 03219  the_end_pending = 0
	mov	ax,0x1			; 0321F  return 1
	add	sp,0x6			; 03222
	pop	bp			; 03225
	ret				; 03226

cutscene_play_the_end_wait_enemy_inactive:
; Enemy active during UI request: return 0
	db	0x33, 0xC0		; 03227 xor ax,ax
	add	sp,0x6			; 03229
	pop	bp			; 0322C
	ret				; 0322D

cutscene_play_check_space_key_restart:
; --- Check for death animation completion ---
	cmp	word [player_anim_id],0x46	; 0322E  player in death anim (0x46)?
	jnz	short cutscene_play_check_level_2		; 03233 jnz 0x324a
	mov	al,[pending_key]		; 03235  keypress byte
	xor	ah,ah			; 03238
	db	0x3D, 0x20, 0x00	; 0323A cmp ax,0x20  space bar?
	jnz	short cutscene_play_check_level_2		; 0323D jnz 0x324a
	mov	ax,[player_seq_stop_running]		; 0323F  restart animation frame
	mov	byte [key_pending],0x0	; 03242  clear keypress flag
	mov	[player_frame_ptr],ax		; 03247  player_frame_ptr = restart frame

; ===========================================================
; LEVEL 2 BLOCK: Eagle encounter, gate sequences
; ===========================================================
cutscene_play_check_level_2:
	cmp	word [current_level],0x2		; 0324A  current_level == 2?
	jz	short cutscene_play_gate_trigger_check		; 0324F jz 0x3254
	jmp	near cutscene_play_check_combat_over			; 03251  not level 2, skip to level 3

cutscene_play_gate_trigger_check:
; --- Eagle distance/trigger check ---
	mov	ax,[encounter_target]		; 03254  encounter_target
	sub	ax,[player_x]		; 03257  distance to target
	mov	bx,[eagle_cooldown]		; 0325B  eagle_cooldown
	test	bx,bx			; 0325F
	mov	[bp+0x4],ax		; 03261  save distance
	jng	short cutscene_play_gate_cooldown_expired		; 03264 jng 0x326c
	dec	word [eagle_cooldown]		; 03266  --eagle_cooldown
	jmp	short cutscene_play_gate_check_crush_zone		; 0326A jmp 0x32a6

cutscene_play_gate_cooldown_expired:
; Check scroll and distance conditions for eagle trigger
	cmp	word [scroll_counter],0x0	; 0326C  scroll_counter == 0?
	jnz	short cutscene_play_gate_check_crush_zone		; 03271 jnz 0x32a6  scrolling, skip
	mov	ax,[bp+0x4]		; 03273
	db	0x3D, 0x5E, 0x00	; 03276 cmp ax,0x5e  distance < 94?
	jnl	short cutscene_play_gate_check_crush_zone		; 03279 jnl 0x32a6
	db	0x3D, 0x20, 0x00	; 0327B cmp ax,0x20  distance > 32?
	jng	short cutscene_play_gate_check_crush_zone		; 0327E jng 0x32a6
	db	0x3D, 0x3E, 0x00	; 03280 cmp ax,0x3e  distance < 62?
	jl	short cutscene_play_gate_trigger_if_alive		; 03283 jl 0x3299  yes, close enough

; Far range: additional checks (player must be walking and in combat)
	mov	ax,[player_anim_id]		; 03285  player_anim_id
	db	0x3D, 0x01, 0x00	; 03288 cmp ax,0x1
	jng	short cutscene_play_gate_check_crush_zone		; 0328B jng 0x32a6
	db	0x3D, 0x08, 0x00	; 0328D cmp ax,0x8
	jnl	short cutscene_play_gate_check_crush_zone		; 03290 jnl 0x32a6
	cmp	word [combat_phase],0x0		; 03292  combat_phase > 0?
	jng	short cutscene_play_gate_check_crush_zone		; 03297 jng 0x32a6

cutscene_play_gate_trigger_if_alive:
	cmp	word [combat_active],0x0		; 03299  combat_active?
	jnz	short cutscene_play_gate_check_crush_zone		; 0329E jnz 0x32a6
	mov	word [eagle_trigger],0x1	; 032A0  eagle_trigger = 1!

cutscene_play_gate_check_crush_zone:
; --- Eagle attack: force combat when close ---
	mov	ax,[bp+0x4]		; 032A6
	db	0x3D, 0x3E, 0x00	; 032A9 cmp ax,0x3e
	jnl	short cutscene_play_gate_lower_step		; 032AC jnl 0x32cd
	db	0x3D, 0x20, 0x00	; 032AE cmp ax,0x20
	jng	short cutscene_play_gate_lower_step		; 032B1 jng 0x32cd
	cmp	word [eagle_trigger],0x1	; 032B3  eagle_trigger active?
	jnz	short cutscene_play_gate_lower_step		; 032B8 jnz 0x32cd
	cmp	word [combat_active],0x0		; 032BA  not already in combat?
	jnz	short cutscene_play_gate_lower_step		; 032BF jnz 0x32cd
; Start eagle combat
	mov	word [combat_active],0x1		; 032C1  combat_active = 1
	mov	ax,[player_seq_gate_crush]		; 032C7  eagle attack animation
	mov	[player_frame_ptr],ax		; 032CA  player_frame_ptr

cutscene_play_gate_lower_step:
; --- Eagle scroll sequence ---
	cmp	word [eagle_trigger],0x1	; 032CD  eagle_trigger?
	jnz	short cutscene_play_gate_raise		; 032D2 jnz 0x32fe
	mov	ax,[scroll_counter]		; 032D4  scroll_counter
	inc	ax			; 032D7
	db	0x3D, 0x05, 0x00	; 032D8 cmp ax,0x5  5 scroll steps done?
	mov	[scroll_counter],ax		; 032DB
	jnz	short cutscene_play_gate_skip_first_step		; 032DE jnz 0x32ec
; Eagle scroll complete
	mov	word [eagle_trigger],0x0	; 032E0  eagle_trigger = 0
	mov	word [eagle_cooldown],0x3	; 032E6  eagle_cooldown = 3

cutscene_play_gate_skip_first_step:
; Skip first step (step 1 -> jump to 3)
	mov	ax,[scroll_counter]		; 032EC
	db	0x3D, 0x01, 0x00	; 032EF cmp ax,0x1
	jnz	short cutscene_play_gate_load_row_lowering		; 032F2 jnz 0x32f9
	add	word [scroll_counter],0x2	; 032F4  skip step 1 -> 3
cutscene_play_gate_load_row_lowering:
	call	load_scroll_anim_row	; 032F9  scroll screen left
	jmp	short cutscene_play_gate_update_right_bound		; 032FC jmp 0x332a

cutscene_play_gate_raise:
; --- Reverse scroll (eagle retreating) ---
	cmp	word [scroll_counter],0x0	; 032FE  scroll_counter > 0?
	jng	short cutscene_play_gate_update_right_bound		; 03303 jng 0x332a
	cmp	word [eagle_cooldown],0x0	; 03305  cooldown expired?
	jnz	short cutscene_play_gate_update_right_bound		; 0330A jnz 0x332a
	mov	ax,[eagle_scroll_dir]		; 0330C  eagle_scroll_dir
	neg	ax			; 0330F  reverse direction
	mov	[eagle_scroll_dir],ax		; 03311
	jng	short cutscene_play_gate_update_right_bound		; 03314 jng 0x332a  only scroll if positive
	mov	ax,[scroll_counter]		; 03316  scroll_counter
	dec	ax			; 03319
	test	ax,ax			; 0331A
	mov	[scroll_counter],ax		; 0331C
	jnz	short cutscene_play_gate_load_row_raising		; 0331F jnz 0x3327
	mov	word [eagle_cooldown],0xa	; 03321  cooldown = 10
cutscene_play_gate_load_row_raising:
	call	load_scroll_anim_row	; 03327

cutscene_play_gate_update_right_bound:
; --- Adjust encounter target based on scroll state ---
	cmp	word [scroll_counter],0x1	; 0332A  scrolling active?
	jng	short cutscene_play_gate_open_restore_right_bound		; 0332F jng 0x3349
	cmp	word [bp+0x4],0x20	; 03331  distance > 32?
	jng	short cutscene_play_gate_open_restore_right_bound		; 03335 jng 0x3349
	cmp	word [combat_active],0x0		; 03337  not in combat?
	jnz	short cutscene_play_gate_open_restore_right_bound		; 0333C jnz 0x3349
; Pull encounter target closer during scroll
	mov	ax,[encounter_target]		; 0333E  encounter_target
	db	0x2D, 0x44, 0x00	; 03341 sub ax,0x44  - 68 pixels
	mov	[player_x_max],ax		; 03344  player_x_max = adjusted target
	jmp	short cutscene_play_check_combat_over		; 03347 jmp 0x334f
cutscene_play_gate_open_restore_right_bound:
	mov	ax,[encounter_target]		; 03349  encounter_target
	mov	[player_x_max],ax		; 0334C  player_x_max = normal target

; --- Level 2: combat ended, approach/wait timer ---
; Shared by all levels: the non-level-2 path jumps here too.
cutscene_play_check_combat_over:
	cmp	word [combat_active],0x0		; 0334F  combat_active?
	jng	short cutscene_play_check_at_right_bound		; 03354 jng 0x33bf  not in combat

; Combat just ended: setup approach timer
	cmp	word [approach_timer],0x0	; 03356  approach_timer == 0?
	jnz	short cutscene_play_combat_over_countdown		; 0335B jnz 0x336a
	mov	word [approach_timer],0x14	; 0335D  approach_timer = 20
	db	0x33, 0xC0		; 03363 xor ax,ax  return 0
	add	sp,0x6			; 03365
	pop	bp			; 03368
	ret				; 03369

cutscene_play_combat_over_countdown:
; Count down approach timer
	mov	ax,[approach_timer]		; 0336A  approach_timer
	dec	ax			; 0336D
	test	ax,ax			; 0336E
	mov	[approach_timer],ax		; 03370
	jnz	short cutscene_play_combat_over_check_fast_forward		; 03373 jnz 0x33a4  still counting

; Timer expired: clear enemy health bar, show UI
	cmp	word [player_anim_id],0x44	; 03375  player in death anim?
	jnz	short cutscene_play_combat_over_delay		; 0337A jnz 0x3385
	mov	ax,0x3			; 0337C  3 vsync frames wait
	push	ax			; 0337F
	call	play_sound		; 03380
	db	0x8B, 0xE5		; 03383 mov sp,bp

cutscene_play_combat_over_delay:
; Brief busy-wait loop (0x3E8 = 1000 iterations)
	mov	word [bp+0x4],0x0	; 03385
cutscene_play_combat_over_delay_loop:
	cmp	word [bp+0x4],0x3e8	; 0338A
	jnl	short cutscene_play_request_the_end		; 0338F jnl 0x3396
	inc	word [bp+0x4]		; 03391
	jmp	short cutscene_play_combat_over_delay_loop		; 03394 jmp 0x338a
cutscene_play_request_the_end:
	mov	word [player_hit_points],0x0	; 03396  player_hit_points = 0 (clear bar)
	mov	word [the_end_pending],0x1	; 0339C  the_end_pending = 1
	jmp	short cutscene_play_combat_over_return_0		; 033A2 jmp 0x33b8

cutscene_play_combat_over_check_fast_forward:
; Special case: skip timer from 11 to 1 if player dying
	cmp	word [approach_timer],0xb	; 033A4  approach_timer == 11?
	jnz	short cutscene_play_combat_over_return_0		; 033A9 jnz 0x33b8
	cmp	word [player_anim_id],0x44	; 033AB  death animation?
	jnz	short cutscene_play_combat_over_return_0		; 033B0 jnz 0x33b8
	mov	word [approach_timer],0x1	; 033B2  fast-forward to 1

cutscene_play_combat_over_return_0:
	db	0x33, 0xC0		; 033B8 xor ax,ax  return 0
	add	sp,0x6			; 033BA
	pop	bp			; 033BD
	ret				; 033BE

; --- Level 2: player reached encounter target ---
cutscene_play_check_at_right_bound:
	mov	ax,[player_x]		; 033BF  player_x
	cmp	ax,[player_x_max]		; 033C2  at player_x_max?
	jz	short cutscene_play_at_right_bound_check_skip		; 033C6 jz 0x33cb
	jmp	near cutscene_play_not_at_right_bound			; 033C8  not there yet

; --- Level advance check ---
cutscene_play_at_right_bound_check_skip:
	cmp	word [level_advance],0x3	; 033CB  level_advance == 3?
	jnz	short cutscene_play_apply_level_advance_and_dispatch		; 033D0 jnz 0x3410

; Skip to level 3 (fortress interior)
	mov	word [level_advance],0x0	; 033D2  level_advance = 0
	mov	ax,0x2			; 033D8
	mov	[current_level],ax		; 033DB  current_level = 2
	inc	ax			; 033DE
	push	ax			; 033DF  arg: level 3
	mov	[current_level],ax		; 033E0  current_level = 3
	call	init_combat_level	; 033E3  initialize combat for level 3
	db	0x8B, 0xE5		; 033E6 mov sp,bp
; Set up scene 6 with gate open
	mov	ax,0x6			; 033E8
	mov	bx,0x1			; 033EB
	mov	[scene_index],ax		; 033EE  scene_index = 6
	shl	ax,1			; 033F1
	db	0x8B, 0xF0		; 033F3 mov si,ax
	mov	[si+scene_slot_flags],bx		; 033F5  scene_slot_flags[6] = 1
	mov	word [last_drawn_camera_x],0xffff	; 033F9  anim_state = none
	mov	word [combat_phase],0x2		; 033FF  combat_phase = 2 (retreat)
	mov	[draw_health_bars_pending],bx		; 03405  draw_health_bars_pending = 1
	db	0x33, 0xC0		; 03409 xor ax,ax  return 0
	add	sp,0x6			; 0340B
	pop	bp			; 0340E
	ret				; 0340F

cutscene_play_apply_level_advance_and_dispatch:
; Normal level advance
	mov	ax,[current_level]		; 03410  current_level
	mov	bx,[level_advance]		; 03413  level_advance
	db	0x03, 0xD8		; 03417 add bx,ax  new_level = current + advance
	mov	word [level_advance],0x0	; 03419  level_advance = 0
	mov	[current_level],bx		; 0341F  current_level = new_level
	jmp	near cutscene_play_level_jump_via_table			; 03423  goto level transition setup

; ===========================================================
; LEVEL 2 SCENE TRANSITIONS: music callbacks and encounters
; ===========================================================

; --- Scene 1: first gate music ---
	mov	ax,0x7			; 03426  animation data index
	push	ax			; 03429
	mov	ax,str_cal07a - DS_BASE		; 0342A  script filename pointer
	push	ax			; 0342D
	call	play_music_sequence	; 0342E  play gate-opening music
	db	0x8B, 0xE5		; 03431 mov sp,bp
	mov	ax,[current_level]		; 03433  advance to next level
	inc	ax			; 03436
	push	ax			; 03437
	mov	[current_level],ax		; 03438
	call	init_combat_level	; 0343B  setup combat for next level
	db	0x8B, 0xE5		; 0343E mov sp,bp
; Load palette and set up frozen enemy
	mov	ax,0x5dc		; 03440  palette offset
	push	ax			; 03443
	mov	ax,str_fuji_bcg2 - DS_BASE	; 03444  palette filename
	push	ax			; 03447
	call	load_resource		; 03448
	db	0x8B, 0xE5		; 0344B mov sp,bp
	mov	word [enemy_frozen],0x20	; 0344D  enemy_frozen = 32 frames
	mov	word [enemy_anim_id],0x46	; 03453  enemy_anim_id = death/frozen
	mov	ax,[enemy_seq_run_in]		; 03459
	mov	word [last_drawn_camera_x],0xffff	; 0345C  anim_state = none
	mov	[enemy_frame_ptr],ax		; 03462  enemy_frame_ptr
	db	0x33, 0xC0		; 03465 xor ax,ax  return 0
	add	sp,0x6			; 03467
	pop	bp			; 0346A
	ret				; 0346B

; --- Scene 2: second gate music ---
	mov	ax,0x8			; 0346C
	push	ax			; 0346F
	mov	ax,str_cal04 - DS_BASE		; 03470  script filename
	push	ax			; 03473
	call	play_music_sequence	; 03474
	db	0x8B, 0xE5		; 03477 mov sp,bp
	mov	ax,[current_level]		; 03479
	inc	ax			; 0347C
	push	ax			; 0347D
	mov	[current_level],ax		; 0347E
	call	init_combat_level	; 03481
	db	0x8B, 0xE5		; 03484 mov sp,bp
	mov	ax,0x5dc		; 03486
	push	ax			; 03489
	mov	ax,str_fuji_bcg2 - DS_BASE	; 0348A
	push	ax			; 0348D
	call	load_resource		; 0348E
	db	0x8B, 0xE5		; 03491 mov sp,bp
	mov	word [enemy_x],0xc8	; 03493  enemy_x = 200
	mov	word [scene_param_e2],0x1		; 03499  scene_param_e2 = 1 (special encounter)
	mov	word [approach_timer],0x9	; 0349F  approach_timer = 9
	db	0x33, 0xC0		; 034A5 xor ax,ax
	add	sp,0x6			; 034A7
	pop	bp			; 034AA
	ret				; 034AB

; --- Scene 3: dissolve transition ---
	mov	ax,[player_x_max]		; 034AC  player_x_max
	cmp	ax,[encounter_target]		; 034AF  encounter_target?
	jnl	short cutscene_play_level_2_gate_open_exit		; 034B3 jnl 0x34bf
	call	health_decrement_push		; 034B5  dissolve effect
	db	0x33, 0xC0		; 034B8 xor ax,ax
	add	sp,0x6			; 034BA
	pop	bp			; 034BD
	ret				; 034BE

cutscene_play_level_2_gate_open_exit:
; --- Scene 3 continued: music and level 3 transition ---
	mov	ax,0xa			; 034BF  animation data index
	push	ax			; 034C2
	mov	ax,str_cal05 - DS_BASE		; 034C3  script filename
	push	ax			; 034C6
	call	play_music_sequence	; 034C7
	db	0x8B, 0xE5		; 034CA mov sp,bp
	mov	ax,0x1			; 034CC
	mov	word [last_drawn_camera_x],0xffff	; 034CF  anim_state = none
	mov	bx,[current_level]		; 034D5  current_level
	inc	bx			; 034D9
	push	bx			; 034DA
	mov	[scene_index],ax		; 034DB  scene_index = 1
	mov	[current_level],bx		; 034DE  ++current_level
	call	init_combat_level	; 034E2
	db	0x8B, 0xE5		; 034E5 mov sp,bp
; Initialize level 3 state
	mov	ax,[player_x]		; 034E7  player_x
	mov	word [draw_health_bars_pending],0x1	; 034EA  draw_health_bars_pending = 1
	db	0x33, 0xDB		; 034F0 xor bx,bx
	mov	[player_x_min],ax		; 034F2  player_x_min = current player_x
	mov	[enemy_aggressive],bx		; 034F5  enemy_aggressive = 0
	mov	[cutscene_state],bx		; 034F9  cutscene_state = 0
	mov	[princess_rescued],bx		; 034FD  princess_rescued = 0
	mov	[combat_phase],bx		; 03501  combat_phase = 0
	db	0x8B, 0xC3		; 03505 mov ax,bx  return 0
	add	sp,0x6			; 03507
	pop	bp			; 0350A
	ret				; 0350B

; ===========================================================
; LEVEL 3 BLOCK: Final boss, princess rescue, endgame
; ===========================================================

; Check if draw_health_bars_pending and enemy not yet spawned
	cmp	word [draw_health_bars_pending],0x1	; 0350C  draw_health_bars_pending?
	jz	short cutscene_play_level_3_exit_open		; 03511 jz 0x3516
	jmp	near cutscene_play_level_3_exit_blocked_push_back			; 03513  not pending, skip ahead

cutscene_play_level_3_exit_open:
	cmp	word [special_enemy_active],0x0	; 03516  special_enemy_active?
	jz	short cutscene_play_level_3_advance_scene		; 0351B jz 0x3527
	cmp	word [scene_index],0x5	; 0351D  scene_index >= 5?
	jl	short cutscene_play_level_3_advance_scene		; 03522 jl 0x3527
	jmp	near cutscene_play_level_3_exit_blocked_push_back			; 03524

cutscene_play_level_3_advance_scene:
; Advance scene_index
	mov	ax,[scene_index]		; 03527  scene_index
	inc	ax			; 0352A
	db	0x3D, 0x07, 0x00	; 0352B cmp ax,0x7  reached scene 7?
	mov	[scene_index],ax		; 0352E
	jz	short cutscene_play_level_3_enter_boss_level		; 03531 jz 0x3536
	jmp	near cutscene_play_level_3_adjust_scene_2_bounds			; 03533  not scene 7 yet

cutscene_play_level_3_enter_boss_level:
; --- Scene 7: Final boss entry music ---
	mov	ax,0xc			; 03536  animation data index
	push	ax			; 03539
	mov	ax,str_cal06 - DS_BASE		; 0353A  script filename
	push	ax			; 0353D
	call	play_music_sequence	; 0353E
	db	0x8B, 0xE5		; 03541 mov sp,bp
	mov	ax,[current_level]		; 03543
	inc	ax			; 03546
	push	ax			; 03547
	mov	[current_level],ax		; 03548
	call	init_combat_level	; 0354B
	db	0x8B, 0xE5		; 0354E mov sp,bp

; Load animation script for final boss intro
	mov	ax,0xce3e		; 03550  destination buffer
	push	ax			; 03553
	mov	ax,str_allval - DS_BASE		; 03554  script filename
	push	ax			; 03557
	call	load_anim_script	; 03558
	db	0x8B, 0xE5		; 0355B mov sp,bp
	call	build_enemy_anim_offsets		; 0355D

; Set up final battle scene
	mov	word [scene_index],0x6	; 03560  scene_index = 6
	push	word [scene_index]		; 03566
	call	place_player_for_scene		; 0356A
	db	0x8B, 0xE5		; 0356D mov sp,bp
	mov	ax,0x114		; 0356F  enemy spawn position
	mov	[enemy_x],ax		; 03572  enemy_x
	db	0x2D, 0x1E, 0x00	; 03575 sub ax,0x1e  player starts 30 pixels left
	mov	word [enemy_anim_id],0x6	; 03578  enemy_anim_id = 6
	mov	bx,0x1			; 0357E
	mov	cx,0x1a			; 03581  26 - player_hit_points = initial hits
	sub	cx,[player_hit_points]		; 03584
	cmp	word [player_anim_id],0x3f	; 03588  player alive?
	mov	[player_x],ax		; 0358D  player_x
	mov	[enemy_hit_points],cx		; 03590  enemy_hit_points
	mov	[player_faces_right],bx		; 03594  player_faces_right = 1
	jnl	short cutscene_play_boss_intro_player_dying		; 03598 jnl 0x35ac  player dead

; Player alive: start combat
	mov	word [player_anim_id],0xa	; 0359A  player_anim_id = 10 (fight stance)
	mov	ax,[player_seq_long_recoil]		; 035A0  fight stance animation
	mov	[player_frame_ptr],ax		; 035A3  player_frame_ptr
	mov	[enemy_facing],bx		; 035A6  enemy_facing = 1
	jmp	short cutscene_play_boss_intro_init_regen_count		; 035AA jmp 0x35be

cutscene_play_boss_intro_player_dying:
; Player dead: end combat immediately
	mov	word [player_hit_points],0x0	; 035AC  player_hit_points = 0
	mov	word [combat_active],0x1		; 035B2  combat_active = 1
	mov	ax,[player_seq_death]		; 035B8  death frame
	mov	[player_frame_ptr],ax		; 035BB

cutscene_play_boss_intro_init_regen_count:
; Calculate initial encounter counter
	mov	ax,0x12			; 035BE  18 - enemy_hit_points
	sub	ax,[enemy_hit_points]		; 035C1
	mov	[enemy_regen_pending],ax		; 035C5  enemy_regen_pending
	jnl	short cutscene_play_boss_intro_return		; 035C8 jnl 0x35d0
	mov	word [enemy_regen_pending],0x0	; 035CA  clamp to 0
cutscene_play_boss_intro_return:
	db	0x33, 0xC0		; 035D0 xor ax,ax  return 0
	add	sp,0x6			; 035D2
	pop	bp			; 035D5
	ret				; 035D6

; --- Level 1 scene: adjust screen bounds for scene 2 ---
; level 3 scene advance when new scene_index != 7; shifts right bounds left 320 at scene 2
cutscene_play_level_3_adjust_scene_2_bounds:
	cmp	word [scene_index],0x2	; 035D7  scene_index == 2?
	jnz	short cutscene_play_level_3_load_scene_flags		; 035DC jnz 0x35ea
	sub	word [player_x_max],0x140	; 035DE  player_x_max -= 320
	sub	word [camera_x_max],0x140	; 035E4  camera_x_max -= 320

cutscene_play_level_3_load_scene_flags:
; Load scene slot flags and transition state
	mov	ax,[scene_index]		; 035EA  scene_index
	shl	ax,1			; 035ED
	db	0x8B, 0xF0		; 035EF mov si,ax
	mov	bx,[si+scene_slot_flags]		; 035F1  scene_slot_flags[scene_index]
	cmp	word [combat_phase],0x0		; 035F5  combat_phase?
	mov	[bp+0x0],ax		; 035FA
	mov	[draw_health_bars_pending],bx		; 035FD  draw_health_bars_pending = flags
	jng	short cutscene_play_level_3_no_combat_shift_enemy_x		; 03601 jng 0x363f

; Combat phase active: set retreat state
	mov	word [combat_phase],0x2		; 03603  combat_phase = 2 (retreat)
	cmp	word [si+scene_enemy_pending],0x0	; 03609  damage pending for this scene?
	jng	short cutscene_play_level_3_check_scene_6_cutscene		; 0360E jng 0x3626
	push	word [current_level]		; 03610  apply damage for current level
	call	spawn_enemy		; 03614
	db	0x8B, 0xE5		; 03617 mov sp,bp
	mov	ax,[scene_index]		; 03619
	shl	ax,1			; 0361C
	db	0x8B, 0xF0		; 0361E mov si,ax
	mov	word [si+scene_enemy_pending],0x0	; 03620  clear damage pending

cutscene_play_level_3_check_scene_6_cutscene:
; Level 3 scene 6: trigger princess rescue
	cmp	word [scene_index],0x6	; 03626  scene_index == 6?
	jnz	short cutscene_play_level_3_set_right_bound		; 0362B jnz 0x3645
	cmp	word [princess_rescued],0x0	; 0362D  princess_rescued?
	jnz	short cutscene_play_level_3_set_right_bound		; 03632 jnz 0x3645
	mov	ax,0x1			; 03634
	mov	[princess_rescued],ax		; 03637  princess_rescued = 1
	mov	[cutscene_state],ax		; 0363A  cutscene_state = 1
	jmp	short cutscene_play_level_3_set_right_bound		; 0363D jmp 0x3645

cutscene_play_level_3_no_combat_shift_enemy_x:
; No combat phase: adjust enemy X for transition
	sub	word [enemy_x],0x114	; 0363F  enemy_x -= 276

cutscene_play_level_3_set_right_bound:
; Set up screen bounds based on transition state
	cmp	word [draw_health_bars_pending],0x0	; 03645  draw_health_bars_pending?
	jnz	short cutscene_play_level_3_right_bound_exit_open		; 0364A jnz 0x3654
	mov	word [player_x_max],0xfc	; 0364C  player_x_max = 252 (tighter bounds)
	jmp	short cutscene_play_level_3_place_player		; 03652 jmp 0x365a
cutscene_play_level_3_right_bound_exit_open:
	mov	word [player_x_max],0x130	; 03654  player_x_max = 304 (wider bounds)

cutscene_play_level_3_place_player:
; Apply wipe effect for this scene
	push	word [scene_index]		; 0365A
	call	place_player_for_scene		; 0365E
	db	0x8B, 0xE5		; 03661 mov sp,bp
	db	0x33, 0xC0		; 03663 xor ax,ax  return 0
	add	sp,0x6			; 03665
	pop	bp			; 03668
	ret				; 03669

; Dissolve effect (reached via jump table)
; exit not pending, or enemy active at scene >= 5: calls health_decrement_push, returns 0. Existing comment 'Dissolve effect' looks wrong
cutscene_play_level_3_exit_blocked_push_back:
	call	health_decrement_push		; 0366A
	db	0x33, 0xC0		; 0366D xor ax,ax
	add	sp,0x6			; 0366F
	pop	bp			; 03672
	ret				; 03673

; --- Level 3 scene 7: final animation and dialog ---
	cmp	word [scene_index],0x7	; 03674  scene_index == 7?
	jnz	short cutscene_play_level_4_advance_scene		; 03679 jnz 0x3697
	cmp	word [player_anim_id],0x40	; 0367B  player_anim_id > 0x40?
	jng	short cutscene_play_level_4_final_wait_return_0		; 03680 jng 0x3690

; Play final animation script and show endgame dialog
	call	run_anim_script		; 03682
	call	show_outro_text		; 03685  show ending text
	mov	ax,0x1			; 03688  return 1 (game complete)
	add	sp,0x6			; 0368B
	pop	bp			; 0368E
	ret				; 0368F
cutscene_play_level_4_final_wait_return_0:
	db	0x33, 0xC0		; 03690 xor ax,ax  not ready yet, return 0
	add	sp,0x6			; 03692
	pop	bp			; 03695
	ret				; 03696

; --- Advance scene within level 3 ---
cutscene_play_level_4_advance_scene:
	inc	word [scene_index]		; 03697  ++scene_index
	mov	ax,[combat_phase]		; 0369B  combat_phase
	db	0x3D, 0x01, 0x00	; 0369E cmp ax,0x1  approach?
	jnz	short cutscene_play_level_4_load_scene		; 036A1 jnz 0x36a7
	inc	word [combat_phase]		; 036A3  advance to retreat

cutscene_play_level_4_load_scene:
; Load scene slot flags and apply wipe
	mov	ax,[scene_index]		; 036A7
	shl	ax,1			; 036AA
	db	0x8B, 0xF0		; 036AC mov si,ax
	mov	ax,[si+scene_slot_flags]		; 036AE  scene_slot_flags[scene_index]
	push	word [scene_index]		; 036B2
	mov	[draw_health_bars_pending],ax		; 036B6  draw_health_bars_pending
	call	place_player_for_scene		; 036B9
	db	0x8B, 0xE5		; 036BC mov sp,bp

; Scene 7 special setup: load final battle animations
	cmp	word [scene_index],0x7	; 036BE  scene_index == 7?
	jnz	short cutscene_play_level_4_return_0		; 036C3 jnz 0x370e
	mov	word [player_x_max],0xac	; 036C5  player_x_max = 172
; Load animation scripts for endgame
	mov	ax,0xbd04		; 036CB  destination buffer
	push	ax			; 036CE
	mov	ax,str_cal03 - DS_BASE		; 036CF  script filename
	push	ax			; 036D2
	call	load_anim_script	; 036D3
	db	0x8B, 0xE5		; 036D6 mov sp,bp
	mov	ax,0xb			; 036D8  animation data index
	push	ax			; 036DB
	call	load_sprite_set		; 036DC
	db	0x8B, 0xE5		; 036DF mov sp,bp
	mov	ax,0xce3e		; 036E1  second script buffer
	push	ax			; 036E4
	mov	ax,str_prngal - DS_BASE		; 036E5  second script filename
	push	ax			; 036E8
	call	load_anim_script	; 036E9
	db	0x8B, 0xE5		; 036EC mov sp,bp
	call	build_enemy_anim_offsets		; 036EE
; Set up final encounter
	mov	word [combat_phase],0x0		; 036F1  combat_phase = 0
	mov	word [enemy_x],0xc8	; 036F7  enemy_x = 200
	mov	ax,0x1			; 036FD
	mov	bx,[enemy_seq_offsets]		; 03700  enemy animation backup
	mov	[game_mode],ax		; 03704  game_mode = 1
	mov	[enemy_anim_id],ax		; 03707  enemy_anim_id = 1
	mov	[enemy_frame_ptr],bx		; 0370A  enemy_frame_ptr

cutscene_play_level_4_return_0:
	db	0x33, 0xC0		; 0370E xor ax,ax  return 0
	add	sp,0x6			; 03710
	pop	bp			; 03713
	ret				; 03714

; --- Jump table for level 1 scenes (5 entries) ---
; Entries are code offsets for scenes 0-4 within level 1
	es	xor al,0x6c		; 03715
	xor	al,0xac			; 03718
	xor	al,0xc			; 0371A
	xor	ax,0x3674		; 0371C

; --- Scene dispatcher (using jump table) ---
; BX = new current_level; table at 0x3715 holds 5 per-level handlers (existing 'level 1 scenes' comment looks wrong)
cutscene_play_level_jump_via_table:
	db	0x8B, 0xF3		; 0371F mov si,bx
	cmp	si,0x5			; 03721  scene_index < 5?
	jnc	short cutscene_play_not_at_right_bound		; 03724 jnc 0x372d  out of range
	shl	si,1			; 03726  word index
	jmp	word near [cs:si+0x3715]	; 03728  dispatch via jump table

; ===========================================================
; APPROACH/RETREAT LOGIC (shared by levels 1 and 3)
; ===========================================================

cutscene_play_not_at_right_bound:
; --- Setup approach health regen when entering retreat ---
	cmp	word [combat_phase],0x0		; 0372D  combat_phase > 0?
	jng	short cutscene_play_check_waiting_for_next_enemy		; 03732 jng 0x375d
	cmp	word [scene_index],0x5	; 03734  scene_index == 5?
	jnz	short cutscene_play_check_waiting_for_next_enemy		; 03739 jnz 0x375d
	cmp	word [player_flag_172],0x0	; 0373B  setup already done?
	jnz	short cutscene_play_check_waiting_for_next_enemy		; 03740 jnz 0x375d
	mov	word [player_flag_172],0x1	; 03742  mark setup done
; Calculate initial regen: 21 - player_hit_points
	mov	ax,0x15			; 03748
	sub	ax,[player_hit_points]		; 0374B
	mov	bx,0x2			; 0374F
	mov	[player_regen_pending],ax		; 03752  player_regen_pending = 21 - health
	mov	[player_regen_timer],bx		; 03755  player_regen_timer = 2
	mov	[player_regen_rate],bx		; 03759  player_regen_rate = 2

cutscene_play_check_waiting_for_next_enemy:
; --- Check if in approach phase (combat_phase == 1) ---
	cmp	word [combat_phase],0x1		; 0375D  approach?
	jz	short cutscene_play_next_enemy_check_level		; 03762 jz 0x3767
	jmp	near cutscene_play_check_at_left_bound			; 03764  not approach, return

cutscene_play_next_enemy_check_level:
; Only levels 1 and 2 use the approach timer logic
	mov	ax,[current_level]		; 03767  current_level
	db	0x3D, 0x01, 0x00	; 0376A cmp ax,0x1
	jz	short cutscene_play_next_enemy_check_gate_moving		; 0376D jz 0x3777
	db	0x3D, 0x02, 0x00	; 0376F cmp ax,0x2
	jz	short cutscene_play_next_enemy_check_gate_moving		; 03772 jz 0x3777
	jmp	near cutscene_play_check_at_left_bound			; 03774

cutscene_play_next_enemy_check_gate_moving:
; Skip if currently scrolling
	cmp	word [scroll_counter],0x0	; 03777  scroll_counter > 0?
	jz	short cutscene_play_next_enemy_check_distance		; 0377C jz 0x3781
	jmp	near cutscene_play_check_at_left_bound			; 0377E

cutscene_play_next_enemy_check_distance:
; Check distance to encounter target
	mov	ax,[player_x_max]		; 03781  player_x_max
	sub	ax,[player_x]		; 03784  - player_x
	db	0x3D, 0x3C, 0x00	; 03788 cmp ax,0x3c  distance > 60?
	jg	short cutscene_play_next_enemy_check_timer_set		; 0378B jg 0x3790
	jmp	near cutscene_play_check_at_left_bound			; 0378D  too close, return

cutscene_play_next_enemy_check_timer_set:
; --- Initialize approach timer ---
	cmp	word [approach_timer],0x0	; 03790  approach_timer already set?
	jnz	short cutscene_play_next_enemy_count_down		; 03795 jnz 0x37ce  yes, count down
	mov	ax,0x2			; 03797
	mov	word [approach_timer],0x28	; 0379A  approach_timer = 40
	mov	bx,[player_x_max]		; 037A0  player_x_max
	sub	bx,[player_x]		; 037A4  distance
	cmp	bx,0xfa			; 037A8  distance < 250?
	mov	[player_regen_timer],ax		; 037AC  player_regen_timer = 2
	mov	[player_regen_rate],ax		; 037AF  player_regen_rate = 2
	jnl	short cutscene_play_next_enemy_check_special_timer		; 037B2 jnl 0x37ba
	mov	word [approach_timer],0x3c	; 037B4  closer: longer timer (60)
cutscene_play_next_enemy_check_special_timer:
	cmp	word [scene_param_e2],0x1		; 037BA  scene_param_e2 == 1?
	jnz	short cutscene_play_next_enemy_timer_set_return		; 037BF jnz 0x37c7
	mov	word [approach_timer],0x32	; 037C1  special encounter: timer = 50
cutscene_play_next_enemy_timer_set_return:
	db	0x33, 0xC0		; 037C7 xor ax,ax  return 0
	add	sp,0x6			; 037C9
	pop	bp			; 037CC
	ret				; 037CD

; --- Count down approach timer ---
cutscene_play_next_enemy_count_down:
; Prevent timer from reaching 1 if player is in specific animation
	cmp	word [approach_timer],0x1	; 037CE  timer about to expire?
	jnz	short cutscene_play_next_enemy_decrement_timer		; 037D3 jnz 0x37e0
	cmp	word [player_anim_id],0x8	; 037D5  player in combat anim?
	jnz	short cutscene_play_next_enemy_decrement_timer		; 037DA jnz 0x37e0
	inc	word [approach_timer]		; 037DC  hold timer at 2

cutscene_play_next_enemy_decrement_timer:
	mov	ax,[approach_timer]		; 037E0  approach_timer
	dec	ax			; 037E3
	test	ax,ax			; 037E4
	mov	[approach_timer],ax		; 037E6
	jz	short cutscene_play_next_enemy_timer_expired		; 037E9 jz 0x37ee  timer expired!
	jmp	near cutscene_play_next_enemy_return_0			; 037EB  not expired, return

; --- Approach timer expired ---
cutscene_play_next_enemy_timer_expired:
; Special case: level 2 with special encounter active
	cmp	word [scene_param_e2],0x1		; 037EE  scene_param_e2?
	jnz	short cutscene_play_next_enemy_choose_by_distance		; 037F3 jnz 0x3851
	cmp	word [current_level],0x2		; 037F5  level 2?
	jnz	short cutscene_play_next_enemy_choose_by_distance		; 037FA jnz 0x3851

; Play special encounter music and set up boss
	mov	ax,0x9			; 037FC  animation data index
	push	ax			; 037FF
	mov	ax,str_cal07 - DS_BASE		; 03800  script filename
	push	ax			; 03803
	call	play_music_sequence	; 03804
	db	0x8B, 0xE5		; 03807 mov sp,bp
	mov	ax,0x2			; 03809  animation data index
	push	ax			; 0380C
	call	load_sprite_set		; 0380D
	db	0x8B, 0xE5		; 03810 mov sp,bp
	mov	ax,0x5dc		; 03812  palette offset
	push	ax			; 03815
	mov	ax,str_fuji_bcg2 - DS_BASE	; 03816
	push	ax			; 03819
	call	load_resource		; 0381A
	db	0x8B, 0xE5		; 0381D mov sp,bp
	push	word [current_level]		; 0381F
	call	spawn_enemy		; 03823
	db	0x8B, 0xE5		; 03826 mov sp,bp
; Reset enemy to frozen state
	mov	word [enemy_frozen],0x20	; 03828  enemy_frozen = 32
	mov	word [enemy_anim_id],0x46	; 0382E  enemy_anim_id = frozen
	mov	ax,[enemy_seq_run_in]		; 03834
	mov	word [last_drawn_camera_x],0xffff	; 03837  anim_state = none
	db	0x33, 0xDB		; 0383D xor bx,bx
	mov	[enemy_frame_ptr],ax		; 0383F  enemy_frame_ptr
	mov	[eagle_active],bx		; 03842  eagle_active = 0
	mov	[scene_param_e2],bx		; 03846  scene_param_e2 = 0
	db	0x8B, 0xC3		; 0384A mov ax,bx  return 0
	add	sp,0x6			; 0384C
	pop	bp			; 0384F
	ret				; 03850

; --- Normal approach timer expired: spawn enemy or advance ---
cutscene_play_next_enemy_choose_by_distance:
	mov	ax,[player_x_max]		; 03851  player_x_max
	sub	ax,[player_x]		; 03854  distance
	cmp	ax,0x190		; 03858  distance > 400?
	jng	short cutscene_play_next_enemy_spawn_near		; 0385B jng 0x38d7  close enough

; Far away (>400): level 2 special eagle handling
	cmp	word [current_level],0x2		; 0385D  level 2?
	jnz	short cutscene_play_next_enemy_spawn_far		; 03862 jnz 0x389c
	cmp	word [eagle_active],0x0	; 03864  eagle_active?
	jnz	short cutscene_play_next_enemy_spawn_far		; 03869 jnz 0x389c

; Start eagle encounter
	mov	word [eagle_active],0x1	; 0386B  eagle_active = 1
	mov	ax,0x18			; 03871  24 vsync frames
	push	ax			; 03874
	call	play_sound		; 03875
	db	0x8B, 0xE5		; 03878 mov sp,bp
	call	activate_enemy	; 0387A  scroll screen
	db	0x33, 0xC0		; 0387D xor ax,ax
	mov	bx,[player_x]		; 0387F  player_x
	add	bx,0x128		; 03883  + 296 = eagle spawn position
	mov	word [approach_timer],0x2	; 03887  approach_timer = 2
	mov	[enemy_was_hit],ax		; 0388D  enemy_was_hit = 0
	mov	[enemy_regen_pending],ax		; 03890  enemy_regen_pending = 0
	mov	[enemy_hit_points],ax		; 03893  enemy_hit_points = 0
	mov	[enemy_x],bx		; 03896  enemy_x = spawn position
	jmp	short cutscene_play_next_enemy_return_0		; 0389A jmp 0x38ec

cutscene_play_next_enemy_spawn_far:
; Apply combat damage and reset state
	push	word [current_level]		; 0389C
	call	spawn_enemy		; 038A0
	db	0x8B, 0xE5		; 038A3 mov sp,bp
	mov	word [eagle_active],0x0	; 038A5  eagle_active = 0
	cmp	word [current_level],0x2		; 038AB  level 2?
	jnz	short cutscene_play_next_enemy_lock_scene		; 038B0 jnz 0x38c9
; Cap enemy distance on level 2
	mov	ax,[player_x]		; 038B2  player_x
	mov	bx,[enemy_x]		; 038B5  enemy_x
	db	0x2B, 0xD8		; 038B9 sub bx,ax  distance
	cmp	bx,0x140		; 038BB  > 320?
	jng	short cutscene_play_next_enemy_force_bar_redraw		; 038BF jng 0x38cf
	add	ax,0x12c		; 038C1  cap at player_x + 300
	mov	[enemy_x],ax		; 038C4  enemy_x = capped
	jmp	short cutscene_play_next_enemy_force_bar_redraw		; 038C7 jmp 0x38cf

cutscene_play_next_enemy_lock_scene:
; Non-level-2: lock scene
	mov	word [scene_locked],0x20	; 038C9  scene_locked = 32

cutscene_play_next_enemy_force_bar_redraw:
	mov	word [wipe_prev_left],0x0	; 038CF  wipe_prev_left = 0 (force redraw)
	jmp	short cutscene_play_next_enemy_return_0		; 038D5 jmp 0x38ec

; Close range (<= 400): apply damage if distance > 30
cutscene_play_next_enemy_spawn_near:
	mov	ax,[player_x_max]		; 038D7  player_x_max
	sub	ax,[player_x]		; 038DA
	db	0x3D, 0x1E, 0x00	; 038DE cmp ax,0x1e  distance > 30?
	jng	short cutscene_play_next_enemy_return_0		; 038E1 jng 0x38ec
	push	word [current_level]		; 038E3
	call	spawn_enemy		; 038E7
	db	0x8B, 0xE5		; 038EA mov sp,bp

cutscene_play_next_enemy_return_0:
	db	0x33, 0xC0		; 038EC xor ax,ax  return 0
	add	sp,0x6			; 038EE
	pop	bp			; 038F1
	ret				; 038F2

; ===========================================================
; LEVEL 0 / RETREAT: backward movement and boundary checks
; ===========================================================

; Check if player reached retreat boundary
; reached when the waiting-for-next-enemy checks fail; compares player_x with player_x_min
cutscene_play_check_at_left_bound:
	mov	ax,[player_x]		; 038F3  player_x
	cmp	ax,[player_x_min]		; 038F6  player_x_min?
	jnz	short cutscene_play_check_enemy_distance		; 038FA jnz 0x395f

; Player at boundary: level 0 special case
	cmp	word [current_level],0x0		; 038FC  level 0?
	jnz	short cutscene_play_left_bound_check_level_past_2		; 03901 jnz 0x391c
; Level 0: reset player position
	mov	word [player_x],0x2c	; 03903  player_x = 44
	mov	word [player_x_min],0x28	; 03909  player_x_min = 40
	mov	ax,[player_seq_level0_left_bound]		; 0390F
	mov	[player_frame_ptr],ax		; 03912  player_frame_ptr
	db	0x33, 0xC0		; 03915 xor ax,ax
	add	sp,0x6			; 03917
	pop	bp			; 0391A
	ret				; 0391B

cutscene_play_left_bound_check_level_past_2:
; Levels 1+: retreat through previous scenes
	cmp	word [current_level],0x2		; 0391C  level > 2?
	jng	short cutscene_play_check_enemy_distance		; 03921 jng 0x395f
	mov	ax,[scene_index]		; 03923  scene_index
	db	0x3D, 0x02, 0x00	; 03926 cmp ax,0x2  scene_index > 2?
	jng	short cutscene_play_check_enemy_distance		; 03929 jng 0x395f

; Retreat: go back one scene
	dec	word [scene_index]		; 0392B  --scene_index
	mov	word [draw_health_bars_pending],0x1	; 0392F  draw_health_bars_pending = 1
	push	word [scene_index]		; 03935
	call	place_player_for_scene		; 03939
	db	0x8B, 0xE5		; 0393C mov sp,bp
	cmp	word [scene_index],0x2	; 0393E  back to scene 2?
	jnz	short cutscene_play_left_bound_reposition_player		; 03943 jnz 0x394e
	mov	word [anim_bg_counter],0x2	; 03945  anim_bg_counter = 2
	call	load_anim_row		; 0394B

cutscene_play_left_bound_reposition_player:
; Reset player position for new scene
	mov	ax,0x114		; 0394E
	mov	[player_x],ax		; 03951  player_x = 276
	inc	ax			; 03954
	inc	ax			; 03955
	add	word [enemy_x],0x114	; 03956  enemy_x += 276
	mov	[player_x_max],ax		; 0395C  player_x_max = 278

; ===========================================================
; DISTANCE AND FREEZE CHECKS
; ===========================================================
cutscene_play_check_enemy_distance:
	mov	ax,[enemy_x]		; 0395F  enemy_x
	sub	ax,[player_x]		; 03962  - player_x
	cmp	ax,0x14a		; 03966  distance >= 330?
	mov	[bp+0x4],ax		; 03969
	jnl	short cutscene_play_enemy_far_frozen_countdown		; 0396C jnl 0x3991  far away

; Close enough: clear frozen/locked state
	db	0x33, 0xC0		; 0396E xor ax,ax
	cmp	word [enemy_anim_id],0x3f	; 03970  enemy alive?
	mov	[scene_locked],ax		; 03975  scene_locked = 0
	mov	[enemy_frozen],ax		; 03978  enemy_frozen = 0
	jng	short cutscene_play_enemy_near_return_0		; 0397B jng 0x398a
	cmp	word [current_level],0x0		; 0397D  not level 0?
	jng	short cutscene_play_enemy_near_return_0		; 03982 jng 0x398a
	mov	word [enemy_anim_id],0x1	; 03984  reset enemy to idle
cutscene_play_enemy_near_return_0:
	db	0x33, 0xC0		; 0398A xor ax,ax
	add	sp,0x6			; 0398C
	pop	bp			; 0398F
	ret				; 03990

; --- Enemy is far away: handle freeze countdown ---
cutscene_play_enemy_far_frozen_countdown:
	mov	ax,[enemy_frozen]		; 03991  enemy_frozen
	db	0x3D, 0x01, 0x00	; 03994 cmp ax,0x1  > 1?
	jng	short cutscene_play_enemy_far_check_thaw		; 03997 jng 0x39a4
	dec	word [enemy_frozen]		; 03999  --enemy_frozen
	db	0x33, 0xC0		; 0399D xor ax,ax
	add	sp,0x6			; 0399F
	pop	bp			; 039A2
	ret				; 039A3

cutscene_play_enemy_far_check_thaw:
; enemy_frozen == 1: thaw enemy
	cmp	word [enemy_frozen],0x1	; 039A4
	jnz	short cutscene_play_enemy_far_locked_countdown		; 039A9 jnz 0x39cf
	db	0x33, 0xC0		; 039AB xor ax,ax
; Set up enemy to enter scene
	mov	word [scene_locked],0x20	; 039AD  scene_locked = 32
	mov	word [enemy_anim_id],0x46	; 039B3  enemy_anim_id = entering
	mov	bx,[enemy_seq_run_in]		; 039B9
	mov	word [last_drawn_camera_x],0xffff	; 039BD  anim_state = none
	mov	[enemy_frozen],ax		; 039C3  enemy_frozen = 0
	mov	[enemy_frame_ptr],bx		; 039C6  enemy_frame_ptr
	add	sp,0x6			; 039CA
	pop	bp			; 039CD
	ret				; 039CE

cutscene_play_enemy_far_locked_countdown:
; --- Scene locked countdown ---
	mov	ax,[scene_locked]		; 039CF  scene_locked
	db	0x3D, 0x01, 0x00	; 039D2 cmp ax,0x1  > 1?
	jng	short cutscene_play_enemy_far_check_unlock		; 039D5 jng 0x39e2
	dec	word [scene_locked]		; 039D7  --scene_locked
	db	0x33, 0xC0		; 039DB xor ax,ax
	add	sp,0x6			; 039DD
	pop	bp			; 039E0
	ret				; 039E1

cutscene_play_enemy_far_check_unlock:
; scene_locked == 1: unlock and spawn enemy
	cmp	word [scene_locked],0x1	; 039E2
	jnz	short cutscene_play_return_0		; 039E7 jnz 0x3a26
	mov	word [scene_locked],0x0	; 039E9  scene_locked = 0

; Level 1: re-freeze enemy at far distance
	cmp	word [current_level],0x1		; 039EF  level 1?
	jnz	short cutscene_play_enemy_far_other_level		; 039F4 jnz 0x3a16
	mov	word [enemy_frozen],0x20	; 039F6  enemy_frozen = 32
	mov	word [last_drawn_camera_x],0xffff	; 039FC  anim_state = none
	mov	ax,[bp+0x4]		; 03A02  distance
	cmp	ax,0x320		; 03A05  > 800?
	jng	short cutscene_play_return_0		; 03A08 jng 0x3a26
; Very far: move enemy closer
	mov	bx,0x2			; 03A0A
	cwd				; 03A0D
	idiv	bx			; 03A0E  distance / 2
	sub	[enemy_x],ax		; 03A10  enemy_x -= distance/2
	jmp	short cutscene_play_return_0		; 03A14 jmp 0x3a26

cutscene_play_enemy_far_other_level:
; Other levels: trigger approach
	mov	ax,0x1			; 03A16
	dec	word [enemy_sprite_variant]		; 03A19  --enemy_sprite_variant
	mov	word [enemy_hit_points],0x0	; 03A1D  enemy_hit_points = 0
	mov	[combat_phase],ax		; 03A23  combat_phase = 1 (approach)

cutscene_play_return_0:
	db	0x33, 0xC0		; 03A26 xor ax,ax  return 0
	add	sp,0x6			; 03A28
	pop	bp			; 03A2B
	ret				; 03A2C
