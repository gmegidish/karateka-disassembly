; Game init, main loop, scene management, actor init


; ---- function game_init ----
game_init:
push bp  ; 00255
sub sp,0x4  ; 00256
jc short loc_00261  ; 00259 jc 0x261
cmp sp,[0x17]  ; 0025B
ja short loc_00264  ; 0025F ja 0x264
loc_00261:
jmp 0x420  ; 00261
loc_00264:
db 0x8B, 0xEC  ; 00264 mov bp,sp
mov word [bp+0x2],0x0  ; 00266
call sub_04257  ; 0026B
call check_graphics_card  ; 0026E
test ax,ax  ; 00271
jnz short loc_00281  ; 00273 jnz 0x281
mov ax,0x41b7  ; 00275
push ax  ; 00278
call print_error  ; 00279
db 0x8B, 0xE5  ; 0027C mov sp,bp
call show_insert_disk  ; 0027E
loc_00281:
call init_screen_buffers  ; 00281
call install_handlers  ; 00284
call init_controls  ; 00287
test ax,ax  ; 0028A
jnz short loc_00296  ; 0028C jnz 0x296
mov word [0xdf46],0x1  ; 0028E
jmp short loc_0029C  ; 00294 jmp 0x29c
loc_00296:
mov word [0xdf46],0x0  ; 00296
loc_0029C:
mov ax,0x737  ; 0029C
push ax  ; 0029F
mov ax,0x337  ; 002A0
push ax  ; 002A3
db 0x33, 0xC0  ; 002A4 xor ax,ax
push ax  ; 002A6
call disk_setup  ; 002A7
db 0x8B, 0xE5  ; 002AA mov sp,bp
call load_game_disk  ; 002AC
test ax,ax  ; 002AF
jnz short loc_002B8  ; 002B1 jnz 0x2b8
call check_disk_prompt  ; 002B3
jmp short loc_0029C  ; 002B6 jmp 0x29c
loc_002B8:
call init_sound  ; 002B8
db 0x33, 0xC0  ; 002BB xor ax,ax
mov word [0x114],0xd  ; 002BD
mov [0x118],ax  ; 002C3
mov [0x11a],ax  ; 002C6
mov [0xe2],ax  ; 002C9
mov [0xf0],ax  ; 002CC
mov [0xec],ax  ; 002CF
mov [0x170],ax  ; 002D2
mov [0x16c],ax  ; 002D5
mov [0x16e],ax  ; 002D8
mov [0x172],ax  ; 002DB
mov [0x174],ax  ; 002DE
mov [0x12a],ax  ; 002E1
mov [0xe6],ax  ; 002E4
mov [0xe8],ax  ; 002E7
mov [0xf2],ax  ; 002EA
mov [0xf6],ax  ; 002ED
mov [0xf8],ax  ; 002F0
mov [0xfa],ax  ; 002F3
mov [0x12c],ax  ; 002F6
mov [0x130],ax  ; 002F9
mov [0x166],ax  ; 002FC
mov [0xd5aa],ax  ; 002FF
call game_main_loop  ; 00302
db 0x33, 0xC0  ; 00305 xor ax,ax
mov [0xfc],ax  ; 00307
mov [0x130],ax  ; 0030A
call timer_mark  ; 0030D
mov word [0x16a],0x0  ; 00310
cmp word [0x16a],0x1  ; 00316
jz short loc_002B8  ; 0031B jz 0x2b8
cmp word [0xdf44],0x0  ; 0031D
jg short loc_002B8  ; 00322 jg 0x2b8
mov ax,0x1  ; 00324
push ax  ; 00327
call poll_keyboard  ; 00328
db 0x8B, 0xE5  ; 0032B mov sp,bp
call timer_wait_3ticks  ; 0032D
call scene_update  ; 00330
call level_setup  ; 00333
call sub_00BC9  ; 00336
mov ax,[0x154]  ; 00339
test ax,ax  ; 0033C
jng short loc_00383  ; 0033E jng 0x383
db 0x3D, 0x02, 0x00  ; 00340 cmp ax,0x2
jnz short loc_00350  ; 00343 jnz 0x350
mov ax,0x8  ; 00345
push ax  ; 00348
call wait_vsync  ; 00349
db 0x8B, 0xE5  ; 0034C mov sp,bp
jmp short loc_0037D  ; 0034E jmp 0x37d
loc_00350:
cmp word [0x154],0x3  ; 00350
jnz short loc_00362  ; 00355 jnz 0x362
mov ax,0x18  ; 00357
push ax  ; 0035A
call wait_vsync  ; 0035B
db 0x8B, 0xE5  ; 0035E mov sp,bp
jmp short loc_0037D  ; 00360 jmp 0x37d
loc_00362:
cmp word [0x154],0x4  ; 00362
jnz short loc_00374  ; 00367 jnz 0x374
mov ax,0x16  ; 00369
push ax  ; 0036C
call wait_vsync  ; 0036D
db 0x8B, 0xE5  ; 00370 mov sp,bp
jmp short loc_0037D  ; 00372 jmp 0x37d
loc_00374:
mov ax,0x1  ; 00374
push ax  ; 00377
call wait_vsync  ; 00378
db 0x8B, 0xE5  ; 0037B mov sp,bp
loc_0037D:
mov word [0x154],0x0  ; 0037D
loc_00383:
db 0x33, 0xC0  ; 00383 xor ax,ax
cmp word [0x16a],0x0  ; 00385
mov [0xee],ax  ; 0038A
jnz short loc_00395  ; 0038D jnz 0x395
call cutscene_play  ; 0038F
mov [0x16a],ax  ; 00392
loc_00395:
cmp word [0x12a],0x2  ; 00395
jnz short loc_003AB  ; 0039A jnz 0x3ab
mov word [0x12a],0x0  ; 0039C
mov ax,0x1  ; 003A2
push ax  ; 003A5
call wait_vsync  ; 003A6
db 0x8B, 0xE5  ; 003A9 mov sp,bp
loc_003AB:
cmp word [0x12a],0x1  ; 003AB
jnz short loc_003C1  ; 003B0 jnz 0x3c1
mov word [0x12a],0x2  ; 003B2
mov word [0xc3a6],0x1  ; 003B8
call effect_fade  ; 003BE
loc_003C1:
call scene_transition  ; 003C1
jmp 0x516  ; 003C4

; ---- function game_main_loop ----
game_main_loop:
push bp  ; 003C7
sub sp,0x4  ; 003C8
jc short loc_003D3  ; 003CB jc 0x3d3
cmp sp,[0x17]  ; 003CD
ja short loc_003D6  ; 003D1 ja 0x3d6
loc_003D3:
jmp 0x420  ; 003D3
loc_003D6:
db 0x8B, 0xEC  ; 003D6 mov bp,sp
call flush_keyboard  ; 003D8
db 0x33, 0xC0  ; 003DB xor ax,ax
mov bx,0xce3e  ; 003DD
push bx  ; 003E0
mov bx,0x41f4  ; 003E1
push bx  ; 003E4
mov [0xf6],ax  ; 003E5
mov [0x15c],ax  ; 003E8
mov [0x15a],ax  ; 003EB
call init_figure  ; 003EE
db 0x8B, 0xE5  ; 003F1 mov sp,bp
call play_sound  ; 003F3
mov ax,0x5dc  ; 003F6
push ax  ; 003F9
mov ax,0x41fb  ; 003FA
push ax  ; 003FD
call load_palette  ; 003FE
db 0x8B, 0xE5  ; 00401 mov sp,bp
mov word [0xea],0x0  ; 00403
push word [0xea]  ; 00409
call combat_update  ; 0040D
db 0x8B, 0xE5  ; 00410 mov sp,bp
mov word [0xdf44],0x0  ; 00412
mov ax,0xd  ; 00418
push ax  ; 0041B
call load_animation  ; 0041C
db 0x8B, 0xE5  ; 0041F mov sp,bp
call animate_step  ; 00421
test ax,ax  ; 00424
jz short loc_0042E  ; 00426 jz 0x42e
call load_scene  ; 00428
jmp 0x742  ; 0042B
loc_0042E:
db 0x33, 0xC0  ; 0042E xor ax,ax
push ax  ; 00430
mov ax,0x4204  ; 00431
push ax  ; 00434
call load_palette  ; 00435
db 0x8B, 0xE5  ; 00438 mov sp,bp
call draw_scene_element  ; 0043A
test ax,ax  ; 0043D
jz short loc_00447  ; 0043F jz 0x447
call load_scene  ; 00441
jmp 0x742  ; 00444
loc_00447:
call draw_gate  ; 00447
test ax,ax  ; 0044A
jz short loc_00454  ; 0044C jz 0x454
call load_scene  ; 0044E
jmp 0x742  ; 00451
loc_00454:
call animate_figure  ; 00454
test ax,ax  ; 00457
jz short loc_00461  ; 00459 jz 0x461
call load_scene  ; 0045B
jmp 0x742  ; 0045E
loc_00461:
call draw_health_bar  ; 00461
test ax,ax  ; 00464
jz short loc_0046E  ; 00466 jz 0x46e
call load_scene  ; 00468
jmp 0x742  ; 0046B
loc_0046E:
mov word [0xe4],0x0  ; 0046E
call clear_screen  ; 00474
mov word [0xee],0x1  ; 00477
mov word [0xea],0x4  ; 0047D
mov ax,0xbd04  ; 00483
push ax  ; 00486
mov ax,0x420e  ; 00487
push ax  ; 0048A
call init_figure  ; 0048B
db 0x8B, 0xE5  ; 0048E mov sp,bp
mov ax,0x6  ; 00490
push ax  ; 00493
call load_animation  ; 00494
db 0x8B, 0xE5  ; 00497 mov sp,bp
call setup_screen  ; 00499
test ax,ax  ; 0049C
jz short loc_004A6  ; 0049E jz 0x4a6
call load_scene  ; 004A0
jmp 0x742  ; 004A3
loc_004A6:
mov word [0xea],0x0  ; 004A6
mov ax,0xbd04  ; 004AC
push ax  ; 004AF
mov ax,0x4214  ; 004B0
push ax  ; 004B3
call init_figure  ; 004B4
db 0x8B, 0xE5  ; 004B7 mov sp,bp
mov ax,0x5dc  ; 004B9
push ax  ; 004BC
mov ax,0x41fb  ; 004BD
push ax  ; 004C0
call load_palette  ; 004C1
db 0x8B, 0xE5  ; 004C4 mov sp,bp
db 0x33, 0xC0  ; 004C6 xor ax,ax
push ax  ; 004C8
call combat_update  ; 004C9
db 0x8B, 0xE5  ; 004CC mov sp,bp
call setup_screen  ; 004CE
test ax,ax  ; 004D1
jz short loc_004DA  ; 004D3 jz 0x4da
call game_shutdown  ; 004D5
jmp short loc_00542  ; 004D8 jmp 0x542
loc_004DA:
mov word [0xea],0x0  ; 004DA
mov word [0xf4],0xfa  ; 004E0
mov word [0x156],0x1  ; 004E6
call timer_mark  ; 004EC
mov word [bp+0x2],0x0  ; 004EF
loc_004F4:
cmp word [bp+0x2],0x1  ; 004F4
jz short loc_00537  ; 004F8 jz 0x537
call timer_wait_3ticks  ; 004FA
call scene_update  ; 004FD
call level_setup  ; 00500
call sub_00BC9  ; 00503
mov ax,[0x154]  ; 00506
test ax,ax  ; 00509
jng short loc_0052C  ; 0050B jng 0x52c
db 0x3D, 0x02, 0x00  ; 0050D cmp ax,0x2
jnz short loc_0051D  ; 00510 jnz 0x51d
mov ax,0x8  ; 00512
push ax  ; 00515
call wait_vsync  ; 00516
db 0x8B, 0xE5  ; 00519 mov sp,bp
jmp short loc_00526  ; 0051B jmp 0x526
loc_0051D:
mov ax,0x1  ; 0051D
push ax  ; 00520
call wait_vsync  ; 00521
db 0x8B, 0xE5  ; 00524 mov sp,bp
loc_00526:
mov word [0x154],0x0  ; 00526
loc_0052C:
call scene_transition  ; 0052C
call game_scene  ; 0052F
mov [bp+0x2],ax  ; 00532
jmp short loc_004F4  ; 00535 jmp 0x4f4
loc_00537:
db 0x33, 0xC0  ; 00537 xor ax,ax
push ax  ; 00539
call combat_check_hit  ; 0053A
db 0x8B, 0xE5  ; 0053D mov sp,bp
jmp 0x612  ; 0053F
loc_00542:
mov word [0x10c],0x41  ; 00542
call flush_keyboard  ; 00548
db 0x33, 0xC0  ; 0054B xor ax,ax
mov [0xdf43],al  ; 0054D
mov [0xea],ax  ; 00550
xor ah,ah  ; 00553
mov word [0x156],0x0  ; 00555
mov [0x174],ax  ; 0055B
mov [0x16c],ax  ; 0055E
mov [0x16e],ax  ; 00561
add sp,0x4  ; 00564
pop bp  ; 00567
ret  ; 00568

; ---- function game_scene ----
game_scene:
push bp  ; 00569
sub sp,0x2  ; 0056A
jc short loc_00575  ; 0056D jc 0x575
cmp sp,[0x17]  ; 0056F
ja short loc_00578  ; 00573 ja 0x578
loc_00575:
jmp 0x420  ; 00575
loc_00578:
db 0x8B, 0xEC  ; 00578 mov bp,sp
cmp word [0xf8],0x1  ; 0057A
jnz short loc_00588  ; 0057F jnz 0x588
cmp word [0x10c],0x43  ; 00581
jz short loc_0059E  ; 00586 jz 0x59e
loc_00588:
mov ax,[0xbcd5]  ; 00588
cmp ax,[0x104]  ; 0058B
jz short loc_0059E  ; 0058F jz 0x59e
mov ax,0x1  ; 00591
push ax  ; 00594
call poll_keyboard  ; 00595
db 0x8B, 0xE5  ; 00598 mov sp,bp
test ax,ax  ; 0059A
jz short loc_005A6  ; 0059C jz 0x5a6
loc_0059E:
mov ax,0x1  ; 0059E
add sp,0x2  ; 005A1
pop bp  ; 005A4
ret  ; 005A5
loc_005A6:
db 0x33, 0xC0  ; 005A6 xor ax,ax
add sp,0x2  ; 005A8
pop bp  ; 005AB
ret  ; 005AC

; ---- function load_scene ----
load_scene:
push bp  ; 005AD
db 0x8B, 0xEC  ; 005AE mov bp,sp
call load_background  ; 005B0
mov ax,0x5dc  ; 005B3
push ax  ; 005B6
mov ax,0x41fb  ; 005B7
push ax  ; 005BA
call load_palette  ; 005BB
db 0x8B, 0xE5  ; 005BE mov sp,bp
db 0x33, 0xC0  ; 005C0 xor ax,ax
push ax  ; 005C2
call combat_update  ; 005C3
db 0x8B, 0xE5  ; 005C6 mov sp,bp
call clear_screen  ; 005C8
db 0x33, 0xC0  ; 005CB xor ax,ax
mov bx,0xbd04  ; 005CD
push bx  ; 005D0
mov bx,0x4214  ; 005D1
push bx  ; 005D4
mov [0xdf44],ax  ; 005D5
mov [0xea],ax  ; 005D8
call init_figure  ; 005DB
db 0x8B, 0xE5  ; 005DE mov sp,bp
call setup_screen  ; 005E0
pop bp  ; 005E3
ret  ; 005E4
