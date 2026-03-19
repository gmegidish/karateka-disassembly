; Scene update, animation processing, random numbers


; ---- function scene_update ----
; Main scene state update — called once per game frame.
; Processes both player (character 1) and enemy (character 2) animation frames.
;
; Algorithm:
;   1. Reset sprite update flags
;   2. Align player_x and enemy_x to 4-pixel boundaries
;   3. Copy animation data to write buffer via memcpy_block
;   4. If combat_active > 1, skip to end (combat transition)
;   5. PLAYER LOOP: Walk the player animation frame table:
;      - If end marker (0xFF), call anim_process or player_anim_select to get next anim ID
;      - Look up new frame pointer from animation table
;      - Extract anim ID, direction, facing from frame data
;      - Apply X velocity (signed byte), clamp to [player_x_min, player_x_max]
;      - Push-back: if player would overlap enemy, reduce player_x
;      - Camera follow: camera_x = player_x - 150 (or enemy_x - 170 if locked)
;      - Clamp camera to [camera_x_min, camera_x_max]
;      - Write sprite data to animation buffer
;      - Advance frame pointer by 0x11 (17 bytes per frame entry)
;   6. ENEMY LOOP: Similar processing for enemy animation frames
;      - If end marker, call enemy_ai_decide to get next animation
;      - Apply velocity, clamp to boundaries
;      - Write sprite data to buffer
;   7. Finalize: write end marker, compute total buffer size
;
; Input: none (reads global state)
; Output: updates player/enemy positions, animation buffers, camera
; Clobbers: AX, BX, CX, DX, SI, DI
scene_update:
	mov	byte [0xbb30],0x0	; 022E1  ; reset player sprite command
	mov	word [0xbb31],0x0	; 022E6  ; reset player animation counter
	mov	ax,[0xbcd5]		; 022EC
	db	0x05, 0x03, 0x00	; 022EF add ax,0x3
	db	0x25, 0xFC, 0xFF	; 022F2 and ax,0xfffc  ; align to 4-pixel boundary
	mov	[0xbcd5],ax		; 022F5
	mov	ax,[0x10e]		; 022F8
	db	0x05, 0x03, 0x00	; 022FB add ax,0x3
	db	0x25, 0xFC, 0xFF	; 022FE and ax,0xfffc  ; align to 4-pixel boundary
	mov	[0x10e],ax		; 02301
	push	word [0xc3a2]		; 02304
	push	word [0xc3a0]		; 02308
	lea	ax,[0xbb33]		; 0230C
	push	ax			; 02310
	call	memcpy_block		; 02311
	add	sp,0x6			; 02314
	mov	[0xd5a4],ax		; 02317
	cmp	word [0xf8],0x1		; 0231A  ; if combat_active > 1, skip animation
	jng	short loc_02324		; 0231F jng 0x2324
	jmp	0x2661			; 02321
loc_02324:
	mov	bx,[0xc3d2]		; 02324
loc_02328:
	cmp	byte [bx+0xc428],0xff	; 02328  ; check end-of-sequence marker
	jnz	short loc_0235C		; 0232D jnz 0x235c
	cmp	word [0x156],0x0	; 0232F
	jz	short loc_0233B		; 02334 jz 0x233b
	call	anim_process		; 02336
	jmp	short loc_0233E		; 02339 jmp 0x233e
loc_0233B:
	call	player_anim_select	; 0233B
loc_0233E:
	db	0x3D, 0x2A, 0x00	; 0233E cmp ax,0x2a
	jc	short loc_02345		; 02341 jc 0x2345
	db	0x33, 0xC0		; 02343 xor ax,ax
loc_02345:
	shl	ax,1			; 02345
	db	0x8B, 0xD8		; 02347 mov bx,ax
	mov	ax,[bx+0xc3d4]		; 02349
	mov	[0xc3d2],ax		; 0234D
	db	0x8B, 0xD8		; 02350 mov bx,ax
	cmp	word [0xf8],0x1		; 02352
	jng	short loc_02328		; 02357 jng 0x2328
	jmp	0x2661			; 02359
loc_0235C:
	mov	si,[0xc3d2]		; 0235C
	mov	ah,0x0			; 02360
	mov	al,[si+0xc429]		; 02362
	mov	[0x10c],ax		; 02366
	mov	al,[si+0xc42a]		; 02369
	db	0x8A, 0xC8		; 0236D mov cl,al
	and	al,0x1			; 0236F
	shr	cl,1			; 02371
	mov	[0xd5ae],cl		; 02373
	mov	[0xec],ax		; 02377
	mov	cx,[0xbcd5]		; 0237A
	cmp	word [0x11a],0x0	; 0237E
	jnz	short loc_023AE		; 02383 jnz 0x23ae
	mov	al,[si+0xc42c]		; 02385
	cbw				; 02389
	add	[0xbcd5],ax		; 0238A
	mov	cx,[0xbcd5]		; 0238E
	cmp	cx,[0x102]		; 02392
	jg	short loc_023A0		; 02396 jg 0x23a0
	mov	cx,[0x102]		; 02398
	mov	[0xbcd5],cx		; 0239C
loc_023A0:
	cmp	cx,[0x104]		; 023A0
	jl	short loc_023AE		; 023A4 jl 0x23ae
	mov	cx,[0x104]		; 023A6
	mov	[0xbcd5],cx		; 023AA
loc_023AE:
	cmp	word [0xfa],0x0		; 023AE
	jg	short loc_023F2		; 023B3 jg 0x23f2
	add	cx,0x8			; 023B5
	cmp	word [0xd5aa],0x0	; 023B8
	jz	short loc_023C2		; 023BD jz 0x23c2
	sub	cx,0x4			; 023BF
loc_023C2:
	cmp	word [0x10c],0xb	; 023C2
	jnz	short loc_023E2		; 023C7 jnz 0x23e2
	push	cx			; 023C9
	sub	cx,[0x10e]		; 023CA
	cmp	cx,0xfffffffffffffff0	; 023CE
	pop	cx			; 023D1
	jl	short loc_023F2		; 023D2 jl 0x23f2
	mov	word [0x10c],0x0	; 023D4
	mov	dx,[0xc3d4]		; 023DA
	mov	[0xc3d2],dx		; 023DE
loc_023E2:
	cmp	cx,[0x10e]		; 023E2
	jng	short loc_023F2		; 023E6 jng 0x23f2
	sub	cx,[0x10e]		; 023E8
	sub	[0xbcd5],cx		; 023EC
	db	0x2B, 0xC1		; 023F0 sub ax,cx
loc_023F2:
	cmp	word [0x11a],0x0	; 023F2
	jz	short loc_02407		; 023F7 jz 0x2407
	mov	cx,[0x10e]		; 023F9
	sub	cx,0xaa			; 023FD
	mov	[0xe4],cx		; 02401
	jmp	short loc_02413		; 02405 jmp 0x2413
loc_02407:
	mov	cx,[0xbcd5]		; 02407
	sub	cx,0x96			; 0240B
	mov	[0xe4],cx		; 0240F
loc_02413:
	cmp	cx,[0x108]		; 02413
	jg	short loc_02421		; 02417 jg 0x2421
	mov	cx,[0x108]		; 02419
	mov	[0xe4],cx		; 0241D
loc_02421:
	cmp	cx,[0x10a]		; 02421
	jl	short loc_0242F		; 02425 jl 0x242f
	mov	cx,[0x10a]		; 02427
	mov	[0xe4],cx		; 0242B
loc_0242F:
	cmp	word [0x11a],0x0	; 0242F
	jnz	short loc_0243D		; 02434 jnz 0x243d
	mov	al,[si+0xc42e]		; 02436
	mov	[0xbb30],al		; 0243A
loc_0243D:
	push	word [0xbcd5]		; 0243D
	lea	ax,[0xc42f]		; 02441
	db	0x03, 0xC6		; 02445 add ax,si
	push	ax			; 02447
	lea	ax,[0xbb33]		; 02448
	add	ax,[0xd5a4]		; 0244C
	push	ax			; 02450
	call	copy_sprite_frame		; 02451
	add	sp,0x6			; 02454
	add	word [0xd5a4],0x8	; 02457
	add	word [0xc3d2],0x11	; 0245C  ; advance to next frame (17 bytes per entry)
	cmp	word [0xfa],0x1		; 02461
	jng	short loc_0246B		; 02466 jng 0x246b
	jmp	0x27cd			; 02468
loc_0246B:
	mov	si,[0xcde8]		; 0246B
	cmp	byte [si+0xce3e],0xff	; 0246F
	jnz	short loc_02491		; 02474 jnz 0x2491
	call	enemy_ai_decide		; 02476
	cmp	word [0xfa],0x1		; 02479
	jng	short loc_02483		; 0247E jng 0x2483
	jmp	0x27cd			; 02480
loc_02483:
	db	0x8B, 0xD8		; 02483 mov bx,ax
	shl	bx,1			; 02485
	mov	si,[bx+0xcdea]		; 02487
	mov	[0xcde8],si		; 0248B
	jmp	short loc_0246B		; 0248F jmp 0x246b
loc_02491:
	mov	ah,0x0			; 02491
	mov	al,[si+0xce3f]		; 02493
	mov	[0x110],ax		; 02497
	mov	al,[si+0xce40]		; 0249A
	db	0x8A, 0xC8		; 0249E mov cl,al
	shr	cl,1			; 024A0
	mov	[0xd5b0],cl		; 024A2
	and	al,0x1			; 024A6
	mov	[0x112],ax		; 024A8
	cmp	word [0x118],0x0	; 024AB
	jz	short loc_024B5		; 024B0 jz 0x24b5
	jmp	0x2738			; 024B2
loc_024B5:
	mov	al,[si+0xce42]		; 024B5
	cbw				; 024B9
	add	[0x10e],ax		; 024BA
	cmp	word [0x12e],0x0	; 024BE
	jnz	short loc_024DF		; 024C3 jnz 0x24df
	cmp	word [0xf0],0x0		; 024C5
	jnz	short loc_024DF		; 024CA jnz 0x24df
	cmp	word [0xd5aa],0x0	; 024CC
	jnz	short loc_024DF		; 024D1 jnz 0x24df
	mov	ax,[0x104]		; 024D3
	cmp	ax,[0x10e]		; 024D6
	jnl	short loc_024DF		; 024DA jnl 0x24df
	mov	[0x10e],ax		; 024DC
loc_024DF:
	cmp	word [0xfa],0x0		; 024DF
	jg	short loc_02521		; 024E4 jg 0x2521
	mov	ax,[0xbcd5]		; 024E6
	db	0x05, 0x08, 0x00	; 024E9 add ax,0x8
	cmp	word [0xd5aa],0x0	; 024EC
	jz	short loc_024F8		; 024F1 jz 0x24f8
	db	0x2D, 0x04, 0x00	; 024F3 sub ax,0x4
	jmp	short loc_02518		; 024F6 jmp 0x2518
loc_024F8:
	cmp	word [0x110],0xa	; 024F8
	jnz	short loc_02518		; 024FD jnz 0x2518
	mov	dx,[0x10e]		; 024FF
	db	0x2B, 0xD0		; 02503 sub dx,ax
	cmp	dx,0x10			; 02505
	jg	short loc_02521		; 02508 jg 0x2521
	mov	word [0x110],0x0	; 0250A
	mov	dx,[0xcdea]		; 02510
	mov	[0xcde8],dx		; 02514
loc_02518:
	cmp	[0x10e],ax		; 02518
	jnl	short loc_02521		; 0251C jnl 0x2521
	mov	[0x10e],ax		; 0251E
loc_02521:
	mov	ax,[0x100]		; 02521
	cmp	[0x10e],ax		; 02524
	jnl	short loc_0252D		; 02528 jnl 0x252d
	mov	[0x10e],ax		; 0252A
loc_0252D:
	mov	al,[si+0xce44]		; 0252D
	cmp	al,0x0			; 02531
	jz	short loc_02538		; 02533 jz 0x2538
	mov	[0xbb30],al		; 02535
loc_02538:
	mov	di,[0xd5a4]		; 02538
	mov	al,[si+0xce46]		; 0253C
	mov	[di+0xbb33],al		; 02540
	mov	ax,[si+0xce47]		; 02544
	cmp	word [0xf2],0x0		; 02548
	jz	short loc_02552		; 0254D jz 0x2552
	db	0x05, 0x04, 0x00	; 0254F add ax,0x4
loc_02552:
	cmp	word [0xd5aa],0x0	; 02552
	jz	short loc_0255C		; 02557 jz 0x255c
	db	0x05, 0x0C, 0x00	; 02559 add ax,0xc
loc_0255C:
	add	ax,[0x10e]		; 0255C
	cmp	word [0xf2],0x0		; 02560
	jnz	short loc_02571		; 02565 jnz 0x2571
	cmp	word [0xd5aa],0x0	; 02567
	jnz	short loc_02571		; 0256C jnz 0x2571
	or	ax,0x4000		; 0256E  ; set flip bit (mirror sprite horizontally)
loc_02571:
	mov	[di+0xbb34],ax		; 02571
	mov	al,[si+0xce49]		; 02575
	cmp	word [0xd5aa],0x0	; 02579
	jz	short loc_02584		; 0257E jz 0x2584
	add	al,[0xd5ac]		; 02580
loc_02584:
	mov	[di+0xbb36],al		; 02584
	mov	al,[si+0xce4b]		; 02588
	cmp	word [0xd5aa],0x0	; 0258C
	jnz	short loc_02597		; 02591 jnz 0x2597
	add	al,[0x158]		; 02593
loc_02597:
	mov	[di+0xbb37],al		; 02597
	mov	ax,[si+0xce4c]		; 0259B
	cmp	word [0xf2],0x0		; 0259F
	jz	short loc_025A9		; 025A4 jz 0x25a9
	db	0x05, 0x04, 0x00	; 025A6 add ax,0x4
loc_025A9:
	cmp	word [0xd5aa],0x0	; 025A9
	jz	short loc_025B3		; 025AE jz 0x25b3
	db	0x05, 0x0C, 0x00	; 025B0 add ax,0xc
loc_025B3:
	add	ax,[0x10e]		; 025B3
	mov	[di+0xbb38],ax		; 025B7
	mov	al,[si+0xce4e]		; 025BB
	mov	[di+0xbb3a],al		; 025BF
	add	word [0xd5a4],0x8	; 025C3
	add	word [0xcde8],0x11	; 025C8  ; advance enemy frame pointer
	push	word [0xc3a4]		; 025CD
	push	word [0xc3a2]		; 025D1
	mov	ax,[0xd5a4]		; 025D5
	db	0x05, 0x03, 0x00	; 025D8 add ax,0x3
	mov	[0xd5b2],ax		; 025DB
	lea	ax,[0xbb33]		; 025DE
	add	ax,[0xd5a4]		; 025E2
	push	ax			; 025E6
	mov	[0xd5a8],ax		; 025E7
	call	memcpy_block		; 025EA
	add	sp,0x6			; 025ED
	add	[0xd5a4],ax		; 025F0
	mov	si,[0xd5a4]		; 025F4
	mov	byte [si+0xbb33],0xff	; 025F8  ; write end marker to animation buffer
	add	si,0x3			; 025FD
	mov	[0xbb2e],si		; 02600
	ret				; 02604

; ---- function enemy_ai_decide ----
; Enemy AI decision function — selects the next animation/action for the enemy.
; Despite its old name "math_random", this is the core enemy AI.
;
; Returns an animation table index in AX. Key return values:
;   0x00 = idle/stand          0x01 = advance/walk
;   0x02 = close advance       0x05 = retreat step
;   0x07 = attack (far)        0x08 = kick
;   0x09 = strong attack       0x0B = charge
;   0x0C = kick (far)          0x0D = counter-attack
;   0x0E = flee/run away       0x0F = block
;   0x13 = special attack      0x1B = recoil from hit
;   0x1E = approach walk       0x1F = walk (slow)
;   0x20 = stand               0x21 = transition stand
;
; Decision tree:
;   1. If enemy anim is 0x46 (death): return 0x0E (flee) if scene locked, 0 if frozen
;   2. Compute distance = enemy_x - player_x -> [bp+6]
;   3. If anim 0x1C: set combat counters
;   4. If game_mode == 1: special logic (return 0 if anim 2, advance/retreat based on distance)
;   5. If combat_phase == 1 (approach): return 0x1E
;   6. If enemy_active (enemy present):
;      a. If enemy anim 0x22: enemy defeated — set retreat, calculate health regen
;      b. If enemy_was_hit: clear flag, return 0x20 (stand)
;      c. Walking logic (anim 0x1F/0x21)
;      d. Level 3 boss: special teleport/retreat at distance > 300
;      e. Distance > 240: teleport enemy to 1920, set approach
;      f. Combat active: return special attacks (0x13, 0x09)
;      g. Enemy was hit in combat: knockback + recoil
;      h. Aggressive mode: attack decision via probability tables
;   7. Not aggressive: distance-based logic, set aggressive when close
;
; Input: none (reads global state)
; Output: AX = animation table index
; Local: [bp+6] = distance between enemy and player
enemy_ai_decide:
	push	bp			; 02605
	sub	sp,0xc			; 02606
	jc	short loc_02611		; 02609 jc 0x2611
	cmp	sp,[0x17]		; 0260B
	ja	short loc_02614		; 0260F ja 0x2614
loc_02611:
	jmp	0x420			; 02611
loc_02614:
	db	0x8B, 0xEC		; 02614 mov bp,sp
	cmp	word [0x110],0x46	; 02616  ; enemy anim 0x46 = death animation
	jnz	short loc_0263A		; 0261B jnz 0x263a
	cmp	word [0x11a],0x0	; 0261D
	jng	short loc_0262C		; 02622 jng 0x262c
	mov	ax,0xe			; 02624
	add	sp,0xc			; 02627
	pop	bp			; 0262A
	ret				; 0262B
loc_0262C:
	cmp	word [0x118],0x0	; 0262C
	jng	short loc_0263A		; 02631 jng 0x263a
	db	0x33, 0xC0		; 02633 xor ax,ax
	add	sp,0xc			; 02635
	pop	bp			; 02638
	ret				; 02639
loc_0263A:
	mov	ax,[0x10e]		; 0263A
	sub	ax,[0xbcd5]		; 0263D
	cmp	word [0x110],0x1c	; 02641
	mov	[bp+0x6],ax		; 02646
	jnz	short loc_02654		; 02649 jnz 0x2654
	mov	ax,0x1			; 0264B
	mov	[0x16e],ax		; 0264E
	mov	[0x16c],ax		; 02651
loc_02654:
	cmp	word [0xf0],0x1		; 02654
	jnz	short loc_0269B		; 02659 jnz 0x269b
	cmp	word [0x110],0x2	; 0265B
	jnz	short loc_02669		; 02660 jnz 0x2669
	db	0x33, 0xC0		; 02662 xor ax,ax
	add	sp,0xc			; 02664
	pop	bp			; 02667
	ret				; 02668
loc_02669:
	cmp	word [0x10c],0x3f	; 02669
	jng	short loc_0267F		; 0266E jng 0x267f
	cmp	word [0xf8],0x0		; 02670
	jnz	short loc_0267F		; 02675 jnz 0x267f
	mov	ax,0x1			; 02677
	add	sp,0xc			; 0267A
	pop	bp			; 0267D
	ret				; 0267E
loc_0267F:
	cmp	word [bp+0x6],0x38	; 0267F
	jnl	short loc_02694		; 02683 jnl 0x2694
	cmp	word [0xf8],0x0		; 02685
	jnz	short loc_02694		; 0268A jnz 0x2694
	mov	ax,0x2			; 0268C
	add	sp,0xc			; 0268F
	pop	bp			; 02692
	ret				; 02693
loc_02694:
	db	0x33, 0xC0		; 02694 xor ax,ax
	add	sp,0xc			; 02696
	pop	bp			; 02699
	ret				; 0269A
loc_0269B:
	cmp	word [0xfa],0x1		; 0269B
	jnz	short loc_026AA		; 026A0 jnz 0x26aa
	mov	ax,0x1e			; 026A2
	add	sp,0xc			; 026A5
	pop	bp			; 026A8
	ret				; 026A9
loc_026AA:
	cmp	word [0xd5aa],0x1	; 026AA
	jz	short loc_026B4		; 026AF jz 0x26b4
	jmp	0x29b3			; 026B1
loc_026B4:
	cmp	word [0x110],0x22	; 026B4  ; enemy anim 0x22 = defeated/fallen
	jnz	short loc_02701		; 026B9 jnz 0x2701
	db	0x33, 0xC0		; 026BB xor ax,ax
	mov	word [0xfa],0x2		; 026BD  ; set combat_phase = retreat
	mov	bx,0xffff		; 026C3
	mov	word [0xd64c],0x1	; 026C6  ; set enemy_defeated flag
	cmp	word [0x116],0x9	; 026CC
	mov	[0xd5aa],ax		; 026D1
	mov	[0xd652],bx		; 026D4
	mov	[0xbb2a],bx		; 026D8
	jng	short loc_026E9		; 026DC jng 0x26e9
	mov	word [0x116],0x9	; 026DE
	mov	[0x124],ax		; 026E4
	jmp	short loc_026FA		; 026E7 jmp 0x26fa
loc_026E9:
	mov	ax,[0x116]		; 026E9
	db	0x3D, 0x09, 0x00	; 026EC cmp ax,0x9
	jnl	short loc_026FA		; 026EF jnl 0x26fa
	mov	bx,0x9			; 026F1
	db	0x2B, 0xD8		; 026F4 sub bx,ax
	mov	[0x124],bx		; 026F6
loc_026FA:
	db	0x33, 0xC0		; 026FA xor ax,ax
	add	sp,0xc			; 026FC
	pop	bp			; 026FF
	ret				; 02700
loc_02701:
	cmp	word [0xfe],0x1		; 02701
	jnz	short loc_02716		; 02706 jnz 0x2716
	mov	word [0xfe],0x0		; 02708
	mov	ax,0x20			; 0270E
	add	sp,0xc			; 02711
	pop	bp			; 02714
	ret				; 02715
loc_02716:
	cmp	word [0x110],0x1f	; 02716
	jnz	short loc_02733		; 0271B jnz 0x2733
	cmp	word [bp+0x6],0xc	; 0271D
	jng	short loc_0272B		; 02721 jng 0x272b
	mov	ax,0x1f			; 02723
	add	sp,0xc			; 02726
	pop	bp			; 02729
	ret				; 0272A
loc_0272B:
	mov	ax,0x21			; 0272B
	add	sp,0xc			; 0272E
	pop	bp			; 02731
	ret				; 02732
loc_02733:
	cmp	word [0x110],0x21	; 02733
	jnz	short loc_02742		; 02738 jnz 0x2742
	mov	ax,0x20			; 0273A
	add	sp,0xc			; 0273D
	pop	bp			; 02740
	ret				; 02741
loc_02742:
	cmp	word [0xea],0x3		; 02742  ; level 3 (final boss)
	jnz	short loc_02789		; 02747 jnz 0x2789
	cmp	word [0x10e],0x12c	; 02749
	jng	short loc_02781		; 0274F jng 0x2781
	cmp	word [0xf8],0x0		; 02751
	jng	short loc_02768		; 02756 jng 0x2768
	db	0x33, 0xC0		; 02758 xor ax,ax
	mov	word [0xfa],0x2		; 0275A
	mov	[0xd5aa],ax		; 02760
	add	sp,0xc			; 02763
	pop	bp			; 02766
	ret				; 02767
loc_02768:
	mov	ax,0x2			; 02768
	push	ax			; 0276B
	call	rand_range		; 0276C
	db	0x8B, 0xE5		; 0276F mov sp,bp
	mov	bx,0xc			; 02771
	imul	bx			; 02774
	mov	[0xd5ac],ax		; 02776
	mov	ax,0x1f			; 02779
	add	sp,0xc			; 0277C
	pop	bp			; 0277F
	ret				; 02780
loc_02781:
	mov	ax,0x20			; 02781
	add	sp,0xc			; 02784
	pop	bp			; 02787
	ret				; 02788
loc_02789:
	mov	ax,[0x10e]		; 02789
	sub	ax,[0xbcd5]		; 0278C
	cmp	ax,0xf0			; 02790
	jnl	short loc_0279D		; 02793 jnl 0x279d
	mov	ax,0x20			; 02795
	add	sp,0xc			; 02798
	pop	bp			; 0279B
	ret				; 0279C
loc_0279D:
	mov	word [0x10e],0x780	; 0279D  ; teleport enemy to X=1920 (offscreen right)
	db	0x33, 0xC0		; 027A3 xor ax,ax
	mov	word [0xfa],0x1		; 027A5
	mov	[0xd5aa],ax		; 027AB
	add	sp,0xc			; 027AE
	pop	bp			; 027B1
	ret				; 027B2
	cmp	word [0xf8],0x0		; 027B3
	jng	short loc_027E0		; 027B8 jng 0x27e0
	cmp	word [0x110],0x41	; 027BA
	jnz	short loc_027C9		; 027BF jnz 0x27c9
	mov	ax,0x13			; 027C1
	add	sp,0xc			; 027C4
	pop	bp			; 027C7
	ret				; 027C8
loc_027C9:
	cmp	word [0x110],0x40	; 027C9
	jnz	short loc_027D8		; 027CE jnz 0x27d8
	mov	ax,0x13			; 027D0
	add	sp,0xc			; 027D3
	pop	bp			; 027D6
	ret				; 027D7
loc_027D8:
	mov	ax,0x9			; 027D8
	add	sp,0xc			; 027DB
	pop	bp			; 027DE
	ret				; 027DF
loc_027E0:
	cmp	word [0xfe],0x1		; 027E0
	jnz	short loc_0280E		; 027E5 jnz 0x280e
	mov	word [0xfe],0x0		; 027E7
	add	word [0x10e],0x8	; 027ED
	mov	ax,[0x110]		; 027F2
	db	0x3D, 0x04, 0x00	; 027F5 cmp ax,0x4
	jng	short loc_02807		; 027F8 jng 0x2807
	db	0x3D, 0x08, 0x00	; 027FA cmp ax,0x8
	jnl	short loc_02807		; 027FD jnl 0x2807
	mov	ax,0x1b			; 027FF
	add	sp,0xc			; 02802
	pop	bp			; 02805
	ret				; 02806
loc_02807:
	db	0x33, 0xC0		; 02807 xor ax,ax
	add	sp,0xc			; 02809
	pop	bp			; 0280C
	ret				; 0280D
loc_0280E:
	cmp	word [0xf6],0x1		; 0280E
	jz	short loc_02818		; 02813 jz 0x2818
	jmp	0x2b17			; 02815
loc_02818:
	cmp	word [0x10c],0x3f	; 02818
	jng	short loc_0283A		; 0281D jng 0x283a
	cmp	word [bp+0x6],0x30	; 0281F
	jnl	short loc_0282D		; 02823 jnl 0x282d
	mov	ax,0x5			; 02825
	add	sp,0xc			; 02828
	pop	bp			; 0282B
	ret				; 0282C
loc_0282D:
	push	word [bp+0x6]		; 0282D
	call	combat_pick_far_attack	; 02830
	db	0x8B, 0xE5		; 02833 mov sp,bp
	add	sp,0xc			; 02835
	pop	bp			; 02838
	ret				; 02839
loc_0283A:
	cmp	word [0x110],0xb	; 0283A
	jnz	short loc_02848		; 0283F jnz 0x2848
	db	0x33, 0xC0		; 02841 xor ax,ax
	add	sp,0xc			; 02843
	pop	bp			; 02846
	ret				; 02847
loc_02848:
	cmp	word [bp+0x6],0x2c	; 02848
	jng	short loc_0285B		; 0284C jng 0x285b
	push	word [bp+0x6]		; 0284E
	call	combat_pick_far_attack	; 02851
	db	0x8B, 0xE5		; 02854 mov sp,bp
	add	sp,0xc			; 02856
	pop	bp			; 02859
	ret				; 0285A
loc_0285B:
	mov	ax,0xff			; 0285B
	push	ax			; 0285E
	call	rand_range		; 0285F
	db	0x8B, 0xE5		; 02862 mov sp,bp
	cmp	word [bp+0x6],0x1c	; 02864
	mov	[bp+0xa],ax		; 02868
	jnl	short loc_02872		; 0286B jnl 0x2872
	mov	word [bp+0x6],0x1c	; 0286D
loc_02872:
	mov	ax,[0xea]		; 02872
	mov	bx,0xa			; 02875
	imul	bx			; 02878
	db	0x8B, 0xF0		; 0287A mov si,ax
	mov	ax,[bp+0x6]		; 0287C
	db	0x2D, 0x1C, 0x00	; 0287F sub ax,0x1c
	mov	bx,0x4			; 02882
	cwd				; 02885
	idiv	bx			; 02886
	shl	ax,1			; 02888
	db	0x03, 0xF0		; 0288A add si,ax
	mov	ax,[bp+0xa]		; 0288C
	cmp	ax,[si+0xd5b4]		; 0288F
	jl	short loc_0289C		; 02893 jl 0x289c
	db	0x33, 0xC0		; 02895 xor ax,ax
	add	sp,0xc			; 02897
	pop	bp			; 0289A
	ret				; 0289B
loc_0289C:
	mov	ax,[0xea]		; 0289C
	mov	bx,0xa			; 0289F
	imul	bx			; 028A2
	db	0x8B, 0xF0		; 028A4 mov si,ax
	mov	ax,[bp+0x6]		; 028A6
	db	0x2D, 0x1C, 0x00	; 028A9 sub ax,0x1c
	mov	bx,0x4			; 028AC
	cwd				; 028AF
	idiv	bx			; 028B0
	shl	ax,1			; 028B2
	db	0x03, 0xF0		; 028B4 add si,ax
	mov	ax,[bp+0xa]		; 028B6
	cmp	ax,[si+0xd5e6]		; 028B9
	jl	short loc_028DF		; 028BD jl 0x28df
	mov	ax,[0x110]		; 028BF
	db	0x3D, 0x08, 0x00	; 028C2 cmp ax,0x8
	jnl	short loc_028D7		; 028C5 jnl 0x28d7
	db	0x3D, 0x04, 0x00	; 028C7 cmp ax,0x4
	jng	short loc_028D7		; 028CA jng 0x28d7
	call	anim_interpolate	; 028CC
	db	0x05, 0x14, 0x00	; 028CF add ax,0x14
	add	sp,0xc			; 028D2
	pop	bp			; 028D5
	ret				; 028D6
loc_028D7:
	call	anim_interpolate	; 028D7
	add	sp,0xc			; 028DA
	pop	bp			; 028DD
	ret				; 028DE
loc_028DF:
	mov	ax,[0xea]		; 028DF
	mov	bx,0xa			; 028E2
	imul	bx			; 028E5
	db	0x8B, 0xF0		; 028E7 mov si,ax
	mov	ax,[bp+0x6]		; 028E9
	db	0x2D, 0x1C, 0x00	; 028EC sub ax,0x1c
	mov	bx,0x4			; 028EF
	cwd				; 028F2
	idiv	bx			; 028F3
	shl	ax,1			; 028F5
	db	0x03, 0xF0		; 028F7 add si,ax
	mov	ax,[bp+0xa]		; 028F9
	cmp	ax,[si+0xd618]		; 028FC
	jl	short loc_0290A		; 02900 jl 0x290a
	call	anim_frame_update	; 02902
	add	sp,0xc			; 02905
	pop	bp			; 02908
	ret				; 02909
loc_0290A:
	push	word [bp+0x6]		; 0290A
	call	combat_pick_far_attack	; 0290D
	db	0x8B, 0xE5		; 02910 mov sp,bp
	add	sp,0xc			; 02912
	pop	bp			; 02915
	ret				; 02916
	cmp	word [bp+0x6],0x6e	; 02917
	jng	short loc_02934		; 0291B jng 0x2934
	cmp	word [0x10c],0x42	; 0291D
	jnz	short loc_0292C		; 02922 jnz 0x292c
	mov	ax,0xb			; 02924
	add	sp,0xc			; 02927
	pop	bp			; 0292A
	ret				; 0292B
loc_0292C:
	mov	ax,0x13			; 0292C
	add	sp,0xc			; 0292F
	pop	bp			; 02932
	ret				; 02933
loc_02934:
	mov	word [0xf6],0x1		; 02934
	db	0x33, 0xC0		; 0293A xor ax,ax
	add	sp,0xc			; 0293C
	pop	bp			; 0293F
	ret				; 02940

; ---- function combat_pick_far_attack ----
; Selects an attack animation when enemy is far from player.
; Uses random probability check against enemy_atk_freq.
;
; Input: [bp+0xa] = distance between enemy and player
; Output: AX = animation index (0=idle, 7=attack, 0xC=kick, 0xE=flee)
;
; Logic:
;   - Distance > 300: return 0x0E (flee)
;   - Distance > 75: threshold = enemy_atk_freq
;   - Distance <= 75: threshold = enemy_atk_freq * 3/4
;   - Random(255) > threshold -> return 0 (no attack)
;   - Level 0 boundary checks: don't attack near edges
;   - If enemy anim is 7 or 0xA and distance > 28: return 0x0C (kick)
;   - Default: return 0x07 (standard attack)
combat_pick_far_attack:
	push	bp			; 02941
	sub	sp,0x6			; 02942
	jc	short loc_0294D		; 02945 jc 0x294d
	cmp	sp,[0x17]		; 02947
	ja	short loc_02950		; 0294B ja 0x2950
loc_0294D:
	jmp	0x420			; 0294D
loc_02950:
	db	0x8B, 0xEC		; 02950 mov bp,sp
	cmp	word [bp+0xa],0x12c	; 02952
	jng	short loc_02961		; 02957 jng 0x2961
	mov	ax,0xe			; 02959
	add	sp,0x6			; 0295C
	pop	bp			; 0295F
	ret				; 02960
loc_02961:
	cmp	word [bp+0xa],0x4b	; 02961
	jng	short loc_0296F		; 02965 jng 0x296f
	mov	ax,[0xf4]		; 02967
	mov	[bp+0x4],ax		; 0296A
	jmp	short loc_02980		; 0296D jmp 0x2980
loc_0296F:
	mov	ax,[0xf4]		; 0296F
	mov	bx,0x3			; 02972
	imul	bx			; 02975
	mov	bx,0x4			; 02977
	cwd				; 0297A
	idiv	bx			; 0297B
	mov	[bp+0x4],ax		; 0297D
loc_02980:
	mov	ax,0xff			; 02980
	push	ax			; 02983
	call	rand_range		; 02984
	db	0x8B, 0xE5		; 02987 mov sp,bp
	cmp	ax,[bp+0x4]		; 02989
	jng	short loc_02995		; 0298C jng 0x2995
	db	0x33, 0xC0		; 0298E xor ax,ax
	add	sp,0x6			; 02990
	pop	bp			; 02993
	ret				; 02994
loc_02995:
	cmp	word [0xea],0x0		; 02995
	jnz	short loc_029B1		; 0299A jnz 0x29b1
	mov	ax,[0x102]		; 0299C
	db	0x05, 0x0F, 0x00	; 0299F add ax,0xf
	mov	bx,[0x10e]		; 029A2
	db	0x3B, 0xD8		; 029A6 cmp bx,ax
	jnl	short loc_029B1		; 029A8 jnl 0x29b1
	db	0x33, 0xC0		; 029AA xor ax,ax
	add	sp,0x6			; 029AC
	pop	bp			; 029AF
	ret				; 029B0
loc_029B1:
	mov	ax,[0x102]		; 029B1
	db	0x05, 0x05, 0x00	; 029B4 add ax,0x5
	mov	bx,[0x10e]		; 029B7
	db	0x3B, 0xD8		; 029BB cmp bx,ax
	jnl	short loc_029C6		; 029BD jnl 0x29c6
	db	0x33, 0xC0		; 029BF xor ax,ax
	add	sp,0x6			; 029C1
	pop	bp			; 029C4
	ret				; 029C5
loc_029C6:
	mov	ax,[0x110]		; 029C6
	db	0x3D, 0x07, 0x00	; 029C9 cmp ax,0x7
	jz	short loc_029D3		; 029CC jz 0x29d3
	db	0x3D, 0x0A, 0x00	; 029CE cmp ax,0xa
	jnz	short loc_029E1		; 029D1 jnz 0x29e1
loc_029D3:
	cmp	word [bp+0xa],0x1c	; 029D3
	jng	short loc_029E1		; 029D7 jng 0x29e1
	mov	ax,0xc			; 029D9
	add	sp,0x6			; 029DC
	pop	bp			; 029DF
	ret				; 029E0
loc_029E1:
	mov	ax,0x7			; 029E1
	add	sp,0x6			; 029E4
	pop	bp			; 029E7
	ret				; 029E8

; ---- function anim_frame_update ----
; Returns a small random frame offset for animation variation.
; Input: none
; Output: AX = rand_range(2) + 2, i.e. random value in {2, 3, 4}
anim_frame_update:
	push	bp			; 029E9
	sub	sp,0x2			; 029EA
	jc	short loc_029F5		; 029ED jc 0x29f5
	cmp	sp,[0x17]		; 029EF
	ja	short loc_029F8		; 029F3 ja 0x29f8
loc_029F5:
	jmp	0x420			; 029F5
loc_029F8:
	db	0x8B, 0xEC		; 029F8 mov bp,sp
	mov	ax,0x2			; 029FA
	push	ax			; 029FD
	call	rand_range		; 029FE
	db	0x8B, 0xE5		; 02A01 mov sp,bp
	inc	ax			; 02A03
	inc	ax			; 02A04
	add	sp,0x2			; 02A05
	pop	bp			; 02A08
	ret				; 02A09
	push	bp			; 02A0A
	db	0x8B, 0xEC		; 02A0B mov bp,sp
	pop	bp			; 02A0D
	ret				; 02A0E

; ---- function anim_interpolate ----
; Returns a random interpolation offset for smooth animation transitions.
; Input: none
; Output: AX = rand_range(1 or 2) + 4
;   If player_faces_right: range [4, 5] (smoother)
;   Else: range [4, 5, 6]
anim_interpolate:
	push	bp			; 02A0F
	sub	sp,0x2			; 02A10
	jc	short loc_02A1B		; 02A13 jc 0x2a1b
	cmp	sp,[0x17]		; 02A15
	ja	short loc_02A1E		; 02A19 ja 0x2a1e
loc_02A1B:
	jmp	0x420			; 02A1B
loc_02A1E:
	db	0x8B, 0xEC		; 02A1E mov bp,sp
	cmp	word [0xf2],0x1		; 02A20
	jnz	short loc_02A38		; 02A25 jnz 0x2a38
	mov	ax,0x1			; 02A27
	push	ax			; 02A2A
	call	rand_range		; 02A2B
	db	0x8B, 0xE5		; 02A2E mov sp,bp
	db	0x05, 0x04, 0x00	; 02A30 add ax,0x4
	add	sp,0x2			; 02A33
	pop	bp			; 02A36
	ret				; 02A37
loc_02A38:
	mov	ax,0x2			; 02A38
	push	ax			; 02A3B
	call	rand_range		; 02A3C
	db	0x8B, 0xE5		; 02A3F mov sp,bp
	db	0x05, 0x04, 0x00	; 02A41 add ax,0x4
	add	sp,0x2			; 02A44
	pop	bp			; 02A47
	ret				; 02A48

; ---- function anim_process ----
; Player-side animation state machine — decides what player anim to use.
; Mirror of enemy_ai_decide but for the player character.
;
; Input: none (reads global state)
; Output: AX = animation table index for player
; Local: [bp+4] = distance (enemy_x - player_x)
;        [bp+8] = random value
;
; Logic:
;   - combat_active: return 0x1E (approach walk)
;   - If player anim 0x08 (kick): play sound, return 0x0F (block)
;   - If combat_phase == 1 and anim < 0x3F and enemy anim 0x43: random counter
;   - combat_phase == 1: return 0x0F
;   - player_was_hit: knockback 4px, recoil if mid-attack
;   - Distance > 44: call anim_command
;   - Distance <= 44: probability table lookup (3 tiers per level)
;     - Tier 1: idle
;     - Tier 2: interpolate (mid-attack -> +0x14 offset)
;     - Tier 3: anim_frame_update
;     - Tier 4: combat_pick_far_attack (fallback)
anim_process:
	push	bp			; 02A49
	sub	sp,0xa			; 02A4A
	jc	short loc_02A55		; 02A4D jc 0x2a55
	cmp	sp,[0x17]		; 02A4F
	ja	short loc_02A58		; 02A53 ja 0x2a58
loc_02A55:
	jmp	0x420			; 02A55
loc_02A58:
	db	0x8B, 0xEC		; 02A58 mov bp,sp
	cmp	word [0xf8],0x1		; 02A5A
	jnz	short loc_02A69		; 02A5F jnz 0x2a69
	mov	ax,0x1e			; 02A61
	add	sp,0xa			; 02A64
	pop	bp			; 02A67
	ret				; 02A68
loc_02A69:
	mov	ax,[0x10e]		; 02A69
	sub	ax,[0xbcd5]		; 02A6C
	cmp	word [0x10c],0x8	; 02A70
	mov	[bp+0x4],ax		; 02A75
	jnz	short loc_02A8B		; 02A78 jnz 0x2a8b
	mov	ax,0xb			; 02A7A
	push	ax			; 02A7D
	call	wait_vsync		; 02A7E
	db	0x8B, 0xE5		; 02A81 mov sp,bp
	mov	ax,0xf			; 02A83
	add	sp,0xa			; 02A86
	pop	bp			; 02A89
	ret				; 02A8A
loc_02A8B:
	cmp	word [0xfa],0x1		; 02A8B
	jnz	short loc_02AB8		; 02A90 jnz 0x2ab8
	cmp	word [0x10c],0x3f	; 02A92
	jnl	short loc_02AB8		; 02A97 jnl 0x2ab8
	cmp	word [0x110],0x43	; 02A99
	jnz	short loc_02AB1		; 02A9E jnz 0x2ab1
	mov	ax,0x1			; 02AA0
	push	ax			; 02AA3
	call	rand_range		; 02AA4
	db	0x8B, 0xE5		; 02AA7 mov sp,bp
	db	0x05, 0x11, 0x00	; 02AA9 add ax,0x11
	add	sp,0xa			; 02AAC
	pop	bp			; 02AAF
	ret				; 02AB0
loc_02AB1:
	db	0x33, 0xC0		; 02AB1 xor ax,ax
	add	sp,0xa			; 02AB3
	pop	bp			; 02AB6
	ret				; 02AB7
loc_02AB8:
	cmp	word [0xfa],0x1		; 02AB8
	jnz	short loc_02AC7		; 02ABD jnz 0x2ac7
	mov	ax,0xf			; 02ABF
	add	sp,0xa			; 02AC2
	pop	bp			; 02AC5
	ret				; 02AC6
loc_02AC7:
	cmp	word [0xfc],0x1		; 02AC7
	jnz	short loc_02AF5		; 02ACC jnz 0x2af5
	mov	word [0xfc],0x0		; 02ACE
	sub	word [0xbcd5],0x4	; 02AD4
	mov	ax,[0x10c]		; 02AD9
	db	0x3D, 0x04, 0x00	; 02ADC cmp ax,0x4
	jng	short loc_02AEE		; 02ADF jng 0x2aee
	db	0x3D, 0x08, 0x00	; 02AE1 cmp ax,0x8
	jnl	short loc_02AEE		; 02AE4 jnl 0x2aee
	mov	ax,0x1b			; 02AE6
	add	sp,0xa			; 02AE9
	pop	bp			; 02AEC
	ret				; 02AED
loc_02AEE:
	db	0x33, 0xC0		; 02AEE xor ax,ax
	add	sp,0xa			; 02AF0
	pop	bp			; 02AF3
	ret				; 02AF4
loc_02AF5:
	cmp	word [bp+0x4],0x2c	; 02AF5
	jng	short loc_02B08		; 02AF9 jng 0x2b08
	push	word [bp+0x4]		; 02AFB
	call	anim_command		; 02AFE
	db	0x8B, 0xE5		; 02B01 mov sp,bp
	add	sp,0xa			; 02B03
	pop	bp			; 02B06
	ret				; 02B07
loc_02B08:
	mov	ax,0xff			; 02B08
	push	ax			; 02B0B
	call	rand_range		; 02B0C
	db	0x8B, 0xE5		; 02B0F mov sp,bp
	cmp	word [bp+0x4],0x1c	; 02B11
	mov	[bp+0x8],ax		; 02B15
	jnl	short loc_02B1F		; 02B18 jnl 0x2b1f
	mov	word [bp+0x4],0x1c	; 02B1A
loc_02B1F:
	mov	ax,[bp+0x4]		; 02B1F
	db	0x2D, 0x1C, 0x00	; 02B22 sub ax,0x1c
	mov	bx,0x4			; 02B25
	cwd				; 02B28
	idiv	bx			; 02B29
	shl	ax,1			; 02B2B
	db	0x8B, 0xF0		; 02B2D mov si,ax
	mov	ax,[bp+0x8]		; 02B2F
	cmp	ax,[si+0xd5dc]		; 02B32
	jl	short loc_02B45		; 02B36 jl 0x2b45
	push	word [bp+0x4]		; 02B38
	call	anim_command		; 02B3B
	db	0x8B, 0xE5		; 02B3E mov sp,bp
	add	sp,0xa			; 02B40
	pop	bp			; 02B43
	ret				; 02B44
loc_02B45:
	mov	ax,[bp+0x4]		; 02B45
	db	0x2D, 0x1C, 0x00	; 02B48 sub ax,0x1c
	mov	bx,0x4			; 02B4B
	cwd				; 02B4E
	idiv	bx			; 02B4F
	shl	ax,1			; 02B51
	db	0x8B, 0xF0		; 02B53 mov si,ax
	mov	ax,[bp+0x8]		; 02B55
	cmp	ax,[si+0xd60e]		; 02B58
	jl	short loc_02B66		; 02B5C jl 0x2b66
	call	anim_interpolate	; 02B5E
	add	sp,0xa			; 02B61
	pop	bp			; 02B64
	ret				; 02B65
loc_02B66:
	mov	ax,[bp+0x4]		; 02B66
	db	0x2D, 0x1C, 0x00	; 02B69 sub ax,0x1c
	mov	bx,0x4			; 02B6C
	cwd				; 02B6F
	idiv	bx			; 02B70
	shl	ax,1			; 02B72
	db	0x8B, 0xF0		; 02B74 mov si,ax
	mov	ax,[bp+0x8]		; 02B76
	cmp	ax,[si+0xd640]		; 02B79
	jl	short loc_02B87		; 02B7D jl 0x2b87
	call	anim_frame_update	; 02B7F
	add	sp,0xa			; 02B82
	pop	bp			; 02B85
	ret				; 02B86
loc_02B87:
	push	word [bp+0x4]		; 02B87
	call	anim_command		; 02B8A
	db	0x8B, 0xE5		; 02B8D mov sp,bp
	add	sp,0xa			; 02B8F
	pop	bp			; 02B92
	ret				; 02B93

; ---- function anim_command ----
; Final attack/advance decision for player when close to enemy.
;
; Input: [bp+6] = distance between player and enemy
; Output: AX = animation index
;
; Logic:
;   - Random(255) > 50 and distance < 75: return 0 (hesitate)
;   - If player anim is 8 (kick) or 0xB (charge): return 0x0D (counter)
;   - Default: return 0x08 (kick)
anim_command:
	push	bp			; 02B94
	sub	sp,0x2			; 02B95
	jc	short loc_02BA0		; 02B98 jc 0x2ba0
	cmp	sp,[0x17]		; 02B9A
	ja	short loc_02BA3		; 02B9E ja 0x2ba3
loc_02BA0:
	jmp	0x420			; 02BA0
loc_02BA3:
	db	0x8B, 0xEC		; 02BA3 mov bp,sp
	mov	ax,0xff			; 02BA5
	push	ax			; 02BA8
	call	rand_range		; 02BA9
	db	0x8B, 0xE5		; 02BAC mov sp,bp
	db	0x3D, 0x32, 0x00	; 02BAE cmp ax,0x32
	jng	short loc_02BC0		; 02BB1 jng 0x2bc0
	cmp	word [bp+0x6],0x4b	; 02BB3
	jnl	short loc_02BC0		; 02BB7 jnl 0x2bc0
	db	0x33, 0xC0		; 02BB9 xor ax,ax
	add	sp,0x2			; 02BBB
	pop	bp			; 02BBE
	ret				; 02BBF
loc_02BC0:
	mov	ax,[0x10c]		; 02BC0
	db	0x3D, 0x08, 0x00	; 02BC3 cmp ax,0x8
	jz	short loc_02BCD		; 02BC6 jz 0x2bcd
	db	0x3D, 0x0B, 0x00	; 02BC8 cmp ax,0xb
	jnz	short loc_02BD5		; 02BCB jnz 0x2bd5
loc_02BCD:
	mov	ax,0xd			; 02BCD
	add	sp,0x2			; 02BD0
	pop	bp			; 02BD3
	ret				; 02BD4
loc_02BD5:
	mov	ax,0x8			; 02BD5
	add	sp,0x2			; 02BD8
	pop	bp			; 02BDB
	ret				; 02BDC
