EXE = gibberish

AS=nasm
LDFLAGS=--nmagic -melf_i386
ASFLAGS=-felf32

all: $(EXE)

$(EXE): $(EXE).o
	$(LD) $(LDFLAGS) $< -o $@

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f *.o

