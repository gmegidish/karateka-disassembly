; Screen setup, timer/delay functions


; ---- function run_anim_script ----
run_anim_script:
mov byte [0xbcd0],0x1  ; 01734
call anim_cmd_init_sal  ; 01739
mov word [0xbce6],0x0  ; 0173C
mov byte [0xbcd7],0x0  ; 01742
loc_01747:
mov si,[0xbce6]  ; 01747
mov bl,[si-0x42fc]  ; 0174B
cmp bl,0xff  ; 0174F
jz short loc_0177D  ; 01752 jz 0x177d
mov bh,0x0  ; 01754
push word [0xbce6]  ; 01756
call word near [bx-0x4318]  ; 0175A
cmp word [0x156],0x0  ; 0175E
jz short loc_0177A  ; 01763 jz 0x177a
call poll_keyboard  ; 01765
db 0x3D, 0x00, 0x00  ; 01768 cmp ax,0x0
jz short loc_0177A  ; 0176B jz 0x177a
call wait_for_key  ; 0176D
pop word [0xbce6]  ; 01770
mov byte [0xbcd0],0x0  ; 01774
ret  ; 01779
loc_0177A:
pop ax  ; 0177A
jmp short loc_01747  ; 0177B jmp 0x1747
loc_0177D:
mov ax,0x0  ; 0177D
mov byte [0xbcd0],0x0  ; 01780
ret  ; 01785
mov al,[si-0x42fb]  ; 01786
mov [0xbb30],al  ; 0178A
add word [0xbce6],0x2  ; 0178D
ret  ; 01792
mov al,[si-0x42fb]  ; 01793
mov [0xbb32],al  ; 01797
add word [0xbce6],0x2  ; 0179A
ret  ; 0179F
mov di,[0xbb2e]  ; 017A0
mov al,[si-0x42fb]  ; 017A4
mov [di-0x44d0],al  ; 017A8
mov ax,[si-0x42fa]  ; 017AC
cmp byte [0xbcd7],0x0  ; 017B0
jz short loc_017BF  ; 017B5 jz 0x17bf
dec byte [0xbcd7]  ; 017B7
add ax,[0xbcd5]  ; 017BB
loc_017BF:
mov [di-0x44cf],ax  ; 017BF
mov al,[si-0x42f8]  ; 017C3
mov [di-0x44cd],al  ; 017C7
mov byte [di-0x44cc],0xff  ; 017CB
add word [0xbb2e],0x4  ; 017D0
add word [0xbce6],0x5  ; 017D5
ret  ; 017DA
mov bl,[si-0x42fb]  ; 017DB
mov bh,0x0  ; 017DF
shl bx,1  ; 017E1
shl bx,1  ; 017E3
mov ax,[si-0x42fa]  ; 017E5
mov [bx-0x44cd],ax  ; 017E9
mov ax,[si-0x42f8]  ; 017ED
mov [bx-0x44cb],ax  ; 017F1
add word [0xbce6],0x6  ; 017F5
ret  ; 017FA

; ---- function anim_cmd_do_scr ----
anim_cmd_do_scr:
call render_figures  ; 017FB
inc word [0xbce6]  ; 017FE
cmp word [0xbcd8],0x1  ; 01802
jnz short loc_0180C  ; 01807 jnz 0x180c
call wait_for_key  ; 01809
loc_0180C:
ret  ; 0180C
mov bl,[si+0x1]  ; 0180D
mov bh,0x0  ; 01810
shl bx,1  ; 01812
shl bx,1  ; 01814
add bx,0x3  ; 01816
sub word [0xbb2e],0x4  ; 01819
loc_0181E:
mov ax,[bx-0x44cc]  ; 0181E
mov [bx-0x44d0],ax  ; 01822
mov ax,[bx-0x44ca]  ; 01826
mov [bx-0x44ce],ax  ; 0182A
add bx,0x4  ; 0182E
cmp bx,[0xbb2e]  ; 01831
jl short loc_0181E  ; 01835 jl 0x181e
mov byte [bx-0x44d0],0xff  ; 01837
add word [0xbce6],0x2  ; 0183C
ret  ; 01841
mov byte [0xbb31],0x1  ; 01842
inc word [0xbce6]  ; 01847
ret  ; 0184B
mov byte [0xbb31],0x0  ; 0184C
inc word [0xbce6]  ; 01851
ret  ; 01855
cmp word [0xbcd8],0x0  ; 01856
jnz short loc_01866  ; 0185B jnz 0x1866
mov al,[si-0x42fb]  ; 0185D
mov ah,0x0  ; 01861
call delay_ticks  ; 01863
loc_01866:
add word [0xbce6],0x2  ; 01866
ret  ; 0186B

; ---- function anim_cmd_init_sal ----
anim_cmd_init_sal:
mov word [0xbb2a],0xffff  ; 0186C
mov word [0xee],0x1  ; 01872
mov byte [0xbb30],0x0  ; 01878
mov word [0xbb31],0x0  ; 0187D
mov byte [0xbb33],0xff  ; 01883
mov word [0xbb2e],0x3  ; 01888
inc word [0xbce6]  ; 0188E
ret  ; 01892
cmp word [0xbcd8],0x1  ; 01893
jnz short loc_018A5  ; 01898 jnz 0x18a5
call anim_cmd_do_scr  ; 0189A
call anim_cmd_init_sal  ; 0189D
sub word [0xbce6],0x2  ; 018A0
loc_018A5:
mov byte [0xbcd7],0x2  ; 018A5
add word [0xbce6],0x3  ; 018AA
ret  ; 018AF
mov al,[si-0x42fb]  ; 018B0
cbw  ; 018B4
add [0xbcd5],ax  ; 018B5
add word [0xbce6],0x2  ; 018B9
ret  ; 018BE

; ---- function delay_ticks ----
delay_ticks:
mov [0xbce2],ax  ; 018BF
mov ah,0x0  ; 018C2
int 0x1a  ; 018C4
add [0xbce2],dx  ; 018C6
loc_018CA:
mov ah,0x0  ; 018CA
int 0x1a  ; 018CC
cmp dx,[0xbce2]  ; 018CE
jnz short loc_018CA  ; 018D2 jnz 0x18ca
ret  ; 018D4

; ---- function delay_with_input ----
delay_with_input:
shr ax,1  ; 018D5
mov [0xbce4],ax  ; 018D7
loc_018DA:
mov ax,0x2  ; 018DA
call delay_ticks  ; 018DD
call poll_keyboard  ; 018E0
db 0x3D, 0x00, 0x00  ; 018E3 cmp ax,0x0
jnz short loc_018EE  ; 018E6 jnz 0x18ee
dec word [0xbce4]  ; 018E8
jnz short loc_018DA  ; 018EC jnz 0x18da
loc_018EE:
ret  ; 018EE

; ---- function timer_mark ----
timer_mark:
mov ah,0x0  ; 018EF
int 0x1a  ; 018F1
mov [0xbcd1],dx  ; 018F3
ret  ; 018F7

; ---- function timer_wait_3ticks ----
timer_wait_3ticks:
loc_018F8:
mov ah,0x0  ; 018F8
int 0x1a  ; 018FA
db 0x8B, 0xC2  ; 018FC mov ax,dx
sub dx,[0xbcd1]  ; 018FE
cmp dx,0x3  ; 01902
jc short loc_018F8  ; 01905 jc 0x18f8
mov [0xbcd1],ax  ; 01907
ret  ; 0190A

; ---- function set_music_callback ----
set_music_callback:
push bp  ; 0190B
db 0x8B, 0xEC  ; 0190C mov bp,sp
mov ax,[bp+0x2]  ; 0190E
mov [0xbcde],ax  ; 01911
mov ax,[0xea]  ; 01914
mov [0xbcda],ax  ; 01917
mov ax,[0xe4]  ; 0191A
mov [0xbcdc],ax  ; 0191D
lea ax,[0xbd04]  ; 01920
mov [0xbce0],bp  ; 01924
push ax  ; 01928
push word [bp+0x4]  ; 01929
call load_anim_script  ; 0192C
add sp,0x4  ; 0192F
mov bp,[0xbce0]  ; 01932
push word [bp+0x6]  ; 01936
call load_animation  ; 01939
add sp,0x2  ; 0193C
mov bp,[0xbce0]  ; 0193F
mov word [0xe4],0x0  ; 01943
call clear_screen  ; 01949
mov word [0xee],0x1  ; 0194C
mov word [0xea],0x4  ; 01952
call run_anim_script  ; 01958
mov word [0xd652],0xffff  ; 0195B
mov ax,[0xbcda]  ; 01961
mov [0xea],ax  ; 01964
mov ax,[0xbcdc]  ; 01967
mov [0xe4],ax  ; 0196A
mov bx,[0xbcde]  ; 0196D
mov [bp+0x2],bx  ; 01971
pop bp  ; 01974
ret  ; 01975

; ---- function build_anim_offsets_alt ----
build_anim_offsets_alt:
lea bx,[0xc428]  ; 01976
lea di,[0xc3d4]  ; 0197A

; ---- function build_anim_offsets ----
build_anim_offsets:
mov si,0x0  ; 0197E
mov cl,0x2a  ; 01981
loc_01983:
mov [di],si  ; 01983
add di,0x2  ; 01985
loc_01988:
cmp byte [bx+si],0xff  ; 01988
jz short loc_0199C  ; 0198B jz 0x199c
cmp byte [bx+si],0x18  ; 0198D
jnz short loc_01997  ; 01990 jnz 0x1997
add si,0x2  ; 01992
jmp short loc_01988  ; 01995 jmp 0x1988
loc_01997:
add si,0x11  ; 01997
jmp short loc_01988  ; 0199A jmp 0x1988
loc_0199C:
inc si  ; 0199C
dec cl  ; 0199D
jnz short loc_01983  ; 0199F jnz 0x1983
ret  ; 019A1
