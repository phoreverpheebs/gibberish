section .text
global _start

_start:
	mov ebp, $+len
	jmp $+1
	aad
pro_len equ $-_start
db "Hello, World!", 0x0a 
len equ $-_start
	lahf
	jg $+1
	shr eax, 7			; INTERRUPT flag should be set
	or edx, len-pro_len
	lea ecx, [_start+pro_len]
	int 0x80
	pop eax
	add eax, here
	push eax
	ret
here equ $-_start-pro_len+1
	blsmsk eax, eax
	and eax, 0x1
	xor ebx, ebx
	int 0x80
