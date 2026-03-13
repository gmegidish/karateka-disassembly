; C main(), resource loading entry


; ---- function main ----
main:
push bp  ; 05953
sub sp,0xe  ; 05954
db 0x8B, 0xEC  ; 05957 mov bp,sp
mov word [0xe43e],0x0  ; 05959
loc_0595F:
cmp word [0xe43e],0x20  ; 0595F
jnl short loc_059D4  ; 05964 jnl 0x59d4
loc_05966:
mov si,[bp+0x12]  ; 05966
mov al,[si]  ; 05969
xor ah,ah  ; 0596B
inc ax  ; 0596D
db 0x8B, 0xF8  ; 0596E mov di,ax
mov al,[di-0x1b3c]  ; 05970
xor ah,ah  ; 05974
db 0x25, 0x08, 0x00  ; 05976 and ax,0x8
jz short loc_05980  ; 05979 jz 0x5980
inc word [bp+0x12]  ; 0597B
jmp short loc_05966  ; 0597E jmp 0x5966
loc_05980:
mov si,[bp+0x12]  ; 05980
mov al,[si]  ; 05983
xor ah,ah  ; 05985
test ax,ax  ; 05987
jz short loc_059D4  ; 05989 jz 0x59d4
mov ax,[0xe43e]  ; 0598B
inc word [0xe43e]  ; 0598E
shl ax,1  ; 05992
db 0x8B, 0xF0  ; 05994 mov si,ax
mov ax,[bp+0x12]  ; 05996
mov [si-0x1bc0],ax  ; 05999
loc_0599D:
mov si,[bp+0x12]  ; 0599D
mov al,[si]  ; 059A0
xor ah,ah  ; 059A2
test ax,ax  ; 059A4
mov [bp+0x0],ax  ; 059A6
jz short loc_059BE  ; 059A9 jz 0x59be
inc ax  ; 059AB
db 0x8B, 0xF8  ; 059AC mov di,ax
mov al,[di-0x1b3c]  ; 059AE
xor ah,ah  ; 059B2
db 0x25, 0x08, 0x00  ; 059B4 and ax,0x8
jnz short loc_059BE  ; 059B7 jnz 0x59be
inc word [bp+0x12]  ; 059B9
jmp short loc_0599D  ; 059BC jmp 0x599d
loc_059BE:
mov si,[bp+0x12]  ; 059BE
mov al,[si]  ; 059C1
inc word [bp+0x12]  ; 059C3
mov byte [si],0x0  ; 059C6
mov [bp+0x4],al  ; 059C9
xor ah,ah  ; 059CC
test ax,ax  ; 059CE
jnz short loc_0595F  ; 059D0 jnz 0x595f
jmp short loc_059D4  ; 059D2 jmp 0x59d4
loc_059D4:
mov al,[0xf]  ; 059D4
xor ah,ah  ; 059D7
db 0x3D, 0x02, 0x00  ; 059D9 cmp ax,0x2
jl short loc_059E1  ; 059DC jl 0x59e1
jmp 0x5ca6  ; 059DE
loc_059E1:
mov ax,0xe1b0  ; 059E1
push ax  ; 059E4
mov ax,0xe480  ; 059E5
push ax  ; 059E8
mov ax,0x19  ; 059E9
push ax  ; 059EC
call save_vectors  ; 059ED
db 0x8B, 0xE5  ; 059F0 mov sp,bp
mov bl,[0x39]  ; 059F2
xor bh,bh  ; 059F6
cmp bx,0x3e  ; 059F8
mov [bp+0x8],ax  ; 059FB
jz short loc_05A16  ; 059FE jz 0x5a16
mov ax,0xe1be  ; 05A00
push ax  ; 05A03
mov ax,0xe482  ; 05A04
push ax  ; 05A07
mov ax,0x39  ; 05A08
push ax  ; 05A0B
call save_vectors  ; 05A0C
db 0x8B, 0xE5  ; 05A0F mov sp,bp
mov [bp+0xa],ax  ; 05A11
jmp short loc_05A2A  ; 05A14 jmp 0x5a2a
loc_05A16:
mov ax,0xe1be  ; 05A16
push ax  ; 05A19
mov ax,0xe484  ; 05A1A
push ax  ; 05A1D
mov ax,0x3a  ; 05A1E
push ax  ; 05A21
call save_vectors  ; 05A22
db 0x8B, 0xE5  ; 05A25 mov sp,bp
mov [bp+0xa],ax  ; 05A27
loc_05A2A:
mov ax,0xe1cc  ; 05A2A
push ax  ; 05A2D
mov ax,0xe484  ; 05A2E
push ax  ; 05A31
mov ax,0xe486  ; 05A32
push ax  ; 05A35
call save_vectors  ; 05A36
db 0x8B, 0xE5  ; 05A39 mov sp,bp
test ax,ax  ; 05A3B
mov [bp+0xc],ax  ; 05A3D
jnz short loc_05A4B  ; 05A40 jnz 0x5a4b
mov ax,0x1  ; 05A42
push ax  ; 05A45
call crt_init_io  ; 05A46
db 0x8B, 0xE5  ; 05A49 mov sp,bp
loc_05A4B:
cmp word [bp+0x8],0x0  ; 05A4B
jnz short loc_05A66  ; 05A4F jnz 0x5a66
push word [bp+0xc]  ; 05A51
mov ax,0xe487  ; 05A54
push ax  ; 05A57
call init_file_system  ; 05A58
db 0x8B, 0xE5  ; 05A5B mov sp,bp
mov ax,0x1  ; 05A5D
push ax  ; 05A60
call show_insert_disk  ; 05A61
db 0x8B, 0xE5  ; 05A64 mov sp,bp
loc_05A66:
push word [0xe5c8]  ; 05A66
call string_copy  ; 05A6A
db 0x8B, 0xE5  ; 05A6D mov sp,bp
push ax  ; 05A6F
push word [bp+0x8]  ; 05A70
call format_string  ; 05A73
db 0x8B, 0xE5  ; 05A76 mov sp,bp
mov si,[bp+0x8]  ; 05A78
mov al,[si+0x8]  ; 05A7B
xor ah,ah  ; 05A7E
db 0x25, 0xF7, 0xFF  ; 05A80 and ax,0xfff7
mov [si+0x8],al  ; 05A83
cmp word [bp+0xa],0x0  ; 05A86
jz short loc_05A8F  ; 05A8A jz 0x5a8f
jmp 0x5d14  ; 05A8C
loc_05A8F:
push word [bp+0xc]  ; 05A8F
mov ax,0xe49e  ; 05A92
push ax  ; 05A95
call init_file_system  ; 05A96
db 0x8B, 0xE5  ; 05A99 mov sp,bp
mov ax,0x1  ; 05A9B
push ax  ; 05A9E
call show_insert_disk  ; 05A9F
db 0x8B, 0xE5  ; 05AA2 mov sp,bp
jmp short loc_05B14  ; 05AA4 jmp 0x5b14
mov byte [0xe1b9],0x0  ; 05AA6
mov al,0x1  ; 05AAB
mov bl,0x2  ; 05AAD
mov byte [0xe1d4],0x6  ; 05AAF
mov cx,[0xe5ca]  ; 05AB4
xor cx,[0xe5c6]  ; 05AB8
and cx,0x8000  ; 05ABC
mov [0xe1c7],al  ; 05AC0
mov [0xe1b8],al  ; 05AC3
mov [0xe1d5],bl  ; 05AC6
mov [0xe1c6],bl  ; 05ACA
jz short loc_05AD5  ; 05ACE jz 0x5ad5
mov ax,0x10  ; 05AD0
jmp short loc_05AD7  ; 05AD3 jmp 0x5ad7
loc_05AD5:
db 0x33, 0xC0  ; 05AD5 xor ax,ax
loc_05AD7:
mov [bp+0x5],ax  ; 05AD7
or ax,0xc0  ; 05ADA
mov word [0xe5fa],0x1  ; 05ADD
mov bx,[bp+0x5]  ; 05AE3
or bx,0xa0  ; 05AE6
mov word [0xe624],0x2  ; 05AEA
mov cx,0x1  ; 05AF0
push cx  ; 05AF3
mov [0xe5ce],al  ; 05AF4
mov [0xe622],bl  ; 05AF7
mov [0xe5f8],bl  ; 05AFB
call dos_ioctl  ; 05AFF
db 0x8B, 0xE5  ; 05B02 mov sp,bp
and ax,0x80  ; 05B04
jz short loc_05B14  ; 05B07 jz 0x5b14
mov al,[0xe1c6]  ; 05B09
xor ah,ah  ; 05B0C
db 0x0D, 0x04, 0x00  ; 05B0E or ax,0x4
mov [0xe1c6],al  ; 05B11
loc_05B14:
mov ax,0xe440  ; 05B14
push ax  ; 05B17
push word [0xe43e]  ; 05B18
call game_init  ; 05B1C
db 0x8B, 0xE5  ; 05B1F mov sp,bp
db 0x33, 0xC0  ; 05B21 xor ax,ax
push ax  ; 05B23
call show_insert_disk  ; 05B24
db 0x8B, 0xE5  ; 05B27 mov sp,bp
add sp,0xe  ; 05B29
pop bp  ; 05B2C
ret  ; 05B2D

; ---- function sub_05B2E ----
sub_05B2E:
push bp  ; 05B2E
sub sp,0x8  ; 05B2F
db 0x8B, 0xEC  ; 05B32 mov bp,sp
loc_05B34:
cmp word [bp+0x10],0x0  ; 05B34
jz short loc_05B6F  ; 05B38 jz 0x5b6f
mov si,[bp+0xc]  ; 05B3A
db 0x82  ; 05B3D
cmp al,0x0  ; 05B3E
jz short loc_05B6F  ; 05B40 jz 0x5b6f
mov di,[bp+0xe]  ; 05B42
db 0x82  ; 05B45
cmp ax,0x7400  ; 05B46
and ax,0xc68b  ; 05B49
inc word [bp+0xc]  ; 05B4C
inc word [bp+0xe]  ; 05B4F
mov bl,[di]  ; 05B52
xor bh,bh  ; 05B54
db 0x8B, 0xF0  ; 05B56 mov si,ax
mov cl,[si]  ; 05B58
xor ch,ch  ; 05B5A
db 0x2B, 0xCB  ; 05B5C sub cx,bx
mov [bp+0x6],cx  ; 05B5E
jz short loc_05B6A  ; 05B61 jz 0x5b6a
db 0x8B, 0xC1  ; 05B63 mov ax,cx
add sp,0x8  ; 05B65
pop bp  ; 05B68
ret  ; 05B69
loc_05B6A:
dec word [bp+0x10]  ; 05B6A
jmp short loc_05B34  ; 05B6D jmp 0x5b34
loc_05B6F:
cmp word [bp+0x10],0x0  ; 05B6F
jz short loc_05B95  ; 05B73 jz 0x5b95
mov si,[bp+0xc]  ; 05B75
db 0x82  ; 05B78
cmp al,0x0  ; 05B79
jz short loc_05B85  ; 05B7B jz 0x5b85
mov ax,0x1  ; 05B7D
add sp,0x8  ; 05B80
pop bp  ; 05B83
ret  ; 05B84
loc_05B85:
mov si,[bp+0xe]  ; 05B85
db 0x82  ; 05B88
cmp al,0x0  ; 05B89
jz short loc_05B95  ; 05B8B jz 0x5b95
mov ax,0xffff  ; 05B8D
add sp,0x8  ; 05B90
pop bp  ; 05B93
ret  ; 05B94
loc_05B95:
db 0x33, 0xC0  ; 05B95 xor ax,ax
add sp,0x8  ; 05B97
pop bp  ; 05B9A
ret  ; 05B9B

; ---- function load_resource_3 ----
load_resource_3:
push bp  ; 05B9C
sub sp,0x8  ; 05B9D
db 0x8B, 0xEC  ; 05BA0 mov bp,sp
push word [bp+0xc]  ; 05BA2
call sub_066B9  ; 05BA5
db 0x8B, 0xE5  ; 05BA8 mov sp,bp
mov bx,[bp+0xc]  ; 05BAA
db 0x03, 0xD8  ; 05BAD add bx,ax
mov [bp+0x6],bx  ; 05BAF
loc_05BB2:
mov si,[bp+0x6]  ; 05BB2
inc word [bp+0x6]  ; 05BB5
mov di,[bp+0xe]  ; 05BB8
inc word [bp+0xe]  ; 05BBB
mov al,[di]  ; 05BBE
mov [si],al  ; 05BC0
test al,al  ; 05BC2
jnz short loc_05BB2  ; 05BC4 jnz 0x5bb2
mov ax,[bp+0xc]  ; 05BC6
add sp,0x8  ; 05BC9
pop bp  ; 05BCC
ret  ; 05BCD
push bp  ; 05BCE
sub sp,0x6  ; 05BCF
db 0x8B, 0xEC  ; 05BD2 mov bp,sp
push word [bp+0xa]  ; 05BD4
call sub_066B9  ; 05BD7
db 0x8B, 0xE5  ; 05BDA mov sp,bp
mov bx,[bp+0xa]  ; 05BDC
db 0x03, 0xD8  ; 05BDF add bx,ax
mov [bp+0x4],bx  ; 05BE1
loc_05BE4:
mov ax,[bp+0xe]  ; 05BE4
dec word [bp+0xe]  ; 05BE7
test ax,ax  ; 05BEA
jng short loc_05C04  ; 05BEC jng 0x5c04
mov si,[bp+0xc]  ; 05BEE
inc word [bp+0xc]  ; 05BF1
mov al,[si]  ; 05BF4
mov di,[bp+0x4]  ; 05BF6
mov [di],al  ; 05BF9
test al,al  ; 05BFB
jz short loc_05C04  ; 05BFD jz 0x5c04
inc word [bp+0x4]  ; 05BFF
jmp short loc_05BE4  ; 05C02 jmp 0x5be4
loc_05C04:
mov si,[bp+0x4]  ; 05C04
mov byte [si],0x0  ; 05C07
mov ax,[bp+0xa]  ; 05C0A
add sp,0x6  ; 05C0D
pop bp  ; 05C10
ret  ; 05C11
