; Screen setup, timer/delay functions
;
; Memory variables used in this file:
;   [0xbcd0] = anim_active         - 1 while animation script is running, 0 when done
;   [0xbcd1] = timer_last_tick     - saved tick count for frame timing (used by timer_mark/timer_wait_3ticks)
;   [0xbcd5] = scroll_offset       - horizontal scroll/camera X position (used across many files)
;   [0xbcd7] = inc_x_count         - counter: when >0, set_fig adds scroll_offset to figure X position, then decrements
;   [0xbcd8] = single_step_mode    - when 1, do_scr waits for keypress and loop re-renders + re-inits (debug/slideshow mode)
;   [0xbce0] = saved_bp            - saved base pointer during set_music_callback (bp is clobbered by C calls)
;   [0xbce2] = delay_target_tick   - target tick count that delay_ticks polls until reached
;   [0xbce4] = delay_loop_count    - remaining iterations for delay_with_input loop
;   [0xbce6] = anim_script_pc      - animation script program counter (byte offset into command buffer at 0xBD04)
;   [0xbcda] = saved_scene_state   - saved [0xea] (scene_state) during set_music_callback
;   [0xbcdc] = saved_player_x      - saved [0xe4] (player_x_offset) during set_music_callback
;   [0xbcde] = saved_return_addr   - saved return address during set_music_callback
;   [0xbb2a] = active_bg_id        - current active background scene ID (0xFFFF = none)
;   [0xbb2e] = figure_list_end     - offset past last entry in figure slot array (each slot is 4 bytes)
;   [0xbb30] = bg_index            - background image index for rendering
;   [0xbb31] = wipe_enabled        - 1 = use wipe transition when drawing, 0 = direct draw
;   [0xbb32] = tune_index          - music/tune index for sound playback
;   [0xbb33] = figure_slots_start  - first byte of figure slot array (0xFF = empty/end marker)
;   [0xd652] = bg_scroll_pos       - background scroll position (0xFFFF = reset)
;   [0xea]   = scene_state         - scene state variable (values 0-4)
;   [0xe4]   = player_x_offset     - player/actor X offset from origin
;   [0xee]   = render_mode         - rendering mode (0, 1, 2)
;   [0x156]  = pause_on_input      - when nonzero, animation pauses if a key is pressed
;
; Animation Script System:
;   setup_screen() interprets a bytecode animation script stored at address 0xBD04.
;   The script is a sequence of commands, each starting with a command byte followed
;   by 0-5 parameter bytes depending on the command.
;
;   Command byte is used as index into a jump table at 0xBCE8 (referenced as [bx-0x4318]).
;   The parameter bytes follow at [si-0x42fb], [si-0x42fa], etc. (i.e. script_base + pc + 1, +2, ...).
;   Command 0xFF is the end-of-script marker (checked before dispatch).
;
;   Animation commands (from command table at data offset 0x6E16):
;     set_tune(tune)       - set music/tune index [0xbb32], 1 param byte, advances PC by 2
;     set_bg(bg)           - set background index [0xbb30], 1 param byte, advances PC by 2
;     set_fig(id,x,y,f)    - add figure to slot list, 4 param bytes, advances PC by 5
;     chg_fig(slot,x,y)    - change existing figure slot data, 5 param bytes, advances PC by 6
;     do_scr               - render current frame (calls sub_00BC9), no params, advances PC by 1
;     del_fig(slot)        - delete figure from slot list and shift remaining, 1 param, advances PC by 2
;     set_wipe             - enable wipe transition [0xbb31]=1, no params, advances PC by 1
;     set_nowipe           - disable wipe transition [0xbb31]=0, no params, advances PC by 1
;     wait(ticks)          - delay for N ticks (skipped if single_step_mode), 1 param, advances PC by 2
;     init_sal             - reset figure list and rendering state, no params, advances PC by 1
;     set_pos(?,?)         - in single_step_mode: render + reset + rewind; sets inc_x_count=2, 2 params, advances PC by 3
;     inc_x(delta)         - add signed delta to scroll_offset, 1 param byte (sign-extended), advances PC by 2
;     end_animation (0xFF) - stop script execution (checked before dispatch, not in jump table)


; ---- function setup_screen ----
; Animation script interpreter. Reads commands from buffer at 0xBD04,
; dispatches each via jump table, loops until 0xFF end marker.
; If [0x156] (pause_on_input) is set and a key is pressed, pauses
; and lets the user step through with wait_for_key, then aborts.
; No parameters (uses global state). No return value.
setup_screen:
mov byte [0xbcd0],0x1  ; 01734  anim_active = 1 (animation is running)
call sub_0186C  ; 01739  init_sal: reset figure list and rendering state
mov word [0xbce6],0x0  ; 0173C  anim_script_pc = 0 (start of script)
mov byte [0xbcd7],0x0  ; 01742  inc_x_count = 0
loc_01747:
mov si,[0xbce6]  ; 01747  si = current script position
mov bl,[si-0x42fc]  ; 0174B  bl = command byte at script_base[pc] (0xBD04 + pc, since -0x42fc wraps to 0xBD04)
cmp bl,0xff  ; 0174F  0xFF = end_animation marker
jz short loc_0177D  ; 01752 jz 0x177d  → script finished
mov bh,0x0  ; 01754  bx = command byte (zero-extend)
push word [0xbce6]  ; 01756  save current PC on stack (for abort recovery)
call word near [bx-0x4318]  ; 0175A  dispatch: call handler from jump table at 0xBCE8[bx]
cmp word [0x156],0x0  ; 0175E  pause_on_input enabled?
jz short loc_0177A  ; 01763 jz 0x177a  → no, continue
call poll_keyboard  ; 01765  check for keypress
db 0x3D, 0x00, 0x00  ; 01768 cmp ax,0x0
jz short loc_0177A  ; 0176B jz 0x177a  → no key pressed, continue
call wait_for_key  ; 0176D  key was pressed: wait for another key (step mode)
pop word [0xbce6]  ; 01770  restore saved PC (abort: rewind to before this command)
mov byte [0xbcd0],0x0  ; 01774  anim_active = 0
ret  ; 01779  return early (animation aborted by user)
loc_0177A:
pop ax  ; 0177A  discard saved PC
jmp short loc_01747  ; 0177B jmp 0x1747  → process next command
loc_0177D:
mov ax,0x0  ; 0177D  return 0 (script completed normally)
mov byte [0xbcd0],0x0  ; 01780  anim_active = 0
ret  ; 01785

; --- Animation command handler: set_bg ---
; Sets the background image index. 1 parameter byte.
; Script format: [cmd_byte] [bg_index]
mov al,[si-0x42fb]  ; 01786  al = param: background index
mov [0xbb30],al  ; 0178A  bg_index = al
add word [0xbce6],0x2  ; 0178D  advance PC past command + 1 param byte
ret  ; 01792

; --- Animation command handler: set_tune ---
; Sets the music/tune index. 1 parameter byte.
; Script format: [cmd_byte] [tune_index]
mov al,[si-0x42fb]  ; 01793  al = param: tune index
mov [0xbb32],al  ; 01797  tune_index = al
add word [0xbce6],0x2  ; 0179A  advance PC past command + 1 param byte
ret  ; 0179F

; --- Animation command handler: set_fig ---
; Adds a new figure to the figure slot list. 4 parameter bytes.
; Script format: [cmd_byte] [figure_id] [x_pos_word] [y_pos_byte]
; Figure slot is 4 bytes: [id, x_lo, x_hi, y]
; If inc_x_count > 0, adds scroll_offset to x position (for scrolling scenes).
mov di,[0xbb2e]  ; 017A0  di = figure_list_end (next free slot offset)
mov al,[si-0x42fb]  ; 017A4  al = param 1: figure ID
mov [di-0x44d0],al  ; 017A8  slot[0] = figure_id (slot base is 0xBB30, so [di-0x44d0] = 0xBB30-relative)
mov ax,[si-0x42fa]  ; 017AC  ax = param 2-3: x position (word)
cmp byte [0xbcd7],0x0  ; 017B0  inc_x_count > 0?
jz short loc_017BF  ; 017B5 jz 0x17bf  → no offset adjustment needed
dec byte [0xbcd7]  ; 017B7  inc_x_count--
add ax,[0xbcd5]  ; 017BB  x_pos += scroll_offset (camera-relative positioning)
loc_017BF:
mov [di-0x44cf],ax  ; 017BF  slot[1-2] = x position
mov al,[si-0x42f8]  ; 017C3  al = param 4: y position / frame
mov [di-0x44cd],al  ; 017C7  slot[3] = y position
mov byte [di-0x44cc],0xff  ; 017CB  next slot marker = 0xFF (end of list)
add word [0xbb2e],0x4  ; 017D0  figure_list_end += 4 (advance past new slot)
add word [0xbce6],0x5  ; 017D5  advance PC past command + 4 param bytes
ret  ; 017DA

; --- Animation command handler: chg_fig ---
; Changes data in an existing figure slot. 5 parameter bytes.
; Script format: [cmd_byte] [slot_index] [new_x_word] [new_y_word]
; Slot index is multiplied by 4 to get slot offset.
mov bl,[si-0x42fb]  ; 017DB  bl = param 1: slot index
mov bh,0x0  ; 017DF
shl bx,1  ; 017E1  bx = slot_index * 4 (each slot is 4 bytes)
shl bx,1  ; 017E3
mov ax,[si-0x42fa]  ; 017E5  ax = param 2-3: new x position
mov [bx-0x44cd],ax  ; 017E9  slot[1-2] = new x
mov ax,[si-0x42f8]  ; 017ED  ax = param 4-5: new y position
mov [bx-0x44cb],ax  ; 017F1  slot[3-4] = new y (note: writes 2 bytes, overlaps into next slot byte)
add word [0xbce6],0x6  ; 017F5  advance PC past command + 5 param bytes
ret  ; 017FA

; ---- function sub_017FB ----
; Animation command handler: do_scr
; Renders the current frame by calling sub_00BC9 (draw all active figures).
; In single_step_mode ([0xbcd8]=1), waits for a keypress after rendering.
; No parameters.
sub_017FB:
call sub_00BC9  ; 017FB  render current frame (draw figures to screen)
inc word [0xbce6]  ; 017FE  advance PC past command byte
cmp word [0xbcd8],0x1  ; 01802  single_step_mode?
jnz short loc_0180C  ; 01807 jnz 0x180c  → no, continue
call wait_for_key  ; 01809  wait for keypress (step-through debugging)
loc_0180C:
ret  ; 0180C

; --- Animation command handler: del_fig ---
; Deletes a figure from the slot list by index. Shifts all subsequent
; slots down by 4 bytes to fill the gap. 1 parameter byte.
; Script format: [cmd_byte] [slot_index]
mov bl,[si+0x1]  ; 0180D  bl = param: slot index to delete
mov bh,0x0  ; 01810
shl bx,1  ; 01812  bx = slot_index * 4 + 3 (offset to slot start in array)
shl bx,1  ; 01814
add bx,0x3  ; 01816
sub word [0xbb2e],0x4  ; 01819  figure_list_end -= 4 (one fewer slot)
loc_0181E:                        ;   shift loop: move each subsequent slot down by 4 bytes
mov ax,[bx-0x44cc]  ; 0181E  ax = next_slot[0-1]
mov [bx-0x44d0],ax  ; 01822  current_slot[0-1] = ax
mov ax,[bx-0x44ca]  ; 01826  ax = next_slot[2-3]
mov [bx-0x44ce],ax  ; 0182A  current_slot[2-3] = ax
add bx,0x4  ; 0182E  advance to next slot
cmp bx,[0xbb2e]  ; 01831  past end of list?
jl short loc_0181E  ; 01835 jl 0x181e  → no, keep shifting
mov byte [bx-0x44d0],0xff  ; 01837  mark new end of list with 0xFF
add word [0xbce6],0x2  ; 0183C  advance PC past command + 1 param byte
ret  ; 01841

; --- Animation command handler: set_wipe ---
; Enables wipe transition effect for subsequent screen draws.
; No parameters.
mov byte [0xbb31],0x1  ; 01842  wipe_enabled = 1
inc word [0xbce6]  ; 01847  advance PC past command byte
ret  ; 0184B

; --- Animation command handler: set_nowipe ---
; Disables wipe transition effect (direct draw).
; No parameters.
mov byte [0xbb31],0x0  ; 0184C  wipe_enabled = 0
inc word [0xbce6]  ; 01851  advance PC past command byte
ret  ; 01855

; --- Animation command handler: wait ---
; Delays for N timer ticks. Skipped entirely if single_step_mode is active.
; 1 parameter byte.
; Script format: [cmd_byte] [tick_count]
cmp word [0xbcd8],0x0  ; 01856  single_step_mode?
jnz short loc_01866  ; 0185B jnz 0x1866  → yes, skip delay
mov al,[si-0x42fb]  ; 0185D  al = param: number of ticks to wait
mov ah,0x0  ; 01861  ax = tick count (zero-extend)
call delay_ticks  ; 01863  wait for that many BIOS timer ticks
loc_01866:
add word [0xbce6],0x2  ; 01866  advance PC past command + 1 param byte
ret  ; 0186B

; ---- function sub_0186C ----
; Animation command handler: init_sal (initialize scene animation list)
; Resets all figure slots and rendering state to defaults.
; Called at the start of setup_screen and as a script command.
; No parameters.
sub_0186C:
mov word [0xbb2a],0xffff  ; 0186C  active_bg_id = 0xFFFF (no background)
mov word [0xee],0x1  ; 01872  render_mode = 1
mov byte [0xbb30],0x0  ; 01878  bg_index = 0
mov word [0xbb31],0x0  ; 0187D  wipe_enabled = 0
mov byte [0xbb33],0xff  ; 01883  figure_slots[0] = 0xFF (empty list marker)
mov word [0xbb2e],0x3  ; 01888  figure_list_end = 3 (offset of first slot, since slots start at 0xbb33)
inc word [0xbce6]  ; 0188E  advance PC past command byte
ret  ; 01892

; --- Animation command handler: set_pos ---
; In single_step_mode: forces a render (do_scr) and re-initializes the figure list
; (init_sal), then rewinds PC by 2. Sets inc_x_count=2 so the next two set_fig
; commands will have scroll_offset added to their X positions.
; 2 parameter bytes (purpose of params unclear — may be position data used by other code).
; Script format: [cmd_byte] [param1] [param2]
cmp word [0xbcd8],0x1  ; 01893  single_step_mode?
jnz short loc_018A5  ; 01898 jnz 0x18a5  → no, skip re-render
call sub_017FB  ; 0189A  do_scr: render current frame
call sub_0186C  ; 0189D  init_sal: reset figure list
sub word [0xbce6],0x2  ; 018A0  rewind PC by 2 (compensate for init_sal's +1 and do_scr's +1)
loc_018A5:
mov byte [0xbcd7],0x2  ; 018A5  inc_x_count = 2 (next 2 set_fig commands get scroll offset)
add word [0xbce6],0x3  ; 018AA  advance PC past command + 2 param bytes
ret  ; 018AF

; --- Animation command handler: inc_x ---
; Adds a signed byte delta to the horizontal scroll offset.
; Used to pan/scroll the scene during animations.
; 1 parameter byte (sign-extended to word).
; Script format: [cmd_byte] [signed_delta_byte]
mov al,[si-0x42fb]  ; 018B0  al = param: signed X delta
cbw  ; 018B4  sign-extend al to ax
add [0xbcd5],ax  ; 018B5  scroll_offset += delta
add word [0xbce6],0x2  ; 018B9  advance PC past command + 1 param byte
ret  ; 018BE

; ---- function delay_ticks ----
; Busy-waits for AX timer ticks (each tick ≈ 55ms, ~18.2 ticks/sec).
; Uses BIOS INT 1Ah to read the system timer.
; Input: AX = number of ticks to wait.
; Clobbers: AX, CX, DX.
delay_ticks:
mov [0xbce2],ax  ; 018BF  delay_target_tick = requested ticks
mov ah,0x0  ; 018C2
int 0x1a  ; 018C4 - INT 1Ah/AH=00h: Get system timer tick count (CX:DX = ticks since midnight)
add [0xbce2],dx  ; 018C6  delay_target_tick = current_tick + requested_ticks
loc_018CA:
mov ah,0x0  ; 018CA
int 0x1a  ; 018CC - INT 1Ah/AH=00h: Get system timer tick count (polling in loop)
cmp dx,[0xbce2]  ; 018CE  has current tick reached target?
jnz short loc_018CA  ; 018D2 jnz 0x18ca  → no, keep polling
ret  ; 018D4

; ---- function delay_with_input ----
; Interruptible delay: waits for (AX/2) iterations of 2-tick delays,
; but breaks early if the user presses a key.
; Input: AX = total delay duration (halved, then each iteration waits 2 ticks ≈ 110ms).
; Returns: AX = key code if interrupted, 0 if delay completed.
delay_with_input:
shr ax,1  ; 018D5  iterations = duration / 2
mov [0xbce4],ax  ; 018D7  delay_loop_count = iterations
loc_018DA:
mov ax,0x2  ; 018DA  wait 2 ticks per iteration (~110ms)
call delay_ticks  ; 018DD
call poll_keyboard  ; 018E0  check for keypress
db 0x3D, 0x00, 0x00  ; 018E3 cmp ax,0x0
jnz short loc_018EE  ; 018E6 jnz 0x18ee  → key pressed, break out
dec word [0xbce4]  ; 018E8  delay_loop_count--
jnz short loc_018DA  ; 018EC jnz 0x18da  → more iterations remaining
loc_018EE:
ret  ; 018EE

; ---- function timer_mark ----
; Records the current timer tick count for later use by timer_wait_3ticks.
; Used for frame pacing: call timer_mark at frame start, timer_wait_3ticks
; at frame end to enforce a minimum frame time of 3 ticks (~165ms).
; Clobbers: AX, CX, DX.
timer_mark:
mov ah,0x0  ; 018EF
int 0x1a  ; 018F1 - INT 1Ah/AH=00h: Get system timer tick count (save as timestamp)
mov [0xbcd1],dx  ; 018F3  timer_last_tick = current tick (low word)
ret  ; 018F7

; ---- function timer_wait_3ticks ----
; Busy-waits until at least 3 timer ticks have elapsed since the last timer_mark call.
; This enforces a minimum frame time of 3 ticks (~165ms ≈ ~6 FPS).
; After waiting, updates timer_last_tick to the current tick for the next frame.
; Clobbers: AX, CX, DX.
timer_wait_3ticks:
loc_018F8:
mov ah,0x0  ; 018F8
int 0x1a  ; 018FA - INT 1Ah/AH=00h: Get system timer tick count (wait until 3 ticks elapsed)
db 0x8B, 0xC2  ; 018FC mov ax,dx  ; save current tick in ax
sub dx,[0xbcd1]  ; 018FE  elapsed = current_tick - timer_last_tick
cmp dx,0x3  ; 01902  elapsed >= 3?
jc short loc_018F8  ; 01905 jc 0x18f8  → no, keep polling
mov [0xbcd1],ax  ; 01907  timer_last_tick = current tick (for next frame)
ret  ; 0190A

; ---- function set_music_callback ----
; Plays a music/animation sequence by temporarily hijacking the scene state.
; Saves the current scene_state and player_x_offset, sets up a figure and
; animation, runs the animation script via setup_screen, then restores
; the saved state. Also modifies its own return address on the stack so the
; caller returns to a different location (the callback address).
;
; Stack frame:
;   [bp+0x2] = return address (overwritten with saved_return_addr at end)
;   [bp+0x4] = figure data pointer (passed to init_figure)
;   [bp+0x6] = animation data pointer (passed to load_animation)
;
; The function saves/restores bp manually because C library calls (init_figure,
; load_animation) may clobber it. Uses [0xbce0] as a temp save location for bp.
set_music_callback:
push bp  ; 0190B
db 0x8B, 0xEC  ; 0190C mov bp,sp
mov ax,[bp+0x2]  ; 0190E  ax = original return address
mov [0xbcde],ax  ; 01911  saved_return_addr = return address
mov ax,[0xea]  ; 01914  ax = scene_state
mov [0xbcda],ax  ; 01917  saved_scene_state = scene_state
mov ax,[0xe4]  ; 0191A  ax = player_x_offset
mov [0xbcdc],ax  ; 0191D  saved_player_x = player_x_offset
lea ax,[0xbd04]  ; 01920  ax = address of animation script buffer
mov [0xbce0],bp  ; 01924  saved_bp = bp (C calls will clobber bp)
push ax  ; 01928  arg 2: script buffer address
push word [bp+0x4]  ; 01929  arg 1: figure data pointer
call init_figure  ; 0192C  initialize figure with data
add sp,0x4  ; 0192F  clean up 2 args
mov bp,[0xbce0]  ; 01932  restore bp
push word [bp+0x6]  ; 01936  arg 1: animation data pointer
call load_animation  ; 01939  load animation sequence into script buffer
add sp,0x2  ; 0193C  clean up 1 arg
mov bp,[0xbce0]  ; 0193F  restore bp
mov word [0xe4],0x0  ; 01943  player_x_offset = 0
call clear_screen  ; 01949
mov word [0xee],0x1  ; 0194C  render_mode = 1
mov word [0xea],0x4  ; 01952  scene_state = 4 (animation playback mode)
call setup_screen  ; 01958  run the animation script
mov word [0xd652],0xffff  ; 0195B  bg_scroll_pos = 0xFFFF (reset)
mov ax,[0xbcda]  ; 01961  restore scene_state
mov [0xea],ax  ; 01964
mov ax,[0xbcdc]  ; 01967  restore player_x_offset
mov [0xe4],ax  ; 0196A
mov bx,[0xbcde]  ; 0196D  bx = saved_return_addr
mov [bp+0x2],bx  ; 01971  overwrite return address on stack (return to callback target)
pop bp  ; 01974
ret  ; 01975

; ---- function sub_01976 ----
; Build animation frame offset table for secondary animation data.
; Sets bx = 0xC428 (secondary animation data base) and di = 0xC3D4
; (secondary frame offset table), then falls through to sub_0197E.
sub_01976:
lea bx,[0xc428]  ; 01976  bx = secondary animation data base address
lea di,[0xc3d4]  ; 0197A  di = secondary frame offset table

; ---- function sub_0197E ----
; Build animation frame offset table. Scans animation data at [bx],
; recording the offset of each frame's start into the table at [di].
; Each frame is either a 0x18 (skip) marker (2 bytes) or a regular
; frame record (0x11 = 17 bytes). Frames are terminated by 0xFF.
; Processes 0x2A (42) frames total.
;
; Input: BX = animation data base address, DI = frame offset table address.
; Clobbers: SI, CL, AX.
sub_0197E:
mov si,0x0  ; 0197E  si = current byte offset into animation data
mov cl,0x2a  ; 01981  cl = 42 frames to process
loc_01983:
mov [di],si  ; 01983  table[frame] = current offset (start of this frame's data)
add di,0x2  ; 01985  advance table pointer (2 bytes per entry)
loc_01988:
cmp byte [bx+si],0xff  ; 01988  end-of-frame marker?
jz short loc_0199C  ; 0198B jz 0x199c  → yes, move to next frame
cmp byte [bx+si],0x18  ; 0198D  skip marker? (0x18 = 24)
jnz short loc_01997  ; 01990 jnz 0x1997  → no, regular frame record
add si,0x2  ; 01992  skip marker is 2 bytes
jmp short loc_01988  ; 01995 jmp 0x1988  → check next record in this frame
loc_01997:
add si,0x11  ; 01997  regular record is 17 bytes (0x11)
jmp short loc_01988  ; 0199A jmp 0x1988  → check next record in this frame
loc_0199C:
inc si  ; 0199C  skip past 0xFF marker
dec cl  ; 0199D  one fewer frame to process
jnz short loc_01983  ; 0199F jnz 0x1983  → more frames remaining
ret  ; 019A1
