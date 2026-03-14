; Actor/character initialization and management


; ---- function init_actor ----
init_actor:
push bp  ; 00640
db 0x8B, 0xEC  ; 00641 mov bp,sp
mov byte [0x422c],0x0  ; 00643
mov byte [0x422e],0x0  ; 00648
mov si,[bp+0x4]  ; 0064D
shl si,1  ; 00650
mov bx,[si+0x423c]  ; 00652
mov [0x421e],bx  ; 00656
mov ax,[si-0x78c6]  ; 0065A
mov [0x4220],ax  ; 0065E
mov al,[bx+0x443c]  ; 00661
mov [0x4222],al  ; 00665
cbw  ; 00668
shl ax,1  ; 00669
shl ax,1  ; 0066B
mov [0x4224],ax  ; 0066D
mov al,[bx+0x443d]  ; 00670
mov [0x4223],al  ; 00674
cbw  ; 00677
sub [bp+0x8],ax  ; 00678
mov ax,[bp+0x8]  ; 0067B
mul byte [0x422b]  ; 0067E
mov [0x4230],ax  ; 00682
add word [0x421e],0x3  ; 00685
add word [0x4220],0x3  ; 0068A
mov ax,[bp+0x6]  ; 0068F
sub ax,[0xe4]  ; 00692
mov [bp+0x6],ax  ; 00696
db 0x8B, 0xD8  ; 00699 mov bx,ax
and al,0x3  ; 0069B
mov [0x4226],al  ; 0069D
shl al,1  ; 006A0
mov [0x4227],al  ; 006A2
sub bx,0x140  ; 006A5
add bx,[0x4224]  ; 006A9
jnl short loc_006B2  ; 006AD jnl 0x6b2
jmp short loc_0072D  ; 006AF jmp 0x72d
nop  ; 006B1
loc_006B2:
cmp word [bp+0x6],0x140  ; 006B2
jl short loc_006BC  ; 006B7 jl 0x6bc
jmp 0xa3a  ; 006B9
loc_006BC:
shr bx,1  ; 006BC
shr bx,1  ; 006BE
jz short loc_006D5  ; 006C0 jz 0x6d5
loc_006C2:
mov al,[0x4223]  ; 006C2
cbw  ; 006C5
db 0x8B, 0xF8  ; 006C6 mov di,ax
loc_006C8:
call advance_anim_frame  ; 006C8
dec di  ; 006CB
jnz short loc_006C8  ; 006CC jnz 0x6c8
dec byte [0x4222]  ; 006CE
dec bx  ; 006D2
jnz short loc_006C2  ; 006D3 jnz 0x6c2
loc_006D5:
cmp byte [0x4226],0x0  ; 006D5
jz short loc_0072D  ; 006DA jz 0x72d
mov al,[0x4223]  ; 006DC
mov [0x422a],al  ; 006DF
mov di,[0x4230]  ; 006E2
add di,0x4f  ; 006E6
loc_006E9:
call advance_anim_frame  ; 006E9
cmp al,0x0  ; 006EC
jz short loc_0071B  ; 006EE jz 0x71b
mov cx,0x8  ; 006F0
shr al,1  ; 006F3
rcl ah,1  ; 006F5
shr dl,1  ; 006F7
rcl dh,1  ; 006F9
loop 0x6f3  ; 006FB
xchg al,ah  ; 006FD
db 0x8A, 0xD6  ; 006FF mov dl,dh
not ax  ; 00701
mov cl,[0x4227]  ; 00703
ror ax,cl  ; 00707
and al,[di+0x337]  ; 00709
mov cl,[0x4227]  ; 0070D
mov dh,0x0  ; 00711
ror dx,cl  ; 00713
db 0x0A, 0xC2  ; 00715 or al,dl
mov [di+0x337],al  ; 00717
loc_0071B:
add di,0x50  ; 0071B
dec byte [0x422a]  ; 0071E
jnz short loc_006E9  ; 00722 jnz 0x6e9
dec byte [0x4222]  ; 00724
jnz short loc_0072D  ; 00728 jnz 0x72d
jmp 0xa3a  ; 0072A
loc_0072D:
mov ax,[bp+0x6]  ; 0072D
add ax,[0x4224]  ; 00730
jnl short loc_00739  ; 00734 jnl 0x739
jmp 0xa3a  ; 00736
loc_00739:
mov word [0x4228],0x0  ; 00739
cmp word [bp+0x6],0x0  ; 0073F
jnl short loc_0074B  ; 00743 jnl 0x74b
mov word [0x4228],0x1  ; 00745
loc_0074B:
mov ax,[bp+0x6]  ; 0074B
db 0x3D, 0x00, 0x00  ; 0074E cmp ax,0x0
jnl short loc_00755  ; 00751 jnl 0x755
db 0x33, 0xC0  ; 00753 xor ax,ax
loc_00755:
mov dx,[bp+0x6]  ; 00755
add dx,[0x4224]  ; 00758
cmp dx,0x140  ; 0075C
jl short loc_0076D  ; 00760 jl 0x76d
mov dx,0x140  ; 00762
mov bh,0x0  ; 00765
mov bl,[0x4226]  ; 00767
db 0x2B, 0xD3  ; 0076B sub dx,bx
loc_0076D:
shr ax,1  ; 0076D
shr ax,1  ; 0076F
shr dx,1  ; 00771
shr dx,1  ; 00773
mov [0x421c],dx  ; 00775
db 0x2B, 0xD0  ; 00779 sub dx,ax
db 0x8A, 0xDA  ; 0077B mov bl,dl
jng short loc_007EC  ; 0077D jng 0x7ec
mov ax,[0x4230]  ; 0077F
add [0x421c],ax  ; 00782
dec word [0x421c]  ; 00786
loc_0078A:
mov al,[0x4223]  ; 0078A
mov [0x422a],al  ; 0078D
mov di,[0x421c]  ; 00790
loc_00794:
call advance_anim_frame  ; 00794
cmp al,0x0  ; 00797
jz short loc_007DB  ; 00799 jz 0x7db
mov cx,0x8  ; 0079B
shr al,1  ; 0079E
rcl ah,1  ; 007A0
shr dl,1  ; 007A2
rcl dh,1  ; 007A4
loop 0x79e  ; 007A6
xchg al,ah  ; 007A8
db 0x8A, 0xD6  ; 007AA mov dl,dh
cmp byte [0x4226],0x0  ; 007AC
jz short loc_007CF  ; 007B1 jz 0x7cf
not ax  ; 007B3
mov cl,[0x4227]  ; 007B5
ror ax,cl  ; 007B9
and ax,[di+0x337]  ; 007BB
mov cl,[0x4227]  ; 007BF
mov dh,0x0  ; 007C3
ror dx,cl  ; 007C5
db 0x0B, 0xC2  ; 007C7 or ax,dx
mov [di+0x337],ax  ; 007C9
jmp short loc_007DB  ; 007CD jmp 0x7db
loc_007CF:
xor al,0xff  ; 007CF
and al,[di+0x337]  ; 007D1
db 0x0A, 0xC2  ; 007D5 or al,dl
mov [di+0x337],al  ; 007D7
loc_007DB:
add di,0x50  ; 007DB
dec byte [0x422a]  ; 007DE
jnz short loc_00794  ; 007E2 jnz 0x794
dec word [0x421c]  ; 007E4
dec bl  ; 007E8
jnz short loc_0078A  ; 007EA jnz 0x78a
loc_007EC:
cmp word [0x4228],0x0  ; 007EC
jz short loc_0083A  ; 007F1 jz 0x83a
mov al,[0x4223]  ; 007F3
mov [0x422a],al  ; 007F6
mov di,[0x4230]  ; 007F9
loc_007FD:
call advance_anim_frame  ; 007FD
cmp al,0x0  ; 00800
jz short loc_00831  ; 00802 jz 0x831
mov cx,0x8  ; 00804
shr al,1  ; 00807
rcl ah,1  ; 00809
shr dl,1  ; 0080B
rcl dh,1  ; 0080D
loop 0x807  ; 0080F
db 0x8A, 0xC4  ; 00811 mov al,ah
db 0x8A, 0xD6  ; 00813 mov dl,dh
mov ah,0x0  ; 00815
not ax  ; 00817
mov cl,[0x4227]  ; 00819
ror ax,cl  ; 0081D
and ah,[di+0x337]  ; 0081F
mov cl,[0x4227]  ; 00823
mov dh,0x0  ; 00827
ror dx,cl  ; 00829
db 0x0A, 0xE6  ; 0082B or ah,dh
mov [di+0x337],ah  ; 0082D
loc_00831:
add di,0x50  ; 00831
dec byte [0x422a]  ; 00834
jnz short loc_007FD  ; 00838 jnz 0x7fd
loc_0083A:
pop bp  ; 0083A
ret  ; 0083B

; ---- function process_animation ----
process_animation:
push bp  ; 0083C
db 0x8B, 0xEC  ; 0083D mov bp,sp
mov byte [0x422c],0x0  ; 0083F
mov byte [0x422e],0x0  ; 00844
mov si,[bp+0x4]  ; 00849
shl si,1  ; 0084C
mov bx,[si+0x423c]  ; 0084E
mov [0x421e],bx  ; 00852
mov ax,[si-0x78c6]  ; 00856
mov [0x4220],ax  ; 0085A
mov al,[bx+0x443c]  ; 0085D
mov [0x4222],al  ; 00861
cbw  ; 00864
shl ax,1  ; 00865
shl ax,1  ; 00867
mov [0x4224],ax  ; 00869
mov al,[bx+0x443d]  ; 0086C
mov [0x4223],al  ; 00870
cbw  ; 00873
sub [bp+0x8],ax  ; 00874
mov ax,[bp+0x8]  ; 00877
mul byte [0x422b]  ; 0087A
mov [0x4230],ax  ; 0087E
add word [0x421e],0x3  ; 00881
add word [0x4220],0x3  ; 00886
mov ax,[bp+0x6]  ; 0088B
sub ax,[0xe4]  ; 0088E
mov [bp+0x6],ax  ; 00892
jl short loc_0089A  ; 00895 jl 0x89a
jmp 0xb57  ; 00897
loc_0089A:
db 0x8B, 0xD8  ; 0089A mov bx,ax
add bx,[0x4224]  ; 0089C
jg short loc_008A5  ; 008A0 jg 0x8a5
jmp 0xc69  ; 008A2
loc_008A5:
db 0x33, 0xDB  ; 008A5 xor bx,bx
db 0x2B, 0xD8  ; 008A7 sub bx,ax
db 0x8A, 0xC3  ; 008A9 mov al,bl
and al,0x3  ; 008AB
mov ah,0x4  ; 008AD
db 0x2A, 0xE0  ; 008AF sub ah,al
and ah,0x3  ; 008B1
mov [0x4226],ah  ; 008B4
shl ah,1  ; 008B8
mov [0x4227],ah  ; 008BA
shr bx,1  ; 008BE
shr bx,1  ; 008C0
jz short loc_008F7  ; 008C2 jz 0x8f7
cmp byte [bp+0x4],0xc8  ; 008C4
jc short loc_008E0  ; 008C8 jc 0x8e0
mov al,[0x4223]  ; 008CA
mul bl  ; 008CD
add [0x421e],ax  ; 008CF
sub [0x4222],bl  ; 008D3
shl bx,1  ; 008D7
shl bx,1  ; 008D9
add [bp+0x6],bx  ; 008DB
jmp short loc_008F7  ; 008DE jmp 0x8f7
loc_008E0:
mov al,[0x4223]  ; 008E0
cbw  ; 008E3
db 0x8B, 0xF8  ; 008E4 mov di,ax
loc_008E6:
call advance_anim_frame  ; 008E6
dec di  ; 008E9
jnz short loc_008E6  ; 008EA jnz 0x8e6
add word [bp+0x6],0x4  ; 008EC
dec byte [0x4222]  ; 008F0
dec bx  ; 008F4
jnz short loc_008E0  ; 008F5 jnz 0x8e0
loc_008F7:
cmp byte [0x4226],0x0  ; 008F7
jz short loc_0094C  ; 008FC jz 0x94c
mov al,[0x4223]  ; 008FE
mov [0x422a],al  ; 00901
mov di,[0x4230]  ; 00904
cmp byte [bp+0x4],0xc8  ; 00908
jc short loc_00911  ; 0090C jc 0x911
jmp 0xc6b  ; 0090E
loc_00911:
call advance_anim_frame  ; 00911
cmp al,0x0  ; 00914
jz short loc_00936  ; 00916 jz 0x936
mov ah,0x0  ; 00918
db 0x23, 0xD0  ; 0091A and dx,ax
not ax  ; 0091C
mov cl,[0x4227]  ; 0091E
ror ax,cl  ; 00922
and ah,[di+0x337]  ; 00924
mov cl,[0x4227]  ; 00928
mov dh,0x0  ; 0092C
ror dx,cl  ; 0092E
db 0x0A, 0xE6  ; 00930 or ah,dh
mov [di+0x337],ah  ; 00932
loc_00936:
add di,0x50  ; 00936
dec byte [0x422a]  ; 00939
jnz short loc_00911  ; 0093D jnz 0x911
add word [bp+0x6],0x4  ; 0093F
dec byte [0x4222]  ; 00943
jnz short loc_0094C  ; 00947 jnz 0x94c
jmp 0xc69  ; 00949

; ---- function run_cutscene ----
run_cutscene:
loc_0094C:
mov al,[0x4222]  ; 0094C
cbw  ; 0094F
shl ax,1  ; 00950
shl ax,1  ; 00952
mov [0x4224],ax  ; 00954
mov ax,[bp+0x6]  ; 00957
and al,0x3  ; 0095A
mov [0x4226],al  ; 0095C
shl al,1  ; 0095F
mov [0x4227],al  ; 00961
mov ax,[bp+0x6]  ; 00964
sub ax,0x140  ; 00967
jng short loc_0096F  ; 0096A jng 0x96f
jmp 0xc69  ; 0096C
loc_0096F:
mov word [0x4228],0x0  ; 0096F
add ax,[0x4224]  ; 00975
jng short loc_00995  ; 00979 jng 0x995
cmp byte [0x4226],0x0  ; 0097B
jz short loc_00988  ; 00980 jz 0x988
mov word [0x4228],0x1  ; 00982
loc_00988:
mov al,[0x4226]  ; 00988
cbw  ; 0098B
add ax,0x140  ; 0098C
sub ax,[bp+0x6]  ; 0098F
mov [0x4224],ax  ; 00992
loc_00995:
mov ax,[bp+0x6]  ; 00995
db 0x8B, 0xD0  ; 00998 mov dx,ax
add ax,[0x4224]  ; 0099A
shr ax,1  ; 0099E
shr ax,1  ; 009A0
shr dx,1  ; 009A2
shr dx,1  ; 009A4
db 0x2B, 0xC2  ; 009A6 sub ax,dx
sub ax,[0x4228]  ; 009A8
db 0x8A, 0xE8  ; 009AC mov ch,al
jz short loc_00A1E  ; 009AE jz 0xa1e
mov di,[0x4230]  ; 009B0
mov dx,[bp+0x6]  ; 009B4
shr dx,1  ; 009B7
shr dx,1  ; 009B9
db 0x03, 0xFA  ; 009BB add di,dx
mov [0x4232],di  ; 009BD
cmp byte [bp+0x4],0xc8  ; 009C1
jc short loc_009CA  ; 009C5 jc 0x9ca
jmp 0xc9f  ; 009C7
loc_009CA:
mov al,[0x4223]  ; 009CA
db 0x8A, 0xD8  ; 009CD mov bl,al
mov di,[0x4232]  ; 009CF
loc_009D3:
call advance_anim_frame  ; 009D3
cmp al,0x0  ; 009D6
jz short loc_00A0B  ; 009D8 jz 0xa0b
cmp byte [0x4226],0x0  ; 009DA
jz short loc_009FF  ; 009DF jz 0x9ff
mov ah,0x0  ; 009E1
not ax  ; 009E3
mov cl,[0x4227]  ; 009E5
ror ax,cl  ; 009E9
and ax,[di+0x337]  ; 009EB
mov cl,[0x4227]  ; 009EF
mov dh,0x0  ; 009F3
ror dx,cl  ; 009F5
db 0x0B, 0xC2  ; 009F7 or ax,dx
mov [di+0x337],ax  ; 009F9
jmp short loc_00A0B  ; 009FD jmp 0xa0b
loc_009FF:
not al  ; 009FF
and al,[di+0x337]  ; 00A01
db 0x0A, 0xC2  ; 00A05 or al,dl
mov [di+0x337],al  ; 00A07
loc_00A0B:
add di,0x50  ; 00A0B
dec bl  ; 00A0E
jnz short loc_009D3  ; 00A10 jnz 0x9d3
add word [bp+0x6],0x4  ; 00A12
inc word [0x4232]  ; 00A16
dec ch  ; 00A1A
jnz short loc_009CA  ; 00A1C jnz 0x9ca
loc_00A1E:
cmp word [0x4228],0x0  ; 00A1E
jz short loc_00A69  ; 00A23 jz 0xa69
mov al,[0x4223]  ; 00A25
mov [0x422a],al  ; 00A28
mov di,[0x4230]  ; 00A2B
add di,0x4f  ; 00A2F
cmp byte [bp+0x4],0xc8  ; 00A32
jc short loc_00A3B  ; 00A36 jc 0xa3b
jmp 0xd1e  ; 00A38
loc_00A3B:
call advance_anim_frame  ; 00A3B
cmp al,0x0  ; 00A3E
jz short loc_00A60  ; 00A40 jz 0xa60
mov ah,0x0  ; 00A42
db 0x23, 0xD0  ; 00A44 and dx,ax
not ax  ; 00A46
mov cl,[0x4227]  ; 00A48
ror ax,cl  ; 00A4C
and al,[di+0x337]  ; 00A4E
mov cl,[0x4227]  ; 00A52
mov dh,0x0  ; 00A56
ror dx,cl  ; 00A58
db 0x0A, 0xC2  ; 00A5A or al,dl
mov [di+0x337],al  ; 00A5C
loc_00A60:
add di,0x50  ; 00A60
dec byte [0x422a]  ; 00A63
jnz short loc_00A3B  ; 00A67 jnz 0xa3b
loc_00A69:
pop bp  ; 00A69
ret  ; 00A6A
mov si,[0x421e]  ; 00A6B
loc_00A6F:
mov dl,[si+0x443c]  ; 00A6F
mov ax,0xff00  ; 00A73
inc si  ; 00A76
mov cl,[0x4227]  ; 00A77
ror ax,cl  ; 00A7B
and ah,[di+0x337]  ; 00A7D
mov cl,[0x4227]  ; 00A81
mov dh,0x0  ; 00A85
ror dx,cl  ; 00A87
db 0x0A, 0xE6  ; 00A89 or ah,dh
mov [di+0x337],ah  ; 00A8B
add di,0x50  ; 00A8F
dec byte [0x422a]  ; 00A92
jnz short loc_00A6F  ; 00A96 jnz 0xa6f
mov [0x421e],si  ; 00A98
jmp 0xb3f  ; 00A9C
mov bl,[0x4227]  ; 00A9F
db 0x32, 0xFF  ; 00AA3 xor bh,bh
mov si,[0x421e]  ; 00AA5
cmp bx,0x0  ; 00AA9
jnz short loc_00ADD  ; 00AAC jnz 0xadd
loc_00AAE:
mov al,[0x4223]  ; 00AAE
mov [0x422a],al  ; 00AB1
mov di,[0x4232]  ; 00AB4
loc_00AB8:
mov dl,[si+0x443c]  ; 00AB8
inc si  ; 00ABC
mov [di+0x337],dl  ; 00ABD
add di,0x50  ; 00AC1
dec byte [0x422a]  ; 00AC4
jnz short loc_00AB8  ; 00AC8 jnz 0xab8
add word [bp+0x6],0x4  ; 00ACA
inc word [0x4232]  ; 00ACE
dec ch  ; 00AD2
jnz short loc_00AAE  ; 00AD4 jnz 0xaae
mov [0x421e],si  ; 00AD6
jmp 0xc1e  ; 00ADA
loc_00ADD:
mov al,[0x4223]  ; 00ADD
mov [0x422a],al  ; 00AE0
mov di,[0x4232]  ; 00AE3
loc_00AE7:
mov dl,[si+0x443c]  ; 00AE7
inc si  ; 00AEB
mov ax,[bx+0x4234]  ; 00AEC
and ax,[di+0x337]  ; 00AF0
mov cl,[0x4227]  ; 00AF4
db 0x32, 0xF6  ; 00AF8 xor dh,dh
ror dx,cl  ; 00AFA
db 0x0B, 0xC2  ; 00AFC or ax,dx
mov [di+0x337],ax  ; 00AFE
add di,0x50  ; 00B02
dec byte [0x422a]  ; 00B05
jnz short loc_00AE7  ; 00B09 jnz 0xae7
add word [bp+0x6],0x4  ; 00B0B
inc word [0x4232]  ; 00B0F
dec ch  ; 00B13
jnz short loc_00ADD  ; 00B15 jnz 0xadd
mov [0x421e],si  ; 00B17
jmp 0xc1e  ; 00B1B
mov si,[0x421e]  ; 00B1E
loc_00B22:
mov dl,[si+0x443c]  ; 00B22
inc si  ; 00B26
mov ax,0xff00  ; 00B27
mov cl,[0x4227]  ; 00B2A
ror ax,cl  ; 00B2E
and al,[di+0x337]  ; 00B30
mov cl,[0x4227]  ; 00B34
mov dh,0x0  ; 00B38
ror dx,cl  ; 00B3A
db 0x0A, 0xC2  ; 00B3C or al,dl
mov [di+0x337],al  ; 00B3E
add di,0x50  ; 00B42
dec byte [0x422a]  ; 00B45
jnz short loc_00B22  ; 00B49 jnz 0xb22
jmp 0xc69  ; 00B4B
