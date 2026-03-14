; C runtime startup, entry point, error handlers

add [bx+si],al  ; 00000
cli  ; 00002
mov ax,0x6ca  ; 00003
mov ds,ax  ; 00006
mov ax,0x155c  ; 00008
mov ss,ax  ; 0000B
mov sp,0x80  ; 0000D
sti  ; 00010
mov ah,0x30  ; 00011
int 0x21  ; 00013
db 0x0A, 0xC0  ; 00015 or al,al
jnz short loc_0001C  ; 00017 jnz 0x1c
mov ax,0x1  ; 00019
loc_0001C:
mov [0xf],ax  ; 0001C
mov word [0x5b],es  ; 0001F
cmp byte [0xf],0x2  ; 00023
jl short loc_00051  ; 00028 jl 0x51
mov ax,[es:0x2c]  ; 0002A
mov [0x6d],ax  ; 0002E
db 0x0B, 0xC0  ; 00031 or ax,ax
jz short loc_00051  ; 00033 jz 0x51
push es  ; 00035
cld  ; 00036
les di,word [0x6b]  ; 00037
db 0x33, 0xC0  ; 0003B xor ax,ax
mov cx,0x7fff  ; 0003D
loc_00040:
repne scasb  ; 00040
jnz short loc_00050  ; 00042 jnz 0x50
scasb  ; 00044
jnz short loc_00040  ; 00045 jnz 0x40
inc di  ; 00047
db 0x81, 0xE7, 0xFE, 0xFF  ; 00048 and di,0xfffe
mov [0x6f],di  ; 0004C
loc_00050:
pop es  ; 00050
loc_00051:
mov si,0x80  ; 00051
mov cl,[es:si]  ; 00054
db 0x32, 0xED  ; 00057 xor ch,ch
jcxz short loc_0007F  ; 00059 jcxz 0x7f
loc_0005B:
inc si  ; 0005B
mov al,[es:si]  ; 0005C
cmp byte [0xf],0x2  ; 0005F
jnl short loc_0006E  ; 00064 jnl 0x6e
cmp al,0x3c  ; 00066
jz short loc_00082  ; 00068 jz 0x82
cmp al,0x3e  ; 0006A
jz short loc_00088  ; 0006C jz 0x88
loc_0006E:
cmp al,0x3d  ; 0006E
jz short loc_000B3  ; 00070 jz 0xb3
cmp al,0x20  ; 00072
jz short loc_0007A  ; 00074 jz 0x7a
cmp al,0x9  ; 00076
jnz short loc_0007F  ; 00078 jnz 0x7f
loc_0007A:
dec cx  ; 0007A
jg short loc_0005B  ; 0007B jg 0x5b
db 0x33, 0xC9  ; 0007D xor cx,cx
loc_0007F:
jmp short loc_000F6  ; 0007F jmp 0xf6
nop  ; 00081
loc_00082:
mov di,0x19  ; 00082
jmp short loc_0008B  ; 00085 jmp 0x8b
nop  ; 00087
loc_00088:
mov di,0x39  ; 00088
loc_0008B:
db 0x32, 0xE4  ; 0008B xor ah,ah
loc_0008D:
dec cx  ; 0008D
jz short loc_000A8  ; 0008E jz 0xa8
inc si  ; 00090
mov al,[es:si]  ; 00091
cmp al,0x20  ; 00094
jz short loc_000A8  ; 00096 jz 0xa8
cmp al,0x9  ; 00098
jz short loc_000A8  ; 0009A jz 0xa8
mov [di],al  ; 0009C
inc di  ; 0009E
inc ah  ; 0009F
cmp ah,0x20  ; 000A1
jz short loc_000AD  ; 000A4 jz 0xad
jmp short loc_0008D  ; 000A6 jmp 0x8d
loc_000A8:
mov byte [di],0x0  ; 000A8
jmp short loc_0007A  ; 000AB jmp 0x7a
loc_000AD:
mov dx,0x97  ; 000AD
jmp 0x407  ; 000B0
loc_000B3:
db 0x33, 0xDB  ; 000B3 xor bx,bx
loc_000B5:
dec cx  ; 000B5
jz short loc_000E6  ; 000B6 jz 0xe6
inc si  ; 000B8
mov al,[es:si]  ; 000B9
cmp al,0x20  ; 000BC
jz short loc_000E6  ; 000BE jz 0xe6
cmp al,0x9  ; 000C0
jz short loc_000E6  ; 000C2 jz 0xe6
sub al,0x30  ; 000C4
jl short loc_000F0  ; 000C6 jl 0xf0
cmp al,0x9  ; 000C8
jg short loc_000F0  ; 000CA jg 0xf0
db 0x03, 0xDB  ; 000CC add bx,bx
jc short loc_000F0  ; 000CE jc 0xf0
db 0x8B, 0xD3  ; 000D0 mov dx,bx
db 0x03, 0xDB  ; 000D2 add bx,bx
jc short loc_000F0  ; 000D4 jc 0xf0
db 0x03, 0xDB  ; 000D6 add bx,bx
jc short loc_000F0  ; 000D8 jc 0xf0
db 0x03, 0xDA  ; 000DA add bx,dx
jc short loc_000F0  ; 000DC jc 0xf0
db 0x32, 0xE4  ; 000DE xor ah,ah
db 0x03, 0xD8  ; 000E0 add bx,ax
jc short loc_000F0  ; 000E2 jc 0xf0
jmp short loc_000B5  ; 000E4 jmp 0xb5
loc_000E6:
db 0x0B, 0xDB  ; 000E6 or bx,bx
jz short loc_000F0  ; 000E8 jz 0xf0
mov [0xe0],bx  ; 000EA
jmp short loc_0007A  ; 000EE jmp 0x7a
loc_000F0:
mov dx,0x82  ; 000F0
jmp 0x407  ; 000F3
loc_000F6:
mov ax,[0x6f]  ; 000F6
mov bx,[0xe0]  ; 000F9
shr bx,1  ; 000FD
db 0x03, 0xDB  ; 000FF add bx,bx
cmp bx,0x200  ; 00101
ja short loc_0010E  ; 00105 ja 0x10e
mov bx,0x200  ; 00107
mov [0xe0],bx  ; 0010A
loc_0010E:
db 0x03, 0xD8  ; 0010E add bx,ax
jc short loc_00139  ; 00110 jc 0x139
mov dx,[es:0x2]  ; 00112
mov ax,ss  ; 00117
db 0x2B, 0xD0  ; 00119 sub dx,ax
test dx,0xf000  ; 0011B
jnz short loc_0012C  ; 0011F jnz 0x12c
shl dx,1  ; 00121
shl dx,1  ; 00123
shl dx,1  ; 00125
shl dx,1  ; 00127
jmp short loc_0012F  ; 00129 jmp 0x12f
nop  ; 0012B
loc_0012C:
mov dx,0xfff0  ; 0012C
loc_0012F:
db 0x3B, 0xD3  ; 0012F cmp dx,bx
jc short loc_00139  ; 00131 jc 0x139
add bx,[0x17]  ; 00133
jnc short loc_0013F  ; 00137 jnc 0x13f
loc_00139:
mov dx,0xb1  ; 00139
jmp 0x407  ; 0013C
loc_0013F:
cli  ; 0013F
mov [0x15],bx  ; 00140
db 0x8B, 0xE3  ; 00144 mov sp,bx
mov ax,ds  ; 00146
mov ss,ax  ; 00148
mov word [0x11],ss  ; 0014A
sti  ; 0014E
push cx  ; 0014F
add bx,0xf  ; 00150
mov cl,0x4  ; 00153
shr bx,cl  ; 00155
mov ax,ss  ; 00157
db 0x03, 0xC3  ; 00159 add ax,bx
mov [0x5f],ax  ; 0015B
mov [0x63],ax  ; 0015E
mov bx,[es:0x2]  ; 00161
db 0x2B, 0xD8  ; 00166 sub bx,ax
jna short loc_00139  ; 00168 jna 0x139
mov cl,0x4  ; 0016A
rol bx,cl  ; 0016C
db 0x8B, 0xC3  ; 0016E mov ax,bx
db 0x25, 0x0F, 0x00  ; 00170 and ax,0xf
db 0x81, 0xE3, 0xF0, 0xFF  ; 00173 and bx,0xfff0
mov [0x65],bx  ; 00177
mov [0x67],ax  ; 0017B
call reset_heap  ; 0017E
db 0x0B, 0xC0  ; 00181 or ax,ax
jnz short loc_00139  ; 00183 jnz 0x139
pop dx  ; 00185
push es  ; 00186
db 0x33, 0xC0  ; 00187 xor ax,ax
push ax  ; 00189
db 0x8B, 0xEC  ; 0018A mov bp,sp
les di,word [0x6b]  ; 0018C
mov di,[0x6f]  ; 00190
loc_00194:
sub di,0x2  ; 00194
jl short loc_0019E  ; 00197 jl 0x19e
push word [es:di]  ; 00199
jmp short loc_00194  ; 0019C jmp 0x194
loc_0019E:
mov es,word [0x5b]  ; 0019E
mov [0x6b],sp  ; 001A2
mov word [0x6d],ss  ; 001A6
db 0x8B, 0xDA  ; 001AA mov bx,dx
db 0x8B, 0xCA  ; 001AC mov cx,dx
add bx,0x4  ; 001AE
db 0x81, 0xE3, 0xFE, 0xFF  ; 001B1 and bx,0xfffe
db 0x2B, 0xE3  ; 001B5 sub sp,bx
db 0x8B, 0xFC  ; 001B7 mov di,sp
mov byte [ss:di],0x63  ; 001B9
inc di  ; 001BD
jcxz short loc_001CF  ; 001BE jcxz 0x1cf
mov byte [ss:di],0x20  ; 001C0
inc di  ; 001C4
mov al,[es:si]  ; 001C5
mov [ss:di],al  ; 001C8
inc si  ; 001CB
inc di  ; 001CC
loop 0x1c5  ; 001CD
loc_001CF:
mov byte [ss:di],0x0  ; 001CF
fninit  ; 001D3
fnstsw [0x7c]  ; 001D5
mov ax,0x64  ; 001D9
db 0x8B, 0xD0  ; 001DC mov dx,ax
imul dx  ; 001DE
test word [0x7c],0xb8bf  ; 001E0
jnz short loc_001EC  ; 001E6 jnz 0x1ec
inc byte [0x7b]  ; 001E8
loc_001EC:
mov [0x13],sp  ; 001EC
db 0x8B, 0xC4  ; 001F0 mov ax,sp
push ax  ; 001F2
push ds  ; 001F3
pop es  ; 001F4
call main  ; 001F5
cmp byte [0xf],0x2  ; 001F8
jl short loc_00204  ; 001FD jl 0x204
mov ax,0x4c00  ; 001FF
int 0x21  ; 00202
loc_00204:
db 0x8B, 0xE5  ; 00204 mov sp,bp
retf  ; 00206
mov ah,0x9  ; 00207
int 0x21  ; 00209
mov es,word [0x5b]  ; 0020B
cmp byte [0xf],0x2  ; 0020F
jl short loc_0021B  ; 00214 jl 0x21b
mov ax,0x4c01  ; 00216
int 0x21  ; 00219
loc_0021B:
push es  ; 0021B
db 0x33, 0xC0  ; 0021C xor ax,ax
push ax  ; 0021E
retf  ; 0021F
mov ax,[0x15]  ; 00220
db 0x2D, 0x04, 0x00  ; 00223 sub ax,0x4
db 0x8B, 0xE0  ; 00226 mov sp,ax
mov dx,0xc7  ; 00228
mov ah,0x9  ; 0022B
int 0x21  ; 0022D
cmp byte [0xf],0x2  ; 0022F
jl short loc_0023B  ; 00234 jl 0x23b
mov ax,0x4c01  ; 00236
int 0x21  ; 00239
loc_0023B:
retf  ; 0023B

; ---- function crt_exit ----
crt_exit:
cmp byte [0xf],0x2  ; 0023C
jl short loc_0024C  ; 00241 jl 0x24c
db 0x8B, 0xEC  ; 00243 mov bp,sp
mov ax,[bp+0x2]  ; 00245
mov ah,0x4c  ; 00248
int 0x21  ; 0024A
loc_0024C:
mov ax,[0x15]  ; 0024C
db 0x2D, 0x04, 0x00  ; 0024F sub ax,0x4
db 0x8B, 0xE0  ; 00252 mov sp,ax
retf  ; 00254
