; Controls, interrupt handlers, collision, disk prompts


; ---- function init_controls ----
init_controls:
push di  ; 04619
push si  ; 0461A
mov byte [0xe196],0x0  ; 0461B
mov dx,0x201  ; 04620
out dx,al  ; 04623
in al,dx  ; 04624
and al,0x3  ; 04625
cmp al,0x3  ; 04627
jnz short loc_0464C  ; 04629 jnz 0x464c
mov cx,0x0  ; 0462B
loop 0x462e  ; 0462E
in al,dx  ; 04630
and al,0x3  ; 04631
jnz short loc_0464C  ; 04633 jnz 0x464c
mov byte [0xe196],0x1  ; 04635
mov ah,0x1  ; 0463A
lea di,[0xe197]  ; 0463C
call sub_046FC  ; 04640
mov ah,0x2  ; 04643
lea di,[0xe19b]  ; 04645
call sub_046FC  ; 04649
loc_0464C:
push bp  ; 0464C
push ds  ; 0464D
db 0x33, 0xC0  ; 0464E xor ax,ax
mov ds,ax  ; 04650
db 0x8B, 0xF8  ; 04652 mov di,ax
mov bp,0x7  ; 04654
mov cx,0x1f40  ; 04657
mov bx,0x46c  ; 0465A
mov si,[bx]  ; 0465D
inc si  ; 0465F
db 0x03, 0xEE  ; 04660 add bp,si
loc_04662:
cmp si,[bx]  ; 04662
jnz short loc_04662  ; 04664 jnz 0x4662
loc_04666:
in al,dx  ; 04666
inc cx  ; 04667
loopne 0x466a  ; 04668
in al,dx  ; 0466A
inc cx  ; 0466B
loopne 0x466e  ; 0466C
mov ax,[bx]  ; 0466E
inc di  ; 04670
db 0x3B, 0xC5  ; 04671 cmp ax,bp
jnz short loc_04666  ; 04673 jnz 0x4666
pop ds  ; 04675
mov [0xe1a7],di  ; 04676
pop bp  ; 0467A
cmp di,0x2af8  ; 0467B
ja short loc_046B4  ; 0467F ja 0x46b4
mov bx,0x4  ; 04681
loc_04684:
inc byte [bx-0x28f2]  ; 04684
shr byte [bx-0x28f2],1  ; 04688
dec bx  ; 0468C
jnl short loc_04684  ; 0468D jnl 0x4684
mov bx,0x1c  ; 0468F
loc_04692:
mov si,[bx-0x28e8]  ; 04692
shr byte [si],1  ; 04696
cmp bx,0x6  ; 04698
jc short loc_046AD  ; 0469B jc 0x46ad
cmp bx,0xe  ; 0469D
ja short loc_046A6  ; 046A0 ja 0x46a6
inc byte [si]  ; 046A2
jmp short loc_046AD  ; 046A4 jmp 0x46ad
loc_046A6:
cmp bx,0x10  ; 046A6
jnz short loc_046AD  ; 046A9 jnz 0x46ad
dec byte [si]  ; 046AB
loc_046AD:
sub bx,0x2  ; 046AD
jnl short loc_04692  ; 046B0 jnl 0x4692
jmp short loc_046F4  ; 046B2 jmp 0x46f4
loc_046B4:
cmp di,0x34bc  ; 046B4
ja short loc_046D6  ; 046B8 ja 0x46d6
mov bx,0x1c  ; 046BA
loc_046BD:
mov si,[bx-0x28e8]  ; 046BD
cmp byte [si],0x6  ; 046C1
jc short loc_046C8  ; 046C4 jc 0x46c8
dec byte [si]  ; 046C6
loc_046C8:
cmp byte [si],0x8  ; 046C8
ja short loc_046CF  ; 046CB ja 0x46cf
dec byte [si]  ; 046CD
loc_046CF:
sub bx,0x2  ; 046CF
jnl short loc_046BD  ; 046D2 jnl 0x46bd
jmp short loc_046F4  ; 046D4 jmp 0x46f4
loc_046D6:
cmp di,0x4e20  ; 046D6
jc short loc_046F4  ; 046DA jc 0x46f4
mov bx,0x4  ; 046DC
loc_046DF:
shl byte [bx-0x28f2],1  ; 046DF
dec bx  ; 046E3
jnl short loc_046DF  ; 046E4 jnl 0x46df
mov bx,0x1c  ; 046E6
loc_046E9:
mov si,[bx-0x28e8]  ; 046E9
shl byte [si],1  ; 046ED
sub bx,0x2  ; 046EF
jnl short loc_046E9  ; 046F2 jnl 0x46e9
loc_046F4:
pop si  ; 046F4
pop di  ; 046F5
mov al,[0xe196]  ; 046F6
mov ah,0x0  ; 046F9
ret  ; 046FB

; ---- function sub_046FC ----
sub_046FC:
call sub_047EE  ; 046FC
push ax  ; 046FF
db 0x8B, 0xD8  ; 04700 mov bx,ax
shr bx,1  ; 04702
mov [di],bx  ; 04704
pop ax  ; 04706
db 0x03, 0xC3  ; 04707 add ax,bx
mov [di+0x2],ax  ; 04709
ret  ; 0470C

; ---- function sub_0470D ----
sub_0470D:
mov word [0xe19f],0x0  ; 0470D
mov byte [0xe1a5],0x0  ; 04713
mov byte [0xe1a6],0x0  ; 04718
cmp byte [0xe196],0x0  ; 0471D
jz short loc_04752  ; 04722 jz 0x4752
mov dx,0x201  ; 04724
in al,dx  ; 04727
db 0x8A, 0xE0  ; 04728 mov ah,al
and ah,0x30  ; 0472A
xor ah,0x30  ; 0472D
jz short loc_04752  ; 04730 jz 0x4752
test ah,0x10  ; 04732
jnz short loc_04742  ; 04735 jnz 0x4742
db 0x81, 0x0E, 0x9F, 0xE1, 0x20, 0x00  ; 04737 or word [0xe19f],0x20
mov byte [0xe1a6],0x1  ; 0473D
loc_04742:
test ah,0x20  ; 04742
jnz short loc_04752  ; 04745 jnz 0x4752
db 0x81, 0x0E, 0x9F, 0xE1, 0x10, 0x00  ; 04747 or word [0xe19f],0x10
mov byte [0xe1a5],0x1  ; 0474D
loc_04752:
mov ax,[0xe19f]  ; 04752
ret  ; 04755

; ---- function sub_04756 ----
sub_04756:
push di  ; 04756
push si  ; 04757
mov word [0xe19f],0x0  ; 04758
mov word [0xe1a1],0x0  ; 0475E
mov word [0xe1a3],0x0  ; 04764
cmp byte [0xe196],0x0  ; 0476A
jz short loc_047D9  ; 0476F jz 0x47d9
call sub_0470D  ; 04771
cmp word [bp+0x4],0x0  ; 04774
jnz short loc_047E4  ; 04778 jnz 0x47e4
mov dx,0x201  ; 0477A
mov ah,0x1  ; 0477D
call sub_047EE  ; 0477F
db 0x3D, 0x00, 0x00  ; 04782 cmp ax,0x0
jz short loc_047AB  ; 04785 jz 0x47ab
cmp ax,[0xe197]  ; 04787
jg short loc_0479A  ; 0478B jg 0x479a
db 0x81, 0x0E, 0x9F, 0xE1, 0x01, 0x00  ; 0478D or word [0xe19f],0x1
mov byte [0xe1a1],0x1  ; 04793
jmp short loc_047AB  ; 04798 jmp 0x47ab
loc_0479A:
cmp ax,[0xe199]  ; 0479A
jl short loc_047AB  ; 0479E jl 0x47ab
db 0x81, 0x0E, 0x9F, 0xE1, 0x02, 0x00  ; 047A0 or word [0xe19f],0x2
mov byte [0xe1a2],0x1  ; 047A6
loc_047AB:
mov ah,0x2  ; 047AB
call sub_047EE  ; 047AD
db 0x3D, 0x00, 0x00  ; 047B0 cmp ax,0x0
jz short loc_047D9  ; 047B3 jz 0x47d9
cmp ax,[0xe19b]  ; 047B5
jg short loc_047C8  ; 047B9 jg 0x47c8
db 0x81, 0x0E, 0x9F, 0xE1, 0x04, 0x00  ; 047BB or word [0xe19f],0x4
mov byte [0xe1a3],0x1  ; 047C1
jmp short loc_047D9  ; 047C6 jmp 0x47d9
loc_047C8:
cmp ax,[0xe19d]  ; 047C8
jl short loc_047D9  ; 047CC jl 0x47d9
db 0x81, 0x0E, 0x9F, 0xE1, 0x08, 0x00  ; 047CE or word [0xe19f],0x8
mov byte [0xe1a4],0x1  ; 047D4
loc_047D9:
mov ax,[0xe19f]  ; 047D9
test ax,0xf  ; 047DC
jz short loc_047E1  ; 047DF jz 0x47e1
loc_047E1:
pop si  ; 047E1
pop di  ; 047E2
ret  ; 047E3
loc_047E4:
db 0x3D, 0x00, 0x00  ; 047E4 cmp ax,0x0
jz short loc_047E1  ; 047E7 jz 0x47e1
mov ax,0xd  ; 047E9
jmp short loc_047E1  ; 047EC jmp 0x47e1

; ---- function sub_047EE ----
sub_047EE:
mov si,0x0  ; 047EE
mov bx,0x4  ; 047F1
loc_047F4:
call sub_04806  ; 047F4
db 0x03, 0xF1  ; 047F7 add si,cx
dec bx  ; 047F9
jnz short loc_047F4  ; 047FA jnz 0x47f4
mov cl,0x2  ; 047FC
shr si,cl  ; 047FE
mov ax,0x310  ; 04800
db 0x2B, 0xC6  ; 04803 sub ax,si
ret  ; 04805

; ---- function sub_04806 ----
sub_04806:
mov cx,0x310  ; 04806
out dx,al  ; 04809
in al,dx  ; 0480A
test ah,al  ; 0480B
loopne 0x480a  ; 0480D
ret  ; 0480F
push bx  ; 04810
push cx  ; 04811
push dx  ; 04812
push bp  ; 04813
push si  ; 04814
push di  ; 04815
push ds  ; 04816
push es  ; 04817
mov ax,0x6ca  ; 04818
mov ds,ax  ; 0481B
call check_disk_prompt  ; 0481D
mov al,0x1  ; 04820
pop es  ; 04822
pop ds  ; 04823
pop di  ; 04824
pop si  ; 04825
pop bp  ; 04826
pop dx  ; 04827
pop cx  ; 04828
pop bx  ; 04829
iret  ; 0482A

; ---- function install_handlers ----
install_handlers:
push ds  ; 0482B
mov ax,0x0  ; 0482C
mov ds,ax  ; 0482F
mov ax,0x2524  ; 04831
lea dx,[0x4810]  ; 04834
int 0x21  ; 04838 - INT 21h/AH=25h: Set interrupt vector 24h (critical error handler) to DS:DX
pop ds  ; 0483A
ret  ; 0483B

; ---- function restore_int_vectors ----
restore_int_vectors:
push bp  ; 0483C
sub sp,0x6  ; 0483D
db 0x8B, 0xEC  ; 04840 mov bp,sp
mov ax,0xe1b0  ; 04842
mov [bp+0x2],ax  ; 04845
loc_04848:
mov ax,0xe2c8  ; 04848
mov bx,[bp+0x2]  ; 0484B
db 0x3B, 0xD8  ; 0484E cmp bx,ax
jnc short loc_04861  ; 04850 jnc 0x4861
mov al,[bx+0x8]  ; 04852
xor ah,ah  ; 04855
test ax,ax  ; 04857
jz short loc_04861  ; 04859 jz 0x4861
add word [bp+0x2],0xe  ; 0485B
jmp short loc_04848  ; 0485F jmp 0x4848
loc_04861:
mov ax,[bp+0x2]  ; 04861
cmp ax,0xe2c8  ; 04864
jnz short loc_04870  ; 04867 jnz 0x4870
db 0x33, 0xC0  ; 04869 xor ax,ax
add sp,0x6  ; 0486B
pop bp  ; 0486E
ret  ; 0486F
loc_04870:
push word [bp+0x2]  ; 04870
push word [bp+0xc]  ; 04873
push word [bp+0xa]  ; 04876
call save_vectors  ; 04879
db 0x8B, 0xE5  ; 0487C mov sp,bp
add sp,0x6  ; 0487E
pop bp  ; 04881
ret  ; 04882

; ---- function save_vectors ----
save_vectors:
push bp  ; 04883
sub sp,0xe  ; 04884
db 0x8B, 0xEC  ; 04887 mov bp,sp
mov si,[bp+0x16]  ; 04889
db 0x82  ; 0488C
db 0x7C, 0x08  ; 0488D jl 0x4897
add [si+0x6],dh  ; 0488F
push si  ; 04892
call collision_check  ; 04893
db 0x8B, 0xE5  ; 04896 mov sp,bp
mov ax,[0xe5ca]  ; 04898
mov si,[bp+0x14]  ; 0489B
mov bl,[si+0x1]  ; 0489E
xor bh,bh  ; 048A1
mov [bp+0x8],ax  ; 048A3
mov [bp+0xa],si  ; 048A6
jmp short loc_048BC  ; 048A9 jmp 0x48bc
loc_048AB:
mov word [bp+0x8],0x0  ; 048AB
jmp short loc_048B7  ; 048B0 jmp 0x48b7
loc_048B2:
mov word [bp+0x8],0x8000  ; 048B2
loc_048B7:
inc word [bp+0xa]  ; 048B7
jmp short loc_048C6  ; 048BA jmp 0x48c6
loc_048BC:
cmp bx,0x62  ; 048BC
jz short loc_048B2  ; 048BF jz 0x48b2
cmp bx,0x61  ; 048C1
jz short loc_048AB  ; 048C4 jz 0x48ab
loc_048C6:
mov si,[bp+0xa]  ; 048C6
mov al,[si+0x1]  ; 048C9
xor ah,ah  ; 048CC
db 0x3D, 0x2B, 0x00  ; 048CE cmp ax,0x2b
jz short loc_048D7  ; 048D1 jz 0x48d7
db 0x33, 0xDB  ; 048D3 xor bx,bx
jmp short loc_048DA  ; 048D5 jmp 0x48da
loc_048D7:
db 0x33, 0xDB  ; 048D7 xor bx,bx
inc bx  ; 048D9
loc_048DA:
mov si,[bp+0x14]  ; 048DA
mov al,[si]  ; 048DD
xor ah,ah  ; 048DF
mov [bp+0xc],bl  ; 048E1
jmp 0x4bd1  ; 048E4
mov ax,[bp+0x8]  ; 048E7
db 0x0D, 0x08, 0x00  ; 048EA or ax,0x8
mov [bp+0x0],ax  ; 048ED
db 0x82  ; 048F0
db 0x7E, 0x0C  ; 048F1 jng 0x48ff
add [si+0x5],dh  ; 048F3
mov ax,0x2  ; 048F6
jmp short loc_048FE  ; 048F9 jmp 0x48fe
mov ax,0x1  ; 048FB
loc_048FE:
mov bx,[bp+0x0]  ; 048FE
db 0x0B, 0xD8  ; 04901 or bx,ax
or bx,0x100  ; 04903
mov ax,0x1a4  ; 04907
push ax  ; 0490A
push bx  ; 0490B
push word [bp+0x12]  ; 0490C
call file_manager  ; 0490F
db 0x8B, 0xE5  ; 04912 mov sp,bp
mov [bp+0x6],ax  ; 04914
inc ax  ; 04917
jnz short loc_04921  ; 04918 jnz 0x4921
db 0x33, 0xC0  ; 0491A xor ax,ax
add sp,0xe  ; 0491C
pop bp  ; 0491F
ret  ; 04920
loc_04921:
mov ax,0x2  ; 04921
push ax  ; 04924
db 0x33, 0xC0  ; 04925 xor ax,ax
push ax  ; 04927
db 0x33, 0xDB  ; 04928 xor bx,bx
push bx  ; 0492A
push word [bp+0x6]  ; 0492B
call parse_resource_data  ; 0492E
db 0x8B, 0xE5  ; 04931 mov sp,bp
db 0x82  ; 04933
db 0x7E, 0x0C  ; 04934 jng 0x4942
add [si+0x5],dh  ; 04936
mov ax,0x80  ; 04939
jmp short loc_04941  ; 0493C jmp 0x4941
mov ax,0x2  ; 0493E
loc_04941:
mov [bp+0x4],ax  ; 04941
jmp 0x4be8  ; 04944
db 0x82  ; 04947
db 0x7E, 0x0C  ; 04948 jng 0x4956
add [si+0x5],dh  ; 0494A
mov ax,0x2  ; 0494D
jmp short loc_04954  ; 04950 jmp 0x4954
db 0x33, 0xC0  ; 04952 xor ax,ax
loc_04954:
mov bx,[bp+0x8]  ; 04954
db 0x0B, 0xD8  ; 04957 or bx,ax
push bx  ; 04959
push word [bp+0x12]  ; 0495A
call file_manager  ; 0495D
db 0x8B, 0xE5  ; 04960 mov sp,bp
mov [bp+0x6],ax  ; 04962
inc ax  ; 04965
jnz short loc_0496F  ; 04966 jnz 0x496f
db 0x33, 0xC0  ; 04968 xor ax,ax
add sp,0xe  ; 0496A
pop bp  ; 0496D
ret  ; 0496E
loc_0496F:
db 0x82  ; 0496F
db 0x7E, 0x0C  ; 04970 jng 0x497e
add [si+0x5],dh  ; 04972
mov ax,0x80  ; 04975
jmp short loc_0497D  ; 04978 jmp 0x497d
mov ax,0x1  ; 0497A
loc_0497D:
mov [bp+0x4],ax  ; 0497D
jmp short loc_049E8  ; 04980 jmp 0x49e8
loc_04982:
db 0x82  ; 04982
db 0x7E, 0x0C  ; 04983 jng 0x4991
add [si+0x5],dh  ; 04985
mov ax,0x2  ; 04988
jmp short loc_04990  ; 0498B jmp 0x4990
mov ax,0x1  ; 0498D
loc_04990:
mov bx,[bp+0x8]  ; 04990
db 0x0B, 0xD8  ; 04993 or bx,ax
or bx,0x100  ; 04995
or bx,0x200  ; 04999
mov ax,0x1a4  ; 0499D
push ax  ; 049A0
push bx  ; 049A1
push word [bp+0x12]  ; 049A2
call file_manager  ; 049A5
db 0x8B, 0xE5  ; 049A8 mov sp,bp
mov [bp+0x6],ax  ; 049AA
inc ax  ; 049AD
jnz short loc_049B7  ; 049AE jnz 0x49b7
db 0x33, 0xC0  ; 049B0 xor ax,ax
add sp,0xe  ; 049B2
pop bp  ; 049B5
ret  ; 049B6
loc_049B7:
db 0x82  ; 049B7
db 0x7E, 0x0C  ; 049B8 jng 0x49c6
add [si+0x5],dh  ; 049BA
mov ax,0x80  ; 049BD
jmp short loc_049C5  ; 049C0 jmp 0x49c5
mov ax,0x2  ; 049C2
loc_049C5:
mov [bp+0x4],ax  ; 049C5
jmp short loc_049E8  ; 049C8 jmp 0x49e8
loc_049CA:
db 0x33, 0xC0  ; 049CA xor ax,ax
add sp,0xe  ; 049CC
pop bp  ; 049CF
ret  ; 049D0
db 0x3D, 0x77, 0x00  ; 049D1 cmp ax,0x77
jz short loc_04982  ; 049D4 jz 0x4982
db 0x3D, 0x72, 0x00  ; 049D6 cmp ax,0x72
jnz short loc_049DE  ; 049D9 jnz 0x49de
jmp 0x4b47  ; 049DB
loc_049DE:
db 0x3D, 0x61, 0x00  ; 049DE cmp ax,0x61
jnz short loc_049E6  ; 049E1 jnz 0x49e6
jmp 0x4ae7  ; 049E3
loc_049E6:
jmp short loc_049CA  ; 049E6 jmp 0x49ca
loc_049E8:
mov ax,[bp+0x6]  ; 049E8
mov bx,0x2a  ; 049EB
imul bx  ; 049EE
db 0x8B, 0xF0  ; 049F0 mov si,ax
db 0x82  ; 049F2
mov sp,0xe5cf  ; 049F3
add [si+0x13],dh  ; 049F6
db 0x81, 0x4E, 0x04, 0x04, 0x00  ; 049F9 or word [bp+0x4],0x4
mov ax,[bp+0x16]  ; 049FE
db 0x05, 0x0C, 0x00  ; 04A01 add ax,0xc
mov si,[bp+0x16]  ; 04A04
mov [si+0x6],ax  ; 04A07
jmp short loc_04A14  ; 04A0A jmp 0x4a14
mov si,[bp+0x16]  ; 04A0C
mov word [si+0x6],0x0  ; 04A0F
loc_04A14:
mov ax,[bp+0x6]  ; 04A14
mov si,[bp+0x16]  ; 04A17
mov [si+0x9],al  ; 04A1A
mov ax,[si+0x6]  ; 04A1D
mov [si],ax  ; 04A20
db 0x33, 0xC0  ; 04A22 xor ax,ax
mov [si+0x4],ax  ; 04A24
mov [si+0x2],ax  ; 04A27
mov ax,[bp+0x4]  ; 04A2A
mov [si+0x8],al  ; 04A2D
db 0x8B, 0xC6  ; 04A30 mov ax,si
add sp,0xe  ; 04A32
pop bp  ; 04A35
ret  ; 04A36

; ---- function collision_check ----
collision_check:
push bp  ; 04A37
sub sp,0x4  ; 04A38
db 0x8B, 0xEC  ; 04A3B mov bp,sp
mov si,[bp+0x8]  ; 04A3D
mov al,[si+0x8]  ; 04A40
xor ah,ah  ; 04A43
db 0x25, 0x02, 0x00  ; 04A45 and ax,0x2
jz short loc_04A54  ; 04A48 jz 0x4a54
push si  ; 04A4A
mov ax,0xffff  ; 04A4B
push ax  ; 04A4E
call sub_0644E  ; 04A4F
db 0x8B, 0xE5  ; 04A52 mov sp,bp
loc_04A54:
mov si,[bp+0x8]  ; 04A54
mov al,[si+0x8]  ; 04A57
xor ah,ah  ; 04A5A
db 0x25, 0x0C, 0x00  ; 04A5C and ax,0xc
jnz short loc_04A72  ; 04A5F jnz 0x4a72
cmp word [si+0xa],0x0  ; 04A61
jz short loc_04A72  ; 04A65 jz 0x4a72
push word [si+0xa]  ; 04A67
push word [si+0x6]  ; 04A6A
call sub_06954  ; 04A6D
db 0x8B, 0xE5  ; 04A70 mov sp,bp
loc_04A72:
db 0x33, 0xC0  ; 04A72 xor ax,ax
mov si,[bp+0x8]  ; 04A74
mov [si+0x6],ax  ; 04A77
mov [si+0xa],ax  ; 04A7A
mov byte [si+0x8],0x0  ; 04A7D
mov al,[si+0x9]  ; 04A81
xor ah,ah  ; 04A84
push ax  ; 04A86
call load_resource  ; 04A87
db 0x8B, 0xE5  ; 04A8A mov sp,bp
add sp,0x4  ; 04A8C
pop bp  ; 04A8F
ret  ; 04A90
push bp  ; 04A91
sub sp,0x8  ; 04A92
db 0x8B, 0xEC  ; 04A95 mov bp,sp
mov word [bp+0x4],0x0  ; 04A97
loc_04A9C:
mov ax,[0xe1b2]  ; 04A9C
dec ax  ; 04A9F
test ax,ax  ; 04AA0
mov [0xe1b2],ax  ; 04AA2
js short loc_04AB5  ; 04AA5 js 0x4ab5
mov si,[0xe1b0]  ; 04AA7
inc word [0xe1b0]  ; 04AAB
mov al,[si]  ; 04AAF
xor ah,ah  ; 04AB1
jmp short loc_04ABE  ; 04AB3 jmp 0x4abe
loc_04AB5:
mov ax,0xe1b0  ; 04AB5
push ax  ; 04AB8
call sub_06342  ; 04AB9
db 0x8B, 0xE5  ; 04ABC mov sp,bp
loc_04ABE:
db 0x3D, 0xFF, 0xFF  ; 04ABE cmp ax,0xffff
mov [bp+0x6],ax  ; 04AC1
jz short loc_04AED  ; 04AC4 jz 0x4aed
db 0x3D, 0x0A, 0x00  ; 04AC6 cmp ax,0xa
jnz short loc_04ADB  ; 04AC9 jnz 0x4adb
mov ax,[bp+0x4]  ; 04ACB
inc word [bp+0x4]  ; 04ACE
mov si,[bp+0xc]  ; 04AD1
db 0x03, 0xF0  ; 04AD4 add si,ax
mov byte [si],0x0  ; 04AD6
jmp short loc_04AED  ; 04AD9 jmp 0x4aed
loc_04ADB:
mov ax,[bp+0x4]  ; 04ADB
inc word [bp+0x4]  ; 04ADE
mov si,[bp+0xc]  ; 04AE1
db 0x03, 0xF0  ; 04AE4 add si,ax
mov ax,[bp+0x6]  ; 04AE6
mov [si],al  ; 04AE9
jmp short loc_04A9C  ; 04AEB jmp 0x4a9c
loc_04AED:
cmp word [bp+0x4],0x0  ; 04AED
jnz short loc_04AFA  ; 04AF1 jnz 0x4afa
db 0x33, 0xC0  ; 04AF3 xor ax,ax
add sp,0x8  ; 04AF5
pop bp  ; 04AF8
ret  ; 04AF9
loc_04AFA:
mov ax,[bp+0xc]  ; 04AFA
mov si,[bp+0x4]  ; 04AFD
db 0x03, 0xF0  ; 04B00 add si,ax
mov byte [si],0x0  ; 04B02
add sp,0x8  ; 04B05
pop bp  ; 04B08
ret  ; 04B09

; ---- function bounds_check ----
bounds_check:
push bp  ; 04B0A
sub sp,0x8  ; 04B0B
db 0x8B, 0xEC  ; 04B0E mov bp,sp
mov word [bp+0x4],0x0  ; 04B10
loc_04B15:
mov ax,[bp+0xe]  ; 04B15
dec ax  ; 04B18
mov bx,[bp+0x4]  ; 04B19
db 0x3B, 0xD8  ; 04B1C cmp bx,ax
jnl short loc_04B61  ; 04B1E jnl 0x4b61
mov si,[bp+0x10]  ; 04B20
mov ax,[si+0x2]  ; 04B23
dec ax  ; 04B26
mov [si+0x2],ax  ; 04B27
test ax,ax  ; 04B2A
js short loc_04B3A  ; 04B2C js 0x4b3a
mov ax,[si]  ; 04B2E
inc word [si]  ; 04B30
db 0x8B, 0xF8  ; 04B32 mov di,ax
mov bl,[di]  ; 04B34
xor bh,bh  ; 04B36
jmp short loc_04B44  ; 04B38 jmp 0x4b44
loc_04B3A:
push word [bp+0x10]  ; 04B3A
call sub_06342  ; 04B3D
db 0x8B, 0xE5  ; 04B40 mov sp,bp
db 0x8B, 0xD8  ; 04B42 mov bx,ax
loc_04B44:
mov [bp+0x6],bx  ; 04B44
inc bx  ; 04B47
jz short loc_04B61  ; 04B48 jz 0x4b61
mov ax,[bp+0x4]  ; 04B4A
inc word [bp+0x4]  ; 04B4D
mov si,[bp+0xc]  ; 04B50
db 0x03, 0xF0  ; 04B53 add si,ax
mov ax,[bp+0x6]  ; 04B55
mov [si],al  ; 04B58
db 0x3D, 0x0A, 0x00  ; 04B5A cmp ax,0xa
jnz short loc_04B15  ; 04B5D jnz 0x4b15
jmp short loc_04B61  ; 04B5F jmp 0x4b61
loc_04B61:
mov ax,[bp+0x4]  ; 04B61
mov si,[bp+0xc]  ; 04B64
db 0x03, 0xF0  ; 04B67 add si,ax
mov byte [si],0x0  ; 04B69
test ax,ax  ; 04B6C
jnz short loc_04B77  ; 04B6E jnz 0x4b77
db 0x33, 0xC0  ; 04B70 xor ax,ax
add sp,0x8  ; 04B72
pop bp  ; 04B75
ret  ; 04B76
loc_04B77:
mov ax,[bp+0xc]  ; 04B77
add sp,0x8  ; 04B7A
pop bp  ; 04B7D
ret  ; 04B7E

; ---- function show_insert_disk ----
show_insert_disk:
push bp  ; 04B7F
sub sp,0x4  ; 04B80
db 0x8B, 0xEC  ; 04B83 mov bp,sp
mov word [bp+0x2],0x0  ; 04B85
loc_04B8A:
mov ax,[bp+0x2]  ; 04B8A
db 0x3D, 0x14, 0x00  ; 04B8D cmp ax,0x14
jnl short loc_04BA5  ; 04B90 jnl 0x4ba5
mov bx,0xe  ; 04B92
imul bx  ; 04B95
add ax,0xe1b0  ; 04B97
push ax  ; 04B9A
call collision_check  ; 04B9B
db 0x8B, 0xE5  ; 04B9E mov sp,bp
inc word [bp+0x2]  ; 04BA0
jmp short loc_04B8A  ; 04BA3 jmp 0x4b8a
loc_04BA5:
mov word [bp+0x2],0x0  ; 04BA5
loc_04BAA:
mov ax,[bp+0x2]  ; 04BAA
cmp ax,[0xe5cc]  ; 04BAD
jnl short loc_04BBE  ; 04BB1 jnl 0x4bbe
push ax  ; 04BB3
call load_resource  ; 04BB4
db 0x8B, 0xE5  ; 04BB7 mov sp,bp
inc word [bp+0x2]  ; 04BB9
jmp short loc_04BAA  ; 04BBC jmp 0x4baa
loc_04BBE:
push word [bp+0xa]  ; 04BBE
push word [bp+0x8]  ; 04BC1
call crt_init_io  ; 04BC4
db 0x8B, 0xE5  ; 04BC7 mov sp,bp
add sp,0x4  ; 04BC9
pop bp  ; 04BCC
ret  ; 04BCD

; ---- function sub_04BCE ----
sub_04BCE:
push bp  ; 04BCE
sub sp,0xc  ; 04BCF
db 0x8B, 0xEC  ; 04BD2 mov bp,sp
mov ax,[bp+0x12]  ; 04BD4
mov bx,[bp+0x10]  ; 04BD7
mov cx,[0x67]  ; 04BDA
mov dx,[0x65]  ; 04BDE
call sub_06B3A  ; 04BE2
jng short loc_04C50  ; 04BE5 jng 0x4c50
mov al,[0xf]  ; 04BE7
xor ah,ah  ; 04BEA
db 0x3D, 0x02, 0x00  ; 04BEC cmp ax,0x2
jnl short loc_04BF8  ; 04BEF jnl 0x4bf8
db 0x33, 0xC0  ; 04BF1 xor ax,ax
add sp,0xc  ; 04BF3
pop bp  ; 04BF6
ret  ; 04BF7
loc_04BF8:
mov ax,[bp+0x10]  ; 04BF8
db 0x05, 0x0F, 0x00  ; 04BFB add ax,0xf
mov bx,[bp+0x12]  ; 04BFE
adc bx,0x0  ; 04C01
mov [bp+0xa],bx  ; 04C04
db 0x81, 0xE3, 0xF0, 0xFF  ; 04C07 and bx,0xfff0
mov [bp+0x8],ax  ; 04C0B
db 0x33, 0xC0  ; 04C0E xor ax,ax
db 0x0B, 0xD8  ; 04C10 or bx,ax
jz short loc_04C1B  ; 04C12 jz 0x4c1b
db 0x33, 0xC0  ; 04C14 xor ax,ax
add sp,0xc  ; 04C16
pop bp  ; 04C19
ret  ; 04C1A
loc_04C1B:
mov cx,0x4  ; 04C1B
mov ax,[bp+0xa]  ; 04C1E
mov bx,[bp+0x8]  ; 04C21
sar ax,1  ; 04C24
rcr bx,1  ; 04C26
loop 0x4c24  ; 04C28
push bx  ; 04C2A
mov [bp+0x6],bx  ; 04C2B
call crt_realloc_up  ; 04C2E
db 0x8B, 0xE5  ; 04C31 mov sp,bp
test ax,ax  ; 04C33
jz short loc_04C3E  ; 04C35 jz 0x4c3e
db 0x33, 0xC0  ; 04C37 xor ax,ax
add sp,0xc  ; 04C39
pop bp  ; 04C3C
ret  ; 04C3D
loc_04C3E:
mov ax,[bp+0xa]  ; 04C3E
mov bx,[bp+0x8]  ; 04C41
db 0x81, 0xE3, 0xF0, 0xFF  ; 04C44 and bx,0xfff0
add [0x65],bx  ; 04C48
adc [0x67],ax  ; 04C4C
loc_04C50:
mov ax,[0x15]  ; 04C50
mov bx,[0x61]  ; 04C53
db 0x03, 0xC3  ; 04C57 add ax,bx
mov cx,[bp+0x10]  ; 04C59
add [0x61],cx  ; 04C5C
sub [0x65],cx  ; 04C60
mov bx,[bp+0x12]  ; 04C64
sbb [0x67],bx  ; 04C67
mov [bp+0x4],ax  ; 04C6B
add sp,0xc  ; 04C6E
pop bp  ; 04C71
ret  ; 04C72
push bp  ; 04C73
sub sp,0x8  ; 04C74
db 0x8B, 0xEC  ; 04C77 mov bp,sp
mov ax,[bp+0xc]  ; 04C79
db 0x33, 0xDB  ; 04C7C xor bx,bx
push bx  ; 04C7E
push ax  ; 04C7F
call sub_04BCE  ; 04C80
db 0x8B, 0xE5  ; 04C83 mov sp,bp
mov [bp+0x6],ax  ; 04C85
test ax,ax  ; 04C88
jz short loc_04C91  ; 04C8A jz 0x4c91
add sp,0x8  ; 04C8C
pop bp  ; 04C8F
ret  ; 04C90
loc_04C91:
mov ax,0xffff  ; 04C91
add sp,0x8  ; 04C94
pop bp  ; 04C97
ret  ; 04C98

; ---- function resource_manager ----
resource_manager:
push bp  ; 04C99
sub sp,0xe  ; 04C9A
db 0x8B, 0xEC  ; 04C9D mov bp,sp
mov al,[0xf]  ; 04C9F
xor ah,ah  ; 04CA2
db 0x3D, 0x02, 0x00  ; 04CA4 cmp ax,0x2
jnl short loc_04CFC  ; 04CA7 jnl 0x4cfc
mov ax,[0x61]  ; 04CA9
sub ax,[0x5d]  ; 04CAC
db 0x33, 0xDB  ; 04CB0 xor bx,bx
test ax,ax  ; 04CB2
jns short loc_04CB7  ; 04CB4 jns 0x4cb7
dec bx  ; 04CB6
loc_04CB7:
mov cx,[0x65]  ; 04CB7
db 0x03, 0xC1  ; 04CBB add ax,cx
mov dx,[0x67]  ; 04CBD
db 0x13, 0xDA  ; 04CC1 adc bx,dx
mov cx,[0x15]  ; 04CC3
db 0x33, 0xD2  ; 04CC7 xor dx,dx
mov [0x65],ax  ; 04CC9
db 0x03, 0xC1  ; 04CCC add ax,cx
mov [0x67],bx  ; 04CCE
db 0x13, 0xDA  ; 04CD2 adc bx,dx
mov [bp+0x4],ax  ; 04CD4
db 0x8B, 0xC3  ; 04CD7 mov ax,bx
mov bx,[bp+0x4]  ; 04CD9
mov [bp+0x0],cx  ; 04CDC
mov cx,0x1  ; 04CDF
mov [bp+0x2],dx  ; 04CE2
db 0x33, 0xD2  ; 04CE5 xor dx,dx
call sub_06B3A  ; 04CE7
jng short loc_04D56  ; 04CEA jng 0x4d56
sub dx,[bp+0x0]  ; 04CEC
sbb cx,[bp+0x2]  ; 04CEF
mov [0x67],cx  ; 04CF2
mov [0x65],dx  ; 04CF6
jmp short loc_04D56  ; 04CFA jmp 0x4d56
loc_04CFC:
mov ax,[0xe4c0]  ; 04CFC
db 0x05, 0x0F, 0x00  ; 04CFF add ax,0xf
mov bx,[0xe4c2]  ; 04D02
adc bx,0x0  ; 04D06
mov [bp+0xc],bx  ; 04D09
db 0x81, 0xE3, 0xF0, 0xFF  ; 04D0C and bx,0xfff0
mov [bp+0xa],ax  ; 04D10
db 0x33, 0xC0  ; 04D13 xor ax,ax
db 0x0B, 0xD8  ; 04D15 or bx,ax
jz short loc_04D21  ; 04D17 jz 0x4d21
mov ax,0xffff  ; 04D19
add sp,0xe  ; 04D1C
pop bp  ; 04D1F
ret  ; 04D20
loc_04D21:
mov cx,0x4  ; 04D21
mov ax,[bp+0xc]  ; 04D24
mov bx,[bp+0xa]  ; 04D27
sar ax,1  ; 04D2A
rcr bx,1  ; 04D2C
loop 0x4d2a  ; 04D2E
push bx  ; 04D30
mov [bp+0x8],bx  ; 04D31
call crt_realloc_down  ; 04D34
db 0x8B, 0xE5  ; 04D37 mov sp,bp
test ax,ax  ; 04D39
jz short loc_04D45  ; 04D3B jz 0x4d45
mov ax,0xffff  ; 04D3D
add sp,0xe  ; 04D40
pop bp  ; 04D43
ret  ; 04D44
loc_04D45:
mov ax,[bp+0xc]  ; 04D45
mov bx,[bp+0xa]  ; 04D48
db 0x81, 0xE3, 0xF0, 0xFF  ; 04D4B and bx,0xfff0
mov [0x67],ax  ; 04D4F
mov [0x65],bx  ; 04D52
loc_04D56:
mov ax,[0x5d]  ; 04D56
db 0x33, 0xDB  ; 04D59 xor bx,bx
db 0x33, 0xC9  ; 04D5B xor cx,cx
mov [0x61],ax  ; 04D5D
mov [0xe4b8],cx  ; 04D60
mov [0xe4bc],cx  ; 04D64
mov [0xe4b6],bx  ; 04D68
mov [0xe4ba],bx  ; 04D6C
db 0x8B, 0xC3  ; 04D70 mov ax,bx
add sp,0xe  ; 04D72
pop bp  ; 04D75
ret  ; 04D76

; ---- function build_filename ----
build_filename:
push bp  ; 04D77
sub sp,0x2  ; 04D78
db 0x8B, 0xEC  ; 04D7B mov bp,sp
mov ax,[bp+0x6]  ; 04D7D
test ax,ax  ; 04D80
js short loc_04D9C  ; 04D82 js 0x4d9c
cmp ax,[0xe5cc]  ; 04D84
jnl short loc_04D9C  ; 04D88 jnl 0x4d9c
mov bx,0x2a  ; 04D8A
imul bx  ; 04D8D
db 0x8B, 0xF0  ; 04D8F mov si,ax
mov al,[si-0x1a32]  ; 04D91
xor ah,ah  ; 04D95
and ax,0x80  ; 04D97
jnz short loc_04DA9  ; 04D9A jnz 0x4da9
loc_04D9C:
mov word [0xe4be],0x9  ; 04D9C
db 0x33, 0xC0  ; 04DA2 xor ax,ax
add sp,0x2  ; 04DA4
pop bp  ; 04DA7
ret  ; 04DA8
loc_04DA9:
mov ax,[bp+0x6]  ; 04DA9
mov bx,0x2a  ; 04DAC
imul bx  ; 04DAF
add ax,0xe5ce  ; 04DB1
add sp,0x2  ; 04DB4
pop bp  ; 04DB7
ret  ; 04DB8

; ---- function file_manager ----
file_manager:
push bp  ; 04DB9
sub sp,0xc  ; 04DBA
db 0x8B, 0xEC  ; 04DBD mov bp,sp
mov word [bp+0x4],0x0  ; 04DBF
loc_04DC4:
mov ax,[bp+0x4]  ; 04DC4
mov bx,[0xe5cc]  ; 04DC7
db 0x3B, 0xD8  ; 04DCB cmp bx,ax
jng short loc_04DE5  ; 04DCD jng 0x4de5
mov bx,0x2a  ; 04DCF
imul bx  ; 04DD2
db 0x8B, 0xF0  ; 04DD4 mov si,ax
mov al,[si-0x1a32]  ; 04DD6
xor ah,ah  ; 04DDA
test ax,ax  ; 04DDC
jz short loc_04DE5  ; 04DDE jz 0x4de5
inc word [bp+0x4]  ; 04DE0
jmp short loc_04DC4  ; 04DE3 jmp 0x4dc4
loc_04DE5:
mov ax,[bp+0x4]  ; 04DE5
cmp ax,[0xe5cc]  ; 04DE8
jnz short loc_04DFC  ; 04DEC jnz 0x4dfc
mov word [0xe4be],0x18  ; 04DEE
mov ax,0xffff  ; 04DF4
add sp,0xc  ; 04DF7
pop bp  ; 04DFA
ret  ; 04DFB
loc_04DFC:
mov ax,[bp+0x4]  ; 04DFC
mov bx,0x2a  ; 04DFF
imul bx  ; 04E02
add ax,0xe5ce  ; 04E04
db 0x8B, 0xF0  ; 04E07 mov si,ax
mov ax,[0xe5c6]  ; 04E09
and ax,0x8000  ; 04E0C
mov bx,[bp+0x12]  ; 04E0F
db 0x33, 0xC3  ; 04E12 xor ax,bx
mov [bp+0x12],ax  ; 04E14
and ax,0x8000  ; 04E17
mov [bp+0xa],si  ; 04E1A
jz short loc_04E24  ; 04E1D jz 0x4e24
mov ax,0x10  ; 04E1F
jmp short loc_04E26  ; 04E22 jmp 0x4e26
loc_04E24:
db 0x33, 0xC0  ; 04E24 xor ax,ax
loc_04E26:
or ax,0x80  ; 04E26
mov si,[bp+0xa]  ; 04E29
mov [si],al  ; 04E2C
mov ax,[bp+0x12]  ; 04E2E
db 0x25, 0x03, 0x00  ; 04E31 and ax,0x3
jmp short loc_04E96  ; 04E34 jmp 0x4e96
loc_04E36:
mov si,[bp+0xa]  ; 04E36
mov al,[si]  ; 04E39
xor ah,ah  ; 04E3B
db 0x0D, 0x40, 0x00  ; 04E3D or ax,0x40
mov [si],al  ; 04E40
jmp short loc_04EA7  ; 04E42 jmp 0x4ea7
loc_04E44:
mov ax,[bp+0x12]  ; 04E44
db 0x25, 0x08, 0x00  ; 04E47 and ax,0x8
jz short loc_04E51  ; 04E4A jz 0x4e51
mov ax,0x8  ; 04E4C
jmp short loc_04E53  ; 04E4F jmp 0x4e53
loc_04E51:
db 0x33, 0xC0  ; 04E51 xor ax,ax
loc_04E53:
db 0x0D, 0x20, 0x00  ; 04E53 or ax,0x20
mov si,[bp+0xa]  ; 04E56
mov bl,[si]  ; 04E59
xor bh,bh  ; 04E5B
db 0x0B, 0xD8  ; 04E5D or bx,ax
mov [si],bl  ; 04E5F
jmp short loc_04EA7  ; 04E61 jmp 0x4ea7
loc_04E63:
mov ax,[bp+0x12]  ; 04E63
db 0x25, 0x08, 0x00  ; 04E66 and ax,0x8
jz short loc_04E70  ; 04E69 jz 0x4e70
mov ax,0x8  ; 04E6B
jmp short loc_04E72  ; 04E6E jmp 0x4e72
loc_04E70:
db 0x33, 0xC0  ; 04E70 xor ax,ax
loc_04E72:
db 0x0D, 0x60, 0x00  ; 04E72 or ax,0x60
mov si,[bp+0xa]  ; 04E75
mov bl,[si]  ; 04E78
xor bh,bh  ; 04E7A
db 0x0B, 0xD8  ; 04E7C or bx,ax
mov [si],bl  ; 04E7E
jmp short loc_04EA7  ; 04E80 jmp 0x4ea7
loc_04E82:
mov si,[bp+0xa]  ; 04E82
mov byte [si],0x0  ; 04E85
mov word [0xe4be],0x16  ; 04E88
mov ax,0xffff  ; 04E8E
add sp,0xc  ; 04E91
pop bp  ; 04E94
ret  ; 04E95
loc_04E96:
db 0x3D, 0x02, 0x00  ; 04E96 cmp ax,0x2
jz short loc_04E63  ; 04E99 jz 0x4e63
db 0x3D, 0x01, 0x00  ; 04E9B cmp ax,0x1
jz short loc_04E44  ; 04E9E jz 0x4e44
db 0x3D, 0x00, 0x00  ; 04EA0 cmp ax,0x0
jz short loc_04E36  ; 04EA3 jz 0x4e36
jmp short loc_04E82  ; 04EA5 jmp 0x4e82
loc_04EA7:
mov si,[bp+0x10]  ; 04EA7
mov al,[si]  ; 04EAA
xor ah,ah  ; 04EAC
test ax,ax  ; 04EAE
jnz short loc_04EC1  ; 04EB0 jnz 0x4ec1
mov si,[bp+0xa]  ; 04EB2
mov byte [si+0x1],0x1  ; 04EB5
mov ax,[bp+0x4]  ; 04EB9
add sp,0xc  ; 04EBC
pop bp  ; 04EBF
ret  ; 04EC0
loc_04EC1:
mov word [bp+0x6],0x0  ; 04EC1
loc_04EC6:
mov ax,[bp+0x6]  ; 04EC6
db 0x3D, 0x18, 0x00  ; 04EC9 cmp ax,0x18
jnl short loc_04F05  ; 04ECC jnl 0x4f05
mov bx,0xa  ; 04ECE
imul bx  ; 04ED1
add ax,0xe2c8  ; 04ED3
inc ax  ; 04ED6
push ax  ; 04ED7
push word [bp+0x10]  ; 04ED8
call crt_str_util  ; 04EDB
db 0x8B, 0xE5  ; 04EDE mov sp,bp
test ax,ax  ; 04EE0
jnz short loc_04F00  ; 04EE2 jnz 0x4f00
mov ax,[bp+0x6]  ; 04EE4
mov bx,0xa  ; 04EE7
imul bx  ; 04EEA
db 0x8B, 0xF0  ; 04EEC mov si,ax
mov al,[si-0x1d38]  ; 04EEE
mov di,[bp+0xa]  ; 04EF2
mov [di+0x1],al  ; 04EF5
mov ax,[bp+0x4]  ; 04EF8
add sp,0xc  ; 04EFB
pop bp  ; 04EFE
ret  ; 04EFF
loc_04F00:
inc word [bp+0x6]  ; 04F00
jmp short loc_04EC6  ; 04F03 jmp 0x4ec6
loc_04F05:
mov si,[bp+0xa]  ; 04F05
mov byte [si+0x1],0x0  ; 04F08
mov al,[0xf]  ; 04F0C
xor ah,ah  ; 04F0F
db 0x3D, 0x01, 0x00  ; 04F11 cmp ax,0x1
jg short loc_04F19  ; 04F14 jg 0x4f19
jmp 0x51b0  ; 04F16
loc_04F19:
mov ax,[bp+0x12]  ; 04F19
and ax,0x200  ; 04F1C
jz short loc_04F29  ; 04F1F jz 0x4f29
push word [bp+0x10]  ; 04F21
call dos_delete_file  ; 04F24
db 0x8B, 0xE5  ; 04F27 mov sp,bp
loc_04F29:
mov ax,[bp+0x12]  ; 04F29
db 0x25, 0x08, 0x00  ; 04F2C and ax,0x8
jz short loc_04F36  ; 04F2F jz 0x4f36
mov ax,0x2  ; 04F31
jmp short loc_04F3C  ; 04F34 jmp 0x4f3c
loc_04F36:
mov ax,[bp+0x12]  ; 04F36
db 0x25, 0x03, 0x00  ; 04F39 and ax,0x3
loc_04F3C:
push ax  ; 04F3C
push word [bp+0x10]  ; 04F3D
call dos_open_file  ; 04F40
db 0x8B, 0xE5  ; 04F43 mov sp,bp
mov si,[bp+0xa]  ; 04F45
mov [si+0x2],ax  ; 04F48
cmp word [0x80],0x0  ; 04F4B
jz short loc_04F86  ; 04F50 jz 0x4f86
mov ax,[bp+0x12]  ; 04F52
and ax,0x300  ; 04F55
jz short loc_04F6B  ; 04F58 jz 0x4f6b
db 0x33, 0xC0  ; 04F5A xor ax,ax
push ax  ; 04F5C
push word [bp+0x10]  ; 04F5D
call dos_create_file  ; 04F60
db 0x8B, 0xE5  ; 04F63 mov sp,bp
mov si,[bp+0xa]  ; 04F65
mov [si+0x2],ax  ; 04F68
loc_04F6B:
cmp word [0x80],0x0  ; 04F6B
jz short loc_04FB0  ; 04F70 jz 0x4fb0
mov word [0xe4be],0x2  ; 04F72
mov si,[bp+0xa]  ; 04F78
mov byte [si],0x0  ; 04F7B
mov ax,0xffff  ; 04F7E
add sp,0xc  ; 04F81
pop bp  ; 04F84
ret  ; 04F85
loc_04F86:
mov ax,[bp+0x12]  ; 04F86
and ax,0x500  ; 04F89
cmp ax,0x500  ; 04F8C
jnz short loc_04FB0  ; 04F8F jnz 0x4fb0
mov si,[bp+0xa]  ; 04F91
push word [si+0x2]  ; 04F94
call dos_close_file  ; 04F97
db 0x8B, 0xE5  ; 04F9A mov sp,bp
mov word [0xe4be],0x11  ; 04F9C
mov si,[bp+0xa]  ; 04FA2
mov byte [si],0x0  ; 04FA5
mov ax,0xffff  ; 04FA8
add sp,0xc  ; 04FAB
pop bp  ; 04FAE
ret  ; 04FAF
loc_04FB0:
mov ax,[bp+0x4]  ; 04FB0
add sp,0xc  ; 04FB3
pop bp  ; 04FB6
ret  ; 04FB7
push bp  ; 04FB8
sub sp,0x6  ; 04FB9
db 0x8B, 0xEC  ; 04FBC mov bp,sp
mov ax,[bp+0xc]  ; 04FBE
and ax,0x8000  ; 04FC1
or ax,0x301  ; 04FC4
mov bx,[bp+0xc]  ; 04FC7
and bx,0x7fff  ; 04FCA
push bx  ; 04FCE
push ax  ; 04FCF
push word [bp+0xa]  ; 04FD0
call file_manager  ; 04FD3
db 0x8B, 0xE5  ; 04FD6 mov sp,bp
add sp,0x6  ; 04FD8
pop bp  ; 04FDB
ret  ; 04FDC
