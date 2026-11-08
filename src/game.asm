; Game init, main loop, scene management, actor init


; ---- function game_init ----
; Master initialization and outer game loop. This is the top-level entry
; point called from main(). Sets up graphics, installs interrupt handlers,
; initializes controls, loads the game disk, then runs the main game loop.
;
; After game_main_loop returns, enters the FRAME LOOP (loc_00316):
;   timer_wait -> poll_keyboard -> scene_update -> resolve_hits -> render_figures
; Handles approach_flag [0x154] values: 2=vsync(8), 3=vsync(24), 4=vsync(22), else=vsync(1)
; Calls cutscene_play and handles scene transitions with fade effects.
; In this binary skip_disk_check (002A7) never returns, so the load_game_disk check and check_disk_prompt retry after it are unreachable, and the three pushed arguments are discarded.
; Actual frame loop order: poll_keyboard(1), timer_wait_3ticks, scene_update, resolve_hits, render_figures.
; The approach_flag values select play_sound indices 8, 24 and 22, else 1.
; [0x16a] is the restart flag: set by Ctrl+R in key_to_move or by a nonzero cutscene_play result.
game_init:
	push	bp			; 00255
	sub	sp,0x4			; 00256
	jc	short game_init_stack_overflow		; 00259 jc 0x261
	cmp	sp,[stack_limit]		; 0025B
	ja	short game_init_stack_ok		; 0025F ja 0x264
game_init_stack_overflow:
	jmp	0x420			; 00261
game_init_stack_ok:
	db	0x8B, 0xEC		; 00264 mov bp,sp
	mov	word [bp+0x2],0x0	; 00266
	call	noop_stub		; 0026B
	call	check_graphics_card	; 0026E
	test	ax,ax			; 00271
	jnz	short game_init_graphics_card_ok		; 00273 jnz 0x281
	mov	ax,str_no_graphics - DS_BASE	; 00275
	push	ax			; 00278
	call	puts		; 00279
	db	0x8B, 0xE5		; 0027C mov sp,bp
	call	exit	; 0027E
game_init_graphics_card_ok:
	call	patch_font_tables	; 00281
	call	install_handlers	; 00284
	call	init_controls		; 00287
	test	ax,ax			; 0028A
	jnz	short game_init_joystick_detected		; 0028C jnz 0x296
	mov	word [keyboard_only],0x1	; 0028E
	jmp	short game_init_verify_game_disk		; 00294 jmp 0x29c
; init_controls found a joystick: [0xdf46]=0 lets poll_keyboard read it.
game_init_joystick_detected:
	mov	word [keyboard_only],0x0	; 00296
; Disk-check retry loop. In this binary it never loops: skip_disk_check at 002A7 does not return.
game_init_verify_game_disk:
	mov	ax,0x737		; 0029C
	push	ax			; 0029F
	mov	ax,0x337		; 002A0
	push	ax			; 002A3
	db	0x33, 0xC0		; 002A4 xor ax,ax
	push	ax			; 002A6
	call	skip_disk_check	; 002A7
	db	0x8B, 0xE5		; 002AA mov sp,bp
	call	load_game_disk		; 002AC
	test	ax,ax			; 002AF
	jnz	short game_init_start_new_game		; 002B1 jnz 0x2b8
	call	check_disk_prompt	; 002B3
	jmp	short game_init_verify_game_disk		; 002B6 jmp 0x29c
; Reached from a successful disk check, from skip_disk_check, or on restart (Ctrl+R or input_advance > 0).
game_init_start_new_game:
	call	load_player_anim_data	; 002B8
	db	0x33, 0xC0		; 002BB xor ax,ax
	mov	word [enemy_hit_points],0xd	; 002BD
	mov	[enemy_frozen],ax		; 002C3
	mov	[scene_locked],ax		; 002C6
	mov	[scene_param_e2],ax		; 002C9
	mov	[game_mode],ax		; 002CC
	mov	[player_facing],ax		; 002CF
	mov	[player_flag_170],ax		; 002D2
	mov	[combat_counter_a],ax		; 002D5
	mov	[combat_counter_b],ax		; 002D8
	mov	[player_flag_172],ax		; 002DB
	mov	[player_flag_174],ax		; 002DE
	mov	[anim_row_reload_state],ax		; 002E1
	mov	[player_moved_flag],ax		; 002E4
	mov	[enemy_spawned_flag],ax		; 002E7
	mov	[player_faces_right],ax		; 002EA
	mov	[enemy_aggressive],ax		; 002ED
	mov	[combat_active],ax		; 002F0
	mov	[combat_phase],ax		; 002F3
	mov	[scroll_counter],ax		; 002F6
	mov	[scene_index],ax		; 002F9
	mov	[approach_timer],ax		; 002FC
	mov	[special_enemy_active],ax		; 002FF
	call	game_main_loop		; 00302
	db	0x33, 0xC0		; 00305 xor ax,ax
	mov	[player_was_hit],ax		; 00307
	mov	[scene_index],ax		; 0030A
	call	timer_mark		; 0030D
	mov	word [game_restart_flag],0x0	; 00310
; per-frame gameplay loop: exits on game_restart_flag==1 or input_advance>0
game_init_frame_loop:
	cmp	word [game_restart_flag],0x1	; 00316
	jz	short game_init_start_new_game		; 0031B jz 0x2b8
	cmp	word [input_advance],0x0	; 0031D
	jg	short game_init_start_new_game		; 00322 jg 0x2b8
	mov	ax,0x1			; 00324
	push	ax			; 00327
	call	poll_keyboard		; 00328
	db	0x8B, 0xE5		; 0032B mov sp,bp
	call	timer_wait_3ticks	; 0032D
	call	scene_update		; 00330
	call	resolve_hits		; 00333
	call	render_figures		; 00336
	mov	ax,[approach_flag]		; 00339
	test	ax,ax			; 0033C
	jng	short game_init_after_approach_sound		; 0033E jng 0x383
	db	0x3D, 0x02, 0x00	; 00340 cmp ax,0x2
	jnz	short game_init_check_approach_flag_3		; 00343 jnz 0x350
	mov	ax,0x8			; 00345
	push	ax			; 00348
	call	play_sound		; 00349
	db	0x8B, 0xE5		; 0034C mov sp,bp
	jmp	short game_init_clear_approach_flag		; 0034E jmp 0x37d
game_init_check_approach_flag_3:
	cmp	word [approach_flag],0x3	; 00350
	jnz	short game_init_check_approach_flag_4		; 00355 jnz 0x362
	mov	ax,0x18			; 00357
	push	ax			; 0035A
	call	play_sound		; 0035B
	db	0x8B, 0xE5		; 0035E mov sp,bp
	jmp	short game_init_clear_approach_flag		; 00360 jmp 0x37d
game_init_check_approach_flag_4:
	cmp	word [approach_flag],0x4	; 00362
	jnz	short game_init_approach_default_sound		; 00367 jnz 0x374
	mov	ax,0x16			; 00369
	push	ax			; 0036C
	call	play_sound		; 0036D
	db	0x8B, 0xE5		; 00370 mov sp,bp
	jmp	short game_init_clear_approach_flag		; 00372 jmp 0x37d
game_init_approach_default_sound:
	mov	ax,0x1			; 00374
	push	ax			; 00377
	call	play_sound		; 00378
	db	0x8B, 0xE5		; 0037B mov sp,bp
game_init_clear_approach_flag:
	mov	word [approach_flag],0x0	; 0037D
game_init_after_approach_sound:
	db	0x33, 0xC0		; 00383 xor ax,ax
	cmp	word [game_restart_flag],0x0	; 00385
	mov	[anim_render_mode],ax		; 0038A
	jnz	short game_init_check_anim_row_state_2		; 0038D jnz 0x395
	call	cutscene_play		; 0038F
	mov	[game_restart_flag],ax		; 00392
; [0x12a] sequence: 1 = reload anim row and go to 2, 2 = play sound 1 next frame and clear.
game_init_check_anim_row_state_2:
	cmp	word [anim_row_reload_state],0x2	; 00395
	jnz	short game_init_check_anim_row_state_1		; 0039A jnz 0x3ab
	mov	word [anim_row_reload_state],0x0	; 0039C
	mov	ax,0x1			; 003A2
	push	ax			; 003A5
	call	play_sound		; 003A6
	db	0x8B, 0xE5		; 003A9 mov sp,bp
game_init_check_anim_row_state_1:
	cmp	word [anim_row_reload_state],0x1	; 003AB
	jnz	short game_init_scene_transition		; 003B0 jnz 0x3c1
	mov	word [anim_row_reload_state],0x2	; 003B2
	mov	word [anim_bg_counter],0x1	; 003B8
	call	load_anim_row		; 003BE
game_init_scene_transition:
	call	draw_health_bars	; 003C1
	jmp	near game_init_frame_loop			; 003C4

; ---- function game_main_loop ----
; Sets up initial game state and runs the intro sequence, then enters the
; gameplay loop. Loads enemy animation scripts, palette, combat level 0,
; and plays the intro (title screen, animated intro, story text).
;
; GAMEPLAY LOOP at game_main_loop_demo_frame_loop:
;   timer_wait -> scene_update -> resolve_hits -> render_figures
;   -> handle approach_flag -> draw_health_bars -> game_scene
; Loops until game_scene returns 1 (scene complete).
; On completion, calls init_combat_state(0) and jumps to set_video_mode.
; When the demo ends, the raw jmp 0x612 at 0053F (code offset 0x412) restarts the title sequence, not set_video_mode.
; A title step or cal00 returning nonzero runs load_scene then exits; cal01 returning nonzero runs game_shutdown then exits.
; The loop at game_main_loop_demo_frame_loop is an attract demo, not player-controlled play: anim_mode=1 makes scene_update call demo_player_ai for the player.
game_main_loop:
	push	bp			; 003C7
	sub	sp,0x4			; 003C8
	jc	short game_main_loop_stack_overflow		; 003CB jc 0x3d3
	cmp	sp,[stack_limit]		; 003CD
	ja	short game_main_loop_stack_ok		; 003D1 ja 0x3d6
game_main_loop_stack_overflow:
	jmp	near stack_overflow_handler			; 003D3
game_main_loop_stack_ok:
	db	0x8B, 0xEC		; 003D6 mov bp,sp
	call	flush_keyboard		; 003D8
	db	0x33, 0xC0		; 003DB xor ax,ax
	mov	bx,0xce3e		; 003DD
	push	bx			; 003E0
	mov	bx,str_allgal - DS_BASE		; 003E1
	push	bx			; 003E4
	mov	[enemy_aggressive],ax		; 003E5
	mov	[unk_game_main_loop_word],ax		; 003E8
	mov	[player_input_repeat_count],ax		; 003EB
	call	load_anim_script	; 003EE
	db	0x8B, 0xE5		; 003F1 mov sp,bp
	call	build_enemy_anim_offsets	; 003F3
	mov	ax,0x5dc		; 003F6
	push	ax			; 003F9
	mov	ax,str_fuji_bcg - DS_BASE	; 003FA
	push	ax			; 003FD
	call	load_resource		; 003FE
	db	0x8B, 0xE5		; 00401 mov sp,bp
	mov	word [current_level],0x0		; 00403
	push	word [current_level]		; 00409
	call	init_combat_level	; 0040D
	db	0x8B, 0xE5		; 00410 mov sp,bp
; title/credits/demo attract sequence; restarted after the demo finishes
game_main_loop_title_sequence_start:
	mov	word [input_advance],0x0	; 00412
	mov	ax,0xd			; 00418
	push	ax			; 0041B
	call	load_sprite_set		; 0041C
	db	0x8B, 0xE5		; 0041F mov sp,bp
	call	title_step_sprite		; 00421
	test	ax,ax			; 00424
	jz	short game_main_loop_show_title_screen		; 00426 jz 0x42e
	call	load_scene		; 00428
	jmp	near game_main_loop_reset_and_return			; 0042B
game_main_loop_show_title_screen:
	db	0x33, 0xC0		; 0042E xor ax,ax
	push	ax			; 00430
	mov	ax,str_title_bcg - DS_BASE	; 00431
	push	ax			; 00434
	call	load_resource		; 00435
	db	0x8B, 0xE5		; 00438 mov sp,bp
	call	show_credit_mechner	; 0043A
	test	ax,ax			; 0043D
	jz	short game_main_loop_show_ibm_credit		; 0043F jz 0x447
	call	load_scene		; 00441
	jmp	near game_main_loop_reset_and_return			; 00444
game_main_loop_show_ibm_credit:
	call	show_credit_ibm		; 00447
	test	ax,ax			; 0044A
	jz	short game_main_loop_show_title_picture		; 0044C jz 0x454
	call	load_scene		; 0044E
	jmp	near game_main_loop_reset_and_return			; 00451
game_main_loop_show_title_picture:
	call	title_step_picture		; 00454
	test	ax,ax			; 00457
	jz	short game_main_loop_show_scroll_text		; 00459 jz 0x461
	call	load_scene		; 0045B
	jmp	near game_main_loop_reset_and_return			; 0045E
game_main_loop_show_scroll_text:
	call	show_scroll_text	; 00461
	test	ax,ax			; 00464
	jz	short game_main_loop_play_cal00_intro		; 00466 jz 0x46e
	call	load_scene		; 00468
	jmp	near game_main_loop_reset_and_return			; 0046B
game_main_loop_play_cal00_intro:
	mov	word [camera_x],0x0		; 0046E
	call	clear_screen		; 00474
	mov	word [anim_render_mode],0x1		; 00477
	mov	word [current_level],0x4		; 0047D
	mov	ax,0xbd04		; 00483
	push	ax			; 00486
	mov	ax,str_cal00 - DS_BASE		; 00487
	push	ax			; 0048A
	call	load_anim_script	; 0048B
	db	0x8B, 0xE5		; 0048E mov sp,bp
	mov	ax,0x6			; 00490
	push	ax			; 00493
	call	load_sprite_set		; 00494
	db	0x8B, 0xE5		; 00497 mov sp,bp
	call	run_anim_script		; 00499
	test	ax,ax			; 0049C
	jz	short game_main_loop_play_cal01_intro		; 0049E jz 0x4a6
	call	load_scene		; 004A0
	jmp	near game_main_loop_reset_and_return			; 004A3
game_main_loop_play_cal01_intro:
	mov	word [current_level],0x0		; 004A6
	mov	ax,0xbd04		; 004AC
	push	ax			; 004AF
	mov	ax,str_cal01 - DS_BASE		; 004B0
	push	ax			; 004B3
	call	load_anim_script	; 004B4
	db	0x8B, 0xE5		; 004B7 mov sp,bp
	mov	ax,0x5dc		; 004B9
	push	ax			; 004BC
	mov	ax,str_fuji_bcg - DS_BASE	; 004BD
	push	ax			; 004C0
	call	load_resource		; 004C1
	db	0x8B, 0xE5		; 004C4 mov sp,bp
	db	0x33, 0xC0		; 004C6 xor ax,ax
	push	ax			; 004C8
	call	init_combat_level	; 004C9
	db	0x8B, 0xE5		; 004CC mov sp,bp
	call	run_anim_script		; 004CE
	test	ax,ax			; 004D1
	jz	short game_main_loop_start_demo		; 004D3 jz 0x4da
	call	game_shutdown		; 004D5
	jmp	short game_main_loop_reset_and_return		; 004D8 jmp 0x542
; Attract demo: anim_mode=1 makes scene_update drive the player with demo_player_ai.
game_main_loop_start_demo:
	mov	word [current_level],0x0		; 004DA
	mov	word [enemy_atk_freq],0xfa	; 004E0
	mov	word [anim_mode],0x1	; 004E6
	call	timer_mark		; 004EC
	mov	word [bp+0x2],0x0	; 004EF
game_main_loop_demo_frame_loop:
	cmp	word [bp+0x2],0x1	; 004F4
	jz	short game_main_loop_demo_finished		; 004F8 jz 0x537
	call	timer_wait_3ticks	; 004FA
	call	scene_update		; 004FD
	call	resolve_hits		; 00500
	call	render_figures		; 00503
	mov	ax,[approach_flag]		; 00506
	test	ax,ax			; 00509
	jng	short game_main_loop_scene_transition		; 0050B jng 0x52c
	db	0x3D, 0x02, 0x00	; 0050D cmp ax,0x2
	jnz	short game_main_loop_approach_default_sound		; 00510 jnz 0x51d
	mov	ax,0x8			; 00512
	push	ax			; 00515
	call	play_sound		; 00516
	db	0x8B, 0xE5		; 00519 mov sp,bp
	jmp	short game_main_loop_clear_approach_flag		; 0051B jmp 0x526
game_main_loop_approach_default_sound:
	mov	ax,0x1			; 0051D
	push	ax			; 00520
	call	play_sound		; 00521
	db	0x8B, 0xE5		; 00524 mov sp,bp
game_main_loop_clear_approach_flag:
	mov	word [approach_flag],0x0	; 00526
game_main_loop_scene_transition:
	call	draw_health_bars	; 0052C
	call	game_scene		; 0052F
	mov	[bp+0x2],ax		; 00532
	jmp	short game_main_loop_demo_frame_loop		; 00535 jmp 0x4f4
game_main_loop_demo_finished:
	db	0x33, 0xC0		; 00537 xor ax,ax
	push	ax			; 00539
	call	init_combat_state	; 0053A
	db	0x8B, 0xE5		; 0053D mov sp,bp
	jmp	near game_main_loop_title_sequence_start			; 0053F
game_main_loop_reset_and_return:
	mov	word [player_anim_id],0x41	; 00542
	call	flush_keyboard		; 00548
	db	0x33, 0xC0		; 0054B xor ax,ax
	mov	[key_pending],al		; 0054D
	mov	[current_level],ax		; 00550
	xor	ah,ah			; 00553
	mov	word [anim_mode],0x0	; 00555
	mov	[player_flag_174],ax		; 0055B
	mov	[combat_counter_a],ax		; 0055E
	mov	[combat_counter_b],ax		; 00561
	add	sp,0x4			; 00564
	pop	bp			; 00567
	ret				; 00568

; ---- function game_scene ----
; Checks if the current scene/level segment is complete.
; Returns AX=1 if: combat_active and player anim is 0x43 (victory),
;   OR player reached right boundary [0xBCD5] == [0x104].
; Returns AX=0 if: player presses a key (poll returns nonzero).
; This is the "should we transition to next scene?" check.
; Correction: a nonzero poll_keyboard result returns AX=1 like the other two conditions; AX=0 means none of them held.
game_scene:
	push	bp			; 00569
	sub	sp,0x2			; 0056A
	jc	short game_scene_stack_overflow		; 0056D jc 0x575
	cmp	sp,[stack_limit]		; 0056F
	ja	short game_scene_stack_ok		; 00573 ja 0x578
game_scene_stack_overflow:
	jmp	near stack_overflow_handler			; 00575
game_scene_stack_ok:
	db	0x8B, 0xEC		; 00578 mov bp,sp
	cmp	word [combat_active],0x1		; 0057A
	jnz	short game_scene_check_right_boundary		; 0057F jnz 0x588
	cmp	word [player_anim_id],0x43	; 00581
	jz	short game_scene_return_complete		; 00586 jz 0x59e
game_scene_check_right_boundary:
	mov	ax,[player_x]		; 00588
	cmp	ax,[player_x_max]		; 0058B
	jz	short game_scene_return_complete		; 0058F jz 0x59e
	mov	ax,0x1			; 00591
	push	ax			; 00594
	call	poll_keyboard		; 00595
	db	0x8B, 0xE5		; 00598 mov sp,bp
	test	ax,ax			; 0059A
	jz	short game_scene_return_continue		; 0059C jz 0x5a6
game_scene_return_complete:
	mov	ax,0x1			; 0059E
	add	sp,0x2			; 005A1
	pop	bp			; 005A4
	ret				; 005A5
game_scene_return_continue:
	db	0x33, 0xC0		; 005A6 xor ax,ax
	add	sp,0x2			; 005A8
	pop	bp			; 005AB
	ret				; 005AC

; ---- function load_scene ----
; Loads a new scene: loads background image, palette, resets combat state,
; clears screen, loads animation script from 0xBD04, then runs it.
load_scene:
	push	bp			; 005AD
	db	0x8B, 0xEC		; 005AE mov bp,sp
	call	load_background		; 005B0
	mov	ax,0x5dc		; 005B3
	push	ax			; 005B6
	mov	ax,str_fuji_bcg - DS_BASE	; 005B7
	push	ax			; 005BA
	call	load_resource		; 005BB
	db	0x8B, 0xE5		; 005BE mov sp,bp
	db	0x33, 0xC0		; 005C0 xor ax,ax
	push	ax			; 005C2
	call	init_combat_level	; 005C3
	db	0x8B, 0xE5		; 005C6 mov sp,bp
	call	clear_screen		; 005C8
	db	0x33, 0xC0		; 005CB xor ax,ax
	mov	bx,0xbd04		; 005CD
	push	bx			; 005D0
	mov	bx,str_cal01 - DS_BASE		; 005D1
	push	bx			; 005D4
	mov	[input_advance],ax		; 005D5
	mov	[current_level],ax		; 005D8
	call	load_anim_script	; 005DB
	db	0x8B, 0xE5		; 005DE mov sp,bp
	call	run_anim_script		; 005E0
	pop	bp			; 005E3
	ret				; 005E4
