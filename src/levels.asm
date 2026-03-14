; Level setup, cutscenes, scene transitions


; ---- function level_setup ----
level_setup:
push bp  ; 02BDD
sub sp,0x8  ; 02BDE
jc short loc_02BE9  ; 02BE1 jc 0x2be9
cmp sp,[0x17]  ; 02BE3
ja short loc_02BEC  ; 02BE7 ja 0x2bec
loc_02BE9:
jmp 0x420  ; 02BE9
loc_02BEC:
db 0x8B, 0xEC  ; 02BEC mov bp,sp
cmp word [0xf8],0x0  ; 02BEE
jng short loc_02BFC  ; 02BF3 jng 0x2bfc
db 0x33, 0xC0  ; 02BF5 xor ax,ax
add sp,0x8  ; 02BF7
pop bp  ; 02BFA
ret  ; 02BFB
loc_02BFC:
mov ax,[0x10e]  ; 02BFC
sub ax,[0xbcd5]  ; 02BFF
cmp word [0xec],0x1  ; 02C03
mov [bp+0x4],ax  ; 02C08
jz short loc_02C10  ; 02C0B jz 0x2c10
jmp 0x2fb0  ; 02C0D
loc_02C10:
cmp word [0xd5aa],0x1  ; 02C10
jnz short loc_02C85  ; 02C15 jnz 0x2c85
cmp word [0x110],0x1f  ; 02C17
jz short loc_02C21  ; 02C1C jz 0x2c21
jmp 0x2fb0  ; 02C1E
loc_02C21:
db 0x3D, 0x13, 0x00  ; 02C21 cmp ax,0x13
jg short loc_02C29  ; 02C24 jg 0x2c29
jmp 0x2fb0  ; 02C26
loc_02C29:
db 0x3D, 0x1C, 0x00  ; 02C29 cmp ax,0x1c
jl short loc_02C31  ; 02C2C jl 0x2c31
jmp 0x2fb0  ; 02C2E
loc_02C31:
mov ax,[0x10c]  ; 02C31
db 0x3D, 0x04, 0x00  ; 02C34 cmp ax,0x4
jz short loc_02C3E  ; 02C37 jz 0x2c3e
db 0x3D, 0x07, 0x00  ; 02C39 cmp ax,0x7
jnz short loc_02C4B  ; 02C3C jnz 0x2c4b
loc_02C3E:
cmp word [0xd5ac],0x18  ; 02C3E
jnz short loc_02C4B  ; 02C43 jnz 0x2c4b
call anim_set_figure  ; 02C45
jmp 0x2fb0  ; 02C48
loc_02C4B:
mov ax,[0x10c]  ; 02C4B
db 0x3D, 0x03, 0x00  ; 02C4E cmp ax,0x3
jz short loc_02C58  ; 02C51 jz 0x2c58
db 0x3D, 0x06, 0x00  ; 02C53 cmp ax,0x6
jnz short loc_02C65  ; 02C56 jnz 0x2c65
loc_02C58:
cmp word [0xd5ac],0xc  ; 02C58
jnz short loc_02C65  ; 02C5D jnz 0x2c65
call anim_set_figure  ; 02C5F
jmp 0x2fb0  ; 02C62
loc_02C65:
mov ax,[0x10c]  ; 02C65
db 0x3D, 0x02, 0x00  ; 02C68 cmp ax,0x2
jz short loc_02C75  ; 02C6B jz 0x2c75
db 0x3D, 0x05, 0x00  ; 02C6D cmp ax,0x5
jz short loc_02C75  ; 02C70 jz 0x2c75
jmp 0x2fb0  ; 02C72
loc_02C75:
cmp word [0xd5ac],0x0  ; 02C75
jz short loc_02C7F  ; 02C7A jz 0x2c7f
jmp 0x2fb0  ; 02C7C
loc_02C7F:
call anim_set_figure  ; 02C7F
jmp 0x2fb0  ; 02C82
loc_02C85:
cmp word [0xfa],0x0  ; 02C85
jng short loc_02CFB  ; 02C8A jng 0x2cfb
cmp word [0x12e],0x0  ; 02C8C
jz short loc_02C96  ; 02C91 jz 0x2c96
jmp 0x2fb0  ; 02C93
loc_02C96:
cmp word [0xbcd5],0xec  ; 02C96
jg short loc_02CA1  ; 02C9C jg 0x2ca1
jmp 0x2fb0  ; 02C9E
loc_02CA1:
cmp word [0xea],0x2  ; 02CA1
jg short loc_02CAB  ; 02CA6 jg 0x2cab
jmp 0x2fb0  ; 02CA8
loc_02CAB:
cmp word [0x10c],0x5  ; 02CAB
jnl short loc_02CBB  ; 02CB0 jnl 0x2cbb
mov word [0x154],0x1  ; 02CB2
jmp 0x2fb0  ; 02CB8
loc_02CBB:
call anim_set_bg  ; 02CBB
mov ax,[0x10c]  ; 02CBE
dec ax  ; 02CC1
dec ax  ; 02CC2
push ax  ; 02CC3
db 0x33, 0xC0  ; 02CC4 xor ax,ax
push ax  ; 02CC6
call update_position  ; 02CC7
db 0x8B, 0xE5  ; 02CCA mov sp,bp
cmp word [0x130],0x5  ; 02CCC
jz short loc_02CD6  ; 02CD1 jz 0x2cd6
jmp 0x2fb0  ; 02CD3
loc_02CD6:
call effect_scroll_right  ; 02CD6
mov word [0x114],0x5  ; 02CD9
mov ax,[0x122]  ; 02CDF
mov bx,[0x104]  ; 02CE2
add bx,0x10  ; 02CE6
mov cx,[0xc3ec]  ; 02CE9
mov [0x120],ax  ; 02CED
mov [0xc3d2],cx  ; 02CF0
mov [0x10e],bx  ; 02CF4
jmp 0x2fb0  ; 02CF8
loc_02CFB:
mov ax,[0x10c]  ; 02CFB
dec ax  ; 02CFE
dec ax  ; 02CFF
push word [0xd5b0]  ; 02D00
push word [bp+0x4]  ; 02D04
push ax  ; 02D07
call apply_gravity  ; 02D08
db 0x8B, 0xE5  ; 02D0B mov sp,bp
db 0x3D, 0x04, 0x00  ; 02D0D cmp ax,0x4
mov [bp+0x6],ax  ; 02D10
jnz short loc_02D22  ; 02D13 jnz 0x2d22
cmp word [0x130],0x6  ; 02D15
jz short loc_02D22  ; 02D1A jz 0x2d22
mov ax,[0xcdfa]  ; 02D1C
mov [0xcde8],ax  ; 02D1F
loc_02D22:
mov ax,[bp+0x6]  ; 02D22
db 0x3D, 0x02, 0x00  ; 02D25 cmp ax,0x2
jz short loc_02D32  ; 02D28 jz 0x2d32
db 0x3D, 0x03, 0x00  ; 02D2A cmp ax,0x3
jz short loc_02D32  ; 02D2D jz 0x2d32
jmp 0x2fb0  ; 02D2F
loc_02D32:
mov ax,0x1  ; 02D32
mov bx,[0x114]  ; 02D35
dec bx  ; 02D39
test bx,bx  ; 02D3A
mov [0x154],ax  ; 02D3C
mov [0x114],bx  ; 02D3F
jnz short loc_02D79  ; 02D43 jnz 0x2d79
mov word [0x154],0x2  ; 02D45
mov word [0x11e],0x0  ; 02D4B
cmp word [0xf2],0x1  ; 02D51
mov [0x174],ax  ; 02D56
mov [0xfa],ax  ; 02D59
jnz short loc_02D61  ; 02D5C jnz 0x2d61
mov [0x170],ax  ; 02D5E
loc_02D61:
cmp word [0x124],0x0  ; 02D61
jng short loc_02D71  ; 02D66 jng 0x2d71
mov ax,0x2  ; 02D68
mov [0x126],ax  ; 02D6B
mov [0x120],ax  ; 02D6E
loc_02D71:
mov ax,[0xce22]  ; 02D71
mov [0xcde8],ax  ; 02D74
jmp short loc_02DA2  ; 02D77 jmp 0x2da2
loc_02D79:
mov ax,[0x110]  ; 02D79
db 0x3D, 0x0B, 0x00  ; 02D7C cmp ax,0xb
jng short loc_02D93  ; 02D7F jng 0x2d93
db 0x3D, 0x12, 0x00  ; 02D81 cmp ax,0x12
jnl short loc_02D93  ; 02D84 jnl 0x2d93
cmp word [0x130],0x6  ; 02D86
jz short loc_02D93  ; 02D8B jz 0x2d93
mov ax,[0xcdfa]  ; 02D8D
mov [0xcde8],ax  ; 02D90
loc_02D93:
add word [0x128],0x3  ; 02D93
inc word [0x11e]  ; 02D98
mov word [0xfe],0x1  ; 02D9C
loc_02DA2:
mov ax,[0x10c]  ; 02DA2
dec ax  ; 02DA5
dec ax  ; 02DA6
push ax  ; 02DA7
db 0x33, 0xC0  ; 02DA8 xor ax,ax
push ax  ; 02DAA
call update_position  ; 02DAB
db 0x8B, 0xE5  ; 02DAE mov sp,bp
mov ax,[0x11e]  ; 02DB0
test ax,ax  ; 02DB3
jng short loc_02DE1  ; 02DB5 jng 0x2de1
mov bx,[0x114]  ; 02DB7
mov cx,[0x116]  ; 02DBB
db 0x03, 0xCB  ; 02DBF add cx,bx
cmp cx,0x1a  ; 02DC1
jnl short loc_02DE1  ; 02DC4 jnl 0x2de1
mov cx,[0x128]  ; 02DC6
dec cx  ; 02DCA
test cx,cx  ; 02DCB
mov [0x128],cx  ; 02DCD
jnz short loc_02DE1  ; 02DD1 jnz 0x2de1
inc word [0x114]  ; 02DD3
dec word [0x11e]  ; 02DD7
mov ax,[0x11c]  ; 02DDB
mov [0x128],ax  ; 02DDE
loc_02DE1:
cmp word [0x112],0x1  ; 02DE1
jz short loc_02DEB  ; 02DE6 jz 0x2deb
jmp 0x30df  ; 02DE8
loc_02DEB:
cmp word [0x130],0x7  ; 02DEB
jnz short loc_02DFF  ; 02DF0 jnz 0x2dff
mov word [0x116],0x1  ; 02DF2
mov word [bp+0x6],0x3  ; 02DF8
jmp short loc_02E39  ; 02DFD jmp 0x2e39
loc_02DFF:
mov ax,[0x110]  ; 02DFF
db 0x3D, 0x21, 0x00  ; 02E02 cmp ax,0x21
jz short loc_02E39  ; 02E05 jz 0x2e39
db 0x3D, 0x07, 0x00  ; 02E07 cmp ax,0x7
jnz short loc_02E10  ; 02E0A jnz 0x2e10
sub word [bp+0x4],0x4  ; 02E0C
loc_02E10:
mov ax,[0x110]  ; 02E10
dec ax  ; 02E13
dec ax  ; 02E14
push word [0xd5ae]  ; 02E15
push word [bp+0x4]  ; 02E19
push ax  ; 02E1C
call apply_gravity  ; 02E1D
db 0x8B, 0xE5  ; 02E20 mov sp,bp
db 0x3D, 0x04, 0x00  ; 02E22 cmp ax,0x4
mov [bp+0x6],ax  ; 02E25
jnz short loc_02E39  ; 02E28 jnz 0x2e39
mov ax,[0xbcd5]  ; 02E2A
cmp ax,[0x102]  ; 02E2D
jng short loc_02E39  ; 02E31 jng 0x2e39
mov ax,[0xc3e2]  ; 02E33
mov [0xc3d2],ax  ; 02E36
loc_02E39:
cmp word [0x110],0x21  ; 02E39
jz short loc_02E56  ; 02E3E jz 0x2e56
cmp word [bp+0x6],0x2  ; 02E40
jz short loc_02E56  ; 02E44 jz 0x2e56
cmp word [bp+0x6],0x3  ; 02E46
jz short loc_02E56  ; 02E4A jz 0x2e56
cmp word [0x10c],0x3f  ; 02E4C
jg short loc_02E56  ; 02E51 jg 0x2e56
jmp 0x30df  ; 02E53
loc_02E56:
cmp word [0x154],0x0  ; 02E56
jnz short loc_02E63  ; 02E5B jnz 0x2e63
mov word [0x154],0x1  ; 02E5D
loc_02E63:
mov ax,[0x116]  ; 02E63
dec ax  ; 02E66
test ax,ax  ; 02E67
mov [0x116],ax  ; 02E69
jz short loc_02E75  ; 02E6C jz 0x2e75
cmp word [0x10c],0x3f  ; 02E6E
jng short loc_02E90  ; 02E73 jng 0x2e90
loc_02E75:
cmp word [0x10c],0x44  ; 02E75
jz short loc_02E90  ; 02E7A jz 0x2e90
mov word [0xf8],0x1  ; 02E7C
mov ax,[0xc40c]  ; 02E82
mov word [0x10c],0x44  ; 02E85
mov [0xc3d2],ax  ; 02E8B
jmp short loc_02EB9  ; 02E8E jmp 0x2eb9
loc_02E90:
mov ax,[0x10c]  ; 02E90
db 0x3D, 0x0E, 0x00  ; 02E93 cmp ax,0xe
jng short loc_02E9D  ; 02E96 jng 0x2e9d
db 0x3D, 0x12, 0x00  ; 02E98 cmp ax,0x12
jl short loc_02EA4  ; 02E9B jl 0x2ea4
loc_02E9D:
cmp word [0x110],0x21  ; 02E9D
jnz short loc_02EAA  ; 02EA2 jnz 0x2eaa
loc_02EA4:
mov ax,[0xc3e2]  ; 02EA4
mov [0xc3d2],ax  ; 02EA7
loc_02EAA:
add word [0x126],0x3  ; 02EAA
inc word [0x124]  ; 02EAF
mov word [0xfc],0x1  ; 02EB3
loc_02EB9:
cmp word [0x130],0x7  ; 02EB9
jnz short loc_02ECF  ; 02EBE jnz 0x2ecf
mov ax,0x9  ; 02EC0
push ax  ; 02EC3
mov ax,0x1  ; 02EC4
push ax  ; 02EC7
call update_position  ; 02EC8
db 0x8B, 0xE5  ; 02ECB mov sp,bp
jmp short loc_02EDF  ; 02ECD jmp 0x2edf
loc_02ECF:
mov ax,[0x110]  ; 02ECF
db 0x05, 0x04, 0x00  ; 02ED2 add ax,0x4
push ax  ; 02ED5
mov ax,0x1  ; 02ED6
push ax  ; 02ED9
call update_position  ; 02EDA
db 0x8B, 0xE5  ; 02EDD mov sp,bp
loc_02EDF:
cmp word [0xf8],0x0  ; 02EDF
jng short loc_02EED  ; 02EE4 jng 0x2eed
db 0x33, 0xC0  ; 02EE6 xor ax,ax
add sp,0x8  ; 02EE8
pop bp  ; 02EEB
ret  ; 02EEC
loc_02EED:
mov ax,[0x124]  ; 02EED
test ax,ax  ; 02EF0
jng short loc_02F28  ; 02EF2 jng 0x2f28
mov bx,[0x116]  ; 02EF4
mov cx,[0x114]  ; 02EF8
db 0x03, 0xCB  ; 02EFC add cx,bx
cmp cx,0x1a  ; 02EFE
jnl short loc_02F28  ; 02F01 jnl 0x2f28
mov cx,[0x126]  ; 02F03
dec cx  ; 02F07
test cx,cx  ; 02F08
mov [0x126],cx  ; 02F0A
jnz short loc_02F28  ; 02F0E jnz 0x2f28
inc word [0x116]  ; 02F10
dec ax  ; 02F14
test ax,ax  ; 02F15
mov [0x124],ax  ; 02F17
jnz short loc_02F22  ; 02F1A jnz 0x2f22
mov ax,[0x122]  ; 02F1C
mov [0x120],ax  ; 02F1F
loc_02F22:
mov ax,[0x120]  ; 02F22
mov [0x126],ax  ; 02F25
loc_02F28:
add sp,0x8  ; 02F28
pop bp  ; 02F2B
ret  ; 02F2C

; ---- function anim_set_bg ----
anim_set_bg:
push bp  ; 02F2D
sub sp,0x4  ; 02F2E
jc short loc_02F39  ; 02F31 jc 0x2f39
cmp sp,[0x17]  ; 02F33
ja short loc_02F3C  ; 02F37 ja 0x2f3c
loc_02F39:
jmp 0x420  ; 02F39
loc_02F3C:
db 0x8B, 0xEC  ; 02F3C mov bp,sp
add word [0x104],0x14  ; 02F3E
mov ax,[0x130]  ; 02F43
shl ax,1  ; 02F46
db 0x8B, 0xF0  ; 02F48 mov si,ax
mov ax,0x1  ; 02F4A
mov [si+0x142],ax  ; 02F4D
mov bx,[0xc3a6]  ; 02F51
inc bx  ; 02F55
mov [0xc3a6],bx  ; 02F56
shl bx,1  ; 02F5A
mov cx,[bx-0x3c4a]  ; 02F5C
mov bx,[0xc3a6]  ; 02F60
shl bx,1  ; 02F64
mov dx,[bx-0x3c58]  ; 02F66
mov [0x12e],ax  ; 02F6A
mov ax,[bx-0x3c3c]  ; 02F6D
mov word [0x154],0x1  ; 02F71
mov word [0xee],0x2  ; 02F77
mov bx,0xffff  ; 02F7D
mov [0xc3a4],ax  ; 02F80
mov [0xc3a2],cx  ; 02F83
mov [0xc3a0],dx  ; 02F87
mov [0xd652],bx  ; 02F8B
mov [0xbb2a],bx  ; 02F8F
add sp,0x4  ; 02F93
pop bp  ; 02F96
ret  ; 02F97

; ---- function anim_set_figure ----
anim_set_figure:
push bp  ; 02F98
sub sp,0x2  ; 02F99
jc short loc_02FA4  ; 02F9C jc 0x2fa4
cmp sp,[0x17]  ; 02F9E
ja short loc_02FA7  ; 02FA2 ja 0x2fa7
loc_02FA4:
jmp 0x420  ; 02FA4
loc_02FA7:
db 0x8B, 0xEC  ; 02FA7 mov bp,sp
mov ax,0x3  ; 02FA9
cmp word [0xea],0x3  ; 02FAC
mov [0x154],ax  ; 02FB1
jnz short loc_03003  ; 02FB4 jnz 0x3003
mov ax,[0x114]  ; 02FB6
dec ax  ; 02FB9
test ax,ax  ; 02FBA
mov [0x114],ax  ; 02FBC
jnz short loc_02FFB  ; 02FBF jnz 0x2ffb
mov word [0x154],0x4  ; 02FC1
mov ax,[0xce2e]  ; 02FC7
cmp word [0xd5ac],0x0  ; 02FCA
mov [0xcde8],ax  ; 02FCF
jnz short loc_02FDA  ; 02FD2 jnz 0x2fda
mov word [0xd5ac],0xc  ; 02FD4
loc_02FDA:
cmp word [0x116],0xa  ; 02FDA
jng short loc_02FEF  ; 02FDF jng 0x2fef
mov word [0x116],0xa  ; 02FE1
mov word [0x124],0x0  ; 02FE7
jmp short loc_03009  ; 02FED jmp 0x3009
loc_02FEF:
mov ax,0xa  ; 02FEF
sub ax,[0x116]  ; 02FF2
mov [0x124],ax  ; 02FF6
jmp short loc_03009  ; 02FF9 jmp 0x3009
loc_02FFB:
mov word [0xfe],0x1  ; 02FFB
jmp short loc_03009  ; 03001 jmp 0x3009
loc_03003:
mov word [0xfe],0x1  ; 03003
loc_03009:
mov ax,[0x10c]  ; 03009
dec ax  ; 0300C
dec ax  ; 0300D
push ax  ; 0300E
db 0x33, 0xC0  ; 0300F xor ax,ax
push ax  ; 03011
call update_position  ; 03012
db 0x8B, 0xE5  ; 03015 mov sp,bp
add sp,0x2  ; 03017
pop bp  ; 0301A
ret  ; 0301B

; ---- function scene_transition ----
scene_transition:
cmp word [0xf8],0x0  ; 0301C
jz short loc_03029  ; 03021 jz 0x3029
mov word [0x116],0x0  ; 03023
loc_03029:
push word [0x116]  ; 03029
push word [0x114]  ; 0302D
cmp word [0x170],0x0  ; 03031
jz short loc_0303E  ; 03036 jz 0x303e
mov word [0x116],0x0  ; 03038
loc_0303E:
cmp word [0x118],0x0  ; 0303E
jz short loc_0304E  ; 03043 jz 0x304e
mov word [0x114],0x0  ; 03045
jmp short loc_030CA  ; 0304B jmp 0x30ca
nop  ; 0304D
loc_0304E:
cmp word [0x11a],0x0  ; 0304E
jz short loc_0305E  ; 03053 jz 0x305e
mov word [0x116],0x0  ; 03055
jmp short loc_030CA  ; 0305B jmp 0x30ca
nop  ; 0305D
loc_0305E:
mov ax,[0x116]  ; 0305E
sub ax,[0xd652]  ; 03061
db 0x3D, 0x01, 0x00  ; 03065 cmp ax,0x1
jz short loc_0308F  ; 03068 jz 0x308f
jg short loc_030CA  ; 0306A jg 0x30ca
db 0x3D, 0xFF, 0xFF  ; 0306C cmp ax,0xffff
jmp short loc_030CA  ; 0306F jmp 0x30ca
nop  ; 03071
jl short loc_030CA  ; 03072 jl 0x30ca
jnz short loc_03096  ; 03074 jnz 0x3096
mov bx,[0x116]  ; 03076
inc bx  ; 0307A
db 0x8B, 0xC3  ; 0307B mov ax,bx
shl ax,1  ; 0307D
db 0x03, 0xC3  ; 0307F add ax,bx
db 0x2D, 0x02, 0x00  ; 03081 sub ax,0x2
lea di,[0x3f87]  ; 03084
db 0x03, 0xF8  ; 03088 add di,ax
call cutscene_step  ; 0308A
jmp short loc_03096  ; 0308D jmp 0x3096
loc_0308F:
mov bx,[0x116]  ; 0308F
call sub_0317F  ; 03093
loc_03096:
mov ax,[0x114]  ; 03096
sub ax,[0xd650]  ; 03099
db 0x3D, 0x01, 0x00  ; 0309D cmp ax,0x1
jz short loc_030C1  ; 030A0 jz 0x30c1
jg short loc_030CA  ; 030A2 jg 0x30ca
db 0x3D, 0xFF, 0xFF  ; 030A4 cmp ax,0xffff
jl short loc_030CA  ; 030A7 jl 0x30ca
jnz short loc_030F3  ; 030A9 jnz 0x30f3
mov bx,[0x114]  ; 030AB
inc bx  ; 030AF
db 0x8B, 0xC3  ; 030B0 mov ax,bx
shl ax,1  ; 030B2
db 0x03, 0xC3  ; 030B4 add ax,bx
lea di,[0x3fd7]  ; 030B6
db 0x2B, 0xF8  ; 030BA sub di,ax
call cutscene_step  ; 030BC
jmp short loc_030F3  ; 030BF jmp 0x30f3
loc_030C1:
mov bx,[0x114]  ; 030C1
call sub_03196  ; 030C5
jmp short loc_030F3  ; 030C8 jmp 0x30f3
loc_030CA:
lea di,[0x3cb7]  ; 030CA
db 0x33, 0xC0  ; 030CE xor ax,ax
mov cx,0x280  ; 030D0
rep stosw  ; 030D3
mov bx,[0x116]  ; 030D5
cmp bx,0x0  ; 030D9
jz short loc_030E4  ; 030DC jz 0x30e4
loc_030DE:
call sub_0317F  ; 030DE
dec bx  ; 030E1
jg short loc_030DE  ; 030E2 jg 0x30de
loc_030E4:
mov bx,[0x114]  ; 030E4
cmp bx,0x0  ; 030E8
jz short loc_030F3  ; 030EB jz 0x30f3
loc_030ED:
call sub_03196  ; 030ED
dec bx  ; 030F0
jg short loc_030ED  ; 030F1 jg 0x30ed
loc_030F3:
mov ax,[0x116]  ; 030F3
mov [0xd652],ax  ; 030F6
mov ax,[0x114]  ; 030F9
mov [0xd650],ax  ; 030FC
cmp byte [0xd670],0x0  ; 030FF
jz short loc_0310C  ; 03104 jz 0x310c
dec byte [0xd670]  ; 03106
jmp short loc_0312C  ; 0310A jmp 0x312c
loc_0310C:
cmp word [0x116],0x2  ; 0310C
jg short loc_0312C  ; 03111 jg 0x312c
mov byte [0xd670],0x1  ; 03113
lea di,[0x3f88]  ; 03118
call cutscene_step  ; 0311C
lea di,[0x3f8b]  ; 0311F
call cutscene_step  ; 03123
mov word [0xd652],0x0  ; 03126
loc_0312C:
cmp byte [0xd671],0x0  ; 0312C
jz short loc_03139  ; 03131 jz 0x3139
dec byte [0xd671]  ; 03133
jmp short loc_03159  ; 03137 jmp 0x3159
loc_03139:
cmp word [0x114],0x2  ; 03139
jg short loc_03159  ; 0313E jg 0x3159
mov byte [0xd671],0x1  ; 03140
lea di,[0x3fd4]  ; 03145
call cutscene_step  ; 03149
lea di,[0x3fd1]  ; 0314C
call cutscene_step  ; 03150
mov word [0xd650],0x0  ; 03153
loc_03159:
pop word [0x114]  ; 03159
pop word [0x116]  ; 0315D
ret  ; 03161

; ---- function cutscene_step ----
cutscene_step:
mov cx,0x7  ; 03162
mov word [di],0x0  ; 03165
add di,0x50  ; 03169
loop 0x3165  ; 0316C
ret  ; 0316E

; ---- function sub_0316F ----
sub_0316F:
mov cx,0x7  ; 0316F
mov ax,[si]  ; 03172
mov [di],ax  ; 03174
add si,0x2  ; 03176
add di,0x50  ; 03179
loop 0x3172  ; 0317C
ret  ; 0317E

; ---- function sub_0317F ----
sub_0317F:
db 0x8B, 0xC3  ; 0317F mov ax,bx
shl ax,1  ; 03181
db 0x03, 0xC3  ; 03183 add ax,bx
db 0x2D, 0x02, 0x00  ; 03185 sub ax,0x2
lea di,[0x3f87]  ; 03188
db 0x03, 0xF8  ; 0318C add di,ax
lea si,[0xd654]  ; 0318E
call sub_0316F  ; 03192
ret  ; 03195

; ---- function sub_03196 ----
sub_03196:
db 0x8B, 0xC3  ; 03196 mov ax,bx
shl ax,1  ; 03198
db 0x03, 0xC3  ; 0319A add ax,bx
lea di,[0x3fd7]  ; 0319C
db 0x2B, 0xF8  ; 031A0 sub di,ax
lea si,[0xd662]  ; 031A2
call sub_0316F  ; 031A6
ret  ; 031A9

; ---- function cutscene_play ----
cutscene_play:
push bp  ; 031AA
sub sp,0x6  ; 031AB
jc short loc_031B6  ; 031AE jc 0x31b6
cmp sp,[0x17]  ; 031B0
ja short loc_031B9  ; 031B4 ja 0x31b9
loc_031B6:
jmp 0x420  ; 031B6
loc_031B9:
db 0x8B, 0xEC  ; 031B9 mov bp,sp
cmp word [0xd672],0x6  ; 031BB
jnz short loc_031D1  ; 031C0 jnz 0x31d1
mov ax,0xc  ; 031C2
push ax  ; 031C5
call wait_vsync  ; 031C6
db 0x8B, 0xE5  ; 031C9 mov sp,bp
mov word [0xd672],0x0  ; 031CB
loc_031D1:
mov ax,[0xd672]  ; 031D1
db 0x3D, 0x02, 0x00  ; 031D4 cmp ax,0x2
jng short loc_031DD  ; 031D7 jng 0x31dd
inc word [0xd672]  ; 031D9
loc_031DD:
cmp word [0xd672],0x2  ; 031DD
jnz short loc_031F1  ; 031E2 jnz 0x31f1
cmp word [0x10c],0x1  ; 031E4
jnz short loc_031F1  ; 031E9 jnz 0x31f1
mov word [0xd672],0x3  ; 031EB
loc_031F1:
cmp word [0xd674],0x0  ; 031F1
jng short loc_0322E  ; 031F6 jng 0x322e
cmp word [0xd5aa],0x0  ; 031F8
jnz short loc_03227  ; 031FD jnz 0x3227
cmp word [0x10c],0x1c  ; 031FF
jnz short loc_0320D  ; 03204 jnz 0x320d
db 0x33, 0xC0  ; 03206 xor ax,ax
add sp,0x6  ; 03208
pop bp  ; 0320B
ret  ; 0320C
loc_0320D:
mov ax,0xa  ; 0320D
push ax  ; 03210
call wait_vsync  ; 03211
db 0x8B, 0xE5  ; 03214 mov sp,bp
call draw_ui_element  ; 03216
mov word [0xd674],0x0  ; 03219
mov ax,0x1  ; 0321F
add sp,0x6  ; 03222
pop bp  ; 03225
ret  ; 03226
loc_03227:
db 0x33, 0xC0  ; 03227 xor ax,ax
add sp,0x6  ; 03229
pop bp  ; 0322C
ret  ; 0322D
loc_0322E:
cmp word [0x10c],0x46  ; 0322E
jnz short loc_0324A  ; 03233 jnz 0x324a
mov al,[0xdf42]  ; 03235
xor ah,ah  ; 03238
db 0x3D, 0x20, 0x00  ; 0323A cmp ax,0x20
jnz short loc_0324A  ; 0323D jnz 0x324a
mov ax,[0xc3f4]  ; 0323F
mov byte [0xdf43],0x0  ; 03242
mov [0xc3d2],ax  ; 03247
loc_0324A:
cmp word [0xea],0x2  ; 0324A
jz short loc_03254  ; 0324F jz 0x3254
jmp 0x354f  ; 03251
loc_03254:
mov ax,[0x106]  ; 03254
sub ax,[0xbcd5]  ; 03257
mov bx,[0xd67c]  ; 0325B
test bx,bx  ; 0325F
mov [bp+0x4],ax  ; 03261
jng short loc_0326C  ; 03264 jng 0x326c
dec word [0xd67c]  ; 03266
jmp short loc_032A6  ; 0326A jmp 0x32a6
loc_0326C:
cmp word [0x12c],0x0  ; 0326C
jnz short loc_032A6  ; 03271 jnz 0x32a6
mov ax,[bp+0x4]  ; 03273
db 0x3D, 0x5E, 0x00  ; 03276 cmp ax,0x5e
jnl short loc_032A6  ; 03279 jnl 0x32a6
db 0x3D, 0x20, 0x00  ; 0327B cmp ax,0x20
jng short loc_032A6  ; 0327E jng 0x32a6
db 0x3D, 0x3E, 0x00  ; 03280 cmp ax,0x3e
jl short loc_03299  ; 03283 jl 0x3299
mov ax,[0x10c]  ; 03285
db 0x3D, 0x01, 0x00  ; 03288 cmp ax,0x1
jng short loc_032A6  ; 0328B jng 0x32a6
db 0x3D, 0x08, 0x00  ; 0328D cmp ax,0x8
jnl short loc_032A6  ; 03290 jnl 0x32a6
cmp word [0xfa],0x0  ; 03292
jng short loc_032A6  ; 03297 jng 0x32a6
loc_03299:
cmp word [0xf8],0x0  ; 03299
jnz short loc_032A6  ; 0329E jnz 0x32a6
mov word [0xd67a],0x1  ; 032A0
loc_032A6:
mov ax,[bp+0x4]  ; 032A6
db 0x3D, 0x3E, 0x00  ; 032A9 cmp ax,0x3e
jnl short loc_032CD  ; 032AC jnl 0x32cd
db 0x3D, 0x20, 0x00  ; 032AE cmp ax,0x20
jng short loc_032CD  ; 032B1 jng 0x32cd
cmp word [0xd67a],0x1  ; 032B3
jnz short loc_032CD  ; 032B8 jnz 0x32cd
cmp word [0xf8],0x0  ; 032BA
jnz short loc_032CD  ; 032BF jnz 0x32cd
mov word [0xf8],0x1  ; 032C1
mov ax,[0xc40e]  ; 032C7
mov [0xc3d2],ax  ; 032CA
loc_032CD:
cmp word [0xd67a],0x1  ; 032CD
jnz short loc_032FE  ; 032D2 jnz 0x32fe
mov ax,[0x12c]  ; 032D4
inc ax  ; 032D7
db 0x3D, 0x05, 0x00  ; 032D8 cmp ax,0x5
mov [0x12c],ax  ; 032DB
jnz short loc_032EC  ; 032DE jnz 0x32ec
mov word [0xd67a],0x0  ; 032E0
mov word [0xd67c],0x3  ; 032E6
loc_032EC:
mov ax,[0x12c]  ; 032EC
db 0x3D, 0x01, 0x00  ; 032EF cmp ax,0x1
jnz short loc_032F9  ; 032F2 jnz 0x32f9
add word [0x12c],0x2  ; 032F4
loc_032F9:
call effect_scroll_left  ; 032F9
jmp short loc_0332A  ; 032FC jmp 0x332a
loc_032FE:
cmp word [0x12c],0x0  ; 032FE
jng short loc_0332A  ; 03303 jng 0x332a
cmp word [0xd67c],0x0  ; 03305
jnz short loc_0332A  ; 0330A jnz 0x332a
mov ax,[0xd678]  ; 0330C
neg ax  ; 0330F
mov [0xd678],ax  ; 03311
jng short loc_0332A  ; 03314 jng 0x332a
mov ax,[0x12c]  ; 03316
dec ax  ; 03319
test ax,ax  ; 0331A
mov [0x12c],ax  ; 0331C
jnz short loc_03327  ; 0331F jnz 0x3327
mov word [0xd67c],0xa  ; 03321
loc_03327:
call effect_scroll_left  ; 03327
loc_0332A:
cmp word [0x12c],0x1  ; 0332A
jng short loc_03349  ; 0332F jng 0x3349
cmp word [bp+0x4],0x20  ; 03331
jng short loc_03349  ; 03335 jng 0x3349
cmp word [0xf8],0x0  ; 03337
jnz short loc_03349  ; 0333C jnz 0x3349
mov ax,[0x106]  ; 0333E
db 0x2D, 0x44, 0x00  ; 03341 sub ax,0x44
mov [0x104],ax  ; 03344
jmp short loc_0334F  ; 03347 jmp 0x334f
loc_03349:
mov ax,[0x106]  ; 03349
mov [0x104],ax  ; 0334C
loc_0334F:
cmp word [0xf8],0x0  ; 0334F
jng short loc_033BF  ; 03354 jng 0x33bf
cmp word [0x166],0x0  ; 03356
jnz short loc_0336A  ; 0335B jnz 0x336a
mov word [0x166],0x14  ; 0335D
db 0x33, 0xC0  ; 03363 xor ax,ax
add sp,0x6  ; 03365
pop bp  ; 03368
ret  ; 03369
loc_0336A:
mov ax,[0x166]  ; 0336A
dec ax  ; 0336D
test ax,ax  ; 0336E
mov [0x166],ax  ; 03370
jnz short loc_033A4  ; 03373 jnz 0x33a4
cmp word [0x10c],0x44  ; 03375
jnz short loc_03385  ; 0337A jnz 0x3385
mov ax,0x3  ; 0337C
push ax  ; 0337F
call wait_vsync  ; 03380
db 0x8B, 0xE5  ; 03383 mov sp,bp
loc_03385:
mov word [bp+0x4],0x0  ; 03385
loc_0338A:
cmp word [bp+0x4],0x3e8  ; 0338A
jnl short loc_03396  ; 0338F jnl 0x3396
inc word [bp+0x4]  ; 03391
jmp short loc_0338A  ; 03394 jmp 0x338a
loc_03396:
mov word [0x116],0x0  ; 03396
mov word [0xd674],0x1  ; 0339C
jmp short loc_033B8  ; 033A2 jmp 0x33b8
loc_033A4:
cmp word [0x166],0xb  ; 033A4
jnz short loc_033B8  ; 033A9 jnz 0x33b8
cmp word [0x10c],0x44  ; 033AB
jnz short loc_033B8  ; 033B0 jnz 0x33b8
mov word [0x166],0x1  ; 033B2
loc_033B8:
db 0x33, 0xC0  ; 033B8 xor ax,ax
add sp,0x6  ; 033BA
pop bp  ; 033BD
ret  ; 033BE
loc_033BF:
mov ax,[0xbcd5]  ; 033BF
cmp ax,[0x104]  ; 033C2
jz short loc_033CB  ; 033C6 jz 0x33cb
jmp 0x392d  ; 033C8
loc_033CB:
cmp word [0x152],0x3  ; 033CB
jnz short loc_03410  ; 033D0 jnz 0x3410
mov word [0x152],0x0  ; 033D2
mov ax,0x2  ; 033D8
mov [0xea],ax  ; 033DB
inc ax  ; 033DE
push ax  ; 033DF
mov [0xea],ax  ; 033E0
call combat_update  ; 033E3
db 0x8B, 0xE5  ; 033E6 mov sp,bp
mov ax,0x6  ; 033E8
mov bx,0x1  ; 033EB
mov [0x130],ax  ; 033EE
shl ax,1  ; 033F1
db 0x8B, 0xF0  ; 033F3 mov si,ax
mov [si+0x142],bx  ; 033F5
mov word [0xbb2a],0xffff  ; 033F9
mov word [0xfa],0x2  ; 033FF
mov [0x12e],bx  ; 03405
db 0x33, 0xC0  ; 03409 xor ax,ax
add sp,0x6  ; 0340B
pop bp  ; 0340E
ret  ; 0340F
loc_03410:
mov ax,[0xea]  ; 03410
mov bx,[0x152]  ; 03413
db 0x03, 0xD8  ; 03417 add bx,ax
mov word [0x152],0x0  ; 03419
mov [0xea],bx  ; 0341F
jmp 0x391f  ; 03423
mov ax,0x7  ; 03426
push ax  ; 03429
mov ax,0xd680  ; 0342A
push ax  ; 0342D
call set_music_callback  ; 0342E
db 0x8B, 0xE5  ; 03431 mov sp,bp
mov ax,[0xea]  ; 03433
inc ax  ; 03436
push ax  ; 03437
mov [0xea],ax  ; 03438
call combat_update  ; 0343B
db 0x8B, 0xE5  ; 0343E mov sp,bp
mov ax,0x5dc  ; 03440
push ax  ; 03443
mov ax,0xd687  ; 03444
push ax  ; 03447
call load_palette  ; 03448
db 0x8B, 0xE5  ; 0344B mov sp,bp
mov word [0x118],0x20  ; 0344D
mov word [0x110],0x46  ; 03453
mov ax,[0xce06]  ; 03459
mov word [0xbb2a],0xffff  ; 0345C
mov [0xcde8],ax  ; 03462
db 0x33, 0xC0  ; 03465 xor ax,ax
add sp,0x6  ; 03467
pop bp  ; 0346A
ret  ; 0346B
mov ax,0x8  ; 0346C
push ax  ; 0346F
mov ax,0xd690  ; 03470
push ax  ; 03473
call set_music_callback  ; 03474
db 0x8B, 0xE5  ; 03477 mov sp,bp
mov ax,[0xea]  ; 03479
inc ax  ; 0347C
push ax  ; 0347D
mov [0xea],ax  ; 0347E
call combat_update  ; 03481
db 0x8B, 0xE5  ; 03484 mov sp,bp
mov ax,0x5dc  ; 03486
push ax  ; 03489
mov ax,0xd687  ; 0348A
push ax  ; 0348D
call load_palette  ; 0348E
db 0x8B, 0xE5  ; 03491 mov sp,bp
mov word [0x10e],0xc8  ; 03493
mov word [0xe2],0x1  ; 03499
mov word [0x166],0x9  ; 0349F
db 0x33, 0xC0  ; 034A5 xor ax,ax
add sp,0x6  ; 034A7
pop bp  ; 034AA
ret  ; 034AB
mov ax,[0x104]  ; 034AC
cmp ax,[0x106]  ; 034AF
jnl short loc_034BF  ; 034B3 jnl 0x34bf
call effect_dissolve  ; 034B5
db 0x33, 0xC0  ; 034B8 xor ax,ax
add sp,0x6  ; 034BA
pop bp  ; 034BD
ret  ; 034BE
loc_034BF:
mov ax,0xa  ; 034BF
push ax  ; 034C2
mov ax,0xd696  ; 034C3
push ax  ; 034C6
call set_music_callback  ; 034C7
db 0x8B, 0xE5  ; 034CA mov sp,bp
mov ax,0x1  ; 034CC
mov word [0xbb2a],0xffff  ; 034CF
mov bx,[0xea]  ; 034D5
inc bx  ; 034D9
push bx  ; 034DA
mov [0x130],ax  ; 034DB
mov [0xea],bx  ; 034DE
call combat_update  ; 034E2
db 0x8B, 0xE5  ; 034E5 mov sp,bp
mov ax,[0xbcd5]  ; 034E7
mov word [0x12e],0x1  ; 034EA
db 0x33, 0xDB  ; 034F0 xor bx,bx
mov [0x102],ax  ; 034F2
mov [0xf6],bx  ; 034F5
mov [0xd672],bx  ; 034F9
mov [0xd67e],bx  ; 034FD
mov [0xfa],bx  ; 03501
db 0x8B, 0xC3  ; 03505 mov ax,bx
add sp,0x6  ; 03507
pop bp  ; 0350A
ret  ; 0350B
cmp word [0x12e],0x1  ; 0350C
jz short loc_03516  ; 03511 jz 0x3516
jmp 0x386a  ; 03513
loc_03516:
cmp word [0xd5aa],0x0  ; 03516
jz short loc_03527  ; 0351B jz 0x3527
cmp word [0x130],0x5  ; 0351D
jl short loc_03527  ; 03522 jl 0x3527
jmp 0x386a  ; 03524
loc_03527:
mov ax,[0x130]  ; 03527
inc ax  ; 0352A
db 0x3D, 0x07, 0x00  ; 0352B cmp ax,0x7
mov [0x130],ax  ; 0352E
jz short loc_03536  ; 03531 jz 0x3536
jmp 0x37d7  ; 03533
loc_03536:
mov ax,0xc  ; 03536
push ax  ; 03539
mov ax,0xd69c  ; 0353A
push ax  ; 0353D
call set_music_callback  ; 0353E
db 0x8B, 0xE5  ; 03541 mov sp,bp
mov ax,[0xea]  ; 03543
inc ax  ; 03546
push ax  ; 03547
mov [0xea],ax  ; 03548
call combat_update  ; 0354B
db 0x8B, 0xE5  ; 0354E mov sp,bp
mov ax,0xce3e  ; 03550
push ax  ; 03553
mov ax,0xd6a2  ; 03554
push ax  ; 03557
call init_figure  ; 03558
db 0x8B, 0xE5  ; 0355B mov sp,bp
call play_sound  ; 0355D
mov word [0x130],0x6  ; 03560
push word [0x130]  ; 03566
call effect_wipe  ; 0356A
db 0x8B, 0xE5  ; 0356D mov sp,bp
mov ax,0x114  ; 0356F
mov [0x10e],ax  ; 03572
db 0x2D, 0x1E, 0x00  ; 03575 sub ax,0x1e
mov word [0x110],0x6  ; 03578
mov bx,0x1  ; 0357E
mov cx,0x1a  ; 03581
sub cx,[0x116]  ; 03584
cmp word [0x10c],0x3f  ; 03588
mov [0xbcd5],ax  ; 0358D
mov [0x114],cx  ; 03590
mov [0xf2],bx  ; 03594
jnl short loc_035AC  ; 03598 jnl 0x35ac
mov word [0x10c],0xa  ; 0359A
mov ax,[0xc3ec]  ; 035A0
mov [0xc3d2],ax  ; 035A3
mov [0x112],bx  ; 035A6
jmp short loc_035BE  ; 035AA jmp 0x35be
loc_035AC:
mov word [0x116],0x0  ; 035AC
mov word [0xf8],0x1  ; 035B2
mov ax,[0xc40c]  ; 035B8
mov [0xc3d2],ax  ; 035BB
loc_035BE:
mov ax,0x12  ; 035BE
sub ax,[0x114]  ; 035C1
mov [0x11e],ax  ; 035C5
jnl short loc_035D0  ; 035C8 jnl 0x35d0
mov word [0x11e],0x0  ; 035CA
loc_035D0:
db 0x33, 0xC0  ; 035D0 xor ax,ax
add sp,0x6  ; 035D2
pop bp  ; 035D5
ret  ; 035D6
cmp word [0x130],0x2  ; 035D7
jnz short loc_035EA  ; 035DC jnz 0x35ea
sub word [0x104],0x140  ; 035DE
sub word [0x10a],0x140  ; 035E4
loc_035EA:
mov ax,[0x130]  ; 035EA
shl ax,1  ; 035ED
db 0x8B, 0xF0  ; 035EF mov si,ax
mov bx,[si+0x142]  ; 035F1
cmp word [0xfa],0x0  ; 035F5
mov [bp+0x0],ax  ; 035FA
mov [0x12e],bx  ; 035FD
jng short loc_0363F  ; 03601 jng 0x363f
mov word [0xfa],0x2  ; 03603
cmp word [si+0x132],0x0  ; 03609
jng short loc_03626  ; 0360E jng 0x3626
push word [0xea]  ; 03610
call combat_apply_damage  ; 03614
db 0x8B, 0xE5  ; 03617 mov sp,bp
mov ax,[0x130]  ; 03619
shl ax,1  ; 0361C
db 0x8B, 0xF0  ; 0361E mov si,ax
mov word [si+0x132],0x0  ; 03620
loc_03626:
cmp word [0x130],0x6  ; 03626
jnz short loc_03645  ; 0362B jnz 0x3645
cmp word [0xd67e],0x0  ; 0362D
jnz short loc_03645  ; 03632 jnz 0x3645
mov ax,0x1  ; 03634
mov [0xd67e],ax  ; 03637
mov [0xd672],ax  ; 0363A
jmp short loc_03645  ; 0363D jmp 0x3645
loc_0363F:
sub word [0x10e],0x114  ; 0363F
loc_03645:
cmp word [0x12e],0x0  ; 03645
jnz short loc_03654  ; 0364A jnz 0x3654
mov word [0x104],0xfc  ; 0364C
jmp short loc_0365A  ; 03652 jmp 0x365a
loc_03654:
mov word [0x104],0x130  ; 03654
loc_0365A:
push word [0x130]  ; 0365A
call effect_wipe  ; 0365E
db 0x8B, 0xE5  ; 03661 mov sp,bp
db 0x33, 0xC0  ; 03663 xor ax,ax
add sp,0x6  ; 03665
pop bp  ; 03668
ret  ; 03669
call effect_dissolve  ; 0366A
db 0x33, 0xC0  ; 0366D xor ax,ax
add sp,0x6  ; 0366F
pop bp  ; 03672
ret  ; 03673
cmp word [0x130],0x7  ; 03674
jnz short loc_03697  ; 03679 jnz 0x3697
cmp word [0x10c],0x40  ; 0367B
jng short loc_03690  ; 03680 jng 0x3690
call run_anim_script  ; 03682
call show_dialog  ; 03685
mov ax,0x1  ; 03688
add sp,0x6  ; 0368B
pop bp  ; 0368E
ret  ; 0368F
loc_03690:
db 0x33, 0xC0  ; 03690 xor ax,ax
add sp,0x6  ; 03692
pop bp  ; 03695
ret  ; 03696
loc_03697:
inc word [0x130]  ; 03697
mov ax,[0xfa]  ; 0369B
db 0x3D, 0x01, 0x00  ; 0369E cmp ax,0x1
jnz short loc_036A7  ; 036A1 jnz 0x36a7
inc word [0xfa]  ; 036A3
loc_036A7:
mov ax,[0x130]  ; 036A7
shl ax,1  ; 036AA
db 0x8B, 0xF0  ; 036AC mov si,ax
mov ax,[si+0x142]  ; 036AE
push word [0x130]  ; 036B2
mov [0x12e],ax  ; 036B6
call effect_wipe  ; 036B9
db 0x8B, 0xE5  ; 036BC mov sp,bp
cmp word [0x130],0x7  ; 036BE
jnz short loc_0370E  ; 036C3 jnz 0x370e
mov word [0x104],0xac  ; 036C5
mov ax,0xbd04  ; 036CB
push ax  ; 036CE
mov ax,0xd6a9  ; 036CF
push ax  ; 036D2
call init_figure  ; 036D3
db 0x8B, 0xE5  ; 036D6 mov sp,bp
mov ax,0xb  ; 036D8
push ax  ; 036DB
call load_animation  ; 036DC
db 0x8B, 0xE5  ; 036DF mov sp,bp
mov ax,0xce3e  ; 036E1
push ax  ; 036E4
mov ax,0xd6af  ; 036E5
push ax  ; 036E8
call init_figure  ; 036E9
db 0x8B, 0xE5  ; 036EC mov sp,bp
call play_sound  ; 036EE
mov word [0xfa],0x0  ; 036F1
mov word [0x10e],0xc8  ; 036F7
mov ax,0x1  ; 036FD
mov bx,[0xcdea]  ; 03700
mov [0xf0],ax  ; 03704
mov [0x110],ax  ; 03707
mov [0xcde8],bx  ; 0370A
loc_0370E:
db 0x33, 0xC0  ; 0370E xor ax,ax
add sp,0x6  ; 03710
pop bp  ; 03713
ret  ; 03714
es xor al,0x6c  ; 03715
xor al,0xac  ; 03718
xor al,0xc  ; 0371A
xor ax,0x3674  ; 0371C
db 0x8B, 0xF3  ; 0371F mov si,bx
cmp si,0x5  ; 03721
jnc short loc_0372D  ; 03724 jnc 0x372d
shl si,1  ; 03726
jmp word near [cs:si+0x3715]  ; 03728
loc_0372D:
cmp word [0xfa],0x0  ; 0372D
jng short loc_0375D  ; 03732 jng 0x375d
cmp word [0x130],0x5  ; 03734
jnz short loc_0375D  ; 03739 jnz 0x375d
cmp word [0x172],0x0  ; 0373B
jnz short loc_0375D  ; 03740 jnz 0x375d
mov word [0x172],0x1  ; 03742
mov ax,0x15  ; 03748
sub ax,[0x116]  ; 0374B
mov bx,0x2  ; 0374F
mov [0x124],ax  ; 03752
mov [0x126],bx  ; 03755
mov [0x120],bx  ; 03759
loc_0375D:
cmp word [0xfa],0x1  ; 0375D
jz short loc_03767  ; 03762 jz 0x3767
jmp 0x3af3  ; 03764
loc_03767:
mov ax,[0xea]  ; 03767
db 0x3D, 0x01, 0x00  ; 0376A cmp ax,0x1
jz short loc_03777  ; 0376D jz 0x3777
db 0x3D, 0x02, 0x00  ; 0376F cmp ax,0x2
jz short loc_03777  ; 03772 jz 0x3777
jmp 0x3af3  ; 03774
loc_03777:
cmp word [0x12c],0x0  ; 03777
jz short loc_03781  ; 0377C jz 0x3781
jmp 0x3af3  ; 0377E
loc_03781:
mov ax,[0x104]  ; 03781
sub ax,[0xbcd5]  ; 03784
db 0x3D, 0x3C, 0x00  ; 03788 cmp ax,0x3c
jg short loc_03790  ; 0378B jg 0x3790
jmp 0x3af3  ; 0378D
loc_03790:
cmp word [0x166],0x0  ; 03790
jnz short loc_037CE  ; 03795 jnz 0x37ce
mov ax,0x2  ; 03797
mov word [0x166],0x28  ; 0379A
mov bx,[0x104]  ; 037A0
sub bx,[0xbcd5]  ; 037A4
cmp bx,0xfa  ; 037A8
mov [0x126],ax  ; 037AC
mov [0x120],ax  ; 037AF
jnl short loc_037BA  ; 037B2 jnl 0x37ba
mov word [0x166],0x3c  ; 037B4
loc_037BA:
cmp word [0xe2],0x1  ; 037BA
jnz short loc_037C7  ; 037BF jnz 0x37c7
mov word [0x166],0x32  ; 037C1
loc_037C7:
db 0x33, 0xC0  ; 037C7 xor ax,ax
add sp,0x6  ; 037C9
pop bp  ; 037CC
ret  ; 037CD
loc_037CE:
cmp word [0x166],0x1  ; 037CE
jnz short loc_037E0  ; 037D3 jnz 0x37e0
cmp word [0x10c],0x8  ; 037D5
jnz short loc_037E0  ; 037DA jnz 0x37e0
inc word [0x166]  ; 037DC
loc_037E0:
mov ax,[0x166]  ; 037E0
dec ax  ; 037E3
test ax,ax  ; 037E4
mov [0x166],ax  ; 037E6
jz short loc_037EE  ; 037E9 jz 0x37ee
jmp 0x3aec  ; 037EB
loc_037EE:
cmp word [0xe2],0x1  ; 037EE
jnz short loc_03851  ; 037F3 jnz 0x3851
cmp word [0xea],0x2  ; 037F5
jnz short loc_03851  ; 037FA jnz 0x3851
mov ax,0x9  ; 037FC
push ax  ; 037FF
mov ax,0xd6b6  ; 03800
push ax  ; 03803
call set_music_callback  ; 03804
db 0x8B, 0xE5  ; 03807 mov sp,bp
mov ax,0x2  ; 03809
push ax  ; 0380C
call load_animation  ; 0380D
db 0x8B, 0xE5  ; 03810 mov sp,bp
mov ax,0x5dc  ; 03812
push ax  ; 03815
mov ax,0xd687  ; 03816
push ax  ; 03819
call load_palette  ; 0381A
db 0x8B, 0xE5  ; 0381D mov sp,bp
push word [0xea]  ; 0381F
call combat_apply_damage  ; 03823
db 0x8B, 0xE5  ; 03826 mov sp,bp
mov word [0x118],0x20  ; 03828
mov word [0x110],0x46  ; 0382E
mov ax,[0xce06]  ; 03834
mov word [0xbb2a],0xffff  ; 03837
db 0x33, 0xDB  ; 0383D xor bx,bx
mov [0xcde8],ax  ; 0383F
mov [0xd676],bx  ; 03842
mov [0xe2],bx  ; 03846
db 0x8B, 0xC3  ; 0384A mov ax,bx
add sp,0x6  ; 0384C
pop bp  ; 0384F
ret  ; 03850
loc_03851:
mov ax,[0x104]  ; 03851
sub ax,[0xbcd5]  ; 03854
cmp ax,0x190  ; 03858
jng short loc_038D7  ; 0385B jng 0x38d7
cmp word [0xea],0x2  ; 0385D
jnz short loc_0389C  ; 03862 jnz 0x389c
cmp word [0xd676],0x0  ; 03864
jnz short loc_0389C  ; 03869 jnz 0x389c
mov word [0xd676],0x1  ; 0386B
mov ax,0x18  ; 03871
push ax  ; 03874
call wait_vsync  ; 03875
db 0x8B, 0xE5  ; 03878 mov sp,bp
call effect_scroll_right  ; 0387A
db 0x33, 0xC0  ; 0387D xor ax,ax
mov bx,[0xbcd5]  ; 0387F
add bx,0x128  ; 03883
mov word [0x166],0x2  ; 03887
mov [0xfe],ax  ; 0388D
mov [0x11e],ax  ; 03890
mov [0x114],ax  ; 03893
mov [0x10e],bx  ; 03896
jmp short loc_038EC  ; 0389A jmp 0x38ec
loc_0389C:
push word [0xea]  ; 0389C
call combat_apply_damage  ; 038A0
db 0x8B, 0xE5  ; 038A3 mov sp,bp
mov word [0xd676],0x0  ; 038A5
cmp word [0xea],0x2  ; 038AB
jnz short loc_038C9  ; 038B0 jnz 0x38c9
mov ax,[0xbcd5]  ; 038B2
mov bx,[0x10e]  ; 038B5
db 0x2B, 0xD8  ; 038B9 sub bx,ax
cmp bx,0x140  ; 038BB
jng short loc_038CF  ; 038BF jng 0x38cf
add ax,0x12c  ; 038C1
mov [0x10e],ax  ; 038C4
jmp short loc_038CF  ; 038C7 jmp 0x38cf
loc_038C9:
mov word [0x11a],0x20  ; 038C9
loc_038CF:
mov word [0xd652],0x0  ; 038CF
jmp short loc_038EC  ; 038D5 jmp 0x38ec
loc_038D7:
mov ax,[0x104]  ; 038D7
sub ax,[0xbcd5]  ; 038DA
db 0x3D, 0x1E, 0x00  ; 038DE cmp ax,0x1e
jng short loc_038EC  ; 038E1 jng 0x38ec
push word [0xea]  ; 038E3
call combat_apply_damage  ; 038E7
db 0x8B, 0xE5  ; 038EA mov sp,bp
loc_038EC:
db 0x33, 0xC0  ; 038EC xor ax,ax
add sp,0x6  ; 038EE
pop bp  ; 038F1
ret  ; 038F2
mov ax,[0xbcd5]  ; 038F3
cmp ax,[0x102]  ; 038F6
jnz short loc_0395F  ; 038FA jnz 0x395f
cmp word [0xea],0x0  ; 038FC
jnz short loc_0391C  ; 03901 jnz 0x391c
mov word [0xbcd5],0x2c  ; 03903
mov word [0x102],0x28  ; 03909
mov ax,[0xc414]  ; 0390F
mov [0xc3d2],ax  ; 03912
db 0x33, 0xC0  ; 03915 xor ax,ax
add sp,0x6  ; 03917
pop bp  ; 0391A
ret  ; 0391B
loc_0391C:
cmp word [0xea],0x2  ; 0391C
jng short loc_0395F  ; 03921 jng 0x395f
mov ax,[0x130]  ; 03923
db 0x3D, 0x02, 0x00  ; 03926 cmp ax,0x2
jng short loc_0395F  ; 03929 jng 0x395f
dec word [0x130]  ; 0392B
mov word [0x12e],0x1  ; 0392F
push word [0x130]  ; 03935
call effect_wipe  ; 03939
db 0x8B, 0xE5  ; 0393C mov sp,bp
cmp word [0x130],0x2  ; 0393E
jnz short loc_0394E  ; 03943 jnz 0x394e
mov word [0xc3a6],0x2  ; 03945
call effect_fade  ; 0394B
loc_0394E:
mov ax,0x114  ; 0394E
mov [0xbcd5],ax  ; 03951
inc ax  ; 03954
inc ax  ; 03955
add word [0x10e],0x114  ; 03956
mov [0x104],ax  ; 0395C
loc_0395F:
mov ax,[0x10e]  ; 0395F
sub ax,[0xbcd5]  ; 03962
cmp ax,0x14a  ; 03966
mov [bp+0x4],ax  ; 03969
jnl short loc_03991  ; 0396C jnl 0x3991
db 0x33, 0xC0  ; 0396E xor ax,ax
cmp word [0x110],0x3f  ; 03970
mov [0x11a],ax  ; 03975
mov [0x118],ax  ; 03978
jng short loc_0398A  ; 0397B jng 0x398a
cmp word [0xea],0x0  ; 0397D
jng short loc_0398A  ; 03982 jng 0x398a
mov word [0x110],0x1  ; 03984
loc_0398A:
db 0x33, 0xC0  ; 0398A xor ax,ax
add sp,0x6  ; 0398C
pop bp  ; 0398F
ret  ; 03990
loc_03991:
mov ax,[0x118]  ; 03991
db 0x3D, 0x01, 0x00  ; 03994 cmp ax,0x1
jng short loc_039A4  ; 03997 jng 0x39a4
dec word [0x118]  ; 03999
db 0x33, 0xC0  ; 0399D xor ax,ax
add sp,0x6  ; 0399F
pop bp  ; 039A2
ret  ; 039A3
loc_039A4:
cmp word [0x118],0x1  ; 039A4
jnz short loc_039CF  ; 039A9 jnz 0x39cf
db 0x33, 0xC0  ; 039AB xor ax,ax
mov word [0x11a],0x20  ; 039AD
mov word [0x110],0x46  ; 039B3
mov bx,[0xce06]  ; 039B9
mov word [0xbb2a],0xffff  ; 039BD
mov [0x118],ax  ; 039C3
mov [0xcde8],bx  ; 039C6
add sp,0x6  ; 039CA
pop bp  ; 039CD
ret  ; 039CE
loc_039CF:
mov ax,[0x11a]  ; 039CF
db 0x3D, 0x01, 0x00  ; 039D2 cmp ax,0x1
jng short loc_039E2  ; 039D5 jng 0x39e2
dec word [0x11a]  ; 039D7
db 0x33, 0xC0  ; 039DB xor ax,ax
add sp,0x6  ; 039DD
pop bp  ; 039E0
ret  ; 039E1
loc_039E2:
cmp word [0x11a],0x1  ; 039E2
jnz short loc_03A26  ; 039E7 jnz 0x3a26
mov word [0x11a],0x0  ; 039E9
cmp word [0xea],0x1  ; 039EF
jnz short loc_03A16  ; 039F4 jnz 0x3a16
mov word [0x118],0x20  ; 039F6
mov word [0xbb2a],0xffff  ; 039FC
mov ax,[bp+0x4]  ; 03A02
cmp ax,0x320  ; 03A05
jng short loc_03A26  ; 03A08 jng 0x3a26
mov bx,0x2  ; 03A0A
cwd  ; 03A0D
idiv bx  ; 03A0E
sub [0x10e],ax  ; 03A10
jmp short loc_03A26  ; 03A14 jmp 0x3a26
loc_03A16:
mov ax,0x1  ; 03A16
dec word [0x158]  ; 03A19
mov word [0x114],0x0  ; 03A1D
mov [0xfa],ax  ; 03A23
loc_03A26:
db 0x33, 0xC0  ; 03A26 xor ax,ax
add sp,0x6  ; 03A28
pop bp  ; 03A2B
ret  ; 03A2C
