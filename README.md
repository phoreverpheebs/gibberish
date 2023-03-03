# x86 'Hello, World!', but make it gibberish

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
