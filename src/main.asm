; C main() and CRT string functions (strncmp, strcat, strncat)


; ---- function main ----
; Lattice C main() - called from C runtime startup at 0x01F5.
; Parses command line into argc/argv, sets up I/O handles, initializes
; the file system, then calls game_init(argv, argc).
;
; Parameters:
;   [bp+0x12] = pointer to raw command line string (from PSP)
;
; Local variables:
;   [bp+0x0]  = temp: current character value
;   [bp+0x4]  = temp: saved character
;   [bp+0x5]  = device mode flags (text/binary)
;   [bp+0x8]  = init_iob_entry result for stdin
;   [bp+0xa]  = init_iob_entry result for stdout
;   [bp+0xc]  = init_iob_entry result for stderr
;
; DS = DGROUP (code+data segment)
; ES = PSP segment (set by DOS before program start)
; The init_iob_entry calls are really fopen(name, mode, iob), reopening redirected streams on DOS 1: stdin from [stdin_redir] mode "r", stdout from [stdout_redir] mode "w", or from the name after '>' mode "a" for '>>', and stderr with an empty name mode "a".
; On a failed open, fputs prints "Can't open stdin file" or "Can't open stdout file" to stderr and exit(1) exits.
; DOS 2+ goes straight to the code at 0x5AA6 that sets up the predefined handles.
main:
	push	bp			; 05953
	sub	sp,0xe			; 05954 - allocate 14 bytes of locals
	db	0x8B, 0xEC		; 05957 mov bp,sp

; --- Phase 1: Parse command line into argc/argv ---
; Scans the command line string, splitting on whitespace (ctype bit 3).
; Stores up to 32 argument pointers in argv[]. Null-terminates each arg
; by replacing the whitespace delimiter with 0x00.
	mov	word [argc],0x0		; 05959 - argc = 0
main_parse_next_arg:
	cmp	word [argc],0x20	; 0595F - if argc >= 32, stop parsing
	jnl	short main_args_parsed_check_dos_version		; 05964 jnl 0x59d4
main_skip_whitespace_loop:
; Skip whitespace characters (ctype bit 3 = whitespace)
	mov	si,[bp+0x12]		; 05966 - si = current position in cmdline
	mov	al,[si]			; 05969 - al = current char
	xor	ah,ah			; 0596B
	inc	ax			; 0596D
	db	0x8B, 0xF8		; 0596E mov di,ax
	mov	al,[di+ctype_with_eof]		; 05970 - lookup ctype[char] (0xe4c4 = ctype table)
	xor	ah,ah			; 05974
	db	0x25, 0x08, 0x00	; 05976 and ax,0x8 - test whitespace bit
	jz	short main_check_end_of_cmdline		; 05979 - not whitespace, start new arg
	inc	word [bp+0x12]		; 0597B - skip this whitespace char
	jmp	short main_skip_whitespace_loop		; 0597E - check next char
main_check_end_of_cmdline:
; Check for end of string
	mov	si,[bp+0x12]		; 05980
	mov	al,[si]			; 05983
	xor	ah,ah			; 05985
	test	ax,ax			; 05987
	jz	short main_args_parsed_check_dos_version		; 05989 - null terminator, done parsing

; Record this argument in argv[]
	mov	ax,[argc]		; 0598B
	inc	word [argc]		; 0598E - argc++
	shl	ax,1			; 05992 - word index
	db	0x8B, 0xF0		; 05994 mov si,ax
	mov	ax,[bp+0x12]		; 05996
	mov	[si+argv],ax		; 05999 - argv[i] = pointer to this arg (0xe440 = argv)
main_scan_arg_end_loop:
; Scan forward to next whitespace or end of string
	mov	si,[bp+0x12]		; 0599D
	mov	al,[si]			; 059A0
	xor	ah,ah			; 059A2
	test	ax,ax			; 059A4
	mov	[bp+0x0],ax		; 059A6 - save char value
	jz	short main_terminate_arg		; 059A9 - null terminator, end of arg
	inc	ax			; 059AB
	db	0x8B, 0xF8		; 059AC mov di,ax
	mov	al,[di+ctype_with_eof]		; 059AE - lookup ctype[char]
	xor	ah,ah			; 059B2
	db	0x25, 0x08, 0x00	; 059B4 and ax,0x8 - test whitespace bit
	jnz	short main_terminate_arg		; 059B7 - whitespace found, end of arg
	inc	word [bp+0x12]		; 059B9 - advance to next char
	jmp	short main_scan_arg_end_loop		; 059BC - keep scanning
main_terminate_arg:
; Null-terminate this argument
	mov	si,[bp+0x12]		; 059BE
	mov	al,[si]			; 059C1
	inc	word [bp+0x12]		; 059C3 - advance past delimiter
	mov	byte [si],0x0		; 059C6 - null-terminate the arg
	mov	[bp+0x4],al		; 059C9 - save original delimiter char
	xor	ah,ah			; 059CC
	test	ax,ax			; 059CE
	jnz	short main_parse_next_arg		; 059D0 - more chars, parse next arg
	jmp	short main_args_parsed_check_dos_version		; 059D2 - done

; --- Phase 2: Check DOS version ---
main_args_parsed_check_dos_version:
	mov	al,[dos_version]	; 059D4 - DOS major version
	xor	ah,ah			; 059D7
	db	0x3D, 0x02, 0x00	; 059D9 cmp ax,0x2
	jl	short main_open_redirected_streams_dos1		; 059DC - DOS < 2: skip I/O redirection setup
	jmp	near main_configure_stdio_dos2			; 059DE - DOS >= 2: jump to I/O redirection handler (in crt.asm)

; --- Phase 3: Set up I/O handles (DOS 1.x path) ---
main_open_redirected_streams_dos1:
; Save interrupt vectors for stdin (INT 19h)
	mov	ax,iob_stdin		; 059E1 - address of stdin I/O block
	push	ax			; 059E4
	mov	ax,0xe480		; 059E5 - address of vector save buffer
	push	ax			; 059E8
	mov	ax,0x19			; 059E9 - INT 19h
	push	ax			; 059EC
	call	init_iob_entry		; 059ED - init_iob_entry(0x19, save_buf, iob_stdin)
	db	0x8B, 0xE5		; 059F0 mov sp,bp

; Check if stdout redirect is append mode (>>)
	mov	bl,[stdout_redir]	; 059F2 - first char of redirect path
	xor	bh,bh			; 059F6
	cmp	bx,0x3e			; 059F8 - is it '>' (0x3E)?
	mov	[bp+0x8],ax		; 059FB - save stdin result
	jz	short main_open_stdout_append		; 059FE - yes: append mode, use INT 3Ah

; Save interrupt vectors for stdout (INT 39h, normal mode)
	mov	ax,iob_stdout		; 05A00 - address of stdout I/O block
	push	ax			; 05A03
	mov	ax,0xe482		; 05A04 - address of vector save buffer
	push	ax			; 05A07
	mov	ax,0x39			; 05A08 - INT 39h
	push	ax			; 05A0B
	call	init_iob_entry		; 05A0C - init_iob_entry(0x39, save_buf, iob_stdout)
	db	0x8B, 0xE5		; 05A0F mov sp,bp
	mov	[bp+0xa],ax		; 05A11 - save stdout result
	jmp	short main_open_stderr		; 05A14 jmp 0x5a2a

main_open_stdout_append:
; Save interrupt vectors for stdout (INT 3Ah, append mode)
	mov	ax,iob_stdout		; 05A16 - address of stdout I/O block
	push	ax			; 05A19
	mov	ax,0xe484		; 05A1A - address of vector save buffer
	push	ax			; 05A1D
	mov	ax,0x3a			; 05A1E - INT 3Ah
	push	ax			; 05A21
	call	init_iob_entry		; 05A22 - init_iob_entry(0x3a, save_buf, iob_stdout)
	db	0x8B, 0xE5		; 05A25 mov sp,bp
	mov	[bp+0xa],ax		; 05A27 - save stdout result

main_open_stderr:
; Save interrupt vectors for stderr
	mov	ax,iob_stderr		; 05A2A - address of stderr I/O block
	push	ax			; 05A2D
	mov	ax,0xe484		; 05A2E - address of save buffer
	push	ax			; 05A31
	mov	ax,0xe486		; 05A32 - address of save buffer 2
	push	ax			; 05A35
	call	init_iob_entry		; 05A36
	db	0x8B, 0xE5		; 05A39 mov sp,bp
	test	ax,ax			; 05A3B
	mov	[bp+0xc],ax		; 05A3D - save stderr result
	jnz	short main_check_stdin_opened		; 05A40 - if non-zero, skip CRT I/O init

; stderr setup failed, initialize CRT I/O manually
	mov	ax,0x1			; 05A42
	push	ax			; 05A45
	call	crt_exit_forward		; 05A46 - crt_exit_forward(1)
	db	0x8B, 0xE5		; 05A49 mov sp,bp

; --- Phase 4: Initialize file system ---
main_check_stdin_opened:
	cmp	word [bp+0x8],0x0	; 05A4B - check stdin result
	jnz	short main_set_stdin_buffer		; 05A4F - non-zero: skip file system init

; stdin handle not available, initialize file system
	push	word [bp+0xc]		; 05A51 - stderr result
	mov	ax,0xe487		; 05A54 - file system config address
	push	ax			; 05A57
	call	fputs	; 05A58
	db	0x8B, 0xE5		; 05A5B mov sp,bp
	mov	ax,0x1			; 05A5D
	push	ax			; 05A60
	call	exit	; 05A61 - prompt for game disk
	db	0x8B, 0xE5		; 05A64 mov sp,bp

main_set_stdin_buffer:
; Format stdin I/O block string
	push	word [stdio_bufsiz]	; 05A66 - default buffer size (512)
	call	malloc_16		; 05A6A
	db	0x8B, 0xE5		; 05A6D mov sp,bp
	push	ax			; 05A6F
	push	word [bp+0x8]		; 05A70
	call	setbuf		; 05A73
	db	0x8B, 0xE5		; 05A76 mov sp,bp

; Clear bit 3 of stdin I/O block flags
	mov	si,[bp+0x8]		; 05A78
	mov	al,[si+0x8]		; 05A7B - flags byte at iob+8
	xor	ah,ah			; 05A7E
	db	0x25, 0xF7, 0xFF	; 05A80 and ax,0xfff7 - clear bit 3
	mov	[si+0x8],al		; 05A83

; Check stdout result
	cmp	word [bp+0xa],0x0	; 05A86
	jz	short main_stdout_open_failed		; 05A8A - zero: need to init file system for stdout
	jmp	near main_call_game_init			; 05A8C - non-zero: jump to stdout init (in crt.asm)

main_stdout_open_failed:
; Initialize file system for stdout path
	push	word [bp+0xc]		; 05A8F - stderr result
	mov	ax,0xe49e		; 05A92 - second file system config address
	push	ax			; 05A95
	call	fputs	; 05A96
	db	0x8B, 0xE5		; 05A99 mov sp,bp
	mov	ax,0x1			; 05A9B
	push	ax			; 05A9E
	call	exit	; 05A9F - prompt for game disk
	db	0x8B, 0xE5		; 05AA2 mov sp,bp
	jmp	short main_call_game_init		; 05AA4 jmp 0x5b14

; --- Phase 5: Configure stdio device flags (reached from DOS 2+ path) ---
; Sets up _iob[] flags for stdin/stdout/stderr based on device mode
; DOS 2+ path: sets stdin/stdout/stderr flags and fds
main_configure_stdio_dos2:
	mov	byte [iob_stdin+9],0x0	; 05AA6 - stdin flags2 = 0
	mov	al,0x1			; 05AAB
	mov	bl,0x2			; 05AAD
	mov	byte [iob_stderr+8],0x6	; 05AAF - stderr flags1 = 6 (read+write+special)
	mov	cx,[stdio_mode]		; 05AB4 - global mode flags
	xor	cx,[stdio_flags]	; 05AB8 - XOR with stdio flags
	and	cx,0x8000		; 05ABC - isolate bit 15 (text/binary mode mismatch)
	mov	[iob_stdout+9],al	; 05AC0 - stdout flags2 = 1
	mov	[iob_stdin+8],al	; 05AC3 - stdin flags1 = 1 (text mode/open)
	mov	[iob_stderr+9],bl	; 05AC6 - stderr flags2 = 2
	mov	[iob_stdout+8],bl	; 05ACA - stdout flags1 = 2
	jz	short main_device_mode_clear		; 05ACE - no mode mismatch: ax = 0
	mov	ax,0x10			; 05AD0 - mode mismatch: ax = 0x10
	jmp	short main_store_device_mode		; 05AD3 jmp 0x5ad7
main_device_mode_clear:
	db	0x33, 0xC0		; 05AD5 xor ax,ax
main_store_device_mode:
	mov	[bp+0x5],ax		; 05AD7 - save device mode flags
	or	ax,0xc0			; 05ADA - add read+write bits
	mov	word [file_stdout+2],0x1	; 05ADD - stdout FILE fd = 1
	mov	bx,[bp+0x5]		; 05AE3
	or	bx,0xa0			; 05AE6 - add read+binary bits
	mov	word [file_stderr+2],0x2	; 05AEA - stderr FILE fd = 2
	mov	cx,0x1			; 05AF0
	push	cx			; 05AF3
	mov	[file_stdin],al		; 05AF4 - stdin FILE flags = mode | 0xc0
	mov	[file_stderr],bl	; 05AF7 - stderr FILE flags = mode | 0xa0
	mov	[file_stdout],bl	; 05AFB - stdout FILE flags = mode | 0xa0
	call	dos_ioctl		; 05AFF - check if stdout is a character device
	db	0x8B, 0xE5		; 05B02 mov sp,bp
	and	ax,0x80			; 05B04 - bit 7 = character device flag
	jz	short main_call_game_init		; 05B07 - not a char device: skip

; stdout is a character device, set char-device bit in flags
	mov	al,[iob_stdout+8]	; 05B09 - get stdout flags1
	xor	ah,ah			; 05B0C
	db	0x0D, 0x04, 0x00	; 05B0E or ax,0x4 - set bit 2 (character device)
	mov	[iob_stdout+8],al	; 05B11 - store updated flags

; --- Phase 6: Call game_init(argv, argc) ---
main_call_game_init:
	mov	ax,argv			; 05B14 - address of argument vector
	push	ax			; 05B17
	push	word [argc]		; 05B18 - argument count
	call	game_init		; 05B1C - game_init(argc, argv)
	db	0x8B, 0xE5		; 05B1F mov sp,bp

; Cleanup: dismiss disk prompt
	db	0x33, 0xC0		; 05B21 xor ax,ax
	push	ax			; 05B23
	call	exit	; 05B24 - exit(0) = dismiss
	db	0x8B, 0xE5		; 05B27 mov sp,bp
	add	sp,0xe			; 05B29 - free locals
	pop	bp			; 05B2C
	ret				; 05B2D

; ---- function strncmp ----
; Compare two strings up to n characters.
; Lattice C runtime strncmp() - uses alternate 0x82 opcode encoding.
;
; Parameters:
;   [bp+0xc]  = str1 pointer
;   [bp+0xe]  = str2 pointer
;   [bp+0x10] = max character count
;
; Returns:
;   AX = 0 if equal, positive if str1 > str2, negative if str1 < str2
;
; Note: db 0x82 bytes are the alternate CMP encoding (0x82 vs 0x80)
;   that NASM doesn't generate. "82 3C 00" = "cmp byte [si],0x0"
;   and "82 3D 00" = "cmp byte [di],0x0".
strncmp:
	push	bp			; 05B2E
	sub	sp,0x8			; 05B2F
	db	0x8B, 0xEC		; 05B32 mov bp,sp
strncmp_compare_loop:
	cmp	word [bp+0x10],0x0	; 05B34 - count exhausted?
	jz	short strncmp_loop_ended		; 05B38 jz 0x5b6f
	mov	si,[bp+0xc]		; 05B3A - si = str1
	db	0x82			; 05B3D         --+
	cmp	al,0x0			; 05B3E          | = cmp byte [si],0x0 (*str1 == null?) (*str1 == null?)
	jz	short strncmp_loop_ended		; 05B40 jz 0x5b6f
	mov	di,[bp+0xe]		; 05B42 - di = str2
	db	0x82			; 05B45         --+
	cmp	ax,0x7400		; 05B46      | = cmp byte [di],0x0; jz ...  (db 82 3D 00 74 xx)
	and	ax,0xc68b		; 05B49    | these bytes decode as the compare + conditional jump
	inc	word [bp+0xc]		; 05B4C - str1++
	inc	word [bp+0xe]		; 05B4F - str2++
	mov	bl,[di]			; 05B52 - bl = *str2 (via ctype/tolower lookup)
	xor	bh,bh			; 05B54
	db	0x8B, 0xF0		; 05B56 mov si,ax
	mov	cl,[si]			; 05B58 - cl = *str1 (via lookup)
	xor	ch,ch			; 05B5A
	db	0x2B, 0xCB		; 05B5C sub cx,bx - diff = *str1 - *str2
	mov	[bp+0x6],cx		; 05B5E
	jz	short strncmp_next_char		; 05B61 - if equal, continue
	db	0x8B, 0xC1		; 05B63 mov ax,cx - return difference
	add	sp,0x8			; 05B65
	pop	bp			; 05B68
	ret				; 05B69
strncmp_next_char:
	dec	word [bp+0x10]		; 05B6A - count--
	jmp	short strncmp_compare_loop		; 05B6D - next iteration
strncmp_loop_ended:
; One or both strings ended, check which
	cmp	word [bp+0x10],0x0	; 05B6F - count exhausted?
	jz	short strncmp_return_equal		; 05B73 - yes: strings equal up to n chars
	mov	si,[bp+0xc]		; 05B75 - check if str1 has more
	db	0x82			; 05B78         --+
	cmp	al,0x0			; 05B79          | = cmp byte [si],0x0
	jz	short strncmp_check_str2_ended		; 05B7B - str1 ended
	mov	ax,0x1			; 05B7D - str1 has more: return 1 (str1 > str2)
	add	sp,0x8			; 05B80
	pop	bp			; 05B83
	ret				; 05B84
strncmp_check_str2_ended:
	mov	si,[bp+0xe]		; 05B85 - check if str2 has more
	db	0x82			; 05B88         --+
	cmp	al,0x0			; 05B89          | = cmp byte [si],0x0
	jz	short strncmp_return_equal		; 05B8B - str2 also ended: equal
	mov	ax,0xffff		; 05B8D - str2 has more: return -1 (str1 < str2)
	add	sp,0x8			; 05B90
	pop	bp			; 05B93
	ret				; 05B94
strncmp_return_equal:
	db	0x33, 0xC0		; 05B95 xor ax,ax - return 0 (equal)
	add	sp,0x8			; 05B97
	pop	bp			; 05B9A
	ret				; 05B9B

; ---- function strcat ----
; Append source string to end of dest string.
; Lattice C runtime strcat().
;
; Parameters:
;   [bp+0xc] = dest string pointer
;   [bp+0xe] = source string pointer
;
; Returns:
;   AX = dest pointer
strcat:
	push	bp			; 05B9C
	sub	sp,0x8			; 05B9D
	db	0x8B, 0xEC		; 05BA0 mov bp,sp
	push	word [bp+0xc]		; 05BA2 - push dest
	call	strlen			; 05BA5 - strlen(dest)
	db	0x8B, 0xE5		; 05BA8 mov sp,bp
	mov	bx,[bp+0xc]		; 05BAA
	db	0x03, 0xD8		; 05BAD add bx,ax - bx = dest + strlen(dest) = end of dest
	mov	[bp+0x6],bx		; 05BAF - save write position
strcat_copy_loop:
; Copy loop: copy src chars to end of dest until null
	mov	si,[bp+0x6]		; 05BB2 - si = write position
	inc	word [bp+0x6]		; 05BB5
	mov	di,[bp+0xe]		; 05BB8 - di = read position (src)
	inc	word [bp+0xe]		; 05BBB
	mov	al,[di]			; 05BBE - al = *src
	mov	[si],al			; 05BC0 - *dest_end = *src
	test	al,al			; 05BC2
	jnz	short strcat_copy_loop		; 05BC4 - loop until null terminator copied
	mov	ax,[bp+0xc]		; 05BC6 - return dest pointer
	add	sp,0x8			; 05BC9
	pop	bp			; 05BCC
	ret				; 05BCD

; ---- function strncat ----
; Append at most n characters from source to end of dest string.
; Lattice C runtime strncat(). Not called in this program (dead CRT code).
;
; Parameters:
;   [bp+0xa] = dest string pointer
;   [bp+0xc] = source string pointer
;   [bp+0xe] = max characters to append
;
; Returns:
;   AX = dest pointer
strncat:
	push	bp			; 05BCE
	sub	sp,0x6			; 05BCF
	db	0x8B, 0xEC		; 05BD2 mov bp,sp
	push	word [bp+0xa]		; 05BD4 - push dest
	call	strlen			; 05BD7 - strlen(dest)
	db	0x8B, 0xE5		; 05BDA mov sp,bp
	mov	bx,[bp+0xa]		; 05BDC
	db	0x03, 0xD8		; 05BDF add bx,ax - bx = end of dest
	mov	[bp+0x4],bx		; 05BE1 - save write position
strncat_copy_loop:
	mov	ax,[bp+0xe]		; 05BE4 - remaining count
	dec	word [bp+0xe]		; 05BE7 - count--
	test	ax,ax			; 05BEA
	jng	short strncat_terminate		; 05BEC - count <= 0: done
	mov	si,[bp+0xc]		; 05BEE - si = src
	inc	word [bp+0xc]		; 05BF1
	mov	al,[si]			; 05BF4 - al = *src
	mov	di,[bp+0x4]		; 05BF6 - di = write position
	mov	[di],al			; 05BF9 - *dest_end = *src
	test	al,al			; 05BFB
	jz	short strncat_terminate		; 05BFD - null terminator: done
	inc	word [bp+0x4]		; 05BFF - advance write position
	jmp	short strncat_copy_loop		; 05C02 - next char
strncat_terminate:
	mov	si,[bp+0x4]		; 05C04
	mov	byte [si],0x0		; 05C07 - null-terminate result
	mov	ax,[bp+0xa]		; 05C0A - return dest pointer
	add	sp,0x6			; 05C0D
	pop	bp			; 05C10
	ret				; 05C11
