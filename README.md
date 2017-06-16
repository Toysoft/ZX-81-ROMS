# ZX-81-ROMS

Study of the Sinclair ZX-81 ROMS disassembly.

There are a lot of resources in the internet with scattered information about the internal workings of the
Sinclair ZX-81 operating system that came in a 8K ROM.

This project builds on these resources by adding information and keeping this open for comments and discussion.

As far as I know, the Sinclair ROM copyright is held by Amstrad, who has allowed non-commercial use of its contents. 
This project is setup on this principle. If I'm wrong, and this project infringes any copyright rights, please
let me know.

The assembly source files are in the syntax used by the Z88DK Z80ASM assembler [https://github.com/z88dk/z88dk](https://github.com/z88dk/z88dk "The development kit for over fifty z80 machines - c compiler, assembler, linker, libraries").

## ZX-81 version 2 (improved) ROM

ROM disassembly: [https://www.dropbox.com/s/kobh280px4ab0lr/zx81.html?dl=0](https://www.dropbox.com/s/kobh280px4ab0lr/zx81.html?dl=0 "ZX-81 version 2 (improved) ROM")

Source: An Assembly Listing of the Operating System of the ZX81 ROM [https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ROMs/zx81%20version%202%20'improved'%20rom%20source.txt](https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ROMs/zx81%20version%202%20'improved'%20rom%20source.txt "An Assembly Listing of the Operating System of the ZX81 ROM")

User Manual: ZX81 Basic Programming [https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ZX81%20Basic%20Programming.pdf](https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ZX81%20Basic%20Programming.pdf "ZX81 Basic Programming")

The ROM Disassembly Book by Dr. Ian Logan and Dr. Frank O'Hara [https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ROMs/zx81%20version%202%20'improved'%20rom%20disassembly%20(Logan%2C%20O'Hara).html](https://k1.spdns.de/Vintage/Sinclair/80/Sinclair%20ZX81/ROMs/zx81%20version%202%20'improved'%20rom%20disassembly%20(Logan%2C%20O'Hara).html "The Complete Timex TS1000 / Sinclair ZX81 ROM Disassembly")


## ZX-81 "Shoulder of Giants" ROM

ROM disassembly: ...work in progress...

This is a customized ZX81 ROM variant by Geoff Wearmouth which uses space-saving techniques to make way for Newton's square root calculation, improved decimal number input and consistent output to the screen and printer of floating point numbers. 

Source: [https://web.archive.org/web/20150501015418/http://www.wearmouth.demon.co.uk/sg.htm](https://web.archive.org/web/20150501015418/http://www.wearmouth.demon.co.uk/sg.htm "The Shoulders of Giants ZX81 ROM Assembly")


## TK-85 ROM

ROM disassembly: [https://www.dropbox.com/s/0crgpfcqqcu2jbt/tk85.html?dl=0](https://www.dropbox.com/s/0crgpfcqqcu2jbt/tk85.html?dl=0 "TK-85 ROM")

The TK-85 was a Brazilian clone of the ZX-81 that came with 2K, 16K or 48K of RAM and 10K of ROM.

The first 8K of the ROM are mostly the same as the ZX-81 improved ROM, with the following differences:

- The memory test goes up to ```$FEFF```, instead of ```$7FFF``` in the ZX-81, to cope with the 48K models.

- Some spare bytes that in the ZX-81 are encoded with $FF, contain information:
	- At ```$0017```, ```$0025```, ```$0026```, ```$0027```, ```$0065``` : ```"TK82C"```
	- At ```$27FD```, ```$27FE```, ```$27FF```: ```$34```, ```$20```, ```$41``` - maybe a version code?

- The PAUSE command routine has the bug of the ZX-81 version 1 ROM where a pause can crash. The TK-85 User Manual recommends in Chapter 19, page 19-1 that the user shall ```POKE 16437, 255``` after a PAUSE. 

The extra 2K of ROM contain utility routines to be called by ```USR```. The user manual calls these the TOS, Tape Operating System, and describes most of them in chapter 29. These routines have several code duplications and repeat some code existing in the 8K ROM.

The routines are:
 
- Make REM space: 
	- Create a line ```1 REM xx``` (exactly two characters after the REM);
	- Poke at 16514, 16515 the size of the REM wanted;
	- ```RAND USR 8192``` creates a ```2 REM ...``` with as many dots as defined in the two-byte value at 16514.
	- It would be simple to change the interface to ```PRINT USR 8192;NNN``` to create only one REM statement in one go.

- Save the program in High Speed:
	- ```RAND USR 8405``` saves the program to tape at 1500 baud with a different format than the ZX-Spectrum - 4096 0-bit, of which at least 30 are expected on read, 1 start-bit=1, one $43 byte, the E\_LINE in two bytes, the data from VERSN to (E\_LINE), and two 8-bit sum bytes.
	
- Verify a program saved in High Speed:
	- ```RAND USR 8539``` reads the program from tape and computes the checksum, but does not overwrite the program in memory.

- Load a program saved in High Speed:
	- ```RAND USR 8630``` reads the program from tape at high speed.
	
- Save and load buffers: several routines allow saving, loading and verifying data buffers to/from tape. The interface is through buffers defined as character arrays (e.g. ```DIM C$(200)```), a buffer pointer as a string variable Z$ (e.g. ```LET Z$="C"```), a read/write size variable Z (```LET Z=0```) and calling each function (```LET STATUS=USR xxxx```). The functions are:
	- Write buffer to tape at normal speed: ```LET STATUS=USR 8288```;
	- Read buffer from tape at normal speed: ```LET STATUS=USR 8305```;
	- Verify buffer from tape at normal speed: ```LET STATUS=USR 9816```;
	- Write buffer to tape at high speed: ```LET STATUS=USR 9008```;
	- Read buffer from tape at high speed: ```LET STATUS=USR 9189```.
