; By gammy.
; Random number generator segment by unknown author - see random.inc.
;
; nasm -l faphex.asm -f bin -o fap.com fap.asm
; a work in progress.
;
; FIXMEs: parallax speeds, nicer colors (now, a lot = black!),re-rand on wrap

[bits 16]

org 0x100

call	init_stars

mov 	ax,     0x13
int 	0x10

call    init_pal

main_loop:
	call	kb_chk_esc
	call	draw
	call	wait_vblank
	jmp	main_loop

init_pal:
	xor	ax, ax
	mov	dx, 0x3c8
	out	dx, al
pal_loop:
	mov	dx, 0x3c9
	;mov	al, 0			; because I want blue.
	;out	dx, al
	;out	dx, al
	mov	al, ah
	shr	al, 2
	out	dx, al			; fill white
	out	dx, al			; -||-
	out	dx, al
	inc	ah
	mov	al, ah
	cmp	ah, 255
	jne	pal_loop
	ret

init_stars:
	push	ax
	push	bx
	xor	ax, ax			; our counter. ZARRO.
; This is horrible.
init_loop:
	mov	bx, _x			; &x
	add	bx, ax			; + offset
	push	ax
	call	RANDOM
	xor	ah, ah
	;add	ax, 32			; hack ((320-256) >> 1) - centering.
	shl	ax, 8
	mov	[bx], word ax
	pop	ax

	mov	bx, _y			; &y
	add	bx, ax			; + offset
	push	ax
	call	RANDOM
	xor	ah, ah
	xor	dx, dx
	mov	cx, 200			; screen height
	div	cx			; dx = ax % cx
	mov	[bx], word dx
	pop	ax

	mov	bx, _xstep		; &xstep
	add	bx, ax			; + offset
	push	ax
	call	RANDOM
	;mov	dl, al

	xor	dx, dx
	mov	cx, word _star_layers 
	div	cx			; dx = ax % cx 
	shl	dx, 14

	;mov	dx, 32767
	;xor	dx, dx
	mov	[bx], word dx
	;mov	[bx], byte dl
	pop	ax

	; Color is based on xstep (parallax)
	mov	bx, _color		; &color
	add	bx, ax			; + offset
	shr	dx, 8
	mov	[bx], byte dl

; No vertical movement.
;	mov	bx, _ystep		; &ystep
;	add	bx, ax			; + offset
;	push	ax
;	call	RANDOM
;	mov	[bx], byte al
;	pop	ax

	add	ax, 2
	cmp	ax, _star_count  * 2 
	jne	init_loop
	pop	bx
	pop	ax
	ret
 
draw:  
	push	ax
	push	bx
	xor	ax, ax			; counter
; Also fucking horrible. 
draw_clear:
	mov	bx, _x
	add	bx, ax
	push	word [bx]		; x

	mov	bx, _y
	add	bx, ax
	push	word [bx]		; y

	push	word 0
	call	plot			; fucking clear it!
draw_update:
	mov	bx, _xstep
	add	bx, ax			; xstep offset
	mov	dx, [bx]
	shr	dx, 8			; dx = real xstep val
	
	mov	bx, _x			; x 
	add	bx, ax			; x offset

	; Sub xstep from x
	sub	word [bx], dx

	cmp	word [bx], 0		; 31 (hack)
	jg	draw_fill

	mov	dx, 255 << 8		; far right
	sub	dx, [bx]		; minus abs x

	;add	word [bx], 65535; (255 << 8) 
draw_fill:
	; Set
	mov	bx, _x
	add	bx, ax
	push	word [bx]		; x

	mov	bx, _y
	add	bx, ax
	push	word [bx]		; y

	mov	bx, _color
	add	bx, ax
	push	word [bx]		; color

	call	plot			; fucking draw it!

	add	ax, 2
	cmp	ax, _star_count * 2
	jne	draw_clear
	pop	bx
	pop	ax
	ret

wait_vblank:
	mov	dx, 0x3da		; vblank addr
retrace_beg:
	in	al, dx
	test	al, 8
	jnz	retrace_beg
retrace_end:
	in	al, dx
	test	al, 8
	jz	retrace_end
	ret

kb_chk_esc:
	xor	ax, ax
	mov	ah, 1			; get keystroke status
	int	0x16
	jz	kb_chk_end		; no key
	mov	ah, 0			; get key
	int 	0x16
	cmp	al, 27			; is it esc?
	jne	kb_chk_end		; nope
	call	exit			; yup
kb_chk_end:
	ret

plot:
	push	bp			; store bp
	mov	bp, sp
	push	ax

	; Setup vram write
	mov	di, 0xa000		; stosb reads es:di, so..
	mov	es, di
	xor	di, di

	; Compute offset (i = y; i <<= 8; i += y << 6; i += x)
	mov     ax, [bp + 6]		; y
	mov     dx, ax
	shl     ax, 8			; y << 8 (256)
	shl     dx, 6			; y << 6 (64) (256+64=320)
	add     ax, dx			; ax(y << 8) += dx(y << 6)
	;add     ax, [bp + 8]		; + x
	;mov	dx, ax
	push	dx
	mov     dx, [bp + 8]		; + x
	shr	dx, 8
	add	dx, 32
	add	ax, dx
	pop	dx

;	mov	ax, 320			; width
;	mov	dx, [bp + 6]		; y
;	mul	dx; ax *= dx
;	add	ax, [bp + 8]		; + x

	mov	di, ax			; ready for stosb
	mov	al, [bp + 4]		; color
	stosb				; al -> vram (fucking updated!)

	pop	ax
	pop	bp			; restore bp
	ret	2 * 3			; 2 bytes * 3 params

exit:
	mov 	ax, 0x3
	int	0x10

	; Terminate
	mov 	ah, 0x4c
	mov 	al, 0
	int 	0x21

%include 'random.inc'

_star_count	equ	512
_star_layers	equ	4

_x:	resw	_star_count
_y:	resw	_star_count
_xstep:	resw	_star_count
_ystep:	resw	_star_count
_color:	resb	_star_count
