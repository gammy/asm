; by gammy
; nasm -fbin -o lol.com lol.asm
; a work in progress :D

[bits 16]

org 0x100				; setup location counter

mov 	ax, 0x13
int 	0x10

; Print _message 
mov 	ah, 0x9	
mov 	dx, _message
int 	0x21

draw:
; Plot white pixel in center
push	160					; x
push	100					; y
push	31					; color
call	plot				; fucking draw it!
;call	wait_vblank (not finished)
jnz		draw

; Keyboard loop
kbinput:
	mov 	ah, 1			; Nonzero
	int 	0x16 			; Wait for keypress & read char to ah
	jz 		kbinput

mov 	ax, 0x3
int 	0x10

call 	exit

;wait_vblank:
;
;	mov		dx, 0x3da		; vblank addr
;	in 		al, 8
;	test	al, 8			; wait for vblank
;	jnz 	wait_vblank
;	; FIXME not finished (need to wait for retrace, too)

; Plot pixel
plot:
	; prolog (equiv to enter $n, $0)
	push	bp				; store bp
	mov		bp, sp

	; Setup vram write
	mov 	di,	_vram		; stosb reads es:di, so..
	mov		es, di
	xor		di, di

	; Offset calc
	mov		ax, 320			; width
	mov		bx, [bp + 6]    ; y
	mul		bx				; ax *= bx
	add		ax, [bp + 8]	; + x

	mov		di, ax			; ready for stosb
	mov		al, [bp + 4]	; color
	stosb					; al -> vram (fucking updated!)

	; epilogue
	pop		bp				; restore bp
	ret		6				; 2 bytes per parm, 3 parm = 6 bytes

; Terminate with return code
exit:
	mov 	ah, 0x4c
	mov 	al, 0
	int 	0x21
	leave

; Data
_message 	db  0b0000000001000010, 'OL!', 10, 13, '$'
_vram 		equ 0xa000
