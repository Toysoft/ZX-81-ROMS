zx81.bin : zx81.asm
	asmpp.pl -b zx81.asm 
	diff zx81.bin zx81.rom
