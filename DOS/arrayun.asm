; Initialize array, then print.
; by gammy
; nasm -fbin -o lol.com lol.asm

[bits 16]

org 0x100

xor     si, si
mov     bp, _array_end

mov     al, 48  ; '0' in ASCII

; Initialize
setloop:
    mov     [_array + si], al
    inc     al
    inc     si
    cmp     si, bp
    jne     setloop

; Reset "counters"
xor     si, si
mov     bp, _array_end

; Print
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
_array       resb   10
_array_end   equ $-_array

_message 	db  'X', '$'
