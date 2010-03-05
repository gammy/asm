; nasm -fbin -o kb.com kb.asm

_waitmsg	db 'Hit esc to exit.', 10, 13, '$'

[bits 16]
org 0x100

mov     ah, 0x9
mov     dx, _waitmsg
int     0x21

mainloop:
    call    kbinput
    jmp	    mainloop

kbinput:
    mov     al, 256
    xor     ax, ax
    mov     ah, 1       ; Get keystroke status
    int     0x16
    jz      kbinput_end ; No key
    mov     ah, 0       ; Get key
    int     0x16
    cmp     al, 27      ; Is it esc?
    jne     kbinput_end ; nope
    call    exit        ; yup
kbinput_end:
    ret

exit:
    mov     ah, 0x4c
    mov     al, 0
    int     0x21
    leave

