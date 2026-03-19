; Level setup, cutscenes, scene transitions
;
; This is the largest game logic module.  It manages combat encounters,
; level transitions, cutscene state machines, and door/gate wipe effects.
;
; Key functions:
;   level_setup        - Per-frame combat encounter management
;   anim_set_bg        - Advance to next background/scene area
;   anim_set_figure    - Trigger figure change (enemy entering/leaving)
;   scene_transition   - Door-opening wipe effect with gate animation
;   clear_gate_column      - Clear a 7-row column in transition buffer
;   blit_column_data   - Copy 7 words with CGA scanline stride
;   blit_transition_col_left/right - Compute screen position and blit
;   cutscene_play      - Main cutscene/level-progression state machine


; ---- function level_setup ----
; Main combat encounter management, called each frame during gameplay.
; Handles hit detection, damage exchange, enemy spawn/despawn,
; health regeneration timers, and combat state transitions.
;
; Flow:
; 1. If combat_active > 0: return 0 immediately (combat handler owns this)
; 2. Compute distance = enemy_x - player_x
; 3. If player facing right: handle active enemy encounter logic
;    - Check animation states and Y offsets to trigger anim_set_figure
;    - Handle combat_phase > 0: manage gate opening and scrolling
; 4. If no active enemy: call check_hit_zone, manage health regen timers
; 5. If enemy facing player: handle enemy-side hit detection
level_setup:
	push	bp			; 02BDD
	sub	sp,0x8			; 02BDE
	jc	short loc_02BE9		; 02BE1 jc 0x2be9
	cmp	sp,[0x17]		; 02BE3  stack overflow check
	ja	short loc_02BEC		; 02BE7 ja 0x2bec
loc_02BE9:
	jmp	0x420			; 02BE9  stack overflow handler
loc_02BEC:
	db	0x8B, 0xEC		; 02BEC mov bp,sp
	cmp	word [0xf8],0x0		; 02BEE  combat_active?
	jng	short loc_02BFC		; 02BF3 jng 0x2bfc
	db	0x33, 0xC0		; 02BF5 xor ax,ax  return 0
	add	sp,0x8			; 02BF7
	pop	bp			; 02BFA
	ret				; 02BFB

loc_02BFC:
; Compute distance = enemy_x - player_x
	mov	ax,[0x10e]		; 02BFC  ax = enemy_x
	sub	ax,[0xbcd5]		; 02BFF  ax -= player_x
	cmp	word [0xec],0x1		; 02C03  player_facing right?
	mov	[bp+0x4],ax		; 02C08  [bp+4] = distance
	jz	short loc_02C10		; 02C0B jz 0x2c10  yes, handle player-facing-right
	jmp	0x2fb0			; 02C0D  jump to enemy-facing-player section

; --- Player facing right: active enemy encounter ---
loc_02C10:
	cmp	word [0xd5aa],0x1	; 02C10  enemy_active?
	jnz	short loc_02C85		; 02C15 jnz 0x2c85  no active enemy

; Check if enemy is at specific animation states to trigger figure change
	cmp	word [0x110],0x1f	; 02C17  enemy_anim_id == 0x1F?
	jz	short loc_02C21		; 02C1C jz 0x2c21
	jmp	0x2fb0			; 02C1E

loc_02C21:
; Distance check: must be in range [0x14..0x1B]
	db	0x3D, 0x13, 0x00	; 02C21 cmp ax,0x13
	jg	short loc_02C29		; 02C24 jg 0x2c29
	jmp	0x2fb0			; 02C26
loc_02C29:
	db	0x3D, 0x1C, 0x00	; 02C29 cmp ax,0x1c
	jl	short loc_02C31		; 02C2C jl 0x2c31
	jmp	0x2fb0			; 02C2E

loc_02C31:
; Check player animation state: standing (4) or crouching (7)
	mov	ax,[0x10c]		; 02C31  player_anim_id
	db	0x3D, 0x04, 0x00	; 02C34 cmp ax,0x4
	jz	short loc_02C3E		; 02C37 jz 0x2c3e
	db	0x3D, 0x07, 0x00	; 02C39 cmp ax,0x7
	jnz	short loc_02C4B		; 02C3C jnz 0x2c4b
loc_02C3E:
	cmp	word [0xd5ac],0x18	; 02C3E  enemy_y_off == 0x18?
	jnz	short loc_02C4B		; 02C43 jnz 0x2c4b
	call	anim_set_figure		; 02C45  trigger figure change
	jmp	0x2fb0			; 02C48
loc_02C4B:
; Check player anim: walking (3) or retreating (6)
	mov	ax,[0x10c]		; 02C4B
	db	0x3D, 0x03, 0x00	; 02C4E cmp ax,0x3
	jz	short loc_02C58		; 02C51 jz 0x2c58
	db	0x3D, 0x06, 0x00	; 02C53 cmp ax,0x6
	jnz	short loc_02C65		; 02C56 jnz 0x2c65
loc_02C58:
	cmp	word [0xd5ac],0xc	; 02C58  enemy_y_off == 0x0C?
	jnz	short loc_02C65		; 02C5D jnz 0x2c65
	call	anim_set_figure		; 02C5F
	jmp	0x2fb0			; 02C62
loc_02C65:
; Check player anim: attacking (2) or kicking (5)
	mov	ax,[0x10c]		; 02C65
	db	0x3D, 0x02, 0x00	; 02C68 cmp ax,0x2
	jz	short loc_02C75		; 02C6B jz 0x2c75
	db	0x3D, 0x05, 0x00	; 02C6D cmp ax,0x5
	jz	short loc_02C75		; 02C70 jz 0x2c75
	jmp	0x2fb0			; 02C72
loc_02C75:
	cmp	word [0xd5ac],0x0	; 02C75  enemy_y_off == 0?
	jz	short loc_02C7F		; 02C7A jz 0x2c7f
	jmp	0x2fb0			; 02C7C
loc_02C7F:
	call	anim_set_figure		; 02C7F
	jmp	0x2fb0			; 02C82

; --- No active enemy: handle combat_phase and approach ---
loc_02C85:
	cmp	word [0xfa],0x0		; 02C85  combat_phase > 0?
	jng	short loc_02CFB		; 02C8A jng 0x2cfb  no, handle hit detection
	cmp	word [0x12e],0x0	; 02C8C  scene_transition_pending?
	jz	short loc_02C96		; 02C91 jz 0x2c96
	jmp	0x2fb0			; 02C93

loc_02C96:
; Gate opening / approach: player must be past X=0xEC and level > 2
	cmp	word [0xbcd5],0xec	; 02C96  player_x > 0xEC?
	jg	short loc_02CA1		; 02C9C jg 0x2ca1
	jmp	0x2fb0			; 02C9E
loc_02CA1:
	cmp	word [0xea],0x2		; 02CA1  current_level > 2?
	jg	short loc_02CAB		; 02CA6 jg 0x2cab
	jmp	0x2fb0			; 02CA8

loc_02CAB:
; Check if player is in approach animation (< 5)
	cmp	word [0x10c],0x5	; 02CAB  player_anim_id < 5?
	jnl	short loc_02CBB		; 02CB0 jnl 0x2cbb
	mov	word [0x154],0x1	; 02CB2  approach_flag = 1 (approaching)
	jmp	0x2fb0			; 02CB8

loc_02CBB:
; Advance background and update position
	call	anim_set_bg		; 02CBB
	mov	ax,[0x10c]		; 02CBE  player_anim_id
	dec	ax			; 02CC1
	dec	ax			; 02CC2  anim_id - 2
	push	ax			; 02CC3
	db	0x33, 0xC0		; 02CC4 xor ax,ax
	push	ax			; 02CC6  actor=0 (player)
	call	add_figure_to_scene		; 02CC7
	db	0x8B, 0xE5		; 02CCA mov sp,bp

; If scene_index == 5: scroll right and set up encounter
	cmp	word [0x130],0x5	; 02CCC  scene_index == 5?
	jz	short loc_02CD6		; 02CD1 jz 0x2cd6
	jmp	0x2fb0			; 02CD3
loc_02CD6:
	call	effect_scroll_right	; 02CD6
	mov	word [0x114],0x5	; 02CD9  player_hits_left = 5
	mov	ax,[0x122]		; 02CDF  hit_regen_init_e
	mov	bx,[0x104]		; 02CE2  player_x_max
	add	bx,0x10			; 02CE6  enemy spawns 16 pixels past max
	mov	cx,[0xc3ec]		; 02CE9  animation lookup
	mov	[0x120],ax		; 02CED  hit_regen_rate_e = initial rate
	mov	[0xc3d2],cx		; 02CF0  player_frame_ptr
	mov	[0x10e],bx		; 02CF4  enemy_x = player_x_max + 16
	jmp	0x2fb0			; 02CF8

; --- Apply gravity / hit detection for player ---
loc_02CFB:
	mov	ax,[0x10c]		; 02CFB  player_anim_id
	dec	ax			; 02CFE
	dec	ax			; 02CFF  anim_id - 2
	push	word [0xd5b0]		; 02D00  enemy_dir_flag
	push	word [bp+0x4]		; 02D04  distance
	push	ax			; 02D07  adjusted anim_id
	call	check_hit_zone		; 02D08
	db	0x8B, 0xE5		; 02D0B mov sp,bp
	db	0x3D, 0x04, 0x00	; 02D0D cmp ax,0x4  hit result == 4?
	mov	[bp+0x6],ax		; 02D10  save result
	jnz	short loc_02D22		; 02D13 jnz 0x2d22
	cmp	word [0x130],0x6	; 02D15  scene_index != 6?
	jz	short loc_02D22		; 02D1A jz 0x2d22
	mov	ax,[0xcdfa]		; 02D1C  update enemy frame pointer
	mov	[0xcde8],ax		; 02D1F
loc_02D22:
	mov	ax,[bp+0x6]		; 02D22  gravity result
	db	0x3D, 0x02, 0x00	; 02D25 cmp ax,0x2  player hit?
	jz	short loc_02D32		; 02D28 jz 0x2d32
	db	0x3D, 0x03, 0x00	; 02D2A cmp ax,0x3  player hit (alternate)?
	jz	short loc_02D32		; 02D2D jz 0x2d32
	jmp	0x2fb0			; 02D2F

; --- Player was hit: decrement hits, manage approach state ---
loc_02D32:
	mov	ax,0x1			; 02D32
	mov	bx,[0x114]		; 02D35  player_hits_left
	dec	bx			; 02D39
	test	bx,bx			; 02D3A
	mov	[0x154],ax		; 02D3C  approach_flag = 1
	mov	[0x114],bx		; 02D3F  --player_hits_left
	jnz	short loc_02D79		; 02D43 jnz 0x2d79  still has hits

; Player hits exhausted: transition to retreat
	mov	word [0x154],0x2	; 02D45  approach_flag = 2 (retreat)
	mov	word [0x11e],0x0	; 02D4B  encounter_counter = 0
	cmp	word [0xf2],0x1		; 02D51  player_faces_right?
	mov	[0x174],ax		; 02D56  player_flag_174 = 1
	mov	[0xfa],ax		; 02D59  combat_phase = 1
	jnz	short loc_02D61		; 02D5C jnz 0x2d61
	mov	[0x170],ax		; 02D5E  player_flag_170 = 1 (if facing right)
loc_02D61:
; Set up health regen for enemy if recovering
	cmp	word [0x124],0x0	; 02D61  enemy_health_regen > 0?
	jng	short loc_02D71		; 02D66 jng 0x2d71
	mov	ax,0x2			; 02D68
	mov	[0x126],ax		; 02D6B  hit_regen_timer_e = 2
	mov	[0x120],ax		; 02D6E  hit_regen_rate_e = 2
loc_02D71:
	mov	ax,[0xce22]		; 02D71  animation frame for retreat
	mov	[0xcde8],ax		; 02D74  enemy_frame_ptr = retreat frame
	jmp	short loc_02DA2		; 02D77 jmp 0x2da2

loc_02D79:
; Player still has hits: check if enemy is in recoil animation
	mov	ax,[0x110]		; 02D79  enemy_anim_id
	db	0x3D, 0x0B, 0x00	; 02D7C cmp ax,0xb
	jng	short loc_02D93		; 02D7F jng 0x2d93
	db	0x3D, 0x12, 0x00	; 02D81 cmp ax,0x12
	jnl	short loc_02D93		; 02D84 jnl 0x2d93
	cmp	word [0x130],0x6	; 02D86  scene_index != 6?
	jz	short loc_02D93		; 02D8B jz 0x2d93
	mov	ax,[0xcdfa]		; 02D8D  update enemy frame
	mov	[0xcde8],ax		; 02D90

loc_02D93:
; Advance player health regen timer
	add	word [0x128],0x3	; 02D93  hit_regen_timer_p += 3
	inc	word [0x11e]		; 02D98  ++encounter_counter
	mov	word [0xfe],0x1		; 02D9C  enemy_was_hit = 1

loc_02DA2:
; Update player position after hit
	mov	ax,[0x10c]		; 02DA2  player_anim_id
	dec	ax			; 02DA5
	dec	ax			; 02DA6
	push	ax			; 02DA7
	db	0x33, 0xC0		; 02DA8 xor ax,ax
	push	ax			; 02DAA  actor=0 (player)
	call	add_figure_to_scene		; 02DAB
	db	0x8B, 0xE5		; 02DAE mov sp,bp

; --- Player health regeneration ---
	mov	ax,[0x11e]		; 02DB0  encounter_counter
	test	ax,ax			; 02DB3
	jng	short loc_02DE1		; 02DB5 jng 0x2de1  no hits to regenerate
	mov	bx,[0x114]		; 02DB7  player_hits_left
	mov	cx,[0x116]		; 02DBB  enemy_health
	db	0x03, 0xCB		; 02DBF add cx,bx  total health remaining
	cmp	cx,0x1a			; 02DC1  max total health cap?
	jnl	short loc_02DE1		; 02DC4 jnl 0x2de1  at cap, no regen
	mov	cx,[0x128]		; 02DC6  hit_regen_timer_p
	dec	cx			; 02DCA
	test	cx,cx			; 02DCB
	mov	[0x128],cx		; 02DCD  --timer
	jnz	short loc_02DE1		; 02DD1 jnz 0x2de1  timer not expired
; Regenerate one hit point for player
	inc	word [0x114]		; 02DD3  ++player_hits_left
	dec	word [0x11e]		; 02DD7  --encounter_counter
	mov	ax,[0x11c]		; 02DDB  hit_regen_rate_p
	mov	[0x128],ax		; 02DDE  reset timer to rate
loc_02DE1:

; --- Enemy facing player: hit detection ---
	cmp	word [0x112],0x1	; 02DE1  enemy_facing == 1?
	jz	short loc_02DEB		; 02DE6 jz 0x2deb
	jmp	0x30df			; 02DE8  skip to return section

loc_02DEB:
; Special case: scene_index == 7 (final encounter)
	cmp	word [0x130],0x7	; 02DEB
	jnz	short loc_02DFF		; 02DF0 jnz 0x2dff
	mov	word [0x116],0x1	; 02DF2  enemy_health = 1
	mov	word [bp+0x6],0x3	; 02DF8  force hit result
	jmp	short loc_02E39		; 02DFD jmp 0x2e39

loc_02DFF:
; Check enemy animation for hit conditions
	mov	ax,[0x110]		; 02DFF  enemy_anim_id
	db	0x3D, 0x21, 0x00	; 02E02 cmp ax,0x21  special anim?
	jz	short loc_02E39		; 02E05 jz 0x2e39
	db	0x3D, 0x07, 0x00	; 02E07 cmp ax,0x7  retreating?
	jnz	short loc_02E10		; 02E0A jnz 0x2e10
	sub	word [bp+0x4],0x4	; 02E0C  adjust distance for retreat
loc_02E10:
; Apply gravity for enemy
	mov	ax,[0x110]		; 02E10  enemy_anim_id
	dec	ax			; 02E13
	dec	ax			; 02E14
	push	word [0xd5ae]		; 02E15  player_dir_flag
	push	word [bp+0x4]		; 02E19  distance
	push	ax			; 02E1C  adjusted anim_id
	call	check_hit_zone		; 02E1D
	db	0x8B, 0xE5		; 02E20 mov sp,bp
	db	0x3D, 0x04, 0x00	; 02E22 cmp ax,0x4  hit result == 4?
	mov	[bp+0x6],ax		; 02E25
	jnz	short loc_02E39		; 02E28 jnz 0x2e39
; Update animation when player is past boundary
	mov	ax,[0xbcd5]		; 02E2A  player_x
	cmp	ax,[0x102]		; 02E2D  player_x_min?
	jng	short loc_02E39		; 02E31 jng 0x2e39
	mov	ax,[0xc3e2]		; 02E33
	mov	[0xc3d2],ax		; 02E36  update player_frame_ptr

loc_02E39:
; Check if enemy died or was hit
	cmp	word [0x110],0x21	; 02E39  enemy_anim_id == 0x21 (death)?
	jz	short loc_02E56		; 02E3E jz 0x2e56
	cmp	word [bp+0x6],0x2	; 02E40  hit result == 2?
	jz	short loc_02E56		; 02E44 jz 0x2e56
	cmp	word [bp+0x6],0x3	; 02E46  hit result == 3?
	jz	short loc_02E56		; 02E4A jz 0x2e56
	cmp	word [0x10c],0x3f	; 02E4C  player_anim_id > 0x3F (dead)?
	jg	short loc_02E56		; 02E51 jg 0x2e56
	jmp	0x30df			; 02E53

loc_02E56:
; Set approach flag if not already set
	cmp	word [0x154],0x0	; 02E56  approach_flag == 0?
	jnz	short loc_02E63		; 02E5B jnz 0x2e63
	mov	word [0x154],0x1	; 02E5D  approach_flag = 1

loc_02E63:
; Decrement enemy health
	mov	ax,[0x116]		; 02E63  enemy_health
	dec	ax			; 02E66
	test	ax,ax			; 02E67
	mov	[0x116],ax		; 02E69
	jz	short loc_02E75		; 02E6C jz 0x2e75  enemy health reached 0
	cmp	word [0x10c],0x3f	; 02E6E  player alive?
	jng	short loc_02E90		; 02E73 jng 0x2e90

loc_02E75:
; Enemy defeated or player dead
	cmp	word [0x10c],0x44	; 02E75  already in death anim?
	jz	short loc_02E90		; 02E7A jz 0x2e90
	mov	word [0xf8],0x1		; 02E7C  combat_active = 1 (combat over)
	mov	ax,[0xc40c]		; 02E82  death animation frame
	mov	word [0x10c],0x44	; 02E85  player_anim_id = death
	mov	[0xc3d2],ax		; 02E8B  player_frame_ptr = death frame
	jmp	short loc_02EB9		; 02E8E jmp 0x2eb9

loc_02E90:
; Enemy still alive: check for recoil animations
	mov	ax,[0x10c]		; 02E90  player_anim_id
	db	0x3D, 0x0E, 0x00	; 02E93 cmp ax,0xe  mid-kick?
	jng	short loc_02E9D		; 02E96 jng 0x2e9d
	db	0x3D, 0x12, 0x00	; 02E98 cmp ax,0x12
	jl	short loc_02EA4		; 02E9B jl 0x2ea4
loc_02E9D:
	cmp	word [0x110],0x21	; 02E9D  enemy death anim?
	jnz	short loc_02EAA		; 02EA2 jnz 0x2eaa
loc_02EA4:
	mov	ax,[0xc3e2]		; 02EA4
	mov	[0xc3d2],ax		; 02EA7  update player frame

loc_02EAA:
; Advance enemy health regen timer
	add	word [0x126],0x3	; 02EAA  hit_regen_timer_e += 3
	inc	word [0x124]		; 02EAF  ++enemy_health_regen
	mov	word [0xfc],0x1		; 02EB3  player_was_hit = 1

loc_02EB9:
; Update enemy position after combat resolution
	cmp	word [0x130],0x7	; 02EB9  scene_index == 7 (final)?
	jnz	short loc_02ECF		; 02EBE jnz 0x2ecf
	mov	ax,0x9			; 02EC0  special anim for final encounter
	push	ax			; 02EC3
	mov	ax,0x1			; 02EC4  actor=1 (enemy)
	push	ax			; 02EC7
	call	add_figure_to_scene		; 02EC8
	db	0x8B, 0xE5		; 02ECB mov sp,bp
	jmp	short loc_02EDF		; 02ECD jmp 0x2edf
loc_02ECF:
	mov	ax,[0x110]		; 02ECF  enemy_anim_id
	db	0x05, 0x04, 0x00	; 02ED2 add ax,0x4  offset for recoil
	push	ax			; 02ED5
	mov	ax,0x1			; 02ED6  actor=1 (enemy)
	push	ax			; 02ED9
	call	add_figure_to_scene		; 02EDA
	db	0x8B, 0xE5		; 02EDD mov sp,bp

loc_02EDF:
; If combat just ended, return 0
	cmp	word [0xf8],0x0		; 02EDF  combat_active?
	jng	short loc_02EED		; 02EE4 jng 0x2eed
	db	0x33, 0xC0		; 02EE6 xor ax,ax
	add	sp,0x8			; 02EE8
	pop	bp			; 02EEB
	ret				; 02EEC

loc_02EED:
; --- Enemy health regeneration ---
	mov	ax,[0x124]		; 02EED  enemy_health_regen
	test	ax,ax			; 02EF0
	jng	short loc_02F28		; 02EF2 jng 0x2f28  nothing to regen
	mov	bx,[0x116]		; 02EF4  enemy_health
	mov	cx,[0x114]		; 02EF8  player_hits_left
	db	0x03, 0xCB		; 02EFC add cx,bx  total health
	cmp	cx,0x1a			; 02EFE  health cap
	jnl	short loc_02F28		; 02F01 jnl 0x2f28  at cap
	mov	cx,[0x126]		; 02F03  hit_regen_timer_e
	dec	cx			; 02F07
	test	cx,cx			; 02F08
	mov	[0x126],cx		; 02F0A  --timer
	jnz	short loc_02F28		; 02F0E jnz 0x2f28  timer not expired
; Regenerate one hit point for enemy
	inc	word [0x116]		; 02F10  ++enemy_health
	dec	ax			; 02F14  --enemy_health_regen
	test	ax,ax			; 02F15
	mov	[0x124],ax		; 02F17
	jnz	short loc_02F22		; 02F1A jnz 0x2f22
	mov	ax,[0x122]		; 02F1C  hit_regen_init_e
	mov	[0x120],ax		; 02F1F  reset rate to initial
loc_02F22:
	mov	ax,[0x120]		; 02F22  hit_regen_rate_e
	mov	[0x126],ax		; 02F25  reset timer

loc_02F28:
	add	sp,0x8			; 02F28
	pop	bp			; 02F2B
	ret				; 02F2C

; ---- function anim_set_bg ----
; Advance to the next background/scene area.
; Increments background scene counter, loads new animation divisors
; from lookup tables, sets scene_transition_pending=1, and marks
; the current scene slot as active.
anim_set_bg:
	push	bp			; 02F2D
	sub	sp,0x4			; 02F2E
	jc	short loc_02F39		; 02F31 jc 0x2f39
	cmp	sp,[0x17]		; 02F33  stack overflow check
	ja	short loc_02F3C		; 02F37 ja 0x2f3c
loc_02F39:
	jmp	0x420			; 02F39
loc_02F3C:
	db	0x8B, 0xEC		; 02F3C mov bp,sp
	add	word [0x104],0x14	; 02F3E  player_x_max += 20
	mov	ax,[0x130]		; 02F43  scene_index
	shl	ax,1			; 02F46  * 2 for word index
	db	0x8B, 0xF0		; 02F48 mov si,ax
	mov	ax,0x1			; 02F4A
	mov	[si+0x142],ax		; 02F4D  scene_slot_flags[scene_index] = 1
	mov	bx,[0xc3a6]		; 02F51  anim_bg_counter
	inc	bx			; 02F55
	mov	[0xc3a6],bx		; 02F56  ++anim_bg_counter
	shl	bx,1			; 02F5A  * 2 for word index
	mov	cx,[bx-0x3c4a]		; 02F5C  lookup table A (animation divisor)
	mov	bx,[0xc3a6]		; 02F60  anim_bg_counter (reload)
	shl	bx,1			; 02F64
	mov	dx,[bx-0x3c58]		; 02F66  lookup table B
	mov	[0x12e],ax		; 02F6A  scene_transition_pending = 1
	mov	ax,[bx-0x3c3c]		; 02F6D  lookup table C
	mov	word [0x154],0x1	; 02F71  approach_flag = 1
	mov	word [0xee],0x2		; 02F77  anim_render_mode = transition
	mov	bx,0xffff		; 02F7D
	mov	[0xc3a4],ax		; 02F80  store animation param C
	mov	[0xc3a2],cx		; 02F83  player_anim_div_b = table A value
	mov	[0xc3a0],dx		; 02F87  player_anim_div_a = table B value
	mov	[0xd652],bx		; 02F8B  wipe_prev_left = 0xFFFF (force redraw)
	mov	[0xbb2a],bx		; 02F8F  anim_state = no animation
	add	sp,0x4			; 02F93
	pop	bp			; 02F96
	ret				; 02F97

; ---- function anim_set_figure ----
; Trigger a figure change (enemy entering/leaving screen).
; On level 3 (final boss): handles countdown logic, health caps,
; and special animation transitions.
; On other levels: just sets enemy_was_hit flag and updates position.
anim_set_figure:
	push	bp			; 02F98
	sub	sp,0x2			; 02F99
	jc	short loc_02FA4		; 02F9C jc 0x2fa4
	cmp	sp,[0x17]		; 02F9E  stack overflow check
	ja	short loc_02FA7		; 02FA2 ja 0x2fa7
loc_02FA4:
	jmp	0x420			; 02FA4
loc_02FA7:
	db	0x8B, 0xEC		; 02FA7 mov bp,sp
	mov	ax,0x3			; 02FA9
	cmp	word [0xea],0x3		; 02FAC  current_level == 3 (final boss)?
	mov	[0x154],ax		; 02FB1  approach_flag = 3 (trigger)
	jnz	short loc_03003		; 02FB4 jnz 0x3003  not level 3

; --- Level 3 specific: countdown hits and cap health ---
	mov	ax,[0x114]		; 02FB6  player_hits_left
	dec	ax			; 02FB9
	test	ax,ax			; 02FBA
	mov	[0x114],ax		; 02FBC
	jnz	short loc_02FFB		; 02FBF jnz 0x2ffb  still has hits

; All hits used: transition to done state
	mov	word [0x154],0x4	; 02FC1  approach_flag = 4 (done)
	mov	ax,[0xce2e]		; 02FC7  animation frame for done state
	cmp	word [0xd5ac],0x0	; 02FCA  enemy_y_off == 0?
	mov	[0xcde8],ax		; 02FCF  enemy_frame_ptr
	jnz	short loc_02FDA		; 02FD2 jnz 0x2fda
	mov	word [0xd5ac],0xc	; 02FD4  set enemy_y_off = 12

loc_02FDA:
; Cap enemy health at 10
	cmp	word [0x116],0xa	; 02FDA  enemy_health > 10?
	jng	short loc_02FEF		; 02FDF jng 0x2fef
	mov	word [0x116],0xa	; 02FE1  cap at 10
	mov	word [0x124],0x0	; 02FE7  enemy_health_regen = 0
	jmp	short loc_03009		; 02FED jmp 0x3009
loc_02FEF:
; Health below cap: compute regen needed
	mov	ax,0xa			; 02FEF
	sub	ax,[0x116]		; 02FF2  10 - enemy_health
	mov	[0x124],ax		; 02FF6  enemy_health_regen = deficit
	jmp	short loc_03009		; 02FF9 jmp 0x3009

loc_02FFB:
; Level 3 but still has hits: just set enemy_was_hit
	mov	word [0xfe],0x1		; 02FFB  enemy_was_hit = 1
	jmp	short loc_03009		; 03001 jmp 0x3009

loc_03003:
; Non-level-3: set enemy_was_hit
	mov	word [0xfe],0x1		; 03003  enemy_was_hit = 1

loc_03009:
; Update player position
	mov	ax,[0x10c]		; 03009  player_anim_id
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

; ---- function scene_transition ----
; Manages the door-opening wipe effect during scene transitions.
; Two independent wipe columns (left/right) reveal the next scene.
; Compares current column counts with previous values to detect changes.
; Calls blit_transition_col_left/right for each active column.
; Also handles gate animation using clear_gate_column with cooldown timers.
scene_transition:
	cmp	word [0xf8],0x0		; 0301C  combat_active?
	jz	short loc_03029		; 03021 jz 0x3029
	mov	word [0x116],0x0	; 03023  clear enemy_health during combat end

loc_03029:
	push	word [0x116]		; 03029  save enemy_health (left wipe)
	push	word [0x114]		; 0302D  save player_hits_left (right wipe)

; Override wipe counts based on state flags
	cmp	word [0x170],0x0	; 03031  player_flag_170?
	jz	short loc_0303E		; 03036 jz 0x303e
	mov	word [0x116],0x0	; 03038  block left wipe
loc_0303E:
	cmp	word [0x118],0x0	; 0303E  enemy_frozen?
	jz	short loc_0304E		; 03043 jz 0x304e
	mov	word [0x114],0x0	; 03045  block right wipe
	jmp	short loc_030CA		; 0304B jmp 0x30ca  full redraw
	nop				; 0304D

loc_0304E:
	cmp	word [0x11a],0x0	; 0304E  scene_locked?
	jz	short loc_0305E		; 03053 jz 0x305e
	mov	word [0x116],0x0	; 03055  block left wipe
	jmp	short loc_030CA		; 0305B jmp 0x30ca
	nop				; 0305D

; --- Delta detection for left wipe column ---
loc_0305E:
	mov	ax,[0x116]		; 0305E  current left wipe count
	sub	ax,[0xd652]		; 03061  delta = current - previous
	db	0x3D, 0x01, 0x00	; 03065 cmp ax,0x1  grew by exactly 1?
	jz	short loc_0308F		; 03068 jz 0x308f  blit one new column
	jg	short loc_030CA		; 0306A jg 0x30ca  grew by more: full redraw
	db	0x3D, 0xFF, 0xFF	; 0306C cmp ax,0xffff  shrunk by 1?
	jmp	short loc_030CA		; 0306F jmp 0x30ca
	nop				; 03071
	jl	short loc_030CA		; 03072 jl 0x30ca  shrunk more: full redraw
	jnz	short loc_03096		; 03074 jnz 0x3096

; Left wipe shrunk by 1: clear the removed column with gate frame
	mov	bx,[0x116]		; 03076
	inc	bx			; 0307A
	db	0x8B, 0xC3		; 0307B mov ax,bx
	shl	ax,1			; 0307D
	db	0x03, 0xC3		; 0307F add ax,bx  ax = bx * 3
	db	0x2D, 0x02, 0x00	; 03081 sub ax,0x2
	lea	di,[0x3f87]		; 03084  transition buffer base (left)
	db	0x03, 0xF8		; 03088 add di,ax
	call	clear_gate_column	; 0308A  clear 7-row column
	jmp	short loc_03096		; 0308D jmp 0x3096

loc_0308F:
; Left wipe grew by 1: blit one column
	mov	bx,[0x116]		; 0308F
	call	blit_transition_col_left	; 03093

; --- Delta detection for right wipe column ---
loc_03096:
	mov	ax,[0x114]		; 03096  current right wipe count
	sub	ax,[0xd650]		; 03099  delta = current - previous
	db	0x3D, 0x01, 0x00	; 0309D cmp ax,0x1
	jz	short loc_030C1		; 030A0 jz 0x30c1  grew by 1
	jg	short loc_030CA		; 030A2 jg 0x30ca  full redraw
	db	0x3D, 0xFF, 0xFF	; 030A4 cmp ax,0xffff
	jl	short loc_030CA		; 030A7 jl 0x30ca
	jnz	short loc_030F3		; 030A9 jnz 0x30f3

; Right wipe shrunk by 1: clear the removed column
	mov	bx,[0x114]		; 030AB
	inc	bx			; 030AF
	db	0x8B, 0xC3		; 030B0 mov ax,bx
	shl	ax,1			; 030B2
	db	0x03, 0xC3		; 030B4 add ax,bx
	lea	di,[0x3fd7]		; 030B6  transition buffer base (right)
	db	0x2B, 0xF8		; 030BA sub di,ax
	call	clear_gate_column	; 030BC
	jmp	short loc_030F3		; 030BF jmp 0x30f3

loc_030C1:
; Right wipe grew by 1: blit one column
	mov	bx,[0x114]		; 030C1
	call	blit_transition_col_right	; 030C5
	jmp	short loc_030F3		; 030C8 jmp 0x30f3

; --- Full redraw: clear entire transition buffer and redraw all columns ---
loc_030CA:
	lea	di,[0x3cb7]		; 030CA  transition buffer start
	db	0x33, 0xC0		; 030CE xor ax,ax
	mov	cx,0x280		; 030D0  640 words = 1280 bytes
	rep	stosw			; 030D3  zero fill

; Redraw all left wipe columns
	mov	bx,[0x116]		; 030D5
	cmp	bx,0x0			; 030D9
	jz	short loc_030E4		; 030DC jz 0x30e4
loc_030DE:
	call	blit_transition_col_left	; 030DE
	dec	bx			; 030E1
	jg	short loc_030DE		; 030E2 jg 0x30de

loc_030E4:
; Redraw all right wipe columns
	mov	bx,[0x114]		; 030E4
	cmp	bx,0x0			; 030E8
	jz	short loc_030F3		; 030EB jz 0x30f3
loc_030ED:
	call	blit_transition_col_right	; 030ED
	dec	bx			; 030F0
	jg	short loc_030ED		; 030F1 jg 0x30ed

loc_030F3:
; Save current wipe counts as previous values
	mov	ax,[0x116]		; 030F3
	mov	[0xd652],ax		; 030F6  wipe_prev_left = current left
	mov	ax,[0x114]		; 030F9
	mov	[0xd650],ax		; 030FC  wipe_prev_right = current right

; --- Left gate animation ---
	cmp	byte [0xd670],0x0	; 030FF  gate_anim_left cooldown active?
	jz	short loc_0310C		; 03104 jz 0x310c
	dec	byte [0xd670]		; 03106  --cooldown
	jmp	short loc_0312C		; 0310A jmp 0x312c  skip gate draw
loc_0310C:
	cmp	word [0x116],0x2	; 0310C  left wipe <= 2 columns?
	jg	short loc_0312C		; 03111 jg 0x312c  too many columns, skip
	mov	byte [0xd670],0x1	; 03113  set cooldown = 1
	lea	di,[0x3f88]		; 03118  gate frame column 1
	call	clear_gate_column	; 0311C  clear gate column
	lea	di,[0x3f8b]		; 0311F  gate frame column 2
	call	clear_gate_column	; 03123  clear gate column
	mov	word [0xd652],0x0	; 03126  force left wipe redraw next frame

loc_0312C:
; --- Right gate animation ---
	cmp	byte [0xd671],0x0	; 0312C  gate_anim_right cooldown active?
	jz	short loc_03139		; 03131 jz 0x3139
	dec	byte [0xd671]		; 03133  --cooldown
	jmp	short loc_03159		; 03137 jmp 0x3159

loc_03139:
	cmp	word [0x114],0x2	; 03139  right wipe <= 2 columns?
	jg	short loc_03159		; 0313E jg 0x3159
	mov	byte [0xd671],0x1	; 03140  set cooldown = 1
	lea	di,[0x3fd4]		; 03145  gate frame column 1
	call	clear_gate_column	; 03149
	lea	di,[0x3fd1]		; 0314C  gate frame column 2
	call	clear_gate_column	; 03150
	mov	word [0xd650],0x0	; 03153  force right wipe redraw next frame

loc_03159:
; Restore saved wipe counts
	pop	word [0x114]		; 03159  restore player_hits_left
	pop	word [0x116]		; 0315D  restore enemy_health
	ret				; 03161

; ---- function clear_gate_column ----
; Clears a 7-row column in the transition buffer.
; Writes 7 zero words at DI with 0x50-byte stride (CGA scanline pitch).
; Input: DI = buffer position to clear.
clear_gate_column:
	mov	cx,0x7			; 03162  7 rows
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
	lea	di,[0x3f87]		; 03188  left transition buffer base
	db	0x03, 0xF8		; 0318C add di,ax  di = base + offset
	lea	si,[0xd654]		; 0318E  source: left transition data
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
	lea	di,[0x3fd7]		; 0319C  right transition buffer base
	db	0x2B, 0xF8		; 031A0 sub di,ax  di = base - offset (grows left)
	lea	si,[0xd662]		; 031A2  source: right transition data
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
;   ui_pending [0xD674] - 1 if UI element needs to be displayed
;
; The function uses large switch-like blocks for each level:
;   Level 1 ([0xEA]=1): jump table at 0x3715 (5 entries)
;   Level 2 ([0xEA]=2): eagle encounter, gate sequences, approach timers
;   Level 3 ([0xEA]=3): final boss, princess rescue, endgame
cutscene_play:
	push	bp			; 031AA
	sub	sp,0x6			; 031AB
	jc	short loc_031B6		; 031AE jc 0x31b6
	cmp	sp,[0x17]		; 031B0  stack overflow check
	ja	short loc_031B9		; 031B4 ja 0x31b9
loc_031B6:
	jmp	0x420			; 031B6
loc_031B9:
	db	0x8B, 0xEC		; 031B9 mov bp,sp

; --- Cutscene state machine: delay/cooldown ---
	cmp	word [0xd672],0x6	; 031BB  cutscene_state == 6?
	jnz	short loc_031D1		; 031C0 jnz 0x31d1
	mov	ax,0xc			; 031C2  12 vsync frames delay
	push	ax			; 031C5
	call	wait_vsync		; 031C6
	db	0x8B, 0xE5		; 031C9 mov sp,bp
	mov	word [0xd672],0x0	; 031CB  reset cutscene_state

loc_031D1:
; Increment cutscene_state if > 2
	mov	ax,[0xd672]		; 031D1  cutscene_state
	db	0x3D, 0x02, 0x00	; 031D4 cmp ax,0x2
	jng	short loc_031DD		; 031D7 jng 0x31dd
	inc	word [0xd672]		; 031D9  ++cutscene_state

loc_031DD:
; If cutscene_state == 2 and player_anim_id == 1, advance to 3
	cmp	word [0xd672],0x2	; 031DD
	jnz	short loc_031F1		; 031E2 jnz 0x31f1
	cmp	word [0x10c],0x1	; 031E4  player standing idle?
	jnz	short loc_031F1		; 031E9 jnz 0x31f1
	mov	word [0xd672],0x3	; 031EB  advance state

loc_031F1:
; --- UI element display ---
	cmp	word [0xd674],0x0	; 031F1  ui_pending?
	jng	short loc_0322E		; 031F6 jng 0x322e  no pending UI
	cmp	word [0xd5aa],0x0	; 031F8  enemy_active?
	jnz	short loc_03227		; 031FD jnz 0x3227  enemy active, skip UI
	cmp	word [0x10c],0x1c	; 031FF  specific animation?
	jnz	short loc_0320D		; 03204 jnz 0x320d
	db	0x33, 0xC0		; 03206 xor ax,ax  return 0
	add	sp,0x6			; 03208
	pop	bp			; 0320B
	ret				; 0320C

loc_0320D:
; Wait then draw UI element
	mov	ax,0xa			; 0320D  10 vsync frames
	push	ax			; 03210
	call	wait_vsync		; 03211
	db	0x8B, 0xE5		; 03214 mov sp,bp
	call	draw_ui_element		; 03216  display the UI element
	mov	word [0xd674],0x0	; 03219  ui_pending = 0
	mov	ax,0x1			; 0321F  return 1
	add	sp,0x6			; 03222
	pop	bp			; 03225
	ret				; 03226

loc_03227:
; Enemy active during UI request: return 0
	db	0x33, 0xC0		; 03227 xor ax,ax
	add	sp,0x6			; 03229
	pop	bp			; 0322C
	ret				; 0322D

loc_0322E:
; --- Check for death animation completion ---
	cmp	word [0x10c],0x46	; 0322E  player in death anim (0x46)?
	jnz	short loc_0324A		; 03233 jnz 0x324a
	mov	al,[0xdf42]		; 03235  keypress byte
	xor	ah,ah			; 03238
	db	0x3D, 0x20, 0x00	; 0323A cmp ax,0x20  space bar?
	jnz	short loc_0324A		; 0323D jnz 0x324a
	mov	ax,[0xc3f4]		; 0323F  restart animation frame
	mov	byte [0xdf43],0x0	; 03242  clear keypress flag
	mov	[0xc3d2],ax		; 03247  player_frame_ptr = restart frame

; ===========================================================
; LEVEL 2 BLOCK: Eagle encounter, gate sequences
; ===========================================================
loc_0324A:
	cmp	word [0xea],0x2		; 0324A  current_level == 2?
	jz	short loc_03254		; 0324F jz 0x3254
	jmp	0x354f			; 03251  not level 2, skip to level 3

loc_03254:
; --- Eagle distance/trigger check ---
	mov	ax,[0x106]		; 03254  encounter_target
	sub	ax,[0xbcd5]		; 03257  distance to target
	mov	bx,[0xd67c]		; 0325B  eagle_cooldown
	test	bx,bx			; 0325F
	mov	[bp+0x4],ax		; 03261  save distance
	jng	short loc_0326C		; 03264 jng 0x326c
	dec	word [0xd67c]		; 03266  --eagle_cooldown
	jmp	short loc_032A6		; 0326A jmp 0x32a6

loc_0326C:
; Check scroll and distance conditions for eagle trigger
	cmp	word [0x12c],0x0	; 0326C  scroll_counter == 0?
	jnz	short loc_032A6		; 03271 jnz 0x32a6  scrolling, skip
	mov	ax,[bp+0x4]		; 03273
	db	0x3D, 0x5E, 0x00	; 03276 cmp ax,0x5e  distance < 94?
	jnl	short loc_032A6		; 03279 jnl 0x32a6
	db	0x3D, 0x20, 0x00	; 0327B cmp ax,0x20  distance > 32?
	jng	short loc_032A6		; 0327E jng 0x32a6
	db	0x3D, 0x3E, 0x00	; 03280 cmp ax,0x3e  distance < 62?
	jl	short loc_03299		; 03283 jl 0x3299  yes, close enough

; Far range: additional checks (player must be walking and in combat)
	mov	ax,[0x10c]		; 03285  player_anim_id
	db	0x3D, 0x01, 0x00	; 03288 cmp ax,0x1
	jng	short loc_032A6		; 0328B jng 0x32a6
	db	0x3D, 0x08, 0x00	; 0328D cmp ax,0x8
	jnl	short loc_032A6		; 03290 jnl 0x32a6
	cmp	word [0xfa],0x0		; 03292  combat_phase > 0?
	jng	short loc_032A6		; 03297 jng 0x32a6

loc_03299:
	cmp	word [0xf8],0x0		; 03299  combat_active?
	jnz	short loc_032A6		; 0329E jnz 0x32a6
	mov	word [0xd67a],0x1	; 032A0  eagle_trigger = 1!

loc_032A6:
; --- Eagle attack: force combat when close ---
	mov	ax,[bp+0x4]		; 032A6
	db	0x3D, 0x3E, 0x00	; 032A9 cmp ax,0x3e
	jnl	short loc_032CD		; 032AC jnl 0x32cd
	db	0x3D, 0x20, 0x00	; 032AE cmp ax,0x20
	jng	short loc_032CD		; 032B1 jng 0x32cd
	cmp	word [0xd67a],0x1	; 032B3  eagle_trigger active?
	jnz	short loc_032CD		; 032B8 jnz 0x32cd
	cmp	word [0xf8],0x0		; 032BA  not already in combat?
	jnz	short loc_032CD		; 032BF jnz 0x32cd
; Start eagle combat
	mov	word [0xf8],0x1		; 032C1  combat_active = 1
	mov	ax,[0xc40e]		; 032C7  eagle attack animation
	mov	[0xc3d2],ax		; 032CA  player_frame_ptr

loc_032CD:
; --- Eagle scroll sequence ---
	cmp	word [0xd67a],0x1	; 032CD  eagle_trigger?
	jnz	short loc_032FE		; 032D2 jnz 0x32fe
	mov	ax,[0x12c]		; 032D4  scroll_counter
	inc	ax			; 032D7
	db	0x3D, 0x05, 0x00	; 032D8 cmp ax,0x5  5 scroll steps done?
	mov	[0x12c],ax		; 032DB
	jnz	short loc_032EC		; 032DE jnz 0x32ec
; Eagle scroll complete
	mov	word [0xd67a],0x0	; 032E0  eagle_trigger = 0
	mov	word [0xd67c],0x3	; 032E6  eagle_cooldown = 3

loc_032EC:
; Skip first step (step 1 -> jump to 3)
	mov	ax,[0x12c]		; 032EC
	db	0x3D, 0x01, 0x00	; 032EF cmp ax,0x1
	jnz	short loc_032F9		; 032F2 jnz 0x32f9
	add	word [0x12c],0x2	; 032F4  skip step 1 -> 3
loc_032F9:
	call	effect_scroll_left	; 032F9  scroll screen left
	jmp	short loc_0332A		; 032FC jmp 0x332a

loc_032FE:
; --- Reverse scroll (eagle retreating) ---
	cmp	word [0x12c],0x0	; 032FE  scroll_counter > 0?
	jng	short loc_0332A		; 03303 jng 0x332a
	cmp	word [0xd67c],0x0	; 03305  cooldown expired?
	jnz	short loc_0332A		; 0330A jnz 0x332a
	mov	ax,[0xd678]		; 0330C  eagle_scroll_dir
	neg	ax			; 0330F  reverse direction
	mov	[0xd678],ax		; 03311
	jng	short loc_0332A		; 03314 jng 0x332a  only scroll if positive
	mov	ax,[0x12c]		; 03316  scroll_counter
	dec	ax			; 03319
	test	ax,ax			; 0331A
	mov	[0x12c],ax		; 0331C
	jnz	short loc_03327		; 0331F jnz 0x3327
	mov	word [0xd67c],0xa	; 03321  cooldown = 10
loc_03327:
	call	effect_scroll_left	; 03327

loc_0332A:
; --- Adjust encounter target based on scroll state ---
	cmp	word [0x12c],0x1	; 0332A  scrolling active?
	jng	short loc_03349		; 0332F jng 0x3349
	cmp	word [bp+0x4],0x20	; 03331  distance > 32?
	jng	short loc_03349		; 03335 jng 0x3349
	cmp	word [0xf8],0x0		; 03337  not in combat?
	jnz	short loc_03349		; 0333C jnz 0x3349
; Pull encounter target closer during scroll
	mov	ax,[0x106]		; 0333E  encounter_target
	db	0x2D, 0x44, 0x00	; 03341 sub ax,0x44  - 68 pixels
	mov	[0x104],ax		; 03344  player_x_max = adjusted target
	jmp	short loc_0334F		; 03347 jmp 0x334f
loc_03349:
	mov	ax,[0x106]		; 03349  encounter_target
	mov	[0x104],ax		; 0334C  player_x_max = normal target

; --- Level 2: combat ended, approach/wait timer ---
loc_0334F:
	cmp	word [0xf8],0x0		; 0334F  combat_active?
	jng	short loc_033BF		; 03354 jng 0x33bf  not in combat

; Combat just ended: setup approach timer
	cmp	word [0x166],0x0	; 03356  approach_timer == 0?
	jnz	short loc_0336A		; 0335B jnz 0x336a
	mov	word [0x166],0x14	; 0335D  approach_timer = 20
	db	0x33, 0xC0		; 03363 xor ax,ax  return 0
	add	sp,0x6			; 03365
	pop	bp			; 03368
	ret				; 03369

loc_0336A:
; Count down approach timer
	mov	ax,[0x166]		; 0336A  approach_timer
	dec	ax			; 0336D
	test	ax,ax			; 0336E
	mov	[0x166],ax		; 03370
	jnz	short loc_033A4		; 03373 jnz 0x33a4  still counting

; Timer expired: clear enemy health bar, show UI
	cmp	word [0x10c],0x44	; 03375  player in death anim?
	jnz	short loc_03385		; 0337A jnz 0x3385
	mov	ax,0x3			; 0337C  3 vsync frames wait
	push	ax			; 0337F
	call	wait_vsync		; 03380
	db	0x8B, 0xE5		; 03383 mov sp,bp

loc_03385:
; Brief busy-wait loop (0x3E8 = 1000 iterations)
	mov	word [bp+0x4],0x0	; 03385
loc_0338A:
	cmp	word [bp+0x4],0x3e8	; 0338A
	jnl	short loc_03396		; 0338F jnl 0x3396
	inc	word [bp+0x4]		; 03391
	jmp	short loc_0338A		; 03394 jmp 0x338a
loc_03396:
	mov	word [0x116],0x0	; 03396  enemy_health = 0 (clear bar)
	mov	word [0xd674],0x1	; 0339C  ui_pending = 1
	jmp	short loc_033B8		; 033A2 jmp 0x33b8

loc_033A4:
; Special case: skip timer from 11 to 1 if player dying
	cmp	word [0x166],0xb	; 033A4  approach_timer == 11?
	jnz	short loc_033B8		; 033A9 jnz 0x33b8
	cmp	word [0x10c],0x44	; 033AB  death animation?
	jnz	short loc_033B8		; 033B0 jnz 0x33b8
	mov	word [0x166],0x1	; 033B2  fast-forward to 1

loc_033B8:
	db	0x33, 0xC0		; 033B8 xor ax,ax  return 0
	add	sp,0x6			; 033BA
	pop	bp			; 033BD
	ret				; 033BE

; --- Level 2: player reached encounter target ---
loc_033BF:
	mov	ax,[0xbcd5]		; 033BF  player_x
	cmp	ax,[0x104]		; 033C2  at player_x_max?
	jz	short loc_033CB		; 033C6 jz 0x33cb
	jmp	0x392d			; 033C8  not there yet

; --- Level advance check ---
loc_033CB:
	cmp	word [0x152],0x3	; 033CB  level_advance == 3?
	jnz	short loc_03410		; 033D0 jnz 0x3410

; Skip to level 3 (fortress interior)
	mov	word [0x152],0x0	; 033D2  level_advance = 0
	mov	ax,0x2			; 033D8
	mov	[0xea],ax		; 033DB  current_level = 2
	inc	ax			; 033DE
	push	ax			; 033DF  arg: level 3
	mov	[0xea],ax		; 033E0  current_level = 3
	call	init_combat_level	; 033E3  initialize combat for level 3
	db	0x8B, 0xE5		; 033E6 mov sp,bp
; Set up scene 6 with gate open
	mov	ax,0x6			; 033E8
	mov	bx,0x1			; 033EB
	mov	[0x130],ax		; 033EE  scene_index = 6
	shl	ax,1			; 033F1
	db	0x8B, 0xF0		; 033F3 mov si,ax
	mov	[si+0x142],bx		; 033F5  scene_slot_flags[6] = 1
	mov	word [0xbb2a],0xffff	; 033F9  anim_state = none
	mov	word [0xfa],0x2		; 033FF  combat_phase = 2 (retreat)
	mov	[0x12e],bx		; 03405  scene_transition_pending = 1
	db	0x33, 0xC0		; 03409 xor ax,ax  return 0
	add	sp,0x6			; 0340B
	pop	bp			; 0340E
	ret				; 0340F

loc_03410:
; Normal level advance
	mov	ax,[0xea]		; 03410  current_level
	mov	bx,[0x152]		; 03413  level_advance
	db	0x03, 0xD8		; 03417 add bx,ax  new_level = current + advance
	mov	word [0x152],0x0	; 03419  level_advance = 0
	mov	[0xea],bx		; 0341F  current_level = new_level
	jmp	0x391f			; 03423  goto level transition setup

; ===========================================================
; LEVEL 2 SCENE TRANSITIONS: music callbacks and encounters
; ===========================================================

; --- Scene 1: first gate music ---
	mov	ax,0x7			; 03426  animation data index
	push	ax			; 03429
	mov	ax,0xd680		; 0342A  script filename pointer
	push	ax			; 0342D
	call	play_music_sequence	; 0342E  play gate-opening music
	db	0x8B, 0xE5		; 03431 mov sp,bp
	mov	ax,[0xea]		; 03433  advance to next level
	inc	ax			; 03436
	push	ax			; 03437
	mov	[0xea],ax		; 03438
	call	init_combat_level	; 0343B  setup combat for next level
	db	0x8B, 0xE5		; 0343E mov sp,bp
; Load palette and set up frozen enemy
	mov	ax,0x5dc		; 03440  palette offset
	push	ax			; 03443
	mov	ax,0xd687		; 03444  palette filename
	push	ax			; 03447
	call	load_palette		; 03448
	db	0x8B, 0xE5		; 0344B mov sp,bp
	mov	word [0x118],0x20	; 0344D  enemy_frozen = 32 frames
	mov	word [0x110],0x46	; 03453  enemy_anim_id = death/frozen
	mov	ax,[0xce06]		; 03459
	mov	word [0xbb2a],0xffff	; 0345C  anim_state = none
	mov	[0xcde8],ax		; 03462  enemy_frame_ptr
	db	0x33, 0xC0		; 03465 xor ax,ax  return 0
	add	sp,0x6			; 03467
	pop	bp			; 0346A
	ret				; 0346B

; --- Scene 2: second gate music ---
	mov	ax,0x8			; 0346C
	push	ax			; 0346F
	mov	ax,0xd690		; 03470  script filename
	push	ax			; 03473
	call	play_music_sequence	; 03474
	db	0x8B, 0xE5		; 03477 mov sp,bp
	mov	ax,[0xea]		; 03479
	inc	ax			; 0347C
	push	ax			; 0347D
	mov	[0xea],ax		; 0347E
	call	init_combat_level	; 03481
	db	0x8B, 0xE5		; 03484 mov sp,bp
	mov	ax,0x5dc		; 03486
	push	ax			; 03489
	mov	ax,0xd687		; 0348A
	push	ax			; 0348D
	call	load_palette		; 0348E
	db	0x8B, 0xE5		; 03491 mov sp,bp
	mov	word [0x10e],0xc8	; 03493  enemy_x = 200
	mov	word [0xe2],0x1		; 03499  scene_param_e2 = 1 (special encounter)
	mov	word [0x166],0x9	; 0349F  approach_timer = 9
	db	0x33, 0xC0		; 034A5 xor ax,ax
	add	sp,0x6			; 034A7
	pop	bp			; 034AA
	ret				; 034AB

; --- Scene 3: dissolve transition ---
	mov	ax,[0x104]		; 034AC  player_x_max
	cmp	ax,[0x106]		; 034AF  encounter_target?
	jnl	short loc_034BF		; 034B3 jnl 0x34bf
	call	effect_dissolve		; 034B5  dissolve effect
	db	0x33, 0xC0		; 034B8 xor ax,ax
	add	sp,0x6			; 034BA
	pop	bp			; 034BD
	ret				; 034BE

loc_034BF:
; --- Scene 3 continued: music and level 3 transition ---
	mov	ax,0xa			; 034BF  animation data index
	push	ax			; 034C2
	mov	ax,0xd696		; 034C3  script filename
	push	ax			; 034C6
	call	play_music_sequence	; 034C7
	db	0x8B, 0xE5		; 034CA mov sp,bp
	mov	ax,0x1			; 034CC
	mov	word [0xbb2a],0xffff	; 034CF  anim_state = none
	mov	bx,[0xea]		; 034D5  current_level
	inc	bx			; 034D9
	push	bx			; 034DA
	mov	[0x130],ax		; 034DB  scene_index = 1
	mov	[0xea],bx		; 034DE  ++current_level
	call	init_combat_level	; 034E2
	db	0x8B, 0xE5		; 034E5 mov sp,bp
; Initialize level 3 state
	mov	ax,[0xbcd5]		; 034E7  player_x
	mov	word [0x12e],0x1	; 034EA  scene_transition_pending = 1
	db	0x33, 0xDB		; 034F0 xor bx,bx
	mov	[0x102],ax		; 034F2  player_x_min = current player_x
	mov	[0xf6],bx		; 034F5  enemy_aggressive = 0
	mov	[0xd672],bx		; 034F9  cutscene_state = 0
	mov	[0xd67e],bx		; 034FD  princess_rescued = 0
	mov	[0xfa],bx		; 03501  combat_phase = 0
	db	0x8B, 0xC3		; 03505 mov ax,bx  return 0
	add	sp,0x6			; 03507
	pop	bp			; 0350A
	ret				; 0350B

; ===========================================================
; LEVEL 3 BLOCK: Final boss, princess rescue, endgame
; ===========================================================

; Check if scene_transition_pending and enemy not yet spawned
	cmp	word [0x12e],0x1	; 0350C  scene_transition_pending?
	jz	short loc_03516		; 03511 jz 0x3516
	jmp	0x386a			; 03513  not pending, skip ahead

loc_03516:
	cmp	word [0xd5aa],0x0	; 03516  enemy_active?
	jz	short loc_03527		; 0351B jz 0x3527
	cmp	word [0x130],0x5	; 0351D  scene_index >= 5?
	jl	short loc_03527		; 03522 jl 0x3527
	jmp	0x386a			; 03524

loc_03527:
; Advance scene_index
	mov	ax,[0x130]		; 03527  scene_index
	inc	ax			; 0352A
	db	0x3D, 0x07, 0x00	; 0352B cmp ax,0x7  reached scene 7?
	mov	[0x130],ax		; 0352E
	jz	short loc_03536		; 03531 jz 0x3536
	jmp	0x37d7			; 03533  not scene 7 yet

loc_03536:
; --- Scene 7: Final boss entry music ---
	mov	ax,0xc			; 03536  animation data index
	push	ax			; 03539
	mov	ax,0xd69c		; 0353A  script filename
	push	ax			; 0353D
	call	play_music_sequence	; 0353E
	db	0x8B, 0xE5		; 03541 mov sp,bp
	mov	ax,[0xea]		; 03543
	inc	ax			; 03546
	push	ax			; 03547
	mov	[0xea],ax		; 03548
	call	init_combat_level	; 0354B
	db	0x8B, 0xE5		; 0354E mov sp,bp

; Load animation script for final boss intro
	mov	ax,0xce3e		; 03550  destination buffer
	push	ax			; 03553
	mov	ax,0xd6a2		; 03554  script filename
	push	ax			; 03557
	call	load_anim_script	; 03558
	db	0x8B, 0xE5		; 0355B mov sp,bp
	call	build_enemy_anim_offsets		; 0355D

; Set up final battle scene
	mov	word [0x130],0x6	; 03560  scene_index = 6
	push	word [0x130]		; 03566
	call	effect_wipe		; 0356A
	db	0x8B, 0xE5		; 0356D mov sp,bp
	mov	ax,0x114		; 0356F  enemy spawn position
	mov	[0x10e],ax		; 03572  enemy_x
	db	0x2D, 0x1E, 0x00	; 03575 sub ax,0x1e  player starts 30 pixels left
	mov	word [0x110],0x6	; 03578  enemy_anim_id = 6
	mov	bx,0x1			; 0357E
	mov	cx,0x1a			; 03581  26 - enemy_health = initial hits
	sub	cx,[0x116]		; 03584
	cmp	word [0x10c],0x3f	; 03588  player alive?
	mov	[0xbcd5],ax		; 0358D  player_x
	mov	[0x114],cx		; 03590  player_hits_left
	mov	[0xf2],bx		; 03594  player_faces_right = 1
	jnl	short loc_035AC		; 03598 jnl 0x35ac  player dead

; Player alive: start combat
	mov	word [0x10c],0xa	; 0359A  player_anim_id = 10 (fight stance)
	mov	ax,[0xc3ec]		; 035A0  fight stance animation
	mov	[0xc3d2],ax		; 035A3  player_frame_ptr
	mov	[0x112],bx		; 035A6  enemy_facing = 1
	jmp	short loc_035BE		; 035AA jmp 0x35be

loc_035AC:
; Player dead: end combat immediately
	mov	word [0x116],0x0	; 035AC  enemy_health = 0
	mov	word [0xf8],0x1		; 035B2  combat_active = 1
	mov	ax,[0xc40c]		; 035B8  death frame
	mov	[0xc3d2],ax		; 035BB

loc_035BE:
; Calculate initial encounter counter
	mov	ax,0x12			; 035BE  18 - player_hits_left
	sub	ax,[0x114]		; 035C1
	mov	[0x11e],ax		; 035C5  encounter_counter
	jnl	short loc_035D0		; 035C8 jnl 0x35d0
	mov	word [0x11e],0x0	; 035CA  clamp to 0
loc_035D0:
	db	0x33, 0xC0		; 035D0 xor ax,ax  return 0
	add	sp,0x6			; 035D2
	pop	bp			; 035D5
	ret				; 035D6

; --- Level 1 scene: adjust screen bounds for scene 2 ---
	cmp	word [0x130],0x2	; 035D7  scene_index == 2?
	jnz	short loc_035EA		; 035DC jnz 0x35ea
	sub	word [0x104],0x140	; 035DE  player_x_max -= 320
	sub	word [0x10a],0x140	; 035E4  camera_x_max -= 320

loc_035EA:
; Load scene slot flags and transition state
	mov	ax,[0x130]		; 035EA  scene_index
	shl	ax,1			; 035ED
	db	0x8B, 0xF0		; 035EF mov si,ax
	mov	bx,[si+0x142]		; 035F1  scene_slot_flags[scene_index]
	cmp	word [0xfa],0x0		; 035F5  combat_phase?
	mov	[bp+0x0],ax		; 035FA
	mov	[0x12e],bx		; 035FD  scene_transition_pending = flags
	jng	short loc_0363F		; 03601 jng 0x363f

; Combat phase active: set retreat state
	mov	word [0xfa],0x2		; 03603  combat_phase = 2 (retreat)
	cmp	word [si+0x132],0x0	; 03609  damage pending for this scene?
	jng	short loc_03626		; 0360E jng 0x3626
	push	word [0xea]		; 03610  apply damage for current level
	call	spawn_enemy		; 03614
	db	0x8B, 0xE5		; 03617 mov sp,bp
	mov	ax,[0x130]		; 03619
	shl	ax,1			; 0361C
	db	0x8B, 0xF0		; 0361E mov si,ax
	mov	word [si+0x132],0x0	; 03620  clear damage pending

loc_03626:
; Level 3 scene 6: trigger princess rescue
	cmp	word [0x130],0x6	; 03626  scene_index == 6?
	jnz	short loc_03645		; 0362B jnz 0x3645
	cmp	word [0xd67e],0x0	; 0362D  princess_rescued?
	jnz	short loc_03645		; 03632 jnz 0x3645
	mov	ax,0x1			; 03634
	mov	[0xd67e],ax		; 03637  princess_rescued = 1
	mov	[0xd672],ax		; 0363A  cutscene_state = 1
	jmp	short loc_03645		; 0363D jmp 0x3645

loc_0363F:
; No combat phase: adjust enemy X for transition
	sub	word [0x10e],0x114	; 0363F  enemy_x -= 276

loc_03645:
; Set up screen bounds based on transition state
	cmp	word [0x12e],0x0	; 03645  scene_transition_pending?
	jnz	short loc_03654		; 0364A jnz 0x3654
	mov	word [0x104],0xfc	; 0364C  player_x_max = 252 (tighter bounds)
	jmp	short loc_0365A		; 03652 jmp 0x365a
loc_03654:
	mov	word [0x104],0x130	; 03654  player_x_max = 304 (wider bounds)

loc_0365A:
; Apply wipe effect for this scene
	push	word [0x130]		; 0365A
	call	effect_wipe		; 0365E
	db	0x8B, 0xE5		; 03661 mov sp,bp
	db	0x33, 0xC0		; 03663 xor ax,ax  return 0
	add	sp,0x6			; 03665
	pop	bp			; 03668
	ret				; 03669

; Dissolve effect (reached via jump table)
	call	effect_dissolve		; 0366A
	db	0x33, 0xC0		; 0366D xor ax,ax
	add	sp,0x6			; 0366F
	pop	bp			; 03672
	ret				; 03673

; --- Level 3 scene 7: final animation and dialog ---
	cmp	word [0x130],0x7	; 03674  scene_index == 7?
	jnz	short loc_03697		; 03679 jnz 0x3697
	cmp	word [0x10c],0x40	; 0367B  player_anim_id > 0x40?
	jng	short loc_03690		; 03680 jng 0x3690

; Play final animation script and show endgame dialog
	call	run_anim_script		; 03682
	call	show_dialog		; 03685  show ending text
	mov	ax,0x1			; 03688  return 1 (game complete)
	add	sp,0x6			; 0368B
	pop	bp			; 0368E
	ret				; 0368F
loc_03690:
	db	0x33, 0xC0		; 03690 xor ax,ax  not ready yet, return 0
	add	sp,0x6			; 03692
	pop	bp			; 03695
	ret				; 03696

; --- Advance scene within level 3 ---
loc_03697:
	inc	word [0x130]		; 03697  ++scene_index
	mov	ax,[0xfa]		; 0369B  combat_phase
	db	0x3D, 0x01, 0x00	; 0369E cmp ax,0x1  approach?
	jnz	short loc_036A7		; 036A1 jnz 0x36a7
	inc	word [0xfa]		; 036A3  advance to retreat

loc_036A7:
; Load scene slot flags and apply wipe
	mov	ax,[0x130]		; 036A7
	shl	ax,1			; 036AA
	db	0x8B, 0xF0		; 036AC mov si,ax
	mov	ax,[si+0x142]		; 036AE  scene_slot_flags[scene_index]
	push	word [0x130]		; 036B2
	mov	[0x12e],ax		; 036B6  scene_transition_pending
	call	effect_wipe		; 036B9
	db	0x8B, 0xE5		; 036BC mov sp,bp

; Scene 7 special setup: load final battle animations
	cmp	word [0x130],0x7	; 036BE  scene_index == 7?
	jnz	short loc_0370E		; 036C3 jnz 0x370e
	mov	word [0x104],0xac	; 036C5  player_x_max = 172
; Load animation scripts for endgame
	mov	ax,0xbd04		; 036CB  destination buffer
	push	ax			; 036CE
	mov	ax,0xd6a9		; 036CF  script filename
	push	ax			; 036D2
	call	load_anim_script	; 036D3
	db	0x8B, 0xE5		; 036D6 mov sp,bp
	mov	ax,0xb			; 036D8  animation data index
	push	ax			; 036DB
	call	load_animation		; 036DC
	db	0x8B, 0xE5		; 036DF mov sp,bp
	mov	ax,0xce3e		; 036E1  second script buffer
	push	ax			; 036E4
	mov	ax,0xd6af		; 036E5  second script filename
	push	ax			; 036E8
	call	load_anim_script	; 036E9
	db	0x8B, 0xE5		; 036EC mov sp,bp
	call	build_enemy_anim_offsets		; 036EE
; Set up final encounter
	mov	word [0xfa],0x0		; 036F1  combat_phase = 0
	mov	word [0x10e],0xc8	; 036F7  enemy_x = 200
	mov	ax,0x1			; 036FD
	mov	bx,[0xcdea]		; 03700  enemy animation backup
	mov	[0xf0],ax		; 03704  game_mode = 1
	mov	[0x110],ax		; 03707  enemy_anim_id = 1
	mov	[0xcde8],bx		; 0370A  enemy_frame_ptr

loc_0370E:
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
	db	0x8B, 0xF3		; 0371F mov si,bx
	cmp	si,0x5			; 03721  scene_index < 5?
	jnc	short loc_0372D		; 03724 jnc 0x372d  out of range
	shl	si,1			; 03726  word index
	jmp	word near [cs:si+0x3715]	; 03728  dispatch via jump table

; ===========================================================
; APPROACH/RETREAT LOGIC (shared by levels 1 and 3)
; ===========================================================

loc_0372D:
; --- Setup approach health regen when entering retreat ---
	cmp	word [0xfa],0x0		; 0372D  combat_phase > 0?
	jng	short loc_0375D		; 03732 jng 0x375d
	cmp	word [0x130],0x5	; 03734  scene_index == 5?
	jnz	short loc_0375D		; 03739 jnz 0x375d
	cmp	word [0x172],0x0	; 0373B  setup already done?
	jnz	short loc_0375D		; 03740 jnz 0x375d
	mov	word [0x172],0x1	; 03742  mark setup done
; Calculate initial regen: 21 - enemy_health
	mov	ax,0x15			; 03748
	sub	ax,[0x116]		; 0374B
	mov	bx,0x2			; 0374F
	mov	[0x124],ax		; 03752  enemy_health_regen = 21 - health
	mov	[0x126],bx		; 03755  hit_regen_timer_e = 2
	mov	[0x120],bx		; 03759  hit_regen_rate_e = 2

loc_0375D:
; --- Check if in approach phase (combat_phase == 1) ---
	cmp	word [0xfa],0x1		; 0375D  approach?
	jz	short loc_03767		; 03762 jz 0x3767
	jmp	0x3af3			; 03764  not approach, return

loc_03767:
; Only levels 1 and 2 use the approach timer logic
	mov	ax,[0xea]		; 03767  current_level
	db	0x3D, 0x01, 0x00	; 0376A cmp ax,0x1
	jz	short loc_03777		; 0376D jz 0x3777
	db	0x3D, 0x02, 0x00	; 0376F cmp ax,0x2
	jz	short loc_03777		; 03772 jz 0x3777
	jmp	0x3af3			; 03774

loc_03777:
; Skip if currently scrolling
	cmp	word [0x12c],0x0	; 03777  scroll_counter > 0?
	jz	short loc_03781		; 0377C jz 0x3781
	jmp	0x3af3			; 0377E

loc_03781:
; Check distance to encounter target
	mov	ax,[0x104]		; 03781  player_x_max
	sub	ax,[0xbcd5]		; 03784  - player_x
	db	0x3D, 0x3C, 0x00	; 03788 cmp ax,0x3c  distance > 60?
	jg	short loc_03790		; 0378B jg 0x3790
	jmp	0x3af3			; 0378D  too close, return

loc_03790:
; --- Initialize approach timer ---
	cmp	word [0x166],0x0	; 03790  approach_timer already set?
	jnz	short loc_037CE		; 03795 jnz 0x37ce  yes, count down
	mov	ax,0x2			; 03797
	mov	word [0x166],0x28	; 0379A  approach_timer = 40
	mov	bx,[0x104]		; 037A0  player_x_max
	sub	bx,[0xbcd5]		; 037A4  distance
	cmp	bx,0xfa			; 037A8  distance < 250?
	mov	[0x126],ax		; 037AC  hit_regen_timer_e = 2
	mov	[0x120],ax		; 037AF  hit_regen_rate_e = 2
	jnl	short loc_037BA		; 037B2 jnl 0x37ba
	mov	word [0x166],0x3c	; 037B4  closer: longer timer (60)
loc_037BA:
	cmp	word [0xe2],0x1		; 037BA  scene_param_e2 == 1?
	jnz	short loc_037C7		; 037BF jnz 0x37c7
	mov	word [0x166],0x32	; 037C1  special encounter: timer = 50
loc_037C7:
	db	0x33, 0xC0		; 037C7 xor ax,ax  return 0
	add	sp,0x6			; 037C9
	pop	bp			; 037CC
	ret				; 037CD

; --- Count down approach timer ---
loc_037CE:
; Prevent timer from reaching 1 if player is in specific animation
	cmp	word [0x166],0x1	; 037CE  timer about to expire?
	jnz	short loc_037E0		; 037D3 jnz 0x37e0
	cmp	word [0x10c],0x8	; 037D5  player in combat anim?
	jnz	short loc_037E0		; 037DA jnz 0x37e0
	inc	word [0x166]		; 037DC  hold timer at 2

loc_037E0:
	mov	ax,[0x166]		; 037E0  approach_timer
	dec	ax			; 037E3
	test	ax,ax			; 037E4
	mov	[0x166],ax		; 037E6
	jz	short loc_037EE		; 037E9 jz 0x37ee  timer expired!
	jmp	0x3aec			; 037EB  not expired, return

; --- Approach timer expired ---
loc_037EE:
; Special case: level 2 with special encounter active
	cmp	word [0xe2],0x1		; 037EE  scene_param_e2?
	jnz	short loc_03851		; 037F3 jnz 0x3851
	cmp	word [0xea],0x2		; 037F5  level 2?
	jnz	short loc_03851		; 037FA jnz 0x3851

; Play special encounter music and set up boss
	mov	ax,0x9			; 037FC  animation data index
	push	ax			; 037FF
	mov	ax,0xd6b6		; 03800  script filename
	push	ax			; 03803
	call	play_music_sequence	; 03804
	db	0x8B, 0xE5		; 03807 mov sp,bp
	mov	ax,0x2			; 03809  animation data index
	push	ax			; 0380C
	call	load_animation		; 0380D
	db	0x8B, 0xE5		; 03810 mov sp,bp
	mov	ax,0x5dc		; 03812  palette offset
	push	ax			; 03815
	mov	ax,0xd687		; 03816
	push	ax			; 03819
	call	load_palette		; 0381A
	db	0x8B, 0xE5		; 0381D mov sp,bp
	push	word [0xea]		; 0381F
	call	spawn_enemy		; 03823
	db	0x8B, 0xE5		; 03826 mov sp,bp
; Reset enemy to frozen state
	mov	word [0x118],0x20	; 03828  enemy_frozen = 32
	mov	word [0x110],0x46	; 0382E  enemy_anim_id = frozen
	mov	ax,[0xce06]		; 03834
	mov	word [0xbb2a],0xffff	; 03837  anim_state = none
	db	0x33, 0xDB		; 0383D xor bx,bx
	mov	[0xcde8],ax		; 0383F  enemy_frame_ptr
	mov	[0xd676],bx		; 03842  eagle_active = 0
	mov	[0xe2],bx		; 03846  scene_param_e2 = 0
	db	0x8B, 0xC3		; 0384A mov ax,bx  return 0
	add	sp,0x6			; 0384C
	pop	bp			; 0384F
	ret				; 03850

; --- Normal approach timer expired: spawn enemy or advance ---
loc_03851:
	mov	ax,[0x104]		; 03851  player_x_max
	sub	ax,[0xbcd5]		; 03854  distance
	cmp	ax,0x190		; 03858  distance > 400?
	jng	short loc_038D7		; 0385B jng 0x38d7  close enough

; Far away (>400): level 2 special eagle handling
	cmp	word [0xea],0x2		; 0385D  level 2?
	jnz	short loc_0389C		; 03862 jnz 0x389c
	cmp	word [0xd676],0x0	; 03864  eagle_active?
	jnz	short loc_0389C		; 03869 jnz 0x389c

; Start eagle encounter
	mov	word [0xd676],0x1	; 0386B  eagle_active = 1
	mov	ax,0x18			; 03871  24 vsync frames
	push	ax			; 03874
	call	wait_vsync		; 03875
	db	0x8B, 0xE5		; 03878 mov sp,bp
	call	effect_scroll_right	; 0387A  scroll screen
	db	0x33, 0xC0		; 0387D xor ax,ax
	mov	bx,[0xbcd5]		; 0387F  player_x
	add	bx,0x128		; 03883  + 296 = eagle spawn position
	mov	word [0x166],0x2	; 03887  approach_timer = 2
	mov	[0xfe],ax		; 0388D  enemy_was_hit = 0
	mov	[0x11e],ax		; 03890  encounter_counter = 0
	mov	[0x114],ax		; 03893  player_hits_left = 0
	mov	[0x10e],bx		; 03896  enemy_x = spawn position
	jmp	short loc_038EC		; 0389A jmp 0x38ec

loc_0389C:
; Apply combat damage and reset state
	push	word [0xea]		; 0389C
	call	spawn_enemy		; 038A0
	db	0x8B, 0xE5		; 038A3 mov sp,bp
	mov	word [0xd676],0x0	; 038A5  eagle_active = 0
	cmp	word [0xea],0x2		; 038AB  level 2?
	jnz	short loc_038C9		; 038B0 jnz 0x38c9
; Cap enemy distance on level 2
	mov	ax,[0xbcd5]		; 038B2  player_x
	mov	bx,[0x10e]		; 038B5  enemy_x
	db	0x2B, 0xD8		; 038B9 sub bx,ax  distance
	cmp	bx,0x140		; 038BB  > 320?
	jng	short loc_038CF		; 038BF jng 0x38cf
	add	ax,0x12c		; 038C1  cap at player_x + 300
	mov	[0x10e],ax		; 038C4  enemy_x = capped
	jmp	short loc_038CF		; 038C7 jmp 0x38cf

loc_038C9:
; Non-level-2: lock scene
	mov	word [0x11a],0x20	; 038C9  scene_locked = 32

loc_038CF:
	mov	word [0xd652],0x0	; 038CF  wipe_prev_left = 0 (force redraw)
	jmp	short loc_038EC		; 038D5 jmp 0x38ec

; Close range (<= 400): apply damage if distance > 30
loc_038D7:
	mov	ax,[0x104]		; 038D7  player_x_max
	sub	ax,[0xbcd5]		; 038DA
	db	0x3D, 0x1E, 0x00	; 038DE cmp ax,0x1e  distance > 30?
	jng	short loc_038EC		; 038E1 jng 0x38ec
	push	word [0xea]		; 038E3
	call	spawn_enemy		; 038E7
	db	0x8B, 0xE5		; 038EA mov sp,bp

loc_038EC:
	db	0x33, 0xC0		; 038EC xor ax,ax  return 0
	add	sp,0x6			; 038EE
	pop	bp			; 038F1
	ret				; 038F2

; ===========================================================
; LEVEL 0 / RETREAT: backward movement and boundary checks
; ===========================================================

; Check if player reached retreat boundary
	mov	ax,[0xbcd5]		; 038F3  player_x
	cmp	ax,[0x102]		; 038F6  player_x_min?
	jnz	short loc_0395F		; 038FA jnz 0x395f

; Player at boundary: level 0 special case
	cmp	word [0xea],0x0		; 038FC  level 0?
	jnz	short loc_0391C		; 03901 jnz 0x391c
; Level 0: reset player position
	mov	word [0xbcd5],0x2c	; 03903  player_x = 44
	mov	word [0x102],0x28	; 03909  player_x_min = 40
	mov	ax,[0xc414]		; 0390F
	mov	[0xc3d2],ax		; 03912  player_frame_ptr
	db	0x33, 0xC0		; 03915 xor ax,ax
	add	sp,0x6			; 03917
	pop	bp			; 0391A
	ret				; 0391B

loc_0391C:
; Levels 1+: retreat through previous scenes
	cmp	word [0xea],0x2		; 0391C  level > 2?
	jng	short loc_0395F		; 03921 jng 0x395f
	mov	ax,[0x130]		; 03923  scene_index
	db	0x3D, 0x02, 0x00	; 03926 cmp ax,0x2  scene_index > 2?
	jng	short loc_0395F		; 03929 jng 0x395f

; Retreat: go back one scene
	dec	word [0x130]		; 0392B  --scene_index
	mov	word [0x12e],0x1	; 0392F  scene_transition_pending = 1
	push	word [0x130]		; 03935
	call	effect_wipe		; 03939
	db	0x8B, 0xE5		; 0393C mov sp,bp
	cmp	word [0x130],0x2	; 0393E  back to scene 2?
	jnz	short loc_0394E		; 03943 jnz 0x394e
	mov	word [0xc3a6],0x2	; 03945  anim_bg_counter = 2
	call	effect_fade		; 0394B

loc_0394E:
; Reset player position for new scene
	mov	ax,0x114		; 0394E
	mov	[0xbcd5],ax		; 03951  player_x = 276
	inc	ax			; 03954
	inc	ax			; 03955
	add	word [0x10e],0x114	; 03956  enemy_x += 276
	mov	[0x104],ax		; 0395C  player_x_max = 278

; ===========================================================
; DISTANCE AND FREEZE CHECKS
; ===========================================================
loc_0395F:
	mov	ax,[0x10e]		; 0395F  enemy_x
	sub	ax,[0xbcd5]		; 03962  - player_x
	cmp	ax,0x14a		; 03966  distance >= 330?
	mov	[bp+0x4],ax		; 03969
	jnl	short loc_03991		; 0396C jnl 0x3991  far away

; Close enough: clear frozen/locked state
	db	0x33, 0xC0		; 0396E xor ax,ax
	cmp	word [0x110],0x3f	; 03970  enemy alive?
	mov	[0x11a],ax		; 03975  scene_locked = 0
	mov	[0x118],ax		; 03978  enemy_frozen = 0
	jng	short loc_0398A		; 0397B jng 0x398a
	cmp	word [0xea],0x0		; 0397D  not level 0?
	jng	short loc_0398A		; 03982 jng 0x398a
	mov	word [0x110],0x1	; 03984  reset enemy to idle
loc_0398A:
	db	0x33, 0xC0		; 0398A xor ax,ax
	add	sp,0x6			; 0398C
	pop	bp			; 0398F
	ret				; 03990

; --- Enemy is far away: handle freeze countdown ---
loc_03991:
	mov	ax,[0x118]		; 03991  enemy_frozen
	db	0x3D, 0x01, 0x00	; 03994 cmp ax,0x1  > 1?
	jng	short loc_039A4		; 03997 jng 0x39a4
	dec	word [0x118]		; 03999  --enemy_frozen
	db	0x33, 0xC0		; 0399D xor ax,ax
	add	sp,0x6			; 0399F
	pop	bp			; 039A2
	ret				; 039A3

loc_039A4:
; enemy_frozen == 1: thaw enemy
	cmp	word [0x118],0x1	; 039A4
	jnz	short loc_039CF		; 039A9 jnz 0x39cf
	db	0x33, 0xC0		; 039AB xor ax,ax
; Set up enemy to enter scene
	mov	word [0x11a],0x20	; 039AD  scene_locked = 32
	mov	word [0x110],0x46	; 039B3  enemy_anim_id = entering
	mov	bx,[0xce06]		; 039B9
	mov	word [0xbb2a],0xffff	; 039BD  anim_state = none
	mov	[0x118],ax		; 039C3  enemy_frozen = 0
	mov	[0xcde8],bx		; 039C6  enemy_frame_ptr
	add	sp,0x6			; 039CA
	pop	bp			; 039CD
	ret				; 039CE

loc_039CF:
; --- Scene locked countdown ---
	mov	ax,[0x11a]		; 039CF  scene_locked
	db	0x3D, 0x01, 0x00	; 039D2 cmp ax,0x1  > 1?
	jng	short loc_039E2		; 039D5 jng 0x39e2
	dec	word [0x11a]		; 039D7  --scene_locked
	db	0x33, 0xC0		; 039DB xor ax,ax
	add	sp,0x6			; 039DD
	pop	bp			; 039E0
	ret				; 039E1

loc_039E2:
; scene_locked == 1: unlock and spawn enemy
	cmp	word [0x11a],0x1	; 039E2
	jnz	short loc_03A26		; 039E7 jnz 0x3a26
	mov	word [0x11a],0x0	; 039E9  scene_locked = 0

; Level 1: re-freeze enemy at far distance
	cmp	word [0xea],0x1		; 039EF  level 1?
	jnz	short loc_03A16		; 039F4 jnz 0x3a16
	mov	word [0x118],0x20	; 039F6  enemy_frozen = 32
	mov	word [0xbb2a],0xffff	; 039FC  anim_state = none
	mov	ax,[bp+0x4]		; 03A02  distance
	cmp	ax,0x320		; 03A05  > 800?
	jng	short loc_03A26		; 03A08 jng 0x3a26
; Very far: move enemy closer
	mov	bx,0x2			; 03A0A
	cwd				; 03A0D
	idiv	bx			; 03A0E  distance / 2
	sub	[0x10e],ax		; 03A10  enemy_x -= distance/2
	jmp	short loc_03A26		; 03A14 jmp 0x3a26

loc_03A16:
; Other levels: trigger approach
	mov	ax,0x1			; 03A16
	dec	word [0x158]		; 03A19  --player_y_off
	mov	word [0x114],0x0	; 03A1D  player_hits_left = 0
	mov	[0xfa],ax		; 03A23  combat_phase = 1 (approach)

loc_03A26:
	db	0x33, 0xC0		; 03A26 xor ax,ax  return 0
	add	sp,0x6			; 03A28
	pop	bp			; 03A2B
	ret				; 03A2C
