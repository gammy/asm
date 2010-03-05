;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Programmed by Yaniv LEVIATHAN
; http://yaniv.leviathanonline.com
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[bits 16]
[org 0x100]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global defines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define NUM_PARTS	150
%define X_OFFSET	0
%define Y_OFFSET	2
%define X_SPEED_OFFSET	4
%define Y_SPEED_OFFSET	6
%define COLOR_OFFSET	8
%define PART_SIZE	10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; resize self
mov ah, 0x4a
mov bx, 0x1000
int 0x21
jc near exit

; allocate buffer
mov ah, 0x48
mov bx, 0x1000
int 0x21
jc near exit
mov es, ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov ax, 0x13
int 0x10

; uncomment the following line to skip palette initialization
;jmp std_pal

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

	
zero_buffer:
	mov cx, 320*200/4
	xor di, di
	xor eax, eax
	rep stosb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

db 0x0f, 0x31
mov [seed], eax

jmp MAIN

init_particle:
db 0x0f, 0x31
and ax, 0x1F
jnz .dont_re_init_globals
; init x
call rand
xor dx, dx
mov bx, 320
div bx
shl dx, 6
mov [global_x], dx
; init y
call rand
xor dx, dx
mov bx, 200
div bx
shl dx, 6
mov [global_y], dx
.dont_re_init_globals:
; init x
mov dx, [global_x]
mov [bp+X_OFFSET], dx
; init y
mov dx, [global_y]
mov [bp+Y_OFFSET], dx
; init x speed
call rand
and ax, 31
sub ax, 15
;shl ax, 6
mov [bp+X_SPEED_OFFSET], ax
; init y speed
call rand
and ax, 31
sub ax, 15
;shl ax, 6
mov [bp+Y_SPEED_OFFSET], ax
; init color
mov ax, 255
;call rand
;and ax, 0xFF
mov [bp+COLOR_OFFSET], ax
ret

MAIN:
	mov cx, NUM_PARTS
	mov bp, particles
	.advance_particles:
		mov ax, [bp+X_OFFSET]
		mov bx, [bp+Y_OFFSET]

		sar ax, 6
		sar bx, 6

		cmp ax, 5
		jb .new_particle
		cmp ax, 315
		jge .new_particle
		cmp bx, 5
		jb .new_particle
		cmp bx, 195
		jge .new_particle

		jmp .part_ok

	.new_particle:
		call init_particle
		jmp .advance_particles

	.part_ok:
		mov di, ax
		mov ax, 320
		mul bx
		add di, ax
		mov ax, [bp+COLOR_OFFSET]
		stosb

		mov ax, [bp+X_OFFSET]
		mov bx, [bp+Y_OFFSET]
		add ax, [bp+X_SPEED_OFFSET]
		add bx, [bp+Y_SPEED_OFFSET]
		mov [bp+X_OFFSET], ax
		mov [bp+Y_OFFSET], bx

		db 0x0f, 0x31
		and ax, 0x7F
		jnz .dont_inc_y_speed
		inc word [bp+Y_SPEED_OFFSET]
		.dont_inc_y_speed:
	
		add bp, PART_SIZE
	loop .advance_particles

	call mmx_shade

	mov eax, [blur_right_flag]
	and eax, 0x800000
	jnz .do_blur_right
	call mmx_blur
	db 0x0f, 0x31
	and ax, 1
	jz .blur_ok
	jmp .dont_blur
	.do_blur_right:
	call mmx_blur_right
	.blur_ok:
	mov eax, [blur_right_flag]
	add eax, 0x1000
	mov [blur_right_flag],  eax
	.dont_blur:

	.copy_buffer_to_video:
		xor si, si
		xor di, di
		push es
		pop  ds
		mov bx, 0xA000
		mov es, bx
		mov cx, 320*200/4
		rep movsd
		push ds
		pop es
		push cs
		pop ds
	.check_for_key:
		mov ah, 1
		int 0x16
		jz MAIN

exit:
mov ax, 3
int 0x10
mov ah, 0x4c
int 0x21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Misc. Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mmx_shade:
mov cx, 320*200/8
xor di, di
movq mm1, [sub_mask]
.lop:
	movq mm0, [es:di]
	psubusb mm0, mm1
	movq [es:di], mm0
	add di, 8
	loop .lop
ret

mmx_blur:
mov cx, (320*200-330*2)/8
mov di, 328
.lop:
	movq mm0, [es:di]
	movq mm1, [es:di+1]
	movq mm2, [es:di-1]
	movq mm3, mm0
	movq mm4, [es:di-320]
	movq mm5, [es:di+320]

	pavgb mm0, mm1 ; mm0 = avg(cur,cur+1)
	pavgb mm3, mm2 ; mm3 = avg(cur,cur-1)
	pavgb mm4, mm5 ; mm4 = avg(cur+320,cur-320)
	pavgb mm3, mm4 ; mm3 = avg(avg(cur,cur-1),avg(cur+320,cur-320))
	pavgb mm0, mm3 ; mm0 = avg(avg(cur,cur+1),

;	pavgb mm1, mm2
;	pavgb mm4, mm5
;	pavgb mm1, mm4
;	pavgb mm0, mm1
	
	movq [es:di], mm0
	add di, 8
	loop .lop
ret

mmx_blur_right:
mov cx, (320*200-330*2)/8
mov di, 328
.lop:
	movq mm0, [es:di]
	movq mm1, [es:di+1]
	movq mm2, [es:di+320]
	movq mm3, [es:di+321]
	pavgb mm0, mm1
	pavgb mm3, mm2
	pavgb mm0, mm3
	movq [es:di], mm0
	add di, 8
	loop .lop
ret


rand:
mov eax, [seed]
imul eax, 214013
add eax, 2531011
mov [seed], eax
shr eax, 16
ret

[section .data]
seed: dd 0
global_x: dw 160*64
global_y: dw 100*64
sub_mask: dd 0x01010101, 0x01010101
;                             x, y, x_speed, y_speed, color
particles: times NUM_PARTS dw 0, 0, 0,       0,       0
blur_right_flag: dd 0

