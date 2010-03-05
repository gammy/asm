;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Programmed by Yaniv LEVIATHAN
; http://yaniv.leviathanonline.com
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[bits 16]
[org 0x100]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enter mode 13
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax, 0x13
int 0x10

init_palette:
mov dx, 0x3c8
xor ax, ax
out dx, al
inc dx

red_loop:
	out dx, al	; r
	xchg al, ah
	out dx, al	; g
	out dx, al	; b
	xchg al, ah

	out dx, al	; r
	xchg al, ah
	out dx, al	; g
	out dx, al	; b
	xchg al, ah

	inc ax
	cmp al, 64
	jl red_loop

xor ax, ax
mov ah, 63
white_loop:
	xchg al, ah
	out dx, al	; r
	xchg al, ah
	out dx, al	; g
	out dx, al	; b

	xchg al, ah
	out dx, al	; r
	xchg al, ah
	out dx, al	; g
	out dx, al	; b
		
	inc al
	cmp al, 64
	jl white_loop


	
jmp MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAIN:
	mov bx, 0xA000
	mov es, bx
	xor di, di
	xor al, al
	
	mov dl, 200
	mov cx,256
	.color_loop:
		stosb
		inc al
		dec cx
		jnz .color_loop
	add di, 320-256
	mov cx,256
	dec dl
	jnz .color_loop

	.check_for_key:
		mov ah, 1
		int 0x16
		jz MAIN

exit:
mov ax, 3
int 0x10
mov ah, 0x4c
int 0x21

