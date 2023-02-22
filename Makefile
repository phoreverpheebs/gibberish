FILENAME = gibberish

gibberish: ${FILENAME}.o
	ld --nmagic -melf_i386 ${FILENAME}.o -o ${FILENAME}

gibberish.o: ${FILENAME}.asm
	nasm -felf32 ${FILENAME}.asm -o ${FILENAME}.o

.PHONY: clean
clean:
	rm -f *.o

