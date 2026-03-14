; Keyboard polling, joystick, video mode init


; ---- function poll_keyboard ----
poll_keyboard:
push bp  ; 04149
db 0x8B, 0xEC  ; 0414A mov bp,sp
call check_ctrl_q  ; 0414C
nop  ; 0414F
nop  ; 04150
nop  ; 04151
jnz short loc_04177  ; 04152 jnz 0x4177
cmp word [0xdf46],0x0  ; 04154
jnz short loc_04169  ; 04159 jnz 0x4169
db 0x33, 0xC0  ; 0415B xor ax,ax
push ax  ; 0415D
call check_joystick  ; 0415E
pop bx  ; 04161
cmp al,0x0  ; 04162
jz short loc_04169  ; 04164 jz 0x4169
jmp 0x43e8  ; 04166
loc_04169:
cmp byte [0xdf43],0x0  ; 04169
jnz short loc_04173  ; 0416E jnz 0x4173
cbw  ; 04170
pop bp  ; 04171
ret  ; 04172
loc_04173:
mov al,0xff  ; 04173
pop bp  ; 04175
ret  ; 04176
loc_04177:
cmp al,0x1b  ; 04177
jz short loc_041F4  ; 04179 jz 0x41f4
cmp al,0x12  ; 0417B
jnz short loc_0418C  ; 0417D jnz 0x418c
call consume_key  ; 0417F
mov word [0xdf44],0x1  ; 04182
db 0x33, 0xC0  ; 04188 xor ax,ax
pop bp  ; 0418A
ret  ; 0418B
loc_0418C:
cmp al,0x13  ; 0418C
jnz short loc_041A7  ; 0418E jnz 0x41a7
call consume_key  ; 04190
inc byte [0xd6bc]  ; 04193
cmp byte [0xd6bc],0x3  ; 04197
jc short loc_041A3  ; 0419C jc 0x41a3
mov byte [0xd6bc],0x0  ; 0419E
loc_041A3:
db 0x33, 0xC0  ; 041A3 xor ax,ax
pop bp  ; 041A5
ret  ; 041A6
loc_041A7:
cmp word [0x168],0x1  ; 041A7
jnz short loc_041CE  ; 041AC jnz 0x41ce
cmp al,0x16  ; 041AE
jnz short loc_041CE  ; 041B0 jnz 0x41ce
call consume_key  ; 041B2
mov ax,0xbe  ; 041B5
push ax  ; 041B8
mov ax,0x96  ; 041B9
push ax  ; 041BC
mov ax,0x5d  ; 041BD
push ax  ; 041C0
call process_animation  ; 041C1
add sp,0x6  ; 041C4
call update_display  ; 041C7
db 0x33, 0xC0  ; 041CA xor ax,ax
pop bp  ; 041CC
ret  ; 041CD
loc_041CE:
cmp al,0x0  ; 041CE
jnz short loc_041E8  ; 041D0 jnz 0x41e8
mov ah,0x7  ; 041D2
int 0x21  ; 041D4
cmp al,0x4b  ; 041D6
jnz short loc_041DE  ; 041D8 jnz 0x41de
mov al,0x34  ; 041DA
jmp short loc_041E8  ; 041DC jmp 0x41e8
loc_041DE:
cmp al,0x4d  ; 041DE
jz short loc_041E6  ; 041E0 jz 0x41e6
db 0x33, 0xC0  ; 041E2 xor ax,ax
pop bp  ; 041E4
ret  ; 041E5
loc_041E6:
mov al,0x36  ; 041E6
loc_041E8:
mov [0xdf42],al  ; 041E8
mov byte [0xdf43],0x1  ; 041EB
mov al,0xff  ; 041F0
pop bp  ; 041F2
ret  ; 041F3
loc_041F4:
mov ah,0x7  ; 041F4
int 0x21  ; 041F6
db 0x33, 0xC0  ; 041F8 xor ax,ax
pop bp  ; 041FA
ret  ; 041FB

; ---- function wait_for_key ----
wait_for_key:
loc_041FC:
mov al,[0xdf42]  ; 041FC
cmp byte [0xdf43],0x0  ; 041FF
jnz short loc_0420A  ; 04204 jnz 0x420a
mov ah,0x7  ; 04206
int 0x21  ; 04208
loc_0420A:
mov ah,0x0  ; 0420A
mov byte [0xdf43],0x0  ; 0420C
cmp al,0x0  ; 04211
jz short loc_04217  ; 04213 jz 0x4217
jmp short loc_0422D  ; 04215 jmp 0x422d
loc_04217:
mov ah,0x7  ; 04217
int 0x21  ; 04219
cmp al,0x4b  ; 0421B
jnz short loc_04225  ; 0421D jnz 0x4225
mov al,0x34  ; 0421F
mov ah,0x0  ; 04221
jmp short loc_0422D  ; 04223 jmp 0x422d
loc_04225:
cmp al,0x4d  ; 04225
jnz short loc_041FC  ; 04227 jnz 0x41fc
mov al,0x36  ; 04229
mov ah,0x0  ; 0422B
loc_0422D:
push ax  ; 0422D
call flush_keyboard  ; 0422E
pop ax  ; 04231
ret  ; 04232

; ---- function flush_keyboard ----
flush_keyboard:
loc_04233:
call check_ctrl_q  ; 04233
nop  ; 04236
nop  ; 04237
nop  ; 04238
jnz short loc_04233  ; 04239 jnz 0x4233
mov byte [0xdf43],0x0  ; 0423B
ret  ; 04240

; ---- function consume_key ----
consume_key:
push word [0xd6bc]  ; 04241
mov byte [0xd6bc],0x0  ; 04245
mov ax,0x5  ; 0424A
push ax  ; 0424D
call wait_vsync  ; 0424E
pop ax  ; 04251
pop word [0xd6bc]  ; 04252
ret  ; 04256

; ---- function noop_stub ----
noop_stub:
ret  ; 04257
add [si-0x32f2],dh  ; 04258
and bx,ax  ; 0425C

; ---- function detect_hercules_vsync ----
detect_hercules_vsync:
in al,dx  ; 0425E
db 0x22, 0xC3  ; 0425F and al,bl
xchg ah,al  ; 04261
mov cx,0x7530  ; 04263
in al,dx  ; 04266
db 0x22, 0xC3  ; 04267 and al,bl
db 0x3A, 0xE0  ; 04269 cmp ah,al
jnz short loc_04271  ; 0426B jnz 0x4271
loop 0x4266  ; 0426D
stc  ; 0426F
ret  ; 04270
loc_04271:
clc  ; 04271
ret  ; 04272

; ---- function video_set_mode_4 ----
video_set_mode_4:
mov dx,0x3bf  ; 04273
mov al,0x0  ; 04276
out dx,al  ; 04278
push ds  ; 04279
mov ax,0x40  ; 0427A
mov ds,ax  ; 0427D
mov si,0x10  ; 0427F
mov al,[si]  ; 04282
and al,0xcf  ; 04284
or al,0x20  ; 04286
mov [si],al  ; 04288
pop ds  ; 0428A
mov ah,0x0  ; 0428B
mov al,0x4  ; 0428D
int 0x10  ; 0428F
push es  ; 04291
mov es,word [0xdf48]  ; 04292
mov di,0x1f40  ; 04296
db 0x8B, 0xD7  ; 04299 mov dx,di
mov cx,0x5a  ; 0429B
db 0x8B, 0xD9  ; 0429E mov bx,cx
cld  ; 042A0
mov ax,0x55aa  ; 042A1
rep stosw  ; 042A4
db 0x8B, 0xFA  ; 042A6 mov di,dx
db 0x8B, 0xCB  ; 042A8 mov cx,bx
repe scasw  ; 042AA
pop es  ; 042AC
jcxz short loc_042B1  ; 042AD jcxz 0x42b1
stc  ; 042AF
ret  ; 042B0
loc_042B1:
mov word [0xe0e9],0x0  ; 042B1
mov ax,0x0  ; 042B7
mov dx,0x2000  ; 042BA
mov cx,0xc8  ; 042BD
lea bx,[0xdf59]  ; 042C0
mov [bx],ax  ; 042C4
add bx,0x2  ; 042C6
db 0x05, 0x50, 0x00  ; 042C9 add ax,0x50
xchg ax,dx  ; 042CC
loop 0x42c4  ; 042CD
clc  ; 042CF
ret  ; 042D0

; ---- function init_hercules_mode ----
init_hercules_mode:
mov dx,0x3bf  ; 042D1
mov al,0x3  ; 042D4
out dx,al  ; 042D6
mov bl,[0xdf4a]  ; 042D7
push ds  ; 042DB
mov ax,0x40  ; 042DC
mov ds,ax  ; 042DF
mov si,0x10  ; 042E1
mov [si],bl  ; 042E4
pop ds  ; 042E6
mov dx,0x3ba  ; 042E7
mov bl,0x80  ; 042EA
call detect_hercules_vsync  ; 042EC
jnc short loc_042F3  ; 042EF jnc 0x42f3
stc  ; 042F1
ret  ; 042F2
loc_042F3:
mov word [0xe0e9],0x1  ; 042F3
push si  ; 042F9
push di  ; 042FA
mov cx,0x32  ; 042FB
lea bx,[0xdf59]  ; 042FE
mov si,0x658  ; 04302
mov di,0x2658  ; 04305
mov ax,0x4658  ; 04308
mov dx,0x6658  ; 0430B
mov [bx],si  ; 0430E
mov [bx+0x2],di  ; 04310
mov [bx+0x4],ax  ; 04313
mov [bx+0x6],dx  ; 04316
add si,0x5a  ; 04319
add di,0x5a  ; 0431C
db 0x05, 0x5A, 0x00  ; 0431F add ax,0x5a
add dx,0x5a  ; 04322
add bx,0x8  ; 04325
loop 0x430e  ; 04328
call clear_video_buffer  ; 0432A
lea si,[0xdf4d]  ; 0432D
call program_crtc_registers  ; 04331
mov dx,0x3b8  ; 04334
mov al,0x8a  ; 04337
out dx,al  ; 04339
pop di  ; 0433A
pop si  ; 0433B
clc  ; 0433C
ret  ; 0433D

; ---- function program_crtc_registers ----
program_crtc_registers:
mov dx,0x3b4  ; 0433E
mov cx,0xc  ; 04341
db 0x32, 0xE4  ; 04344 xor ah,ah
db 0x8A, 0xC4  ; 04346 mov al,ah
out dx,al  ; 04348
inc dx  ; 04349
lodsb  ; 0434A
out dx,al  ; 0434B
inc ah  ; 0434C
dec dx  ; 0434E
loop 0x4346  ; 0434F
ret  ; 04351

; ---- function check_graphics_card ----
check_graphics_card:
int 0x11  ; 04352
mov [0xdf4a],al  ; 04354
mov ah,0xf  ; 04357
int 0x10  ; 04359
mov [0xdf4b],al  ; 0435B
call video_set_mode_4  ; 0435E
jnc short loc_04368  ; 04361 jnc 0x4368
call init_hercules_mode  ; 04363
jc short loc_0436D  ; 04366 jc 0x436d
loc_04368:
db 0x32, 0xE4  ; 04368 xor ah,ah
add al,0x41  ; 0436A
ret  ; 0436C
loc_0436D:
call video_init  ; 0436D
db 0x33, 0xC0  ; 04370 xor ax,ax
ret  ; 04372

; ---- function video_init ----
video_init:
call clear_video_buffer  ; 04373
mov bl,[0xdf4a]  ; 04376
push ds  ; 0437A
mov ax,0x40  ; 0437B
mov ds,ax  ; 0437E
mov si,0x10  ; 04380
mov [si],bl  ; 04383
pop ds  ; 04385
mov ah,0x0  ; 04386
mov al,[0xdf4b]  ; 04388
int 0x10  ; 0438B
mov dl,[0xdf4c]  ; 0438D
mov ah,0xe  ; 04391
int 0x21  ; 04393
ret  ; 04395

; ---- function clear_video_buffer ----
clear_video_buffer:
push di  ; 04396
push es  ; 04397
mov es,word [0xdf48]  ; 04398
mov cx,0x4000  ; 0439C
mov ax,0x0  ; 0439F
db 0x8B, 0xF8  ; 043A2 mov di,ax
cld  ; 043A4
rep stosw  ; 043A5
pop es  ; 043A7
pop di  ; 043A8
ret  ; 043A9

; ---- function apply_gravity ----
apply_gravity:
push bp  ; 043AA
db 0x8B, 0xEC  ; 043AB mov bp,sp
cmp byte [bp+0x4],0x2  ; 043AD
jg short loc_043B9  ; 043B1 jg 0x43b9
add byte [bp+0x4],0x3  ; 043B3
jmp short loc_043C9  ; 043B7 jmp 0x43c9
loc_043B9:
sub byte [bp+0x4],0x3  ; 043B9
jz short loc_043C9  ; 043BD jz 0x43c9
sub word [bp+0x6],0x4  ; 043BF
cmp byte [bp+0x4],0x1  ; 043C3
jz short loc_043C9  ; 043C7 jz 0x43c9
loc_043C9:
mov si,[bp+0x8]  ; 043C9
db 0x81, 0x66, 0x06, 0xFC, 0xFF  ; 043CC and word [bp+0x6],0xfffc
db 0x33, 0xDB  ; 043D1 xor bx,bx
db 0x33, 0xD2  ; 043D3 xor dx,dx
db 0x33, 0xC0  ; 043D5 xor ax,ax
mov bl,[si-0x1eee]  ; 043D7
mov dl,[si-0x1f08]  ; 043DB
cmp [bp+0x6],dx  ; 043DF
jl short loc_0443D  ; 043E2 jl 0x443d
jnz short loc_04402  ; 043E4 jnz 0x4402
loc_043E6:
cmp word [bp+0x4],0x4  ; 043E6
jng short loc_043F2  ; 043EA jng 0x43f2
mov al,[bx-0x1eb6]  ; 043EC
jmp short loc_0443F  ; 043F0 jmp 0x443f
loc_043F2:
cmp word [bp+0x4],0x3  ; 043F2
jl short loc_043FE  ; 043F6 jl 0x43fe
mov al,[bx-0x1ec0]  ; 043F8
jmp short loc_0443F  ; 043FC jmp 0x443f
loc_043FE:
mov al,0x3  ; 043FE
jmp short loc_0443F  ; 04400 jmp 0x443f
loc_04402:
add dx,0x11  ; 04402
cmp [bp+0x6],dx  ; 04405
jg short loc_0443F  ; 04408 jg 0x443f
cmp word [bp+0x4],0x1  ; 0440A
jnz short loc_04416  ; 0440E jnz 0x4416
mov al,[bx-0x1eca]  ; 04410
jmp short loc_0443F  ; 04414 jmp 0x443f
loc_04416:
cmp word [bp+0x4],0x2  ; 04416
jg short loc_0442F  ; 0441A jg 0x442f
mov al,[bx-0x1ed4]  ; 0441C
cmp bl,0x1  ; 04420
jnz short loc_0443F  ; 04423 jnz 0x443f
cmp byte [bp+0x4],0x2  ; 04425
jnz short loc_0443F  ; 04429 jnz 0x443f
mov al,0x0  ; 0442B
jmp short loc_0443F  ; 0442D jmp 0x443f
loc_0442F:
sub dx,0x4  ; 0442F
cmp [bp+0x6],dx  ; 04432
jl short loc_043E6  ; 04435 jl 0x43e6
mov al,[bx-0x1eac]  ; 04437
jmp short loc_0443F  ; 0443B jmp 0x443f
loc_0443D:
mov al,0x4  ; 0443D
loc_0443F:
pop bp  ; 0443F
ret  ; 04440

; ---- function update_position ----
update_position:
push bp  ; 04441
db 0x8B, 0xEC  ; 04442 mov bp,sp
mov bx,[bp+0x6]  ; 04444
shl bx,1  ; 04447
cmp word [0xf2],0x1  ; 04449
jnz short loc_04458  ; 0444E jnz 0x4458
cmp bx,0xc  ; 04450
jl short loc_04458  ; 04453 jl 0x4458
add bx,0xc  ; 04455
loc_04458:
cmp word [bp+0x4],0x0  ; 04458
jnz short loc_0446D  ; 0445C jnz 0x446d
mov ax,[0xbcd5]  ; 0445E
mov cl,0x61  ; 04461
cmp word [bp+0x6],0x3  ; 04463
jnl short loc_04483  ; 04467 jnl 0x4483
inc cl  ; 04469
jmp short loc_04483  ; 0446B jmp 0x4483
loc_0446D:
mov ax,[0x10e]  ; 0446D
mov cl,0x63  ; 04470
cmp word [0xd5aa],0x0  ; 04472
jz short loc_0447C  ; 04477 jz 0x447c
mov bx,0xe  ; 04479
loc_0447C:
cmp bx,0x12  ; 0447C
jnl short loc_04483  ; 0447F jnl 0x4483
inc cl  ; 04481
loc_04483:
mov si,[0xbb2e]  ; 04483
db 0x8B, 0xFE  ; 04487 mov di,si
add di,0x4  ; 04489
loc_0448C:
mov dl,[si-0x44d0]  ; 0448C
mov [di-0x44d0],dl  ; 04490
dec si  ; 04494
dec di  ; 04495
cmp si,[0xd5b2]  ; 04496
jnc short loc_0448C  ; 0449A jnc 0x448c
inc si  ; 0449C
add ax,[bx-0x1ea2]  ; 0449D
cmp word [0x130],0x7  ; 044A1
jnz short loc_044AB  ; 044A6 jnz 0x44ab
db 0x2D, 0x23, 0x00  ; 044A8 sub ax,0x23
loc_044AB:
mov [si-0x44cf],ax  ; 044AB
mov [si-0x44d0],cl  ; 044AF
shr bx,1  ; 044B3
mov cl,[bx-0x1e7e]  ; 044B5
cmp word [0x130],0x7  ; 044B9
jnz short loc_044C3  ; 044BE jnz 0x44c3
add cl,0x8  ; 044C0
loc_044C3:
mov [si-0x44cd],cl  ; 044C3
add word [0xbb2e],0x4  ; 044C7
add word [0xd5b2],0x4  ; 044CC
pop bp  ; 044D1
ret  ; 044D2

; ---- function check_joystick ----
check_joystick:
call read_joystick  ; 044D3
cmp word [bp+0x4],0x0  ; 044D6
jz short loc_044DD  ; 044DA jz 0x44dd
ret  ; 044DC
loc_044DD:
cmp al,0x0  ; 044DD
jnz short loc_044EF  ; 044DF jnz 0x44ef
cmp word [0x10c],0x40  ; 044E1
jnc short loc_044EB  ; 044E6 jnc 0x44eb
db 0x33, 0xC0  ; 044E8 xor ax,ax
ret  ; 044EA
loc_044EB:
mov ax,0x20  ; 044EB
ret  ; 044EE
loc_044EF:
cmp byte [0xe1ab],0x0  ; 044EF
jz short loc_04500  ; 044F4 jz 0x4500
mov al,[0xe1a1]  ; 044F6
xchg al,[0xe1a2]  ; 044F9
mov [0xe1a1],al  ; 044FD
loc_04500:
cmp byte [0xe1ac],0x0  ; 04500
jz short loc_04511  ; 04505 jz 0x4511
mov al,[0xe1a3]  ; 04507
xchg al,[0xe1a4]  ; 0450A
mov [0xe1a3],al  ; 0450E
loc_04511:
cmp byte [0xe1ad],0x0  ; 04511
jz short loc_0452C  ; 04516 jz 0x452c
mov al,[0xe1a1]  ; 04518
xchg al,[0xe1a3]  ; 0451B
mov [0xe1a1],al  ; 0451F
mov al,[0xe1a2]  ; 04522
xchg al,[0xe1a4]  ; 04525
mov [0xe1a2],al  ; 04529
loc_0452C:
cmp byte [0xe1ae],0x0  ; 0452C
jz short loc_0453D  ; 04531 jz 0x453d
mov al,[0xe1a5]  ; 04533
xchg al,[0xe1a6]  ; 04536
mov [0xe1a5],al  ; 0453A
loc_0453D:
cmp byte [0xe1a2],0x1  ; 0453D
jnz short loc_0456D  ; 04542 jnz 0x456d
cmp byte [0xe1a3],0x1  ; 04544
jnz short loc_0456D  ; 04549 jnz 0x456d
cmp word [0xfa],0x0  ; 0454B
jnz short loc_04569  ; 04550 jnz 0x4569
cmp word [0xd5aa],0x0  ; 04552
jnz short loc_04566  ; 04557 jnz 0x4566
mov dx,[0x10e]  ; 04559
sub dx,[0xbcd5]  ; 0455D
cmp dx,0x64  ; 04561
jnc short loc_04569  ; 04564 jnc 0x4569
loc_04566:
jmp 0x4816  ; 04566
loc_04569:
mov ax,0x26  ; 04569
ret  ; 0456C
loc_0456D:
cmp word [0x10c],0x3f  ; 0456D
jng short loc_0457F  ; 04572 jng 0x457f
cmp byte [0xe1a6],0x1  ; 04574
jnz short loc_0457F  ; 04579 jnz 0x457f
mov ax,0x62  ; 0457B
ret  ; 0457E
loc_0457F:
cmp byte [0xe1a1],0x1  ; 0457F
jnz short loc_0458A  ; 04584 jnz 0x458a
mov ax,0x34  ; 04586
ret  ; 04589
loc_0458A:
cmp byte [0xe1a2],0x1  ; 0458A
jnz short loc_04595  ; 0458F jnz 0x4595
mov ax,0x36  ; 04591
ret  ; 04594
loc_04595:
cmp byte [0xe1a5],0x1  ; 04595
jnz short loc_045B6  ; 0459A jnz 0x45b6
cmp byte [0xe1a3],0x1  ; 0459C
jnz short loc_045A7  ; 045A1 jnz 0x45a7
mov ax,0x77  ; 045A3
ret  ; 045A6
loc_045A7:
cmp byte [0xe1a4],0x1  ; 045A7
jnz short loc_045B2  ; 045AC jnz 0x45b2
mov ax,0x78  ; 045AE
ret  ; 045B1
loc_045B2:
mov ax,0x73  ; 045B2
ret  ; 045B5
loc_045B6:
cmp byte [0xe1a6],0x1  ; 045B6
jnz short loc_045D7  ; 045BB jnz 0x45d7
cmp byte [0xe1a3],0x1  ; 045BD
jnz short loc_045C8  ; 045C2 jnz 0x45c8
mov ax,0x71  ; 045C4
ret  ; 045C7
loc_045C8:
cmp byte [0xe1a4],0x1  ; 045C8
jnz short loc_045D3  ; 045CD jnz 0x45d3
mov ax,0x7a  ; 045CF
ret  ; 045D2
loc_045D3:
mov ax,0x61  ; 045D3
ret  ; 045D6
loc_045D7:
cmp byte [0xe1a3],0x0  ; 045D7
jz short loc_04616  ; 045DC jz 0x4616
cmp word [0x10c],0x41  ; 045DE
jz short loc_04616  ; 045E3 jz 0x4616
cmp word [0x10c],0x42  ; 045E5
jz short loc_04616  ; 045EA jz 0x4616
cmp word [0x10c],0x46  ; 045EC
jnz short loc_045F7  ; 045F1 jnz 0x45f7
mov ax,0x30  ; 045F3
ret  ; 045F6
loc_045F7:
cmp word [0xd5aa],0x0  ; 045F7
jnz short loc_04616  ; 045FC jnz 0x4616
cmp word [0xfa],0x0  ; 045FE
jnz short loc_04612  ; 04603 jnz 0x4612
mov dx,[0x10e]  ; 04605
sub dx,[0xbcd5]  ; 04609
cmp dx,0x64  ; 0460D
jc short loc_04616  ; 04610 jc 0x4616
loc_04612:
mov ax,0x20  ; 04612
ret  ; 04615
loc_04616:
db 0x33, 0xC0  ; 04616 xor ax,ax
ret  ; 04618
