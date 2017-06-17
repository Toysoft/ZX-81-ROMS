#ifdef ROM_tk85
; ======================
; TK85 specific routines
; ======================

; --------------
; MAKE_REM_SPACE
; --------------
; The user writes a 1 REM xx statement as the first program line, pokes at
; 16514 the desired REM space (two characters after the REM) and calls USR 8192
; This routine creates a 2 REM .... line as many dots as poked.

MAKE_REM_SPACE:
        call    FAST            ; Needs FAST to move memory

        ld      bc, 6           ; Add 6 to desired space for total REM line length
        ld      hl, (PROG+5)    ; input desired space
        push    hl              ; * save desired_space in stack
        add     hl, bc          ; desired_space + 6
        ld      b, h
        ld      c, l            ; total new REM line length to BC

        ld      hl, (NXTLIN)    ; get address of next line to be executed
        add     hl, bc
        ld      (NXTLIN), hl    ; adjust with space to add

; Similar to the ROM routine POINTERS at $09AD
; NOTE: does not test for out-of-memory!

        ld      hl, D_FILE      ; first pointer
        ld      a, 09h          ; 9 pointers: D_FILE to STKEND

NEXT_PTR_1:
        ld      e, (hl)         ; pointer into DE
        inc     hl
        ld      d, (hl)

        push    de              ; ** save current pointer

        ex      de, hl          ; to HL
        add     hl, bc          ; add space to move
        ex      de, hl          ; DE = old_pointer + space_moved

        ld      (hl), d         ; store new pointer
        dec     hl
        ld      (hl), e

        inc     hl              ; advance to next pointer
        inc     hl

        dec     a
        jr      z, PTR_DONE_1   ; end after 9 pointers

        pop     de              ; ** get current pointer

        jr      NEXT_PTR_1

; enters with DE = new STKEND position and old STKEND position in stack

PTR_DONE_1:
        pop     hl              ; ** get last pointer: old STKEND
        push    hl              ; ** save again in stack

        ld      bc, PROG + 7    ; point to $76 at end of 1 REM

        and     a
        sbc     hl, bc          ; HL = end of space to move - start of space to move

        ld      b, h            ; BC = number of bytes to move
        ld      c, l

        pop     hl              ; * old STKEND
        lddr                    ; move bytes to DE = new STKEND

        ld      hl, PROG + 8    ; point to first byte of 2 REM

        ld      (hl), 0         ; add line number = 2
        inc     hl
        ld      (hl), 2
        inc     hl

        pop     bc              ; * pop desired space
        inc     bc              ; add 2 for REM and NL
        inc     bc

        ld      (hl), c         ; store REM size
        inc     hl
        ld      (hl), b
        inc     hl

        ld      (hl), 0eah      ; store REM token

        dec     bc              ; subract 2 to get desired_space
        dec     bc

        inc     hl              ; point to first REM byte

        ld      de, 1           ; set DE to HL+1
        ex      de, hl
        add     hl, de
        ex      de, hl

        ld      (hl), '.' - 19  ; write a dot
        ldir                    ; copy desired_size

        ld      (hl), 75h       ; overwrite last copied byte with NL
        inc     (hl)            ; why not ld (hl), $76???

        call    SLOW
        ret

; ---
        defs    2, $FF          ; unused locations


; ==================
; START OF TK-85 TOS
; ==================
; These routines handle saving and loading to and from tape at normal and hi-speed
; of programs and data buffers
; They start by creating a 44-byte stack frame pointed by IY with the following local variables:
;
;       iy-44 :
;       iy-43 :
;       iy-42 :
;       iy-41 :
;       iy-40 :
;       iy-39 :
;       iy-38 :
;       iy-37 :
;       iy-36 :
;       iy-35 :
;       iy-34 :
;       iy-33 :
;       iy-32 :
;       iy-31 :
;       iy-30 :
;       iy-29 :
;       iy-28 :
;       iy-27 :
;       iy-26 :
;       iy-25 :
;       iy-24 :
;       iy-23 :
;       iy-22 :
;       iy-21 :
;       iy-20 :
;       iy-19 :
;       iy-18 :
;       iy-17 :
;       iy-16 :
;       iy-15 :
;       iy-14 :
;       iy-13 :
;       iy-12 :
;       iy-11 :
;       iy-10 :
;       iy-9  : signal bits for timer errors during load
;               bit 0: timer <= 10
;               bit 1: timer <= 110
;               bit 2: timer <  215
;       iy-8  : current load routine to re-enter in DLOAD
;               read buffer size in DHLOAD
;       iy-6  : location of Z variable number
;       iy-4  : data buffer size
;       iy-2  : data buffer address

; ---------
; Data Save
; ---------
; Saves the string pointed by Z$, with a maximum save size held in variable Z

DSAVE:
        call    PREP_DLO_DSA_WS ; set FAST and reserve work space
        call    GET_BUFFER      ; get address and size of buffer
        call    GET_SAVE_SIZE   ; get size to save
        call    DSAVE_BUFFER    ; save buffer to tape

        ld      bc, TOS_OK      ; return with OK result
        jr      DLO_DSA_RET

; ---------
; Data Load
; ---------
; Loads data from tape to the string pointed by Z$
; Save the number of bytes loaded in the variable Z

DLOAD:
        call    PREP_DLO_DSA_WS ; set FAST and reserve work space
        call    GET_BUFFER      ; get address and size of buffer
        call    GET_Z_VALUE     ; HL = address of Z variable

        ld      (iy-5), h       ; save in IY(-6,-5); Note: unnecessary, already done
        ld      (iy-6), l       ; in GET_Z_VALUE

; set Z to zero

        ld      b, 5            ; 5 bytes per number
FILL_Z_ZERO:
        ld      (hl), 00h
        inc     hl
        djnz    FILL_Z_ZERO

        call    DLOAD_BUFFER    ; load buffer from tape, HL = number of bytes read
        call    SAVE_Z_VALUE    ; store HL in the Z variable
        jr      DLO_DSA_RET

; --------------------------
; Make DSAVE/DLOAD workspace
; --------------------------
; Checks for available RAM (Report G if not enough), sets FAST mode
; and allocates a frame of 14 bytes in the stack, setting IY to the
; frame pointer and original SP

PREP_DLO_DSA_WS:
        ld      hl, -44         ; working space 44 bytes below stack
        add     hl, sp
        ex      de, hl          ; SP - 44 -> DE

        ld      hl, (STKEND)    ; check for free space
        or      a
        sbc     hl, de          ; HL = STKEND - (SP - 44), must be < 0
        jr      c, PREP_DLO_DSA_CONT

; --------------
; THE 'REPORT-G'
; --------------

REPORT_G:                       ; NOTE: why not RST 08h, 0Fh?
        ld      a, ERR_G_NO_ROOM_WS
        ld      (ERR_NR), a
        pop     hl              ; drop return address of DSAVE/DLOAD
        ret                     ; return to original caller

; DE has SP-44 as address of work buffer

PREP_DLO_DSA_CONT:
        call    SET_FAST_IF_SLOW; assert FAST mode

        ld      iy, 0           ; IY = SP
        add     iy, sp

        inc     iy              ; IY = SP+2
        inc     iy

        pop     de              ; DE = return address to DSAVE / DLOAD
                                ; IY = SP

        ld      hl, -14         ; reserve 14 bytes below stack; IY is the frame pointer
        add     hl, sp
        ld      sp, hl

        ex      de, hl          ; return to caller
        jp      (hl)

; Exit point from DLOAD et.al.
; Restores the SP and IY

DLO_DSA_RET:
        ld      (2000h), a      ; Note: nonsense, writing to ROM
        ld      sp, iy          ; Remove frame
        ld      iy, ERR_NR      ; Restore IY
        ret

; -------------------------
; Change to FAST if in SLOW
; -------------------------

SET_FAST_IF_SLOW:
        ld      hl, CDFLAG      ; test SLOW/FAST bits
        ld      a, (hl)
        and     $C0
        jr      z, IN_FAST_MODE ; both are clear - in FAST mode

; wait for interruput and disable NMI

        halt                    ; synchronize with display frame
        out     (0fdh), a       ; Turn off the NMI generator.

        ld      hl, CDFLAG      ; clear both bits - set FAST mode
        ld      a, (hl)
        and     3fh
        ld      (hl), a

IN_FAST_MODE:
        ret

; -------------
; Hi-speed save
; -------------
; Save:
;   - 512 zero bytes = 4096 zero bits
;   - 1   one bit
;   - $43 signature byte
;   - E_LINE, LSB first
;   - bytes from VERSN to (E_LINE)
;   - twice the checksum byte computed by adding all bytes from VERSN to (E_LINE)

HISAVE:
        call    SET_FAST        ; FAST mode

; save prologue of 512 zero bytes

        ld      hl, 0           ; Reset counter

HISAVE_PROLOGUE:
        inc     hl

        ld      d, 0            ; Save a zero byte
        call    HISAVE_BYTE

        ld      a, h            ; repeat until HL = $0200 (512 bytes)
        cp      02h
        jr      nz, HISAVE_PROLOGUE

; save 1 one bit

        ld      d, $FF          ; Save bit 7 of D
        call    HISAVE_BIT

; save signature byte

        ld      d, $43
        call    HISAVE_BYTE     ; Save signature $43

; save E_LINE, LSB first

        ld      hl, (E_LINE)    ; Fetch E_LINE, i.e. end of area to save

        ld      d, l            ; save LSB of E_LINE
        call    HISAVE_BYTE
        ld      d, h            ; save MSB of E_LINE
        call    HISAVE_BYTE

        ld      hl, VERSN       ; Start address to be saved ($4009)

; save bytes from VERSN to (E_LINE)

        ld      e, 0            ; E is used for a checksum byte

HISAVE_BYTES:
        ld      a, (hl)         ; Fetch byte to be saved
        ld      d, a            ; will save D

        add     a, e            ; compute checksum: E := E + D
        ld      e, a            ; save checksum

        call    HISAVE_BYTE     ; save byte

        inc     hl              ; point to next

        push    de
        ex      de, hl
        ld      hl, (E_LINE)
        scf                     ; compare < instead of <=
        sbc     hl, de
        ex      de, hl
        pop     de
        jr      nc, HISAVE_BYTES; repeat if HL < E_LINE

; save checksum twice

        ld      d, e            ; D = checksum
        call    HISAVE_BYTE     ; save checksum

        ld      d, e
        call    HISAVE_BYTE     ; save checksum

        jp      SLOW_FAST       ; exit through SLOW_FAST

; save 8 bits

HISAVE_BYTE:
        call    HISAVE_BIT      ; Save bit 7
        call    HISAVE_BIT      ; Save bit 6
        call    HISAVE_BIT      ; Save bit 5
        call    HISAVE_BIT      ; Save bit 4
        call    HISAVE_BIT      ; Save bit 3
        call    HISAVE_BIT      ; Save bit 2
        call    HISAVE_BIT      ; Save bit 1
        call    HISAVE_BIT      ; Save bit 0
        ret

; save bit-7 of D and rotate D

HISAVE_BIT:
        and     a               ; Reset carry flag
        rl      d               ; Bit to save into carry
        sbc     a, a            ; $FF if bit=1 or $00 if bit=0
        and     26h             ; $26 if bit=1 or $00 if bit=0
        add     a, 11h          ; $37 if bit=1 or $11 if bit=0

        ld      b, a            ; transfer timer to B. a set bit has a longer
                                ; mark pulse than a reset bit

        ld      a, $7F          ; Read keyboard and start VSYNC pulse
        in      a, ($FE)

        rra                     ; check bit-0 = BREAK key

        push    hl              ; Timing?
        pop     hl

        jr      nc, BREAK_PRESSED_2

DELAY_8:
        djnz    DELAY_8

        ld      b, $11          ; space = size of zero bit
        out     ($FF), a        ; End the VSYNC pulse

DELAY_9:
        djnz    DELAY_9

        nop                     ; Timing?
        nop
        ret

BREAK_PRESSED_2:
        pop     hl              ; remove three return addresses
        pop     hl
        pop     hl
        jp      REPORT_D        ; NOTE: Should call RST 08 directly


; ---------------
; Hi-speed verify
; ---------------

HIVERIFY:
        call    HILOAD_WAIT_HEADER
                                ; wait for header stream and signature

        call    HILOAD_BYTE_1   ; read E_LINE low
        ld      a, d
        cpl                     ; is inverted
        ld      l, a            ; into L

        call    HILOAD_BYTE_1   ; read E_LINE high
        ld      a, d
        cpl                     ; is inverted
        ld      h, a            ; into H

        ld      (SPARE2), hl    ; save E_LINE in SPARE2

        ld      b, 1            ; Note: seams to be a LOAD(0)/VERIFY(1) flag
                                ; but is not used
        ld      e, 0            ; init checksum to zero

        ld      hl, VERSN       ; start of saved program

HIVERIFY_BYTES:
        call    HILOAD_BYTE_1   ; read next byte
                                ; not compared with actual memory, just compute checksum
        ld      a, d
        cpl                     ; is inverted

        add     a, e            ; compute checksum: E := E + D
        ld      e, a            ; save checksum

        inc     hl              ; point to next

        push    de
        ex      de, hl
        ld      hl, (SPARE2)    ; SPARE2 has read E_LINE
        scf                     ; compare < instead of <=
        sbc     hl, de
        ex      de, hl
        pop     de
        jr      nc, HIVERIFY_BYTES
                                ; repeat if HL < read E_LINE

        call    HILOAD_BYTE_1   ; read checksum - first copy discarded
        call    HILOAD_BYTE_1   ; read checksum - second copy

        ld      bc, TOS_OK

        ld      a, d
        cpl                     ; is inverted
        cp      e               ; compare computed checksum with read checksum

        jr      nz, HIVERIFY_ERROR
                                ; compare checksum

; print OK
        ld      a, 'O' - 27
        rst     PRINT_A
        ld      a, 'K' - 27
        rst     PRINT_A
        jr      HIVERIFY_END

; print ERRO (error in Portuguese)

HIVERIFY_ERROR:
        ld      a, 'E' - 27
        rst     PRINT_A
        ld      a, 'R' - 27
        rst     PRINT_A
        ld      a, 'R' - 27
        rst     PRINT_A
        ld      a, 'O' - 27
        rst     PRINT_A

; end through SLOW/FAST

HIVERIFY_END:
        jp      SLOW_FAST

; ---

        defs    9, $00          ; unused locations


; -------------
; Hi-speed load
; -------------

HILOAD:
        call    HILOAD_WAIT_HEADER
                                ; wait for header stream and signature

        call    HILOAD_BYTE_1   ; read and discard E_LINE low
        call    HILOAD_BYTE_1   ; read and discard E_LINE high

        ld      b, 0            ; Note: seams to be a LOAD(0)/VERIFY(1) flag
                                ; but is not used

        ld      e, 0            ; init checksum to zero

        ld      hl, VERSN       ; start of saved program

HILOAD_BYTES:
        call    HILOAD_BYTE_1   ; read next byte

        ld      a, d
        cpl                     ; is inverted
        ld      (hl), a         ; store in memory

        add     a, e            ; compute checksum: E := E + D
        ld      e, a            ; save checksum

        inc     hl              ; point to next

        push    de
        ex      de, hl
        ld      hl, (E_LINE)    ; compare HL with E_LINE
                                ; Note: has the same bug as the original ZX-81 ROM
                                ; where a load may end early because the LSB of E_LINE
                                ; is read from tape before the MSB, and this test can
                                ; get a wrong E_LINE

        scf                     ; compare < instead of <=
        sbc     hl, de
        ex      de, hl
        pop     de
        jr      nc, HILOAD_BYTES; repeat if HL < E_LINE

        call    HILOAD_BYTE_1   ; read checksum - first copy discarded
        call    HILOAD_BYTE_1   ; read checksum - second copy

        ld      a, d
        cpl                     ; is inverted
        cp      e               ; compare computed checksum with read checksum

        jp      nz, START       ; Reset if wrong checksum, as system variables may be
                                ; corrupt
                                ; NOTE: should be INITIAL

        jp      SLOW_FAST

; read inverted byte into D

HILOAD_BYTE:
        ld      d, 0
        call    HILOAD_BIT      ; Load bit 7
        call    HILOAD_BIT      ; Load bit 6
        call    HILOAD_BIT      ; Load bit 5
        call    HILOAD_BIT      ; Load bit 4
        call    HILOAD_BIT      ; Load bit 3
        call    HILOAD_BIT      ; Load bit 2
        call    HILOAD_BIT      ; Load bit 1
        call    HILOAD_BIT      ; Load bit 0
        ret

; read inverted bit into D-0

HILOAD_BIT:
        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.

        rra                     ; test for SPACE pressed.
        jp      nc, BREAK_PRESSED_2
                                ; jump if so

        rla                     ; reverse above rotation
        rla                     ; test tape bit.
        jr      c, HILOAD_BIT   ; wait while bit=1

        ld      c, 0            ; counter
HILOAD_BIT_0:
        inc     c               ; count loop

        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.

        rra                     ; test for SPACE pressed.
        jp      nc, BREAK_PRESSED_2
                                ; jump if so

        rla                     ; reverse above rotation
        rla                     ; test tape bit.
        jp      nc, HILOAD_BIT_0; wait while pulse is 0

        out     ($FF), a        ; output signal to screen.

        ld      a, c            ; loop counter
        sub     $0A             ; compare to 10, Carry for short pulse (=0),
                                ; no carry for long pulse (=1)

        rl      d               ; read inverted bit into D
        ret

; wait for header with stream of of 0-bits, 1 1-bit, and $43 byte

HILOAD_WAIT_HEADER:
        call    SET_FAST

WAIT_HEADER:
        ld      e, 0            ; init counter

WAIT_COUNT_ZEROS:
        inc     e               ; count loops
        out     ($FF), a        ; output signal to screen

        ld      a, e            ; get counter
        cp      $1E
        jr      nc, WAIT_ONES   ; found header if found more than 30 0-bits

        ld      d, 0            ; prepare to read one bit
        call    HILOAD_BIT_1
        ld      a, d            ; D=1 if bit=0

        cp      $01
        jr      nz, WAIT_HEADER ; bit=1, wait header and reset counter
        jr      WAIT_COUNT_ZEROS; bit=0, count continuous 0 bits

WAIT_ONES:
        out     ($FF), a        ; output signal to screen

        ld      d, 0            ; prepare to read one bit
        call    HILOAD_BIT_1
        ld      a, d            ; D=0 if bit=1

        cp      $01
        jr      z, WAIT_ONES    ; still a zero bit, wait for the marker 1-bit

        call    HILOAD_BYTE     ; read byte
        ld      a, d
        cpl                     ; byte is read inverted

        cp      $43             ; check signature
        jr      nz, WAIT_HEADER ; wait for next if wrong

        ret

HILOAD_BYTE_1:
        call    HILOAD_BYTE     ; Todo: nonsense!
        ret

HILOAD_BIT_1:
        call    HILOAD_BIT      ; Todo: nonsense!
        ret

; ---

        defs    77, $FF         ; unused locations

; -------------
; GET SAVE SIZE
; -------------
; Read buffer size and variable Z and set IY(-4,-3) to save size

GET_SAVE_SIZE:
        ld      a, ERR_H_INVALID_LENGTH
        ld      (ERR_NR), a

        call    GET_Z_VALUE     ; HL = address of Z number = number of bytes to save
        ld      bc, TOS_Z_INT_OVERFLOW
        call    TOS_FP_TO_INT   ; DE = integer value in Z

        ld      h, (iy-3)       ; HL = buffer size
        ld      l, (iy-4)

        or      a
        sbc     hl, de
        ld      bc, TOS_Z_TOO_LARGE
        jr      c, DLO_DSA_RET_2; bytes to save > buffer size -> error

        ld      (iy-3), d       ; save new buffer size from Z variable
        ld      (iy-4), e

        ld      a, ERR_0_OK
        ld      (ERR_NR), a
        ret

; ---------------
; WRITE LOAD SIZE
; ---------------
; store HL in the Z variable

SAVE_Z_VALUE:
        ld      d, (iy-5)       ; DE = address of variable value
        ld      e, (iy-6)

        call    TOS_INT_TO_FP   ; save Z value
        ret

; ---------------------
; FLOATING POINT TO INT
; ---------------------
; On input HL points at a 5 byte loating point value.
; On output DE has the corresponding integer value.

TOS_FP_TO_INT:
        ld      a, (hl)         ; A = exponent+128
        ld      de, 0           ; DE = return value
        or      a
        ret     z               ; exponent = 0 -> integer = 0

        sub     81h             ; 1 is $81 $00 $00 $00 $00
        jp      m, DLO_DSA_RET  ; number too small, error

        inc     a               ; A = exponent+1
        cp      11h
        jr      nc, DLO_DSA_RET_2
                                ; number too big, error

        inc     hl              ; point at mantissa
        ld      d, (hl)         ; get DE = mantissa
        inc     hl
        ld      e, (hl)

        push    af              ; * save exponent+1

        inc     hl              ; make sure the other 2 mantissa bytes are zero
        ld      a, (hl)
        inc     hl
        or      (hl)
        jr      nz, DLO_DSA_RET_2
                                ; error if not

        pop     af              ; * restore exponent+1

        bit     7, d            ; sign bit
        jr      nz, DLO_DSA_RET_2
                                ; error if mantissa is negative
        set     7, d            ; restore the most significant mantissa bit that
                                ; shares memory with the sign bit

        ex      de, hl          ; HL = mantissa
        ld      de, 0           ; DE = 0

CVT_TO_INT:
        add     hl, hl          ; mantissa *= 2

        ex      de, hl          ; add overflow to DE
        adc     hl, hl
        ex      de, hl

        dec     a
        jr      nz, CVT_TO_INT  ; repeat exponent times

        ld      a, h
        or      l
        ret     z               ; HL must be zero, and DE has the converted number

; fall through to error

DLO_DSA_RET_2:
        jp      DLO_DSA_RET

; -----------------
; Convert INT to FP
; -----------------
; HL has an integer value and DE the address of the FP variable to store
; Converts integer to floating point

TOS_INT_TO_FP:
        ld      a, l
        or      h
        jr      z, STORE_FP     ; if HL = 0

; shift HL right and decrement exponent while bit 15 of HL is zero

        ld      a, $80+16       ; initial exponent

NEXT_SHIFT:
        bit     7, h
        jr      nz, STORE_FP

        add     hl, hl          ; rotate left
        dec     a               ; decrement exponent
        jr      NEXT_SHIFT

STORE_FP:
        ex      de, hl          ; HL = address, DE = mantissa

        ld      (hl), a         ; save exponent

        res     7, d            ; clear sign bit
        inc     hl
        ld      (hl), d         ; store mantissa high
        inc     hl
        ld      (hl), e         ; store mantissa low
        inc     hl
        ld      (hl), 0
        inc     hl
        ld      (hl), 0
        ret

; -----------------------
; Data save at high speed
; -----------------------
; Save:
;   - 512 zero bytes = 4096 zero bits
;   - 1   one bit
;   - $43 signature byte
;   - size of buffer, LSB first
;   - buffer bytes
;   - once the checksum byte computed by adding all buffer bytes

DHSAVE:
        call    PREP_DLO_DSA_WS ; set FAST and reserve work space
        call    GET_BUFFER      ; get address and size of buffer
        call    GET_SAVE_SIZE   ; get size to save
        call    DHSAVE_BUFFER   ; save buffer to tape

        ld      bc, TOS_OK      ; return with OK result
        jp      DLO_DSA_RET


; --------------------------
; Save a data buffer to tape
; --------------------------
; Save buffer pointed by IY(-2,-1) with size IY(-2,-1) to tape

DHSAVE_BUFFER:
        ld      d, (iy-3)       ; DE = buffer size
        ld      e, (iy-4)

        ld      hl, -40
        add     hl, de
        jr      c, HSIZE_OK

; size to save < 40 -> error

        ld      a, ERR_H_INVALID_LENGTH
        ld      (ERR_NR), a

        ld      bc, TOS_Z_TOO_SMALL
        jp      DLO_DSA_RET     ; error

HSIZE_OK:
        push    de              ; * save buffer size

; save prologue of 512 zero bytes

        ld      hl, 0           ; Reset counter

DHSAVE_PROLOGUE:
        inc     hl
        ld      d, 0            ; Save a zero byte
        call    DHSAVE_BYTE

        ld      a, h            ; repeat until HL = $0200 (512 bytes)
        cp      02h
        jr      nz, DHSAVE_PROLOGUE

; save 1 one bit

        ld      d, $FF          ; Save bit 7 of D
        call    DHSAVE_BIT

; save signature byte

        ld      d, $43
        call    DHSAVE_BYTE     ; Save signature $43

        pop     de              ; * get buffer size
        push    de              ; * and push it back

        call    DHSAVE_BYTE     ; Save size MSB

        ld      d, e
        call    DHSAVE_BYTE     ; Save size LSB

        pop     de              ; * restore buffer size

        ld      h, (iy-1)       ; HL = buffer address
        ld      l, (iy-2)

        ld      c, 0            ; C is the checksum

DHSAVE_BYTES:
        push    de              ; * save buffer size

        ld      d, (hl)         ; Fetch byte to be saved

        ld      a, d            ; C += D
        add     a, c
        ld      c, a            ; save new checksum

        call    DHSAVE_BYTE     ; save data byte

        pop     de              ; * restore buffer size

        inc     hl              ; advance address

        dec     de              ; decrement size

        ld      a, d
        or      e
        jr      nz, DHSAVE_BYTES; still more bytes to save

        ld      d, c
        call    DHSAVE_BYTE     ; save checksum

        ret

; save 8 bits

DHSAVE_BYTE:                    ; Note: repeated???
        call    DHSAVE_BIT      ; Save bit 7
        call    DHSAVE_BIT      ; Save bit 6
        call    DHSAVE_BIT      ; Save bit 5
        call    DHSAVE_BIT      ; Save bit 4
        call    DHSAVE_BIT      ; Save bit 3
        call    DHSAVE_BIT      ; Save bit 2
        call    DHSAVE_BIT      ; Save bit 1
        call    DHSAVE_BIT      ; Save bit 0
        ret

; save bit-7 of D and rotate D

DHSAVE_BIT:
        and     a               ; Reset carry flag
        rl      d               ; Bit to save into carry
        sbc     a, a            ; $FF if bit=1 or $00 if bit=0
        and     26h             ; $26 if bit=1 or $00 if bit=0
        add     a, 11h          ; $37 if bit=1 or $11 if bit=0

        ld      b, a            ; transfer timer to B. a set bit has a longer
                                ; mark pulse than a reset bit

        ld      a, $7F          ; Read keyboard and start VSYNC pulse
        in      a, ($FE)

        rra                     ; check bit-0 = BREAK key

        push    hl              ; Timing?
        pop     hl

        jr      nc, BREAK_PRESSED_3

DELAY_10:
        djnz    DELAY_10

        ld      b, $11          ; space = size of zero bit
        out     ($FF), a        ; End the VSYNC pulse

DELAY_11:
        djnz    DELAY_11

        nop                     ; Timing?
        nop
        ret

BREAK_PRESSED_3:
        ld      hl, CDFLAG
        res     0, (hl)         ; signal no key available

        ld      a, ($00FF)      ; Note: ??? A = $87
        ld      (DB_ST), a

        pop     hl

        ld      a, ERR_D_BREAK  ; error - break pressed
        ld      (ERR_NR), a

        ld      bc, TOS_BREAK_PRESSED
        jp      DLO_DSA_RET


; ------------------
; Data Hi-Speed Load
; ------------------
; Loads data from tape to the string pointed by Z$
; Save the number of bytes loaded in the variable Z

DHLOAD:
        call    PREP_DLO_DSA_WS ; set FAST and reserve work space
        call    GET_BUFFER      ; get address and size of buffer
        call    GET_Z_VALUE     ; HL = address of Z variable

        ld      (iy-5), h       ; save in IY(-6,-5); Note: unnecessary, already done
        ld      (iy-6), l       ; in GET_Z_VALUE

; set Z to zero

        ld      b, 5            ; 5 bytes per number
FILL_Z_ZERO_1:
        ld      (hl), 00h
        inc     hl
        djnz    FILL_Z_ZERO_1

        call    DHLOAD_BUFFER   ; load buffer from tape, HL = number of bytes read
        call    SAVE_Z_VALUE    ; store HL in the Z variable
        jp      DLO_DSA_RET


DHLOAD_BUFFER:
        ld      e, 0            ; init counter

WAIT_COUNT_ZEROS_1:
        inc     e               ; count loops
        out     ($FF), a        ; output signal to screen

        ld      a, e            ; get counter
        cp      $1E
        jr      nc, WAIT_ONES_1 ; found header if found more than 30 0-bits

        ld      d, 0            ; prepare to read one bit
        call    HILOAD_BIT_2
        ld      a, d            ; D=1 if bit=0

        cp      $01
        jr      nz, DHLOAD_BUFFER
                                ; bit=1, wait header and reset counter
        jr      WAIT_COUNT_ZEROS_1
                                ; bit=0, count continuous 0 bits

WAIT_ONES_1:
        out     ($FF), a        ; output signal to screen

        ld      d, 0            ; prepare to read one bit
        call    HILOAD_BIT_2
        ld      a, d            ; D=0 if bit=1

        cp      $01
        jr      z, WAIT_ONES_1  ; still a zero bit, wait for the marker 1-bit

        call    HILOAD_BYTE_2   ; read byte
        ld      a, d
        cpl                     ; byte is read inverted

        cp      $43             ; check signature
        jr      nz, DHLOAD_BUFFER
                                ; wait for next if wrong

        call    HILOAD_BYTE_2   ; read size low
        ld      a, d
        cpl                     ; is inverted
        ld      (iy-7), a       ; size IY(-8,-7)

        call    HILOAD_BYTE_2   ; read size high
        ld      a, d
        cpl                     ; is inverted
        ld      (iy-8), a       ; size IY(-8,-7)

; now read data

        call    HILOAD_BYTE_2   ; read first buffer byte
        ld      a, d            ; into A

        ld      de, 0           ; DE = number of read bytes

        ld      h, (iy-1)       ; get data buffer address
        ld      l, (iy-2)

        ld      b, 0

DH_GET_NEXT_BYTE:
        push    hl              ; * save data buffer address

        ld      h, (iy-3)       ; get data buffer size
        ld      l, (iy-4)

        scf
        sbc     hl, de          ; HL = size-read_bytes-1

        jp      m, DH_MORE_THAN_BUFSIZ
                                ; jump if read_bytes >= size - end of buffer

        ld      h, (iy-7)       ; get buffer size read from tape header
        ld      l, (iy-8)

        scf
        sbc     hl, de          ; HL = size-read_bytes-1

        pop     hl              ; * restore data buffer address

        jp      m, DHSAVE_END
                                ; jump if read_bytes >= read size - end of tape data

        inc     de              ; count read bytes

        cpl                     ; is inverted
        ld      (hl), a         ; store in memory

        add     a, b            ; compute checksum: B := B + A
        ld      b, a            ; save checksum

        inc     hl              ; point to next

        push    de              ; * save number of bytes read

        call    HILOAD_BYTE_2   ; read next byte
        ld      a, d            ; into A

        pop     de              ; * restore number of bytes read

        jr      DH_GET_NEXT_BYTE

DH_MORE_THAN_BUFSIZ:
        pop     hl              ; * drop data buffer address

        ld      h, (iy-7)       ; get buffer size read from tape header
        ld      l, (iy-8)

        or      a               ; compare read bytes with buffer size from tape
        sbc     hl, de
        jr      z, DHSAVE_END   ; the same, OK

        dec     hl

DH_SKIP_BYTES:
        ld      a, h            ; check if size is zero
        or      l
        jr      z, DH_READ_OVERFLOW
                                ; end with error if reached the end

        dec     hl              ; count bytes read

        push    de              ; save read size
        call    HILOAD_BYTE_2   ; read and discard byte from tape
        pop     de              ; restore read size

        jr      DH_SKIP_BYTES

DH_READ_OVERFLOW:
        ld      bc, TOS_READ_OVERFLOW
        ex      de, hl
        ret

DHSAVE_END:
        cpl                     ; A has last byte read - checksum; invert
        cp      b               ; compare with checksum

        jr      nz, DHSAVE_ERROR
        ld      bc, TOS_OK
        ex      de, hl
        ret

DHSAVE_ERROR:
        ld      b, 0
        ld      c, TOS_TAPE_ERROR_VOLUME_LOW
        ex      de, hl          ; HL is number of bytes read
        ret

; read inverted byte into D

HILOAD_BYTE_2:
        ld      d, 0
        call    HILOAD_BIT_2    ; Load bit 7
        call    HILOAD_BIT_2    ; Load bit 6
        call    HILOAD_BIT_2    ; Load bit 5
        call    HILOAD_BIT_2    ; Load bit 4
        call    HILOAD_BIT_2    ; Load bit 3
        call    HILOAD_BIT_2    ; Load bit 2
        call    HILOAD_BIT_2    ; Load bit 1
        call    HILOAD_BIT_2    ; Load bit 0
        ret

; read inverted bit into D-0

HILOAD_BIT_2:
        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.

        rra                     ; test for SPACE pressed.
        jr      nc, BREAK_PRESSED_4
                                ; jump if so

        rla                     ; reverse above rotation
        rla                     ; test tape bit.
        jr      c, HILOAD_BIT_2 ; wait while bit=1

        ld      c, 0            ; counter
HILOAD_BIT_0_2:
        inc     c               ; count loop

        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.

        rra                     ; test for SPACE pressed.
        jr      nc, BREAK_PRESSED_4
                                ; jump if so

        rla                     ; reverse above rotation
        rla                     ; test tape bit.
        jr      nc, HILOAD_BIT_0_2
                                ; wait while pulse is 0

        out     ($FF), a        ; output signal to screen.

        ld      a, c            ; loop counter
        sub     $0A             ; compare to 10, Carry for short pulse (=0),
                                ; no carry for long pulse (=1)

        rl      d               ; read inverted bit into D
        ret

BREAK_PRESSED_4:
        ld      a, ERR_D_BREAK
        ld      (ERR_NR), a

        ld      bc, TOS_BREAK_PRESSED
        jp      DLO_DSA_RET

;---
        defs    182, $FF        ; unused locations


; --------------------------
; Save a data buffer to tape
; --------------------------
; Save buffer pointed by IY(-2,-1) with size IY(-2,-1) to tape

DSAVE_BUFFER:
        ld      d, (iy-3)       ; DE = buffer size
        ld      e, (iy-4)

        ld      hl, -40
        add     hl, de
        jp      c, SIZE_OK

; size to save < 40 -> error

        ld      a, ERR_H_INVALID_LENGTH
        ld      (ERR_NR), a

        ld      bc, TOS_Z_TOO_SMALL
        jp      DLO_DSA_RET     ; error

SIZE_OK:
        ld      bc, $1388       ; five seconds(?) timing value
        call    SILENCE_DELAY_BC; test for BREAK key and start VSYNC pulse (output=0)

        ld      h, (iy-1)       ; HL = buffer address
        ld      l, (iy-2)

DSAVE_BYTES:
        push    de              ; * save buffer size
        call    D_OUT_BYTE      ; output one byte
        pop     de              ; * restore buffer size

        inc     hl              ; point to next byte
        dec     de              ; decrement buffer size counter

        ld      a, d
        or      e
        jp      nz, DSAVE_BYTES ; loop back while there are bytes to save

        ret

; -------------------------
; THE 'OUT-BYTE' SUBROUTINE
; -------------------------
; This subroutine outputs a byte a bit at a time to a domestic tape recorder.
; HL has the location of the byte to send

D_OUT_BYTE:
        ld      e, (hl)         ; fetch byte to be saved.
        scf                     ; set carry flag - as a marker.

D_EACH_BIT:
        rl      e               ;  C < 76543210 < C
        ret     z               ; return when the marker bit has passed
                                ; right through.                        >>

        sbc     a, a            ; $FF if set bit or $00 with no carry.
        and     $05             ; $05               $00
        add     a, $04          ; $09               $04
        ld      c, a            ; transfer timer to C. a set bit has a longer
                                ; pulse than a reset bit.

D_PULSES:
        out     ($FF), a        ; end the VSYNC pulse (output=1 during DELAY_5)

        ld      b, $22          ; set timing constant
DELAY_5:
        djnz    DELAY_5         ; self-loop to DELAY-5


        call    CHECK_BREAK     ; test for BREAK key and start VSYNC pulse

        ld      b, $1D          ; set timing value.
DELAY_6:
        djnz    DELAY_6

        dec     c               ; decrement pulse counter
        jp      nz, D_PULSES    ; loop back to D_PULSES

DELAY_7:
        or      a               ; clear carry for next bit test.
        djnz    DELAY_7         ; self loop to DELAY-4 (B is zero - 256)

        jp      D_EACH_BIT

; -----------
; Load buffer
; -----------
; Load a data buffer from tape, return number of bytes read in HL

DLOAD_BUFFER:
        ld      hl, DLOAD_BUFFER
        ld      (iy-7), h       ; save my own address in IY(-8,-7)
        ld      (iy-8), l

        ld      de, 0           ; DE = number of read bytes
        ld      hl, $0BB8       ; wait timer

DLOAD_WAIT_HEADER:
        ld      (iy-9), 0       ; error flags

        push    de              ; * save DE
        call    DLOAD_IN_BYTE   ; carry set if got byte
        pop     de              ; * retore DE

        jp      c, D_GOT_BYTE

        dec     hl              ; decrement header timner
        ld      a, h
        or      l
        jp      nz, DLOAD_WAIT_HEADER

        ld      bc, TOS_TIMEOUT ; exit with timeout error
        jp      DLO_DSA_RET

; Received a byte

D_GOT_BYTE:
        ld      h, (iy-1)       ; get data buffer address
        ld      l, (iy-2)

D_GET_NEXT_BYTE:
        push    hl              ; * save data buffer address

        ld      h, (iy-3)       ; get data buffer size
        ld      l, (iy-4)

        scf
        sbc     hl, de          ; HL = size-read_bytes-1

        pop     hl              ; * restore data buffer address

        jp      m, DLOAD_SKIP_BYTES
                                ; jump if read_bytes >= size

        inc     de              ; count bytes read
        ld      (hl), c         ; store byte read in buffer
        inc     hl              ; and advance buffer pointer

        push    de              ; get next byte
        call    DLOAD_IN_BYTE
        pop     de
        jp      c, D_GET_NEXT_BYTE

D_NO_MORE_BYTES:
        ld      bc, TOS_OK
        ld      a, (iy-9)       ; get timeout flags
        or      a
        jp      z, DLOAD_EXIT   ; all zero -> OK

        add     a, 15           ; move timeout value to BC to return
        ld      c, a
        ld      b, 0

DLOAD_EXIT:
        ex      de, hl          ; return HL = number of bytes loaded
        ret

; tape buffer greater than read size, skip other tape bytes

DLOAD_SKIP_BYTES:
        push    de
        call    DLOAD_IN_BYTE
        pop     de

        jp      c, DLOAD_SKIP_BYTES
                                ; while read bytes

        ld      bc, TOS_READ_OVERFLOW
                                ; exit with read-overflow error
        jp      DLOAD_EXIT


; -----------
; Data Verify
; -----------
; Verifies buffer from tape

DVERIFY:
        call    PREP_DLO_DSA_WS ; set FAST and reserve work space

        ld      hl, DLO_DSA_RET ; save return address
        push    hl

        ld      hl, DVERIFY_BUFFER
        ld      (iy-7), h       ; save my own address in IY(-8,-7)
        ld      (iy-8), l

DVERIFY_BUFFER:
        ld      de, 0           ; DE = number of read bytes
        ld      hl, $0BB8       ; wait timer

DVERIFY_WAIT_HEADER:
        ld      (iy-9), 0       ; error flags

        push    de              ; * save DE
        call    DLOAD_IN_BYTE   ; carry set if got byte
        pop     de              ; * retore DE

        jp      c, DV_GOT_BYTE

        dec     hl              ; decrement header timner
        ld      a, h
        or      l
        jp      nz, DVERIFY_WAIT_HEADER

        ld      bc, TOS_TIMEOUT ; exit with timeout error
        jp      DLO_DSA_RET

; Received a byte

DV_GOT_BYTE:
        inc     de              ; count bytes read

        push    de              ; get next byte
        call    DLOAD_IN_BYTE
        pop     de

        jp      c, DV_GOT_BYTE
        jp      D_NO_MORE_BYTES

; ---------------------------
; THE DATA IN BYTE SUBROUTINE
; ---------------------------

DLOAD_IN_BYTE:
        ld      c, $01          ; prepare an eight counter 00000001.

DLOAD_NEXT_BIT:
        ld      b, $00          ; set counter to 256

DLOAD_WAIT_BIT:
        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.

        out     ($FF), a        ; output signal to screen.

        bit     7, a            ; test tape signal
        jp      nz, DLOAD_GET_BIT
                                ; tape=1 -> found pulse

        rrca                    ; test BREAK key

        jp      nc, BREAK_PRESSED_1

        djnz    DLOAD_WAIT_BIT

        dec     c
        jp      nz, DLOAD_TIMEOUT
                                ; C has data read from tape, timeout reading

        or      a               ; clear carry and return if no byte received
        ret

; exit if BREAK pressed

BREAK_PRESSED_1:
        pop     hl              ; drop two return addresses, go back to DLOAD level
        pop     hl

        ld      a, ERR_D_BREAK  ; signal BREAK-pressed error
        ld      (ERR_NR), a

        ld      bc, TOS_BREAK_PRESSED
        ret

DLOAD_GET_BIT:
        ld      de, $FFBF       ; timing value

DLOAD_TRAILER:
        ld      b, $1E          ; counter

DLOAD_COUNTER:
        inc     de              ; increment timer
        in      a, ($FE)        ; read tape port
        rlca                    ; test bit 7 = tape

        jp      c, DLOAD_TRAILER; found signal, loop back to trailer

        djnz    DLOAD_COUNTER   ; wait for next pulse

        ld      a, d            ; get counter-high
        rlca                    ; test bit 15

        jp      c, DLOAD_NEXT_BIT
                                ; if 1, then a pulse was received before DE reaching 0

        ld      a, $0A
        cp      e

        jp      c, DLOAD_TIMER_BIT_0
                                ; jump if 10 < timer

        set     0, (iy-9)       ; timer <= 10

DLOAD_TIMER_BIT_0:
        ld      a, $50
        cp      e
        jp      nc, DLOAD_UPDATE_COUNTER
                                ; jump if 80 <= timer

        ld      a, $6E
        cp      e

        jp      c, DLOAD_TIMER_BIT_1
                                ; jump if 110 < timer

        set     1, (iy-9)       ; timer <= 110

DLOAD_TIMER_BIT_1:
        ld      a, $D7
        cp      e
        jp      nc, DLOAD_TIMER_BIT_2
                                ; jump if 215 <= timer

        set     2, (iy-9)       ; timer < 215

DLOAD_TIMER_BIT_2:
        scf

; enter with carry clear if timer >= 80, carry set if timer > 80

DLOAD_UPDATE_COUNTER:
        ld      a, c            ; initially = 1
        adc     a, c            ; rotate left and add carry (read bit) to bit 0
        ld      c, a            ; store new byte

        jp      nc, DLOAD_NEXT_BIT
                                ; while marker bit does not enter carry, i.e. 8 times

        ret                     ; return with carry set if got a byte

; timeout in the middle of reading a byte

DLOAD_TIMEOUT:
        pop     bc              ; pop two return addresses
        pop     de

        ld      hl, $FFD8
        add     hl, de
        jp      nc, DLOAD_RE_ENTER
                                ; re-enter load if timer < -40

        push    de              ; restore return addresses
        push    bc
        or      a               ; clear carry and return if no bit received
        ret

; Jump back to the address of my load routine

DLOAD_RE_ENTER:
        ld      h, (iy-7)       ; jump to my routine again
        ld      l, (iy-8)
        jp      (hl)

; -------------
; Silence delay
; -------------
; Wait in silence, input loop counter in BC

SILENCE_DELAY_BC:
        push    af              ; * save AF and HL
        push    hl

SV_LOOP_2:
        push    bc              ; * save delay counter

        ld      b, $EF          ; delay
SV_LOOP_1:
        djnz    SV_LOOP_1

        call    CHECK_BREAK     ; check if BREAK pressed

        pop     bc              ; * restore delay counter

        dec     bc
        ld      a, b
        or      c
        jp      nz, SV_LOOP_2   ; decrement and repeat while not zero

        pop     hl
        pop     af              ; * restore AF and HL
        ret

; -------------------------
; Check if BREAK is pressed
; -------------------------
; Exit via error if BREAK key is pressed

CHECK_BREAK:
        push    hl

        ld      a, $7F          ; read the keyboard row
        in      a, ($FE)        ; with the SPACE key.
        rra                     ; test for SPACE pressed.

        ld      hl, CDFLAG
        res     0, (hl)         ; signal no key available

        ld      a, ($00FF)      ; Note: ??? A = $87
        ld      (DB_ST), a

        pop     hl
        ret     c               ; Break not pressed

; error - BREAK pressed

        ld      a, ERR_D_BREAK
        ld      (ERR_NR), a

        ld      bc, TOS_BREAK_PRESSED
        jp      DLO_DSA_RET

; ---------------------------
; GET BUFFER SIZE AND ADDRESS
; ---------------------------
; Read variable Z$ and get name of buffer x
; Read variable x$() and get buffer address and size
; Store address in IY(-2,-1), size in IY(-4,-3)
; Returns if OK; else skips caller address and returns error.

GET_BUFFER:
        ld      a, ERR_H_INVALID_BUFFER
                                ; prepare for REPORT I
        ld      (ERR_NR), a

; search for Z$

        ld      a, +('Z' - 27) & $1F
                                ; search Z$ or Z$() variable (bit 5=0)
        call    SEARCH_VAR

        cp      $80             ; found end marker $80 - Z$ undefined error
        ld      bc, TOS_ZDOLLAR_UNDEF
        jr      z, DLO_DSA_RET_1

        or      a               ; found string array Z$() - error
        ld      bc, TOS_ZDOLLAR_IS_ARR
        jr      z, DLO_DSA_RET_1

        ld      a, (hl)         ; Z$ found, check length
        inc     hl
        or      (hl)
        ld      bc, TOS_ZDOLLAR_EMPTY
        jr      z, DLO_DSA_RET_1; error - empty Z$

; read Z$ - must contain name of string array to be used as buffer

        inc     hl              ; point at Z$ data
        ld      a, (hl)         ; read first character
        ld      bc, TOS_ZDOLLAR_INVALID

        cp      'A' - 27
        jr      c, DLO_DSA_RET_1; character < 'A' -> error

        cp      'Y' - 27 + 1
        jr      nc, DLO_DSA_RET_1
                                ; character >= 'Y' -> error

; get string buffer

        sub     20h             ; clear bit 5 -> search for x$ or x$()
        call    SEARCH_VAR

        cp      $80             ; found end marker $80 - buffer undefined error
        ld      bc, TOS_BUFFER_UNDEF
        jr      z, DLO_DSA_RET_1

        or      a               ; found string x$ - error
        ld      bc, TOS_BUFFER_IS_STR
        jr      nz, DLO_DSA_RET_1

        inc     hl              ; have a x$(); advance past total length
        inc     hl

        ld      a, (hl)         ; get number of dimensions
        cp      1
        ld      bc, TOS_BUFFER_IS_MULTI_DIMENSIONAL
        jr      nz, DLO_DSA_RET_1
                                ; error if multi-dimensional

        inc     hl              ; point to dimension size
        ld      e, (hl)         ; DE = buffer size
        inc     hl
        ld      d, (hl)
        inc     hl              ; HL = buffer address

        ld      (iy-3), d       ; save buffer size in Frame (-4,-3)
        ld      (iy-4), e
        ld      (iy-1), h       ; save buffer address in Frame (-2,-1)
        ld      (iy-2), l

        ld      a, ERR_0_OK
        ld      (ERR_NR), a
        ret

DLO_DSA_RET_1:
        jp      DLO_DSA_RET

; -----------
; GET Z VALUE
; -----------
; Read variable Z and get address of number
; Store number address in IY(-6,-5), return in HL
; Returns if OK; else skips caller address and returns error.

GET_Z_VALUE:
        ld      a, +('Z' - 27) & $3F
                                ; search Z numeric variable (bit 5=1)
        call    SEARCH_VAR

        ld      bc, TOS_Z_UNDEF
        cp      $80             ; check for end marker
        jr      z, DLO_DSA_RET_1; error if end marker found

        inc     hl              ; hl = location of Z variable data

        ld      (iy-5), h       ; store in Frame (-6,-5)
        ld      (iy-6), l
        ret

; ---------------------
; SEARCH BASIC VARIABLE
; ---------------------
; Search BASIC variable in A (if input has bit 5=0) or A$() or A$ (if input has bit 5=1)
; - if not found, return A = $80 end marker, HL poiting at marker
; - if number or string return A = variable code in VARS, HL poiting at length field
; - if string array return A = 0, HL poiting at length field
; See comment on ZX-81 User VARIABLES to follow this code

SEARCH_VAR:
        ld      hl, (VARS)
        ld      c, a            ; save variable to search in C

SEARCH_VAR_NEXT:
        ld      a, (hl)         ; check for end marker $80
        cp      $80
        ret     z               ; return HL pointing at the end marker

        and     $C0             ; check bits 7 and 6
        ld      a, c            ; restore letter
        ld      bc, TOS_VARS_ERROR

        jr      z, DLO_DSA_RET_1; %00x - invalid

        ld      c, a            ; save variable to search

        ld      a, (hl)
        and     20h             ; check bit 5
        jr      z, VAR_IS_STR_OR_ARR
                                ; bit 5 = 0 - array or string

        ld      a, (hl)         ; check bit 7
        rla
        jr      nc, VAR_IS_NUMBER
                                ; bit 7=0 & bit 5=1

        rla                     ; check bit 6
        ld      e, 1+3*5+2      ; size of FOR-NEXT variable
        jr      c, VAR_SKIP_E   ; bit 7=1 & bit 6=1 & bit 5=1 - FOR-NEXT variable

VAR_SKIP_NAME:                  ; bit 7=1 & bit 6=0 & bit 5=1 - long number variable
                                ; last char has bit 7=1
        inc     hl
        ld      a, (hl)
        rla
        jr      nc, VAR_SKIP_NAME
                                ; loop while bit 7=0
        jr      VAR_SKIP_NUMBER

; Found a number variable with one letter only - %011 vvvvv
; Return if it is the search variable, or skip to next variable otherwise

VAR_IS_NUMBER:
        rra                     ; restore A
        xor     c               ; compare with letter being searched
        and     3fh             ; keep only lower 5 bits - letter code
        ret     z               ; return if found number variable

VAR_SKIP_NUMBER:
        ld      e, 1+5          ; advance past letter code and value

VAR_SKIP_E:
        ld      d, 0

VAR_SKIP_DE:
        add     hl, de          ; skip to next variable
        jr      SEARCH_VAR_NEXT

; Found a string or number array, or a string variable - %xx0 vvvvv

VAR_IS_STR_OR_ARR:
        ld      a, (hl)
        and     40h             ; check bit 6
        jr      z, VAR_IS_NUMARR
                                ; bit 6=0 & bit 5=0 - array of numbers

; bit 6=1 & bit 5=0 - string or array of chars

        ld      a, (hl)         ; restore A
        xor     c               ; compare with letter being searched
        and     3fh             ; keep only lower 5 bits - letter code
        jr      z, VAR_FOUND_STR_OR_STRARR
                                ; return if found string variable

VAR_IS_NUMARR:
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        jr      VAR_SKIP_DE

VAR_FOUND_STR_OR_STRARR:
        ld      a, (hl)         ; restore A
        or      a
        inc     hl              ; point at length
        ret     p               ; end if bit 7=0 - string
        xor     a               ; A = 0 for string array
        ret

;---

; Signature
        defb    $34
        defb    $20
        defb    $41
#endif
