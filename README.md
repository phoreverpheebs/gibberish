# 'Hello, World!' in x86 assembly, but make it gibberish

`gibberish` is a **simple** 'Hello, World!' program written in x86 assembly, which
doesn't reuse instructions and barely makes any sense. We have branched off a version
of `gibberish`, which defines the 'Hello, World!' string directly in the source and 
compiled binary instead of scattering its bytes all over, before and during execution.
This branch also spends more time explaining the process of its creation and techniques
we can use to offset execution to keep the program's doings secret.
([The defined-string branch](https://github.com/phoreverpheebs/gibberish/tree/defined-string)).

This repository is to demonstrate ways we can obfuscate a binary from being
read through a simple `objdump` or other disassembly tools. Though, this method
is not perfect, as simply tracking all `call` and `jmp` instructions could lead
to a reliable reconstruction of the execution flow, we still may observe that
running `strings` on this binary does not show any signs of an encoded `Hello, World!`
string, since we use various methods to encode these in instructions, or increment
and decrement previous values to get the character we need.

We also demonstrate how certain actions may be performed in redundant ways, so
as to confuse the average reverse engineer (e.g. the print procedure uses four
total instructions to zero the `eax` register).

## Exposed strings

```
$ strings gibberish
gibberish.asm
__bss_start
_edata
_end
.symtab
.strtab
.shstrtab
.text
```

The only exposed strings are symbols, which may simply be stripped.

## Potential segmentation faults

The instruction at offset _\_start+0xb9_ negates the _ebp_ register, which at the time
holds a stack address. The assumption here is that the stack is allocated in a higher
section of the address space, where the sign bit ends up being set. However, as pointed
out by [fortyonepercent on Hacker News](https://news.ycombinator.com/item?id=35204432)
certain emulations with [qemu](https://github.com/qemu/qemu) may allocate the stack
to a lower address space causing the `jns` after the negation to be ignored.
