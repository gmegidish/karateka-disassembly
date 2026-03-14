; Figure/animation data loading and setup


; ---- function init_figure ----
init_figure:
push bp  ; 01277
sub sp,0x66  ; 01278
jc short loc_01283  ; 0127B jc 0x1283
cmp sp,[0x17]  ; 0127D
ja short loc_01286  ; 01281 ja 0x1286
loc_01283:
jmp 0x420  ; 01283
loc_01286:
db 0x8B, 0xEC  ; 01286 mov bp,sp
db 0x33, 0xC0  ; 01288 xor ax,ax
mov [bp+0x5e],ax  ; 0128A
mov [bp+0x5a],ax  ; 0128D
loc_01290:
mov ax,0xbc83  ; 01290
push ax  ; 01293
push word [bp+0x6a]  ; 01294
call restore_int_vectors  ; 01297
db 0x8B, 0xE5  ; 0129A mov sp,bp
test ax,ax  ; 0129C
mov [bp+0x64],ax  ; 0129E
jnz short loc_012A8  ; 012A1 jnz 0x12a8
call check_disk_prompt  ; 012A3
jmp short loc_01290  ; 012A6 jmp 0x1290
loc_012A8:
push word [bp+0x64]  ; 012A8
mov ax,0x50  ; 012AB
push ax  ; 012AE
lea ax,[bp+0x2]  ; 012AF
push ax  ; 012B2
call bounds_check  ; 012B3
db 0x8B, 0xE5  ; 012B6 mov sp,bp
test ax,ax  ; 012B8
mov [bp+0x52],ax  ; 012BA
jz short loc_012D5  ; 012BD jz 0x12d5
lea ax,[bp+0x5e]  ; 012BF
push ax  ; 012C2
lea ax,[bp+0x5a]  ; 012C3
push ax  ; 012C6
push word [bp+0x6c]  ; 012C7
lea ax,[bp+0x2]  ; 012CA
push ax  ; 012CD
call setup_figure_data  ; 012CE
db 0x8B, 0xE5  ; 012D1 mov sp,bp
jmp short loc_012A8  ; 012D3 jmp 0x12a8
loc_012D5:
push word [bp+0x64]  ; 012D5
call collision_check  ; 012D8
db 0x8B, 0xE5  ; 012DB mov sp,bp
mov ax,[bp+0x5a]  ; 012DD
mov [0xbd02],ax  ; 012E0
mov ax,[bp+0x5e]  ; 012E3
add sp,0x66  ; 012E6
pop bp  ; 012E9
ret  ; 012EA

; ---- function setup_figure_data ----
setup_figure_data:
push bp  ; 012EB
sub sp,0x12  ; 012EC
jc short loc_012F7  ; 012EF jc 0x12f7
cmp sp,[0x17]  ; 012F1
ja short loc_012FA  ; 012F5 ja 0x12fa
loc_012F7:
jmp 0x420  ; 012F7
loc_012FA:
db 0x8B, 0xEC  ; 012FA mov bp,sp
mov word [bp+0x8],0x0  ; 012FC
loc_01301:
mov si,[bp+0x16]  ; 01301
add si,[bp+0x8]  ; 01304
mov al,[si]  ; 01307
xor ah,ah  ; 01309
db 0x3D, 0x2C, 0x00  ; 0130B cmp ax,0x2c
jz short loc_01315  ; 0130E jz 0x1315
inc word [bp+0x8]  ; 01310
jmp short loc_01301  ; 01313 jmp 0x1301
loc_01315:
mov si,[bp+0x16]  ; 01315
add si,[bp+0x8]  ; 01318
mov byte [si],0x0  ; 0131B
mov word [bp+0xa],0x0  ; 0131E
loc_01323:
mov ax,[bp+0xa]  ; 01323
db 0x3D, 0x0E, 0x00  ; 01326 cmp ax,0xe
jnl short loc_0134D  ; 01329 jnl 0x134d
shl ax,1  ; 0132B
db 0x8B, 0xF0  ; 0132D mov si,ax
mov ax,0x5  ; 0132F
push ax  ; 01332
push word [si+0x1e8]  ; 01333
push word [bp+0x16]  ; 01337
call strncmp  ; 0133A
db 0x8B, 0xE5  ; 0133D mov sp,bp
mov [bp+0x10],al  ; 0133F
xor ah,ah  ; 01342
test ax,ax  ; 01344
jz short loc_0134D  ; 01346 jz 0x134d
inc word [bp+0xa]  ; 01348
jmp short loc_01323  ; 0134B jmp 0x1323
loc_0134D:
mov al,[bp+0x10]  ; 0134D
xor ah,ah  ; 01350
test ax,ax  ; 01352
jz short loc_0135E  ; 01354 jz 0x135e
mov si,[bp+0x1c]  ; 01356
inc word [si]  ; 01359
jmp 0x1868  ; 0135B
loc_0135E:
mov ax,[bp+0xa]  ; 0135E
jmp 0x185a  ; 01361
mov si,[bp+0x1a]  ; 01364
mov ax,[si]  ; 01367
mov [bp+0x0],ax  ; 01369
inc ax  ; 0136C
mov [si],ax  ; 0136D
mov bx,[bp+0x18]  ; 0136F
mov si,[bp+0x0]  ; 01372
db 0x03, 0xF3  ; 01375 add si,bx
mov byte [si],0x0  ; 01377
mov cx,[bp+0x8]  ; 0137A
inc cx  ; 0137D
mov dx,[bp+0x16]  ; 0137E
db 0x03, 0xD1  ; 01381 add dx,cx
mov si,[bp+0x1a]  ; 01383
inc word [si]  ; 01386
db 0x03, 0xD8  ; 01388 add bx,ax
push bx  ; 0138A
mov ax,0xbc85  ; 0138B
push ax  ; 0138E
push dx  ; 0138F
call scanf_format_parser  ; 01390
db 0x8B, 0xE5  ; 01393 mov sp,bp
jmp 0x1868  ; 01395
mov si,[bp+0x1a]  ; 01398
mov ax,[si]  ; 0139B
mov [bp+0x0],ax  ; 0139D
inc ax  ; 013A0
mov [si],ax  ; 013A1
mov bx,[bp+0x18]  ; 013A3
mov si,[bp+0x0]  ; 013A6
db 0x03, 0xF3  ; 013A9 add si,bx
mov byte [si],0x2  ; 013AB
mov cx,[bp+0x8]  ; 013AE
inc cx  ; 013B1
mov dx,[bp+0x16]  ; 013B2
db 0x03, 0xD1  ; 013B5 add dx,cx
mov si,[bp+0x1a]  ; 013B7
inc word [si]  ; 013BA
db 0x03, 0xD8  ; 013BC add bx,ax
push bx  ; 013BE
mov ax,0xbc85  ; 013BF
push ax  ; 013C2
push dx  ; 013C3
call scanf_format_parser  ; 013C4
db 0x8B, 0xE5  ; 013C7 mov sp,bp
jmp 0x1868  ; 013C9
mov si,[bp+0x1a]  ; 013CC
mov ax,[si]  ; 013CF
mov [bp+0x0],ax  ; 013D1
inc ax  ; 013D4
mov [si],ax  ; 013D5
mov bx,[bp+0x18]  ; 013D7
mov si,[bp+0x0]  ; 013DA
db 0x03, 0xF3  ; 013DD add si,bx
mov byte [si],0x4  ; 013DF
mov cx,[bp+0x8]  ; 013E2
inc cx  ; 013E5
mov dx,[bp+0x16]  ; 013E6
db 0x03, 0xD1  ; 013E9 add dx,cx
mov si,[bp+0x1a]  ; 013EB
inc word [si]  ; 013EE
db 0x03, 0xD8  ; 013F0 add bx,ax
lea ax,[bp+0xe]  ; 013F2
push ax  ; 013F5
lea ax,[bp+0xc]  ; 013F6
push ax  ; 013F9
push bx  ; 013FA
mov ax,0xbc88  ; 013FB
push ax  ; 013FE
push dx  ; 013FF
call scanf_format_parser  ; 01400
db 0x8B, 0xE5  ; 01403 mov sp,bp
mov si,[bp+0x1a]  ; 01405
mov ax,[si]  ; 01408
mov [bp+0x0],ax  ; 0140A
inc ax  ; 0140D
mov [si],ax  ; 0140E
mov bx,[bp+0x18]  ; 01410
mov si,[bp+0x0]  ; 01413
db 0x03, 0xF3  ; 01416 add si,bx
mov cx,[bp+0xc]  ; 01418
and cx,0xff  ; 0141B
mov [si],cl  ; 0141F
mov [bp+0x0],ax  ; 01421
inc ax  ; 01424
mov si,[bp+0x1a]  ; 01425
mov [si],ax  ; 01428
mov si,[bp+0x0]  ; 0142A
db 0x03, 0xF3  ; 0142D add si,bx
mov cl,0x8  ; 0142F
mov dx,[bp+0xc]  ; 01431
sar dx,cl  ; 01434
mov [si],dl  ; 01436
mov si,[bp+0x1a]  ; 01438
inc word [si]  ; 0143B
db 0x03, 0xD8  ; 0143D add bx,ax
mov ax,[bp+0xe]  ; 0143F
mov [bx],al  ; 01442
jmp 0x1868  ; 01444
mov si,[bp+0x1a]  ; 01447
mov ax,[si]  ; 0144A
mov [bp+0x0],ax  ; 0144C
inc ax  ; 0144F
mov [si],ax  ; 01450
mov bx,[bp+0x18]  ; 01452
mov si,[bp+0x0]  ; 01455
db 0x03, 0xF3  ; 01458 add si,bx
mov byte [si],0x6  ; 0145A
mov cx,[bp+0x8]  ; 0145D
inc cx  ; 01460
mov dx,[bp+0x16]  ; 01461
db 0x03, 0xD1  ; 01464 add dx,cx
mov [bp+0x2],ax  ; 01466
inc ax  ; 01469
mov si,[bp+0x1a]  ; 0146A
mov [si],ax  ; 0146D
mov cx,[bp+0x2]  ; 0146F
db 0x03, 0xCB  ; 01472 add cx,bx
inc word [si]  ; 01474
db 0x03, 0xD8  ; 01476 add bx,ax
lea ax,[bp+0xe]  ; 01478
push ax  ; 0147B
lea ax,[bp+0xc]  ; 0147C
push ax  ; 0147F
push bx  ; 01480
push cx  ; 01481
mov ax,0xbc91  ; 01482
push ax  ; 01485
push dx  ; 01486
call scanf_format_parser  ; 01487
db 0x8B, 0xE5  ; 0148A mov sp,bp
mov si,[bp+0x1a]  ; 0148C
mov ax,[si]  ; 0148F
mov [bp+0x0],ax  ; 01491
inc ax  ; 01494
mov [si],ax  ; 01495
mov bx,[bp+0x18]  ; 01497
mov si,[bp+0x0]  ; 0149A
db 0x03, 0xF3  ; 0149D add si,bx
mov cx,[bp+0xc]  ; 0149F
and cx,0xff  ; 014A2
mov [si],cl  ; 014A6
mov [bp+0x0],ax  ; 014A8
inc ax  ; 014AB
mov si,[bp+0x1a]  ; 014AC
mov [si],ax  ; 014AF
mov si,[bp+0x0]  ; 014B1
db 0x03, 0xF3  ; 014B4 add si,bx
mov cl,0x8  ; 014B6
mov dx,[bp+0xc]  ; 014B8
sar dx,cl  ; 014BB
mov [si],dl  ; 014BD
mov si,[bp+0x1a]  ; 014BF
inc word [si]  ; 014C2
db 0x03, 0xD8  ; 014C4 add bx,ax
mov ax,[bp+0xe]  ; 014C6
mov [bx],al  ; 014C9
jmp 0x1868  ; 014CB
mov si,[bp+0x1a]  ; 014CE
mov ax,[si]  ; 014D1
inc word [si]  ; 014D3
mov si,[bp+0x18]  ; 014D5
db 0x03, 0xF0  ; 014D8 add si,ax
mov byte [si],0x8  ; 014DA
jmp 0x1868  ; 014DD
mov si,[bp+0x1a]  ; 014E0
mov ax,[si]  ; 014E3
mov [bp+0x0],ax  ; 014E5
inc ax  ; 014E8
mov [si],ax  ; 014E9
mov bx,[bp+0x18]  ; 014EB
mov si,[bp+0x0]  ; 014EE
db 0x03, 0xF3  ; 014F1 add si,bx
mov byte [si],0xa  ; 014F3
mov cx,[bp+0x8]  ; 014F6
inc cx  ; 014F9
mov dx,[bp+0x16]  ; 014FA
db 0x03, 0xD1  ; 014FD add dx,cx
mov si,[bp+0x1a]  ; 014FF
inc word [si]  ; 01502
db 0x03, 0xD8  ; 01504 add bx,ax
push bx  ; 01506
mov ax,0xbc85  ; 01507
push ax  ; 0150A
push dx  ; 0150B
call scanf_format_parser  ; 0150C
db 0x8B, 0xE5  ; 0150F mov sp,bp
jmp 0x1868  ; 01511
mov si,[bp+0x1a]  ; 01514
mov ax,[si]  ; 01517
inc word [si]  ; 01519
mov si,[bp+0x18]  ; 0151B
db 0x03, 0xF0  ; 0151E add si,ax
mov byte [si],0xc  ; 01520
jmp 0x1868  ; 01523
mov si,[bp+0x1a]  ; 01526
mov ax,[si]  ; 01529
inc word [si]  ; 0152B
mov si,[bp+0x18]  ; 0152D
db 0x03, 0xF0  ; 01530 add si,ax
mov byte [si],0xe  ; 01532
jmp 0x1868  ; 01535
mov si,[bp+0x1a]  ; 01538
mov ax,[si]  ; 0153B
mov [bp+0x0],ax  ; 0153D
inc ax  ; 01540
mov [si],ax  ; 01541
mov bx,[bp+0x18]  ; 01543
mov si,[bp+0x0]  ; 01546
db 0x03, 0xF3  ; 01549 add si,bx
mov byte [si],0x10  ; 0154B
mov cx,[bp+0x8]  ; 0154E
inc cx  ; 01551
mov dx,[bp+0x16]  ; 01552
db 0x03, 0xD1  ; 01555 add dx,cx
mov si,[bp+0x1a]  ; 01557
inc word [si]  ; 0155A
db 0x03, 0xD8  ; 0155C add bx,ax
push bx  ; 0155E
mov ax,0xbc85  ; 0155F
push ax  ; 01562
push dx  ; 01563
call scanf_format_parser  ; 01564
db 0x8B, 0xE5  ; 01567 mov sp,bp
jmp 0x1868  ; 01569
mov si,[bp+0x1a]  ; 0156C
mov ax,[si]  ; 0156F
inc word [si]  ; 01571
mov si,[bp+0x18]  ; 01573
db 0x03, 0xF0  ; 01576 add si,ax
mov byte [si],0x12  ; 01578
jmp 0x1868  ; 0157B
mov si,[bp+0x1a]  ; 0157E
mov ax,[si]  ; 01581
mov [bp+0x0],ax  ; 01583
inc ax  ; 01586
mov [si],ax  ; 01587
mov bx,[bp+0x18]  ; 01589
mov si,[bp+0x0]  ; 0158C
db 0x03, 0xF3  ; 0158F add si,bx
mov byte [si],0x14  ; 01591
mov cx,[bp+0x8]  ; 01594
inc cx  ; 01597
mov dx,[bp+0x16]  ; 01598
db 0x03, 0xD1  ; 0159B add dx,cx
mov [bp+0x2],ax  ; 0159D
inc ax  ; 015A0
mov si,[bp+0x1a]  ; 015A1
mov [si],ax  ; 015A4
mov cx,[bp+0x2]  ; 015A6
db 0x03, 0xCB  ; 015A9 add cx,bx
inc word [si]  ; 015AB
db 0x03, 0xD8  ; 015AD add bx,ax
push bx  ; 015AF
push cx  ; 015B0
mov ax,0xbc9d  ; 015B1
push ax  ; 015B4
push dx  ; 015B5
call scanf_format_parser  ; 015B6
db 0x8B, 0xE5  ; 015B9 mov sp,bp
jmp 0x1868  ; 015BB
mov si,[bp+0x1a]  ; 015BE
mov ax,[si]  ; 015C1
inc word [si]  ; 015C3
mov si,[bp+0x18]  ; 015C5
db 0x03, 0xF0  ; 015C8 add si,ax
mov byte [si],0x16  ; 015CA
mov ax,[bp+0x8]  ; 015CD
inc ax  ; 015D0
mov bx,[bp+0x16]  ; 015D1
db 0x03, 0xD8  ; 015D4 add bx,ax
lea ax,[bp+0xc]  ; 015D6
push ax  ; 015D9
mov ax,0xbc85  ; 015DA
push ax  ; 015DD
push bx  ; 015DE
call scanf_format_parser  ; 015DF
db 0x8B, 0xE5  ; 015E2 mov sp,bp
mov si,[bp+0x1a]  ; 015E4
mov ax,[si]  ; 015E7
inc word [si]  ; 015E9
mov si,[bp+0x18]  ; 015EB
db 0x03, 0xF0  ; 015EE add si,ax
mov ax,[bp+0xc]  ; 015F0
and ax,0xff  ; 015F3
mov [si],al  ; 015F6
jmp short loc_01668  ; 015F8 jmp 0x1668
mov si,[bp+0x1a]  ; 015FA
mov ax,[si]  ; 015FD
mov [bp+0x0],ax  ; 015FF
inc ax  ; 01602
mov [si],ax  ; 01603
mov bx,[bp+0x18]  ; 01605
mov si,[bp+0x0]  ; 01608
db 0x03, 0xF3  ; 0160B add si,bx
mov byte [si],0x18  ; 0160D
mov cx,[bp+0x8]  ; 01610
inc cx  ; 01613
mov dx,[bp+0x16]  ; 01614
db 0x03, 0xD1  ; 01617 add dx,cx
mov si,[bp+0x1a]  ; 01619
inc word [si]  ; 0161C
db 0x03, 0xD8  ; 0161E add bx,ax
push bx  ; 01620
mov ax,0xbc85  ; 01621
push ax  ; 01624
push dx  ; 01625
call scanf_format_parser  ; 01626
db 0x8B, 0xE5  ; 01629 mov sp,bp
jmp short loc_01668  ; 0162B jmp 0x1668
mov si,[bp+0x1a]  ; 0162D
mov ax,[si]  ; 01630
inc word [si]  ; 01632
mov si,[bp+0x18]  ; 01634
db 0x03, 0xF0  ; 01637 add si,ax
mov byte [si],0xff  ; 01639
jmp short loc_01668  ; 0163C jmp 0x1668
adc bx,[fs:bx+si-0x33ed]  ; 0163E
adc ax,[bx+0x14]  ; 01643
into  ; 01646
adc al,0xe0  ; 01647
adc al,0x14  ; 01649
adc ax,0x1526  ; 0164B
cmp [di],dl  ; 0164E
insb  ; 01650
adc ax,0x157e  ; 01651
mov si,0xfa15  ; 01654
adc ax,0x162d  ; 01657
db 0x8B, 0xF0  ; 0165A mov si,ax
cmp si,0xe  ; 0165C
jnc short loc_01668  ; 0165F jnc 0x1668
shl si,1  ; 01661
jmp word near [cs:si+0x163e]  ; 01663
loc_01668:
add sp,0x12  ; 01668
pop bp  ; 0166B
ret  ; 0166C
