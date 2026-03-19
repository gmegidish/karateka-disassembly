; System: control initialization, joystick I/O, interrupt handlers,
; Lattice C file I/O (IOB management), heap management, file slot management.
; Code range: 0x4619-0x4FDC


; ---- function init_controls ----
; Initializes the input system: detects joystick, calibrates axes, measures
; CPU speed and scales timing tables accordingly.
; Returns: AX = joystick detected flag (0 or 1)
init_controls:
	push	di			; 04619
	push	si			; 0461A
	mov	byte [0xe196],0x0	; 0461B  joystick_present = false
	mov	dx,0x201		; 04620  joystick game port
	out	dx,al			; 04623  fire one-shot (trigger RC charge)
	in	al,dx			; 04624  read back axis bits
	and	al,0x3			; 04625  mask X and Y axis bits
	cmp	al,0x3			; 04627  both bits set = axes still charging
	jnz	short loc_0464C		; 04629 jnz 0x464c  ; no joystick if bits cleared immediately
	mov	cx,0x0			; 0462B  CX=0 means loop 65536 times
	loop	0x462e			; 0462E  busy-wait for RC discharge
	in	al,dx			; 04630  read port again after delay
	and	al,0x3			; 04631  check axis bits again
	jnz	short loc_0464C		; 04633 jnz 0x464c  ; still set = no joystick (stuck high)
	mov	byte [0xe196],0x1	; 04635  joystick_present = true
	mov	ah,0x1			; 0463A  axis mask: X axis
	lea	di,[0xe197]		; 0463C  -> joy_x_lo_thresh / joy_x_hi_thresh
	call	calibrate_joystick_axis	; 04640
	mov	ah,0x2			; 04643  axis mask: Y axis
	lea	di,[0xe19b]		; 04645  -> joy_y_lo_thresh / joy_y_hi_thresh
	call	calibrate_joystick_axis	; 04649
loc_0464C:
; --- CPU speed measurement ---
; Counts loop iterations between 7 BIOS timer ticks (at 0000:046C).
; DS is set to 0 to access the BIOS data area directly.
	push	bp			; 0464C
	push	ds			; 0464D
	db	0x33, 0xC0		; 0464E xor ax,ax
	mov	ds,ax			; 04650  DS = 0 (BIOS data area)
	db	0x8B, 0xF8		; 04652 mov di,ax  ; DI = tick counter (iterations)
	mov	bp,0x7			; 04654  target = current_tick + 7
	mov	cx,0x1f40		; 04657  CX = 8000 (inner loop limit)
	mov	bx,0x46c		; 0465A  BX -> BIOS timer tick count (0000:046C)
	mov	si,[bx]			; 0465D  SI = current tick
	inc	si			; 0465F  wait for next tick boundary
	db	0x03, 0xEE		; 04660 add bp,si  ; BP = target tick (current + 7)
loc_04662:
	cmp	si,[bx]			; 04662  wait for tick to change
	jnz	short loc_04662		; 04664 jnz 0x4662
loc_04666:
; Inner speed test loop: reads joystick port in a tight loop
	in	al,dx			; 04666
	inc	cx			; 04667
	loopne	0x466a			; 04668
	in	al,dx			; 0466A
	inc	cx			; 0466B
	loopne	0x466e			; 0466C
	mov	ax,[bx]			; 0466E  check current tick
	inc	di			; 04670  count iterations
	db	0x3B, 0xC5		; 04671 cmp ax,bp  ; reached target tick?
	jnz	short loc_04666		; 04673 jnz 0x4666
	pop	ds			; 04675
	mov	[0xe1a7],di		; 04676  cpu_speed_count = iterations
	pop	bp			; 0467A
; --- Scale timing tables based on CPU speed ---
	cmp	di,0x2af8		; 0467B  speed <= 11000? (slow CPU)
	ja	short loc_046B4		; 0467F ja 0x46b4
; Slow CPU: halve timing values (round up via inc before shr)
	mov	bx,0x4			; 04681
loc_04684:
	inc	byte [bx+0xd70e]	; 04684  timing_table[bx]++
	shr	byte [bx+0xd70e],1	; 04688  timing_table[bx] /= 2
	dec	bx			; 0468C
	jnl	short loc_04684		; 0468D jnl 0x4684
; Halve pointer-table values with special-case adjustments
	mov	bx,0x1c			; 0468F
loc_04692:
	mov	si,[bx+0xd718]		; 04692  SI = pointer to timing value
	shr	byte [si],1		; 04696  *SI /= 2
	cmp	bx,0x6			; 04698
	jc	short loc_046AD		; 0469B jc 0x46ad  ; bx < 6: no adjustment
	cmp	bx,0xe			; 0469D
	ja	short loc_046A6		; 046A0 ja 0x46a6  ; bx > 14: check bx==16
	inc	byte [si]		; 046A2  6 <= bx <= 14: round up
	jmp	short loc_046AD		; 046A4 jmp 0x46ad
loc_046A6:
	cmp	bx,0x10			; 046A6  bx == 16?
	jnz	short loc_046AD		; 046A9 jnz 0x46ad
	dec	byte [si]		; 046AB  bx == 16: round down
loc_046AD:
	sub	bx,0x2			; 046AD
	jnl	short loc_04692		; 046B0 jnl 0x4692
	jmp	short loc_046F4		; 046B2 jmp 0x46f4
loc_046B4:
; Medium CPU: 11000 < speed <= 13500
	cmp	di,0x34bc		; 046B4  speed <= 13500?
	ja	short loc_046D6		; 046B8 ja 0x46d6
	mov	bx,0x1c			; 046BA
loc_046BD:
	mov	si,[bx+0xd718]		; 046BD
	cmp	byte [si],0x6		; 046C1  if value >= 6, decrement
	jc	short loc_046C8		; 046C4 jc 0x46c8
	dec	byte [si]		; 046C6
loc_046C8:
	cmp	byte [si],0x8		; 046C8  if value > 8, decrement again
	ja	short loc_046CF		; 046CB ja 0x46cf
	dec	byte [si]		; 046CD
loc_046CF:
	sub	bx,0x2			; 046CF
	jnl	short loc_046BD		; 046D2 jnl 0x46bd
	jmp	short loc_046F4		; 046D4 jmp 0x46f4
loc_046D6:
; Fast CPU: speed >= 20000 — double all timing values
	cmp	di,0x4e20		; 046D6  speed >= 20000?
	jc	short loc_046F4		; 046DA jc 0x46f4  ; 13500 < speed < 20000: no adjustment
	mov	bx,0x4			; 046DC
loc_046DF:
	shl	byte [bx+0xd70e],1	; 046DF  timing_table[bx] *= 2
	dec	bx			; 046E3
	jnl	short loc_046DF		; 046E4 jnl 0x46df
	mov	bx,0x1c			; 046E6
loc_046E9:
	mov	si,[bx+0xd718]		; 046E9
	shl	byte [si],1		; 046ED  *SI *= 2
	sub	bx,0x2			; 046EF
	jnl	short loc_046E9		; 046F2 jnl 0x46e9
loc_046F4:
	pop	si			; 046F4
	pop	di			; 046F5
	mov	al,[0xe196]		; 046F6  return joystick_present
	mov	ah,0x0			; 046F9
	ret				; 046FB

; ---- function calibrate_joystick_axis ----
; Reads the current joystick axis position and computes dead-zone thresholds.
; Input: AH = axis mask (1=X, 2=Y), DI = pointer to threshold storage
; Output: [DI] = center - dead_zone, [DI+2] = center + dead_zone
; Dead zone = half the center value.
calibrate_joystick_axis:
	call	read_joystick_axis	; 046FC  AX = axis position
	push	ax			; 046FF
	db	0x8B, 0xD8		; 04700 mov bx,ax  ; BX = center position
	shr	bx,1			; 04702  BX = dead_zone (center / 2)
	mov	[di],bx			; 04704  store low threshold (center - dead_zone ≈ center/2)
	pop	ax			; 04706
	db	0x03, 0xC3		; 04707 add ax,bx  ; AX = center + dead_zone
	mov	[di+0x2],ax		; 04709  store high threshold
	ret				; 0470C

; ---- function read_joystick_buttons ----
; Reads joystick fire buttons from port 0x201.
; Buttons are active-low: bit 4 = button 1, bit 5 = button 2.
; Sets joy_button_state bits: 0x20 = button 1, 0x10 = button 2.
; Returns: AX = button state bitmask
read_joystick_buttons:
	mov	word [0xe19f],0x0	; 0470D  clear joy_button_state
	mov	byte [0xe1a5],0x0	; 04713  clear joy_btn_2
	mov	byte [0xe1a6],0x0	; 04718  clear joy_btn_1
	cmp	byte [0xe196],0x0	; 0471D  joystick_present?
	jz	short loc_04752		; 04722 jz 0x4752  ; no joystick, return 0
	mov	dx,0x201		; 04724  joystick port
	in	al,dx			; 04727  read button state
	db	0x8A, 0xE0		; 04728 mov ah,al
	and	ah,0x30			; 0472A  isolate button bits (4 and 5)
	xor	ah,0x30			; 0472D  invert (active-low -> active-high)
	jz	short loc_04752		; 04730 jz 0x4752  ; no buttons pressed
	test	ah,0x10			; 04732  button 1 pressed? (was bit 4)
	jnz	short loc_04742		; 04735 jnz 0x4742  ; no, skip
	db	0x81, 0x0E, 0x9F, 0xE1, 0x20, 0x00	; 04737 or word [0xe19f],0x20  ; set bit 5 in button_state
	mov	byte [0xe1a6],0x1	; 0473D  joy_btn_1 = 1
loc_04742:
	test	ah,0x20			; 04742  button 2 pressed? (was bit 5)
	jnz	short loc_04752		; 04745 jnz 0x4752  ; no, skip
	db	0x81, 0x0E, 0x9F, 0xE1, 0x10, 0x00	; 04747 or word [0xe19f],0x10  ; set bit 4 in button_state
	mov	byte [0xe1a5],0x1	; 0474D  joy_btn_2 = 1
loc_04752:
	mov	ax,[0xe19f]		; 04752  return joy_button_state
	ret				; 04755

; ---- function read_joystick ----
; Full joystick read: buttons + both axes with threshold comparison.
; Input: [bp+4] = mode (0 = full read, non-zero = buttons only)
; Direction bits in joy_button_state:
;   bit 0 = left, bit 1 = right, bit 2 = up, bit 3 = down
;   bit 4 = button 2, bit 5 = button 1
; Returns: AX = combined direction+button state (or 0/13 in button-only mode)
read_joystick:
	push	di			; 04756
	push	si			; 04757
	mov	word [0xe19f],0x0	; 04758  clear joy_button_state
	mov	word [0xe1a1],0x0	; 0475E  clear joy_axis_left + joy_axis_right
	mov	word [0xe1a3],0x0	; 04764  clear joy_axis_up + joy_axis_down
	cmp	byte [0xe196],0x0	; 0476A  joystick_present?
	jz	short loc_047D9		; 0476F jz 0x47d9  ; no joystick
	call	read_joystick_buttons	; 04771
	cmp	word [bp+0x4],0x0	; 04774  buttons-only mode?
	jnz	short loc_047E4		; 04778 jnz 0x47e4  ; yes, skip axis read
; --- Read X axis ---
	mov	dx,0x201		; 0477A  joystick port
	mov	ah,0x1			; 0477D  X axis mask
	call	read_joystick_axis	; 0477F
	db	0x3D, 0x00, 0x00	; 04782 cmp ax,0x0  ; axis returned 0 (timeout)?
	jz	short loc_047AB		; 04785 jz 0x47ab  ; skip X axis
	cmp	ax,[0xe197]		; 04787  compare with joy_x_lo_thresh
	jg	short loc_0479A		; 0478B jg 0x479a  ; not left
	db	0x81, 0x0E, 0x9F, 0xE1, 0x01, 0x00	; 0478D or word [0xe19f],0x1  ; set left bit
	mov	byte [0xe1a1],0x1	; 04793  joy_axis_left = 1
	jmp	short loc_047AB		; 04798 jmp 0x47ab
loc_0479A:
	cmp	ax,[0xe199]		; 0479A  compare with joy_x_hi_thresh
	jl	short loc_047AB		; 0479E jl 0x47ab  ; in dead zone
	db	0x81, 0x0E, 0x9F, 0xE1, 0x02, 0x00	; 047A0 or word [0xe19f],0x2  ; set right bit
	mov	byte [0xe1a2],0x1	; 047A6  joy_axis_right = 1
loc_047AB:
; --- Read Y axis ---
	mov	ah,0x2			; 047AB  Y axis mask
	call	read_joystick_axis	; 047AD
	db	0x3D, 0x00, 0x00	; 047B0 cmp ax,0x0  ; axis returned 0 (timeout)?
	jz	short loc_047D9		; 047B3 jz 0x47d9  ; skip Y axis
	cmp	ax,[0xe19b]		; 047B5  compare with joy_y_lo_thresh
	jg	short loc_047C8		; 047B9 jg 0x47c8  ; not up
	db	0x81, 0x0E, 0x9F, 0xE1, 0x04, 0x00	; 047BB or word [0xe19f],0x4  ; set up bit
	mov	byte [0xe1a3],0x1	; 047C1  joy_axis_up = 1
	jmp	short loc_047D9		; 047C6 jmp 0x47d9
loc_047C8:
	cmp	ax,[0xe19d]		; 047C8  compare with joy_y_hi_thresh
	jl	short loc_047D9		; 047CC jl 0x47d9  ; in dead zone
	db	0x81, 0x0E, 0x9F, 0xE1, 0x08, 0x00	; 047CE or word [0xe19f],0x8  ; set down bit
	mov	byte [0xe1a4],0x1	; 047D4  joy_axis_down = 1
loc_047D9:
	mov	ax,[0xe19f]		; 047D9  return combined state
	test	ax,0xf			; 047DC  any direction pressed?
	jz	short loc_047E1		; 047DF jz 0x47e1
loc_047E1:
	pop	si			; 047E1
	pop	di			; 047E2
	ret				; 047E3
loc_047E4:
; Buttons-only mode: return 0 if no button, 13 if any button
	db	0x3D, 0x00, 0x00	; 047E4 cmp ax,0x0
	jz	short loc_047E1		; 047E7 jz 0x47e1  ; no button -> return 0
	mov	ax,0xd			; 047E9  return 13 (Enter key equivalent)
	jmp	short loc_047E1		; 047EC jmp 0x47e1

; ---- function read_joystick_axis ----
; Times RC discharge for one joystick axis, averaged over 4 samples.
; Input: AH = axis mask (1=X, 2=Y), DX = 0x201 (joystick port)
; Returns: AX = 0x310 - averaged_pulse_count (0 if axis timed out)
read_joystick_axis:
	mov	si,0x0			; 047EE  SI = accumulated pulse count
	mov	bx,0x4			; 047F1  4 samples
loc_047F4:
	call	time_joystick_pulse	; 047F4
	db	0x03, 0xF1		; 047F7 add si,cx  ; accumulate remaining count
	dec	bx			; 047F9
	jnz	short loc_047F4		; 047FA jnz 0x47f4
	mov	cl,0x2			; 047FC
	shr	si,cl			; 047FE  SI /= 4 (average)
	mov	ax,0x310		; 04800  max pulse count
	db	0x2B, 0xC6		; 04803 sub ax,si  ; AX = 0x310 - average
	ret				; 04805

; ---- function time_joystick_pulse ----
; Fires one-shot on joystick port and counts down CX while axis bit is set.
; Input: AH = axis mask, DX = 0x201 (joystick port)
; Returns: CX = remaining count (higher = shorter discharge = nearer center)
time_joystick_pulse:
	mov	cx,0x310		; 04806  max count (784 decimal)
	out	dx,al			; 04809  fire one-shot
	in	al,dx			; 0480A  read axis bit
	test	ah,al			; 0480B  axis bit still set?
	loopne	0x480a			; 0480D  loop while set and CX > 0
	ret				; 0480F

; ---- INT 24h critical error handler ----
; Installed by install_handlers. Called by DOS on critical errors (e.g., disk not ready).
; Sets DS to game data segment, calls check_disk_prompt to handle "insert disk" prompt,
; then returns AL=1 (retry the operation).
critical_error_handler:
	push	bx			; 04810
	push	cx			; 04811
	push	dx			; 04812
	push	bp			; 04813
	push	si			; 04814
	push	di			; 04815
	push	ds			; 04816
	push	es			; 04817
	mov	ax,0x6ca		; 04818  game data segment (relocation applied)
	mov	ds,ax			; 0481B
	call	check_disk_prompt	; 0481D  show "insert disk" if needed
	mov	al,0x1			; 04820  AL=1 = retry the DOS operation
	pop	es			; 04822
	pop	ds			; 04823
	pop	di			; 04824
	pop	si			; 04825
	pop	bp			; 04826
	pop	dx			; 04827
	pop	cx			; 04828
	pop	bx			; 04829
	iret				; 0482A

; ---- function install_handlers ----
; Installs the critical error handler (INT 24h) via DOS function 25h.
; Points INT 24h vector to critical_error_handler above.
install_handlers:
	push	ds			; 0482B
	mov	ax,0x0			; 0482C
	mov	ds,ax			; 0482F  DS = 0 (for INT 21h/25h, DS:DX = handler address)
	mov	ax,0x2524		; 04831  AH=25h (set interrupt vector), AL=24h (INT 24h)
	lea	dx,[0x4810]		; 04834  DX = offset of critical_error_handler
	int	0x21			; 04838
	pop	ds			; 0483A
	ret				; 0483B

; ---- function fopen_iob ----
; Lattice C fopen() implementation. Scans the IOB array (0xe1b0-0xe2c8,
; 14 bytes per entry, 20 entries) for a free slot (flags byte at offset+8 == 0).
; If found, calls init_iob_entry to parse mode and open the file.
; Input: [bp+0xa] = filename string, [bp+0xc] = mode string
; Output: AX = IOB pointer, or 0 if no free slot
fopen_iob:
	push	bp			; 0483C
	sub	sp,0x6			; 0483D
	db	0x8B, 0xEC		; 04840 mov bp,sp
	mov	ax,0xe1b0		; 04842  start of IOB array (iob_stdin)
	mov	[bp+0x2],ax		; 04845  local: current IOB pointer
loc_04848:
	mov	ax,0xe2c8		; 04848  end of IOB array (20 * 14 = 0x118 past start)
	mov	bx,[bp+0x2]		; 0484B
	db	0x3B, 0xD8		; 0484E cmp bx,ax  ; past end of array?
	jnc	short loc_04861		; 04850 jnc 0x4861
	mov	al,[bx+0x8]		; 04852  check IOB flags byte
	xor	ah,ah			; 04855
	test	ax,ax			; 04857
	jz	short loc_04861		; 04859 jz 0x4861  ; flags == 0 means slot is free
	add	word [bp+0x2],0xe	; 0485B  advance to next IOB (14 bytes)
	jmp	short loc_04848		; 0485F jmp 0x4848
loc_04861:
	mov	ax,[bp+0x2]		; 04861
	cmp	ax,0xe2c8		; 04864  reached end without finding free slot?
	jnz	short loc_04870		; 04867 jnz 0x4870  ; found one
	db	0x33, 0xC0		; 04869 xor ax,ax  ; return 0 (no free slot)
	add	sp,0x6			; 0486B
	pop	bp			; 0486E
	ret				; 0486F
loc_04870:
	push	word [bp+0x2]		; 04870  IOB pointer (free slot)
	push	word [bp+0xc]		; 04873  mode string
	push	word [bp+0xa]		; 04876  filename
	call	init_iob_entry		; 04879
	db	0x8B, 0xE5		; 0487C mov sp,bp
	add	sp,0x6			; 0487E
	pop	bp			; 04881
	ret				; 04882

; ---- function init_iob_entry ----
; Lattice C fopen() core: parses the mode string and opens a file.
; Mode characters: 'r' (0x72) = read, 'w' (0x77) = write+create,
;   'a' (0x61) = append, 'b' (0x62) = binary mode prefix,
;   '+' (0x2B) after mode = read+write.
; Calls open_file_slot to get a DOS file handle, sets up IOB fields.
; Input: [bp+0x12] = filename, [bp+0x14] = mode string, [bp+0x16] = IOB pointer
; Output: AX = IOB pointer, or 0 on failure
init_iob_entry:
	push	bp			; 04883
	sub	sp,0xe			; 04884
	db	0x8B, 0xEC		; 04887 mov bp,sp
	mov	si,[bp+0x16]		; 04889  SI = IOB pointer
	db	0x82			; 0488C  ; (multi-byte instruction encoding)
	db	0x7C, 0x08		; 0488D jl 0x4897
	add	[si+0x6],dh		; 0488F
	push	si			; 04892  close existing IOB if already open
	call	fclose_iob		; 04893
	db	0x8B, 0xE5		; 04896 mov sp,bp
	mov	ax,[0xe5ca]		; 04898  stdio_mode (default mode flags)
	mov	si,[bp+0x14]		; 0489B  SI = mode string pointer
	mov	bl,[si+0x1]		; 0489E  BL = second char of mode string
	xor	bh,bh			; 048A1
	mov	[bp+0x8],ax		; 048A3  local: accumulated flags
	mov	[bp+0xa],si		; 048A6  local: mode string pointer (advanced)
	jmp	short loc_048BC		; 048A9 jmp 0x48bc
loc_048AB:
; Mode prefix 'a' (append): clear binary flag
	mov	word [bp+0x8],0x0	; 048AB  flags = 0 (text mode)
	jmp	short loc_048B7		; 048B0 jmp 0x48b7
loc_048B2:
; Mode prefix 'b' (binary): set binary flag 0x8000
	mov	word [bp+0x8],0x8000	; 048B2  flags = 0x8000 (binary mode)
loc_048B7:
	inc	word [bp+0xa]		; 048B7  skip prefix char
	jmp	short loc_048C6		; 048BA jmp 0x48c6
loc_048BC:
	cmp	bx,0x62			; 048BC  'b' = binary mode?
	jz	short loc_048B2		; 048BF jz 0x48b2
	cmp	bx,0x61			; 048C1  'a' = append mode?
	jz	short loc_048AB		; 048C4 jz 0x48ab
loc_048C6:
; Check for '+' modifier (read+write)
	mov	si,[bp+0xa]		; 048C6
	mov	al,[si+0x1]		; 048C9  next char after mode
	xor	ah,ah			; 048CC
	db	0x3D, 0x2B, 0x00	; 048CE cmp ax,0x2b  ; '+' ?
	jz	short loc_048D7		; 048D1 jz 0x48d7  ; yes: read+write
	db	0x33, 0xDB		; 048D3 xor bx,bx  ; BX = 0 (single mode)
	jmp	short loc_048DA		; 048D5 jmp 0x48da
loc_048D7:
	db	0x33, 0xDB		; 048D7 xor bx,bx
	inc	bx			; 048D9  BX = 1 (read+write mode)
loc_048DA:
; Dispatch on main mode character
	mov	si,[bp+0x14]		; 048DA  original mode string
	mov	al,[si]			; 048DD  first char = mode
	xor	ah,ah			; 048DF
	mov	[bp+0xc],bl		; 048E1  save read+write flag
	jmp	0x4bd1			; 048E4  jump to mode dispatch (in another module)
; --- 'w' mode: write with create (continuation from dispatch) ---
	mov	ax,[bp+0x8]		; 048E7
	db	0x0D, 0x08, 0x00	; 048EA or ax,0x8  ; set write-through flag
	mov	[bp+0x0],ax		; 048ED
	db	0x82			; 048F0
	db	0x7E, 0x0C		; 048F1 jng 0x48ff
	add	[si+0x5],dh		; 048F3
	mov	ax,0x2			; 048F6  open mode = write
	jmp	short loc_048FE		; 048F9 jmp 0x48fe
	mov	ax,0x1			; 048FB  open mode = write-only
loc_048FE:
	mov	bx,[bp+0x0]		; 048FE
	db	0x0B, 0xD8		; 04901 or bx,ax
	or	bx,0x100		; 04903  set create flag
	mov	ax,0x1a4		; 04907  Unix permissions 0644
	push	ax			; 0490A
	push	bx			; 0490B  flags
	push	word [bp+0x12]		; 0490C  filename
	call	open_file_slot		; 0490F
	db	0x8B, 0xE5		; 04912 mov sp,bp
	mov	[bp+0x6],ax		; 04914  file slot index
	inc	ax			; 04917  check for -1 (error)
	jnz	short loc_04921		; 04918 jnz 0x4921
	db	0x33, 0xC0		; 0491A xor ax,ax  ; return 0 on failure
	add	sp,0xe			; 0491C
	pop	bp			; 0491F
	ret				; 04920
loc_04921:
; Seek to end for append mode
	mov	ax,0x2			; 04921  whence = SEEK_END
	push	ax			; 04924
	db	0x33, 0xC0		; 04925 xor ax,ax  ; offset = 0
	push	ax			; 04927
	db	0x33, 0xDB		; 04928 xor bx,bx
	push	bx			; 0492A
	push	word [bp+0x6]		; 0492B  file slot
	call	seek_and_read		; 0492E  seek to end of file
	db	0x8B, 0xE5		; 04931 mov sp,bp
	db	0x82			; 04933
	db	0x7E, 0x0C		; 04934 jng 0x4942
	add	[si+0x5],dh		; 04936
	mov	ax,0x80			; 04939  IOB flag: has buffer
	jmp	short loc_04941		; 0493C jmp 0x4941
	mov	ax,0x2			; 0493E  IOB flag: write mode
loc_04941:
	mov	[bp+0x4],ax		; 04941  save IOB flags
	jmp	0x4be8			; 04944  jump to IOB finalization (in another module)
; --- 'r' mode read path (continuation) ---
	db	0x82			; 04947
	db	0x7E, 0x0C		; 04948 jng 0x4956
	add	[si+0x5],dh		; 0494A
	mov	ax,0x2			; 0494D  open mode = read+write
	jmp	short loc_04954		; 04950 jmp 0x4954
	db	0x33, 0xC0		; 04952 xor ax,ax  ; open mode = read-only
loc_04954:
	mov	bx,[bp+0x8]		; 04954
	db	0x0B, 0xD8		; 04957 or bx,ax
	push	bx			; 04959
	push	word [bp+0x12]		; 0495A  filename
	call	open_file_slot		; 0495D
	db	0x8B, 0xE5		; 04960 mov sp,bp
	mov	[bp+0x6],ax		; 04962  file slot index
	inc	ax			; 04965
	jnz	short loc_0496F		; 04966 jnz 0x496f
	db	0x33, 0xC0		; 04968 xor ax,ax  ; return 0 on failure
	add	sp,0xe			; 0496A
	pop	bp			; 0496D
	ret				; 0496E
loc_0496F:
	db	0x82			; 0496F
	db	0x7E, 0x0C		; 04970 jng 0x497e
	add	[si+0x5],dh		; 04972
	mov	ax,0x80			; 04975  IOB flag: has buffer
	jmp	short loc_0497D		; 04978 jmp 0x497d
	mov	ax,0x1			; 0497A  IOB flag: read mode
loc_0497D:
	mov	[bp+0x4],ax		; 0497D
	jmp	short loc_049E8		; 04980 jmp 0x49e8  ; -> IOB setup
loc_04982:
; --- 'w' mode write path (write+create+truncate) ---
	db	0x82			; 04982
	db	0x7E, 0x0C		; 04983 jng 0x4991
	add	[si+0x5],dh		; 04985
	mov	ax,0x2			; 04988  open mode = read+write
	jmp	short loc_04990		; 0498B jmp 0x4990
	mov	ax,0x1			; 0498D  open mode = write-only
loc_04990:
	mov	bx,[bp+0x8]		; 04990
	db	0x0B, 0xD8		; 04993 or bx,ax
	or	bx,0x100		; 04995  set create flag
	or	bx,0x200		; 04999  set truncate flag
	mov	ax,0x1a4		; 0499D  Unix permissions 0644
	push	ax			; 049A0
	push	bx			; 049A1  flags
	push	word [bp+0x12]		; 049A2  filename
	call	open_file_slot		; 049A5
	db	0x8B, 0xE5		; 049A8 mov sp,bp
	mov	[bp+0x6],ax		; 049AA  file slot index
	inc	ax			; 049AD
	jnz	short loc_049B7		; 049AE jnz 0x49b7
	db	0x33, 0xC0		; 049B0 xor ax,ax  ; return 0 on failure
	add	sp,0xe			; 049B2
	pop	bp			; 049B5
	ret				; 049B6
loc_049B7:
	db	0x82			; 049B7
	db	0x7E, 0x0C		; 049B8 jng 0x49c6
	add	[si+0x5],dh		; 049BA
	mov	ax,0x80			; 049BD  IOB flag: has buffer
	jmp	short loc_049C5		; 049C0 jmp 0x49c5
	mov	ax,0x2			; 049C2  IOB flag: write mode
loc_049C5:
	mov	[bp+0x4],ax		; 049C5
	jmp	short loc_049E8		; 049C8 jmp 0x49e8
loc_049CA:
; Unrecognized mode: return 0
	db	0x33, 0xC0		; 049CA xor ax,ax
	add	sp,0xe			; 049CC
	pop	bp			; 049CF
	ret				; 049D0
; --- Mode dispatch jump table (jumped to from 0x4BD1) ---
	db	0x3D, 0x77, 0x00	; 049D1 cmp ax,0x77  ; 'w' = write mode?
	jz	short loc_04982		; 049D4 jz 0x4982
	db	0x3D, 0x72, 0x00	; 049D6 cmp ax,0x72  ; 'r' = read mode?
	jnz	short loc_049DE		; 049D9 jnz 0x49de
	jmp	0x4b47			; 049DB  ; jump to read-mode path
loc_049DE:
	db	0x3D, 0x61, 0x00	; 049DE cmp ax,0x61  ; 'a' = append mode?
	jnz	short loc_049E6		; 049E1 jnz 0x49e6
	jmp	0x4ae7			; 049E3  ; jump to append-mode path
loc_049E6:
	jmp	short loc_049CA		; 049E6 jmp 0x49ca  ; unknown mode -> return 0
loc_049E8:
; --- IOB entry finalization ---
; Set up the IOB struct fields after successful file open.
	mov	ax,[bp+0x6]		; 049E8  file slot index
	mov	bx,0x2a			; 049EB  42 bytes per file table entry
	imul	bx			; 049EE
	db	0x8B, 0xF0		; 049F0 mov si,ax
	db	0x82			; 049F2  ; (multi-byte encoding)
	mov	sp,0xe5cf		; 049F3
	add	[si+0x13],dh		; 049F6  ; set flag in file table entry
	db	0x81, 0x4E, 0x04, 0x04, 0x00	; 049F9 or word [bp+0x4],0x4  ; add "opened" flag
	mov	ax,[bp+0x16]		; 049FE  IOB pointer
	db	0x05, 0x0C, 0x00	; 04A01 add ax,0xc  ; point to inline buffer (offset +12 in IOB)
	mov	si,[bp+0x16]		; 04A04
	mov	[si+0x6],ax		; 04A07  IOB buffer pointer = inline buffer
	jmp	short loc_04A14		; 04A0A jmp 0x4a14
	mov	si,[bp+0x16]		; 04A0C
	mov	word [si+0x6],0x0	; 04A0F  no buffer allocated
loc_04A14:
	mov	ax,[bp+0x6]		; 04A14  file slot index
	mov	si,[bp+0x16]		; 04A17  IOB pointer
	mov	[si+0x9],al		; 04A1A  IOB.fd = file slot index
	mov	ax,[si+0x6]		; 04A1D  buffer pointer
	mov	[si],ax			; 04A20  IOB.ptr = buffer start
	db	0x33, 0xC0		; 04A22 xor ax,ax
	mov	[si+0x4],ax		; 04A24  IOB.size = 0
	mov	[si+0x2],ax		; 04A27  IOB.count = 0
	mov	ax,[bp+0x4]		; 04A2A  mode flags
	mov	[si+0x8],al		; 04A2D  IOB.flags = mode flags
	db	0x8B, 0xC6		; 04A30 mov ax,si  ; return IOB pointer
	add	sp,0xe			; 04A32
	pop	bp			; 04A35
	ret				; 04A36

; ---- function fclose_iob ----
; Flushes and closes an IOB file entry.
; If write mode (flag & 2), flushes the write buffer first.
; If the IOB has a dynamically allocated buffer (not inline), frees it.
; Clears all IOB fields and closes the underlying file slot.
; Input: [bp+0x8] = IOB pointer
fclose_iob:
	push	bp			; 04A37
	sub	sp,0x4			; 04A38
	db	0x8B, 0xEC		; 04A3B mov bp,sp
	mov	si,[bp+0x8]		; 04A3D
	mov	al,[si+0x8]		; 04A40  IOB flags
	xor	ah,ah			; 04A43
	db	0x25, 0x02, 0x00	; 04A45 and ax,0x2  ; write mode?
	jz	short loc_04A54		; 04A48 jz 0x4a54  ; no, skip flush
	push	si			; 04A4A  IOB pointer
	mov	ax,0xffff		; 04A4B  flush signal (EOF marker)
	push	ax			; 04A4E
	call	crt_file_write_byte	; 04A4F  flush write buffer
	db	0x8B, 0xE5		; 04A52 mov sp,bp
loc_04A54:
	mov	si,[bp+0x8]		; 04A54
	mov	al,[si+0x8]		; 04A57  IOB flags
	xor	ah,ah			; 04A5A
	db	0x25, 0x0C, 0x00	; 04A5C and ax,0xc  ; check if inline buffer (bits 2-3)
	jnz	short loc_04A72		; 04A5F jnz 0x4a72  ; inline or special: don't free
	cmp	word [si+0xa],0x0	; 04A61  has allocated buffer size?
	jz	short loc_04A72		; 04A65 jz 0x4a72  ; no buffer to free
	push	word [si+0xa]		; 04A67  buffer size
	push	word [si+0x6]		; 04A6A  buffer pointer
	call	crt_free_small		; 04A6D  free the I/O buffer
	db	0x8B, 0xE5		; 04A70 mov sp,bp
loc_04A72:
	db	0x33, 0xC0		; 04A72 xor ax,ax
	mov	si,[bp+0x8]		; 04A74
	mov	[si+0x6],ax		; 04A77  clear buffer pointer
	mov	[si+0xa],ax		; 04A7A  clear buffer size
	mov	byte [si+0x8],0x0	; 04A7D  clear flags (mark as free)
	mov	al,[si+0x9]		; 04A81  file descriptor (slot index)
	xor	ah,ah			; 04A84
	push	ax			; 04A86
	call	close_file_slot		; 04A87  close underlying DOS file handle
	db	0x8B, 0xE5		; 04A8A mov sp,bp
	add	sp,0x4			; 04A8C
	pop	bp			; 04A8F
	ret				; 04A90

; ---- function fgets_iob ----
; Reads a line from stdin IOB (0xe1b0) until newline (0x0A) or EOF (0xFFFF).
; Null-terminates the output buffer.
; Input: [bp+0xc] = output buffer pointer
; Output: AX = buffer pointer if data was read, 0 if EOF with no data
fgets_iob:
	push	bp			; 04A91
	sub	sp,0x8			; 04A92
	db	0x8B, 0xEC		; 04A95 mov bp,sp
	mov	word [bp+0x4],0x0	; 04A97  bytes_read = 0
loc_04A9C:
; Try to read one byte from IOB inline buffer first
	mov	ax,[0xe1b2]		; 04A9C  iob_stdin.count (bytes remaining in buffer)
	dec	ax			; 04A9F
	test	ax,ax			; 04AA0
	mov	[0xe1b2],ax		; 04AA2
	js	short loc_04AB5		; 04AA5 js 0x4ab5  ; buffer empty, refill
	mov	si,[0xe1b0]		; 04AA7  iob_stdin.ptr (current buffer position)
	inc	word [0xe1b0]		; 04AAB  advance pointer
	mov	al,[si]			; 04AAF  read one byte
	xor	ah,ah			; 04AB1
	jmp	short loc_04ABE		; 04AB3 jmp 0x4abe
loc_04AB5:
; Buffer empty: call crt_file_read_byte to refill and get one byte
	mov	ax,0xe1b0		; 04AB5  iob_stdin
	push	ax			; 04AB8
	call	crt_file_read_byte	; 04AB9
	db	0x8B, 0xE5		; 04ABC mov sp,bp
loc_04ABE:
	db	0x3D, 0xFF, 0xFF	; 04ABE cmp ax,0xffff  ; EOF?
	mov	[bp+0x6],ax		; 04AC1  save current byte
	jz	short loc_04AED		; 04AC4 jz 0x4aed  ; EOF reached
	db	0x3D, 0x0A, 0x00	; 04AC6 cmp ax,0xa  ; newline (LF)?
	jnz	short loc_04ADB		; 04AC9 jnz 0x4adb  ; no, store byte
; Newline found: null-terminate and return
	mov	ax,[bp+0x4]		; 04ACB  bytes_read
	inc	word [bp+0x4]		; 04ACE
	mov	si,[bp+0xc]		; 04AD1  output buffer
	db	0x03, 0xF0		; 04AD4 add si,ax
	mov	byte [si],0x0		; 04AD6  null-terminate
	jmp	short loc_04AED		; 04AD9 jmp 0x4aed
loc_04ADB:
; Store byte in output buffer and continue
	mov	ax,[bp+0x4]		; 04ADB  bytes_read
	inc	word [bp+0x4]		; 04ADE
	mov	si,[bp+0xc]		; 04AE1  output buffer
	db	0x03, 0xF0		; 04AE4 add si,ax
	mov	ax,[bp+0x6]		; 04AE6  current byte
	mov	[si],al			; 04AE9  store it
	jmp	short loc_04A9C		; 04AEB jmp 0x4a9c  ; read next byte
loc_04AED:
	cmp	word [bp+0x4],0x0	; 04AED  any bytes read?
	jnz	short loc_04AFA		; 04AF1 jnz 0x4afa  ; yes
	db	0x33, 0xC0		; 04AF3 xor ax,ax  ; return 0 (EOF, no data)
	add	sp,0x8			; 04AF5
	pop	bp			; 04AF8
	ret				; 04AF9
loc_04AFA:
; Null-terminate and return buffer pointer
	mov	ax,[bp+0xc]		; 04AFA  output buffer
	mov	si,[bp+0x4]		; 04AFD  bytes_read
	db	0x03, 0xF0		; 04B00 add si,ax
	mov	byte [si],0x0		; 04B02  null-terminate
	add	sp,0x8			; 04B05
	pop	bp			; 04B08
	ret				; 04B09

; ---- function fread_iob ----
; Reads up to N bytes from an IOB (file stream) into a buffer.
; Stops early on newline (0x0A) or EOF (0xFFFF).
; Input: [bp+0x10] = IOB pointer, [bp+0xe] = max byte count, [bp+0xc] = dest buffer
; Output: AX = buffer pointer if data read, 0 if EOF with no data
fread_iob:
	push	bp			; 04B0A
	sub	sp,0x8			; 04B0B
	db	0x8B, 0xEC		; 04B0E mov bp,sp
	mov	word [bp+0x4],0x0	; 04B10  bytes_read = 0
loc_04B15:
	mov	ax,[bp+0xe]		; 04B15  max count
	dec	ax			; 04B18  leave room for null terminator
	mov	bx,[bp+0x4]		; 04B19  bytes_read
	db	0x3B, 0xD8		; 04B1C cmp bx,ax  ; reached limit?
	jnl	short loc_04B61		; 04B1E jnl 0x4b61  ; yes, done
; Try inline buffer read first
	mov	si,[bp+0x10]		; 04B20  IOB pointer
	mov	ax,[si+0x2]		; 04B23  IOB.count
	dec	ax			; 04B26
	mov	[si+0x2],ax		; 04B27
	test	ax,ax			; 04B2A
	js	short loc_04B3A		; 04B2C js 0x4b3a  ; buffer empty, refill
	mov	ax,[si]			; 04B2E  IOB.ptr
	inc	word [si]		; 04B30  advance pointer
	db	0x8B, 0xF8		; 04B32 mov di,ax
	mov	bl,[di]			; 04B34  read byte from buffer
	xor	bh,bh			; 04B36
	jmp	short loc_04B44		; 04B38 jmp 0x4b44
loc_04B3A:
	push	word [bp+0x10]		; 04B3A  IOB pointer
	call	crt_file_read_byte	; 04B3D  refill buffer and get byte
	db	0x8B, 0xE5		; 04B40 mov sp,bp
	db	0x8B, 0xD8		; 04B42 mov bx,ax
loc_04B44:
	mov	[bp+0x6],bx		; 04B44  save current byte
	inc	bx			; 04B47  check for EOF (0xFFFF + 1 = 0)
	jz	short loc_04B61		; 04B48 jz 0x4b61  ; EOF
	mov	ax,[bp+0x4]		; 04B4A  bytes_read
	inc	word [bp+0x4]		; 04B4D
	mov	si,[bp+0xc]		; 04B50  dest buffer
	db	0x03, 0xF0		; 04B53 add si,ax
	mov	ax,[bp+0x6]		; 04B55  current byte
	mov	[si],al			; 04B58  store it
	db	0x3D, 0x0A, 0x00	; 04B5A cmp ax,0xa  ; newline?
	jnz	short loc_04B15		; 04B5D jnz 0x4b15  ; no, continue reading
	jmp	short loc_04B61		; 04B5F jmp 0x4b61  ; yes, stop
loc_04B61:
	mov	ax,[bp+0x4]		; 04B61  bytes_read
	mov	si,[bp+0xc]		; 04B64  dest buffer
	db	0x03, 0xF0		; 04B67 add si,ax
	mov	byte [si],0x0		; 04B69  null-terminate
	test	ax,ax			; 04B6C  any bytes read?
	jnz	short loc_04B77		; 04B6E jnz 0x4b77  ; yes
	db	0x33, 0xC0		; 04B70 xor ax,ax  ; return 0 (EOF, no data)
	add	sp,0x8			; 04B72
	pop	bp			; 04B75
	ret				; 04B76
loc_04B77:
	mov	ax,[bp+0xc]		; 04B77  return buffer pointer
	add	sp,0x8			; 04B7A
	pop	bp			; 04B7D
	ret				; 04B7E

; ---- function show_insert_disk ----
; Closes all 20 IOB entries and all file slots, then reinitializes I/O.
; Called when a disk swap is needed (e.g., "insert disk" prompt).
show_insert_disk:
	push	bp			; 04B7F
	sub	sp,0x4			; 04B80
	db	0x8B, 0xEC		; 04B83 mov bp,sp
	mov	word [bp+0x2],0x0	; 04B85  loop counter i = 0
loc_04B8A:
; Close all 20 IOB entries (14 bytes each, starting at 0xe1b0)
	mov	ax,[bp+0x2]		; 04B8A
	db	0x3D, 0x14, 0x00	; 04B8D cmp ax,0x14  ; i < 20?
	jnl	short loc_04BA5		; 04B90 jnl 0x4ba5  ; done with IOBs
	mov	bx,0xe			; 04B92  14 bytes per IOB
	imul	bx			; 04B95
	add	ax,0xe1b0		; 04B97  iob_array + i*14
	push	ax			; 04B9A
	call	fclose_iob		; 04B9B
	db	0x8B, 0xE5		; 04B9E mov sp,bp
	inc	word [bp+0x2]		; 04BA0
	jmp	short loc_04B8A		; 04BA3 jmp 0x4b8a
loc_04BA5:
; Close all file slots
	mov	word [bp+0x2],0x0	; 04BA5  i = 0
loc_04BAA:
	mov	ax,[bp+0x2]		; 04BAA
	cmp	ax,[0xe5cc]		; 04BAD  i < file_slot_count?
	jnl	short loc_04BBE		; 04BB1 jnl 0x4bbe  ; done
	push	ax			; 04BB3
	call	close_file_slot		; 04BB4
	db	0x8B, 0xE5		; 04BB7 mov sp,bp
	inc	word [bp+0x2]		; 04BB9
	jmp	short loc_04BAA		; 04BBC jmp 0x4baa
loc_04BBE:
; Reinitialize the I/O system
	push	word [bp+0xa]		; 04BBE
	push	word [bp+0x8]		; 04BC1
	call	crt_init_io		; 04BC4
	db	0x8B, 0xE5		; 04BC7 mov sp,bp
	add	sp,0x4			; 04BC9
	pop	bp			; 04BCC
	ret				; 04BCD

; ---- function heap_alloc ----
; Allocates paragraph-aligned memory from the heap.
; If not enough heap space: on DOS 2+, grows via crt_realloc_up; on DOS 1.x returns 0.
; Input: [bp+0x10]::[bp+0x12] = requested size (low:high, 32-bit)
; Output: AX = segment address of allocated block, or 0 if failed
heap_alloc:
	push	bp			; 04BCE
	sub	sp,0xc			; 04BCF
	db	0x8B, 0xEC		; 04BD2 mov bp,sp
	mov	ax,[bp+0x12]		; 04BD4  size high word
	mov	bx,[bp+0x10]		; 04BD7  size low word
	mov	cx,[0x67]		; 04BDA  heap_remainder
	mov	dx,[0x65]		; 04BDE  heap_size
	call	crt_cmp_long		; 04BE2  compare requested vs available
	jng	short loc_04C50		; 04BE5 jng 0x4c50  ; enough space, allocate directly
; Not enough heap: try to grow
	mov	al,[0xf]		; 04BE7  dos_version
	xor	ah,ah			; 04BEA
	db	0x3D, 0x02, 0x00	; 04BEC cmp ax,0x2  ; DOS 2+ ?
	jnl	short loc_04BF8		; 04BEF jnl 0x4bf8  ; yes, can realloc
	db	0x33, 0xC0		; 04BF1 xor ax,ax  ; DOS 1.x: return 0 (can't grow)
	add	sp,0xc			; 04BF3
	pop	bp			; 04BF6
	ret				; 04BF7
loc_04BF8:
; Round up size to paragraph boundary (16 bytes) and convert to paragraphs
	mov	ax,[bp+0x10]		; 04BF8  size low
	db	0x05, 0x0F, 0x00	; 04BFB add ax,0xf  ; round up to next paragraph
	mov	bx,[bp+0x12]		; 04BFE  size high
	adc	bx,0x0			; 04C01
	mov	[bp+0xa],bx		; 04C04
	db	0x81, 0xE3, 0xF0, 0xFF	; 04C07 and bx,0xfff0  ; mask to paragraph
	mov	[bp+0x8],ax		; 04C0B
	db	0x33, 0xC0		; 04C0E xor ax,ax
	db	0x0B, 0xD8		; 04C10 or bx,ax  ; check if high word is non-zero
	jz	short loc_04C1B		; 04C12 jz 0x4c1b
	db	0x33, 0xC0		; 04C14 xor ax,ax  ; too large, return 0
	add	sp,0xc			; 04C16
	pop	bp			; 04C19
	ret				; 04C1A
loc_04C1B:
; Shift right by 4 to convert bytes to paragraphs
	mov	cx,0x4			; 04C1B
	mov	ax,[bp+0xa]		; 04C1E
	mov	bx,[bp+0x8]		; 04C21
	sar	ax,1			; 04C24
	rcr	bx,1			; 04C26
	loop	0x4c24			; 04C28  shift 32-bit value right by 4
	push	bx			; 04C2A  paragraphs to allocate
	mov	[bp+0x6],bx		; 04C2B
	call	crt_realloc_up		; 04C2E  grow DOS memory allocation
	db	0x8B, 0xE5		; 04C31 mov sp,bp
	test	ax,ax			; 04C33  success?
	jz	short loc_04C3E		; 04C35 jz 0x4c3e  ; yes
	db	0x33, 0xC0		; 04C37 xor ax,ax  ; realloc failed, return 0
	add	sp,0xc			; 04C39
	pop	bp			; 04C3C
	ret				; 04C3D
loc_04C3E:
; Update heap tracking with new space
	mov	ax,[bp+0xa]		; 04C3E
	mov	bx,[bp+0x8]		; 04C41
	db	0x81, 0xE3, 0xF0, 0xFF	; 04C44 and bx,0xfff0
	add	[0x65],bx		; 04C48  heap_size += new paragraphs (low)
	adc	[0x67],ax		; 04C4C  heap_remainder += carry (high)
loc_04C50:
; Allocate from current heap position
	mov	ax,[0x15]		; 04C50  stack_top (heap base segment)
	mov	bx,[0x61]		; 04C53  heap_offset
	db	0x03, 0xC3		; 04C57 add ax,bx  ; AX = allocated segment
	mov	cx,[bp+0x10]		; 04C59  requested size (low)
	add	[0x61],cx		; 04C5C  advance heap_offset
	sub	[0x65],cx		; 04C60  decrease heap_size
	mov	bx,[bp+0x12]		; 04C64  requested size (high)
	sbb	[0x67],bx		; 04C67  decrease heap_remainder
	mov	[bp+0x4],ax		; 04C6B  return value = allocated segment
	add	sp,0xc			; 04C6E
	pop	bp			; 04C71
	ret				; 04C72

; ---- function heap_alloc_16 ----
; Thin wrapper: allocates memory with a 16-bit size (zero-extends to 32-bit).
; Input: [bp+0xc] = size in bytes (16-bit)
; Output: AX = segment address of allocated block, or 0xFFFF if failed
heap_alloc_16:
	push	bp			; 04C73
	sub	sp,0x8			; 04C74
	db	0x8B, 0xEC		; 04C77 mov bp,sp
	mov	ax,[bp+0xc]		; 04C79  size (16-bit)
	db	0x33, 0xDB		; 04C7C xor bx,bx  ; high word = 0
	push	bx			; 04C7E
	push	ax			; 04C7F
	call	heap_alloc		; 04C80
	db	0x8B, 0xE5		; 04C83 mov sp,bp
	mov	[bp+0x6],ax		; 04C85
	test	ax,ax			; 04C88  success?
	jz	short loc_04C91		; 04C8A jz 0x4c91  ; no, return 0xFFFF
	add	sp,0x8			; 04C8C
	pop	bp			; 04C8F
	ret				; 04C90
loc_04C91:
	mov	ax,0xffff		; 04C91  return 0xFFFF (allocation failed)
	add	sp,0x8			; 04C94
	pop	bp			; 04C97
	ret				; 04C98

; ---- function reset_heap ----
; Resets the heap to its initial state. On DOS 2+, shrinks DOS memory allocation
; back to minimum. Clears heap offset and all free-list head pointers.
reset_heap:
	push	bp			; 04C99
	sub	sp,0xe			; 04C9A
	db	0x8B, 0xEC		; 04C9D mov bp,sp
	mov	al,[0xf]		; 04C9F  dos_version
	xor	ah,ah			; 04CA2
	db	0x3D, 0x02, 0x00	; 04CA4 cmp ax,0x2  ; DOS 2+?
	jnl	short loc_04CFC		; 04CA7 jnl 0x4cfc  ; yes, use realloc_down path
; DOS 1.x path: recalculate heap size without shrinking
	mov	ax,[0x61]		; 04CA9  heap_offset
	sub	ax,[0x5d]		; 04CAC  heap_base_off
	db	0x33, 0xDB		; 04CB0 xor bx,bx  ; sign-extend to 32-bit
	test	ax,ax			; 04CB2
	jns	short loc_04CB7		; 04CB4 jns 0x4cb7
	dec	bx			; 04CB6  negative: set high word to -1
loc_04CB7:
	mov	cx,[0x65]		; 04CB7  heap_size
	db	0x03, 0xC1		; 04CBB add ax,cx  ; AX:BX = used + remaining
	mov	dx,[0x67]		; 04CBD  heap_remainder
	db	0x13, 0xDA		; 04CC1 adc bx,dx
	mov	cx,[0x15]		; 04CC3  stack_top
	db	0x33, 0xD2		; 04CC7 xor dx,dx
	mov	[0x65],ax		; 04CC9  restore heap_size
	db	0x03, 0xC1		; 04CCC add ax,cx
	mov	[0x67],bx		; 04CCE  restore heap_remainder
	db	0x13, 0xDA		; 04CD2 adc bx,dx
	mov	[bp+0x4],ax		; 04CD4
	db	0x8B, 0xC3		; 04CD7 mov ax,bx
	mov	bx,[bp+0x4]		; 04CD9
	mov	[bp+0x0],cx		; 04CDC
	mov	cx,0x1			; 04CDF
	mov	[bp+0x2],dx		; 04CE2
	db	0x33, 0xD2		; 04CE5 xor dx,dx
	call	crt_cmp_long		; 04CE7  check if heap > 1 paragraph
	jng	short loc_04D56		; 04CEA jng 0x4d56
	sub	dx,[bp+0x0]		; 04CEC
	sbb	cx,[bp+0x2]		; 04CEF
	mov	[0x67],cx		; 04CF2
	mov	[0x65],dx		; 04CF6
	jmp	short loc_04D56		; 04CFA jmp 0x4d56
loc_04CFC:
; DOS 2+ path: shrink DOS memory allocation back
	mov	ax,[0xe4c0]		; 04CFC  heap_pool_lo
	db	0x05, 0x0F, 0x00	; 04CFF add ax,0xf  ; round up to paragraph
	mov	bx,[0xe4c2]		; 04D02  heap_pool_hi
	adc	bx,0x0			; 04D06
	mov	[bp+0xc],bx		; 04D09
	db	0x81, 0xE3, 0xF0, 0xFF	; 04D0C and bx,0xfff0
	mov	[bp+0xa],ax		; 04D10
	db	0x33, 0xC0		; 04D13 xor ax,ax
	db	0x0B, 0xD8		; 04D15 or bx,ax  ; high word non-zero?
	jz	short loc_04D21		; 04D17 jz 0x4d21
	mov	ax,0xffff		; 04D19  too large, return error
	add	sp,0xe			; 04D1C
	pop	bp			; 04D1F
	ret				; 04D20
loc_04D21:
; Convert to paragraphs (shift right 4)
	mov	cx,0x4			; 04D21
	mov	ax,[bp+0xc]		; 04D24
	mov	bx,[bp+0xa]		; 04D27
	sar	ax,1			; 04D2A
	rcr	bx,1			; 04D2C
	loop	0x4d2a			; 04D2E
	push	bx			; 04D30  paragraphs to shrink to
	mov	[bp+0x8],bx		; 04D31
	call	crt_realloc_down	; 04D34  shrink DOS memory allocation
	db	0x8B, 0xE5		; 04D37 mov sp,bp
	test	ax,ax			; 04D39  success?
	jz	short loc_04D45		; 04D3B jz 0x4d45
	mov	ax,0xffff		; 04D3D  realloc failed
	add	sp,0xe			; 04D40
	pop	bp			; 04D43
	ret				; 04D44
loc_04D45:
; Update heap tracking
	mov	ax,[bp+0xc]		; 04D45
	mov	bx,[bp+0xa]		; 04D48
	db	0x81, 0xE3, 0xF0, 0xFF	; 04D4B and bx,0xfff0
	mov	[0x67],ax		; 04D4F  heap_remainder = new value
	mov	[0x65],bx		; 04D52  heap_size = new value
loc_04D56:
; Reset heap offset and free-list pointers
	mov	ax,[0x5d]		; 04D56  heap_base_off
	db	0x33, 0xDB		; 04D59 xor bx,bx
	db	0x33, 0xC9		; 04D5B xor cx,cx
	mov	[0x61],ax		; 04D5D  heap_offset = heap_base_off (reset)
	mov	[0xe4b8],cx		; 04D60  clear free-list head B
	mov	[0xe4bc],cx		; 04D64  clear free-list head D
	mov	[0xe4b6],bx		; 04D68  clear free-list head A
	mov	[0xe4ba],bx		; 04D6C  clear free-list head C
	db	0x8B, 0xC3		; 04D70 mov ax,bx  ; return 0
	add	sp,0xe			; 04D72
	pop	bp			; 04D75
	ret				; 04D76

; ---- function get_file_slot ----
; Validates a file slot index and returns a pointer to the 42-byte file table entry.
; Input: [bp+0x6] = file slot index
; Output: AX = pointer to file table entry (base 0xe5ce + index*42), or 0 if invalid
; Sets file_error_code to 9 (EBADF) on invalid slot.
get_file_slot:
	push	bp			; 04D77
	sub	sp,0x2			; 04D78
	db	0x8B, 0xEC		; 04D7B mov bp,sp
	mov	ax,[bp+0x6]		; 04D7D  file slot index
	test	ax,ax			; 04D80
	js	short loc_04D9C		; 04D82 js 0x4d9c  ; negative index -> error
	cmp	ax,[0xe5cc]		; 04D84  >= file_slot_count?
	jnl	short loc_04D9C		; 04D88 jnl 0x4d9c  ; out of range -> error
; Check that slot is in use (flag byte has bit 7 set)
	mov	bx,0x2a			; 04D8A  42 bytes per entry
	imul	bx			; 04D8D
	db	0x8B, 0xF0		; 04D8F mov si,ax
	mov	al,[si+0xe5ce]		; 04D91  flags byte (0xe5ce - 0x1a32 offset trick)
	xor	ah,ah			; 04D95
	and	ax,0x80			; 04D97  bit 7 = "slot in use"
	jnz	short loc_04DA9		; 04D9A jnz 0x4da9  ; slot is valid
loc_04D9C:
	mov	word [0xe4be],0x9	; 04D9C  file_error_code = 9 (EBADF)
	db	0x33, 0xC0		; 04DA2 xor ax,ax  ; return 0 (invalid)
	add	sp,0x2			; 04DA4
	pop	bp			; 04DA7
	ret				; 04DA8
loc_04DA9:
; Return pointer to file table entry
	mov	ax,[bp+0x6]		; 04DA9  file slot index
	mov	bx,0x2a			; 04DAC  42 bytes per entry
	imul	bx			; 04DAF
	add	ax,0xe5ce		; 04DB1  file_table_base + index*42
	add	sp,0x2			; 04DB4
	pop	bp			; 04DB7
	ret				; 04DB8

; ---- function open_file_slot ----
; Finds a free file table slot, sets up flags, and opens a DOS file handle.
; Scans the file table (up to file_slot_count entries, 42 bytes each at 0xe5ce)
; for a free slot (flags byte == 0).
; Input: [bp+0x10] = filename, [bp+0x12] = flags (mode bits), [bp+0x14] = permissions
; Output: AX = file slot index, or 0xFFFF on error
; Error codes: 0x18 = no free slot, 0x02 = file not found, 0x11 = file exists,
;              0x16 = invalid argument
open_file_slot:
	push	bp			; 04DB9
	sub	sp,0xc			; 04DBA
	db	0x8B, 0xEC		; 04DBD mov bp,sp
	mov	word [bp+0x4],0x0	; 04DBF  slot_index = 0
loc_04DC4:
; Scan for free slot
	mov	ax,[bp+0x4]		; 04DC4
	mov	bx,[0xe5cc]		; 04DC7  file_slot_count
	db	0x3B, 0xD8		; 04DCB cmp bx,ax  ; past all slots?
	jng	short loc_04DE5		; 04DCD jng 0x4de5  ; yes, check result
	mov	bx,0x2a			; 04DCF  42 bytes per entry
	imul	bx			; 04DD2
	db	0x8B, 0xF0		; 04DD4 mov si,ax
	mov	al,[si+0xe5ce]		; 04DD6  flags byte (file_table_base offset trick)
	xor	ah,ah			; 04DDA
	test	ax,ax			; 04DDC  slot in use?
	jz	short loc_04DE5		; 04DDE jz 0x4de5  ; no, found free slot
	inc	word [bp+0x4]		; 04DE0  try next slot
	jmp	short loc_04DC4		; 04DE3 jmp 0x4dc4
loc_04DE5:
	mov	ax,[bp+0x4]		; 04DE5
	cmp	ax,[0xe5cc]		; 04DE8  used all slots without finding free one?
	jnz	short loc_04DFC		; 04DEC jnz 0x4dfc  ; no, slot found
	mov	word [0xe4be],0x18	; 04DEE  file_error_code = 0x18 (EMFILE, too many open files)
	mov	ax,0xffff		; 04DF4  return -1
	add	sp,0xc			; 04DF7
	pop	bp			; 04DFA
	ret				; 04DFB
loc_04DFC:
; Set up slot: calculate entry pointer
	mov	ax,[bp+0x4]		; 04DFC  slot_index
	mov	bx,0x2a			; 04DFF
	imul	bx			; 04E02
	add	ax,0xe5ce		; 04E04  AX = file_table_base + slot_index * 42
	db	0x8B, 0xF0		; 04E07 mov si,ax  ; SI = entry pointer
; Determine text/binary mode from global flags and request flags
	mov	ax,[0xe5c6]		; 04E09  stdio_flags (global binary mode flag)
	and	ax,0x8000		; 04E0C  isolate binary flag
	mov	bx,[bp+0x12]		; 04E0F  request flags
	db	0x33, 0xC3		; 04E12 xor ax,bx  ; XOR: if both agree, result bit = 0 (text)
	mov	[bp+0x12],ax		; 04E14
	and	ax,0x8000		; 04E17  check resulting binary flag
	mov	[bp+0xa],si		; 04E1A  save entry pointer
	jz	short loc_04E24		; 04E1D jz 0x4e24  ; text mode
	mov	ax,0x10			; 04E1F  binary mode flag for slot
	jmp	short loc_04E26		; 04E22 jmp 0x4e26
loc_04E24:
	db	0x33, 0xC0		; 04E24 xor ax,ax  ; text mode
loc_04E26:
	or	ax,0x80			; 04E26  set "slot in use" flag (bit 7)
	mov	si,[bp+0xa]		; 04E29
	mov	[si],al			; 04E2C  store flags byte in slot
; Dispatch on access mode (low 2 bits of flags)
	mov	ax,[bp+0x12]		; 04E2E
	db	0x25, 0x03, 0x00	; 04E31 and ax,0x3  ; 0=read, 1=write, 2=read+write
	jmp	short loc_04E96		; 04E34 jmp 0x4e96  ; -> mode dispatch
loc_04E36:
; Access mode 0: read-only — set read flag (0x40)
	mov	si,[bp+0xa]		; 04E36
	mov	al,[si]			; 04E39
	xor	ah,ah			; 04E3B
	db	0x0D, 0x40, 0x00	; 04E3D or ax,0x40  ; read flag
	mov	[si],al			; 04E40
	jmp	short loc_04EA7		; 04E42 jmp 0x4ea7
loc_04E44:
; Access mode 1: write-only — set write flag (0x20), optionally with write-through (0x08)
	mov	ax,[bp+0x12]		; 04E44
	db	0x25, 0x08, 0x00	; 04E47 and ax,0x8  ; write-through flag?
	jz	short loc_04E51		; 04E4A jz 0x4e51
	mov	ax,0x8			; 04E4C  write-through
	jmp	short loc_04E53		; 04E4F jmp 0x4e53
loc_04E51:
	db	0x33, 0xC0		; 04E51 xor ax,ax  ; no write-through
loc_04E53:
	db	0x0D, 0x20, 0x00	; 04E53 or ax,0x20  ; write flag
	mov	si,[bp+0xa]		; 04E56
	mov	bl,[si]			; 04E59
	xor	bh,bh			; 04E5B
	db	0x0B, 0xD8		; 04E5D or bx,ax
	mov	[si],bl			; 04E5F
	jmp	short loc_04EA7		; 04E61 jmp 0x4ea7
loc_04E63:
; Access mode 2: read+write — set both flags (0x60)
	mov	ax,[bp+0x12]		; 04E63
	db	0x25, 0x08, 0x00	; 04E66 and ax,0x8
	jz	short loc_04E70		; 04E69 jz 0x4e70
	mov	ax,0x8			; 04E6B
	jmp	short loc_04E72		; 04E6E jmp 0x4e72
loc_04E70:
	db	0x33, 0xC0		; 04E70 xor ax,ax
loc_04E72:
	db	0x0D, 0x60, 0x00	; 04E72 or ax,0x60  ; read+write flags
	mov	si,[bp+0xa]		; 04E75
	mov	bl,[si]			; 04E78
	xor	bh,bh			; 04E7A
	db	0x0B, 0xD8		; 04E7C or bx,ax
	mov	[si],bl			; 04E7E
	jmp	short loc_04EA7		; 04E80 jmp 0x4ea7
loc_04E82:
; Invalid access mode: clear slot, set error
	mov	si,[bp+0xa]		; 04E82
	mov	byte [si],0x0		; 04E85  clear slot flags (free it)
	mov	word [0xe4be],0x16	; 04E88  file_error_code = 0x16 (EINVAL)
	mov	ax,0xffff		; 04E8E  return -1
	add	sp,0xc			; 04E91
	pop	bp			; 04E94
	ret				; 04E95
loc_04E96:
; Mode dispatch: 0=read, 1=write, 2=read+write, else=error
	db	0x3D, 0x02, 0x00	; 04E96 cmp ax,0x2
	jz	short loc_04E63		; 04E99 jz 0x4e63  ; read+write
	db	0x3D, 0x01, 0x00	; 04E9B cmp ax,0x1
	jz	short loc_04E44		; 04E9E jz 0x4e44  ; write
	db	0x3D, 0x00, 0x00	; 04EA0 cmp ax,0x0
	jz	short loc_04E36		; 04EA3 jz 0x4e36  ; read
	jmp	short loc_04E82		; 04EA5 jmp 0x4e82  ; invalid
loc_04EA7:
; Check if filename is empty (device name matching)
	mov	si,[bp+0x10]		; 04EA7  filename
	mov	al,[si]			; 04EAA  first char
	xor	ah,ah			; 04EAC
	test	ax,ax			; 04EAE  null string?
	jnz	short loc_04EC1		; 04EB0 jnz 0x4ec1  ; no, try to match device names
; Empty filename: mark as device, return slot
	mov	si,[bp+0xa]		; 04EB2
	mov	byte [si+0x1],0x1	; 04EB5  is_device = 1
	mov	ax,[bp+0x4]		; 04EB9  return slot index
	add	sp,0xc			; 04EBC
	pop	bp			; 04EBF
	ret				; 04EC0
loc_04EC1:
; Search device name table (24 entries, 10 bytes each, at 0xe2c8)
; e.g. CON:, PRN:, LST:, AUX:, NUL: etc.
	mov	word [bp+0x6],0x0	; 04EC1  device_index = 0
loc_04EC6:
	mov	ax,[bp+0x6]		; 04EC6
	db	0x3D, 0x18, 0x00	; 04EC9 cmp ax,0x18  ; 24 devices
	jnl	short loc_04F05		; 04ECC jnl 0x4f05  ; not a device name
	mov	bx,0xa			; 04ECE  10 bytes per entry
	imul	bx			; 04ED1
	add	ax,0xe2c8		; 04ED3  device_table + index*10
	inc	ax			; 04ED6  skip first byte (device handle byte)
	push	ax			; 04ED7  device name string
	push	word [bp+0x10]		; 04ED8  filename
	call	crt_strcmp		; 04EDB  compare strings
	db	0x8B, 0xE5		; 04EDE mov sp,bp
	test	ax,ax			; 04EE0  match?
	jnz	short loc_04F00		; 04EE2 jnz 0x4f00  ; no match, try next
; Found matching device name
	mov	ax,[bp+0x6]		; 04EE4
	mov	bx,0xa			; 04EE7
	imul	bx			; 04EEA
	db	0x8B, 0xF0		; 04EEC mov si,ax
	mov	al,[si+0xe2c8]		; 04EEE  device handle byte
	mov	di,[bp+0xa]		; 04EF2
	mov	[di+0x1],al		; 04EF5  store device handle in file slot
	mov	ax,[bp+0x4]		; 04EF8  return slot index
	add	sp,0xc			; 04EFB
	pop	bp			; 04EFE
	ret				; 04EFF
loc_04F00:
	inc	word [bp+0x6]		; 04F00  next device
	jmp	short loc_04EC6		; 04F03 jmp 0x4ec6
loc_04F05:
; Not a device: open as regular file via DOS
	mov	si,[bp+0xa]		; 04F05
	mov	byte [si+0x1],0x0	; 04F08  is_device = 0
	mov	al,[0xf]		; 04F0C  dos_version
	xor	ah,ah			; 04F0F
	db	0x3D, 0x01, 0x00	; 04F11 cmp ax,0x1  ; DOS 1.x?
	jg	short loc_04F19		; 04F14 jg 0x4f19  ; DOS 2+, use handle-based file I/O
	jmp	0x51b0			; 04F16  ; DOS 1.x: jump to FCB-based file I/O (in another module)
loc_04F19:
; DOS 2+ file open path
	mov	ax,[bp+0x12]		; 04F19  flags
	and	ax,0x200		; 04F1C  truncate flag? (delete before create)
	jz	short loc_04F29		; 04F1F jz 0x4f29  ; no
	push	word [bp+0x10]		; 04F21  filename
	call	dos_delete_file		; 04F24  delete existing file first
	db	0x8B, 0xE5		; 04F27 mov sp,bp
loc_04F29:
; Determine DOS open mode
	mov	ax,[bp+0x12]		; 04F29  flags
	db	0x25, 0x08, 0x00	; 04F2C and ax,0x8  ; write-through bit?
	jz	short loc_04F36		; 04F2F jz 0x4f36
	mov	ax,0x2			; 04F31  DOS open mode = 2 (read+write)
	jmp	short loc_04F3C		; 04F34 jmp 0x4f3c
loc_04F36:
	mov	ax,[bp+0x12]		; 04F36  flags
	db	0x25, 0x03, 0x00	; 04F39 and ax,0x3  ; access mode (0=read, 1=write, 2=rw)
loc_04F3C:
	push	ax			; 04F3C  DOS open mode
	push	word [bp+0x10]		; 04F3D  filename
	call	dos_open_file		; 04F40  INT 21h/3Dh
	db	0x8B, 0xE5		; 04F43 mov sp,bp
	mov	si,[bp+0xa]		; 04F45  file slot entry pointer
	mov	[si+0x2],ax		; 04F48  store DOS file handle
	cmp	word [0x80],0x0		; 04F4B  dos_error_code set?
	jz	short loc_04F86		; 04F50 jz 0x4f86  ; no error, opened OK
; Open failed: try creating the file if create flag is set
	mov	ax,[bp+0x12]		; 04F52
	and	ax,0x300		; 04F55  create flag (bit 8)?
	jz	short loc_04F6B		; 04F58 jz 0x4f6b  ; no create flag, don't retry
	db	0x33, 0xC0		; 04F5A xor ax,ax  ; file attributes = 0
	push	ax			; 04F5C
	push	word [bp+0x10]		; 04F5D  filename
	call	dos_create_file		; 04F60  INT 21h/3Ch
	db	0x8B, 0xE5		; 04F63 mov sp,bp
	mov	si,[bp+0xa]		; 04F65
	mov	[si+0x2],ax		; 04F68  store DOS file handle
loc_04F6B:
	cmp	word [0x80],0x0		; 04F6B  still error?
	jz	short loc_04FB0		; 04F70 jz 0x4fb0  ; no, success
; Both open and create failed
	mov	word [0xe4be],0x2	; 04F72  file_error_code = 2 (ENOENT)
	mov	si,[bp+0xa]		; 04F78
	mov	byte [si],0x0		; 04F7B  clear slot (free it)
	mov	ax,0xffff		; 04F7E  return -1
	add	sp,0xc			; 04F81
	pop	bp			; 04F84
	ret				; 04F85
loc_04F86:
; Open succeeded: check exclusive-create flag (0x500 = must not exist)
	mov	ax,[bp+0x12]		; 04F86
	and	ax,0x500		; 04F89  exclusive + create flags both set?
	cmp	ax,0x500		; 04F8C
	jnz	short loc_04FB0		; 04F8F jnz 0x4fb0  ; no, normal open succeeded
; File already exists but caller wanted exclusive create: close and fail
	mov	si,[bp+0xa]		; 04F91
	push	word [si+0x2]		; 04F94  DOS file handle
	call	dos_close_file		; 04F97
	db	0x8B, 0xE5		; 04F9A mov sp,bp
	mov	word [0xe4be],0x11	; 04F9C  file_error_code = 0x11 (EEXIST)
	mov	si,[bp+0xa]		; 04FA2
	mov	byte [si],0x0		; 04FA5  clear slot
	mov	ax,0xffff		; 04FA8  return -1
	add	sp,0xc			; 04FAB
	pop	bp			; 04FAE
	ret				; 04FAF
loc_04FB0:
	mov	ax,[bp+0x4]		; 04FB0  return slot index
	add	sp,0xc			; 04FB3
	pop	bp			; 04FB6
	ret				; 04FB7

; ---- function open_file_rw ----
; Thin wrapper for open_file_slot with read+write+create flags (0x301).
; The high bit (0x8000) of the flags parameter controls binary/text mode.
; Input: [bp+0xa] = filename, [bp+0xc] = flags (bit 15 = binary, low bits = extra)
; Output: AX = file slot index, or 0xFFFF on error
open_file_rw:
	push	bp			; 04FB8
	sub	sp,0x6			; 04FB9
	db	0x8B, 0xEC		; 04FBC mov bp,sp
	mov	ax,[bp+0xc]		; 04FBE  caller flags
	and	ax,0x8000		; 04FC1  isolate binary mode bit
	or	ax,0x301		; 04FC4  OR with read+write+create (0x301)
	mov	bx,[bp+0xc]		; 04FC7
	and	bx,0x7fff		; 04FCA  extra flags (permissions bits)
	push	bx			; 04FCE  permissions
	push	ax			; 04FCF  flags
	push	word [bp+0xa]		; 04FD0  filename
	call	open_file_slot		; 04FD3
	db	0x8B, 0xE5		; 04FD6 mov sp,bp
	add	sp,0x6			; 04FD8
	pop	bp			; 04FDB
	ret				; 04FDC
