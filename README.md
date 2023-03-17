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

## The SIGSEGV

`gibberish.asm` (at least on my machine) runs into a segmentation fault about
50% of the time, which to me raises an interesting question that will lead me
to look into how memory is laid out at the beginning of a processes execution
on a standard Linux system. In `gdb`, the memory seems to be allocated in a
consistent manner, which causes the exception to never occur, though in normal
execution it seems to be slightly different.
