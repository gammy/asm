     1                                  ; By gammy.
     2                                  ; Random number generator by unknown author - see random.inc.
     3                                  ;
     4                                  ; nasm -l faphex.asm -f bin -o fap.com fap.asm
     5                                  ; a work in progress.
     6                                  ; TODO: 
     7                                  ; - sub x by xstep (not dec) (solve it)
     8                                  
     9                                  [bits 16]
    10                                  
    11                                  org 0x100
    12                                  
    13 00000000 E83000                  call	init_stars
    14                                  
    15 00000003 B81300                  mov 	ax,     0x13
    16 00000006 CD10                    int 	0x10
    17                                  
    18 00000008 E80B00                  call    init_pal
    19                                  
    20                                  main_loop:
    21 0000000B E8CC00                  	call	kb_chk_esc
    22 0000000E E86C00                  	call	draw
    23 00000011 E8B800                  	call	wait_vblank
    24 00000014 EBF5                    	jmp	main_loop
    25                                  
    26                                  init_pal:
    27 00000016 31C0                    	xor	ax, ax
    28 00000018 BAC803                  	mov	dx, 0x3c8
    29 0000001B EE                      	out	dx, al
    30                                  pal_loop:
    31 0000001C BAC903                  	mov	dx, 0x3c9
    32 0000001F B000                    	mov	al, 0			; because I want blue.
    33 00000021 EE                      	out	dx, al
    34 00000022 EE                      	out	dx, al
    35 00000023 88E0                    	mov	al, ah
    36 00000025 C0E802                  	shr	al, 2
    37 00000028 EE                      	out	dx, al
    38 00000029 FEC4                    	inc	ah
    39 0000002B 88E0                    	mov	al, ah
    40 0000002D 80FCFF                  	cmp	ah, 255
    41 00000030 75EA                    	jne	pal_loop
    42 00000032 C3                      	ret
    43                                  
    44                                  init_stars:
    45 00000033 50                      	push	ax
    46 00000034 53                      	push	bx
    47 00000035 31C0                    	xor	ax, ax			; our counter. ZARRO.
    48                                  ; This is horrible.
    49                                  init_loop:
    50 00000037 BB[3F01]                	mov	bx, _x			; &x
    51 0000003A 01C3                    	add	bx, ax			; + offset
    52 0000003C 50                      	push	ax
    53 0000003D E8DF00                  	call	RANDOM
    54 00000040 30E4                    	xor	ah, ah
    55 00000042 052000                  	add	ax, 32			; hack ((320-256) >> 1) - centering.
    56 00000045 8907                    	mov	[bx], word ax
    57 00000047 58                      	pop	ax
    58                                  
    59 00000048 BB[3F03]                	mov	bx, _y			; &y
    60 0000004B 01C3                    	add	bx, ax			; + offset
    61 0000004D 50                      	push	ax
    62 0000004E E8CE00                  	call	RANDOM
    63 00000051 30E4                    	xor	ah, ah
    64 00000053 31D2                    	xor	dx, dx
    65 00000055 B9C800                  	mov	cx, 200			; screen height
    66 00000058 F7F1                    	div	cx			; dx = ax % cx
    67 0000005A 8917                    	mov	[bx], word dx
    68 0000005C 58                      	pop	ax
    69                                  
    70 0000005D BB[3F05]                	mov	bx, _xstep		; &xstep
    71 00000060 01C3                    	add	bx, ax			; + offset
    72 00000062 50                      	push	ax
    73 00000063 E8B900                  	call	RANDOM
    74 00000066 88C2                    	mov	dl, al
    75 00000068 8817                    	mov	[bx], byte dl
    76 0000006A 58                      	pop	ax
    77                                  	; Color is based on xstep (parallax)
    78 0000006B BB[3F07]                	mov	bx, _color		; &color
    79 0000006E 01C3                    	add	bx, ax			; + offset
    80 00000070 8817                    	mov	[bx], byte dl
    81                                  
    82                                  ; No vertical movement.
    83                                  ;	mov	bx, _ystep		; &ystep
    84                                  ;	add	bx, ax			; + offset
    85                                  ;	push	ax
    86                                  ;	call	RANDOM
    87                                  ;	mov	[bx], byte al
    88                                  ;	pop	ax
    89                                  
    90 00000072 050200                  	add	ax, 2
    91 00000075 3D0002                  	cmp	ax, _star_count  * 2 
    92 00000078 75BD                    	jne	init_loop
    93 0000007A 5B                      	pop	bx
    94 0000007B 58                      	pop	ax
    95 0000007C C3                      	ret
    96                                   
    97                                  draw:  
    98 0000007D 50                      	push	ax
    99 0000007E 53                      	push	bx
   100 0000007F 31C0                    	xor	ax, ax			; counter
   101                                  ; Also fucking horrible. 
   102                                  draw_clear:
   103 00000081 BB[3F01]                	mov	bx, _x
   104 00000084 01C3                    	add	bx, ax
   105 00000086 FF37                    	push	word [bx]		; x
   106                                  
   107 00000088 BB[3F03]                	mov	bx, _y
   108 0000008B 01C3                    	add	bx, ax
   109 0000008D FF37                    	push	word [bx]		; y
   110                                  
   111 0000008F 680000                  	push	word 0
   112 00000092 E85900                  	call	plot			; fucking clear it!
   113                                  draw_update:
   114                                  	; Update
   115 00000095 BB[3F01]                	mov	bx, _x
   116 00000098 B9[3F05]                	mov	cx, _xstep
   117 0000009B 01C3                    	add	bx, ax			; x offset
   118                                  	;add	cx, ax			; xstep offset
   119                                  	;sub	word [bx], cx
   120 0000009D FF0F                    	dec	word [bx]
   121 0000009F 813F1F00                	cmp	word [bx], 31		; hack
   122 000000A3 7F04                    	jg	draw_fill
   123 000000A5 81070001                	add	word [bx], 256
   124                                  draw_fill:
   125                                  	; Set
   126 000000A9 BB[3F01]                	mov	bx, _x
   127 000000AC 01C3                    	add	bx, ax
   128 000000AE FF37                    	push	word [bx]		; x
   129                                  
   130 000000B0 BB[3F03]                	mov	bx, _y
   131 000000B3 01C3                    	add	bx, ax
   132 000000B5 FF37                    	push	word [bx]		; y
   133                                  
   134 000000B7 BB[3F07]                	mov	bx, _color
   135 000000BA 01C3                    	add	bx, ax
   136 000000BC FF37                    	push	word [bx]		; color
   137                                  
   138 000000BE E82D00                  	call	plot			; fucking draw it!
   139                                  
   140 000000C1 050200                  	add	ax, 2
   141 000000C4 3D0002                  	cmp	ax, _star_count * 2
   142 000000C7 75B8                    	jne	draw_clear
   143 000000C9 5B                      	pop	bx
   144 000000CA 58                      	pop	ax
   145 000000CB C3                      	ret
   146                                  
   147                                  wait_vblank:
   148 000000CC BADA03                  	mov	dx, 0x3da		; vblank addr
   149                                  retrace_beg:
   150 000000CF EC                      	in	al, dx
   151 000000D0 A808                    	test	al, 8
   152 000000D2 75FB                    	jnz	retrace_beg
   153                                  retrace_end:
   154 000000D4 EC                      	in	al, dx
   155 000000D5 A808                    	test	al, 8
   156 000000D7 74FB                    	jz	retrace_end
   157 000000D9 C3                      	ret
   158                                  
   159                                  kb_chk_esc:
   160 000000DA 31C0                    	xor	ax, ax
   161 000000DC B401                    	mov	ah, 1			; get keystroke status
   162 000000DE CD16                    	int	0x16
   163 000000E0 740B                    	jz	kb_chk_end		; no key
   164 000000E2 B400                    	mov	ah, 0			; get key
   165 000000E4 CD16                    	int 	0x16
   166 000000E6 3C1B                    	cmp	al, 27			; is it esc?
   167 000000E8 7503                    	jne	kb_chk_end		; nope
   168 000000EA E82700                  	call	exit			; yup
   169                                  kb_chk_end:
   170 000000ED C3                      	ret
   171                                  
   172                                  plot:
   173 000000EE 55                      	push	bp			; store bp
   174 000000EF 89E5                    	mov	bp, sp
   175 000000F1 50                      	push	ax
   176                                  
   177                                  	; Setup vram write
   178 000000F2 BF00A0                  	mov	di, 0xa000		; stosb reads es:di, so..
   179 000000F5 8EC7                    	mov	es, di
   180 000000F7 31FF                    	xor	di, di
   181                                  
   182                                  	; Compute offset (i = y; i <<= 8; i += y << 6; i += x)
   183 000000F9 8B4606                  	mov     ax, [bp + 6]		; y
   184 000000FC 89C2                    	mov     dx, ax
   185 000000FE C1E008                  	shl     ax, 8			; y << 8 (256)
   186 00000101 C1E206                  	shl     dx, 6			; y << 6 (64) (256+64=320)
   187 00000104 01D0                    	add     ax, dx			; ax(y << 8) += dx(y << 6)
   188 00000106 034608                  	add     ax, [bp + 8]		; + x
   189                                  
   190                                  ;	mov	ax, 320			; width
   191                                  ;	mov	dx, [bp + 6]		; y
   192                                  ;	mul	dx; ax *= dx
   193                                  ;	add	ax, [bp + 8]		; + x
   194                                  
   195 00000109 89C7                    	mov	di, ax			; ready for stosb
   196 0000010B 8A4604                  	mov	al, [bp + 4]		; color
   197 0000010E AA                      	stosb				; al -> vram (fucking updated!)
   198                                  
   199 0000010F 58                      	pop	ax
   200 00000110 5D                      	pop	bp			; restore bp
   201 00000111 C20600                  	ret	2 * 3			; 2 bytes * 3 params
   202                                  
   203                                  exit:
   204 00000114 B80300                  	mov 	ax, 0x3
   205 00000117 CD10                    	int	0x10
   206                                  
   207                                  	; Terminate
   208 00000119 B44C                    	mov 	ah, 0x4c
   209 0000011B B000                    	mov 	al, 0
   210 0000011D CD21                    	int 	0x21
   211                                  
   212                                  %include 'random.inc'
   213                              <1> ; ========================= RANDOM.INC =========================
   214                              <1> ; 
   215                              <1> ; Call with,	NOTHING
   216                              <1> ; Returns,	AL = random number between 0-255,
   217                              <1> ;		AX may be a random number too ?
   218                              <1> ;		DW RNDNUM holds AX=random_number_in AL
   219                              <1> ; http://www.programmersheaven.com/mb/x86_asm/219366/219366/a-random-number-generator-routine/
   220                              <1> 
   221                              <1> RANDOM:
   222 0000011F 52                  <1> 	PUSH	DX
   223 00000120 A1[3B01]            <1> 	MOV	AX,[SEED]	;; AX = seed
   224 00000123 BA0584              <1> 	MOV	DX,8405h	;; DX = 8405h
   225 00000126 F7E2                <1> 	MUL	DX		;; MUL (8405h * SEED) into dword DX:AX
   226                              <1> 
   227 00000128 3B06[3B01]          <1> 	CMP	AX,[SEED]
   228 0000012C 7503                <1> 	JNZ	GOTSEED		;; if new SEED = old SEED, alter SEED
   229 0000012E 88D4                <1> 	MOV	AH,DL
   230 00000130 40                  <1> 	INC	AX
   231                              <1> GOTSEED:
   232 00000131 A3[3B01]            <1> 	MOV	WORD [SEED],AX	;; We have a new seed, so store it
   233 00000134 89D0                <1> 	MOV	AX,DX		;; AL = random number
   234 00000136 A3[3D01]            <1> 	MOV	WORD [RNDNUM],AX
   235                              <1> 
   236 00000139 5A                  <1> 	POP	DX
   237 0000013A C3                  <1> 	RET
   238                              <1> 
   239 0000013B 4937                <1> SEED	DW 3749h
   240 0000013D 0000                <1> RNDNUM	DW 0
   241                                  
   242                                  _star_count	equ	256
   243                                  
   244 0000013F <res 00000200>          _x:	resw	_star_count
   245 0000033F <res 00000200>          _y:	resw	_star_count
   246 0000053F <res 00000100>          _xstep:	resb	_star_count
   247 0000063F <res 00000100>          _ystep:	resb	_star_count
   248 0000073F <res 00000100>          _color:	resb	_star_count
