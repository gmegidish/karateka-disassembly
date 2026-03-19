; Screen effects, vsync, buffers, UI, health bar, dialog


; ---- function effect_wipe ----
; Sets up a screen wipe transition effect, then calls effect_fade.
;
; Parameters (on stack):
;   [bp+0x6] = wipe type:
;              2 = wide wipe (speed 0x20, step 0x20)
;              7 = uses scene index 5
;              other = narrow wipe (speed 0, step 4), adds [0x12e] to scene index
;
; Uses globals:
;   [0xd672] = wipe state (incremented if == 1)
;   [0xbcd5] = wipe step size (4 or 0x20)
;   [0x102]  = wipe speed (0 or 0x20)
;   [0xc3a6] = scene/effect index (base 3, modified by type)
;   [0x12e]  = scene offset added to index
effect_wipe:
push bp  ; 03A2D
sub sp,0x2  ; 03A2E
jc short loc_03A39  ; 03A31 jc 0x3a39
cmp sp,[0x17]  ; 03A33
ja short loc_03A3C  ; 03A37 ja 0x3a3c
loc_03A39:
jmp 0x420  ; 03A39
loc_03A3C:
db 0x8B, 0xEC  ; 03A3C mov bp,sp
mov ax,[0xd672]  ; 03A3E
db 0x3D, 0x01, 0x00  ; 03A41 cmp ax,0x1
jnz short loc_03A4A  ; 03A44 jnz 0x3a4a
inc word [0xd672]  ; 03A46
loc_03A4A:
cmp word [bp+0x6],0x2  ; 03A4A
jnz short loc_03A5B  ; 03A4E jnz 0x3a5b
mov ax,0x20  ; 03A50
mov [0xbcd5],ax  ; 03A53
mov [0x102],ax  ; 03A56
jmp short loc_03A67  ; 03A59 jmp 0x3a67
loc_03A5B:
mov word [0x102],0x0  ; 03A5B
mov word [0xbcd5],0x4  ; 03A61
loc_03A67:
mov word [0xc3a6],0x3  ; 03A67
cmp word [bp+0x6],0x7  ; 03A6D
jnz short loc_03A7B  ; 03A71 jnz 0x3a7b
mov word [0xc3a6],0x5  ; 03A73
jmp short loc_03A82  ; 03A79 jmp 0x3a82
loc_03A7B:
mov ax,[0x12e]  ; 03A7B
add [0xc3a6],ax  ; 03A7E
loc_03A82:
call effect_fade  ; 03A82
add sp,0x2  ; 03A85
pop bp  ; 03A88
ret  ; 03A89

; ---- function effect_fade ----
; Initializes the fade/transition effect by loading parameters from lookup tables.
; No explicit parameters (reads scene index from [0xc3a6]).
;
; Uses three parallel lookup tables (indexed by [0xc3a6] * 2):
;   [si-0x3c58] -> [0xc3a0] (effect param 1)
;   [si-0x3c4a] -> [0xc3a2] (effect param 2)
;   [si-0x3c3c] -> [0xc3a4] (effect param 3)
;
; Also sets: [0xbb2a]=0xFFFF, [0xd652]=0, [0xee]=1 (buffer display mode)
effect_fade:
push bp  ; 03A8A
sub sp,0x4  ; 03A8B
jc short loc_03A96  ; 03A8E jc 0x3a96
cmp sp,[0x17]  ; 03A90
ja short loc_03A99  ; 03A94 ja 0x3a99
loc_03A96:
jmp 0x420  ; 03A96
loc_03A99:
db 0x8B, 0xEC  ; 03A99 mov bp,sp
mov word [0xbb2a],0xffff  ; 03A9B
mov word [0xd652],0x0  ; 03AA1
mov word [0xee],0x1  ; 03AA7
mov ax,[0xc3a6]  ; 03AAD
shl ax,1  ; 03AB0
db 0x8B, 0xF0  ; 03AB2 mov si,ax
mov bx,[si-0x3c58]  ; 03AB4
mov cx,[si-0x3c4a]  ; 03AB8
mov ax,[si-0x3c3c]  ; 03ABC
mov [0xc3a4],ax  ; 03AC0
mov [0xc3a2],cx  ; 03AC3
mov [0xc3a0],bx  ; 03AC7
add sp,0x4  ; 03ACB
pop bp  ; 03ACE
ret  ; 03ACF

; ---- function effect_scroll_left ----
; Initializes a leftward screen scroll transition.
; No explicit parameters. Reads scene index from [0x12c].
;
; Sets [0xee]=2 (background display mode), [0xbb2a]=0xFFFF, [0xd652]=0.
; Loads effect parameters from same lookup tables as effect_fade.
effect_scroll_left:
push bp  ; 03AD0
sub sp,0x4  ; 03AD1
jc short loc_03ADC  ; 03AD4 jc 0x3adc
cmp sp,[0x17]  ; 03AD6
ja short loc_03ADF  ; 03ADA ja 0x3adf
loc_03ADC:
jmp 0x420  ; 03ADC
loc_03ADF:
db 0x8B, 0xEC  ; 03ADF mov bp,sp
mov word [0xd652],0x0  ; 03AE1
mov ax,0x2  ; 03AE7
mov word [0xbb2a],0xffff  ; 03AEA
mov bx,[0x12c]  ; 03AF0
mov [0xc3a6],bx  ; 03AF4
shl bx,1  ; 03AF8
mov cx,[bx-0x3c58]  ; 03AFA
mov dx,[bx-0x3c4a]  ; 03AFE
mov [0xee],ax  ; 03B02
mov ax,[bx-0x3c3c]  ; 03B05
mov [0xc3a4],ax  ; 03B09
mov [0xc3a0],cx  ; 03B0C
mov [0xc3a2],dx  ; 03B10
add sp,0x4  ; 03B14
pop bp  ; 03B17
ret  ; 03B18

; ---- function effect_scroll_right ----
; Initializes a rightward screen scroll transition.
; No explicit parameters. Uses [0xce28] for position calculation.
;
; Sets [0xd5aa]=1, [0x110]=0x1F, calls rand_range(2) to
; compute scroll base address, then clears [0xfa] and [0xd650].
effect_scroll_right:
push bp  ; 03B19
sub sp,0x2  ; 03B1A
jc short loc_03B25  ; 03B1D jc 0x3b25
cmp sp,[0x17]  ; 03B1F
ja short loc_03B28  ; 03B23 ja 0x3b28
loc_03B25:
jmp 0x420  ; 03B25
loc_03B28:
db 0x8B, 0xEC  ; 03B28 mov bp,sp
mov word [0xd5aa],0x1  ; 03B2A
mov word [0x110],0x1f  ; 03B30
mov ax,[0xce28]  ; 03B36
mov bx,0x2  ; 03B39
push bx  ; 03B3C
mov [0xcde8],ax  ; 03B3D
call rand_range  ; 03B40
db 0x8B, 0xE5  ; 03B43 mov sp,bp
mov bx,0xc  ; 03B45
imul bx  ; 03B48
db 0x33, 0xDB  ; 03B4A xor bx,bx
mov [0xd5ac],ax  ; 03B4C
mov [0xfa],bx  ; 03B4F
mov [0xd650],bx  ; 03B53
add sp,0x2  ; 03B57
pop bp  ; 03B5A
ret  ; 03B5B

; ---- function effect_dissolve ----
; Performs one step of a dissolve transition effect.
; No explicit parameters. Decrements [0x116] each call.
;
; Each step: wait_vsync(1), subtract 4 from [0xbcd5].
; When [0x116] reaches 0: sets [0xf8]=1, loads [0xc40c] into [0xc3d2],
;   returns AX=0 (effect complete).
; Otherwise: increments [0x124], clears [0x10c], loads [0xc3d4] into [0xc3d2].
effect_dissolve:
push bp  ; 03B5C
sub sp,0x2  ; 03B5D
jc short loc_03B68  ; 03B60 jc 0x3b68
cmp sp,[0x17]  ; 03B62
ja short loc_03B6B  ; 03B66 ja 0x3b6b
loc_03B68:
jmp 0x420  ; 03B68
loc_03B6B:
db 0x8B, 0xEC  ; 03B6B mov bp,sp
mov ax,0x1  ; 03B6D
push ax  ; 03B70
call wait_vsync  ; 03B71
db 0x8B, 0xE5  ; 03B74 mov sp,bp
sub word [0xbcd5],0x4  ; 03B76
mov ax,[0x116]  ; 03B7B
dec ax  ; 03B7E
test ax,ax  ; 03B7F
mov [0x116],ax  ; 03B81
jnz short loc_03B99  ; 03B84 jnz 0x3b99
mov word [0xf8],0x1  ; 03B86
mov ax,[0xc40c]  ; 03B8C
mov [0xc3d2],ax  ; 03B8F
db 0x33, 0xC0  ; 03B92 xor ax,ax
add sp,0x2  ; 03B94
pop bp  ; 03B97
ret  ; 03B98
loc_03B99:
inc word [0x124]  ; 03B99
mov word [0x10c],0x0  ; 03B9D
mov ax,[0xc3d4]  ; 03BA3
mov [0xc3d2],ax  ; 03BA6
add sp,0x2  ; 03BA9
pop bp  ; 03BAC
ret  ; 03BAD

; ---- function wait_vsync ----
; Central timing/sync function. Dispatches to various sound and
; screen sync routines based on the sync type parameter.
; Called 21 times throughout the codebase.
;
; Parameters (on stack):
;   [bp+0x4] = sync type (BL):
;              0 = no-op (return immediately)
;              1-8, 9-21, 22-24, 25+ = different sync routines
;
; Uses globals:
;   [0xd6bc] = speed mode (0=normal, 1=selective skip, 2+=skip all)
;
; The unlabeled code blocks after loc_03BE7 (0x3BE9-0x3CF0) are
; individual sync routines reached via jump table at DS:0xD6BD
; ([bx-0x2943]). Each routine calls busy_wait_delay and/or toggle_speaker
; with different timing parameters, then returns via pop bp / ret.
;
; Sync routines at 0x3C97-0x3CF0 load music data pointers (BX = address
; of note data) and fall through to the music player at loc_03CF1.
; The music player reads note data: 0xFF=end, 0xFE=reset vibrato,
; 0xFD nn=set vibrato, else=play note with duration/pitch control.
wait_vsync:
push bp  ; 03BAE
db 0x8B, 0xEC  ; 03BAF mov bp,sp
mov bx,[bp+0x4]  ; 03BB1
cmp bl,0x0  ; 03BB4
jz short loc_03BE7  ; 03BB7 jz 0x3be7
cmp byte [0xd6bc],0x0  ; 03BB9
jz short loc_03BDA  ; 03BBE jz 0x3bda
cmp byte [0xd6bc],0x1  ; 03BC0
jz short loc_03BC9  ; 03BC5 jz 0x3bc9
pop bp  ; 03BC7
ret  ; 03BC8
loc_03BC9:
cmp bl,0x9  ; 03BC9
jc short loc_03BDA  ; 03BCC jc 0x3bda
cmp bl,0x16  ; 03BCE
jc short loc_03BE7  ; 03BD1 jc 0x3be7
cmp bl,0x19  ; 03BD3
jc short loc_03BDA  ; 03BD6 jc 0x3bda
pop bp  ; 03BD8
ret  ; 03BD9
loc_03BDA:
in al,byte 0x61  ; 03BDA
and al,0xfc  ; 03BDC
out byte 0x61,al  ; 03BDE
dec bx  ; 03BE0
shl bx,1  ; 03BE1
jmp word near [bx-0x2943]  ; 03BE3
loc_03BE7:
pop bp  ; 03BE7
ret  ; 03BE8
mov cx,0x2  ; 03BE9
loc_03BEC:
push cx  ; 03BEC
call toggle_speaker  ; 03BED
call busy_wait_delay  ; 03BF0
pop cx  ; 03BF3
inc cx  ; 03BF4
cmp cx,0x28  ; 03BF5
jl short loc_03BEC  ; 03BF8 jl 0x3bec
pop bp  ; 03BFA
ret  ; 03BFB
mov cx,0x2  ; 03BFC
loc_03BFF:
push cx  ; 03BFF
call toggle_speaker  ; 03C00
call busy_wait_delay  ; 03C03
pop cx  ; 03C06
inc cx  ; 03C07
inc cx  ; 03C08
cmp cx,0x3a  ; 03C09
jl short loc_03BFF  ; 03C0C jl 0x3bff
pop bp  ; 03C0E
ret  ; 03C0F
mov cx,0x2  ; 03C10
loc_03C13:
push cx  ; 03C13
call toggle_speaker  ; 03C14
call busy_wait_delay  ; 03C17
pop cx  ; 03C1A
inc cx  ; 03C1B
inc cx  ; 03C1C
cmp cx,0x24  ; 03C1D
jng short loc_03C13  ; 03C20 jng 0x3c13
pop bp  ; 03C22
ret  ; 03C23
mov bl,0xa  ; 03C24
loc_03C26:
mov cx,0x5  ; 03C26
call busy_wait_delay  ; 03C29
call toggle_speaker  ; 03C2C
dec bl  ; 03C2F
jnz short loc_03C26  ; 03C31 jnz 0x3c26
pop bp  ; 03C33
ret  ; 03C34
mov bl,0x10  ; 03C35
loc_03C37:
mov cx,0xa  ; 03C37
call busy_wait_delay  ; 03C3A
call toggle_speaker  ; 03C3D
dec bl  ; 03C40
jnz short loc_03C37  ; 03C42 jnz 0x3c37
pop bp  ; 03C44
ret  ; 03C45
mov cx,0x10  ; 03C46
loc_03C49:
push cx  ; 03C49
call toggle_speaker  ; 03C4A
call busy_wait_delay  ; 03C4D
pop cx  ; 03C50
shr cx,1  ; 03C51
cmp cx,0x1  ; 03C53
jnz short loc_03C49  ; 03C56 jnz 0x3c49
pop bp  ; 03C58
ret  ; 03C59
mov bl,0x3  ; 03C5A
loc_03C5C:
mov cx,0x10  ; 03C5C
call busy_wait_delay  ; 03C5F
call toggle_speaker  ; 03C62
dec bl  ; 03C65
jnz short loc_03C5C  ; 03C67 jnz 0x3c5c
pop bp  ; 03C69
ret  ; 03C6A
mov ax,[0xd710]  ; 03C6B
mov [speaker_delay],al  ; 03C6E
call play_speaker_data  ; 03C71
pop bp  ; 03C74
ret  ; 03C75
mov ax,[0xd712]  ; 03C76
mov [speaker_delay],al  ; 03C79
call play_speaker_data  ; 03C7C
pop bp  ; 03C7F
ret  ; 03C80
mov ax,[0xd714]  ; 03C81
mov [speaker_delay],al  ; 03C84
call play_speaker_data  ; 03C87
pop bp  ; 03C8A
ret  ; 03C8B
mov ax,[0xd716]  ; 03C8C
mov [speaker_delay],al  ; 03C8F
call play_speaker_data  ; 03C92
pop bp  ; 03C95
ret  ; 03C96
mov bx,0xd736  ; 03C97
jmp short loc_03CF1  ; 03C9A jmp 0x3cf1
nop  ; 03C9C
mov bx,0xd77e  ; 03C9D
jmp short loc_03CF1  ; 03CA0 jmp 0x3cf1
nop  ; 03CA2
mov bx,0xd7b2  ; 03CA3
jmp short loc_03CF1  ; 03CA6 jmp 0x3cf1
nop  ; 03CA8
mov bx,0xd7d7  ; 03CA9
jmp short loc_03CF1  ; 03CAC jmp 0x3cf1
nop  ; 03CAE
mov bx,0xd7e7  ; 03CAF
jmp short loc_03CF1  ; 03CB2 jmp 0x3cf1
nop  ; 03CB4
mov bx,0xd800  ; 03CB5
jmp short loc_03CF1  ; 03CB8 jmp 0x3cf1
nop  ; 03CBA
mov bx,0xd834  ; 03CBB
jmp short loc_03CF1  ; 03CBE jmp 0x3cf1
nop  ; 03CC0
mov bx,0xd853  ; 03CC1
jmp short loc_03CF1  ; 03CC4 jmp 0x3cf1
nop  ; 03CC6
mov bx,0xd87b  ; 03CC7
jmp short loc_03CF1  ; 03CCA jmp 0x3cf1
nop  ; 03CCC
mov bx,0xd894  ; 03CCD
jmp short loc_03CF1  ; 03CD0 jmp 0x3cf1
nop  ; 03CD2
mov bx,0xd8ce  ; 03CD3
jmp short loc_03CF1  ; 03CD6 jmp 0x3cf1
nop  ; 03CD8
mov bx,0xd911  ; 03CD9
jmp short loc_03CF1  ; 03CDC jmp 0x3cf1
nop  ; 03CDE
mov bx,0xd95a  ; 03CDF
jmp short loc_03CF1  ; 03CE2 jmp 0x3cf1
nop  ; 03CE4
mov bx,0xda25  ; 03CE5
jmp short loc_03CF1  ; 03CE8 jmp 0x3cf1
nop  ; 03CEA
mov bx,0xd817  ; 03CEB
jmp short loc_03CF1  ; 03CEE jmp 0x3cf1
nop  ; 03CF0
loc_03CF1:
mov al,[bx]  ; 03CF1
mov [music_tempo_hi],al  ; 03CF3
inc bx  ; 03CF6
mov al,[bx]  ; 03CF7
mov [music_tempo_lo],al  ; 03CF9
inc bx  ; 03CFC
mov [music_note_ptr],bx  ; 03CFD
loc_03D01:
mov bx,[music_note_ptr]  ; 03D01
mov al,[bx]  ; 03D05
cmp al,0xff  ; 03D07
jnz short loc_03D0D  ; 03D09 jnz 0x3d0d
pop bp  ; 03D0B
ret  ; 03D0C
loc_03D0D:
cmp al,0xfe  ; 03D0D
jnz short loc_03D1D  ; 03D0F jnz 0x3d1d
mov byte [music_vibrato],0x0  ; 03D11
inc bx  ; 03D16
mov [music_note_ptr],bx  ; 03D17
jmp short loc_03D01  ; 03D1B jmp 0x3d01
loc_03D1D:
cmp al,0xfd  ; 03D1D
jnz short loc_03D2E  ; 03D1F jnz 0x3d2e
inc bx  ; 03D21
mov al,[bx]  ; 03D22
mov [music_vibrato],al  ; 03D24
inc bx  ; 03D27
mov [music_note_ptr],bx  ; 03D28
jmp short loc_03D01  ; 03D2C jmp 0x3d01
loc_03D2E:
mov [music_note_cnt],al  ; 03D2E
inc bx  ; 03D31
mov al,[bx]  ; 03D32
mov [music_pitch_a],al  ; 03D34
mov [music_pitch_b],al  ; 03D37
mov [music_pitch],al  ; 03D3A
inc bx  ; 03D3D
mov al,[bx]  ; 03D3E
mov [music_period],al  ; 03D40
mov al,[music_period]  ; 03D43
db 0x8A, 0xC8  ; 03D46 mov cl,al
db 0x8A, 0xD0  ; 03D48 mov dl,al
loc_03D4A:
mov al,[music_tempo_hi]  ; 03D4A
mov [music_outer],al  ; 03D4D
loc_03D50:
mov byte [music_inner],0xff  ; 03D50
loc_03D55:
dec cl  ; 03D55
jnz short loc_03D7F  ; 03D57 jnz 0x3d7f
dec byte [music_pitch_a]  ; 03D59
jnz short loc_03D7F  ; 03D5D jnz 0x3d7f
cmp byte [music_pitch],0x80  ; 03D5F
jl short loc_03D69  ; 03D64 jl 0x3d69
call toggle_speaker  ; 03D66
loc_03D69:
mov cl,[music_period]  ; 03D69
mov al,[music_pitch]  ; 03D6D
mov [music_pitch_a],al  ; 03D70
cmp byte [music_vibrato],0x0  ; 03D73
jz short loc_03D7F  ; 03D78 jz 0x3d7f
mov al,[music_vibrato]  ; 03D7A
db 0x8A, 0xD0  ; 03D7D mov dl,al
loc_03D7F:
dec dl  ; 03D7F
jnz short loc_03D9F  ; 03D81 jnz 0x3d9f
dec byte [music_pitch_b]  ; 03D83
jnz short loc_03D7F  ; 03D87 jnz 0x3d7f
cmp byte [music_pitch],0x80  ; 03D89
jl short loc_03D93  ; 03D8E jl 0x3d93
call toggle_speaker  ; 03D90
loc_03D93:
mov dl,[music_period]  ; 03D93
dec dl  ; 03D97
mov al,[music_pitch]  ; 03D99
mov [music_pitch_b],al  ; 03D9C
loc_03D9F:
dec byte [music_inner]  ; 03D9F
jnz short loc_03D55  ; 03DA3 jnz 0x3d55
dec byte [music_outer]  ; 03DA5
jnz short loc_03D50  ; 03DA9 jnz 0x3d50
dec byte [music_note_cnt]  ; 03DAB
jnz short loc_03D4A  ; 03DAF jnz 0x3d4a
add word [music_note_ptr],0x3  ; 03DB1
jmp 0x3f01  ; 03DB6

; ---- function busy_wait_delay ----
; Nested busy-wait delay loop for frame timing.
;
; Parameters:
;   CX = inner loop count (delay factor)
;
; Uses globals:
;   [busy_wait_delay_cnt] = outer loop count
;
; Preserves BX, DX.
busy_wait_delay:
push dx  ; 03DB9
push bx  ; 03DBA
mov bx,[busy_wait_delay_cnt]  ; 03DBB
db 0x8B, 0xD1  ; 03DBF mov dx,cx
loc_03DC1:
db 0x8B, 0xCA  ; 03DC1 mov cx,dx
loc_03DC3:
push cx  ; 03DC3
loc_03DC4:
sbb cx,0x1  ; 03DC4
jnz short loc_03DC4  ; 03DC7 jnz 0x3dc4
pop cx  ; 03DC9
sbb cx,0x1  ; 03DCA
jnz short loc_03DC3  ; 03DCD jnz 0x3dc3
dec bx  ; 03DCF
jnz short loc_03DC1  ; 03DD0 jnz 0x3dc1
pop bx  ; 03DD2
pop dx  ; 03DD3
ret  ; 03DD4

; ---- function toggle_speaker ----
; Toggles the PC speaker gate (bit 1 of port 0x61).
; No parameters. Preserves AX.
toggle_speaker:
push ax  ; 03DD5
in al,byte 0x61  ; 03DD6
xor al,0x2  ; 03DD8
out byte 0x61,al  ; 03DDA
pop ax  ; 03DDC
ret  ; 03DDD

; ---- function play_speaker_data ----
; Plays 256 bytes of 1-bit audio data through the PC speaker.
; No parameters on stack.
;
; Reads audio data from DS:0xDA56. For each byte, processes 8 bits:
; each bit toggles the speaker when it differs from the previous state.
; Playback speed controlled by [speaker_delay] (delay loop per sample).
;
; Uses globals:
;   [speaker_delay] = sample delay (set before call)
;   [0xd70c] = delay counter (decremented per sample)
;   [speaker_prev_bit] = previous bit state (for edge detection)
play_speaker_data:
mov cx,0x100  ; 03DDE
mov bx,speaker_pcm_buf  ; 03DE1
mov dl,0x8  ; 03DE4
mov al,[bx]  ; 03DE6
loc_03DE8:
mov ah,[speaker_delay]  ; 03DE8
mov [speaker_delay_cnt],ah  ; 03DEC
loc_03DF0:
dec byte [speaker_delay_cnt]  ; 03DF0
jnz short loc_03DF0  ; 03DF4 jnz 0x3df0
xor al,[speaker_prev_bit]  ; 03DF6
jns short loc_03E10  ; 03DFA jns 0x3e10
xor al,[speaker_prev_bit]  ; 03DFC
mov [speaker_prev_bit],al  ; 03E00
call toggle_speaker  ; 03E03
loc_03E06:
shl al,1  ; 03E06
dec dl  ; 03E08
jnz short loc_03DE8  ; 03E0A jnz 0x3de8
inc bx  ; 03E0C
loop 0x3de4  ; 03E0D
ret  ; 03E0F
loc_03E10:
xor al,[speaker_prev_bit]  ; 03E10
jmp short loc_03E06  ; 03E14 jmp 0x3e06

; ---- function init_screen_buffers ----
; Swaps the double-buffer pointers and clears figure slot dirty flags.
; No parameters. No stack frame.
;
; Swaps [0xb87a] <-> [0xb89c] and shifts values through a chain of
; buffer pointer words (0xb89e through 0xb8a6).
; Then iterates figure slots (even indices 2..0x22, skipping 4->A and
; adding gap at C->E and 1C->1E), clearing bit 0 of each slot's
; 9-byte flag block at [slot_ptr-0x4795].
init_screen_buffers:
mov ax,[0xb87a]  ; 03E16
mov bx,[0xb89c]  ; 03E19
mov [0xb89c],ax  ; 03E1D
mov [0xb87a],bx  ; 03E20
mov ax,[0xb89e]  ; 03E24
mov [0xb87c],ax  ; 03E27
mov ax,[0xb8a0]  ; 03E2A
mov [0xb89e],ax  ; 03E2D
mov ax,[0xb8a2]  ; 03E30
mov [0xb8a0],ax  ; 03E33
mov ax,[0xb8a4]  ; 03E36
mov [0xb8a2],ax  ; 03E39
mov ax,[0xb8a6]  ; 03E3C
mov [0xb8a4],ax  ; 03E3F
mov bx,0x2  ; 03E42
loc_03E45:
cmp bx,0x4  ; 03E45
jnz short loc_03E4F  ; 03E48 jnz 0x3e4f
mov bx,0xa  ; 03E4A
jmp short loc_03E5F  ; 03E4D jmp 0x3e5f
loc_03E4F:
cmp bx,0xc  ; 03E4F
jnz short loc_03E57  ; 03E52 jnz 0x3e57
mov bx,0xe  ; 03E54
loc_03E57:
cmp bx,0x1c  ; 03E57
jnz short loc_03E5F  ; 03E5A jnz 0x3e5f
mov bx,0x1e  ; 03E5C
loc_03E5F:
mov si,[bx-0x4796]  ; 03E5F
mov cx,0x9  ; 03E63
mov al,[si-0x4795]  ; 03E66
and al,0xfe  ; 03E6A
mov [si-0x4795],al  ; 03E6C
inc si  ; 03E70
loop 0x3e66  ; 03E71
add bx,0x2  ; 03E73
cmp bx,0x24  ; 03E76
jl short loc_03E45  ; 03E79 jl 0x3e45
ret  ; 03E7B

; ---- function render_glyphs ----
; Renders a null-terminated string of custom game glyphs to the offscreen buffer.
; Characters below 'a' (0x61) are treated as spaces (advance 2 bytes).
;
; Parameters (registers):
;   SI = pointer to null-terminated text string
;   DI = destination offset in offscreen buffer
;
; Each glyph is looked up in the font bitmap table at DS:0xB86A
; (pointer table at DS:[-0x4796], widths at DS:[-0x248C]).
; Glyphs are variable-width, rendered column by column with
; sub-pixel alignment via shift_glyph_pixels.
;
; Uses globals:
;   [0xdbb1] = sub-pixel shift (0-3, multiplied by 2 for bit shift)
;   [0xdbb2] = column counter
;   [0xdbb4] = row counter
render_glyphs:
mov byte [0xdbb1],0x0  ; 03E7C
loc_03E81:
mov bl,[si]  ; 03E81
cmp bl,0x0  ; 03E83
jnz short loc_03E8B  ; 03E86 jnz 0x3e8b
jmp 0x4128  ; 03E88
loc_03E8B:
sub bl,0x61  ; 03E8B
jnl short loc_03E96  ; 03E8E jnl 0x3e96
add di,0x2  ; 03E90
inc si  ; 03E93
jmp short loc_03E81  ; 03E94 jmp 0x3e81
loc_03E96:
inc si  ; 03E96
mov bh,0x0  ; 03E97
push si  ; 03E99
db 0x8B, 0xF3  ; 03E9A mov si,bx
shl bx,1  ; 03E9C
mov ax,[bx-0x4796]  ; 03E9E
lea bx,[0xb86a]  ; 03EA2
db 0x03, 0xD8  ; 03EA6 add bx,ax
mov ch,[si-0x248c]  ; 03EA8
mov [0xdbb2],ch  ; 03EAC
loc_03EB0:
push di  ; 03EB0
mov cl,[si-0x24aa]  ; 03EB1
mov [0xdbb4],cl  ; 03EB5
loc_03EB9:
mov ah,[bx]  ; 03EB9
mov ch,0x8  ; 03EBB
loc_03EBD:
sar ax,1  ; 03EBD
rcl ax,1  ; 03EBF
rcr dx,1  ; 03EC1
rcl ax,1  ; 03EC3
rcr dx,1  ; 03EC5
dec ch  ; 03EC7
jnz short loc_03EBD  ; 03EC9 jnz 0x3ebd
db 0x33, 0xC0  ; 03ECB xor ax,ax
call shift_glyph_pixels  ; 03ECD
xchg dh,dl  ; 03ED0
xchg ah,al  ; 03ED2
or [di],dx  ; 03ED4
or [di+0x2],ax  ; 03ED6
add di,0x50  ; 03ED9
inc bx  ; 03EDC
dec byte [0xdbb4]  ; 03EDD
jnz short loc_03EB9  ; 03EE1 jnz 0x3eb9
pop di  ; 03EE3
add di,0x2  ; 03EE4
dec byte [0xdbb2]  ; 03EE7
jnz short loc_03EB0  ; 03EEB jnz 0x3eb0
mov ah,[0xdbb1]  ; 03EED
add ah,[si-0x246e]  ; 03EF1
mov al,[si-0x248c]  ; 03EF5
shl al,1  ; 03EF9
shl al,1  ; 03EFB
shl al,1  ; 03EFD
db 0x2A, 0xC4  ; 03EFF sub al,ah
cmp al,0xfc  ; 03F01
jg short loc_03F09  ; 03F03 jg 0x3f09
inc di  ; 03F05
jmp short loc_03F10  ; 03F06 jmp 0x3f10
nop  ; 03F08
loc_03F09:
sub al,0x4  ; 03F09
jl short loc_03F10  ; 03F0B jl 0x3f10
dec di  ; 03F0D
jmp short loc_03F09  ; 03F0E jmp 0x3f09
loc_03F10:
mov ah,[si-0x246e]  ; 03F10
add [0xdbb1],ah  ; 03F14
and byte [0xdbb1],0x3  ; 03F18
jz short loc_03F24  ; 03F1D jz 0x3f24
cmp al,0xfc  ; 03F1F
jl short loc_03F24  ; 03F21 jl 0x3f24
dec di  ; 03F23
loc_03F24:
pop si  ; 03F24
jmp 0x4081  ; 03F25
ret  ; 03F28

; ---- function shift_glyph_pixels ----
; Shifts a 32-bit pixel value (DX:AX) right by [0xdbb1]*2 bits
; for sub-pixel glyph alignment in CGA's 2-bit-per-pixel mode.
;
; Parameters (registers):
;   DX:AX = 32-bit pixel data to shift
;
; Returns:
;   DX:AX = shifted pixel data
;
; If [0xdbb1] == 0, returns immediately (no shift needed).
shift_glyph_pixels:
cmp byte [0xdbb1],0x0  ; 03F29
jz short loc_03F3E  ; 03F2E jz 0x3f3e
mov cl,[0xdbb1]  ; 03F30
shl cl,1  ; 03F34
loc_03F36:
shr dx,1  ; 03F36
rcr ax,1  ; 03F38
dec cl  ; 03F3A
jnz short loc_03F36  ; 03F3C jnz 0x3f36
loc_03F3E:
ret  ; 03F3E

; ---- function show_scroll_text ----
; Shows scrolling story narration text (intro/outro).
; No parameters. No stack frame.
;
; Uses globals:
;   [0xdbb5] = number of text lines to display
;   [0xdbb6] = start of text data (null-terminated lines)
;
; Clears screen, then calls scroll_text_up to animate the scroll.
show_scroll_text:
call clear_screen  ; 03F3F
call update_display  ; 03F42
mov al,[0xdbb5]  ; 03F45
mov [0xdbb3],al  ; 03F48
lea ax,[0xdbb6]  ; 03F4B
mov [0xddbe],ax  ; 03F4F
call scroll_text_up  ; 03F52
ret  ; 03F55

; ---- function draw_ui_element ----
; Draws a single UI text element at a fixed screen position.
; No parameters. No stack frame.
;
; Renders text from DS:0xDEB6 at buffer position DS:0x20B6,
; then displays and waits 0x48 ticks (~4 seconds).
draw_ui_element:
call clear_screen  ; 03F56
call update_display  ; 03F59
lea di,[0x20b6]  ; 03F5C
lea si,[0xdeb6]  ; 03F60
call render_glyphs  ; 03F64
call update_display  ; 03F67
mov ax,0x48  ; 03F6A
call delay_with_input  ; 03F6D
ret  ; 03F70

; ---- function show_dialog ----
; Shows a multi-line dialog box and waits for keypress or joystick.
; No parameters. No stack frame.
;
; Uses globals:
;   [0xddc0] = number of text lines
;   [0xddc1] = start of text data (null-terminated lines)
;   [0xdf44] = joystick button state (nonzero = pressed)
;
; Lines are rendered 0x3C0 bytes apart (12 CGA scanlines) starting
; at buffer offset DS:0x977. Polls keyboard with wait_vsync(0x15)
; between checks.
show_dialog:
call flush_keyboard  ; 03F71
call clear_screen  ; 03F74
call update_display  ; 03F77
push word [0xddc0]  ; 03F7A
lea si,[0xddc1]  ; 03F7E
lea di,[0x977]  ; 03F82
loc_03F86:
push di  ; 03F86
call render_glyphs  ; 03F87
pop di  ; 03F8A
add di,0x3c0  ; 03F8B
inc si  ; 03F8F
dec byte [0xddc0]  ; 03F90
jnz short loc_03F86  ; 03F94 jnz 0x3f86
pop word [0xddc0]  ; 03F96
call update_display  ; 03F9A
loc_03F9D:
mov ax,0x15  ; 03F9D
push ax  ; 03FA0
call wait_vsync  ; 03FA1
pop ax  ; 03FA4
call poll_keyboard  ; 03FA5
cmp word [0xdf44],0x0  ; 03FA8
jnz short loc_03FB6  ; 03FAD jnz 0x3fb6
cmp al,0x0  ; 03FAF
jz short loc_03F9D  ; 03FB1 jz 0x3f9d
call wait_for_key  ; 03FB3
loc_03FB6:
ret  ; 03FB6

; ---- function draw_scene_element ----
; Draws two lines of scene text (e.g., credits) at fixed positions.
; No parameters. No stack frame.
;
; Line 1: DS:0xDEBE at buffer DS:0x1D92
; Line 2: DS:0xDEC8 at buffer DS:0x228B
; Waits 0x48 ticks after display.
draw_scene_element:
call clear_screen  ; 03FB7
lea di,[0x1d92]  ; 03FBA
lea si,[0xdebe]  ; 03FBE
call render_glyphs  ; 03FC2
lea di,[0x228b]  ; 03FC5
lea si,[0xdec8]  ; 03FC9
call render_glyphs  ; 03FCD
call update_display  ; 03FD0
mov ax,0x48  ; 03FD3
call delay_with_input  ; 03FD6
ret  ; 03FD9

; ---- function draw_gate ----
; Draws two lines of gate/door text at fixed positions.
; No parameters. No stack frame.
;
; Line 1: DS:0xDED7 at buffer DS:0x1D8D
; Line 2: DS:0xDEE6 at buffer DS:0x2287
; Waits 0x48 ticks after display.
draw_gate:
call clear_screen  ; 03FDA
lea di,[0x1d8d]  ; 03FDD
lea si,[0xded7]  ; 03FE1
call render_glyphs  ; 03FE5
lea di,[0x2287]  ; 03FE8
lea si,[0xdee6]  ; 03FEC
call render_glyphs  ; 03FF0
call update_display  ; 03FF3
mov ax,0x48  ; 03FF6
call delay_with_input  ; 03FF9
ret  ; 03FFC

; ---- function check_disk_prompt ----
; Shows "make sure your karateka disk is in drive a" prompt (3 lines).
; Waits for any keypress before returning.
; No parameters. No stack frame.
;
; Line 1: DS:0xDEFA at buffer DS:0x1B01
; Line 2: DS:0xDF12 at buffer DS:0x2009
; Line 3: DS:0xDF26 at buffer DS:0x24FF
check_disk_prompt:
call clear_screen  ; 03FFD
lea di,[0x1b01]  ; 04000
lea si,[0xdefa]  ; 04004
call render_glyphs  ; 04008
lea di,[0x2009]  ; 0400B
lea si,[0xdf12]  ; 0400F
call render_glyphs  ; 04013
lea di,[0x24ff]  ; 04016
lea si,[0xdf26]  ; 0401A
call render_glyphs  ; 0401E
call update_display  ; 04021
call wait_for_key  ; 04024
ret  ; 04027

; ---- function scroll_text_up ----
; Scrolls text upward on CGA VRAM, one scanline at a time.
; Renders each new text line from the offscreen buffer at the bottom.
; No parameters. Preserves ES.
;
; Uses globals:
;   [0xddbe] = pointer to current text line (advanced after each line)
;   [0xdbb3] = remaining line count (decremented, stops at 0)
;   [0xe0e7] = VRAM offset for bottom scanline (from scanline LUT)
;
; For each pixel row scrolled: shifts all VRAM scanlines up by one
; (copying from [bx-0x20a5] to [bx-0x20a7] via ES=B800h), then
; copies a row from the rendered text buffer to the bottom.
; Polls keyboard between rows; exits early if key pressed.
; Delays 1 tick between rows for smooth scrolling.
scroll_text_up:
push es  ; 04028
mov ax,0xb800  ; 04029
mov es,ax  ; 0402C
loc_0402E:
mov si,[0xddbe]  ; 0402E
lea di,[0x337]  ; 04032
db 0x33, 0xC0  ; 04036 xor ax,ax
mov cx,0x4b0  ; 04038
push es  ; 0403B
push ds  ; 0403C
pop es  ; 0403D
rep stosw  ; 0403E
pop es  ; 04040
lea di,[0x337]  ; 04041
call render_glyphs  ; 04045
inc si  ; 04048
mov [0xddbe],si  ; 04049
db 0x33, 0xD2  ; 0404D xor dx,dx
loc_0404F:
db 0x33, 0xDB  ; 0404F xor bx,bx
loc_04051:
mov di,[bx-0x20a7]  ; 04051
mov si,[bx-0x20a5]  ; 04055
mov cx,0x28  ; 04059
push ds  ; 0405C
push es  ; 0405D
pop ds  ; 0405E
rep movsw  ; 0405F
pop ds  ; 04061
add bx,0x2  ; 04062
cmp bx,0x18e  ; 04065
jc short loc_04051  ; 04069 jc 0x4051
mov di,[0xe0e7]  ; 0406B
lea si,[0x337]  ; 0406F
db 0x03, 0xF2  ; 04073 add si,dx
mov cx,0x28  ; 04075
rep movsw  ; 04078
add dx,0x50  ; 0407A
cmp dx,0x460  ; 0407D
jnl short loc_04099  ; 04081 jnl 0x4099
push dx  ; 04083
call poll_keyboard  ; 04084
db 0x3D, 0x00, 0x00  ; 04087 cmp ax,0x0
jz short loc_04090  ; 0408A jz 0x4090
pop dx  ; 0408C
pop es  ; 0408D
pop bx  ; 0408E
ret  ; 0408F
loc_04090:
mov ax,0x1  ; 04090
call delay_ticks  ; 04093
pop dx  ; 04096
jmp short loc_0404F  ; 04097 jmp 0x404f
loc_04099:
dec byte [0xdbb3]  ; 04099
jnz short loc_0402E  ; 0409D jnz 0x402e
pop es  ; 0409F
ret  ; 040A0

; ---- function update_score ----
; Checksum verification / anti-tamper check.
; No parameters. No stack frame.
;
; Computes two checksums over code regions:
;   1. Sum of bytes at CS:0x255..0x515 (game_init area, 0x2C1 bytes)
;      Expected: AL == 0x5B
;   2. Sum of bytes at CS:0x169C..0x171C (disk.asm area, 0x81 bytes)
;      Expected: AL == 0x19
;
; If both checksums pass: returns normally.
; If either fails: zeroes out 11 words at DS:[-0x3C2E..], effectively
;   corrupting game state as a tamper response.
update_score:
lea si,[0x255]  ; 040A1
mov bx,0x2c0  ; 040A5
loc_040A8:
add al,[cs:bx+si]  ; 040A8
dec bx  ; 040AB
jnl short loc_040A8  ; 040AC jnl 0x40a8
cmp al,0x5b  ; 040AE
jnz short loc_040C6  ; 040B0 jnz 0x40c6
lea si,[0x169c]  ; 040B2
mov bx,0x80  ; 040B6
db 0x32, 0xC0  ; 040B9 xor al,al
loc_040BB:
add al,[cs:bx+si]  ; 040BB
dec bx  ; 040BE
jnl short loc_040BB  ; 040BF jnl 0x40bb
cmp al,0x19  ; 040C1
jnz short loc_040C6  ; 040C3 jnz 0x40c6
ret  ; 040C5
loc_040C6:
mov bx,0x14  ; 040C6
loc_040C9:
mov word [bx-0x3c2e],0x0  ; 040C9
sub bx,0x2  ; 040CF
jnl short loc_040C9  ; 040D2 jnl 0x40c9
ret  ; 040D4

; ---- function rand_next ----
; Timer-based random seed generator. Reads the timer value, applies
; a linear transformation (val * 0xE5D + 3) / 0x8000, stores the
; remainder back as the new seed.
;
; No parameters on stack.
;
; Local variables:
;   [bp+0x2] = timer/seed value
;
; Returns: AX = pseudo-random value (remainder of division)
;
; The unlabeled function at 0x4111 saves the current timer value
; by calling rand_seed_io(1, &local).
rand_next:
push bp  ; 040D5
sub sp,0x4  ; 040D6
db 0x8B, 0xEC  ; 040D9 mov bp,sp
lea ax,[bp+0x2]  ; 040DB
push ax  ; 040DE
db 0x33, 0xC0  ; 040DF xor ax,ax
push ax  ; 040E1
call rand_seed_io  ; 040E2
db 0x8B, 0xE5  ; 040E5 mov sp,bp
mov ax,[bp+0x2]  ; 040E7
mov bx,0xe5d  ; 040EA
mul bx  ; 040ED
db 0x05, 0x03, 0x00  ; 040EF add ax,0x3
mov bx,0x8000  ; 040F2
xor dx,dx  ; 040F5
div bx  ; 040F7
lea ax,[bp+0x2]  ; 040F9
push ax  ; 040FC
mov ax,0x1  ; 040FD
push ax  ; 04100
mov [bp+0x2],dx  ; 04101
call rand_seed_io  ; 04104
db 0x8B, 0xE5  ; 04107 mov sp,bp
mov ax,[bp+0x2]  ; 04109
add sp,0x4  ; 0410C
pop bp  ; 0410F
ret  ; 04110
set_rand_seed:
push bp  ; 04111
db 0x8B, 0xEC  ; 04112 mov bp,sp
lea ax,[bp+0x4]  ; 04114
push ax  ; 04117
mov ax,0x1  ; 04118
push ax  ; 0411B
call rand_seed_io  ; 0411C
db 0x8B, 0xE5  ; 0411F mov sp,bp
pop bp  ; 04121
ret  ; 04122

; ---- function rand_seed_io ----
; Gets or sets the timer seed value at [0xdf40].
;
; Parameters (on stack):
;   [bp+0x6] = direction: 0 = get (read [0xdf40] into *ptr), 1 = set (write *ptr to [0xdf40])
;   [bp+0x8] = pointer to word value
rand_seed_io:
push bp  ; 04123
sub sp,0x2  ; 04124
db 0x8B, 0xEC  ; 04127 mov bp,sp
mov al,[bp+0x6]  ; 04129
xor ah,ah  ; 0412C
test ax,ax  ; 0412E
jnz short loc_0413C  ; 04130 jnz 0x413c
mov ax,[0xdf40]  ; 04132
mov si,[bp+0x8]  ; 04135
mov [si],ax  ; 04138
jmp short loc_04144  ; 0413A jmp 0x4144
loc_0413C:
mov si,[bp+0x8]  ; 0413C
mov ax,[si]  ; 0413F
mov [0xdf40],ax  ; 04141
loc_04144:
add sp,0x2  ; 04144
pop bp  ; 04147
ret  ; 04148
