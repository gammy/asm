; Loop through and print each byte of an array
; by gammy
; nasm -fbin -o lol.com lol.asm

[bits 16]

org 0x100

xor     si, si
mov     bp, _array_end

readloop:
    mov     dl, [_array + si]
    mov     [_message], dl

    xor     ax, ax
    mov 	ah, 0x9	
    mov 	dx, _message
    int 	0x21

    inc     si
    cmp     si, bp
    jne     readloop

call 	exit

; Terminate with return code
exit:
	mov 	ah, 0x4c
	mov 	al, 0
	int 	0x21
	leave

; Data
_array       db 0x6c, 0x6f, 0x6c, 0x63, 0x61, 0x74, 0x73
_array_end   equ $-_array

_message 	db  'X', '$'
