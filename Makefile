all: zx81.bin

zx81.bin zx81.map: zx81.asm
	z80asm -b -l -m zx81.asm 
	perl -S hexdump zx81.bin > zx81.bin.dump
	perl -S hexdump zx81.rom > zx81.rom.dump
	diff zx81.bin.dump zx81.rom.dump

clean:
	rm -f zx81.bin zx81.err zx81.i zx81.o zx81.lis zx81.map zx81.*.dump *.bak


# build browsable asm source with hyperlinks
all: zx81.html

zx81.html: zx81.asm format_asm.pl build_asm_html.pl
	perl format_asm.pl zx81.asm
	perl build_asm_html.pl zx81.asm
