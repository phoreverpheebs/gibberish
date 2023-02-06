
gibberish: gibberish.o
	ld -melf_i386 gibberish.o -o gibberish

gibberish.o: gibberish.asm
	nasm -felf32 gibberish.asm -o gibberish.o

.PHONY: clean
clean: *.o
	rm -f *.o
