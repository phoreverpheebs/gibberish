section .text
global _start
_start:
	dec eax ; capital H for string
	xchg esi, eax
	and esi, $+len-1
	jmp $+1
	salc
len equ $-_start

; the idea is to have a print that takes an address in ecx
; and prints one byte. This proc shouldn't be called, but 
; instead jmp'ed to with a return address pushed on the 
; stack. This allows us to chain return addresses; or 
; specifically return into a different offset.

; print procedure:
	bts eax, 0 				; stores eax[0] in CF and sets it
	cmc						; inverts the CF bit
	sbb eax, eax			; if eax[0] is unset, this zeroes the eax register
							; if set, the register underflows; setting the SF flag
	js $-7					; if sign is set it jumps back, where eax[0] will be set (the underflow)
	lahf					; the PF and CF are set and eFLAGS[1] is always set on x86 (ah == 70)
	jz $+3					; offset into the second operand of the following subtraction
	sub al, 0xd5			; 0xd5 (aad) uses the 0x96 (xchg r32, eax)
	xchg esi, eax 			; overflow ah (70 * 150) % 256 == 4 where [0x96 == 150]
	jge $+5					; jump into operand of lidt
	lidt [ebx+0xd282f999]	; sign bit of eax is not set, therefore edx is set to 0 with cdq (0x99)
							; CF is unset now so we force it to be set with stc (0xf9)
							; (0x00d282) edx + 0 + CF == 0 + 0 + CF == 1
							; we also have the ebx offset to sneak in 0x9b which xor'ed with 0xf7
							; yields 0x6c (the character 'l')
	add byte [edi], cl
	mov dh, 0x1d		; zero extension move 01 into ebx from the lidt opcode
dd $-0xa
	int 0x80			; syscall
	; XXX the offset here depends on the address above, so refer to this later
	ret

; index:
; rul = ruled out
; pao = pass as operand (implicit 'rul')

; one-byte opcodes:
; dec eax    			(48) H | cause underflow, filling eax ?
; gs override			(65) e
; ins m8, dx 			(6c) l | pao
; ins m8, dx 			(6c) l | pao
; outs 					(6f) o | pao
; sub al, imm8  		(2c) ,
; and r/m8, r8  		(20)
; push edi      		(57) W
; outs m16/32			(6f) o | pao
; jb rel8				(72) r | we can get this from `not` opcode using AND 0b01110010
; ins m8, dx 			(6c) l | pao
; fs override   		(64) d
; and r/m16/32, r16/32 	(21) !
; or r8, r/m8			(0a) \n

; two-byte opcodes:
; cmovs r16/32, r/m16/32 		(0f 48)
; pcmpgtw mm, mm/m64			(0f 65)
; punpcklqdq xmm, xmm/m128 		(0f 6c)
; movq mm, mm/m64				(0f 6f)
; cvttps2pi mm, xmm/m64			(0f 2c)
; mov r32, cr	  				(0f 20) | rul
; xorps xmm, xmm/m128			(0f 57)
; psrld|psrad|pslld xmm, imm8	(0f 72)
; pcmgtb xmm, mm/m64			(0f 64)
; mov r32, dr 					(0f 21) | rul
; undefined						(0f 0a) | jmp over?

