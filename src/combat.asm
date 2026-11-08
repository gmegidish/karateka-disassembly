; Combat system: level init, state setup, player input, move resolution


; ---- function init_combat_level ----
; Initializes a new combat encounter/level. Loads animation data and
; scripts for the given level.
;
; Parameters:
;   [bp+0x8] = level number (0-4)
;
; Behavior:
;   - Calls load_sprite_set(level)
;   - Calls load_anim_script for levels < 4
;   - Calls compact_anim_data(1) for level < 2, compact_anim_data(6) for level >= 2
;   - Calls anti_tamper_check (anti-tamper check) for level 2
;   - Calls init_combat_state to set up initial combat state
init_combat_level:
	push	bp			; 01AC2
	sub	sp,0x4			; 01AC3
	jc	short init_combat_level_stack_overflow		; 01AC6 jc 0x1ace
	cmp	sp,[stack_limit]		; 01AC8
	ja	short init_combat_level_stack_ok		; 01ACC ja 0x1ad1
init_combat_level_stack_overflow:
	jmp	near stack_overflow_handler			; 01ACE
init_combat_level_stack_ok:
	db	0x8B, 0xEC		; 01AD1 mov bp,sp
	push	word [bp+0x8]		; 01AD3
	call	load_sprite_set		; 01AD6
	db	0x8B, 0xE5		; 01AD9 mov sp,bp
	mov	ax,[bp+0x8]		; 01ADB
	db	0x3D, 0x04, 0x00	; 01ADE cmp ax,0x4
	jnl	short init_combat_level_check_anti_tamper		; 01AE1 jnl 0x1b0e
	shl	ax,1			; 01AE3
	db	0x8B, 0xF0		; 01AE5 mov si,ax
	mov	ax,0xc102		; 01AE7
	push	ax			; 01AEA
	push	word [si+level_anim_script_names]		; 01AEB
	call	load_anim_script	; 01AEF
	db	0x8B, 0xE5		; 01AF2 mov sp,bp
	cmp	word [bp+0x8],0x2	; 01AF4
	jnl	short init_combat_level_compact_for_later_levels		; 01AF8 jnl 0x1b05
	mov	ax,0x1			; 01AFA
	push	ax			; 01AFD
	call	compact_anim_data		; 01AFE
	db	0x8B, 0xE5		; 01B01 mov sp,bp
	jmp	short init_combat_level_check_anti_tamper		; 01B03 jmp 0x1b0e
init_combat_level_compact_for_later_levels:
	mov	ax,0x6			; 01B05
	push	ax			; 01B08
	call	compact_anim_data		; 01B09
	db	0x8B, 0xE5		; 01B0C mov sp,bp
init_combat_level_check_anti_tamper:
	cmp	word [bp+0x8],0x2	; 01B0E
	jnz	short init_combat_level_init_state		; 01B12 jnz 0x1b17
	call	anti_tamper_check		; 01B14
init_combat_level_init_state:
	push	word [bp+0x8]		; 01B17
	call	init_combat_state	; 01B1A
	db	0x8B, 0xE5		; 01B1D mov sp,bp
	call	flush_keyboard		; 01B1F
	add	sp,0x4			; 01B22
	pop	bp			; 01B25
	ret				; 01B26

; ---- function init_combat_state ----
; Initializes all combat state variables for a new encounter.
;
; Parameters:
;   [bp+0xa] = level number
;
; Behavior:
;   - Sets player position from level tables at [si+0x2E6], [si+0x2F0], etc.
;   - Sets camera bounds [0x108], player bounds [0x100]-[0x104]
;   - Calls spawn_enemy to position the enemy
;   - For level 3: sets up special scene slot flags [0x132]-[0x144]
;   - Sets enemy health: 13 (level < 2), 12 (level 2), 10 (level 3)
;   - Resets combat_active, hit regen timers, etc.
init_combat_state:
	push	bp			; 01B27
	sub	sp,0x6			; 01B28
	jc	short init_combat_state_stack_overflow		; 01B2B jc 0x1b33
	cmp	sp,[stack_limit]		; 01B2D
	ja	short init_combat_state_stack_ok		; 01B31 ja 0x1b36
init_combat_state_stack_overflow:
	jmp	near stack_overflow_handler			; 01B33
init_combat_state_stack_ok:
	db	0x8B, 0xEC		; 01B36 mov bp,sp
	mov	word [enemy_sprite_variant],0xffff	; 01B38
	db	0x33, 0xC0		; 01B3E xor ax,ax
	mov	bx,[bp+0xa]		; 01B40
	cmp	bx,0x2			; 01B43
	mov	[draw_health_bars_pending],ax		; 01B46
	mov	[camera_x],ax		; 01B49
	jz	short init_combat_state_set_transition_pending		; 01B4C jz 0x1b53
	cmp	bx,0x4			; 01B4E
	jnz	short init_combat_state_load_level_positions		; 01B51 jnz 0x1b59
init_combat_state_set_transition_pending:
	mov	word [draw_health_bars_pending],0x1	; 01B53
init_combat_state_load_level_positions:
	mov	word [anim_render_mode],0x1		; 01B59
	mov	word [last_drawn_camera_x],0xffff	; 01B5F
	mov	ax,[bp+0xa]		; 01B65
	shl	ax,1			; 01B68
	db	0x8B, 0xF0		; 01B6A mov si,ax
	mov	bx,[si+level_player_start_x]		; 01B6C
	mov	cx,[si+level_player_x_min]		; 01B70
	mov	dx,[si+level_player_x_max]		; 01B74
	mov	[player_x],bx		; 01B78
	mov	bx,[si+level_camera_x_min]		; 01B7C
	mov	[camera_x_min],bx		; 01B80
	mov	bx,[si+level_camera_x_max]		; 01B84
	mov	ax,[si+level_enemy_x_min]		; 01B88
	push	word [bp+0xa]		; 01B8C
	mov	[enemy_x_min],ax		; 01B8F
	mov	[player_x_min],cx		; 01B92
	mov	[encounter_target],dx		; 01B96
	mov	[player_x_max],dx		; 01B9A
	mov	[camera_x_max],bx		; 01B9E
	call	spawn_enemy		; 01BA2
	db	0x8B, 0xE5		; 01BA5 mov sp,bp
	cmp	word [bp+0xa],0x3	; 01BA7
	jnz	short init_combat_state_after_level3_slots		; 01BAB jnz 0x1bed
	mov	ax,0x1			; 01BAD
	mov	word [scene_enemy_pending_6],0x0	; 01BB0
	mov	word [scene_enemy_pending_7],0x3	; 01BB6
	mov	word [bp+0x4],0x2	; 01BBC
	mov	[scene_enemy_pending],ax		; 01BC1
	mov	[scene_enemy_pending_1],ax		; 01BC4
	mov	[scene_enemy_pending_3],ax		; 01BC7
	mov	[scene_enemy_pending_4],ax		; 01BCA
	mov	[scene_enemy_pending_5],ax		; 01BCD
init_combat_state_clear_slot_flags_loop:
	mov	ax,[bp+0x4]		; 01BD0
	db	0x3D, 0x07, 0x00	; 01BD3 cmp ax,0x7
	jnl	short init_combat_state_slot_flags_done		; 01BD6 jnl 0x1be7
	shl	ax,1			; 01BD8
	db	0x8B, 0xF0		; 01BDA mov si,ax
	mov	word [si+scene_slot_flags],0x0	; 01BDC
	inc	word [bp+0x4]		; 01BE2
	jmp	short init_combat_state_clear_slot_flags_loop		; 01BE5 jmp 0x1bd0
init_combat_state_slot_flags_done:
	mov	word [scene_slot_flags_1],0x1	; 01BE7
init_combat_state_after_level3_slots:
	mov	ax,[bp+0xa]		; 01BED
	db	0x3D, 0x01, 0x00	; 01BF0 cmp ax,0x1
	jz	short init_combat_state_set_enemy_health		; 01BF3 jz 0x1c06
	db	0x3D, 0x04, 0x00	; 01BF5 cmp ax,0x4
	jz	short init_combat_state_set_enemy_health		; 01BF8 jz 0x1c06
	mov	ax,[player_seq_stand_idle]		; 01BFA
	mov	word [player_anim_id],0x41	; 01BFD
	mov	[player_frame_ptr],ax		; 01C03
init_combat_state_set_enemy_health:
	mov	word [anim_render_mode],0x1		; 01C06
	mov	word [combat_active],0x0		; 01C0C
	cmp	word [bp+0xa],0x2	; 01C12
	jnl	short init_combat_state_enemy_health_level2		; 01C16 jnl 0x1c20
	mov	word [player_hit_points],0xd	; 01C18
	jmp	short init_combat_state_reset_regen		; 01C1E jmp 0x1c3a
init_combat_state_enemy_health_level2:
	cmp	word [bp+0xa],0x2	; 01C20
	jnz	short init_combat_state_enemy_health_level3		; 01C24 jnz 0x1c2e
	mov	word [player_hit_points],0xc	; 01C26
	jmp	short init_combat_state_reset_regen		; 01C2C jmp 0x1c3a
init_combat_state_enemy_health_level3:
	cmp	word [bp+0xa],0x3	; 01C2E
	jnz	short init_combat_state_reset_regen		; 01C32 jnz 0x1c3a
	mov	word [player_hit_points],0xa	; 01C34
init_combat_state_reset_regen:
	db	0x33, 0xC0		; 01C3A xor ax,ax
	mov	bx,[player_regen_rate]		; 01C3C
	cmp	word [bp+0xa],0x0	; 01C40
	mov	[player_regen_pending],ax		; 01C44
	mov	[wipe_prev_left],ax		; 01C47
	mov	[player_regen_timer],bx		; 01C4A
	jnz	short init_combat_state_exit		; 01C4E jnz 0x1c53
	mov	[enemy_aggressive],ax		; 01C50
init_combat_state_exit:
	add	sp,0x6			; 01C53
	pop	bp			; 01C56
	ret				; 01C57

; ---- function spawn_enemy ----
; Spawns/positions the enemy for a new encounter.
;
; Parameters:
;   [bp+0x6] = level number
;
; Behavior:
;   - Sets enemy X from table at [bx+0x2DC]
;   - Sets enemy animation (0x41 idle for level < 2, 0x01 walk for level >= 2)
;   - Sets enemy_atk_freq (0x78 for level < 2, 0xA0 for level >= 2)
;   - Sets initial combat_hits_left from health calculation
;   - Resets hit exchange counter, regen timers
;   - Increments enemy_sprite_variant [0x158] (up to max 4)
; enemy_hit_points is 13 for levels 0-1, else 0x1A - player_hit_points - player_regen_pending.
; Level 3 with scene_index > 1 places the enemy 0x140 further left.
spawn_enemy:
	push	bp			; 01C58
	sub	sp,0x2			; 01C59
	jc	short spawn_enemy_stack_overflow		; 01C5C jc 0x1c64
	cmp	sp,[stack_limit]		; 01C5E
	ja	short spawn_enemy_stack_ok		; 01C62 ja 0x1c67
spawn_enemy_stack_overflow:
	jmp	near stack_overflow_handler			; 01C64
spawn_enemy_stack_ok:
	db	0x8B, 0xEC		; 01C67 mov bp,sp
	mov	ax,0x1			; 01C69
	mov	bx,[bp+0x6]		; 01C6C
	shl	bx,1			; 01C6F
	mov	cx,[bx+level_enemy_start_x]		; 01C71
	cmp	word [bp+0x6],0x3	; 01C75
	mov	[enemy_spawned_flag],ax		; 01C79
	mov	[enemy_x],cx		; 01C7C
	jnz	short spawn_enemy_set_animation		; 01C80 jnz 0x1c8f
	cmp	word [scene_index],0x1	; 01C82
	jng	short spawn_enemy_set_animation		; 01C87 jng 0x1c8f
	sub	word [enemy_x],0x140	; 01C89
spawn_enemy_set_animation:
	cmp	word [bp+0x6],0x2	; 01C8F
	jnl	short spawn_enemy_walk_animation		; 01C93 jnl 0x1ca3
	mov	word [enemy_anim_id],0x41	; 01C95
	mov	ax,[enemy_seq_stand_idle]		; 01C9B
	mov	[enemy_frame_ptr],ax		; 01C9E
	jmp	short spawn_enemy_set_attack_freq		; 01CA1 jmp 0x1caf
spawn_enemy_walk_animation:
	mov	word [enemy_anim_id],0x1	; 01CA3
	mov	ax,[enemy_seq_offsets]		; 01CA9
	mov	[enemy_frame_ptr],ax		; 01CAC
spawn_enemy_set_attack_freq:
	db	0x33, 0xC0		; 01CAF xor ax,ax
	cmp	word [bp+0x6],0x2	; 01CB1
	mov	[combat_phase],ax		; 01CB5
	mov	[player_faces_right],ax		; 01CB8
	jnl	short spawn_enemy_high_attack_freq		; 01CBB jnl 0x1cc5
	mov	word [enemy_atk_freq],0x78	; 01CBD
	jmp	short spawn_enemy_set_player_hits		; 01CC3 jmp 0x1ccb
spawn_enemy_high_attack_freq:
	mov	word [enemy_atk_freq],0xa0	; 01CC5
spawn_enemy_set_player_hits:
	mov	word [enemy_hit_points],0xd	; 01CCB
	cmp	word [bp+0x6],0x1	; 01CD1
	jng	short spawn_enemy_reset_encounter_state		; 01CD5 jng 0x1ce5
	mov	ax,0x1a			; 01CD7
	sub	ax,[player_hit_points]		; 01CDA
	sub	ax,[player_regen_pending]		; 01CDE
	mov	[enemy_hit_points],ax		; 01CE2
spawn_enemy_reset_encounter_state:
	db	0x33, 0xC0		; 01CE5 xor ax,ax
	mov	bx,[enemy_regen_rate]		; 01CE7
	mov	cx,[enemy_sprite_variant]		; 01CEB
	cmp	cx,0x4			; 01CEF
	mov	[enemy_regen_pending],ax		; 01CF2
	mov	[wipe_prev_right],ax		; 01CF5
	mov	[enemy_regen_timer],bx		; 01CF8
	jnl	short spawn_enemy_exit		; 01CFC jnl 0x1d02
	inc	word [enemy_sprite_variant]		; 01CFE
spawn_enemy_exit:
	add	sp,0x2			; 01D02
	pop	bp			; 01D05
	ret				; 01D06

; ---- function read_player_input ----
; Reads the player's keyboard/joystick input and translates to a combat move.
;
; Parameters: none (reads keyboard)
; Output: AX = animation index, or -1 (0xFFFF) if no valid input
;
; Behavior:
;   1. If [0x16E] > 0 (input suppressed), return -1
;   2. Call poll_keyboard(0) to check for input
;   3. If key available: call get_pending_key, then key_to_move to translate
;   4. If valid move: call combat_resolve_move to validate against current pose
;   5. If move rejected: store key in [0xDF42]/[0xDF43] for later
;   6. If accepted: look up animation from table at [si-0x3C2C],
;      set [0xE6]=1, update player frame pointer
read_player_input:
	push	bp			; 01D07
	sub	sp,0x6			; 01D08
	jc	short read_player_input_stack_overflow		; 01D0B jc 0x1d13
	cmp	sp,[stack_limit]		; 01D0D
	ja	short read_player_input_stack_ok		; 01D11 ja 0x1d16
read_player_input_stack_overflow:
	jmp	near stack_overflow_handler			; 01D13
read_player_input_stack_ok:
	db	0x8B, 0xEC		; 01D16 mov bp,sp
	cmp	word [combat_counter_b],0x0	; 01D18
	jng	short read_player_input_poll_keyboard		; 01D1D jng 0x1d27
	mov	ax,0xffff		; 01D1F
	add	sp,0x6			; 01D22
	pop	bp			; 01D25
	ret				; 01D26
read_player_input_poll_keyboard:
	db	0x33, 0xC0		; 01D27 xor ax,ax
	push	ax			; 01D29
	call	poll_keyboard		; 01D2A
	db	0x8B, 0xE5		; 01D2D mov sp,bp
	test	ax,ax			; 01D2F
	jz	short read_player_input_return_none		; 01D31 jz 0x1d82
	call	get_pending_key		; 01D33
	push	ax			; 01D36
	mov	[bp+0x4],ax		; 01D37
	call	key_to_move		; 01D3A
	db	0x8B, 0xE5		; 01D3D mov sp,bp
	mov	[bp+0x2],ax		; 01D3F
	inc	ax			; 01D42
	jz	short read_player_input_apply_move		; 01D43 jz 0x1d61
	push	word [bp+0x4]		; 01D45
	push	word [bp+0x2]		; 01D48
	call	combat_resolve_move	; 01D4B
	db	0x8B, 0xE5		; 01D4E mov sp,bp
	mov	[bp+0x2],ax		; 01D50
	inc	ax			; 01D53
	jnz	short read_player_input_apply_move		; 01D54 jnz 0x1d61
	mov	ax,[bp+0x4]		; 01D56
	mov	byte [key_pending],0x1	; 01D59
	mov	[pending_key],al		; 01D5E
read_player_input_apply_move:
	mov	ax,[bp+0x2]		; 01D61
	db	0x3D, 0xFF, 0xFF	; 01D64 cmp ax,0xffff
	jz	short read_player_input_return_none		; 01D67 jz 0x1d82
	shl	ax,1			; 01D69
	db	0x8B, 0xF0		; 01D6B mov si,ax
	mov	ax,[si+player_seq_offsets]		; 01D6D
	mov	word [player_moved_flag],0x1		; 01D71
	mov	[player_frame_ptr],ax		; 01D77
	mov	ax,[bp+0x2]		; 01D7A
	add	sp,0x6			; 01D7D
	pop	bp			; 01D80
	ret				; 01D81
read_player_input_return_none:
	mov	ax,0xffff		; 01D82
	add	sp,0x6			; 01D85
	pop	bp			; 01D88
	ret				; 01D89

; ---- function get_pending_key ----
; Reads the latest keystroke, draining any buffered repeats in joystick mode.
;   - If joystick mode [0xDF46]=1: loops reading keys until buffer empty, returns last
;   - If keyboard mode: reads one key, returns it
;
; Input: none
; Output: AX = key code, or 0 if none
; Correction: [0xDF46]=1 means keyboard-only (init_controls found no joystick, or 'k' pressed) and is the mode that drains to the last key. [0xDF46]=0 is joystick mode: poll_keyboard calls check_joystick, and one key is read.
get_pending_key:
	push	bp			; 01D8A
	sub	sp,0x4			; 01D8B
	jc	short get_pending_key_stack_overflow		; 01D8E jc 0x1d96
	cmp	sp,[stack_limit]		; 01D90
	ja	short get_pending_key_stack_ok		; 01D94 ja 0x1d99
get_pending_key_stack_overflow:
	jmp	near stack_overflow_handler			; 01D96
get_pending_key_stack_ok:
	db	0x8B, 0xEC		; 01D99 mov bp,sp
	mov	word [bp+0x2],0x0	; 01D9B
	cmp	word [keyboard_only],0x1	; 01DA0
	jnz	short get_pending_key_read_single		; 01DA5 jnz 0x1dbb
get_pending_key_drain_loop:
	db	0x33, 0xC0		; 01DA7 xor ax,ax
	push	ax			; 01DA9
	call	poll_keyboard		; 01DAA
	db	0x8B, 0xE5		; 01DAD mov sp,bp
	test	ax,ax			; 01DAF
	jz	short get_pending_key_return		; 01DB1 jz 0x1dcd
	call	wait_for_key		; 01DB3
	mov	[bp+0x2],ax		; 01DB6
	jmp	short get_pending_key_drain_loop		; 01DB9 jmp 0x1da7
get_pending_key_read_single:
	db	0x33, 0xC0		; 01DBB xor ax,ax
	push	ax			; 01DBD
	call	poll_keyboard		; 01DBE
	db	0x8B, 0xE5		; 01DC1 mov sp,bp
	test	ax,ax			; 01DC3
	jz	short get_pending_key_return		; 01DC5 jz 0x1dcd
	call	wait_for_key		; 01DC7
	mov	[bp+0x2],ax		; 01DCA
get_pending_key_return:
	mov	ax,[bp+0x2]		; 01DCD
	add	sp,0x4			; 01DD0
	pop	bp			; 01DD3
	ret				; 01DD4

; ---- function key_to_move ----
; Translates a raw key code to a combat move index (1-11).
;
; Input: [bp+0xa] = key code
; Output: AX = move index (1-11), or -1 if not a combat key
;
; Key mappings:
;   'j' (0x6A) = toggle joystick off, return -1
;   'k' (0x6B) = toggle joystick on, return -1
;   Ctrl+R (0x12) = set restart flag [0x16A]=1
;   Ctrl+S (0x13) = toggle sound [0xD6BC]
;   Ctrl+X (0x18) = toggle debug [0xE1AC]
;   Ctrl+Y (0x19) = toggle debug [0xE1AB]
;   Ctrl+E (0x05) = toggle debug [0xE1AD]
;   Ctrl+B (0x02) = toggle debug [0xE1AE]
;   Ctrl+N (0x0E) = clear all debug flags
;   '&' (0x26) = force player anim to 0x41 if < 0x40, return move 8
;   Space/printable (>= 0x20): look up in 11-entry move table at [si+0x322]
; The 11-entry table at DS:0x322 is the string 'qazwsx46 b0'; the returned move is table index + 1.
; Correction: 'j' sets [0xDF46]=0 (joystick polled) and 'k' sets it to 1 (keyboard only).
; '4' is rejected at player_x_min. Moves 1-6 are rejected when player_anim_id >= 0x40; 'b' and '0' are rejected when it is below 0x40.
key_to_move:
	push	bp			; 01DD5
	sub	sp,0x6			; 01DD6
	jc	short key_to_move_stack_overflow		; 01DD9 jc 0x1de1
	cmp	sp,[stack_limit]		; 01DDB
	ja	short key_to_move_stack_ok		; 01DDF ja 0x1de4
key_to_move_stack_overflow:
	jmp	near stack_overflow_handler			; 01DE1
key_to_move_stack_ok:
	db	0x8B, 0xEC		; 01DE4 mov bp,sp
	mov	ax,[bp+0xa]		; 01DE6
	db	0x3D, 0x41, 0x00	; 01DE9 cmp ax,0x41
	jl	short key_to_move_check_j_key		; 01DEC jl 0x1df7
	db	0x3D, 0x5A, 0x00	; 01DEE cmp ax,0x5a
	jg	short key_to_move_check_j_key		; 01DF1 jg 0x1df7
	add	word [bp+0xa],0x20	; 01DF3
key_to_move_check_j_key:
	cmp	word [bp+0xa],0x6a	; 01DF7
	jnz	short key_to_move_check_k_key		; 01DFB jnz 0x1e0e
	call	play_sound_5_forced		; 01DFD
	mov	word [keyboard_only],0x0	; 01E00
	mov	ax,0xffff		; 01E06
	add	sp,0x6			; 01E09
	pop	bp			; 01E0C
	ret				; 01E0D
key_to_move_check_k_key:
	cmp	word [bp+0xa],0x6b	; 01E0E
	jnz	short key_to_move_check_control_key		; 01E12 jnz 0x1e25
	call	play_sound_5_forced		; 01E14
	mov	word [keyboard_only],0x1	; 01E17
	mov	ax,0xffff		; 01E1D
	add	sp,0x6			; 01E20
	pop	bp			; 01E23
	ret				; 01E24
key_to_move_check_control_key:
	mov	ax,[bp+0xa]		; 01E25
	db	0x3D, 0x20, 0x00	; 01E28 cmp ax,0x20
	jl	short key_to_move_check_ctrl_r		; 01E2B jl 0x1e30
	jmp	near key_to_move_printable_key			; 01E2D
key_to_move_check_ctrl_r:
	db	0x3D, 0x12, 0x00	; 01E30 cmp ax,0x12
	jnz	short key_to_move_check_ctrl_s		; 01E33 jnz 0x1e3d
	mov	word [game_restart_flag],0x1	; 01E35
	jmp	short key_to_move_control_key_return_none		; 01E3B jmp 0x1eb0
key_to_move_check_ctrl_s:
	cmp	word [bp+0xa],0x13	; 01E3D
	jnz	short key_to_move_check_ctrl_x		; 01E41 jnz 0x1e50
	mov	al,[sound_mode]		; 01E43
	xor	ah,ah			; 01E46
	xor	ax,0xff			; 01E48
	mov	[sound_mode],al		; 01E4B
	jmp	short key_to_move_control_key_return_none		; 01E4E jmp 0x1eb0
key_to_move_check_ctrl_x:
	cmp	word [bp+0xa],0x18	; 01E50
	jnz	short key_to_move_check_ctrl_y		; 01E54 jnz 0x1e63
	mov	al,[joy_swap_up_down]		; 01E56
	xor	ah,ah			; 01E59
	xor	ax,0xff			; 01E5B
	mov	[joy_swap_up_down],al		; 01E5E
	jmp	short key_to_move_control_key_return_none		; 01E61 jmp 0x1eb0
key_to_move_check_ctrl_y:
	cmp	word [bp+0xa],0x19	; 01E63
	jnz	short key_to_move_check_ctrl_e		; 01E67 jnz 0x1e76
	mov	al,[joy_swap_left_right]		; 01E69
	xor	ah,ah			; 01E6C
	xor	ax,0xff			; 01E6E
	mov	[joy_swap_left_right],al		; 01E71
	jmp	short key_to_move_control_key_return_none		; 01E74 jmp 0x1eb0
key_to_move_check_ctrl_e:
	cmp	word [bp+0xa],0x5	; 01E76
	jnz	short key_to_move_check_ctrl_b		; 01E7A jnz 0x1e89
	mov	al,[joy_swap_axes]		; 01E7C
	xor	ah,ah			; 01E7F
	xor	ax,0xff			; 01E81
	mov	[joy_swap_axes],al		; 01E84
	jmp	short key_to_move_control_key_return_none		; 01E87 jmp 0x1eb0
key_to_move_check_ctrl_b:
	cmp	word [bp+0xa],0x2	; 01E89
	jnz	short key_to_move_check_ctrl_n		; 01E8D jnz 0x1e9c
	mov	al,[joy_swap_buttons]		; 01E8F
	xor	ah,ah			; 01E92
	xor	ax,0xff			; 01E94
	mov	[joy_swap_buttons],al		; 01E97
	jmp	short key_to_move_control_key_return_none		; 01E9A jmp 0x1eb0
key_to_move_check_ctrl_n:
	cmp	word [bp+0xa],0xe	; 01E9C
	jnz	short key_to_move_control_key_return_none		; 01EA0 jnz 0x1eb0
	mov	al,0x0			; 01EA2
	mov	[joy_swap_buttons],al		; 01EA4
	mov	[joy_swap_axes],al		; 01EA7
	mov	[joy_swap_left_right],al		; 01EAA
	mov	[joy_swap_up_down],al		; 01EAD
key_to_move_control_key_return_none:
	mov	ax,0xffff		; 01EB0
	add	sp,0x6			; 01EB3
	pop	bp			; 01EB6
	ret				; 01EB7
; Reached from 01E2D when the key is >= 0x20: handles '&' (0x26), then the 11-entry move table at [si+0x322].
key_to_move_printable_key:
	cmp	word [bp+0xa],0x26	; 01EB8
	jnz	short key_to_move_start_table_search		; 01EBC jnz 0x1ed3
	cmp	word [player_anim_id],0x40	; 01EBE
	jnl	short key_to_move_ampersand_return_move_8		; 01EC3 jnl 0x1ecb
	mov	word [player_anim_id],0x41	; 01EC5
key_to_move_ampersand_return_move_8:
	mov	ax,0x8			; 01ECB
	add	sp,0x6			; 01ECE
	pop	bp			; 01ED1
	ret				; 01ED2
key_to_move_start_table_search:
	mov	word [bp+0x2],0x0	; 01ED3
key_to_move_table_search_loop:
	mov	ax,[bp+0x2]		; 01ED8
	db	0x3D, 0x0B, 0x00	; 01EDB cmp ax,0xb
	jnl	short key_to_move_table_search_done		; 01EDE jnl 0x1ef4
	db	0x8B, 0xF0		; 01EE0 mov si,ax
	mov	al,[si+move_key_table]		; 01EE2
	xor	ah,ah			; 01EE6
	mov	bx,[bp+0xa]		; 01EE8
	db	0x3B, 0xD8		; 01EEB cmp bx,ax
	jz	short key_to_move_table_search_done		; 01EED jz 0x1ef4
	inc	word [bp+0x2]		; 01EEF
	jmp	short key_to_move_table_search_loop		; 01EF2 jmp 0x1ed8
key_to_move_table_search_done:
	cmp	word [bp+0x2],0xb	; 01EF4
	jnz	short key_to_move_check_left_boundary		; 01EF8 jnz 0x1f02
	mov	ax,0xffff		; 01EFA
	add	sp,0x6			; 01EFD
	pop	bp			; 01F00
	ret				; 01F01
; Key '4' (table index 6) is rejected when the player is already at player_x_min.
key_to_move_check_left_boundary:
	cmp	word [bp+0x2],0x6	; 01F02
	jnz	short key_to_move_check_anim_range		; 01F06 jnz 0x1f19
	mov	ax,[player_x]		; 01F08
	cmp	ax,[player_x_min]		; 01F0B
	jnz	short key_to_move_check_anim_range		; 01F0F jnz 0x1f19
	mov	ax,0xffff		; 01F11
	add	sp,0x6			; 01F14
	pop	bp			; 01F17
	ret				; 01F18
key_to_move_check_anim_range:
	cmp	word [player_anim_id],0x3f	; 01F19
	jng	short key_to_move_anim_below_40_check_move		; 01F1E jng 0x1f37
	cmp	word [bp+0x2],0x6	; 01F20
	jnl	short key_to_move_anim_40_up_return_move		; 01F24 jnl 0x1f2e
	mov	ax,0xffff		; 01F26
	add	sp,0x6			; 01F29
	pop	bp			; 01F2C
	ret				; 01F2D
key_to_move_anim_40_up_return_move:
	mov	ax,[bp+0x2]		; 01F2E
	inc	ax			; 01F31
	add	sp,0x6			; 01F32
	pop	bp			; 01F35
	ret				; 01F36
key_to_move_anim_below_40_check_move:
	cmp	word [bp+0x2],0x8	; 01F37
	jng	short key_to_move_anim_below_40_return_move		; 01F3B jng 0x1f45
	mov	ax,0xffff		; 01F3D
	add	sp,0x6			; 01F40
	pop	bp			; 01F43
	ret				; 01F44
key_to_move_anim_below_40_return_move:
	mov	ax,[bp+0x2]		; 01F45
	inc	ax			; 01F48
	add	sp,0x6			; 01F49
	pop	bp			; 01F4C
	ret				; 01F4D

; ---- function combat_resolve_move ----
; Validates a combat move against the player's current animation pose
; and remaps to the actual animation ID.
;
; Input:
;   [bp+0x6] = move index from key_to_move
;   [bp+0x8] = raw key code
; Output: AX = animation ID to play, or -1 if move invalid for current state
;
; Uses jump table at 0x200A (14 entries) indexed by current player
; animation state [0x10C]. Each handler checks the move index and
; returns an animation ID or -1 (reject).
combat_resolve_move:
	push	bp			; 01F4E
	sub	sp,0x2			; 01F4F
	jc	short combat_resolve_move_stack_overflow		; 01F52 jc 0x1f5a
	cmp	sp,[stack_limit]		; 01F54
	ja	short combat_resolve_move_stack_ok		; 01F58 ja 0x1f5d
combat_resolve_move_stack_overflow:
	jmp	near stack_overflow_handler			; 01F5A
combat_resolve_move_stack_ok:
	db	0x8B, 0xEC		; 01F5D mov bp,sp
	mov	ax,[player_anim_id]		; 01F5F
	jmp	near combat_resolve_move_scan_table_start			; 01F62
; Jump table case, player_anim_id 0x01: accept any move, return the move index unchanged.
combat_resolve_move_any_move:
	mov	ax,[bp+0x6]		; 01F65
	add	sp,0x2			; 01F68
	pop	bp			; 01F6B
	ret				; 01F6C
; Jump table case, player_anim_id 0x02-0x04 and 0x2A-0x2C: accept moves below 4 unchanged, else reject.
combat_resolve_move_moves_below_4:
	mov	ax,[bp+0x6]		; 01F6D
	db	0x3D, 0x04, 0x00	; 01F70 cmp ax,0x4
	jl	short combat_resolve_move_below_4_return		; 01F73 jl 0x1f78
	jmp	near combat_resolve_move_reject			; 01F75
combat_resolve_move_below_4_return:
	add	sp,0x2			; 01F78
	pop	bp			; 01F7B
	ret				; 01F7C
; Jump table case, player_anim_id 0x05-0x07: accept moves 4-6, return move + 0x14, else reject.
combat_resolve_move_moves_4_to_6:
	mov	ax,[bp+0x6]		; 01F7D
	db	0x3D, 0x03, 0x00	; 01F80 cmp ax,0x3
	jg	short combat_resolve_move_4_to_6_check_upper		; 01F83 jg 0x1f88
	jmp	near combat_resolve_move_reject			; 01F85
combat_resolve_move_4_to_6_check_upper:
	db	0x3D, 0x07, 0x00	; 01F88 cmp ax,0x7
	jl	short combat_resolve_move_4_to_6_return_anim		; 01F8B jl 0x1f90
	jmp	near combat_resolve_move_reject			; 01F8D
combat_resolve_move_4_to_6_return_anim:
	db	0x05, 0x14, 0x00	; 01F90 add ax,0x14
	add	sp,0x2			; 01F93
	pop	bp			; 01F96
	ret				; 01F97
; Jump table case, player_anim_id 0x0A-0x0B: accept moves 7 and 8, return move + 5, else reject.
combat_resolve_move_moves_7_8:
	mov	ax,[bp+0x6]		; 01F98
	db	0x3D, 0x07, 0x00	; 01F9B cmp ax,0x7
	jz	short combat_resolve_move_7_8_return_anim		; 01F9E jz 0x1fa8
	db	0x3D, 0x08, 0x00	; 01FA0 cmp ax,0x8
	jz	short combat_resolve_move_7_8_return_anim		; 01FA3 jz 0x1fa8
	jmp	near combat_resolve_move_reject			; 01FA5
combat_resolve_move_7_8_return_anim:
	mov	ax,[bp+0x6]		; 01FA8
	db	0x05, 0x05, 0x00	; 01FAB add ax,0x5
	add	sp,0x2			; 01FAE
	pop	bp			; 01FB1
	ret				; 01FB2
; Jump table case, player_anim_id 0x41: move 8 -> 0x14, move 9 -> 0x0A, move 0x0A -> 0x0B, else reject.
combat_resolve_move_anim_41:
	cmp	word [bp+0x6],0x8	; 01FB3
	jnz	short combat_resolve_move_anim_41_check_move_9		; 01FB7 jnz 0x1fc1
	mov	ax,0x14			; 01FB9
	add	sp,0x2			; 01FBC
	pop	bp			; 01FBF
	ret				; 01FC0
combat_resolve_move_anim_41_check_move_9:
	cmp	word [bp+0x6],0x9	; 01FC1
	jnz	short combat_resolve_move_anim_41_check_move_10		; 01FC5 jnz 0x1fcf
	mov	ax,0xa			; 01FC7
	add	sp,0x2			; 01FCA
	pop	bp			; 01FCD
	ret				; 01FCE
combat_resolve_move_anim_41_check_move_10:
	cmp	word [bp+0x6],0xa	; 01FCF
	jz	short combat_resolve_move_anim_41_return_move_10_anim		; 01FD3 jz 0x1fd8
	jmp	0x2256			; 01FD5
combat_resolve_move_anim_41_return_move_10_anim:
	mov	ax,0xb			; 01FD8
	add	sp,0x2			; 01FDB
	pop	bp			; 01FDE
	ret				; 01FDF
; Jump table case, player_anim_id 0x46: move 7 -> 0x13, move 9 -> 0x10, move 0x0B -> 0x13, else reject.
combat_resolve_move_anim_46:
	cmp	word [bp+0x6],0x7	; 01FE0
	jnz	short combat_resolve_move_anim_46_check_move_9		; 01FE4 jnz 0x1fee
	mov	ax,0x13			; 01FE6
	add	sp,0x2			; 01FE9
	pop	bp			; 01FEC
	ret				; 01FED
combat_resolve_move_anim_46_check_move_9:
	cmp	word [bp+0x6],0x9	; 01FEE
	jnz	short combat_resolve_move_anim_46_check_move_11		; 01FF2 jnz 0x1ffc
	mov	ax,0x10			; 01FF4
	add	sp,0x2			; 01FF7
	pop	bp			; 01FFA
	ret				; 01FFB
combat_resolve_move_anim_46_check_move_11:
	cmp	word [bp+0x6],0xb	; 01FFC
	jnz	short combat_resolve_move_reject		; 02000 jnz 0x2056
	mov	ax,0x13			; 02002
	add	sp,0x2			; 02005
	pop	bp			; 02008
	ret				; 02009
; Data, not code: 14 {player_anim_id, handler} word pairs, scanned last to first by the dispatch at 02042.
; An animation with no entry falls through to the reject path at combat_resolve_move_reject.
combat_resolve_move_jump_table:
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
; AX = player_anim_id; sets SI to the last switch table entry before the backward scan
combat_resolve_move_scan_table_start:
	mov	si,0x34			; 02042
combat_resolve_move_scan_table_loop:
	cmp	ax,[cs:si+0x200a]	; 02045
	jnz	short combat_resolve_move_scan_previous_entry		; 0204A jnz 0x2051
	jmp	word near [cs:si+0x200c]	; 0204C
combat_resolve_move_scan_previous_entry:
	sub	si,0x4			; 02051
	jns	short combat_resolve_move_scan_table_loop		; 02054 jns 0x2045
combat_resolve_move_reject:
	mov	ax,0xffff		; 02056
	add	sp,0x2			; 02059
	pop	bp			; 0205C
	ret				; 0205D
