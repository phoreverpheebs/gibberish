section .text
global _start

	clflush [0xe6819648]
dd _start+8
	jmp $+1
	salc
_start:
	call _start-11
	lmsw [eax+0x0c87c18f]
	and al, 0x80
	loopz $-0xf ; AND ecx with 0xef to unset ecx[4]

	jp $+3
	test dword [eax+0xeb1d2404], 0x01efbe15 ; add onto return address and jump to print
	rcl dword [eax+0x80900e04], 0xc3
db 0x0b, 0xf6 				; or esi, esi | we have to write it explicitly
	jecxz $+0x2e
	jno $+0x7b
	int1

	nop dword [eax]
	jnp $+0x27

; print procedure:
	bts eax, 0 				; stores eax[0] in CF and sets it
	cmc						; inverts the CF bit
	sbb eax, eax			; if eax[0] is unset, this zeroes the eax register
							; if set, the register underflows; setting the SF flag
	js $-7					; if sign is set it jumps back, where eax[0] will be set (the underflow)
	gs lahf					; the PF and CF are set and eFLAGS[1] is always set on x86 (ah == 70)
	jz $+3					; offset into the second operand of the following subtraction
	sub al, 0xd5			; 0xd5 (aad) uses the 0x96 (xchg r32, eax) -> also comma for (0x2c)
	xchg esi, eax 			; overflow ah (70 * 150) % 256 == 4
	jge $+5					; jump into operand of lidt
	lidt [ebx+0xd282f999]	; sign bit of eax is not set, therefore edx is set to 0 with cdq (0x99)
							; CF is unset now so we force it to be set with stc (0xf9)
							; (0x00d282) edx + 0 + CF == 0 + 0 + CF == 1
	add byte [edi], cl
	mov dh, 0x1d			; zero extension move 01 into ebx from the lidt opcode
dd $-0xa
	int 0x80				; syscall
	ret

	push 0xffffd6e8
	inc dword [edi*8+eax+0xff514141] ; double increments ecx, pushes it and the value it points to
	xor [ecx+0x326c6ae1], ecx
	or eax, $-0x42
	ja $+1

	rol dword [ebx+0xd6ff6ac6], 0xf ; change offset for esi call
	pop ds

	lds eax, [ebx+0xe80f2414] ; 0x0a for second return address
dd 0-0x4f
	jnb $-0x4f ; jnb instead of jg so that the previous 0xff makes a valid instruction
	jo $-0x5917fcf1
dw 0xffff
	dec dword [ebp+0x90660e39] ; beginning is a `lea`, which when used on r, r is basically a mov
; we can assert that on an unmodified linux kernel on an x86 machine the cs segment register 
; will be 0x23 in 32-bit user space, see this line:
; https://elixir.bootlin.com/linux/latest/source/arch/x86/include/asm/segment.h#L137
	loop $+4
	; the jmp fest
	lgs eax, [ebx+0x02eb09c1]
	shld [ecx+0xeb102474], ecx, 2
	shrd [ebx+0x4310e45c], eax, 0x8b
	imul eax, [eax], 0x03ebe987
	cmpxchg8b [0x54ff4141]
	in eax, 4

	shl al, 0x5
	neg ebp ; ebp holds a stack address, meaning negating it will unset the sign bit
	jns $+4
	cmovb edx, [eax+0x8d240420]
	jbe $-0x41
	jge $+4
	ud0 ecx, dword [ebx+0xd6ff90cc]
	lea ebx, dword [esi-0x36]
	jnbe $+6
	popcnt ecx, [ecx+esi+0x0c83241c]
	movsb
	adc [ebx+0x687f2424], eax
dd $+0xf
	cmp ecx, edi
	jnge _start+0x2f
	btr dword [ebx+eax*4+0xd6ff04c1], 0xf6
	fadd dword [eax+0x441802e0]
	frndint


; exit procedure:
	btc ebx, 0
	syscall
