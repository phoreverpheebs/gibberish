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
db 0xc1
	ror eax, 7			; INTERRUPT flag should be set
	or edx, len-pro_len
	lea ebx, [_start+pro_len]
	xchg ecx, ebx
	test ebp, ecx
	cmp cl, 0x80
	jnl $-4
	jne $-0x6f
	retn 0x8366
	rol dl, here
	ret
here equ $-_start-pro_len+1
	blsmsk eax, eax
	and eax, 0x1
	xor ebx, ebx
	syscall
