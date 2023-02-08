# x86 'Hello, World!', but make it gibberish

This project started out as a way to quickly offset the `eip` (instruction pointer) 
progression with a 'Hello, World!' print, but turned into a messy implementation of 
hello world in x86, using the weird properties of instruction encoding and the
weird ways `jmp` can manipulate the stepping of a program.

This README will serve as an in-depth explanation on how `gibberish.asm` works and 
what my thought processes were during the writing of it. I will try to keep it as 
understandable as possible, incase anyone who doesn't know much x86 Assembly decides 
to read this.

I decided to avoid repeat instructions (just to make the challenge a bit more interesting), 
so some operations that could be very simple are implemented in bizarre ways.

_Note: An interesting thing is that running the code through gdb will adjust the instruction 
offset based on execution. So if you are interested in exploring the program through gdb, 
you can run the following commands:_

### Running through gdb

```bash
gdb ./gibberish
```
then continuing within gdb
```gdb
break _start
layout asm
run
stepi
```
and then repeatedly hitting Enter (it repeats the previous command). I suggest using `stepi` 
over `nexti`, since this allows you to step into `call` instructions which is used here.

## Lines

- [1 - 3](#1-to-3)
- [4 - 6](#4-to-6)
- [10 - 13](#10-to-13)

## 1 to 3

```nasm
section .text
global _start
_start:
```
For those who know x86 Assembly this should be very familiar, though we will still
go over it here:

The NASM `section` directive denotes the beginning of a named section. `.text` is
used for the section that contains all the code.

`global` is a directive that exports symbols. Namely, think of it as the `pub`
keyword in most modern languages. Here it is used to export the `_start` label
to the linker.

Finally, `_start:` is a label that marks the beginning of the `_start` "function".

## 3 to 9

```nasm
_start:
    mov ebp, $+len      ; bd 17 90 04 08
    jmp $+1             ; eb ff
    aad                 ; d5 0a
pro_len equ $-_start
db "Hello, World!", 0x0a
len equ $-_start
```
Getting into the actual code part, I will write the hexadecimal encoding of the instructions 
in comments, as we will have to go over hidden instructions, that will only be visible when 
exploring the code with an offset. 

Program execution starts off with a simple `mov` instruction, which moves the address
of `$+len` into the destination `ebp` register (the choice of `ebp` will be apparent on lines
[17 to 24](#17-to-24)). The `$` tells the assembler to substitute it for the the virtual 
address in memory of that line. We use it as a substitute for labels in most cases here.

You can use `$ - {label}` to get the size of the data between the current address and `{label}`.
This is done for `pro_len equ $-_start` to get the length (in bytes) of the 'prologue'. The same
is done for the subsequent `len`, which allows us to get the length of the message by getting
the difference between the two.

`db` means `define byte` and lets us define a byte in-place. There's not specific reason
to put the message in the middle of code, except for playing with bizarre ways of
obfuscating code. Normally, data like this would be in a `.data` section. It is used
once more in this program to encode an instruction that would normally be a bit tricky
with general NASM syntax.

`jmp $+1` allows us to begin the offsetting. The `$` on its own works from the beginning of
the encoded instruction, so offsetting that by 1 sets the next instruction to start from `ff`.

For a quick rundown of instruction encoding in the x86 architecture, we shall go over `ff d5`
and how it is encoded. We can use [coder32](http://ref.x86asm.net/coder32.html) for opcode 
lookups, thanks to which we can see that `ff` has 7 different encodings. 

### ModR/M

Using [this table from coder32](http://ref.x86asm.net/coder32.html#modrm_byte_32) or
the official table from the 
[Intel Developer's Manual Volume 2A (2-6)](https://cdrdv2.intel.com/v1/dl/getContent/671199) 
we can figure out how to encode each of these instructions, based on the register/opcode 
field and the operand we choose to use. What we're looking for is the `call /2` instruction,
so from the top row we pick the `/digit (Opcode)` field to be 2. Further, we can look at the 
left column to find our operand. We're simply using the `ebp` register here, which gives us 
`d5` when coupled with the register/opcode field 2. Now we know our encoded target 
instruction is `ff d5`.

Returning to the code now `ff` is a part of the `jmp` instruction, so we are left with
`d5`, which is an example of a weird implicit encoding of the `aad` instruction. The intricacies
of what it does and how it does it are unimportant for this project, but essentially it takes an
implicit radix of 10 (`0a` in base-16), which is why the actual encoding has an extra byte. 
It's also an interesting instruction for the fact that even the Intel Manual tells the developer 
that the only way the radix can be changed is by hand-editing the underlying machine code.

I'm going on a tangent though, the point here is `d5` is our opcode for `aad` and NASM will take care
of the extra `0a` for us. 

### Summary

To summarize what happens in these lines; we first move the address of the "main" function
(it's not actually labelled, but we can imagine that everything between `len equ $-_start` and
`here equ $-_start-pro_len+1` are the main function), and then in the `jmp` instruction
we offset execution by one byte, which executes `call ebp`. The leftover byte is never
read.

## 10 to 13

```nasm
    lahf            ; 9f
    jq $+1          ; 72 6c
db 0xc1             ; c1
    rol eax, 0x19   ; c1 c0 19
```
At this point our `eax` register should be empty as it hasn't been used yet by any of our previous
registers. `lahf` is an instruction that moves the `flags` register into `ah`. According to 
[Intel Developer's Manual Volume 1 (3-16)](https://cdrdv2.intel.com/v1/dl/getContent/671436),
the second bit of `flags` will always be set (while the rest are reserved as 0 or belong to
a flag) and according to the 
[System V ABI (Table 3.5)](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf)
the rest of the flags will be unset at process initialization. Which means that when looking at `ax` 
as the concatenation of `ah:al` it should be 0000001000000000<sub>2</sub>. Our current goal is
to set `eax` to 4 (a call to the kernel, executed in x86 with the instruction `int 0x80`, uses the
`eax` register to pass the index of the function that we want it to execute; parameters are then
passed in the remaining registers. [32-bit syscall table](https://www.nullmethod.com/syscall-table/)),
which in binary is 100<sub>2</sub>, therefore we may shift `eax` 7 bits to the right.

We do this using the `rol` (rotate left) instruction by rotating it 25 bits to the left since the 
rotate instructions wrap around to the beginning (unlike shift instructions which pad the other
size with 0), but not before offsetting execution again, since the program execution has realigned 
due to the encoding of the bytes `Hello, World!\n` (the instructions that the bytes encode to and 
the operands that they expect cause the disassembler to align with the written assembly).

To avoid using the `jmp` instruction again, we'll use a conditional jump instead (we end up using
this multiple times throughout). `jg rel8` jumps relatively from the current address when the ZF
flag is unset and the OF and SF flags are equal. No preceding instructions affect these flags, so 
the condition is satisfied. In terms of the address being jumped to, we use the same `$+1` trick
as before.

Instead of using `ff` to call into a different procedure, we will increment the `ecx` register 
(lines [14 to 16](#14-to-16) exchange the values between `ebx` and `ecx`, so we will temporarily 
store the value in `ecx`, even though we need the operand in `ebx`), as we want the `sys_write` 
syscall (`eax = 4`) to write to `stdout` (`ebx = 1`). So, once again referencing the 32-bit ModR/M 
table, we can see that the register/opcode field 0 and operand `ecx` gives us `c1` as the second 
byte for the `inc` (increment) instruction.

In `gibberish.asm` this is just written explicitly using the `db` directive, though obfuscating
it further by writing it out as legal instructions is also viable and we will play around with this 
concept later in the code.

Following this we perform a bitwise rotation left on the `eax` register to move the bit set on
the tenth position to the third position. Leaving us with the desired values: 

* `eax` = 4
* `ecx` = 1

_Note:_ the reason we use `rol` to get the right value in `eax` instead of `ror`, is that rotating
right by 7 bits would cause the next instruction to be a single byte, meaning we'd realign again.
Another option would be to over-rotate with ror.

### Summary

We indirectly store the value 4 in `eax` by loading the `flags` register 
(where the second bit is always set) into `ah` and then rotating `eax` left by 25 bits.
We offset execution again and increment `ecx`. Slowly setting up a `sys_write` call.

## 14 to 16

```nasm
    or edx, len-pro_len         ; 83 ca 0e
    lea ebx, [_start+pro_len]   ; 8d 1d 09 90 04 08
    xchg ecx, ebx               ; 87 cb
```

For `sys_write` we need the `edx` register to hold the amount of bytes that we want to write
to the file descriptor in `ebx`. We can get the length of the string by subtracting our compile-time
constants `len` and `pro_len`. `edx` is empty at this point of execution and when an unset bit is
OR'ed with a set bit, the result is 1. We use this property to copy the value `len-pro_len` to
`edx`.

As mentioned in the previous section, we will swap the values `ebx` and `ecx`, but first we must
load the `ecx` target value into `ebx`. The `lea` instruction stores the address of the second
operand into the first operand. `_start + pro_len` contains the beginning of the string and for
the `sys_write` syscall `ecx` stores the address to start writing from.

With `ecx` holding the value that should be in `ebx` and `ebx` holding the value expected
to be in `ecx`, we need to swap their contents. Luckily x86 gives us an operation for this,
which is `xchg` (exchange). A little fun fact is that `nop` is an alias for `xchg eax, eax`.

All `sys_write` operands are loaded in their corresponding registers, which means we are ready
to call a system interrupt (hand execution over to the kernel).

### Summary

We load the amount of bytes to write to `stdout` and the address from which to start writing.
Then we exchange `ebx` and `ecx`, since their values are swapped.

## 17 to 24

```nasm
    test ebp, ecx       ; 85 cd
    cmp cl, 0x80        ; 80 f9 80
    jnl $-4             ; 7d fa
    jne $-0x6f          ; 75 8f
    retn 0xc283         ; c2 83 c2
db $-_start-pro_len+4   ; 30
    push edx            ; 52
    ret                 ; c3
```

Our next goal is to transfer the execution to the kernel for the system call. We do this using the
`int 0x80` instruction, encoded as `cd 80`. Notice it in the source code above, but the previous
section caused us to realign once again. The `test` and `cmp` instructions don't have any effect
on execution (in this case) as long as they don't affect the equality between the 
**SF** and **OF** flags.

`jnl $-4` will jump 4 bytes back relative to the _beginning_ of the `jnl` instruction, which
means that we resume execution from the second byte of the `test` instruction. Meaning the next
instruction is `int 0x80` (`cd 80`); our syscall.

`cmp cl, 0x80` was not a randomly chosen instruction, as it has to be one of the 7 instructions
encoded under `80` and it has to be valid. Our best bet is to rule out the instructions that
modify registers, as they may also attempt to write to illegal addresses. Using the `cmp` instruction
lets us use `f9` as the first operand, since it also corresponds to the `stc` instruction, which
will be valid even as we loop back. The second operand then serves as another `cmp`, which compares
the bytes of the inital `jnl`.

Choosing `jnl` over any other conditional jump is important here, since the second `80` from the 
`cmp` has to be the start of a valid instruction. `7d` together with the register/opcode 7
corresponds to `[ebp]+disp8`, meaning _"the contents of ebp with an 8-bit displacement (signed)"_.
The byte `fa` in [two's complement](https://en.wikipedia.org/wiki/Two%27s_complement)
tells us the displacement is -6, therefore meaning we are taking the address that `ebp` contains
and subtracting 6. Thanks to the first we wrote, `ebp` now contains a valid address (the address
of the "main" function) for user space to read, which means this will be a valid address that doesn't
effect execution (if this weren't the case, we'd get a general protection exception; see 
[Intel Developer's Manual Volume 1 (Table 6.1)](https://cdrdv2.intel.com/v1/dl/getContent/671436)).

The operand to `jne` assembles to `8f`, which is a `pop` instruction, more precisely popping
the top value of the stack (pointed to by `esp`) into `edx`, using the ModR/M-based `pop`
instruction (the operand is `c2`; the beginning of the `retn`). We use `edx` as it is a free 
register that won't affect upcoming instruction execution.

The `call` instruction, called at the beginning of this program, jumps to the desired address, but
first pushes the current value of `eip` (the instruction pointer) onto the stack. This is how
`return` keywords work in most languages; a sub-procedure does its thing and then the `ret` 
instruction pops the value at the top of the stack and jumps back to it. Our intentions here
are to pretend to "return" to `_start` after this procedure, but instead we modify the return
address to be the address of our "exit".

There are also options to modify `ebp` and then push that on the stack or modify at the memory
address of the stack directly, but _where's the fun in that? :(_

`ret` has two variants, one which returns without an operand and the other takes an amount of bytes
to pop from the stack after returning. To avoid instruction realignment, we set the next intended
instructions to be the 16-bit operand. We increment `edx` to the address of the exit, by adding the
amount of bytes between the initial `call` location and the `blsmsk` instruction (start of exit)
and then `push edx`, to return it back to the stack for a final `ret`.

## 25 to 28

```nasm
    blsmsk eax, eax ; c4 e2 78 f3 d0
    and eax, 0x1    ; 83 e0 01
    xor ebx, ebx    ; 31 db
    int 0x80        ; cd 80
```

At this point we know `eax` has the amount of bytes that were written to `stdout`, as the
return value of the system code was returned through `eax` and for `sys_write` that is the
amount of bytes successfully written. Therefore, we know that `eax` is not zero, so we can
use this `blsmsk` instruction, which sets every lower bit in the first operand starting at
the first bit up to the lowest set bit in the second operand.

As long as `eax` was non-zero, we know that after running `blsmsk` the first bit will be set,
therefore doing bitwise AND with 1, will set the first bit to 1 and the rest to 0. Resulting in
`eax = 0` corresponding to the `sys_exit` syscall.

`ebx` then holds the status code of the process, so we bitwise XOR it with itself.
When a register performs an XOR on itself, it clears it; the return code 0 tells the user
the program ended successfully.

Finally, the `int 0x80` once again to pass the execution to the kernel and finally exit the program.

### Summary

We indirectly load the value 1 into `eax`, corresponding to `sys_exit`, we use 0 for the return
code in `ebx` to denote a successful execution and in the end we exit the program using a system
call.

## Thank you <3

If you chose to read this whole thing, thank you so much. This was a really random thing that
came to my mind during class, so I decided to try it out. It ended up being really fun digging
deep into the intricacies of program execution and it was incredibly interesting seeing how certain
instructions could end up having a "double meaning" per se.
