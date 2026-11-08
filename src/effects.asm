; Screen effects, vsync, buffers, UI, health bar, dialog


; ---- function place_player_for_scene ----
; Places the player for a new scene and selects its animation row via
; load_anim_row.
;
; Parameters (on stack):
;   [bp+0x6] = scene index (callers push scene_index [0x130]):
;              2     = player_x and player_x_min both 0x20
;              other = player_x 4, player_x_min 0
;              7     = row index 5 (otherwise row 3 + draw_health_bars_pending)
;
; Reads:   [0x12e]  = draw_health_bars_pending, added to the row index
; Writes:  [0xd672] = cutscene_state (1 becomes 2, otherwise unchanged)
;          [0xbcd5] = player_x
;          [0x102]  = player_x_min
;          [0xc3a6] = anim_bg_counter (row index), plus load_anim_row's writes
; Returns: nothing useful in AX.
place_player_for_scene:
	push	bp			; 03A2D
	sub	sp,0x2			; 03A2E
	jc	short place_player_for_scene_stack_overflow		; 03A31 jc 0x3a39
	cmp	sp,[stack_limit]		; 03A33
	ja	short place_player_for_scene_stack_ok		; 03A37 ja 0x3a3c
place_player_for_scene_stack_overflow:
	jmp	near stack_overflow_handler			; 03A39
place_player_for_scene_stack_ok:
	db	0x8B, 0xEC		; 03A3C mov bp,sp
; cutscene_state 1 advances to 2
	mov	ax,[cutscene_state]		; 03A3E
	db	0x3D, 0x01, 0x00	; 03A41 cmp ax,0x1
	jnz	short place_player_for_scene_set_position		; 03A44 jnz 0x3a4a
	inc	word [cutscene_state]		; 03A46
; Scene 2 starts further right, with a matching left bound
place_player_for_scene_set_position:
	cmp	word [bp+0x6],0x2	; 03A4A
	jnz	short place_player_for_scene_default_position		; 03A4E jnz 0x3a5b
	mov	ax,0x20			; 03A50
	mov	[player_x],ax		; 03A53
	mov	[player_x_min],ax		; 03A56
	jmp	short place_player_for_scene_choose_anim_row		; 03A59 jmp 0x3a67
place_player_for_scene_default_position:
	mov	word [player_x_min],0x0	; 03A5B
	mov	word [player_x],0x4	; 03A61
; Choose the animation row
place_player_for_scene_choose_anim_row:
	mov	word [anim_bg_counter],0x3	; 03A67
	cmp	word [bp+0x6],0x7	; 03A6D
	jnz	short place_player_for_scene_row_from_transition_pending		; 03A71 jnz 0x3a7b
	mov	word [anim_bg_counter],0x5	; 03A73
	jmp	short place_player_for_scene_load_row		; 03A79 jmp 0x3a82
place_player_for_scene_row_from_transition_pending:
	mov	ax,[draw_health_bars_pending]		; 03A7B
	add	[anim_bg_counter],ax		; 03A7E
place_player_for_scene_load_row:
	call	load_anim_row		; 03A82
	add	sp,0x2			; 03A85
	pop	bp			; 03A88
	ret				; 03A89

; ---- function load_anim_row ----
; Loads the current animation row, selected by anim_bg_counter [0xc3a6], and
; forces a redraw.
; No parameters.
;
; compact_anim_data (sound.asm) fills three parallel word tables with pointers
; into the script buffer at 0xc102, one entry per row:
;   [0xc3a8+2n] -> [0xc3a0] row start
;   [0xc3b6+2n] -> [0xc3a2] row middle (position of a 0x12 marker in the data)
;   [0xc3c4+2n] -> [0xc3a4] row end
; scene.asm copies [c3a0,c3a2) and [c3a2,c3a4) as two separate blocks.
;
; Writes: [0xbb2a] = 0xFFFF (last_drawn_camera_x: no background rendered yet)
;         [0xd652] = 0 (wipe_prev_left)
;         [0xee]   = 1 (anim_render_mode: normal)
;         [0xc3a0], [0xc3a2], [0xc3a4] as above
load_anim_row:
	push	bp			; 03A8A
	sub	sp,0x4			; 03A8B
	jc	short load_anim_row_stack_overflow		; 03A8E jc 0x3a96
	cmp	sp,[stack_limit]		; 03A90
	ja	short load_anim_row_stack_ok		; 03A94 ja 0x3a99
load_anim_row_stack_overflow:
	jmp	near stack_overflow_handler			; 03A96
load_anim_row_stack_ok:
	db	0x8B, 0xEC		; 03A99 mov bp,sp
; Force a background redraw
	mov	word [last_drawn_camera_x],0xffff	; 03A9B
	mov	word [wipe_prev_left],0x0	; 03AA1
	mov	word [anim_render_mode],0x1		; 03AA7
; Load the row selected by anim_bg_counter
	mov	ax,[anim_bg_counter]		; 03AAD
	shl	ax,1			; 03AB0
	db	0x8B, 0xF0		; 03AB2 mov si,ax
	mov	bx,[si+scenery_row_starts]		; 03AB4
	mov	cx,[si+scenery_row_middles]		; 03AB8
	mov	ax,[si+scenery_row_ends]		; 03ABC
	mov	[scenery_row_end_ptr],ax		; 03AC0
	mov	[scenery_row_mid_ptr],cx		; 03AC3
	mov	[scenery_row_start_ptr],bx		; 03AC7
	add	sp,0x4			; 03ACB
	pop	bp			; 03ACE
	ret				; 03ACF

; ---- function load_scroll_anim_row ----
; Same job as load_anim_row, but takes the row index from scroll_counter and
; selects transition rendering.
; Called by the eagle scroll logic in levels.asm after it steps scroll_counter.
; No parameters.
;
; Reads:  [0x12c]  = scroll_counter (row index)
;         [0xc3a8+2n], [0xc3b6+2n], [0xc3c4+2n] (see load_anim_row)
; Writes: [0xc3a6] = anim_bg_counter (= scroll_counter)
;         [0xee]   = 2 (anim_render_mode: transition)
;         [0xbb2a] = 0xFFFF, [0xd652] = 0
;         [0xc3a0], [0xc3a2], [0xc3a4] = row start, middle, end
load_scroll_anim_row:
	push	bp			; 03AD0
	sub	sp,0x4			; 03AD1
	jc	short load_scroll_anim_row_stack_overflow		; 03AD4 jc 0x3adc
	cmp	sp,[stack_limit]		; 03AD6
	ja	short load_scroll_anim_row_stack_ok		; 03ADA ja 0x3adf
load_scroll_anim_row_stack_overflow:
	jmp	near stack_overflow_handler			; 03ADC
load_scroll_anim_row_stack_ok:
	db	0x8B, 0xEC		; 03ADF mov bp,sp
	mov	word [wipe_prev_left],0x0	; 03AE1
	mov	ax,0x2			; 03AE7
	mov	word [last_drawn_camera_x],0xffff	; 03AEA
; scroll_counter selects the row
	mov	bx,[scroll_counter]		; 03AF0
	mov	[anim_bg_counter],bx		; 03AF4
	shl	bx,1			; 03AF8
	mov	cx,[bx+scenery_row_starts]		; 03AFA
	mov	dx,[bx+scenery_row_middles]		; 03AFE
	mov	[anim_render_mode],ax		; 03B02
	mov	ax,[bx+scenery_row_ends]		; 03B05
	mov	[scenery_row_end_ptr],ax		; 03B09
	mov	[scenery_row_start_ptr],cx		; 03B0C
	mov	[scenery_row_mid_ptr],dx		; 03B10
	add	sp,0x4			; 03B14
	pop	bp			; 03B17
	ret				; 03B18

; ---- function activate_enemy ----
; Activates the enemy for an encounter at a random vertical offset.
; No parameters.
;
; Reads:  [0xce28] = enemy frame table entry (0xcdea + 2*0x1F, so likely the
;                    frame for animation 0x1F)
; Writes: [0xd5aa] = 1 (special_enemy_active)
;         [0x110]  = 0x1F (enemy_anim_id)
;         [0xcde8] = enemy_frame_ptr, from [0xce28]
;         [0xd5ac] = enemy_y_off = rand_range(2) * 12, so 0, 12 or 24
;         [0xfa]   = 0 (combat_phase)
;         [0xd650] = 0 (wipe_prev_right)
activate_enemy:
	push	bp			; 03B19
	sub	sp,0x2			; 03B1A
	jc	short activate_enemy_stack_overflow		; 03B1D jc 0x3b25
	cmp	sp,[stack_limit]		; 03B1F
	ja	short activate_enemy_stack_ok		; 03B23 ja 0x3b28
activate_enemy_stack_overflow:
	jmp	near stack_overflow_handler			; 03B25
activate_enemy_stack_ok:
	db	0x8B, 0xEC		; 03B28 mov bp,sp
; Activate the enemy with animation 0x1F
	mov	word [special_enemy_active],0x1	; 03B2A
	mov	word [enemy_anim_id],0x1f	; 03B30
	mov	ax,[enemy_seq_eagle_fly]		; 03B36
; enemy_y_off = rand_range(2) * 12
	mov	bx,0x2			; 03B39
	push	bx			; 03B3C
	mov	[enemy_frame_ptr],ax		; 03B3D
	call	rand_range		; 03B40
	db	0x8B, 0xE5		; 03B43 mov sp,bp
	mov	bx,0xc			; 03B45
	imul	bx			; 03B48
	db	0x33, 0xDB		; 03B4A xor bx,bx
	mov	[enemy_y_off],ax		; 03B4C
	mov	[combat_phase],bx		; 03B4F
	mov	[wipe_prev_right],bx		; 03B53
	add	sp,0x2			; 03B57
	pop	bp			; 03B5A
	ret				; 03B5B

; ---- function health_decrement_push ----
; One step of health loss with a 4-pixel push to the left, plus sound 1.
; No parameters.
;
; Reads/writes: [0x116] = player_hit_points in data.asm, decremented once per call
;               (the code also uses this word as a left wipe column count)
; Writes: [0xbcd5] = player_x, minus 4
; When [0x116] reaches 0:
;   [0xf8] = 1 (combat_active), [0xc3d2] = [0xc40c] (the frame levels.asm
;   calls the death animation frame). Returns AX = 0.
; Otherwise:
;   [0x124] += 1 (player_regen_pending), [0x10c] = 0 (player_anim_id),
;   [0xc3d2] = [0xc3d4]. AX is left holding that frame pointer.
; Both callers ignore the return value (they zero AX right after).
health_decrement_push:
	push	bp			; 03B5C
	sub	sp,0x2			; 03B5D
	jc	short health_decrement_push_stack_overflow		; 03B60 jc 0x3b68
	cmp	sp,[stack_limit]		; 03B62
	ja	short health_decrement_push_stack_ok		; 03B66 ja 0x3b6b
health_decrement_push_stack_overflow:
	jmp	near stack_overflow_handler			; 03B68
health_decrement_push_stack_ok:
	db	0x8B, 0xEC		; 03B6B mov bp,sp
; Sound 1, then the 4-pixel push
	mov	ax,0x1			; 03B6D
	push	ax			; 03B70
	call	play_sound		; 03B71
	db	0x8B, 0xE5		; 03B74 mov sp,bp
	sub	word [player_x],0x4	; 03B76
; Lose one point of health
	mov	ax,[player_hit_points]		; 03B7B
	dec	ax			; 03B7E
	test	ax,ax			; 03B7F
	mov	[player_hit_points],ax		; 03B81
	jnz	short health_decrement_push_health_remains		; 03B84 jnz 0x3b99
	mov	word [combat_active],0x1		; 03B86
	mov	ax,[player_seq_death]		; 03B8C
	mov	[player_frame_ptr],ax		; 03B8F
	db	0x33, 0xC0		; 03B92 xor ax,ax
	add	sp,0x2			; 03B94
	pop	bp			; 03B97
	ret				; 03B98
; Health remains: back to the idle animation
health_decrement_push_health_remains:
	inc	word [player_regen_pending]		; 03B99
	mov	word [player_anim_id],0x0	; 03B9D
	mov	ax,[player_seq_offsets]		; 03BA3
	mov	[player_frame_ptr],ax		; 03BA6
	add	sp,0x2			; 03BA9
	pop	bp			; 03BAC
	ret				; 03BAD

; ---- function play_sound ----
; Sound dispatcher: plays one PC speaker effect or tune and blocks until it
; ends.
;
; Parameters (on stack):
;   [bp+0x4] = sound index (0 = no sound, return immediately)
;
; Reads: [0xd6bc] = sound mode, cycled by Ctrl+S in poll_keyboard:
;          0   = all sounds
;          1   = effects only: 1-8 and 22-24 play; 9-21 and 25 up are silent
;          2   = silent
;        (play_sound_5_forced temporarily forces mode 0, see input.asm 04245)
; Writes: speaker port 0x61, and the music_* variables for tunes.
; Clobbers: AX, BX, CX, DX. Returns nothing useful.
;
; Dispatch: index-1 selects a word in the jump table at DS:0xD6BD (file offset
; 0x1455D). The table has 26 entries; no range check is made, and the words
; that follow it are not code addresses.
;
;   idx  label                      sound
;   1    play_sound_sweep_long      falling sweep, 38 toggles, delay 2..0x27
;   2    play_sound_sweep_wide      falling sweep, 28 toggles, delay 2..0x38 by 2
;   3    play_sound_sweep_short     falling sweep, 18 toggles, delay 2..0x24 by 2
;   4    play_sound_buzz_high       10 toggles at fixed delay 5
;   5    play_sound_buzz_low        16 toggles at fixed delay 10
;   6    play_sound_chirp_up        rising chirp, 4 toggles, delay 0x10,8,4,2
;   7    play_sound_thud            3 toggles at fixed delay 0x10
;   8    play_sound_pcm_rate_d710   PCM sample, rate from [0xd710] (0x0C in EXE)
;   9-21 play_sound_music_09 to _21 tunes (data pointers at each stub)
;   22   play_sound_pcm_rate_d712   PCM sample, rate from [0xd712] (0x09 in EXE)
;   23   play_sound_pcm_rate_d714   PCM sample, rate from [0xd714] (0x07 in EXE)
;   24   play_sound_pcm_rate_d716   PCM sample, rate from [0xd716] (0x04 in EXE)
;   25   play_sound_music_25        tune
;   26   play_sound_music_26        tune
;
; Delay above means the CX passed to busy_wait_delay: larger is a longer half
; period, so a lower pitch. The CPU speed code in system.asm rescales at least
; the bytes at 0xD70E-0xD712 at startup, so those PCM rates can differ at runtime.
;
; Music player (play_sound_music_start). Tune data is:
;   byte 0 = music_tempo_hi (outer duration count per note unit)
;   byte 1 = music_tempo_lo (stored, never read here; 0xC0 in all 15 tunes)
;   then a list of items:
;     0xFF       = end of tune
;     0xFE       = music_vibrato = 0
;     0xFD nn    = music_vibrato = nn
;     cnt hi lo  = note: cnt units long, half period (hi-1)*256 + lo passes
; A note runs cnt * tempo_hi * 255 passes. Each pass steps two square wave
; counters that share the speaker, A reloading its low counter with lo and
; B with lo-1, so the two are slightly detuned. While music_vibrato is nonzero,
; every toggle from A resets B's low counter to music_vibrato.
; The "cmp pitch,0x80 / jl" before each toggle is signed against -128, so the
; branch is never taken and notes always toggle; an item like "08 FF 00" is
; only a rest because its half period is very long.
; Channel B detail: when DL reaches 0 with music_pitch_b still nonzero, the jump back to play_sound_music_channel_b decrements DL again (0 wraps to 0xFF), so each high-count borrow costs B one extra low-count step within the same pass.
play_sound:
	push	bp			; 03BAE
	db	0x8B, 0xEC		; 03BAF mov bp,sp
; Sound index in BX; 0 means nothing to play
	mov	bx,[bp+0x4]		; 03BB1
	cmp	bl,0x0			; 03BB4
	jz	short play_sound_return		; 03BB7 jz 0x3be7
; Apply the sound mode: 0 plays all, 1 filters, 2 or more returns
	cmp	byte [sound_mode],0x0	; 03BB9
	jz	short play_sound_silence_and_dispatch		; 03BBE jz 0x3bda
	cmp	byte [sound_mode],0x1	; 03BC0
	jz	short play_sound_filter_effects_only		; 03BC5 jz 0x3bc9
	pop	bp			; 03BC7
	ret				; 03BC8
; Mode 1: indices 1-8 and 22-24 play, tunes 9-21 and 25 up are silent
play_sound_filter_effects_only:
	cmp	bl,0x9			; 03BC9
	jc	short play_sound_silence_and_dispatch		; 03BCC jc 0x3bda
	cmp	bl,0x16			; 03BCE
	jc	short play_sound_return		; 03BD1 jc 0x3be7
	cmp	bl,0x19			; 03BD3
	jc	short play_sound_silence_and_dispatch		; 03BD6 jc 0x3bda
	pop	bp			; 03BD8
	ret				; 03BD9
; Speaker off (timer gate and data bits clear), then jump to the case
play_sound_silence_and_dispatch:
	in	al,byte 0x61		; 03BDA
	and	al,0xfc			; 03BDC
	out	byte 0x61,al		; 03BDE
	dec	bx			; 03BE0
	shl	bx,1			; 03BE1
	jmp	word near [bx+sound_jump_table]	; 03BE3
play_sound_return:
	pop	bp			; 03BE7
	ret				; 03BE8
; Index 1: falling sweep, 38 toggles, busy_wait_delay(CX) with CX = 2..0x27
play_sound_sweep_long:
	mov	cx,0x2			; 03BE9
play_sound_sweep_long_loop:
	push	cx			; 03BEC
	call	toggle_speaker		; 03BED
	call	busy_wait_delay		; 03BF0
	pop	cx			; 03BF3
	inc	cx			; 03BF4
	cmp	cx,0x28			; 03BF5
	jl	short play_sound_sweep_long_loop		; 03BF8 jl 0x3bec
	pop	bp			; 03BFA
	ret				; 03BFB
; Index 2: falling sweep, 28 toggles, CX = 2..0x38 in steps of 2
play_sound_sweep_wide:
	mov	cx,0x2			; 03BFC
play_sound_sweep_wide_loop:
	push	cx			; 03BFF
	call	toggle_speaker		; 03C00
	call	busy_wait_delay		; 03C03
	pop	cx			; 03C06
	inc	cx			; 03C07
	inc	cx			; 03C08
	cmp	cx,0x3a			; 03C09
	jl	short play_sound_sweep_wide_loop		; 03C0C jl 0x3bff
	pop	bp			; 03C0E
	ret				; 03C0F
; Index 3: falling sweep, 18 toggles, CX = 2..0x24 in steps of 2
play_sound_sweep_short:
	mov	cx,0x2			; 03C10
play_sound_sweep_short_loop:
	push	cx			; 03C13
	call	toggle_speaker		; 03C14
	call	busy_wait_delay		; 03C17
	pop	cx			; 03C1A
	inc	cx			; 03C1B
	inc	cx			; 03C1C
	cmp	cx,0x24			; 03C1D
	jng	short play_sound_sweep_short_loop		; 03C20 jng 0x3c13
	pop	bp			; 03C22
	ret				; 03C23
; Index 4: 10 toggles with a fixed delay of 5
play_sound_buzz_high:
	mov	bl,0xa			; 03C24
play_sound_buzz_high_loop:
	mov	cx,0x5			; 03C26
	call	busy_wait_delay		; 03C29
	call	toggle_speaker		; 03C2C
	dec	bl			; 03C2F
	jnz	short play_sound_buzz_high_loop		; 03C31 jnz 0x3c26
	pop	bp			; 03C33
	ret				; 03C34
; Index 5: 16 toggles with a fixed delay of 10
play_sound_buzz_low:
	mov	bl,0x10			; 03C35
play_sound_buzz_low_loop:
	mov	cx,0xa			; 03C37
	call	busy_wait_delay		; 03C3A
	call	toggle_speaker		; 03C3D
	dec	bl			; 03C40
	jnz	short play_sound_buzz_low_loop		; 03C42 jnz 0x3c37
	pop	bp			; 03C44
	ret				; 03C45
; Index 6: rising chirp, 4 toggles, CX = 0x10, 8, 4, 2
play_sound_chirp_up:
	mov	cx,0x10			; 03C46
play_sound_chirp_up_loop:
	push	cx			; 03C49
	call	toggle_speaker		; 03C4A
	call	busy_wait_delay		; 03C4D
	pop	cx			; 03C50
	shr	cx,1			; 03C51
	cmp	cx,0x1			; 03C53
	jnz	short play_sound_chirp_up_loop		; 03C56 jnz 0x3c49
	pop	bp			; 03C58
	ret				; 03C59
; Index 7: 3 toggles with a fixed delay of 0x10
play_sound_thud:
	mov	bl,0x3			; 03C5A
play_sound_thud_loop:
	mov	cx,0x10			; 03C5C
	call	busy_wait_delay		; 03C5F
	call	toggle_speaker		; 03C62
	dec	bl			; 03C65
	jnz	short play_sound_thud_loop		; 03C67 jnz 0x3c5c
	pop	bp			; 03C69
	ret				; 03C6A
; Index 8: PCM sample at the rate in [0xd710] (0x0C in the EXE)
play_sound_pcm_rate_d710:
	mov	ax,[pcm_delay_sound_8]		; 03C6B
	mov	[speaker_delay],al	; 03C6E
	call	play_speaker_data	; 03C71
	pop	bp			; 03C74
	ret				; 03C75
; Index 22: PCM sample at the rate in [0xd712] (0x09 in the EXE)
play_sound_pcm_rate_d712:
	mov	ax,[pcm_delay_sound_22]		; 03C76
	mov	[speaker_delay],al	; 03C79
	call	play_speaker_data	; 03C7C
	pop	bp			; 03C7F
	ret				; 03C80
; Index 23: PCM sample at the rate in [0xd714] (0x07 in the EXE)
play_sound_pcm_rate_d714:
	mov	ax,[pcm_delay_sound_23]		; 03C81
	mov	[speaker_delay],al	; 03C84
	call	play_speaker_data	; 03C87
	pop	bp			; 03C8A
	ret				; 03C8B
; Index 24: PCM sample at the rate in [0xd716] (0x04 in the EXE)
play_sound_pcm_rate_d716:
	mov	ax,[pcm_delay_sound_24]		; 03C8C
	mov	[speaker_delay],al	; 03C8F
	call	play_speaker_data	; 03C92
	pop	bp			; 03C95
	ret				; 03C96
; Index 9: tune at DS:0xD736, tempo_hi 0x04
play_sound_music_09:
	mov	bx,0xd736		; 03C97
	jmp	short play_sound_music_start		; 03C9A jmp 0x3cf1
	nop				; 03C9C
; Index 10: tune at DS:0xD77E, tempo_hi 0x06
play_sound_music_10:
	mov	bx,0xd77e		; 03C9D
	jmp	short play_sound_music_start		; 03CA0 jmp 0x3cf1
	nop				; 03CA2
; Index 11: tune at DS:0xD7B2, tempo_hi 0x03
play_sound_music_11:
	mov	bx,0xd7b2		; 03CA3
	jmp	short play_sound_music_start		; 03CA6 jmp 0x3cf1
	nop				; 03CA8
; Index 12: tune at DS:0xD7D7, tempo_hi 0x05
play_sound_music_12:
	mov	bx,0xd7d7		; 03CA9
	jmp	short play_sound_music_start		; 03CAC jmp 0x3cf1
	nop				; 03CAE
; Index 13: tune at DS:0xD7E7, tempo_hi 0x03
play_sound_music_13:
	mov	bx,0xd7e7		; 03CAF
	jmp	short play_sound_music_start		; 03CB2 jmp 0x3cf1
	nop				; 03CB4
; Index 14: tune at DS:0xD800, tempo_hi 0x07
play_sound_music_14:
	mov	bx,0xd800		; 03CB5
	jmp	short play_sound_music_start		; 03CB8 jmp 0x3cf1
	nop				; 03CBA
; Index 15: tune at DS:0xD834, tempo_hi 0x07
play_sound_music_15:
	mov	bx,0xd834		; 03CBB
	jmp	short play_sound_music_start		; 03CBE jmp 0x3cf1
	nop				; 03CC0
; Index 16: tune at DS:0xD853, tempo_hi 0x05
play_sound_music_16:
	mov	bx,0xd853		; 03CC1
	jmp	short play_sound_music_start		; 03CC4 jmp 0x3cf1
	nop				; 03CC6
; Index 17: tune at DS:0xD87B, tempo_hi 0x04
play_sound_music_17:
	mov	bx,0xd87b		; 03CC7
	jmp	short play_sound_music_start		; 03CCA jmp 0x3cf1
	nop				; 03CCC
; Index 18: tune at DS:0xD894, tempo_hi 0x04
play_sound_music_18:
	mov	bx,0xd894		; 03CCD
	jmp	short play_sound_music_start		; 03CD0 jmp 0x3cf1
	nop				; 03CD2
; Index 19: tune at DS:0xD8CE, tempo_hi 0x04
play_sound_music_19:
	mov	bx,0xd8ce		; 03CD3
	jmp	short play_sound_music_start		; 03CD6 jmp 0x3cf1
	nop				; 03CD8
; Index 20: tune at DS:0xD911, tempo_hi 0x04
play_sound_music_20:
	mov	bx,0xd911		; 03CD9
	jmp	short play_sound_music_start		; 03CDC jmp 0x3cf1
	nop				; 03CDE
; Index 21: tune at DS:0xD95A, tempo_hi 0x28
play_sound_music_21:
	mov	bx,0xd95a		; 03CDF
	jmp	short play_sound_music_start		; 03CE2 jmp 0x3cf1
	nop				; 03CE4
; Index 25: tune at DS:0xDA25, tempo_hi 0x0A
play_sound_music_25:
	mov	bx,0xda25		; 03CE5
	jmp	short play_sound_music_start		; 03CE8 jmp 0x3cf1
	nop				; 03CEA
; Index 26: tune at DS:0xD817, tempo_hi 0x07
play_sound_music_26:
	mov	bx,0xd817		; 03CEB
	jmp	short play_sound_music_start		; 03CEE jmp 0x3cf1
	nop				; 03CF0
; --- Music player: BX = tune data, first the 2-byte header ---
play_sound_music_start:
	mov	al,[bx]			; 03CF1
	mov	[music_tempo_hi],al	; 03CF3
	inc	bx			; 03CF6
	mov	al,[bx]			; 03CF7
	mov	[music_tempo_lo],al	; 03CF9
	inc	bx			; 03CFC
	mov	[music_note_ptr],bx	; 03CFD
; Fetch the next item: end, vibrato command, or note
play_sound_music_next_item:
	mov	bx,[music_note_ptr]	; 03D01
	mov	al,[bx]			; 03D05
	cmp	al,0xff			; 03D07
	jnz	short play_sound_music_check_vibrato_off		; 03D09 jnz 0x3d0d
	pop	bp			; 03D0B
	ret				; 03D0C
play_sound_music_check_vibrato_off:
	cmp	al,0xfe			; 03D0D
	jnz	short play_sound_music_check_vibrato_set		; 03D0F jnz 0x3d1d
	mov	byte [music_vibrato],0x0	; 03D11
	inc	bx			; 03D16
	mov	[music_note_ptr],bx	; 03D17
	jmp	short play_sound_music_next_item		; 03D1B jmp 0x3d01
play_sound_music_check_vibrato_set:
	cmp	al,0xfd			; 03D1D
	jnz	short play_sound_music_load_note		; 03D1F jnz 0x3d2e
	inc	bx			; 03D21
	mov	al,[bx]			; 03D22
	mov	[music_vibrato],al	; 03D24
	inc	bx			; 03D27
	mov	[music_note_ptr],bx	; 03D28
	jmp	short play_sound_music_next_item		; 03D2C jmp 0x3d01
; Note item: cnt, hi, lo
play_sound_music_load_note:
	mov	[music_note_cnt],al	; 03D2E
	inc	bx			; 03D31
	mov	al,[bx]			; 03D32
	mov	[music_pitch_a],al	; 03D34
	mov	[music_pitch_b],al	; 03D37
	mov	[music_pitch],al	; 03D3A
	inc	bx			; 03D3D
	mov	al,[bx]			; 03D3E
	mov	[music_period],al	; 03D40
	mov	al,[music_period]	; 03D43
	db	0x8A, 0xC8		; 03D46 mov cl,al
	db	0x8A, 0xD0		; 03D48 mov dl,al
; --- Note loop: cnt units, each tempo_hi * 255 passes ---
play_sound_music_note_unit_loop:
	mov	al,[music_tempo_hi]	; 03D4A
	mov	[music_outer],al	; 03D4D
play_sound_music_tempo_loop:
	mov	byte [music_inner],0xff	; 03D50
; Channel A: CL and music_pitch_a count down the half period
play_sound_music_channel_a:
	dec	cl			; 03D55
	jnz	short play_sound_music_channel_b		; 03D57 jnz 0x3d7f
	dec	byte [music_pitch_a]	; 03D59
	jnz	short play_sound_music_channel_b		; 03D5D jnz 0x3d7f
	cmp	byte [music_pitch],0x80	; 03D5F
	jl	short play_sound_music_reload_channel_a		; 03D64 jl 0x3d69
	call	toggle_speaker		; 03D66
; Reload A; a nonzero vibrato also resets B low counter
; Also the target of the signed "cmp pitch,0x80 / jl", which is never taken
play_sound_music_reload_channel_a:
	mov	cl,[music_period]	; 03D69
	mov	al,[music_pitch]	; 03D6D
	mov	[music_pitch_a],al	; 03D70
	cmp	byte [music_vibrato],0x0	; 03D73
	jz	short play_sound_music_channel_b		; 03D78 jz 0x3d7f
	mov	al,[music_vibrato]	; 03D7A
	db	0x8A, 0xD0		; 03D7D mov dl,al
; Channel B: DL and music_pitch_b, one count shorter on reload
play_sound_music_channel_b:
	dec	dl			; 03D7F
	jnz	short play_sound_music_end_of_pass		; 03D81 jnz 0x3d9f
	dec	byte [music_pitch_b]	; 03D83
	jnz	short play_sound_music_channel_b		; 03D87 jnz 0x3d7f
	cmp	byte [music_pitch],0x80	; 03D89
	jl	short play_sound_music_reload_channel_b		; 03D8E jl 0x3d93
	call	toggle_speaker		; 03D90
; Also the target of the signed "cmp pitch,0x80 / jl", which is never taken
play_sound_music_reload_channel_b:
	mov	dl,[music_period]	; 03D93
	dec	dl			; 03D97
	mov	al,[music_pitch]	; 03D99
	mov	[music_pitch_b],al	; 03D9C
; End of pass: run the duration counters
play_sound_music_end_of_pass:
	dec	byte [music_inner]	; 03D9F
	jnz	short play_sound_music_channel_a		; 03DA3 jnz 0x3d55
	dec	byte [music_outer]	; 03DA5
	jnz	short play_sound_music_tempo_loop		; 03DA9 jnz 0x3d50
	dec	byte [music_note_cnt]	; 03DAB
	jnz	short play_sound_music_note_unit_loop		; 03DAF jnz 0x3d4a
; Note done: step past it and fetch the next item (target is play_sound_music_next_item:
; jmp operands in this file are file offsets, code offset + 0x200)
	add	word [music_note_ptr],0x3	; 03DB1
	jmp	near play_sound_music_next_item			; 03DB6

; ---- function busy_wait_delay ----
; Software delay used to time speaker toggles.
;
; Parameters (registers):
;   CX = delay factor (must be nonzero)
;
; Reads: [busy_wait_delay_cnt] = outer repeat count (word; 4 in the EXE, and
;        its low byte is rescaled by the CPU speed code in system.asm)
;
; Runs cnt * CX * (CX+1) / 2 inner iterations, so the delay grows with the
; square of CX. The loops use SBB, so CF is assumed clear on entry.
; Preserves BX, DX. Returns CX = 0.
busy_wait_delay:
	push	dx			; 03DB9
	push	bx			; 03DBA
	mov	bx,[busy_wait_delay_cnt]	; 03DBB
	db	0x8B, 0xD1		; 03DBF mov dx,cx
busy_wait_delay_repeat_loop:
	db	0x8B, 0xCA		; 03DC1 mov cx,dx
busy_wait_delay_outer_loop:
	push	cx			; 03DC3
busy_wait_delay_inner_loop:
	sbb	cx,0x1			; 03DC4
	jnz	short busy_wait_delay_inner_loop		; 03DC7 jnz 0x3dc4
	pop	cx			; 03DC9
	sbb	cx,0x1			; 03DCA
	jnz	short busy_wait_delay_outer_loop		; 03DCD jnz 0x3dc3
	dec	bx			; 03DCF
	jnz	short busy_wait_delay_repeat_loop		; 03DD0 jnz 0x3dc1
	pop	bx			; 03DD2
	pop	dx			; 03DD3
	ret				; 03DD4

; ---- function toggle_speaker ----
; Inverts the PC speaker data bit (bit 1 of port 0x61), moving the cone once.
; play_sound clears bits 0-1 of the port before each sound, so the timer gate
; is off and this bit alone drives the speaker.
; No parameters. Preserves AX. Modifies flags (XOR clears CF).
toggle_speaker:
	push	ax			; 03DD5
	in	al,byte 0x61		; 03DD6
	xor	al,0x2			; 03DD8
	out	byte 0x61,al		; 03DDA
	pop	ax			; 03DDC
	ret				; 03DDD

; ---- function play_speaker_data ----
; Plays the 256-byte 1-bit sample at speaker_pcm_buf through the PC speaker.
; No parameters on stack. Clobbers AX, BX, CX, DX.
;
; Reads bits most significant first. Before each bit it spins speaker_delay
; times, then toggles the speaker if the bit differs from the previous one,
; so a sample bit is a speaker level and only changes cost a toggle.
;
; Reads:   speaker_delay (set by the caller, low byte of a [0xd710+] word)
;          speaker_pcm_buf (DS:0xDA56, static sample data in the EXE)
; Updates: speaker_delay_cnt (spin counter)
;          speaker_prev_bit (last byte value; only bit 7 is compared)
play_speaker_data:
	mov	cx,0x100		; 03DDE
	mov	bx,speaker_pcm_buf	; 03DE1
; Next sample byte: 8 bits, MSB first (the loop below targets here)
; next sample byte, 0x100 bytes total
play_speaker_data_byte_loop:
	mov	dl,0x8			; 03DE4
	mov	al,[bx]			; 03DE6
; Spin for the sample period
play_speaker_data_bit_loop:
	mov	ah,[speaker_delay]	; 03DE8
	mov	[speaker_delay_cnt],ah	; 03DEC
play_speaker_data_spin_loop:
	dec	byte [speaker_delay_cnt]	; 03DF0
	jnz	short play_speaker_data_spin_loop		; 03DF4 jnz 0x3df0
; Toggle only if bit 7 differs from the previous sample
	xor	al,[speaker_prev_bit]	; 03DF6
	jns	short play_speaker_data_bit_unchanged		; 03DFA jns 0x3e10
	xor	al,[speaker_prev_bit]	; 03DFC
	mov	[speaker_prev_bit],al	; 03E00
	call	toggle_speaker		; 03E03
; Next bit
play_speaker_data_next_bit:
	shl	al,1			; 03E06
	dec	dl			; 03E08
	jnz	short play_speaker_data_bit_loop		; 03E0A jnz 0x3de8
	inc	bx			; 03E0C
	loop	0x3de4			; 03E0D
	ret				; 03E0F
; Bit unchanged: undo the XOR and continue
play_speaker_data_bit_unchanged:
	xor	al,[speaker_prev_bit]	; 03E10
	jmp	short play_speaker_data_next_bit		; 03E14 jmp 0x3e06

; ---- function patch_font_tables ----
; Patches the font tables once at startup (called only from game_init).
; No parameters. No stack frame. Clobbers AX, BX, CX, SI.
;
; Glyph pointer patches, as indices into font_glyph_ptrs (DS:0xB86A):
;   entries 8 ('i') and 25 ('z') are swapped
;   entry 9 ('j') takes entry 26, then 26..29 each take their successor
;
; Then, for glyph indices 1, 5, 7-13 and 15-17 (b f h i j k l m n p q r, using
; BX = 2 * index with hard-coded skips), clears bit 0 of bitmap bytes 1..9.
; Glyph bitmaps are stored column by column with bit 0 as the leftmost pixel,
; so this removes the left pixel of rows 1-9 in the first column.
patch_font_tables:
; Patch the glyph pointer table
	mov	ax,[font_glyph_ptr_i]		; 03E16
	mov	bx,[font_glyph_ptr_z]		; 03E19
	mov	[font_glyph_ptr_z],ax		; 03E1D
	mov	[font_glyph_ptr_i],bx		; 03E20
	mov	ax,[font_glyph_ptr_period]		; 03E24
	mov	[font_glyph_ptr_j],ax		; 03E27
	mov	ax,[font_glyph_ptr_comma]		; 03E2A
	mov	[font_glyph_ptr_period],ax		; 03E2D
	mov	ax,[font_glyph_ptr_dash]		; 03E30
	mov	[font_glyph_ptr_comma],ax		; 03E33
	mov	ax,[font_glyph_ptr_hyphen]		; 03E36
	mov	[font_glyph_ptr_dash],ax		; 03E39
	mov	ax,[font_glyph_ptr_spare]		; 03E3C
	mov	[font_glyph_ptr_hyphen],ax		; 03E3F
; Clear the left pixel of rows 1-9 for the selected glyphs
	mov	bx,0x2			; 03E42
patch_font_tables_glyph_loop:
	cmp	bx,0x4			; 03E45
	jnz	short patch_font_tables_check_skip_glyph_6		; 03E48 jnz 0x3e4f
	mov	bx,0xa			; 03E4A
	jmp	short patch_font_tables_clear_left_pixels		; 03E4D jmp 0x3e5f
patch_font_tables_check_skip_glyph_6:
	cmp	bx,0xc			; 03E4F
	jnz	short patch_font_tables_check_skip_glyph_14		; 03E52 jnz 0x3e57
	mov	bx,0xe			; 03E54
patch_font_tables_check_skip_glyph_14:
	cmp	bx,0x1c			; 03E57
	jnz	short patch_font_tables_clear_left_pixels		; 03E5A jnz 0x3e5f
	mov	bx,0x1e			; 03E5C
; BX = 2 * glyph index; SI = its bitmap offset
patch_font_tables_clear_left_pixels:
	mov	si,[bx+font_glyph_offset_table]		; 03E5F
	mov	cx,0x9			; 03E63
; 9 glyph bitmap rows
patch_font_tables_clear_left_pixels_row_loop:
	mov	al,[si+font_glyph_bitmap_byte1]		; 03E66
	and	al,0xfe			; 03E6A
	mov	[si+font_glyph_bitmap_byte1],al		; 03E6C
	inc	si			; 03E70
	loop	0x3e66			; 03E71
	add	bx,0x2			; 03E73
	cmp	bx,0x24			; 03E76
	jl	short patch_font_tables_glyph_loop		; 03E79 jl 0x3e45
	ret				; 03E7B

; ---- function render_glyphs ----
; Draws a null-terminated string in the game font into the offscreen buffer.
;
; Parameters (registers):
;   SI = pointer to the text; left pointing at the terminating NUL on return
;   DI = byte offset in DS of the top-left of the first glyph (the offscreen
;        buffer starts at DS:0x337, 80 bytes per row, CGA 2 bits per pixel)
; Clobbers AX, BX, CX, DX, DI.
;
; Character mapping: index = char - 'a'. A character below 'a' is a space and
; advances DI by 2 bytes (8 pixels). The characters { | } ~ (0x7B-0x7E) are
; glyphs 26-29: period, comma, dash and hyphen.
;
; Tables, all indexed by glyph:
;   font_glyph_ptrs    (DS:0xB86A) words, bitmap offset from the table base
;   font_glyph_heights (DS:0xDB56) rows per column
;   font_glyph_widths  (DS:0xDB74) columns (each is 8 pixels wide)
;   DS:0xDB92          advance width in pixels
;
; Each bitmap byte is one row of 8 pixels, bit 0 leftmost. Bits are doubled to
; 2bpp (colour 3 or 0), shifted right by the sub-pixel position, then ORed into
; the buffer as two words, so a glyph can straddle a byte boundary.
;
; Globals (all bytes):
;   [0xdbb1] = sub-pixel position 0-3 inside a byte, carried between glyphs
;   [0xdbb2] = columns left in this glyph
;   [0xdbb4] = rows left in this column
; The NUL exit is a near jmp to the lone RET that follows the back-jump at the end of the glyph loop.
render_glyphs:
; Start at sub-pixel 0
	mov	byte [glyph_subpixel_pos],0x0	; 03E7C
; --- Next character ---
render_glyphs_next_char:
	mov	bl,[si]			; 03E81
	cmp	bl,0x0			; 03E83
	jnz	short render_glyphs_check_space		; 03E86 jnz 0x3e8b
	jmp	near render_glyphs_done			; 03E88
render_glyphs_check_space:
	sub	bl,0x61			; 03E8B
	jnl	short render_glyphs_lookup_glyph		; 03E8E jnl 0x3e96
	add	di,0x2			; 03E90
	inc	si			; 03E93
	jmp	short render_glyphs_next_char		; 03E94 jmp 0x3e81
; Look up the glyph: BX = bitmap, SI = glyph index, CH = width
render_glyphs_lookup_glyph:
	inc	si			; 03E96
	mov	bh,0x0			; 03E97
	push	si			; 03E99
	db	0x8B, 0xF3		; 03E9A mov si,bx
	shl	bx,1			; 03E9C
	mov	ax,[bx+font_glyph_offset_table]		; 03E9E
	lea	bx,[font_glyph_offset_table]		; 03EA2
	db	0x03, 0xD8		; 03EA6 add bx,ax
	mov	ch,[si+font_glyph_columns]		; 03EA8
	mov	[glyph_columns_left],ch		; 03EAC
; --- One column (8 pixels wide) ---
render_glyphs_column_loop:
	push	di			; 03EB0
	mov	cl,[si+font_glyph_rows]		; 03EB1
	mov	[glyph_rows_left],cl		; 03EB5
; --- One row: load a bitmap byte ---
render_glyphs_row_loop:
	mov	ah,[bx]			; 03EB9
	mov	ch,0x8			; 03EBB
; Double each bit into DX, so bit 7 ends in DX bits 1:0 and bit 0 in 15:14
render_glyphs_double_bits_loop:
	sar	ax,1			; 03EBD
	rcl	ax,1			; 03EBF
	rcr	dx,1			; 03EC1
	rcl	ax,1			; 03EC3
	rcr	dx,1			; 03EC5
	dec	ch			; 03EC7
	jnz	short render_glyphs_double_bits_loop		; 03EC9 jnz 0x3ebd
; Shift to the sub-pixel position, then OR 4 bytes in screen order
	db	0x33, 0xC0		; 03ECB xor ax,ax
	call	shift_glyph_pixels	; 03ECD
	xchg	dh,dl			; 03ED0
	xchg	ah,al			; 03ED2
	or	[di],dx			; 03ED4
	or	[di+0x2],ax		; 03ED6
	add	di,0x50			; 03ED9
	inc	bx			; 03EDC
	dec	byte [glyph_rows_left]		; 03EDD
	jnz	short render_glyphs_row_loop		; 03EE1 jnz 0x3eb9
	pop	di			; 03EE3
	add	di,0x2			; 03EE4
	dec	byte [glyph_columns_left]		; 03EE7
	jnz	short render_glyphs_column_loop		; 03EEB jnz 0x3eb0
; --- Advance DI: al = pixels advanced so far minus the glyph advance ---
	mov	ah,[glyph_subpixel_pos]		; 03EED
	add	ah,[si+font_glyph_advances]		; 03EF1
	mov	al,[si+font_glyph_columns]		; 03EF5
	shl	al,1			; 03EF9
	shl	al,1			; 03EFB
	shl	al,1			; 03EFD
	db	0x2A, 0xC4		; 03EFF sub al,ah
	cmp	al,0xfc			; 03F01
	jg	short render_glyphs_step_back_loop		; 03F03 jg 0x3f09
	inc	di			; 03F05
	jmp	short render_glyphs_carry_subpixel		; 03F06 jmp 0x3f10
	nop				; 03F08
; Step DI back one byte per 4 pixels of overshoot
render_glyphs_step_back_loop:
	sub	al,0x4			; 03F09
	jl	short render_glyphs_carry_subpixel		; 03F0B jl 0x3f10
	dec	di			; 03F0D
	jmp	short render_glyphs_step_back_loop		; 03F0E jmp 0x3f09
; Carry the new sub-pixel position to the next glyph
render_glyphs_carry_subpixel:
	mov	ah,[si+font_glyph_advances]		; 03F10
	add	[glyph_subpixel_pos],ah		; 03F14
	and	byte [glyph_subpixel_pos],0x3	; 03F18
	jz	short render_glyphs_glyph_done		; 03F1D jz 0x3f24
	cmp	al,0xfc			; 03F1F
	jl	short render_glyphs_glyph_done		; 03F21 jl 0x3f24
	dec	di			; 03F23
render_glyphs_glyph_done:
	pop	si			; 03F24
	jmp	near render_glyphs_next_char			; 03F25
; NUL terminator reached in the string
render_glyphs_done:
	ret				; 03F28

; ---- function shift_glyph_pixels ----
; Shifts DX:AX right by 2 * [0xdbb1] bits, moving glyph pixels to the current
; sub-pixel position (2 bits per pixel in CGA mode 4).
;
; Parameters (registers):
;   DX:AX = 32-bit pixel data, leftmost pixel in the high bits of DX
;
; Returns: DX:AX shifted. Does nothing if [0xdbb1] is 0.
; Clobbers CL when a shift happens.
shift_glyph_pixels:
	cmp	byte [glyph_subpixel_pos],0x0	; 03F29
	jz	short shift_glyph_pixels_done		; 03F2E jz 0x3f3e
	mov	cl,[glyph_subpixel_pos]		; 03F30
	shl	cl,1			; 03F34
shift_glyph_pixels_loop:
	shr	dx,1			; 03F36
	rcr	ax,1			; 03F38
	dec	cl			; 03F3A
	jnz	short shift_glyph_pixels_loop		; 03F3C jnz 0x3f36
shift_glyph_pixels_done:
	ret				; 03F3E

; ---- function show_scroll_text ----
; Plays the intro story: clears the screen, then scrolls the text up.
; No parameters. No stack frame. Called from game.asm.
;
; Reads:  [0xdbb5] = number of text lines (0x25 in the EXE)
;         DS:0xDBB6 = text, one NUL-terminated string per line
; Writes: [0xdbb3] = lines remaining, [0xddbe] = text cursor (both consumed
;         by scroll_text_up)
;
; scroll_text_up can return past this function on a keypress; that is harmless
; because nothing follows the call but RET.
show_scroll_text:
	call	clear_screen		; 03F3F
	call	update_display		; 03F42
%ifdef HEBREW
	jmp	near scroll_bitmap_run
	times 14 nop
%else
	mov	al,[intro_text_line_count]		; 03F45
	mov	[scroll_lines_left],al		; 03F48
	lea	ax,[intro_text]		; 03F4B
	mov	[scroll_text_ptr],ax		; 03F4F
	call	scroll_text_up		; 03F52
	ret				; 03F55
%endif

; ---- function show_the_end ----
; Shows the "the end" screen.
; No parameters. No stack frame.
;
; Renders the string at DS:0xDEB6 to buffer offset DS:0x20B6, shows it, and
; waits delay_with_input(0x48): 36 waits of 2 ticks (about 4 seconds), ending
; early on a keypress.
show_the_end:
	call	clear_screen		; 03F56
%ifdef HEBREW
; hend.bcg: the Hebrew end screen as a bitmap
	mov	ax,(offscreen_buffer + 90*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,outro_text+11
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 1 nop
%else
	call	update_display		; 03F59
	lea	di,[offscreen_the_end_text]		; 03F5C
	lea	si,[text_the_end]		; 03F60
	call	render_glyphs		; 03F64
%endif
	call	update_display		; 03F67
	mov	ax,0x48			; 03F6A
	call	delay_with_input	; 03F6D
	ret				; 03F70

; ---- function show_outro_text ----
; Shows the outro story text and plays a tune until the player responds.
; No parameters. No stack frame. Called from levels.asm 03685.
;
; Reads:  [0xddc0] = number of text lines (11 in the EXE; restored after use)
;         DS:0xDDC1 = text, one NUL-terminated string per line
;         [0xdf44] = input_advance (set to 1 by Ctrl+R in poll_keyboard)
;
; Lines are drawn 0x3C0 bytes (12 rows) apart starting at buffer offset
; DS:0x977. The wait loop plays sound 21 (a tune) each pass, so the music
; loops, and exits on input_advance or a pending key, which it then consumes.
show_outro_text:
	call	flush_keyboard		; 03F71
	call	clear_screen		; 03F74
	call	update_display		; 03F77
%ifdef HEBREW
; houtro.bcg: the Hebrew outro story as a bitmap
	mov	ax,(offscreen_buffer + 13*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,outro_text
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 19 nop
%else
	push	word [outro_text_line_count]		; 03F7A
	lea	si,[outro_text]		; 03F7E
	lea	di,[offscreen_outro_text]		; 03F82
show_outro_text_draw_line_loop:
	push	di			; 03F86
	call	render_glyphs		; 03F87
	pop	di			; 03F8A
	add	di,0x3c0		; 03F8B
	inc	si			; 03F8F
	dec	byte [outro_text_line_count]		; 03F90
	jnz	short show_outro_text_draw_line_loop		; 03F94 jnz 0x3f86
	pop	word [outro_text_line_count]		; 03F96
%endif
	call	update_display		; 03F9A
; Wait loop: tune, then input_advance and keyboard checks
show_outro_text_wait_loop:
	mov	ax,0x15			; 03F9D
	push	ax			; 03FA0
	call	play_sound		; 03FA1
	pop	ax			; 03FA4
	call	poll_keyboard		; 03FA5
	cmp	word [input_advance],0x0	; 03FA8
	jnz	short show_outro_text_done		; 03FAD jnz 0x3fb6
	cmp	al,0x0			; 03FAF
	jz	short show_outro_text_wait_loop		; 03FB1 jz 0x3f9d
	call	wait_for_key		; 03FB3
show_outro_text_done:
	ret				; 03FB6

; ---- function show_credit_mechner ----
; Shows the "a game by / jordan mechner" credit.
; No parameters. No stack frame. Called from game.asm.
;
; Line 1: DS:0xDEBE at buffer DS:0x1D92
; Line 2: DS:0xDEC8 at buffer DS:0x228B
; Then delay_with_input(0x48): about 4 seconds, ending early on a keypress.
show_credit_mechner:
	call	clear_screen		; 03FB7
%ifdef HEBREW
; The Hebrew credit is a bitmap loaded straight to line 78 of the framebuffer.
	mov	ax,(offscreen_buffer + 78*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,text_a_game_by	; holds "hmech.bcg" in this build
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 9 nop
%else
	lea	di,[offscreen_credit_mechner_line1]		; 03FBA
	lea	si,[text_a_game_by]		; 03FBE
	call	render_glyphs		; 03FC2
	lea	di,[offscreen_credit_mechner_line2]		; 03FC5
	lea	si,[text_jordan_mechner]		; 03FC9
	call	render_glyphs		; 03FCD
%endif
	call	update_display		; 03FD0
	mov	ax,0x48			; 03FD3
	call	delay_with_input	; 03FD6
	ret				; 03FD9

; ---- function show_credit_ibm ----
; Shows the "ibm version by / the connelley group" credit.
; No parameters. No stack frame. Called from game.asm.
;
; Line 1: DS:0xDED7 at buffer DS:0x1D8D
; Line 2: DS:0xDEE6 at buffer DS:0x2287
; Then delay_with_input(0x48): about 4 seconds, ending early on a keypress.
show_credit_ibm:
	call	clear_screen		; 03FDA
%ifdef HEBREW
; The Hebrew credit is a bitmap loaded straight to line 78 of the framebuffer.
	mov	ax,(offscreen_buffer + 78*80 - resource_buffer) & 0xFFFF
	push	ax
	mov	ax,text_ibm_version_by	; holds "hibm.bcg" in this build
	push	ax
	call	load_resource
	pop	cx
	pop	cx
	times 9 nop
%else
	lea	di,[offscreen_credit_ibm_line1]		; 03FDD
	lea	si,[text_ibm_version_by]		; 03FE1
	call	render_glyphs		; 03FE5
	lea	di,[offscreen_credit_ibm_line2]		; 03FE8
	lea	si,[text_connelley_group]		; 03FEC
	call	render_glyphs		; 03FF0
%endif
	call	update_display		; 03FF3
	mov	ax,0x48			; 03FF6
	call	delay_with_input	; 03FF9
	ret				; 03FFC

; ---- function check_disk_prompt ----
; Shows the three-line "make sure your karateka disk is in drive a. press any
; key to continue" prompt and blocks until a key is pressed.
; No parameters. No stack frame.
;
; Line 1: DS:0xDEFA at buffer DS:0x1B01
; Line 2: DS:0xDF12 at buffer DS:0x2009
; Line 3: DS:0xDF26 at buffer DS:0x24FF
check_disk_prompt:
	call	clear_screen		; 03FFD
	lea	di,[offscreen_disk_prompt_line1]		; 04000
	lea	si,[text_make_sure_disk]		; 04004
	call	render_glyphs		; 04008
	lea	di,[offscreen_disk_prompt_line2]		; 0400B
	lea	si,[text_disk_in_drive_a]		; 0400F
	call	render_glyphs		; 04013
	lea	di,[offscreen_disk_prompt_line3]		; 04016
	lea	si,[text_press_any_key]		; 0401A
	call	render_glyphs		; 0401E
	call	update_display		; 04021
	call	wait_for_key		; 04024
	ret				; 04027

; ---- function scroll_text_up ----
; Scrolls story text up the CGA screen one scanline at a time, feeding in new
; text at the bottom. Writes straight to VRAM, bypassing the double buffer.
; No parameters. Preserves ES. Clobbers AX, BX, CX, DX, SI, DI.
;
; Reads/writes:
;   [0xddbe] = pointer to the next text line (advanced past each NUL)
;   [0xdbb3] = lines remaining (byte, the outer loop counter)
; Reads:
;   DS:0xDF59 = table of 200 word VRAM offsets, one per scanline
;   [0xe0e7]  = last entry of that table (scanline 199)
;
; Each text line is rendered into the top of the offscreen area at DS:0x337
; after clearing 0x4B0 words of it, then fed in over 14 scanlines (0x460 bytes
; at 80 per row). For each scanline:
;   copy scanlines 1..199 up by one with DS = ES = 0xB800
;   copy one 80-byte row of rendered text into the bottom scanline
;   stop if poll_keyboard reports a key, else wait 1 timer tick
;
; Return paths: the normal path restores ES and returns to the caller. On a
; keypress it pops one extra word, so it discards its return address and
; returns directly to show_scroll_text's caller, with AX = the poll result.
scroll_text_up:
	push	es			; 04028
	mov	ax,0xb800		; 04029
	mov	es,ax			; 0402C
; --- New text line: clear the area and render it at DS:0x337 ---
scroll_text_up_new_text_line:
%ifdef HEBREW
; Read the next 14 rows of the story bitmap (file_read expects ES = DS).
	push	es
	push	ds
	pop	es
	mov	ax,0x460
	push	ax
	lea	ax,[offscreen_buffer]
	push	ax
	push	word [scroll_text_ptr]	; holds the file handle in this build
	call	file_read
	add	sp,0x6
	pop	es
	times 31-($-scroll_text_up_new_text_line) nop
%else
	mov	si,[scroll_text_ptr]		; 0402E
	lea	di,[offscreen_buffer]		; 04032
	db	0x33, 0xC0		; 04036 xor ax,ax
	mov	cx,0x4b0		; 04038
	push	es			; 0403B
	push	ds			; 0403C
	pop	es			; 0403D
	rep	stosw			; 0403E
	pop	es			; 04040
	lea	di,[offscreen_buffer]		; 04041
	call	render_glyphs		; 04045
	inc	si			; 04048
	mov	[scroll_text_ptr],si		; 04049
%endif
	db	0x33, 0xD2		; 0404D xor dx,dx
; --- Scroll one scanline up (BX = 2 * scanline index) ---
scroll_text_up_scroll_scanline:
	db	0x33, 0xDB		; 0404F xor bx,bx
scroll_text_up_copy_row_loop:
	mov	di,[bx+scanline_offsets]		; 04051
	mov	si,[bx+scanline_offsets_next]		; 04055
	mov	cx,0x28			; 04059
	push	ds			; 0405C
	push	es			; 0405D
	pop	ds			; 0405E
	rep	movsw			; 0405F
	pop	ds			; 04061
	add	bx,0x2			; 04062
	cmp	bx,0x18e		; 04065
	jc	short scroll_text_up_copy_row_loop		; 04069 jc 0x4051
; Copy this row of rendered text to the bottom scanline
	mov	di,[scanline_offset_bottom]		; 0406B
	lea	si,[offscreen_buffer]		; 0406F
	db	0x03, 0xF2		; 04073 add si,dx
	mov	cx,0x28			; 04075
	rep	movsw			; 04078
; 14 scanlines per text line
	add	dx,0x50			; 0407A
	cmp	dx,0x460		; 0407D
	jnl	short scroll_text_up_text_line_done		; 04081 jnl 0x4099
; A key ends the scroll
	push	dx			; 04083
	call	poll_keyboard		; 04084
	db	0x3D, 0x00, 0x00	; 04087 cmp ax,0x0
	jz	short scroll_text_up_wait_tick		; 0408A jz 0x4090
	pop	dx			; 0408C
	pop	es			; 0408D
%ifdef HEBREW
	nop				; keep the return address so the file gets closed
%else
	pop	bx			; 0408E
%endif
	ret				; 0408F
; Wait one tick between scanlines
scroll_text_up_wait_tick:
%ifdef HEBREW
	call	scroll_wait		; a little slower than the original
	times 3 nop
%else
	mov	ax,0x1			; 04090
	call	delay_ticks		; 04093
%endif
	pop	dx			; 04096
	jmp	short scroll_text_up_scroll_scanline		; 04097 jmp 0x404f
; Text line done: count down the remaining lines
scroll_text_up_text_line_done:
	dec	byte [scroll_lines_left]		; 04099
	jnz	short scroll_text_up_new_text_line		; 0409D jnz 0x402e
	pop	es			; 0409F
	ret				; 040A0

; ---- function anti_tamper_check ----
; Anti-tamper check, called from init_combat_level only when its [bp+8] argument
; is 2.
; No parameters. No stack frame. Clobbers AL, BX, SI.
;
; Sums bytes of the code in two regions, comparing the low byte each time:
;   1. CS:0x255..0x515 (0x2C1 bytes, game_init onward), expected AL = 0x5B
;   2. CS:0x169C..0x171C (0x81 bytes, disk code), expected AL = 0x19
; AL is not cleared before region 1. That region sums to 0x59 in the EXE, so
; the check needs AL = 2 on entry; what sets AL to 2 was not verified.
;
; Pass: returns with no other effect.
; Fail: zeroes 11 words starting at [0xc3d2] (player_frame_ptr and the 10 words
; after it), damaging the player's animation frame pointers.
anti_tamper_check:
%ifdef HEBREW
; The Hebrew patches change the code region this check sums, so skip the anti-tamper sum.
	ret
	times 3 nop
%else
	lea	si,[anti_tamper_region_1_start]		; 040A1
%endif
; Region 1 (AL carries in from the caller)
	mov	bx,0x2c0		; 040A5
anti_tamper_check_sum_region_1_loop:
	add	al,[cs:bx+si]		; 040A8
	dec	bx			; 040AB
	jnl	short anti_tamper_check_sum_region_1_loop		; 040AC jnl 0x40a8
	cmp	al,0x5b			; 040AE
	jnz	short anti_tamper_check_failed		; 040B0 jnz 0x40c6
; Region 2
	lea	si,[anti_tamper_region_2_start]		; 040B2
	mov	bx,0x80			; 040B6
	db	0x32, 0xC0		; 040B9 xor al,al
anti_tamper_check_sum_region_2_loop:
	add	al,[cs:bx+si]		; 040BB
	dec	bx			; 040BE
	jnl	short anti_tamper_check_sum_region_2_loop		; 040BF jnl 0x40bb
	cmp	al,0x19			; 040C1
	jnz	short anti_tamper_check_failed		; 040C3 jnz 0x40c6
	ret				; 040C5
; Checksum failed: damage the player frame pointers
anti_tamper_check_failed:
	mov	bx,0x14			; 040C6
anti_tamper_check_zero_frame_ptrs_loop:
	mov	word [bx+player_frame_ptr],0x0	; 040C9
	sub	bx,0x2			; 040CF
	jnl	short anti_tamper_check_zero_frame_ptrs_loop		; 040D2 jnl 0x40c9
	ret				; 040D4

; ---- function rand_next ----
; Advances the game's pseudo-random generator and returns the new value.
; No parameters on stack. No timer is involved: the seed is a plain word at
; [0xdf40], 1 in the EXE.
;
; Computes seed = ((seed * 0xE5D + 3) mod 0x10000) mod 0x8000. The high word
; of the product is ignored (DX is cleared before the divide) and the ADD does
; not carry into it.
;
; Local variables:
;   [bp+0x2] = seed copy, read and written through rand_seed_io
;
; Returns: AX = new seed, 0..0x7FFF. Clobbers BX, DX, SI.
rand_next:
	push	bp			; 040D5
	sub	sp,0x4			; 040D6
	db	0x8B, 0xEC		; 040D9 mov bp,sp
; Read the seed
	lea	ax,[bp+0x2]		; 040DB
	push	ax			; 040DE
	db	0x33, 0xC0		; 040DF xor ax,ax
	push	ax			; 040E1
	call	rand_seed_io		; 040E2
	db	0x8B, 0xE5		; 040E5 mov sp,bp
; Next state (the remainder of the divide ends up in DX)
	mov	ax,[bp+0x2]		; 040E7
	mov	bx,0xe5d		; 040EA
	mul	bx			; 040ED
	db	0x05, 0x03, 0x00	; 040EF add ax,0x3
	mov	bx,0x8000		; 040F2
	xor	dx,dx			; 040F5
	div	bx			; 040F7
; Store it back and return it
	lea	ax,[bp+0x2]		; 040F9
	push	ax			; 040FC
	mov	ax,0x1			; 040FD
	push	ax			; 04100
	mov	[bp+0x2],dx		; 04101
	call	rand_seed_io		; 04104
	db	0x8B, 0xE5		; 04107 mov sp,bp
	mov	ax,[bp+0x2]		; 04109
	add	sp,0x4			; 0410C
	pop	bp			; 0410F
	ret				; 04110
; ---- function set_rand_seed ----
; Writes the random seed. No callers in the code (function_names.py marks it
; dead code).
; Parameters (on stack): [bp+0x4] = new seed, written via rand_seed_io(1, &arg).
set_rand_seed:
	push	bp			; 04111
	db	0x8B, 0xEC		; 04112 mov bp,sp
	lea	ax,[bp+0x4]		; 04114
	push	ax			; 04117
	mov	ax,0x1			; 04118
	push	ax			; 0411B
	call	rand_seed_io		; 0411C
	db	0x8B, 0xE5		; 0411F mov sp,bp
	pop	bp			; 04121
	ret				; 04122

; ---- function rand_seed_io ----
; Reads or writes the random seed at [0xdf40].
;
; Parameters (on stack):
;   [bp+0x6] = direction (low byte): 0 = copy seed to *ptr, else copy *ptr to seed
;   [bp+0x8] = pointer to a word
;
; Clobbers AX, SI.
rand_seed_io:
	push	bp			; 04123
	sub	sp,0x2			; 04124
	db	0x8B, 0xEC		; 04127 mov bp,sp
	mov	al,[bp+0x6]		; 04129
	xor	ah,ah			; 0412C
	test	ax,ax			; 0412E
	jnz	short rand_seed_io_write_seed		; 04130 jnz 0x413c
	mov	ax,[random_seed]		; 04132
	mov	si,[bp+0x8]		; 04135
	mov	[si],ax			; 04138
	jmp	short rand_seed_io_return		; 0413A jmp 0x4144
rand_seed_io_write_seed:
	mov	si,[bp+0x8]		; 0413C
	mov	ax,[si]			; 0413F
	mov	[random_seed],ax		; 04141
rand_seed_io_return:
	add	sp,0x2			; 04144
	pop	bp			; 04147
	ret				; 04148
