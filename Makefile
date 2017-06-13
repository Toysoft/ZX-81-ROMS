zx81.bin : zx81.asm
	asmpp.pl -b zx81.asm 
	diff zx81.bin zx81.rom

clean:
	rm -f zx81.bin zx81.err zx81.i zx81.o
