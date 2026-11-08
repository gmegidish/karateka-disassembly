; Screen setup, timer/delay functions
;
; This module contains the animation script bytecode interpreter, its opcode
; handlers, timer/delay routines for frame pacing, a "music callback" that
; saves/restores scene state while playing a cutscene, and the animation
; frame offset table builder.
;
; Animation script bytecodes are stored in a buffer at DS:0xBD04.  The
; interpreter (run_anim_script) reads one opcode byte at a time, indexes
; into a 14-entry jump table at [0xBCE8], and dispatches to the matching
; handler.  Opcode 0xFF terminates the script.
;
; Opcodes (even numbers 0x00-0x16):
;   0x00 set_tune   - set tune/sprite command byte
;   0x02 set_bg     - set background figure index
;   0x04 set_fig    - add figure to scene animation list
;   0x06 chg_fig    - change existing figure slot position
;   0x08 do_scr     - render current frame to screen
;   0x0A del_fig    - delete figure from scene animation list
;   0x0C set_wipe   - enable wipe mode
;   0x0E set_nowipe - disable wipe mode
;   0x10 wait       - delay for N timer ticks
;   0x12 init_sal   - reset scene animation list
;   0x14 set_pos    - set relative position mode
;   0x16 inc_x      - increment player X by signed offset


; ---- function run_anim_script ----
; Animation script bytecode interpreter.
; Reads opcodes from buffer at [script_pc + 0xBD04] (the address
; [si - 0x42FC] wraps to [si + 0xBD04] in 16-bit unsigned math).
; Sets script_running=1, resets script_pc and relative_pos_mode,
; then loops: read opcode, dispatch via jump table, repeat.
; Opcode 0xFF terminates the script.  Returns 0 on normal completion.
; In single-step mode (anim_mode != 0), polls keyboard after each
; command and exits early on keypress.
run_anim_script:
	mov	byte [script_running],0x1	; 01734  script_running = 1
	call	anim_cmd_init_sal	; 01739  reset scene animation list
	mov	word [script_pc],0x0	; 0173C  script_pc = 0
	mov	byte [anim_rel_pos_mode],0x0	; 01742  relative_pos_mode = 0
run_anim_script_next_opcode:
	mov	si,[script_pc]		; 01747  si = script_pc
	mov	bl,[si+anim_script_bytecode]		; 0174B  bl = opcode byte at [si + 0xBD04]
	cmp	bl,0xff			; 0174F  end-of-script marker?
	jz	short run_anim_script_finished		; 01752 jz 0x177d
	mov	bh,0x0			; 01754  zero-extend opcode to word
	push	word [script_pc]		; 01756  save script_pc on stack
	call	word near [bx+anim_jump_table]	; 0175A  dispatch via jump table at [bx + 0xBCE8]
	cmp	word [anim_mode],0x0	; 0175E  single_step_mode?
	jz	short run_anim_script_continue		; 01763 jz 0x177a
	call	poll_keyboard		; 01765  check for keypress
	db	0x3D, 0x00, 0x00	; 01768 cmp ax,0x0
	jz	short run_anim_script_continue		; 0176B jz 0x177a  no key pressed, continue
	call	wait_for_key		; 0176D  wait for key release
	pop	word [script_pc]		; 01770  restore script_pc
	mov	byte [script_running],0x0	; 01774  script_running = 0
	ret				; 01779  early exit on keypress
run_anim_script_continue:
	pop	ax			; 0177A  discard saved script_pc
	jmp	short run_anim_script_next_opcode		; 0177B jmp 0x1747  loop to next opcode

run_anim_script_finished:
; --- script complete ---
	mov	ax,0x0			; 0177D  return 0 (success)
	mov	byte [script_running],0x0	; 01780  script_running = 0
	ret				; 01785

; --- anim handler: set_tune (opcode 0x00) ---
; Reads 1-byte param, stores to player_sprite_cmd [0xBB30].
; Advances script_pc by 2 (opcode + 1 param byte).
	mov	al,[si+anim_script_arg1]		; 01786  al = param byte at [script_pc + 1 + 0xBD04]
	mov	[player_sprite_cmd],al		; 0178A  player_sprite_cmd = param
	add	word [script_pc],0x2	; 0178D  script_pc += 2
	ret				; 01792

; --- anim handler: set_bg (opcode 0x02) ---
; Reads 1-byte param, stores to anim_fig_bg [0xBB32].
; Advances script_pc by 2.
	mov	al,[si+anim_script_arg1]		; 01793  al = background index
	mov	[anim_fig_bg],al		; 01797  anim_fig_bg = param
	add	word [script_pc],0x2	; 0179A  script_pc += 2
	ret				; 0179F

; --- anim handler: set_fig (opcode 0x04) ---
; Adds a new figure entry to the scene animation list.
; Reads 4 param bytes: [si+1]=figure_id, [si+2..3]=x_pos, [si+4]=y_pos.
; If relative_pos_mode > 0, adds player_x to x_pos.
; Writes 4-byte entry to list at [0xBB2E] offset, then advances pointer.
; Advances script_pc by 5.
	mov	di,[player_anim_end]		; 017A0  di = write pointer into figure list
	mov	al,[si+anim_script_arg1]		; 017A4  al = figure_id
	mov	[di+player_sprite_cmd],al		; 017A8  write figure_id to list (0xBB30 base)
	mov	ax,[si+anim_script_arg2]		; 017AC  ax = x_pos (word at param bytes 2-3)
	cmp	byte [anim_rel_pos_mode],0x0	; 017B0  relative_pos_mode active?
	jz	short run_anim_script_set_fig_store_x		; 017B5 jz 0x17bf  no, use absolute position
	dec	byte [anim_rel_pos_mode]		; 017B7  decrement relative_pos_mode counter
	add	ax,[player_x]		; 017BB  add player_x for relative positioning
run_anim_script_set_fig_store_x:
	mov	[di+player_anim_ctr],ax		; 017BF  write x_pos to list
	mov	al,[si+anim_script_arg4]		; 017C3  al = y_pos (param byte 4)
	mov	[di+player_anim_buf],al		; 017C7  write y_pos to list
	mov	byte [di+figure_list_x],0xff	; 017CB  write 0xFF terminator after entry
	add	word [player_anim_end],0x4	; 017D0  advance write pointer by 4
	add	word [script_pc],0x5	; 017D5  script_pc += 5
	ret				; 017DA

; --- anim handler: chg_fig (opcode 0x06) ---
; Changes position data of an existing figure slot.
; Reads slot index from [si+1], then 2 words of position data.
; Slot address = base + slot_index * 4.
; Advances script_pc by 6.
	mov	bl,[si+anim_script_arg1]		; 017DB  bl = slot index
	mov	bh,0x0			; 017DF
	shl	bx,1			; 017E1  bx = slot_index * 2
	shl	bx,1			; 017E3  bx = slot_index * 4
	mov	ax,[si+anim_script_arg2]		; 017E5  ax = new x_pos
	mov	[bx+player_anim_buf],ax		; 017E9  write x_pos to figure slot
	mov	ax,[si+anim_script_arg4]		; 017ED  ax = new y_pos/flags
	mov	[bx+figure_list_x_hi],ax		; 017F1  write y_pos/flags to figure slot
	add	word [script_pc],0x6	; 017F5  script_pc += 6
	ret				; 017FA

; ---- function anim_cmd_do_scr ----
; Animation command: render current frame (opcode 0x08).
; Calls render_figures to draw all active figures.
; In single_step_mode, waits for keypress after each frame.
; Advances script_pc by 1.
anim_cmd_do_scr:
	call	render_figures		; 017FB  draw all figures
	inc	word [script_pc]		; 017FE  script_pc += 1
	cmp	word [single_step_mode],0x1	; 01802  single_step_mode?
	jnz	short anim_cmd_do_scr_done		; 01807 jnz 0x180c
	call	wait_for_key		; 01809  pause until key pressed
anim_cmd_do_scr_done:
	ret				; 0180C

; --- anim handler: del_fig (opcode 0x0A) ---
; Deletes a figure from the scene animation list by shifting
; subsequent 4-byte entries down.  Writes 0xFF terminator at end.
; Reads slot index from [si+1].
; Advances script_pc by 2.
	mov	bl,[si+0x1]		; 0180D  bl = slot index to delete
	mov	bh,0x0			; 01810
	shl	bx,1			; 01812  bx = slot * 2
	shl	bx,1			; 01814  bx = slot * 4
	add	bx,0x3			; 01816  bx = slot * 4 + 3 (offset into list)
	sub	word [player_anim_end],0x4	; 01819  shrink list by one entry
anim_cmd_do_scr_del_fig_shift_loop:
	mov	ax,[bx+figure_list_x]		; 0181E  copy next entry down
	mov	[bx+player_sprite_cmd],ax		; 01822
	mov	ax,[bx+figure_list_y]		; 01826
	mov	[bx+anim_fig_bg],ax		; 0182A
	add	bx,0x4			; 0182E  advance to next slot
	cmp	bx,[player_anim_end]		; 01831  past end of list?
	jl	short anim_cmd_do_scr_del_fig_shift_loop		; 01835 jl 0x181e  keep shifting
	mov	byte [bx+player_sprite_cmd],0xff	; 01837  write terminator
	add	word [script_pc],0x2	; 0183C  script_pc += 2
	ret				; 01841

; --- anim handler: set_wipe (opcode 0x0C) ---
; Enables wipe mode (player_anim_ctr = 1).
; Advances script_pc by 1.
	mov	byte [player_anim_ctr],0x1	; 01842  enable wipe
	inc	word [script_pc]		; 01847  script_pc += 1
	ret				; 0184B

; --- anim handler: set_nowipe (opcode 0x0E) ---
; Disables wipe mode (player_anim_ctr = 0).
; Advances script_pc by 1.
	mov	byte [player_anim_ctr],0x0	; 0184C  disable wipe
	inc	word [script_pc]		; 01851  script_pc += 1
	ret				; 01855

; --- anim handler: wait (opcode 0x10) ---
; If NOT in single_step_mode, delays for param timer ticks.
; Advances script_pc by 2.
	cmp	word [single_step_mode],0x0	; 01856  single_step_mode?
	jnz	short anim_cmd_do_scr_wait_advance_pc		; 0185B jnz 0x1866  skip delay in step mode
	mov	al,[si+anim_script_arg1]		; 0185D  al = tick count param
	mov	ah,0x0			; 01861
	call	delay_ticks		; 01863  wait for AX ticks (~55ms each)
anim_cmd_do_scr_wait_advance_pc:
	add	word [script_pc],0x2	; 01866  script_pc += 2
	ret				; 0186B

; ---- function anim_cmd_init_sal ----
; Animation command: reset scene animation list (opcode 0x12).
; Clears all figure slots, resets render state:
;   [0xBB2A] = 0xFFFF (no active animation)
;   anim_render_mode = 1 (normal)
;   player_sprite_cmd = 0, player_anim_ctr = 0
;   first figure entry = 0xFF (empty list)
;   player_anim_end = 3 (write pointer past 3-byte header)
; Advances script_pc by 1.
anim_cmd_init_sal:
	mov	word [anim_state_bb2a],0xffff	; 0186C  anim_state = no animation
	mov	word [anim_render_mode],0x1		; 01872  anim_render_mode = normal
	mov	byte [player_sprite_cmd],0x0	; 01878  player_sprite_cmd = 0
	mov	word [player_anim_ctr],0x0	; 0187D  player_anim_ctr = 0
	mov	byte [player_anim_buf],0xff	; 01883  first list entry = terminator (empty)
	mov	word [player_anim_end],0x3	; 01888  write pointer = 3 (past header)
	inc	word [script_pc]		; 0188E  script_pc += 1
	ret				; 01892

; --- anim handler: set_pos (opcode 0x14) ---
; Sets relative position mode.  In single_step_mode, renders current
; frame and reinitializes the list first (adjusts PC by -2 to compensate).
; Sets anim_rel_pos_mode = 2 (next two set_fig calls use relative coords).
; Advances script_pc by 3.
	cmp	word [single_step_mode],0x1	; 01893  single_step_mode?
	jnz	short anim_cmd_init_sal_set_pos_enable_relative		; 01898 jnz 0x18a5
	call	anim_cmd_do_scr		; 0189A  render frame
	call	anim_cmd_init_sal	; 0189D  reset list
	sub	word [script_pc],0x2	; 018A0  undo the +1 from each call above
anim_cmd_init_sal_set_pos_enable_relative:
	mov	byte [anim_rel_pos_mode],0x2	; 018A5  relative_pos_mode = 2
	add	word [script_pc],0x3	; 018AA  script_pc += 3
	ret				; 018AF

; --- anim handler: inc_x (opcode 0x16) ---
; Adds signed byte param to player_x [0xBCD5].
; Advances script_pc by 2.
	mov	al,[si+anim_script_arg1]		; 018B0  al = signed offset byte
	cbw				; 018B4  sign-extend to AX
	add	[player_x],ax		; 018B5  player_x += offset
	add	word [script_pc],0x2	; 018B9  script_pc += 2
	ret				; 018BE

; ---- function delay_ticks ----
; Busy-waits for AX timer ticks (~55ms each) using BIOS INT 1Ah.
; Reads current tick count, adds AX to get target, then polls
; until DX (current tick low word) matches the target.
; Input: AX = number of ticks to wait.
delay_ticks:
	mov	[delay_tick_target],ax		; 018BF  delay_tick_target = ticks_to_wait
	mov	ah,0x0			; 018C2
	int	0x1a			; 018C4  INT 1Ah/00h: get timer tick count -> CX:DX
	add	[delay_tick_target],dx		; 018C6  delay_tick_target = current_tick + ticks_to_wait
delay_ticks_poll_loop:
	mov	ah,0x0			; 018CA
	int	0x1a			; 018CC  get current tick count
	cmp	dx,[delay_tick_target]		; 018CE  reached target?
	jnz	short delay_ticks_poll_loop		; 018D2 jnz 0x18ca  keep polling
	ret				; 018D4

; ---- function delay_with_input ----
; Interruptible delay: waits AX/2 iterations of 2-tick delays.
; Breaks early on keypress.  Used for delays that should respond
; to user input (e.g., cutscene skipping).
; Input: AX = total delay (divided by 2 for iteration count).
delay_with_input:
	shr	ax,1			; 018D5  iteration_count = delay / 2
	mov	[delay_iter_count],ax		; 018D7  delay_iter_count = iteration_count
delay_with_input_loop:
	mov	ax,0x2			; 018DA  2 ticks per iteration (~110ms)
	call	delay_ticks		; 018DD
	call	poll_keyboard		; 018E0  check for keypress
	db	0x3D, 0x00, 0x00	; 018E3 cmp ax,0x0
	jnz	short delay_with_input_done		; 018E6 jnz 0x18ee  key pressed, exit early
	dec	word [delay_iter_count]		; 018E8  --delay_iter_count
	jnz	short delay_with_input_loop		; 018EC jnz 0x18da  loop
delay_with_input_done:
	ret				; 018EE

; ---- function timer_mark ----
; Records current BIOS timer tick at timer_mark_tick [0xBCD1]
; for frame pacing.  Called before frame work, paired with
; timer_wait_3ticks after frame work to maintain ~6 FPS.
timer_mark:
	mov	ah,0x0			; 018EF
	int	0x1a			; 018F1  INT 1Ah/00h: get tick count -> CX:DX
	mov	[timer_mark_tick],dx		; 018F3  timer_mark_tick = current tick
	ret				; 018F7

; ---- function timer_wait_3ticks ----
; Waits until 3 ticks (~165ms, ~6 FPS) have elapsed since the
; last timer_mark call.  Polls INT 1Ah in a tight loop, then
; updates timer_mark_tick with the current tick for the next frame.
timer_wait_3ticks:
timer_wait_3ticks_poll_loop:
	mov	ah,0x0			; 018F8
	int	0x1a			; 018FA  get current tick count
	db	0x8B, 0xC2		; 018FC mov ax,dx  save current tick in AX
	sub	dx,[timer_mark_tick]		; 018FE  delta = current - timer_mark_tick
	cmp	dx,0x3			; 01902  3 ticks elapsed?
	jc	short timer_wait_3ticks_poll_loop		; 01905 jc 0x18f8  not yet, keep polling
	mov	[timer_mark_tick],ax		; 01907  update timer_mark_tick for next frame
	ret				; 0190A

; ---- function play_music_sequence ----
; Saves the current scene state (level, camera_x, return address, BP),
; loads and plays an animation script with accompanying animation data,
; then restores the scene state.  Used for music/cutscene interludes.
;
; Input (stack):
;   [bp+4] = animation script filename
;   [bp+6] = animation data filename
;
; The return address is saved from [bp+2] and restored afterward,
; effectively redirecting the caller's return.
play_music_sequence:
	push	bp			; 0190B
	db	0x8B, 0xEC		; 0190C mov bp,sp
	mov	ax,[bp+0x2]		; 0190E  save caller's return address
	mov	[saved_return_addr],ax		; 01911  saved_return_addr
	mov	ax,[current_level]		; 01914  save current_level
	mov	[saved_level],ax		; 01917  saved_level
	mov	ax,[camera_x]		; 0191A  save camera_x
	mov	[saved_camera_x],ax		; 0191D  saved_camera_x
	lea	ax,[anim_script_bytecode]		; 01920  ax = animation script buffer address
	mov	[saved_bp],bp		; 01924  saved_bp
	push	ax			; 01928  arg: destination buffer
	push	word [bp+0x4]		; 01929  arg: script filename
	call	load_anim_script	; 0192C  load and compile script to bytecode
	add	sp,0x4			; 0192F
	mov	bp,[saved_bp]		; 01932  restore BP
	push	word [bp+0x6]		; 01936  arg: animation data filename
	call	load_sprite_set		; 01939  load animation frame data
	add	sp,0x2			; 0193C
	mov	bp,[saved_bp]		; 0193F  restore BP again
	mov	word [camera_x],0x0		; 01943  camera_x = 0
	call	clear_screen		; 01949
	mov	word [anim_render_mode],0x1		; 0194C  anim_render_mode = normal
	mov	word [current_level],0x4		; 01952  current_level = 4 (cutscene mode)
	call	run_anim_script		; 01958  play the animation sequence
	mov	word [wipe_prev_left],0xffff	; 0195B  wipe_prev_left = -1 (force redraw)
	mov	ax,[saved_level]		; 01961  restore current_level
	mov	[current_level],ax		; 01964
	mov	ax,[saved_camera_x]		; 01967  restore camera_x
	mov	[camera_x],ax		; 0196A
	mov	bx,[saved_return_addr]		; 0196D  restore caller's return address
	mov	[bp+0x2],bx		; 01971  redirect return to saved address
	pop	bp			; 01974
	ret				; 01975

; ---- function build_anim_offsets_alt ----
; Sets up base/table pointers for secondary animation data,
; then falls through to build_anim_offsets.
; Base = 0xC428 (secondary animation frame data).
; Table = 0xC3D4 (secondary offset table destination).
build_anim_offsets_alt:
	lea	bx,[player_anim_frames]		; 01976  bx = secondary animation data base
	lea	di,[player_frame_bak]		; 0197A  di = secondary offset table

; ---- function build_anim_offsets ----
; Scans animation frame data to build a table of 42 word offsets,
; each pointing to the start of an animation sequence.
; Records are 0x11 bytes each; loop markers (0x18) have 2-byte skip;
; sequences are terminated by 0xFF.
; Input: BX = data base address, DI = offset table destination.
build_anim_offsets:
	mov	si,0x0			; 0197E  si = current offset into data
	mov	cl,0x2a			; 01981  cl = 42 sequences to scan
build_anim_offsets_next_sequence:
	mov	[di],si			; 01983  store offset for this sequence
	add	di,0x2			; 01985  advance table pointer

build_anim_offsets_scan_records:
	cmp	byte [bx+si],0xff	; 01988  end-of-sequence marker?
	jz	short build_anim_offsets_sequence_end		; 0198B jz 0x199c  yes, next sequence
	cmp	byte [bx+si],0x18	; 0198D  loop marker?
	jnz	short build_anim_offsets_skip_record		; 01990 jnz 0x1997
	add	si,0x2			; 01992  loop marker = 2-byte skip
	jmp	short build_anim_offsets_scan_records		; 01995 jmp 0x1988

build_anim_offsets_skip_record:
	add	si,0x11			; 01997  normal record = 0x11 bytes
	jmp	short build_anim_offsets_scan_records		; 0199A jmp 0x1988

build_anim_offsets_sequence_end:
	inc	si			; 0199C  skip past 0xFF terminator
	dec	cl			; 0199D
	jnz	short build_anim_offsets_next_sequence		; 0199F jnz 0x1983  loop for all 42 sequences
	ret				; 019A1
