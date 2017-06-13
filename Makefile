zx81.bin : zx81.asm
	asmpp.pl -b -l -m zx81.asm 
	perl -S hexdump zx81.bin > zx81.bin.dump
	perl -S hexdump zx81.rom > zx81.rom.dump
	diff zx81.bin.dump zx81.rom.dump

clean:
	rm -f zx81.bin zx81.err zx81.i zx81.o zx81.lis zx81.map zx81.*.dump
