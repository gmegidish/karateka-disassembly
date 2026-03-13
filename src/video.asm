; Video mode, cursor, shutdown


; ---- function game_shutdown ----
game_shutdown:
push bp  ; 005E5
db 0x8B, 0xEC  ; 005E6 mov bp,sp
mov ax,0x5dc  ; 005E8
push ax  ; 005EB
mov ax,0x41fb  ; 005EC
push ax  ; 005EF
call load_palette  ; 005F0
db 0x8B, 0xE5  ; 005F3 mov sp,bp
db 0x33, 0xC0  ; 005F5 xor ax,ax
push ax  ; 005F7
call combat_update  ; 005F8
db 0x8B, 0xE5  ; 005FB mov sp,bp
call clear_screen  ; 005FD
mov word [0xdf44],0x0  ; 00600
pop bp  ; 00606
ret  ; 00607
push bp  ; 00608
db 0x8B, 0xEC  ; 00609 mov bp,sp
mov ax,[bp+0x4]  ; 0060B
mov ah,0x0  ; 0060E
int 0x10  ; 00610
pop bp  ; 00612
ret  ; 00613
push bp  ; 00614
db 0x8B, 0xEC  ; 00615 mov bp,sp
mov ax,[bp+0x4]  ; 00617
db 0x8A, 0xD0  ; 0061A mov dl,al
mov ax,[bp+0x6]  ; 0061C
db 0x8A, 0xF0  ; 0061F mov dh,al
db 0x32, 0xFF  ; 00621 xor bh,bh
mov ah,0x2  ; 00623
int 0x10  ; 00625
pop bp  ; 00627
ret  ; 00628

; ---- function calc_screen_offset ----
calc_screen_offset:
push bp  ; 00629
db 0x8B, 0xEC  ; 0062A mov bp,sp
call sub_040D5  ; 0062C
shl ax,1  ; 0062F
mov [0x421a],ax  ; 00631
mov ax,[bp+0x4]  ; 00634
inc ax  ; 00637
mul word [0x421a]  ; 00638
db 0x8B, 0xC2  ; 0063C mov ax,dx
pop bp  ; 0063E
ret  ; 0063F
