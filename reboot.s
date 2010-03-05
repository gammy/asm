global _start

_start:
	movq rax, 88
	movq rbx, 0xfee1dead
	movq rcx, 0x28121969
	movq rdx, 0x4321fedc
;	xor esi, esi
	int 0x80
