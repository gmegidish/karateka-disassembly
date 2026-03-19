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
mov byte [0xbcd0],0x1  ; 01734  script_running = 1
call anim_cmd_init_sal  ; 01739  reset scene animation list
mov word [0xbce6],0x0  ; 0173C  script_pc = 0
mov byte [0xbcd7],0x0  ; 01742  relative_pos_mode = 0
loc_01747:
mov si,[0xbce6]  ; 01747  si = script_pc
mov bl,[si-0x42fc]  ; 0174B  bl = opcode byte at [si + 0xBD04]
cmp bl,0xff  ; 0174F  end-of-script marker?
jz short loc_0177D  ; 01752 jz 0x177d
mov bh,0x0  ; 01754  zero-extend opcode to word
push word [0xbce6]  ; 01756  save script_pc on stack
call word near [bx-0x4318]  ; 0175A  dispatch via jump table at [bx + 0xBCE8]
cmp word [0x156],0x0  ; 0175E  single_step_mode?
jz short loc_0177A  ; 01763 jz 0x177a
call poll_keyboard  ; 01765  check for keypress
db 0x3D, 0x00, 0x00  ; 01768 cmp ax,0x0
jz short loc_0177A  ; 0176B jz 0x177a  no key pressed, continue
call wait_for_key  ; 0176D  wait for key release
pop word [0xbce6]  ; 01770  restore script_pc
mov byte [0xbcd0],0x0  ; 01774  script_running = 0
ret  ; 01779  early exit on keypress
loc_0177A:
pop ax  ; 0177A  discard saved script_pc
jmp short loc_01747  ; 0177B jmp 0x1747  loop to next opcode

loc_0177D:
; --- script complete ---
mov ax,0x0  ; 0177D  return 0 (success)
mov byte [0xbcd0],0x0  ; 01780  script_running = 0
ret  ; 01785

; --- anim handler: set_tune (opcode 0x00) ---
; Reads 1-byte param, stores to player_sprite_cmd [0xBB30].
; Advances script_pc by 2 (opcode + 1 param byte).
mov al,[si-0x42fb]  ; 01786  al = param byte at [script_pc + 1 + 0xBD04]
mov [0xbb30],al  ; 0178A  player_sprite_cmd = param
add word [0xbce6],0x2  ; 0178D  script_pc += 2
ret  ; 01792

; --- anim handler: set_bg (opcode 0x02) ---
; Reads 1-byte param, stores to anim_fig_bg [0xBB32].
; Advances script_pc by 2.
mov al,[si-0x42fb]  ; 01793  al = background index
mov [0xbb32],al  ; 01797  anim_fig_bg = param
add word [0xbce6],0x2  ; 0179A  script_pc += 2
ret  ; 0179F

; --- anim handler: set_fig (opcode 0x04) ---
; Adds a new figure entry to the scene animation list.
; Reads 4 param bytes: [si+1]=figure_id, [si+2..3]=x_pos, [si+4]=y_pos.
; If relative_pos_mode > 0, adds player_x to x_pos.
; Writes 4-byte entry to list at [0xBB2E] offset, then advances pointer.
; Advances script_pc by 5.
mov di,[0xbb2e]  ; 017A0  di = write pointer into figure list
mov al,[si-0x42fb]  ; 017A4  al = figure_id
mov [di-0x44d0],al  ; 017A8  write figure_id to list (0xBB30 base)
mov ax,[si-0x42fa]  ; 017AC  ax = x_pos (word at param bytes 2-3)
cmp byte [0xbcd7],0x0  ; 017B0  relative_pos_mode active?
jz short loc_017BF  ; 017B5 jz 0x17bf  no, use absolute position
dec byte [0xbcd7]  ; 017B7  decrement relative_pos_mode counter
add ax,[0xbcd5]  ; 017BB  add player_x for relative positioning
loc_017BF:
mov [di-0x44cf],ax  ; 017BF  write x_pos to list
mov al,[si-0x42f8]  ; 017C3  al = y_pos (param byte 4)
mov [di-0x44cd],al  ; 017C7  write y_pos to list
mov byte [di-0x44cc],0xff  ; 017CB  write 0xFF terminator after entry
add word [0xbb2e],0x4  ; 017D0  advance write pointer by 4
add word [0xbce6],0x5  ; 017D5  script_pc += 5
ret  ; 017DA

; --- anim handler: chg_fig (opcode 0x06) ---
; Changes position data of an existing figure slot.
; Reads slot index from [si+1], then 2 words of position data.
; Slot address = base + slot_index * 4.
; Advances script_pc by 6.
mov bl,[si-0x42fb]  ; 017DB  bl = slot index
mov bh,0x0  ; 017DF
shl bx,1  ; 017E1  bx = slot_index * 2
shl bx,1  ; 017E3  bx = slot_index * 4
mov ax,[si-0x42fa]  ; 017E5  ax = new x_pos
mov [bx-0x44cd],ax  ; 017E9  write x_pos to figure slot
mov ax,[si-0x42f8]  ; 017ED  ax = new y_pos/flags
mov [bx-0x44cb],ax  ; 017F1  write y_pos/flags to figure slot
add word [0xbce6],0x6  ; 017F5  script_pc += 6
ret  ; 017FA

; ---- function anim_cmd_do_scr ----
; Animation command: render current frame (opcode 0x08).
; Calls render_figures to draw all active figures.
; In single_step_mode, waits for keypress after each frame.
; Advances script_pc by 1.
anim_cmd_do_scr:
call render_figures  ; 017FB  draw all figures
inc word [0xbce6]  ; 017FE  script_pc += 1
cmp word [0xbcd8],0x1  ; 01802  single_step_mode?
jnz short loc_0180C  ; 01807 jnz 0x180c
call wait_for_key  ; 01809  pause until key pressed
loc_0180C:
ret  ; 0180C

; --- anim handler: del_fig (opcode 0x0A) ---
; Deletes a figure from the scene animation list by shifting
; subsequent 4-byte entries down.  Writes 0xFF terminator at end.
; Reads slot index from [si+1].
; Advances script_pc by 2.
mov bl,[si+0x1]  ; 0180D  bl = slot index to delete
mov bh,0x0  ; 01810
shl bx,1  ; 01812  bx = slot * 2
shl bx,1  ; 01814  bx = slot * 4
add bx,0x3  ; 01816  bx = slot * 4 + 3 (offset into list)
sub word [0xbb2e],0x4  ; 01819  shrink list by one entry
loc_0181E:
mov ax,[bx-0x44cc]  ; 0181E  copy next entry down
mov [bx-0x44d0],ax  ; 01822
mov ax,[bx-0x44ca]  ; 01826
mov [bx-0x44ce],ax  ; 0182A
add bx,0x4  ; 0182E  advance to next slot
cmp bx,[0xbb2e]  ; 01831  past end of list?
jl short loc_0181E  ; 01835 jl 0x181e  keep shifting
mov byte [bx-0x44d0],0xff  ; 01837  write terminator
add word [0xbce6],0x2  ; 0183C  script_pc += 2
ret  ; 01841

; --- anim handler: set_wipe (opcode 0x0C) ---
; Enables wipe mode (player_anim_ctr = 1).
; Advances script_pc by 1.
mov byte [0xbb31],0x1  ; 01842  enable wipe
inc word [0xbce6]  ; 01847  script_pc += 1
ret  ; 0184B

; --- anim handler: set_nowipe (opcode 0x0E) ---
; Disables wipe mode (player_anim_ctr = 0).
; Advances script_pc by 1.
mov byte [0xbb31],0x0  ; 0184C  disable wipe
inc word [0xbce6]  ; 01851  script_pc += 1
ret  ; 01855

; --- anim handler: wait (opcode 0x10) ---
; If NOT in single_step_mode, delays for param timer ticks.
; Advances script_pc by 2.
cmp word [0xbcd8],0x0  ; 01856  single_step_mode?
jnz short loc_01866  ; 0185B jnz 0x1866  skip delay in step mode
mov al,[si-0x42fb]  ; 0185D  al = tick count param
mov ah,0x0  ; 01861
call delay_ticks  ; 01863  wait for AX ticks (~55ms each)
loc_01866:
add word [0xbce6],0x2  ; 01866  script_pc += 2
ret  ; 0186B

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
mov word [0xbb2a],0xffff  ; 0186C  anim_state = no animation
mov word [0xee],0x1  ; 01872  anim_render_mode = normal
mov byte [0xbb30],0x0  ; 01878  player_sprite_cmd = 0
mov word [0xbb31],0x0  ; 0187D  player_anim_ctr = 0
mov byte [0xbb33],0xff  ; 01883  first list entry = terminator (empty)
mov word [0xbb2e],0x3  ; 01888  write pointer = 3 (past header)
inc word [0xbce6]  ; 0188E  script_pc += 1
ret  ; 01892

; --- anim handler: set_pos (opcode 0x14) ---
; Sets relative position mode.  In single_step_mode, renders current
; frame and reinitializes the list first (adjusts PC by -2 to compensate).
; Sets anim_rel_pos_mode = 2 (next two set_fig calls use relative coords).
; Advances script_pc by 3.
cmp word [0xbcd8],0x1  ; 01893  single_step_mode?
jnz short loc_018A5  ; 01898 jnz 0x18a5
call anim_cmd_do_scr  ; 0189A  render frame
call anim_cmd_init_sal  ; 0189D  reset list
sub word [0xbce6],0x2  ; 018A0  undo the +1 from each call above
loc_018A5:
mov byte [0xbcd7],0x2  ; 018A5  relative_pos_mode = 2
add word [0xbce6],0x3  ; 018AA  script_pc += 3
ret  ; 018AF

; --- anim handler: inc_x (opcode 0x16) ---
; Adds signed byte param to player_x [0xBCD5].
; Advances script_pc by 2.
mov al,[si-0x42fb]  ; 018B0  al = signed offset byte
cbw  ; 018B4  sign-extend to AX
add [0xbcd5],ax  ; 018B5  player_x += offset
add word [0xbce6],0x2  ; 018B9  script_pc += 2
ret  ; 018BE

; ---- function delay_ticks ----
; Busy-waits for AX timer ticks (~55ms each) using BIOS INT 1Ah.
; Reads current tick count, adds AX to get target, then polls
; until DX (current tick low word) matches the target.
; Input: AX = number of ticks to wait.
delay_ticks:
mov [0xbce2],ax  ; 018BF  delay_tick_target = ticks_to_wait
mov ah,0x0  ; 018C2
int 0x1a  ; 018C4  INT 1Ah/00h: get timer tick count -> CX:DX
add [0xbce2],dx  ; 018C6  delay_tick_target = current_tick + ticks_to_wait
loc_018CA:
mov ah,0x0  ; 018CA
int 0x1a  ; 018CC  get current tick count
cmp dx,[0xbce2]  ; 018CE  reached target?
jnz short loc_018CA  ; 018D2 jnz 0x18ca  keep polling
ret  ; 018D4

; ---- function delay_with_input ----
; Interruptible delay: waits AX/2 iterations of 2-tick delays.
; Breaks early on keypress.  Used for delays that should respond
; to user input (e.g., cutscene skipping).
; Input: AX = total delay (divided by 2 for iteration count).
delay_with_input:
shr ax,1  ; 018D5  iteration_count = delay / 2
mov [0xbce4],ax  ; 018D7  delay_iter_count = iteration_count
loc_018DA:
mov ax,0x2  ; 018DA  2 ticks per iteration (~110ms)
call delay_ticks  ; 018DD
call poll_keyboard  ; 018E0  check for keypress
db 0x3D, 0x00, 0x00  ; 018E3 cmp ax,0x0
jnz short loc_018EE  ; 018E6 jnz 0x18ee  key pressed, exit early
dec word [0xbce4]  ; 018E8  --delay_iter_count
jnz short loc_018DA  ; 018EC jnz 0x18da  loop
loc_018EE:
ret  ; 018EE

; ---- function timer_mark ----
; Records current BIOS timer tick at timer_mark_tick [0xBCD1]
; for frame pacing.  Called before frame work, paired with
; timer_wait_3ticks after frame work to maintain ~6 FPS.
timer_mark:
mov ah,0x0  ; 018EF
int 0x1a  ; 018F1  INT 1Ah/00h: get tick count -> CX:DX
mov [0xbcd1],dx  ; 018F3  timer_mark_tick = current tick
ret  ; 018F7

; ---- function timer_wait_3ticks ----
; Waits until 3 ticks (~165ms, ~6 FPS) have elapsed since the
; last timer_mark call.  Polls INT 1Ah in a tight loop, then
; updates timer_mark_tick with the current tick for the next frame.
timer_wait_3ticks:
loc_018F8:
mov ah,0x0  ; 018F8
int 0x1a  ; 018FA  get current tick count
db 0x8B, 0xC2  ; 018FC mov ax,dx  save current tick in AX
sub dx,[0xbcd1]  ; 018FE  delta = current - timer_mark_tick
cmp dx,0x3  ; 01902  3 ticks elapsed?
jc short loc_018F8  ; 01905 jc 0x18f8  not yet, keep polling
mov [0xbcd1],ax  ; 01907  update timer_mark_tick for next frame
ret  ; 0190A

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
push bp  ; 0190B
db 0x8B, 0xEC  ; 0190C mov bp,sp
mov ax,[bp+0x2]  ; 0190E  save caller's return address
mov [0xbcde],ax  ; 01911  saved_return_addr
mov ax,[0xea]  ; 01914  save current_level
mov [0xbcda],ax  ; 01917  saved_level
mov ax,[0xe4]  ; 0191A  save camera_x
mov [0xbcdc],ax  ; 0191D  saved_camera_x
lea ax,[0xbd04]  ; 01920  ax = animation script buffer address
mov [0xbce0],bp  ; 01924  saved_bp
push ax  ; 01928  arg: destination buffer
push word [bp+0x4]  ; 01929  arg: script filename
call load_anim_script  ; 0192C  load and compile script to bytecode
add sp,0x4  ; 0192F
mov bp,[0xbce0]  ; 01932  restore BP
push word [bp+0x6]  ; 01936  arg: animation data filename
call load_animation  ; 01939  load animation frame data
add sp,0x2  ; 0193C
mov bp,[0xbce0]  ; 0193F  restore BP again
mov word [0xe4],0x0  ; 01943  camera_x = 0
call clear_screen  ; 01949
mov word [0xee],0x1  ; 0194C  anim_render_mode = normal
mov word [0xea],0x4  ; 01952  current_level = 4 (cutscene mode)
call run_anim_script  ; 01958  play the animation sequence
mov word [0xd652],0xffff  ; 0195B  wipe_prev_left = -1 (force redraw)
mov ax,[0xbcda]  ; 01961  restore current_level
mov [0xea],ax  ; 01964
mov ax,[0xbcdc]  ; 01967  restore camera_x
mov [0xe4],ax  ; 0196A
mov bx,[0xbcde]  ; 0196D  restore caller's return address
mov [bp+0x2],bx  ; 01971  redirect return to saved address
pop bp  ; 01974
ret  ; 01975

; ---- function build_anim_offsets_alt ----
; Sets up base/table pointers for secondary animation data,
; then falls through to build_anim_offsets.
; Base = 0xC428 (secondary animation frame data).
; Table = 0xC3D4 (secondary offset table destination).
build_anim_offsets_alt:
lea bx,[0xc428]  ; 01976  bx = secondary animation data base
lea di,[0xc3d4]  ; 0197A  di = secondary offset table

; ---- function build_anim_offsets ----
; Scans animation frame data to build a table of 42 word offsets,
; each pointing to the start of an animation sequence.
; Records are 0x11 bytes each; loop markers (0x18) have 2-byte skip;
; sequences are terminated by 0xFF.
; Input: BX = data base address, DI = offset table destination.
build_anim_offsets:
mov si,0x0  ; 0197E  si = current offset into data
mov cl,0x2a  ; 01981  cl = 42 sequences to scan
loc_01983:
mov [di],si  ; 01983  store offset for this sequence
add di,0x2  ; 01985  advance table pointer

loc_01988:
cmp byte [bx+si],0xff  ; 01988  end-of-sequence marker?
jz short loc_0199C  ; 0198B jz 0x199c  yes, next sequence
cmp byte [bx+si],0x18  ; 0198D  loop marker?
jnz short loc_01997  ; 01990 jnz 0x1997
add si,0x2  ; 01992  loop marker = 2-byte skip
jmp short loc_01988  ; 01995 jmp 0x1988

loc_01997:
add si,0x11  ; 01997  normal record = 0x11 bytes
jmp short loc_01988  ; 0199A jmp 0x1988

loc_0199C:
inc si  ; 0199C  skip past 0xFF terminator
dec cl  ; 0199D
jnz short loc_01983  ; 0199F jnz 0x1983  loop for all 42 sequences
ret  ; 019A1
