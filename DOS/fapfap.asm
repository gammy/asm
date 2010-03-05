     1                                  ; by gammy
     2                                  ; nasm -fbin -o lol.com lol.asm
     3                                  ; a work in progress :D
     4                                  ; TODO:
     5                                  ; - randomize
     6                                  ; - star structure + star init
     7                                  ; - finish vblank
     8                                  
     9                                  [bits 16]
    10                                  
    11                                  org 0x100
    12                                  
    13 00000000 B81300                  mov 	ax,     0x13
    14 00000003 CD10                    int 	0x10
    15                                  
    16 00000005 E80800                  call    init_pal
    17                                  
    18                                  main_loop:
    19 00000008 E82200                  	call	draw
    20                                  	;call	wait_vblank
    21 0000000B E83B00                  	call	kb_chk_esc
    22 0000000E EBF8                    	jmp	main_loop
    23                                  
    24                                  init_pal:
    25 00000010 31C0                    	xor	ax, ax
    26 00000012 BAC803                  	mov	dx, 0x3c8
    27 00000015 EE                      	out	dx, al
    28                                  pal_loop:
    29 00000016 BAC903                  	mov	dx, 0x3c9
    30 00000019 B000                    	mov	al, 0			; Because I want blue.
    31 0000001B EE                      	out	dx, al
    32 0000001C EE                      	out	dx, al
    33 0000001D 88E0                    	mov	al, ah
    34 0000001F C0E802                  	shr	al, 2			; / 4
    35 00000022 EE                      	out	dx, al
    36 00000023 FEC4                    	inc	ah
    37 00000025 88E0                    	mov	al, ah
    38 00000027 80FCFF                  	cmp	ah, 255
    39 0000002A 75EA                    	jne	pal_loop
    40 0000002C C3                      	ret
    41                                  
    42                                  draw:  
    43                                  	; Obviously just a test so far.
    44 0000002D 31C0                    	xor	ax, ax
    45 0000002F 31D2                    	xor	dx, dx
    46 00000031 68A000                  	push	160			; x
    47 00000034 686400                  	push	100			; y
    48 00000037 68FE00                  	push	254			; color
    49 0000003A E82000                  	call	plot			; fucking draw it!
    50 0000003D C3                      	ret
    51                                  
    52                                  wait_vblank:
    53 0000003E C3                      	ret ; FIXME not finished
    54 0000003F BADA03                  	mov	dx, 0x3da		; vblank addr
    55 00000042 E408                    	in	al, 8
    56 00000044 A808                    	test	al, 8			; wait for vblank
    57 00000046 75F6                    	jnz	wait_vblank
    58 00000048 C3                      	ret
    59                                  
    60                                  kb_chk_esc:
    61 00000049 31C0                    	xor	ax, ax
    62 0000004B B401                    	mov	ah, 1			; Get keystroke status
    63 0000004D CD16                    	int	0x16
    64 0000004F 740B                    	jz	kb_chk_end		; No key
    65 00000051 B400                    	mov	ah, 0			; Get key
    66 00000053 CD16                    	int 	0x16
    67 00000055 3C1B                    	cmp	al, 27			; Is it esc?
    68 00000057 7503                    	jne	kb_chk_end		; nope
    69 00000059 E82500                  	call	exit			; yup
    70                                  kb_chk_end:
    71 0000005C C3                      	ret
    72                                  
    73                                  plot:
    74                                  	; prolog (equiv to enter $n, $0)
    75 0000005D 55                      	push	bp			; store bp
    76 0000005E 89E5                    	mov	bp, sp
    77                                  
    78                                  	; Setup vram write
    79 00000060 BF00A0                  	mov	di, _vram		; stosb reads es:di, so..
    80 00000063 8EC7                    	mov	es, di
    81 00000065 31FF                    	xor	di, di
    82                                  
    83                                  	; Compute offset (i = y; i <<= 8; i += y << 6; i += x)
    84 00000067 8B4606                  	mov     ax, [bp + 6]		; y
    85 0000006A 89C2                    	mov     dx, ax
    86 0000006C C1E008                  	shl     ax, 8			; y << 8 (256)
    87 0000006F C1E206                  	shl     dx, 6			; y << 6 (64) (256+64=320)
    88 00000072 01D0                    	add     ax, dx			; ax(y << 8) += dx(y << 6)
    89 00000074 034608                  	add     ax, [bp + 8]		; + x
    90                                  
    91                                  ;	mov	ax, 320			; width
    92                                  ;	mov	dx, [bp + 6]		; y
    93                                  ;	mul	dx; ax *= dx
    94                                  ;	add	ax, [bp + 8]		; + x
    95                                  
    96 00000077 89C7                    	mov	di, ax			; ready for stosb
    97 00000079 8A4604                  	mov	al, [bp + 4]		; color
    98 0000007C AA                      	stosb				; al -> vram (fucking updated!)
    99                                  
   100                                  	; epilog
   101 0000007D 5D                      	pop	bp			; restore bp
   102 0000007E C20600                  	ret	6			; 2 bytes per parm, 3 parm = 6 bytes
   103                                  
   104                                  exit:
   105                                  	; Textmode
   106 00000081 B80300                  	mov 	ax, 0x3
   107 00000084 CD10                    	int	0x10
   108                                  	; Terminate
   109 00000086 B44C                    	mov 	ah, 0x4c
   110 00000088 B000                    	mov 	al, 0
   111 0000008A CD21                    	int 	0x21
   112                                  
   113                                  ; http://eradicus.blogsome.com/2006/09/06/random-number-generator-in-16-bit-dos-assembly/ (with minor changes)
   114                                  ; 8-bit.
   115                                  ;randomize:
   116                                  ;	xor	ax, ax
   117                                  ;	in	al, 40h			; read micro-clock for initial seed
   118                                  ;	mov	ah, al
   119                                  ;	in	al, 40h
   120                                  ;	xchg	al, ah
   121                                  ;	or	ax, 1
   122                                  ;	mov	rnum, ax		; FIXME
   123                                  ;	ret
   124                                  
   125 0000008C 4869742061206B6579-     _waitmsg	db 'Hit a key.', 10, 13, '$'
   126 00000095 2E0A0D24           
   127 00000099 4C4F4C210A0D24          _message 	db  'LOL!', 10, 13, '$'
   128                                  _vram 		equ 0xa000
   129                                  
   130                                  _star_count equ 256
   131                                  
   132                                  ;struc stars
   133                                  ;    .x      resw    _star_count
   134                                  ;    .y      resw    _star_count
   135                                  ;    .xstep  resb    _star_count
   136                                  ;    .ystep  resb    _star_count
   137                                  ;    .color  resb    _star_count
   138                                  ;endstruc
   139                                  ;
   140                                  ;star:
   141                                  ;    istruc stars
   142                                  ;        at  .x,     dw 1
   143                                  ;        at  .y,     dw 1
   144                                  ;        at  .xstep, db 1
   145                                  ;        at  .ystep, db 1
   146                                  ;        at  .color, db 1
   147                                  ;    iend
   148                                      
   149                                  
