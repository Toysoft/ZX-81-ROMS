; =========================================================
; An Assembly Listing of the "Shoulders of Giants" ZX81 ROM
; =========================================================
; -------------------------
; Last updated: 23-OCT-2003
; -------------------------
;
;   The "Shoulders of Giants" ZX81 ROM.
;   This file shows the altered sections of the ZX81/TS1000 ROM that produced 
;   the customized sg81.rom.
;   The main feature is the inclusion of Newton Raphson square roots.
;   The square roots are executed 3 times faster than those in the 
;   standard ROM. They are more accurate also and
;
;   PRINT SQR 100 = INT SQR 100 gives the result 1 (true) not 0 (false)
;
;   The input and storage of fractional numbers is improved
;
;   PRINT 1/2 = .5 gives the result 1 (true) and not 0 (false) 
;
;   The output of fractional numbers to the ZX Printer is corrected
;
;   LPRINT .00001 gives the output .00001 and not .0XYZ1
;
;   Other alterations have been made to create the space required by the
;   new square root routine and some are obscure and would not otherwise have 
;   been made.
;   Using uncompressed constants rectifies a logic error and improves speed.

#define DEFB .BYTE      ; TASM cross-assembler definitions
#define DEFW .WORD
#define EQU  .EQU
#define ORG  .ORG


;   the backward references
					
subtract   EQU     $174C           ; SUBTRACT
multiply   EQU     $176C           ; multiply
division   EQU     $1882           ; division
addition   EQU     $1755           ; addition
truncate   EQU     $18E4           ; truncate
e_to_fp    EQU     $155A           ; e-to-fp
TEST_ROOM  EQU     $0EC5           ; TEST-ROOM
FIND_INT   EQU     $0EA7           ; FIND-INT
STACK_A    EQU     $151D           ; STACK-A
STACK_BC   EQU     $1520           ; STACK-BC
STK_FETCH  EQU     $13F8           ; STK-FETCH
STK_STO_s  EQU     $12C3           ; STK-STO-$
FP_TO_A    EQU     $15CD           ; FP-TO-A
CLASS_06   EQU     $0D92           ; CLASS-06
CHECK_2    EQU     $0D22           ; CHECK-2
SCANNING   EQU     $0F55           ; SCANNING
PRINT_FP   EQU     $15DB           ; PRINT-FP

; -----------------------------------------------------------------------------

ORG $0010

;--------------------------------
; THE 'PRINT A CHARACTER' RESTART
;--------------------------------
; This restart prints the character in the accumulator using the alternate
; register set so there is no requirement to save the main registers.
; There is sufficient room available to separate a space (zero) from other
; characters as leading spaces need not be considered with a space.
; Note. the accumulator is preserved only when printing to the screen.

PRINT_A   AND   A               ; test for zero - space.
          JP    NZ,PRINT_CH     ; jump forward if not to PRINT-CH.

          JP    PRINT_SP        ; jump forward to PRINT-SP.

; ---

          DEFB  $01             ;+ unused location. Version. PRINT PEEK 23

; -----------------------------------------------------------------------------

ORG $0028


; -----------------------  
; THE 'CALCULATE' RESTART
; -----------------------  
;   An immediate jump is made to the CALCULATE routine the address of which 
;   has changed.

FP_CALC   JP    CALCULATE       ;+ jump to the NEW calculate routine address.

end_calc  POP   AF              ; drop the calculator return address RE-ENTRY
          EXX                   ; switch to the other set.

          EX    (SP),HL         ; transfer H'L' to machine stack for the
                                ; return address.
                                ; when exiting recursion then the previous
                                ; pointer is transferred to H'L'.

          EXX                   ; back to main set.
          RET                   ; return.

; -----------------------------------------------------------------------------

ORG	$13AE 

; ------------------------
; THE 'L-ENTER' SUBROUTINE
; ------------------------
;   Part of the LET command contains a natural subroutine which is a 
;   conditional LDIR. The copy only occurs of BC is non-zero.

L_ENTER   EX    DE,HL           ;


COND_MV   LD    A,B             ;
          OR    C               ;
          RET   Z               ;

          PUSH  DE              ;

          LDIR                  ; Copy Bytes

          POP   HL              ;
          RET                   ; Return.

; -----------------------------------------------------------------------------

ORG $14E5

; ---------------------
; THE 'NEXT DIGIT' LOOP
; ---------------------
;   Within the 'DECIMAL TO FLOATING POINT' routine, swapping the multiply and
;   divide literals preserves accuracy and ensures that .5 is evaluated 
;   as 5/10 and not as .1 * 5.

NXT_DGT_1 RST     20H             ; NEXT-CHAR
          CALL    $1514           ; routine STK-DIGIT
          JR      C,$14F5         ; forward to E-FORMAT


          RST     28H             ;; FP-CALC
          DEFB    $E0             ;;get-mem-0
          DEFB    $A4             ;;stk-ten
;;;       DEFB    $05             ;;division
          DEFB    $04             ;;+multiply
          DEFB    $C0             ;;st-mem-0
;;;       DEFB    $04             ;;multiply
          DEFB    $05             ;;+division
          DEFB    $0F             ;;addition
          DEFB    $34             ;;end-calc

          JR      NXT_DGT_1       ; loop back till exhausted to NXT-DGT-1

; -----------------------------------------------------------------------------

ORG $16B2

; -------------------------------------
; THE 'FLOATING POINT PRINT ZEROS' LOOP
; -------------------------------------

; This branch deals with zeros after decimal point.
; e.g.      .01 or .0000999
; Note. that printing to the ZX Printer destroys A and that A should be 
; initialized to '0' at each stage of the loop.
; Originally LPRINT .00001 printed as .0XYZ1

PF_ZEROS  NEG                   ; negate makes number positive 1 to 4.
          LD    B,A             ; zero count to B.

          LD    A,$1B           ; prepare character '.'
          RST   10H             ; PRINT-A

PF_ZRO_LP LD    A,$1C           ; prepare a '0' in the accumulator each time.

PFZROLP   RST   10H             ; PRINT-A

          DJNZ  PF_ZRO_LP       ;+ New loop back to PF-ZRO-LP

;;;       DJNZ  PFZROLP         ; obsolete loop back to PFZROLP


;   and continue with trailing fractional digits...

; -----------------------------------------------------------------------------

ORG     $1915


;   Up to this point all routine addresses have been maintained so that the
;   modified ROM is compatible with any machine-code software that uses ROM
;   routines.
;   The final section does not maintain address entry points as the routines
;   within are not generally called directly.

;********************************
;**  FLOATING-POINT CALCULATOR **
;********************************

;   As a general rule the calculator avoids using the IY register.
;   The exception is the 'val' function.
;   So an assembly language programmer who has disabled interrupts to use IY
;   for other purposes can still use the calculator for mathematical
;   purposes.


; ------------------------
; THE 'TABLE OF CONSTANTS'
; ------------------------
;   The ZX81 has only floating-point number representation.
;   Both the ZX80 and the ZX Spectrum have integer numbers in some form.
;   This table has been modified so that the constants are held in their
;   uncompressed, ready-to-party, 5-byte form.

;;; L1915:  DEFB    $00             ;;Bytes: 1
;;;         DEFB    $B0             ;;Exponent $00
;;;         DEFB    $00             ;;(+00,+00,+00)
;;; L1918:  DEFB    $31             ;;Exponent $81, Bytes: 1
;;;         DEFB    $00             ;;(+00,+00,+00)
;;; L191A:  DEFB    $30             ;;Exponent: $80, Bytes: 1
;;;         DEFB    $00             ;;(+00,+00,+00)
;;; L191C:  DEFB    $F1             ;;Exponent: $81, Bytes: 4
;;;         DEFB    $49,$0F,$DA,$A2 ;;
;;; L1921:  DEFB    $34             ;;Exponent: $84, Bytes: 1
;;;         DEFB    $20             ;;(+00,+00,+00)

TAB_CNST  DEFB  $00           ; the value zero.
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;

          DEFB  $81           ; the floating point value 1.
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;

          DEFB  $80           ; the floating point value 1/2.
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;

          DEFB  $81           ; the floating point value pi/2.
          DEFB  $49           ;
          DEFB  $0F           ;
          DEFB  $DA           ;
          DEFB  $A2           ;

          DEFB  $84           ; the floating point value ten.
          DEFB  $20           ;
          DEFB  $00           ;
          DEFB  $00           ;
          DEFB  $00           ;

; ------------------------
; THE 'TABLE OF ADDRESSES'
; ------------------------
;
;   Starts with binary operations which have two operands and one result.
;   three pseudo binary operations first.

tbl_addrs DEFW  jump_true       ; $00 Address: $1C2F - jump-true
          DEFW  exchange        ; $01 Address: $1A72 - exchange
          DEFW  delete          ; $02 Address: $19E3 - delete

;   true binary operations.

          DEFW  subtract        ; $03 Address: $174C - subtract
          DEFW  multiply        ; $04 Address: $176C - multiply
          DEFW  division        ; $05 Address: $1882 - division
          DEFW  to_power        ; $06 Address: $1DE2 - to-power
          DEFW  or              ; $07 Address: $1AED - or

          DEFW  no_v_no         ; $08 Address: $1B03 - no-&-no
          DEFW  no_l_eql        ; $09 Address: $1B03 - no-l-eql
          DEFW  no_l_eql        ; $0A Address: $1B03 - no-gr-eql
          DEFW  no_l_eql        ; $0B Address: $1B03 - nos-neql
          DEFW  no_l_eql        ; $0C Address: $1B03 - no-grtr
          DEFW  no_l_eql        ; $0D Address: $1B03 - no-less
          DEFW  no_l_eql        ; $0E Address: $1B03 - nos-eql
          DEFW  addition        ; $0F Address: $1755 - addition

          DEFW  str_v_no        ; $10 Address: $1AF8 - str-&-no
          DEFW  no_l_eql        ; $11 Address: $1B03 - str-l-eql
          DEFW  no_l_eql        ; $12 Address: $1B03 - str-gr-eql
          DEFW  no_l_eql        ; $13 Address: $1B03 - strs-neql
          DEFW  no_l_eql        ; $14 Address: $1B03 - str-grtr
          DEFW  no_l_eql        ; $15 Address: $1B03 - str-less
          DEFW  no_l_eql        ; $16 Address: $1B03 - strs-eql
          DEFW  strs_add        ; $17 Address: $1B62 - strs-add

;   unary follow

          DEFW  negate          ; $18 Address: $1AA0 - neg

          DEFW  code            ; $19 Address: $1C06 - code
          DEFW  val             ; $1A Address: $1BA4 - val
          DEFW  len             ; $1B Address: $1C11 - len
          DEFW  sin             ; $1C Address: $1D49 - sin
          DEFW  cos             ; $1D Address: $1D3E - cos
          DEFW  tan             ; $1E Address: $1D6E - tan
          DEFW  asn             ; $1F Address: $1DC4 - asn
          DEFW  acs             ; $20 Address: $1DD4 - acs
          DEFW  atn             ; $21 Address: $1D76 - atn
          DEFW  ln              ; $22 Address: $1CA9 - ln
          DEFW  exp             ; $23 Address: $1C5B - exp
          DEFW  int             ; $24 Address: $1C46 - int
          DEFW  sqr             ; $25 Address: $1DDB - sqr
          DEFW  sgn             ; $26 Address: $1AAF - sgn
          DEFW  abs             ; $27 Address: $1AAA - abs
          DEFW  peek            ; $28 Address: $1A1B - peek
          DEFW  usr_no          ; $29 Address: $1AC5 - usr-no
          DEFW  strS            ; $2A Address: $1BD5 - str$
          DEFW  chrS            ; $2B Address: $1B8F - chrs
          DEFW  not             ; $2C Address: $1AD5 - not

;   end of true unary

          DEFW  MOVE_FP         ; $2D Address: $19F6 - duplicate
          DEFW  n_mod_m         ; $2E Address: $1C37 - n-mod-m

          DEFW  JUMP            ; $2F Address: $1C23 - jump
          DEFW  stk_data        ; $30 Address: $19FC - stk-data

          DEFW  dec_jr_nz       ; $31 Address: $1C17 - dec-jr-nz
          DEFW  less_0          ; $32 Address: $1ADB - less-0
          DEFW  greater_0       ; $33 Address: $1ACE - greater-0
          DEFW  end_calc        ; $34 Address: $002B - end-calc
          DEFW  get_argt        ; $35 Address: $1D18 - get-argt
          DEFW  truncate        ; $36 Address: $18E4 - truncate
          DEFW  fp_calc_2       ; $37 Address: $19E4 - fp-calc-2
          DEFW  e_to_fp         ; $38 Address: $155A - e-to-fp

;   the following are just the next available slots for the 128 compound 
;   literals which are in range $80 - $FF.

          DEFW  seriesg_x       ; $39 Address: $1A7F - series-xx    $80 - $9F.
          DEFW  stk_con_x       ; $3A Address: $1A51 - stk-const-xx $A0 - $BF.
          DEFW  sto_mem_x       ; $3B Address: $1A63 - st-mem-xx    $C0 - $DF.
          DEFW  get_mem_x       ; $3C Address: $1A45 - get-mem-xx   $E0 - $FF.

; -------------------------------
; THE 'FLOATING POINT CALCULATOR'
; -------------------------------
;
;

CALCULATE CALL  STK_PNTRS       ; routine STK-PNTRS is called to set up the
                                ; calculator stack pointers for a default
                                ; unary operation. HL = last value on stack.
                                ; DE = STKEND first location after stack.

;   the calculate routine is called at this point by the series generator...

GEN_ENT_1 LD    A,B             ; fetch the Z80 B register to A
          LD    ($401E),A       ; and store value in system variable BREG.
                                ; this will be the counter for dec-jr-nz
                                ; or if used from fp-calc2 the calculator
                                ; instruction.

;   ... and again later at this point

GEN_ENT_2 EXX                   ; switch sets
          EX    (SP),HL         ; and store the address of next instruction,
                                ; the return address, in H'L'.
                                ; If this is a recursive call then the H'L'
                                ; of the previous invocation goes on stack.
                                ; c.f. end-calc.
          EXX                   ; switch back to main set.

;   this is the re-entry looping point when handling a string of literals.

RE_ENTRY  LD    ($401C),DE      ; save end of stack in system variable STKEND
          EXX                   ; switch to alt
          LD    A,(HL)          ; get next literal
          INC   HL              ; increase pointer'

;   single operation jumps back to here

SCAN_ENT  PUSH  HL              ; save pointer on stack   *
          AND   A               ; now test the literal
          JP    P,FIRST_3D      ; forward to FIRST-3D if in range $00 - $3D
                                ; anything with bit 7 set will be one of
                                ; 128 compound literals.

;   Compound literals have the following format.
;   bit 7 set indicates compound.
;   bits 6-5 the subgroup 0-3.
;   bits 4-0 the embedded parameter $00 - $1F.
;   The subgroup 0-3 needs to be manipulated to form the next available four
;   address places after the simple literals in the address table.

          LD    D,A             ; save literal in D
          AND   $60             ; and with 01100000 to isolate subgroup
          RRCA                  ; rotate bits
          RRCA                  ; 4 places to right
          RRCA                  ; not five as we need offset * 2
          RRCA                  ; 00000xx0
          ADD   A,$72           ; add ($39 * 2) to give correct offset.
                                ; alter above if you add more literals.
          LD    L,A             ; store in L for later indexing.
          LD    A,D             ; bring back compound literal
          AND   $1F             ; use mask to isolate parameter bits
          JR    ENT_TABLE       ; forward to ENT-TABLE

; ---

;   the branch was here with simple literals.

FIRST_3D  CP    $18             ; compare with first unary operations.
          JR    NC,DOUBLE_A     ; to DOUBLE-A with unary operations

;   it is binary so adjust pointers.

          EXX                   ;
          LD    BC,$FFFB        ; the value -5
          LD    D,H             ; transfer HL, the last value, to DE.
          LD    E,L             ;
          ADD   HL,BC           ; subtract 5 making HL point to second
                                ; value.
          EXX                   ;

DOUBLE_A  RLCA                  ; double the literal
          LD    L,A             ; and store in L for indexing

ENT_TABLE LD    DE,tbl_addrs    ; Address: tbl-addrs
          LD    H,$00           ; prepare to index
          ADD   HL,DE           ; add to get address of routine
          LD    E,(HL)          ; low byte to E
          INC   HL              ;
          LD    D,(HL)          ; high byte to D

          LD    HL,RE_ENTRY     ; Address: RE-ENTRY
          EX    (SP),HL         ; goes on machine stack
                                ; address of next literal goes to HL. *


          PUSH  DE              ; now the address of routine is stacked.
          EXX                   ; back to main set
                                ; avoid using IY register.
          LD    BC,($401D)      ; STKEND_hi
                                ; nothing much goes to C but BREG to B
                                ; and continue into next ret instruction
                                ; which has a dual identity


; -----------------------
; THE 'DELETE' SUBROUTINE
; -----------------------
; (offset $02: 'delete')
;   A simple return but when used as a calculator literal this
;   deletes the last value from the calculator stack.
;   On entry, as always with binary operations,
;   HL=first number, DE=second number
;   On exit, HL=result, DE=stkend.
;   So nothing to do

delete    RET                   ; return - indirect jump if from above.

; ---------------------------------
; THE 'SINGLE OPERATION' SUBROUTINE
; ---------------------------------
;   offset $37: 'fp-calc-2'
;   this single operation is used, in the first instance, to evaluate most
;   of the mathematical and string functions found in BASIC expressions.

fp_calc_2 POP   AF              ; drop return address.
          LD    A,($401E)       ; load accumulator from system variable BREG
                                ; value will be literal eg. 'tan'
          EXX                   ; switch to alt
          JR    SCAN_ENT        ; back to SCAN-ENT
                                ; next literal will be end-calc in scanning

; ------------------------------
; THE 'TEST 5 SPACES' SUBROUTINE
; ------------------------------
;   This routine is called from MOVE-FP, STK-CONST and STK-STORE to
;   test that there is enough space between the calculator stack and the
;   machine stack for another five-byte value. It returns with BC holding
;   the value 5 ready for any subsequent LDIR.

TEST_5_SP PUSH  DE              ; save
          PUSH  HL              ; registers
          LD    BC,$0005        ; an overhead of five bytes
          CALL  TEST_ROOM       ; routine TEST-ROOM tests free RAM raising
                                ; an error if not.
          POP   HL              ; else restore
          POP   DE              ; registers.
          RET                   ; return with BC set at 5.


; ---------------------------------------------
; THE 'MOVE A FLOATING POINT NUMBER' SUBROUTINE
; ---------------------------------------------
; offset $2D: 'duplicate'
;   This simple routine is a 5-byte LDIR instruction
;   that incorporates a memory check.
;   When used as a calculator literal it duplicates the last value on the
;   calculator stack.
;   Unary so on entry HL points to last value, DE to stkend

MOVE_FP   CALL  TEST_5_SP       ; routine TEST-5-SP test free memory
                                ; and sets BC to 5.

          LDIR                  ; copy the five bytes.
          RET                   ; return with DE addressing new STKEND
                                ; and HL addressing new last value.

; -------------------------------
; THE 'STACK LITERALS' SUBROUTINE
; -------------------------------
; offset $30: 'stk-data'
;   When a calculator subroutine needs to put a value on the calculator
;   stack that is not a regular constant this routine is called with a
;   variable number of following data bytes that convey to the routine
;   the floating point form as succinctly as is possible.

stk_data  LD    H,D             ; transfer STKEND
          LD    L,E             ; to HL for result.

STK_CONST CALL  TEST_5_SP       ; routine TEST-5-SP tests that room exists
                                ; and sets BC to $05.

          EXX                   ; switch to alternate set
          PUSH  HL              ; save the pointer to next literal on stack
          EXX                   ; switch back to main set

          EX    (SP),HL         ; pointer to HL, destination to stack.

;;;       PUSH  BC              ; save BC - value 5 from test room. No need.

          LD    A,(HL)          ; fetch the byte following 'stk-data'
          AND   $C0             ; isolate bits 7 and 6
          RLCA                  ; rotate
          RLCA                  ; to bits 1 and 0  range $00 - $03.
          LD    C,A             ; transfer to C
          INC   C               ; and increment to give number of bytes
                                ; to read. $01 - $04
          LD    A,(HL)          ; reload the first byte
          AND   $3F             ; mask off to give possible exponent.
          JR    NZ,FORM_EXP     ; forward to FORM-EXP if it was possible to
                                ; include the exponent.

; else byte is just a byte count and exponent comes next.

          INC   HL              ; address next byte and
          LD    A,(HL)          ; pick up the exponent ( - $50).

FORM_EXP  ADD   A,$50           ; now add $50 to form actual exponent
          LD    (DE),A          ; and load into first destination byte.
          LD    A,$05           ; load accumulator with $05 and
          SUB   C               ; subtract C to give count of trailing
                                ; zeros plus one.
          INC   HL              ; increment source
          INC   DE              ; increment destination
;;;       LD    B,$00           ; prepare to copy. Note. B is zero.
          LDIR                  ; copy C bytes

;;;       POP   BC              ; restore 5 counter to BC.

          EX    (SP),HL         ; put HL on stack as next literal pointer
                                ; and the stack value - result pointer -
                                ; to HL.

          EXX                   ; switch to alternate set.
          POP   HL              ; restore next literal pointer from stack
                                ; to H'L'.
          EXX                   ; switch back to main set.

          LD    B,A             ; zero count to B
          XOR   A               ; clear accumulator

STK_ZEROS DEC   B               ; decrement B counter
          RET   Z               ; return if zero.          >>
                                ; DE points to new STKEND
                                ; HL to new number.

          LD    (DE),A          ; else load zero to destination
          INC   DE              ; increase destination
          JR    STK_ZEROS       ; loop back to STK-ZEROS until done.

; -------------------------------
; THE 'SKIP CONSTANTS' SUBROUTINE
; -------------------------------
; This routine traversed variable-length entries in the table of constants,
; stacking intermediate, unwanted constants onto a dummy calculator stack,
; in the first five bytes of the ZX81 ROM.
; Since the table now uses uncompressed values, some extra ROM space is 
; required for the table but much more is released by getting rid of routines
; like this.

;;; L1A2D:  AND     A               ; test if initially zero.
;;; L1A2E:  RET     Z               ; return if zero.          >>
;;;         PUSH    AF              ; save count.
;;;         PUSH    DE              ; and normal STKEND
;;;         LD      DE,$0000        ; dummy value for STKEND at start of ROM
;;;         CALL    STK_CONST       ; routine STK-CONST works through variable
;;;                                 ; length records.
;;;         POP     DE              ; restore real STKEND
;;;         POP     AF              ; restore count
;;;         DEC     A               ; decrease
;;;         JR      L1A2E           ; loop back to SKIP-NEXT

; --------------------------------
; THE 'MEMORY LOCATION' SUBROUTINE
; --------------------------------
; This routine, when supplied with a base address in HL and an index in A,
; will calculate the address of the A'th entry, where each entry occupies
; five bytes. It is used for addressing floating-point numbers in the
; calculator's memory area.

LOC_MEM   LD    C,A             ; store the original number $00-$1F.
          RLCA                  ; double.
          RLCA                  ; quadruple.
          ADD   A,C             ; now add original value to multiply by five.

          LD    C,A             ; place the result in C.
          LD    B,$00           ; set B to 0.
          ADD   HL,BC           ; add to form address of start of number in HL.

          RET                   ; return.

; -------------------------------------
; THE 'GET FROM MEMORY AREA' SUBROUTINE
; -------------------------------------
; offsets $E0 to $FF: 'get-mem-0', 'get-mem-1' etc.
; A holds $00-$1F offset.
; The calculator stack increases by 5 bytes.
; Note. first two instructions have been swapped to create a subroutine.

get_mem_x LD    HL,($401F)      ; MEM is base address of the memory cells.

INDEX_5   PUSH  DE              ; save STKEND

          CALL  LOC_MEM         ; routine LOC-MEM so that HL = first byte
          CALL  MOVE_FP         ; routine MOVE-FP moves 5 bytes with memory
                                ; check.
                                ; DE now points to new STKEND.
          POP   HL              ; the original STKEND is now RESULT pointer.
          RET                   ; return.

; ---------------------------------
; THE 'STACK A CONSTANT' SUBROUTINE
; ---------------------------------
; (offset $A0: 'stk-zero')
; (offset $A1: 'stk-one')
; (offset $A2: 'stk-half')
; (offset $A3: 'stk-pi/2')
; (offset $A4: 'stk-ten')
; This routine allows a one-byte instruction to stack up to 32 constants
; held in short form in a table of constants. In fact only 5 constants are
; required. On entry the A register holds the literal ANDed with $1F.
;
; It wasn't very efficient and it is better to hold the
; numbers in full, five byte form and stack them in a similar manner
; to that which which is used by the above routine.

stk_con_x LD    HL,TAB_CNST     ; Address: Table of constants.

          JR    INDEX_5         ; and join subsroutine above.

; ---

;;;     LD      H,D             ; save STKEND - required for result
;;;     LD      L,E             ;
;;;     EXX                     ; swap
;;;     PUSH    HL              ; save pointer to next literal
;;;     LD      HL,L1515        ; Address: stk-zero - start of table of
;;;                             ; constants
;;;     EXX                     ;
;;;     CALL    SKIP_CONS       ; routine SKIP-CONS
;;;     CALL    STK_CONST       ; routine STK-CONST
;;;     EXX                     ;
;;;     POP     HL              ; restore pointer to next literal.
;;;     EXX                     ;
;;;     RET                     ; return.

; ---------------------------------------
; THE 'STORE IN A MEMORY AREA' SUBROUTINE
; ---------------------------------------
; Offsets $C0 to $DF: 'st-mem-0', 'st-mem-1' etc.
; Although 32 memory storage locations can be addressed, only six
; $C0 to $C5 are required by the ROM and only the thirty bytes (6*5)
; required for these are allocated. ZX81 programmers who wish to
; use the floating point routines from assembly language may wish to
; alter the system variable MEM to point to 160 bytes of RAM to have
; use the full range available.
; A holds derived offset $00-$1F.
; Unary so on entry HL points to last value, DE to STKEND.

sto_mem_x PUSH  HL              ; save the result pointer.
          EX    DE,HL           ; transfer to DE.
          LD    HL,($401F)      ; fetch MEM the base of memory area.
          CALL  LOC_MEM         ; routine LOC-MEM sets HL to the destination.
          EX    DE,HL           ; swap - HL is start, DE is destination.

;;;       CALL  MOVE_FP         ; routine MOVE-FP.
;;;                             ; Note. a short ld bc,5; ldir
;;;                             ; the embedded memory check is not required
;;;                             ; so these instructions would be faster!

          LD    C,$05           ;+ one extra byte but 
          LDIR                  ;+ faster and no memory check.

          EX    DE,HL           ; DE = STKEND
          POP   HL              ; restore original result pointer
          RET                   ; return.

; -------------------------
; THE 'EXCHANGE' SUBROUTINE
; -------------------------
; offset $01: 'exchange'
; This routine exchanges the last two values on the calculator stack
; On entry, as always with binary operations,
; HL=first number, DE=second number
; On exit, HL=result, DE=stkend.

exchange  LD    B,$05           ; there are five bytes to be swapped

; start of loop.

SWAP_BYTE LD    A,(DE)          ; each byte of second
;;;       LD    C,(HL)          ; each byte of first
;;;       EX    DE,HL           ; swap pointers
          ld    c,a             ;+
          ld    a,(hl)          ;+
          LD    (DE),A          ; store each byte of first
          LD    (HL),C          ; store each byte of second
          INC   HL              ; advance both
          INC   DE              ; pointers.
          DJNZ  SWAP_BYTE       ; loop back to SWAP-BYTE until all 5 done.

;;;       EX    DE,HL           ; even up the exchanges (one byte saved)

          RET                   ; return.

; ---------------------------------
; THE 'SERIES GENERATOR' SUBROUTINE
; ---------------------------------
; offset $86: 'series-06'
; offset $88: 'series-08'
; offset $8C: 'series-0C'
; The ZX81 uses Chebyshev polynomials to generate approximations for
; SIN, ATN, LN and EXP. These are named after the Russian mathematician
; Pafnuty Chebyshev, born in 1821, who did much pioneering work on numerical
; series. As far as calculators are concerned, Chebyshev polynomials have an
; advantage over other series, for example the Taylor series, as they can
; reach an approximation in just six iterations for SIN, eight for EXP and
; twelve for LN and ATN. The mechanics of the routine are interesting but
; for full treatment of how these are generated with demonstrations in
; Sinclair BASIC see "The Complete Spectrum ROM Disassembly" by Dr Ian Logan
; and Dr Frank O'Hara, published 1983 by Melbourne House.

seriesg_x LD    B,A             ; parameter $00 - $1F to B counter
          CALL  GEN_ENT_1       ; routine GEN-ENT-1 is called.
                                ; A recursive call to a special entry point
                                ; in the calculator that puts the B register
                                ; in the system variable BREG. The return
                                ; address is the next location and where
                                ; the calculator will expect its first
                                ; instruction - now pointed to by HL'.
                                ; The previous pointer to the series of
                                ; five-byte numbers goes on the machine stack.

; The initialization phase.

          DEFB  $2D             ;;duplicate       x,x
          DEFB  $0F             ;;addition        x+x
          DEFB  $C0             ;;st-mem-0        x+x
          DEFB  $02             ;;delete          .
          DEFB  $A0             ;;stk-zero        0
          DEFB  $C2             ;;st-mem-2        0

; a loop is now entered to perform the algebraic calculation for each of
; the numbers in the series

G_LOOP    DEFB  $2D             ;;duplicate       v,v.
          DEFB  $E0             ;;get-mem-0       v,v,x+2
          DEFB  $04             ;;multiply        v,v*x+2
          DEFB  $E2             ;;get-mem-2       v,v*x+2,v
          DEFB  $C1             ;;st-mem-1
          DEFB  $03             ;;subtract
          DEFB  $34             ;;end-calc

; the previous pointer is fetched from the machine stack to H'L' where it
; addresses one of the numbers of the series following the series literal.

          CALL  stk_data        ; routine STK-DATA is called directly to
                                ; push a value and advance H'L'.
          CALL  GEN_ENT_2       ; routine GEN-ENT-2 recursively re-enters
                                ; the calculator without disturbing
                                ; system variable BREG
                                ; H'L' value goes on the machine stack and is
                                ; then loaded as usual with the next address.

          DEFB  $0F             ;;addition
          DEFB  $01             ;;exchange
          DEFB  $C2             ;;st-mem-2
          DEFB  $02             ;;delete

          DEFB  $31             ;;dec-jr-nz
          DEFB  G_LOOP - $      ;;back to L1A89, G-LOOP

; when the counted loop is complete the final subtraction yields the result
; for example SIN X.

          DEFB  $E1             ;;get-mem-1
          DEFB  $03             ;;subtract
          DEFB  $34             ;;end-calc

          RET                   ; return with H'L' pointing to location
                                ; after last number in series.

; -----------------------
; Handle unary minus (18)
; -----------------------
; Unary so on entry HL points to last value, DE to STKEND.

negate    LD    A,(HL)          ; fetch exponent of last value on the
                                ; calculator stack.
          AND   A               ; test it.
          RET   Z               ; return if zero.

          INC   HL              ; address the byte with the sign bit.
          LD    A,(HL)          ; fetch to accumulator.
          XOR   $80             ; toggle the sign bit.
          LD    (HL),A          ; put it back.
          DEC   HL              ; point to last value again.
          RET                   ; return.

; -----------------------
; Absolute magnitude (27)
; -----------------------
; This calculator literal finds the absolute value of the last value,
; floating point, on calculator stack.

abs       INC   HL              ; point to byte with sign bit.
          RES   7,(HL)          ; make the sign positive.
          DEC   HL              ; point to last value again.
          RET                   ; return.

; -----------
; Signum (26)
; -----------
; This routine replaces the last value on the calculator stack,
; (which is in floating point form), with one if positive and with minus one
; if it is negative. If it is zero then it is left unchanged.

sgn       INC   HL              ; point to first byte of 4-byte mantissa.
          LD    A,(HL)          ; pick up the byte with the sign bit.
          DEC   HL              ; point to exponent.
          DEC   (HL)            ; test the exponent for
          INC   (HL)            ; the value zero.

          SCF                   ; Set the carry flag.
          CALL  NZ,FP_0_1       ; Routine FP-0/1  replaces last value with one
                                ; if exponent indicates the value is non-zero.
                                ; In either case mantissa is now four zeros.

          INC   HL              ; Point to first byte of 4-byte mantissa.
          RLCA                  ; Rotate original sign bit to carry.
          RR    (HL)            ; Rotate the carry into sign.
          DEC   HL              ; Point to last value.
          RET                   ; Return.


; -------------------------
; Handle PEEK function (28)
; -------------------------
; This function returns the contents of a memory address.
; The entire address space can be peeked including the ROM.

peek      CALL  FIND_INT        ; routine FIND-INT puts address in BC.
          LD    A,(BC)          ; load contents into A register.

IN_PK_STK JP    STACK_A         ; exit via STACK-A to put value on the
                                ; calculator stack.

; ---------------
; USR number (29)
; ---------------
; The USR function followed by a number 0-65535 is the method by which
; the ZX81 invokes machine code programs. This function returns the
; contents of the BC register pair.
; Note. that STACK-BC re-initializes the IY register to $4000 if a user-written
; program has altered it.

usr_no    CALL  FIND_INT        ; routine FIND-INT to fetch the
                                ; supplied address into BC.

          LD    HL,STACK_BC     ; address: STACK-BC is
          PUSH  HL              ; pushed onto the machine stack.
          PUSH  BC              ; then the address of the machine code
                                ; routine.

          RET                   ; make an indirect jump to the user's routine
                                ; and, hopefully, to STACK-BC also.


; -----------------------
; Greater than zero ($33)
; -----------------------
; Test if the last value on the calculator stack is greater than zero.
; This routine is also called directly from the end-tests of the comparison
; routine.

greater_0 LD    A,(HL)          ; fetch exponent.
          AND   A               ; test it for zero.
          RET   Z               ; return if so.


          LD    A,$FF           ; prepare XOR mask for sign bit
          JR    SIGN_TO_C       ; forward to SIGN-TO-C
                                ; to put sign in carry
                                ; (carry will become set if sign is positive)
                                ; and then overwrite location with 1 or 0
                                ; as appropriate.

; ------------------------
; Handle NOT operator ($2C)
; ------------------------
; This overwrites the last value with 1 if it was zero else with zero
; if it was any other value.
;
; e.g. NOT 0 returns 1, NOT 1 returns 0, NOT -3 returns 0.
;
; The subroutine is also called directly from the end-tests of the comparison
; operator.

not       LD    A,(HL)          ; get exponent byte.
          NEG                   ; negate - sets carry if non-zero.
          CCF                   ; complement so carry set if zero, else reset.
          JR    FP_0_1          ; forward to FP-0/1.

; -------------------
; Less than zero (32)
; -------------------
; Destructively test if last value on calculator stack is less than zero.
; Bit 7 of second byte will be set if so.

less_0    XOR   A               ; set xor mask to zero
                                ; (carry will become set if sign is negative).

; transfer sign of mantissa to Carry Flag.

SIGN_TO_C INC   HL              ; address 2nd byte.
          XOR   (HL)            ; bit 7 of HL will be set if number is negative.
          DEC   HL              ; address 1st byte again.
          RLCA                  ; rotate bit 7 of A to carry.

; -----------
; Zero or one
; -----------
; This routine places an integer value zero or one at the addressed location
; of calculator stack or MEM area. The value one is written if carry is set on
; entry else zero.

FP_0_1    PUSH  HL              ; save pointer to the first byte
          LD    B,$05           ; five bytes to do.

FP_loop   LD    (HL),$00        ; insert a zero.
          INC   HL              ;
          DJNZ  FP_loop         ; repeat.

          POP   HL              ;
          RET   NC              ;

          LD    (HL),$81        ; make value 1
          RET                   ; return.


; -----------------------
; Handle OR operator (07)
; -----------------------
; The Boolean OR operator. eg. X OR Y
; The result is zero if both values are zero else a non-zero value.
;
; e.g.    0 OR 0  returns 0.
;        -3 OR 0  returns -3.
;         0 OR -3 returns 1.
;        -3 OR 2  returns 1.
;
; A binary operation.
; On entry HL points to first operand (X) and DE to second operand (Y).

or        LD    A,(DE)          ; fetch exponent of second number
          AND   A               ; test it.
          RET   Z               ; return if zero.

          SCF                   ; set carry flag
          JR    FP_0_1          ; back to FP-0/1 to overwrite the first operand
                                ; with the value 1.


; -----------------------------
; Handle number AND number (08)
; -----------------------------
; The Boolean AND operator.
;
; e.g.    -3 AND 2  returns -3.
;         -3 AND 0  returns 0.
;          0 and -2 returns 0.
;          0 and 0  returns 0.
;
; Compare with OR routine above.

no_v_no   LD    A,(DE)          ; fetch exponent of second number.
          AND   A               ; test it.
          RET   NZ              ; return if not zero.

          JR    FP_0_1          ; back to FP-0/1 to overwrite the first operand
                                ; with zero for return value.

; -----------------------------
; Handle string AND number (10)
; -----------------------------
; e.g. "YOU WIN" AND SCORE>99 will return the string if condition is true
; or the null string if false.

str_v_no  LD    A,(DE)          ; fetch exponent of second number.
          AND   A               ; test it.
          RET   NZ              ; return if number was not zero - the string
                                ; is the result.

; if the number was zero (false) then the null string must be returned by
; altering the length of the string on the calculator stack to zero.

          PUSH  DE              ; save pointer to the now obsolete number
                                ; (which will become the new STKEND)

          DEC   DE              ; point to the 5th byte of string descriptor.
          XOR   A               ; clear the accumulator.
          LD    (DE),A          ; place zero in high byte of length.
          DEC   DE              ; address low byte of length.
          LD    (DE),A          ; place zero there - now the null string.

          POP   DE              ; restore pointer - new STKEND.
          RET                   ; return.

; -------------------------------------
; Perform comparison ($09-$0E, $11-$16)
; -------------------------------------
; True binary operations.
;
; A single entry point is used to evaluate six numeric and six string
; comparisons. On entry, the calculator literal is in the B register and
; the two numeric values, or the two string parameters, are on the
; calculator stack.
; The individual bits of the literal are manipulated to group similar
; operations although the SUB 8 instruction does nothing useful and merely
; alters the string test bit.
; Numbers are compared by subtracting one from the other, strings are
; compared by comparing every character until a mismatch, or the end of one
; or both, is reached.
;
; Numeric Comparisons.
; --------------------
; The 'x>y' example is the easiest as it employs straight-thru logic.
; Number y is subtracted from x and the result tested for greater-0 yielding
; a final value 1 (true) or 0 (false).
; For 'x<y' the same logic is used but the two values are first swapped on the
; calculator stack.
; For 'x=y' NOT is applied to the subtraction result yielding true if the
; difference was zero and false with anything else.
; The first three numeric comparisons are just the opposite of the last three
; so the same processing steps are used and then a final NOT is applied.
;
; literal    Test   No  sub 8       ExOrNot  1st RRCA  exch sub  ?   End-Tests
; =========  ====   == ======== === ======== ========  ==== ===  =  === === ===
; no-l-eql   x<=y   09 00000001 dec 00000000 00000000  ---- x-y  ?  --- >0? NOT
; no-gr-eql  x>=y   0A 00000010 dec 00000001 10000000c swap y-x  ?  --- >0? NOT
; nos-neql   x<>y   0B 00000011 dec 00000010 00000001  ---- x-y  ?  NOT --- NOT
; no-grtr    x>y    0C 00000100  -  00000100 00000010  ---- x-y  ?  --- >0? ---
; no-less    x<y    0D 00000101  -  00000101 10000010c swap y-x  ?  --- >0? ---
; nos-eql    x=y    0E 00000110  -  00000110 00000011  ---- x-y  ?  NOT --- ---
;
;                                                           comp -> C/F
;                                                           ====    ===
; str-l-eql  x$<=y$ 11 00001001 dec 00001000 00000100  ---- x$y$ 0  !or >0? NOT
; str-gr-eql x$>=y$ 12 00001010 dec 00001001 10000100c swap y$x$ 0  !or >0? NOT
; strs-neql  x$<>y$ 13 00001011 dec 00001010 00000101  ---- x$y$ 0  !or >0? NOT
; str-grtr   x$>y$  14 00001100  -  00001100 00000110  ---- x$y$ 0  !or >0? ---
; str-less   x$<y$  15 00001101  -  00001101 10000110c swap y$x$ 0  !or >0? ---
; strs-eql   x$=y$  16 00001110  -  00001110 00000111  ---- x$y$ 0  !or >0? ---
;
; String comparisons are a little different in that the eql/neql carry flag
; from the 2nd RRCA is, as before, fed into the first of the end tests but
; along the way it gets modified by the comparison process. The result on the
; stack always starts off as zero and the carry fed in determines if NOT is
; applied to it. So the only time the greater-0 test is applied is if the
; stack holds zero which is not very efficient as the test will always yield
; zero. The most likely explanation is that there were once separate end tests
; for numbers and strings.

no_l_eql  LD    A,B             ; transfer literal to accumulator.

;;;       SUB   $08             ; subtract eight - which is not useful.

          BIT   2,A             ; isolate '>', '<', '='.

          JR    NZ,EX_OR_NOT    ; skip to EX-OR-NOT with these.

          DEC   A               ; else make $00-$02, $08-$0A to match bits 0-2.

EX_OR_NOT RRCA                  ; the first RRCA sets carry for a swap.
          JR    NC,NU_OR_STR    ; forward to NU-OR-STR with other 8 cases

; for the other 4 cases the two values on the calculator stack are exchanged.

          PUSH  AF              ; save A and carry.
          PUSH  HL              ; save HL - pointer to first operand.
                                ; (DE points to second operand).

          CALL  exchange        ; routine exchange swaps the two values.
                                ; (HL = second operand, DE = STKEND)

          POP   DE              ; DE = first operand
          EX    DE,HL           ; as we were.
          POP   AF              ; restore A and carry.

; Note. it would be better if the 2nd RRCA preceded the string test.
; It would save two duplicate bytes and if we also got rid of that sub 8
; at the beginning we wouldn't have to alter which bit we test.

NU_OR_STR RRCA                  ;+ causes 'eql/neql' to set carry.
          PUSH  AF              ;+ save the carry flag.
          BIT   2,A             ; test if a string comparison.
          JR    NZ,STRINGS      ; forward to STRINGS if so.

; continue with numeric comparisons.

;;;       RRCA                  ; 2nd RRCA causes eql/neql to set carry.
;;;       PUSH    AF            ; save A and carry

          CALL  subtract        ; routine subtract leaves result on stack.
          JR    END_TESTS       ; forward to END-TESTS

; ---

STRINGS     
;;;       RRCA                  ; 2nd RRCA causes eql/neql to set carry.
;;;       PUSH    AF            ; save A and carry.

          CALL  STK_FETCH       ; routine STK-FETCH gets 2nd string params
          PUSH  DE              ; save start2 *.
          PUSH  BC              ; and the length.

          CALL  STK_FETCH       ; routine STK-FETCH gets 1st string
                                ; parameters - start in DE, length in BC.
          POP   HL              ; restore length of second to HL.

; A loop is now entered to compare, by subtraction, each corresponding character
; of the strings. For each successful match, the pointers are incremented and
; the lengths decreased and the branch taken back to here. If both string
; remainders become null at the same time, then an exact match exists.

BYTE_COMP LD    A,H             ; test if the second string
          OR    L               ; is the null string and hold flags.

          EX    (SP),HL         ; put length2 on stack, bring start2 to HL *.
          LD    A,B             ; hi byte of length1 to A

          JR    NZ,SEC_PLUS     ; forward to SEC-PLUS if second not null.

          OR    C               ; test length of first string.

SECND_LOW POP   BC              ; pop the second length off stack.
          JR    Z,BOTH_NULL     ; forward to BOTH-NULL if first string is also
                                ; of zero length.

; the true condition - first is longer than second (SECND-LESS)

          POP   AF              ; restore carry (set if eql/neql)
          CCF                   ; complement carry flag.
                                ; Note. equality becomes false.
                                ; Inequality is true. By swapping or applying
                                ; a terminal 'not', all comparisons have been
                                ; manipulated so that this is success path.
          JR    STR_TEST        ; forward to leave via STR-TEST

; ---
; the branch was here with a match

BOTH_NULL POP   AF              ; restore carry - set for eql/neql
          JR    STR_TEST        ; forward to STR-TEST

; ---
; the branch was here when 2nd string not null and low byte of first is yet
; to be tested.


SEC_PLUS  OR    C               ; test the length of first string.
          JR    Z,FRST_LESS     ; forward to FRST-LESS if length is zero.

; both strings have at least one character left.

          LD    A,(DE)          ; fetch character of first string.
          SUB   (HL)            ; subtract with that of 2nd string.
          JR    C,FRST_LESS     ; forward to FRST-LESS if carry set

          JR    NZ,SECND_LOW    ; back to SECND-LOW and then STR-TEST
                                ; if not exact match.

          DEC   BC              ; decrease length of 1st string.
          INC   DE              ; increment 1st string pointer.

          INC   HL              ; increment 2nd string pointer.
          EX    (SP),HL         ; swap with length on stack
          DEC   HL              ; decrement 2nd string length
          JR    BYTE_COMP       ; back to BYTE-COMP

; ---
; the false condition.

FRST_LESS POP   BC              ; discard length
          POP   AF              ; pop A
          AND   A               ; clear the carry for false result.

; ---
; exact match and x$>y$ rejoin here

STR_TEST  PUSH  AF              ; save A and carry

          RST   28H             ;; FP-CALC
          DEFB  $A0             ;;stk-zero      an initial false value.
          DEFB  $34             ;;end-calc

; both numeric and string paths converge here.

END_TESTS POP   AF              ; pop carry  - will be set if eql/neql
          PUSH  AF              ; save it again.

          CALL  C,not           ; routine NOT sets true(1) if equal(0)
                                ; or, for strings, applies true result.
          CALL  greater_0       ; greater-0 


          POP   AF              ; pop A
          RRCA                  ; the third RRCA - test for '<=', '>=' or '<>'.
          CALL  NC,not          ; apply a terminal NOT if so.
          RET                   ; return.

; -----------------------------------
; THE 'STRING CONCATENATION' OPERATOR
; -----------------------------------
; (offset $17: 'strs_add')
; This literal combines two strings into one e.g. LET A$ = B$ + C$
; The two parameters of the two strings to be combined are on the stack.

strs_add    
          CALL  STK_FETCH       ; routine STK-FETCH fetches string parameters
                                ; and deletes calculator stack entry.
          PUSH  DE              ; save start address.
          PUSH  BC              ; and length.

          CALL  STK_FETCH       ; routine STK-FETCH for first string
          POP   HL              ; re-fetch first length
          PUSH  HL              ; and save again
          PUSH  DE              ; save start of second string
          PUSH  BC              ; and its length.

          ADD   HL,BC           ; add the two lengths.
          LD    B,H             ; transfer to BC
          LD    C,L             ; and create
          RST   30H             ; BC-SPACES in workspace.
                                ; DE points to start of space.

          CALL  STK_STO_s       ; routine STK-STO-$ stores parameters
                                ; of new string updating STKEND.

          POP   BC              ; length of first
          POP   HL              ; address of start

;;;       LD      A,B           ; test for
;;;       OR      C             ; zero length.
;;;       JR      Z,OTHER_STR   ; to OTHER-STR if null string
;;;       LDIR                  ; copy string to workspace.

          CALL  COND_MV         ;+ a conditional (NZ) ldir routine. 

OTHER_STR POP   BC              ; now second length
          POP   HL              ; and start of string

;;;       LD    A,B             ; test this one
;;;       OR    C               ; for zero length
;;;       JR    Z,STK_PNTRS     ; skip forward to STK-PNTRS if so as complete.
;;;       LDIR                  ; else copy the bytes.

          CALL  COND_MV         ;+ a conditional (NZ) ldir routine. 

;   Continue into next routine which sets the calculator stack pointers.

; ----------------------------
; THE 'STACK POINTERS' ROUTINE
; ----------------------------
;   Register DE is set to STKEND and HL, the result pointer, is set to five
;   locations below this - the 'last value'.
;   This routine is used when it is inconvenient to save these values at the
;   time the calculator stack is manipulated due to other activity on the
;   machine stack.
;   This routine is also used to terminate the VAL routine for
;   the same reason and to initialize the calculator stack at the start of
;   the CALCULATE routine.

STK_PNTRS LD    HL,($401C)      ; fetch STKEND value from system variable.
          LD    DE,$FFFB        ; the value -5
          PUSH  HL              ; push STKEND value.

          ADD   HL,DE           ; subtract 5 from HL.

          POP   DE              ; pop STKEND to DE.
          RET                   ; return.

; -------------------
; THE 'CHR$' FUNCTION
; -------------------
; (offset $2B: 'chr$')
;   This function returns a single character string that is a result of
;   converting a number in the range 0-255 to a string e.g. CHR$ 38 = "A".
;   Note. the ZX81 does not have an ASCII character set.

chrS      CALL  FP_TO_A         ; routine FP-TO-A puts the number in A.

          JR    C,REPORT_Bd     ; forward to REPORT-Bd if overflow
          JR    NZ,REPORT_Bd    ; forward to REPORT-Bd if negative

;;;       PUSH  AF              ; save the argument.

          LD    BC,$0001        ; one space required.
          RST   30H             ; BC-SPACES makes DE point to start

;;;       POP   AF              ; restore the number.

          LD    (DE),A          ; and store in workspace

          JR    str_STK         ;+ relative jump to similar sequence in str$.

;;;       CALL  STK_STO_s       ; routine STK-STO-$ stacks descriptor.
;;;       EX    DE,HL           ; make HL point to result and DE to STKEND.
;;;       RET                   ; return.

; ---

REPORT_Bd RST   08H             ; ERROR-1
          DEFB  $0A             ; Error Report: Integer out of range

; ------------------
; THE 'VAL' FUNCTION
; ------------------
; (offset $1A: 'val')
;   VAL treats the characters in a string as a numeric expression.
;   e.g. VAL "2.3" = 2.3, VAL "2+4" = 6, VAL ("2" + "4") = 24.

val       RST   18H             ;+ shorter way to fetch CH_ADD.

;;;       LD    HL,($4016)      ; fetch value of system variable CH_ADD
          PUSH  HL              ; and save on the machine stack.

          CALL  STK_FETCH       ; routine STK-FETCH fetches the string operand
                                ; from calculator stack.

          PUSH  DE              ; save the address of the start of the string.
          INC   BC              ; increment the length for a carriage return.

          RST   30H             ; BC-SPACES creates the space in workspace.
          POP   HL              ; restore start of string to HL.
          LD    ($4016),DE      ; load CH_ADD with start DE in workspace.

          PUSH  DE              ; save the start in workspace
          LDIR                  ; copy string from program or variables or
                                ; workspace to the workspace area.
          EX    DE,HL           ; end of string + 1 to HL
          DEC   HL              ; decrement HL to point to end of new area.
          LD    (HL),$76        ; insert a carriage return at end.
                                ; ZX81 has a non-ASCII character set
          RES   7,(IY+$01)      ; update FLAGS  - signal checking syntax.
          CALL  CLASS_06        ; routine CLASS-06 - SCANNING evaluates string
                                ; expression and checks for integer result.

          CALL  CHECK_2         ; routine CHECK-2 checks for carriage return.


          POP   HL              ; restore start of string in workspace.

          LD    ($4016),HL      ; set CH_ADD to the start of the string again.
          SET   7,(IY+$01)      ; update FLAGS  - signal running program.
          CALL  SCANNING        ; routine SCANNING evaluates the string
                                ; in full leaving result on calculator stack.

          POP   HL              ; restore saved character address in program.
          LD    ($4016),HL      ; and reset the system variable CH_ADD.

          JR    STK_PNTRS       ; back to exit via STK-PNTRS.
                                ; resetting the calculator stack pointers
                                ; HL and DE from STKEND as it wasn't possible
                                ; to preserve them during this routine.

; -------------------
; THE 'STR$' FUNCTION
; -------------------
; (offset $2A: 'str$')
; This function returns a string representation of a numeric argument.
; The method used is to trick the PRINT-FP routine into thinking it
; is writing to a collapsed display file when in fact it is writing to
; string workspace.
; If there is already a newline at the intended print position and the
; column count has not been reduced to zero then the print routine
; assumes that there is only 1K of RAM and the screen memory, like the rest
; of dynamic memory, expands as necessary using calls to the ONE-SPACE
; routine. The screen is character-mapped not bit-mapped.

strS      LD    BC,$0001        ; create an initial byte in workspace
          RST   30H             ; using BC-SPACES restart.

          LD    (HL),$76        ; place a carriage return there.

          LD    HL,($4039)      ; fetch value of S_POSN column/line
          PUSH  HL              ; and preserve on stack.

          LD    L,$FF           ; make column value high to create a
                                ; contrived buffer of length 254.
          LD    ($4039),HL      ; and store in system variable S_POSN.

          LD    HL,($400E)      ; fetch value of DF_CC
          PUSH  HL              ; and preserve on stack also.

          LD    ($400E),DE      ; now set DF_CC which normally addresses
                                ; somewhere in the display file to the start
                                ; of workspace.
          PUSH  DE              ; save the start of new string.

          CALL  PRINT_FP        ; routine PRINT-FP.

          POP   DE              ; retrieve start of string.

          LD    HL,($400E)      ; fetch end of string from DF_CC.
          AND   A               ; prepare for true subtraction.
          SBC   HL,DE           ; subtract to give length.

          LD    B,H             ; and transfer to the BC
          LD    C,L             ; register.

          POP   HL              ; restore original
          LD    ($400E),HL      ; DF_CC value

          POP   HL              ; restore original
          LD    ($4039),HL      ; S_POSN values.

;   New entry-point to exploit similarities and save 3 bytes of code.

str_STK CALL    STK_STO_s       ; routine STK-STO-$ stores the string
                                ; descriptor on the calculator stack.

          EX    DE,HL           ; HL = last value, DE = STKEND.
          RET                   ; return.


; -------------------
; THE 'CODE' FUNCTION
; -------------------
; (offset $19: 'code')
; Returns the code of a character or first character of a string
; e.g. CODE "AARDVARK" = 38  (not 65 as the ZX81 does not have an ASCII
; character set).


code      CALL  STK_FETCH       ; routine STK-FETCH to fetch and delete the
                                ; string parameters.
                                ; DE points to the start, BC holds the length.
          LD    A,B             ; test length
          OR    C               ; of the string.
          JR    Z,STK_CODE      ; skip to STK-CODE with zero if the null string.

          LD    A,(DE)          ; else fetch the first character.

STK_CODE  JP    STACK_A         ; jump back to STACK-A (with memory check)

; --------------------
; THE 'LEN' SUBROUTINE
; --------------------
; (offset $1b: 'len')
; Returns the length of a string.
; In Sinclair BASIC strings can be more than twenty thousand characters long
; so a sixteen-bit register is required to store the length

len       CALL  STK_FETCH       ; routine STK-FETCH to fetch and delete the
                                ; string parameters from the calculator stack.
                                ; register BC now holds the length of string.

          JP    STACK_BC        ; jump back to STACK-BC to save result on the
                                ; calculator stack (with memory check).

; -------------------------------------
; THE 'DECREASE THE COUNTER' SUBROUTINE
; -------------------------------------
; (offset $31: 'dec-jr-nz')
; The calculator has an instruction that decrements a single-byte
; pseudo-register and makes consequential relative jumps just like
; the Z80's DJNZ instruction.

dec_jr_nz EXX                   ; switch in set that addresses code

          PUSH  HL              ; save pointer to offset byte
          LD    HL,$401E        ; address BREG in system variables
          DEC   (HL)            ; decrement it
          POP   HL              ; restore pointer

          JR    NZ,JUMP_2       ; to JUMP-2 if not zero

          INC   HL              ; step past the jump length.
          EXX                   ; switch in the main set.
          RET                   ; return.

; Note. as a general rule the calculator avoids using the IY register
; otherwise the cumbersome 4 instructions in the middle could be replaced by
; dec (iy+$xx) - using three instruction bytes instead of six.


; ---------------------
; THE 'JUMP' SUBROUTINE
; ---------------------
; (Offset $2F; 'jump')
; This enables the calculator to perform relative jumps just like
; the Z80 chip's JR instruction.
; This is one of the few routines that was polished for the ZX Spectrum.

JUMP      EXX                   ;switch in pointer set

JUMP_2    LD    E,(HL)          ; the jump byte 0-127 forward, 128-255 back.

;   Note. Elegance from the ZX Spectrum.

          LD    A,E             ;+
          RLA                   ;+
          SBC   A,A             ;+

;   The original ZX81 code.

;;;       XOR   A               ; clear accumulator.
;;;       BIT   7,E             ; test if negative jump
;;;       JR    Z,JUMP_3        ; skip, if positive, to JUMP-3.
;;;       CPL                   ; else change to $FF.

JUMP_3    LD    D,A             ; transfer to high byte.
          ADD   HL,DE           ; advance calculator pointer forward or back.

          EXX                   ; switch out pointer set.
          RET                   ; return.

; -----------------------------
; THE 'JUMP ON TRUE' SUBROUTINE
; -----------------------------
; (Offset $00; 'jump-true')
; This enables the calculator to perform conditional relative jumps
; dependent on whether the last test gave a true result
; On the ZX81, the exponent will be zero for zero or else $81 for one.

jump_true LD    A,(DE)          ; collect exponent byte

          AND   A               ; is result 0 or 1 ?
          JR    NZ,JUMP         ; back to JUMP if true (1).

          EXX                   ; else switch in the pointer set.
          INC   HL              ; step past the jump length.
          EXX                   ; switch in the main set.
          RET                   ; return.


; ------------------------
; THE 'MODULUS' SUBROUTINE
; ------------------------
; ( Offset $2E: 'n-mod-m' )
; ( i1, i2 -- i3, i4 )
; The subroutine calculate N mod M where M is the positive integer, the
; 'last value' on the calculator stack and N is the integer beneath.
; The subroutine returns the integer quotient as the last value and the
; remainder as the value beneath.
; e.g.    17 MOD 3 = 5 remainder 2
; It is invoked during the calculation of a random number and also by
; the PRINT-FP routine.

n_mod_m   RST   28H             ;; FP-CALC          17, 3.
          DEFB  $C0             ;;st-mem-0          17, 3.
          DEFB  $02             ;;delete            17.
          DEFB  $2D             ;;duplicate         17, 17.
          DEFB  $E0             ;;get-mem-0         17, 17, 3.
          DEFB  $05             ;;division          17, 17/3.
          DEFB  $24             ;;int               17, 5.
          DEFB  $E0             ;;get-mem-0         17, 5, 3.
          DEFB  $01             ;;exchange          17, 3, 5.
          DEFB  $C0             ;;st-mem-0          17, 3, 5.
          DEFB  $04             ;;multiply          17, 15.
          DEFB  $03             ;;subtract          2.
          DEFB  $E0             ;;get-mem-0         2, 5.
          DEFB  $34             ;;end-calc          2, 5.

          RET                   ; return.


; ----------------------
; THE 'INTEGER' FUNCTION
; ----------------------
; (offset $24: 'int')
; This function returns the integer of x, which is just the same as truncate
; for positive numbers. The truncate literal truncates negative numbers
; upwards so that -3.4 gives -3 whereas the BASIC INT function has to
; truncate negative numbers down so that INT -3.4 is 4.
; It is best to work through using, say, plus and minus 3.4 as examples.

int       RST   28H             ;; FP-CALC              x.    (= 3.4 or -3.4).
          DEFB  $2D             ;;duplicate             x, x.
          DEFB  $32             ;;less-0                x, (1/0)
          DEFB  $00             ;;jump-true             x, (1/0)
          DEFB  $04             ;;to L1C46, X-NEG

          DEFB  $36             ;;truncate              trunc 3.4 = 3.
          DEFB  $34             ;;end-calc              3.

          RET                   ; return with + int x on stack.


X_NEG     DEFB  $2D             ;;duplicate             -3.4, -3.4.
          DEFB  $36             ;;truncate              -3.4, -3.
          DEFB  $C0             ;;st-mem-0              -3.4, -3.
          DEFB  $03             ;;subtract              -.4
          DEFB  $E0             ;;get-mem-0             -.4, -3.
          DEFB  $01             ;;exchange              -3, -.4.
          DEFB  $2C             ;;not                   -3, (0).
          DEFB  $00             ;;jump-true             -3.
          DEFB  $03             ;;to L1C59, EXIT        -3.

          DEFB  $A1             ;;stk-one               -3, 1.
          DEFB  $03             ;;subtract              -4.

EXIT      DEFB  $34             ;;end-calc              -4.

          RET                   ; return.


; --------------------------
; THE 'EXPONENTIAL' FUNCTION
; --------------------------
; (Offset $23: 'exp')
;   The exponential function returns the exponential of the argument, or the
;   value of 'e' (2.7182818...) raised to the power of the argument.
;   PRINT EXP 1 gives 2.7182818
;
;   EXP is the opposite of the LN function (see below) and is equivalent to 
;   the 'antiln' function found on pocket calculators or the 'Inverse ln'
;   function found on the Windows scientific calculator.
;   So PRINT EXP LN 5.3 will give 5.3 as will PRINT LN EXP 5.3 or indeed
;   any number e.g. PRINT EXP LN PI.
;
;   The applications of the exponential function are in areas where exponential
;   growth is experienced, calculus, population growth and compound interest.
;
;   Error 6 if the argument is above 88.

exp       RST   28H             ;; FP-CALC
          DEFB  $30             ;;stk-data			1/LN 2
          DEFB  $F1             ;;Exponent: $81, Bytes: 4
          DEFB  $38,$AA,$3B,$29 ;;
          DEFB  $04             ;;multiply
          DEFB  $2D             ;;duplicate
          DEFB  $24             ;;int
          DEFB  $C3             ;;st-mem-3
          DEFB  $03             ;;subtract
          DEFB  $2D             ;;duplicate
          DEFB  $0F             ;;addition
          DEFB  $A1             ;;stk-one
          DEFB  $03             ;;subtract
          DEFB  $88             ;;series-08
          DEFB  $13             ;;Exponent: $63, Bytes: 1
          DEFB  $36             ;;(+00,+00,+00)
          DEFB  $58             ;;Exponent: $68, Bytes: 2
          DEFB  $65,$66         ;;(+00,+00)
          DEFB  $9D             ;;Exponent: $6D, Bytes: 3
          DEFB  $78,$65,$40     ;;(+00)
          DEFB  $A2             ;;Exponent: $72, Bytes: 3
          DEFB  $60,$32,$C9     ;;(+00)
          DEFB  $E7             ;;Exponent: $77, Bytes: 4
          DEFB  $21,$F7,$AF,$24 ;;
          DEFB  $EB             ;;Exponent: $7B, Bytes: 4
          DEFB  $2F,$B0,$B0,$14 ;;
          DEFB  $EE             ;;Exponent: $7E, Bytes: 4
          DEFB  $7E,$BB,$94,$58 ;;
          DEFB  $F1             ;;Exponent: $81, Bytes: 4
          DEFB  $3A,$7E,$F8,$CF ;;
          DEFB  $E3             ;;get-mem-3
          DEFB  $34             ;;end-calc

          CALL  FP_TO_A         ; routine FP-TO-A
          JR    NZ,N_NEGTV      ; to N-NEGTV

          JR    C,REPORT_6b     ; to REPORT-6b

          ADD   A,(HL)          ;
          JR    NC,RESULT_OK    ; to RESULT-OK


REPORT_6b RST   08H             ; ERROR-1
          DEFB  $05             ; Error Report: Number too big

N_NEGTV   JR    C,RSLT_ZERO     ; to RSLT-ZERO

          SUB   (HL)            ;
          JR    NC,RSLT_ZERO    ; to RSLT-ZERO

          NEG                   ; Negate

RESULT_OK LD    (HL),A          ;
          RET                   ; return.


RSLT_ZERO RST   28H             ;; FP-CALC
          DEFB  $02             ;;delete
          DEFB  $A0             ;;stk-zero
          DEFB  $34             ;;end-calc

          RET                   ; return.


; --------------------------------
; THE 'NATURAL LOGARITHM' FUNCTION
; --------------------------------
; (offset $22: 'ln')
;   Like the ZX81 itself, 'natural' logarithms came from Scotland.
;   They were devised in 1614 by well-traveled Scotsman John Napier who noted
;   "Nothing doth more molest and hinder calculators than the multiplications,
;    divisions, square and cubical extractions of great numbers".
;   Napier's logarithms enabled the above operations to be accomplished by 
;   simple addition and subtraction simplifying the navigational and 
;   astronomical calculations which beset his age.
;   Napier's logarithms were quickly overtaken by logarithms to the base 10
;   devised, in conjunction with Napier, by Henry Briggs a Cambridge-educated 
;   professor of Geometry at Oxford University. These simplified the layout
;   of the tables enabling humans to easily scale calculations.
;
;   It is only recently with the introduction of pocket calculators and
;   computers like the ZX81 that natural logarithms are once more at the fore,
;   although some computers retain logarithms to the base ten.
;   'Natural' logarithms are powers to the base 'e', which like 'pi' is a 
;   naturally occurring number in branches of mathematics.
;   Like 'pi' also, 'e' is an irrational number and starts 2.718281828...
;
;   The tabular use of logarithms was that to multiply two numbers one looked
;   up their two logarithms in the tables, added them together and then looked 
;   for the result in a table of antilogarithms to give the desired product.
;
;   The EXP function is the BASIC equivalent of a calculator's 'antiln' function 
;   and by picking any two numbers, 1.72 and 6.89 say,
;     10 PRINT EXP ( LN 1.72 + LN 6.89 ) 
;   will give just the same result as
;     20 PRINT 1.72 * 6.89.
;   Division is accomplished by subtracting the two logs.
;
;   Napier also mentioned "square and cubicle extractions". 
;   To raise a number to the power 3, find its 'ln', multiply by 3 and find the 
;   'antiln'.  e.g. PRINT EXP( LN 4 * 3 )  gives 64.
;   Similarly to find the n'th root divide the logarithm by 'n'.
;   The ZX81 ROM used PRINT EXP ( LN 9 / 2 ) to find the square root of the 
;   number 9. The Napieran square root function is just a special case of 
;   the 'to_power' function. A cube root or indeed any root/power would be just
;   as simple.

;   First test that the argument to LN is a positive, non-zero number.


ln        RST   28H             ;; FP-CALC		x.
          DEFB  $2D             ;;duplicate		x,x.
          DEFB  $33             ;;greater-0		x,(0/1).
          DEFB  $00             ;;jump-true		x.
          DEFB  $04             ;;to L1CB1, VALID

          DEFB  $34             ;;end-calc		x.


REPORT_Ab RST   08H             ; ERROR-1
          DEFB  $09             ; Error Report: Invalid argument

VALID      	 
;;;       DEFB  $A0             ;;stk-zero	
;;;       DEFB  $02             ;;delete
          DEFB  $34             ;;end-calc		x.

;   Register HL addresses the 'last value' x.

          LD    A,(HL)          ; Fetch exponent to A.

          LD    (HL),$80        ; Insert 'plus zero' as exponent.
          CALL  STACK_A         ; routine STACK-A stacks true binary exponent.
		
          RST   28H             ;; FP-CALC
          DEFB  $30             ;;stk-data
          DEFB  $38             ;;Exponent: $88, Bytes: 1
          DEFB  $00             ;;(+00,+00,+00)
          DEFB  $03             ;;subtract
          DEFB  $01             ;;exchange
          DEFB  $2D             ;;duplicate
          DEFB  $30             ;;stk-data
          DEFB  $F0             ;;Exponent: $80, Bytes: 4
          DEFB  $4C,$CC,$CC,$CD ;;
          DEFB  $03             ;;subtract
          DEFB  $33             ;;greater-0
          DEFB  $00             ;;jump-true
          DEFB  $08             ;;to L1CD2, GRE.8

          DEFB  $01             ;;exchange
          DEFB  $A1             ;;stk-one
          DEFB  $03             ;;subtract
          DEFB  $01             ;;exchange
          DEFB  $34             ;;end-calc

          INC   (HL)            ;

          RST   28H             ;; FP-CALC

GRE_8     DEFB  $01             ;;exchange
          DEFB  $30             ;;stk-data			LN 2
          DEFB  $F0             ;;Exponent: $80, Bytes: 4
          DEFB  $31,$72,$17,$F8 ;;
          DEFB  $04             ;;multiply
          DEFB  $01             ;;exchange
          DEFB  $A2             ;;stk-half
          DEFB  $03             ;;subtract
          DEFB  $A2             ;;stk-half
          DEFB  $03             ;;subtract
          DEFB  $2D             ;;duplicate
          DEFB  $30             ;;stk-data
          DEFB  $32             ;;Exponent: $82, Bytes: 1
          DEFB  $20             ;;(+00,+00,+00)
          DEFB  $04             ;;multiply
          DEFB  $A2             ;;stk-half
          DEFB  $03             ;;subtract
          DEFB  $8C             ;;series-0C
          DEFB  $11             ;;Exponent: $61, Bytes: 1
          DEFB  $AC             ;;(+00,+00,+00)
          DEFB  $14             ;;Exponent: $64, Bytes: 1
          DEFB  $09             ;;(+00,+00,+00)
          DEFB  $56             ;;Exponent: $66, Bytes: 2
          DEFB  $DA,$A5         ;;(+00,+00)
          DEFB  $59             ;;Exponent: $69, Bytes: 2
          DEFB  $30,$C5         ;;(+00,+00)
          DEFB  $5C             ;;Exponent: $6C, Bytes: 2
          DEFB  $90,$AA         ;;(+00,+00)
          DEFB  $9E             ;;Exponent: $6E, Bytes: 3
          DEFB  $70,$6F,$61     ;;(+00)
          DEFB  $A1             ;;Exponent: $71, Bytes: 3
          DEFB  $CB,$DA,$96     ;;(+00)
          DEFB  $A4             ;;Exponent: $74, Bytes: 3
          DEFB  $31,$9F,$B4     ;;(+00)
          DEFB  $E7             ;;Exponent: $77, Bytes: 4
          DEFB  $A0,$FE,$5C,$FC ;;
          DEFB  $EA             ;;Exponent: $7A, Bytes: 4
          DEFB  $1B,$43,$CA,$36 ;;
          DEFB  $ED             ;;Exponent: $7D, Bytes: 4
          DEFB  $A7,$9C,$7E,$5E ;;
          DEFB  $F0             ;;Exponent: $80, Bytes: 4
          DEFB  $6E,$23,$80,$93 ;;
          DEFB  $04             ;;multiply
          DEFB  $0F             ;;addition
          DEFB  $34             ;;end-calc

          RET                   ; return.

; ------------------------------
; THE NEW 'SQUARE ROOT' FUNCTION
; ------------------------------
; (Offset $25: 'sqr')
;   "If I have seen further, it is by standing on the shoulders of giants" -
;   Sir Isaac Newton, Cambridge 1676.
;   The sqr function has been re-written to use the Newton-Raphson method.
;   Joseph Raphson was a student of Sir Isaac Newton at Cambridge University
;   and helped publicize his work.
;   Although Newton's method is centuries old, this routine, appropriately, is 
;   based on a FORTH word written by Steven Vickers in the Jupiter Ace manual.
;   Whereas that method uses an initial guess of one, this one manipulates 
;   the exponent byte to obtain a better starting guess. 
;   First test for zero and return zero, if so, as the result.
;   If the argument is negative, then produce an error.

sqr       RST   28H             ;; FP-CALC              x
          DEFB  $C3             ;;st-mem-3              x.   (seed for guess)
          DEFB  $34             ;;end-calc		x.

;   HL now points to exponent of argument on calculator stack.

          LD    A,(HL)          ; Test for zero argument
          AND   A               ; 

          RET   Z               ; Return with zero on the calculator stack.

;   Test for a positive argument

          INC   HL              ; Address byte with sign bit.
          BIT   7,(HL)          ; Test the bit.

          JR    NZ,REPORT_Ab    ; back to REPORT_A 
                                ; 'Invalid argument'
 
;   This guess is based on a Usenet discussion.
;   Halve the exponent to achieve a good guess.(accurate with .25 16 64 etc.)

          LD    HL,$4071        ; Address first byte of mem-3

          LD    A,(HL)          ; fetch exponent of mem-3
          XOR   $80             ; toggle sign of exponent of mem-3
          SRA   A               ; shift right, bit 7 unchanged.
          INC   A               ;
          JR    Z,ASIS          ; forward with say .25 -> .5
          JP    P,ASIS          ; leave increment if value > .5
          DEC   A               ; restore to shift only.
ASIS      XOR   $80             ; restore sign.
          LD    (HL),A          ; and put back 'halved' exponent.

;   Now re-enter the calculator.

          RST   28H             ;; FP-CALC              x

SLOOP     DEFB  $2D             ;;duplicate             x,x.
          DEFB  $E3             ;;get-mem-3             x,x,guess
          DEFB  $C4             ;;st-mem-4              x,x,guess
          DEFB  $05             ;;div                   x,x/guess.
          DEFB  $E3             ;;get-mem-3             x,x/guess,guess
          DEFB  $0F             ;;addition              x,x/guess+guess
          DEFB  $A2             ;;stk-half              x,x/guess+guess,.5
          DEFB  $04             ;;multiply              x,(x/guess+guess)*.5
          DEFB  $C3             ;;st-mem-3              x,newguess
          DEFB  $E4             ;;get-mem-4             x,newguess,oldguess
          DEFB  $03             ;;subtract              x,newguess-oldguess
          DEFB  $27             ;;abs                   x,difference.
          DEFB  $33             ;;greater-0             x,(0/1).
          DEFB  $00             ;;jump-true             x.

          DEFB  SLOOP - $       ;;to sloop              x.

          DEFB  $02             ;;delete                .
          DEFB  $E3             ;;get-mem-3             retrieve final guess.
          DEFB  $34             ;;end-calc              sqr x.

          RET                  ; return with square root on stack

;   or in ZX81 BASIC
;
;      5 PRINT "NEWTON RAPHSON SQUARE ROOTS"
;     10 INPUT "NUMBER ";N
;     20 INPUT "GUESS ";G
;     30 PRINT " NUMBER "; N ;" GUESS "; G
;     40 FOR I = 1 TO 10
;     50  LET B = N/G
;     60  LET C = B+G
;     70  LET G = C/2
;     80  PRINT I; " VALUE "; G
;     90 NEXT I
;    100 PRINT "NAPIER METHOD"; SQR N

; -----------------------------
; THE 'TRIGONOMETRIC' FUNCTIONS
; -----------------------------
;   Trigonometry is rocket science. It is also used by carpenters and pyramid
;   builders. 
;   Some uses can be quite abstract but the principles can be seen in simple
;   right-angled triangles. Triangles have some special properties -
;
;   1) The sum of the three angles is always PI radians (180 degrees).
;      Very helpful if you know two angles and wish to find the third.
;   2) In any right-angled triangle the sum of the squares of the two shorter
;      sides is equal to the square of the longest side opposite the right-angle.
;      Very useful if you know the length of two sides and wish to know the
;      length of the third side.
;   3) Functions sine, cosine and tangent enable one to calculate the length 
;      of an unknown side when the length of one other side and an angle is 
;      known.
;   4) Functions arcsin, arccosine and arctan enable one to calculate an unknown
;      angle when the length of two of the sides is known.

; --------------------------------
; THE 'REDUCE ARGUMENT' SUBROUTINE
; --------------------------------
; (offset $35: 'get-argt')
;
;   This routine performs two functions on the angle, in radians, that forms
;   the argument to the sine and cosine functions.
;   First it ensures that the angle 'wraps round'. That if a ship turns through 
;   an angle of, say, 3*PI radians (540 degrees) then the net effect is to turn 
;   through an angle of PI radians (180 degrees).
;   Secondly it converts the angle in radians to a fraction of a right angle,
;   depending within which quadrant the angle lies, with the periodicity 
;   resembling that of the desired sine value.
;   The result lies in the range -1 to +1.              
;
;                       90 deg.
; 
;                       (pi/2)
;                II       +1        I
;                         |
;          sin+      |\   |   /|    sin+
;          cos-      | \  |  / |    cos+
;          tan-      |  \ | /  |    tan+
;                    |   \|/)  |           
;   180 deg. (pi) 0 -|----+----|-- 0  (0)   0 degrees
;                    |   /|\   |
;          sin-      |  / | \  |    sin-
;          cos-      | /  |  \ |    cos+
;          tan+      |/   |   \|    tan-
;                         |
;                III      -1       IV
;                       (3pi/2)
;
;                       270 deg.


get_argt  RST   28H             ;; FP-CALC         X.
          DEFB  $30             ;;stk-data
          DEFB  $EE             ;;Exponent: $7E, 
                                ;;Bytes: 4
          DEFB  $22,$F9,$83,$6E ;;                 X, 1/(2*PI)             
          DEFB  $04             ;;multiply         X/(2*PI) = fraction

          DEFB  $2D             ;;duplicate             
          DEFB  $A2             ;;stk-half
          DEFB  $0F             ;;addition
          DEFB  $24             ;;int

          DEFB  $03             ;;subtract         now range -.5 to .5

          DEFB  $2D             ;;duplicate
          DEFB  $0F             ;;addition         now range -1 to 1.
          DEFB  $2D             ;;duplicate
          DEFB  $0F             ;;addition         now range -2 to 2.

;   quadrant I (0 to +1) and quadrant IV (-1 to 0) are now correct.
;   quadrant II ranges +1 to +2.
;   quadrant III ranges -2 to -1.

          DEFB  $2D             ;;duplicate        Y, Y.
          DEFB  $27             ;;abs              Y, abs(Y).    range 1 to 2
          DEFB  $A1             ;;stk-one          Y, abs(Y), 1.
          DEFB  $03             ;;subtract         Y, abs(Y)-1.  range 0 to 1
          DEFB  $2D             ;;duplicate        Y, Z, Z.
          DEFB  $33             ;;greater-0        Y, Z, (1/0).

          DEFB  $C0             ;;st-mem-0         store as possible sign 
                                ;;                 for cosine function.

          DEFB  $00             ;;jump-true
          DEFB  $04             ;;to L1D35, ZPLUS  with quadrants II and III

;   else the angle lies in quadrant I or IV and value Y is already correct.

          DEFB  $02             ;;delete          Y    delete test value.
          DEFB  $34             ;;end-calc        Y.

          RET                   ; return.         with Q1 and Q4 >>>

;   The branch was here with quadrants II (0 to 1) and III (1 to 0).
;   Y will hold -2 to -1 if this is quadrant III.

ZPLUS     DEFB  $A1             ;;stk-one         Y, Z, 1
          DEFB  $03             ;;subtract        Y, Z-1.       Q3 = 0 to -1
          DEFB  $01             ;;exchange        Z-1, Y.
          DEFB  $32             ;;less-0          Z-1, (1/0).
          DEFB  $00             ;;jump-true       Z-1.
          DEFB  $02             ;;to L1D3C, YNEG
                                ;;if angle in quadrant III

;   else angle is within quadrant II (-1 to 0)

          DEFB  $18             ;;negate          range +1 to 0


YNEG      DEFB  $34             ;;end-calc        quadrants II and III correct.

          RET                   ; return.


; ---------------------
; THE 'COSINE' FUNCTION
; ---------------------
; (offset $1D: 'cos')
;   Cosines are calculated as the sine of the opposite angle rectifying the 
;   sign depending on the quadrant rules. 
;
;
;             /|
;          h /y|
;           /  |o
;          /x  |
;         /----|    
;           a
;
;   The cosine of angle x is the adjacent side (a) divided by the hypotenuse 1.
;   However if we examine angle y then a/h is the sine of that angle.
;   Since angle x plus angle y equals a right-angle, we can find angle y by 
;   subtracting angle x from pi/2.
;   However it's just as easy to reduce the argument first and subtract the
;   reduced argument from the value 1 (a reduced right-angle).
;   It's even easier to subtract 1 from the angle and rectify the sign.
;   In fact, after reducing the argument, the absolute value of the argument
;   is used and rectified using the test result stored in mem-0 by 'get-argt'
;   for that purpose.

cos       RST   28H             ;; FP-CALC              angle in radians.
          DEFB  $35             ;;get-argt              X       reduce -1 to +1

          DEFB  $27             ;;abs                   ABS X   0 to 1
          DEFB  $A1             ;;stk-one               ABS X, 1.
          DEFB  $03             ;;subtract              now opposite angle 
                                ;;                      though negative sign.
          DEFB  $E0             ;;get-mem-0             fetch sign indicator.
          DEFB  $00             ;;jump-true
          DEFB  $06             ;;fwd to L1D4B, C-ENT
                                ;;forward to common code if in QII or QIII 


          DEFB  $18             ;;negate                else make positive.
          DEFB  $2F             ;;jump
          DEFB  $03             ;;fwd to L1D4B, C-ENT
                                ;;with quadrants QI and QIV 

; -------------------
; THE 'SINE' FUNCTION
; -------------------
; (offset $1C: 'sin')
;   This is a fundamental transcendental function from which others such as cos
;   and tan are directly, or indirectly, derived.
;   It uses the series generator to produce Chebyshev polynomials.
;
;
;             /|
;          1 / |
;           /  |x
;          /a  |
;         /----|    
;           y
;
;   The 'get-argt' function is designed to modify the angle and its sign 
;   in line with the desired sine value and afterwards it can launch straight
;   into common code.

sin       RST   28H             ;; FP-CALC      angle in radians
          DEFB  $35             ;;get-argt      reduce - sign now correct.

C_ENT     DEFB  $2D             ;;duplicate
          DEFB  $2D             ;;duplicate
          DEFB  $04             ;;multiply
          DEFB  $2D             ;;duplicate
          DEFB  $0F             ;;addition
          DEFB  $A1             ;;stk-one
          DEFB  $03             ;;subtract

          DEFB  $86             ;;series-06
          DEFB  $14             ;;Exponent: $64, Bytes: 1
          DEFB  $E6             ;;(+00,+00,+00)
          DEFB  $5C             ;;Exponent: $6C, Bytes: 2
          DEFB  $1F,$0B         ;;(+00,+00)
          DEFB  $A3             ;;Exponent: $73, Bytes: 3
          DEFB  $8F,$38,$EE     ;;(+00)
          DEFB  $E9             ;;Exponent: $79, Bytes: 4
          DEFB  $15,$63,$BB,$23 ;;
          DEFB  $EE             ;;Exponent: $7E, Bytes: 4
          DEFB  $92,$0D,$CD,$ED ;;
          DEFB  $F1             ;;Exponent: $81, Bytes: 4
          DEFB  $23,$5D,$1B,$EA ;;

          DEFB  $04             ;;multiply
          DEFB  $34             ;;end-calc

          RET                   ; return.


; ----------------------
; THE 'TANGENT' FUNCTION
; ----------------------
; (offset $1E: 'tan')
;
;   Evaluates tangent x as    sin(x) / cos(x).
;
;
;             /|
;          h / |
;           /  |o
;          /x  |
;         /----|    
;           a
;
;   The tangent of angle x is the ratio of the length of the opposite side 
;   divided by the length of the adjacent side.  As the opposite length can 
;   be calculates using sin(x) and the adjacent length using cos(x) then 
;   the tangent can be defined in terms of the previous two functions.

;   Error 6 if the argument, in radians, is too close to one like pi/2
;   which has an infinite tangent. e.g. PRINT TAN (PI/2)  evaluates as 1/0.
;   Similarly PRINT TAN (3*PI/2), TAN (5*PI/2) etc.

tan       RST   28H             ;; FP-CALC          x.
          DEFB  $2D             ;;duplicate         x, x.
          DEFB  $1C             ;;sin               x, sin x.
          DEFB  $01             ;;exchange          sin x, x.
          DEFB  $1D             ;;cos               sin x, cos x.
          DEFB  $05             ;;division          sin x/cos x (= tan x).
          DEFB  $34             ;;end-calc          tan x.

          RET                   ; return.

; ---------------------
; THE 'ARCTAN' FUNCTION
; ---------------------
; (Offset $21: 'atn')
;   The inverse tangent function with the result in radians.
;   This is a fundamental transcendental function from which others such as asn
;   and acs are directly, or indirectly, derived.
;   It uses the series generator to produce Chebyshev polynomials.

atn       LD    A,(HL)          ; fetch exponent
          CP    $81             ; compare to that for 'one'
          JR    C,SMALL         ; forward, if less, to SMALL

          RST   28H             ;; FP-CALC      X.
          DEFB  $A1             ;;stk-one
          DEFB  $18             ;;negate
          DEFB  $01             ;;exchange
          DEFB  $05             ;;division
          DEFB  $2D             ;;duplicate
          DEFB  $32             ;;less-0
          DEFB  $A3             ;;stk-pi/2
          DEFB  $01             ;;exchange
          DEFB  $00             ;;jump-true
          DEFB  $06             ;;to L1D8B, CASES

          DEFB  $18             ;;negate
          DEFB  $2F             ;;jump
          DEFB  $03             ;;to L1D8B, CASES

; ---

SMALL     RST   28H             ;; FP-CALC
          DEFB  $A0             ;;stk-zero

CASES     DEFB  $01             ;;exchange
          DEFB  $2D             ;;duplicate
          DEFB  $2D             ;;duplicate
          DEFB  $04             ;;multiply
          DEFB  $2D             ;;duplicate
          DEFB  $0F             ;;addition
          DEFB  $A1             ;;stk-one
          DEFB  $03             ;;subtract

          DEFB  $8C             ;;series-0C
          DEFB  $10             ;;Exponent: $60, Bytes: 1
          DEFB  $B2             ;;(+00,+00,+00)
          DEFB  $13             ;;Exponent: $63, Bytes: 1
          DEFB  $0E             ;;(+00,+00,+00)
          DEFB  $55             ;;Exponent: $65, Bytes: 2
          DEFB  $E4,$8D         ;;(+00,+00)
          DEFB  $58             ;;Exponent: $68, Bytes: 2
          DEFB  $39,$BC         ;;(+00,+00)
          DEFB  $5B             ;;Exponent: $6B, Bytes: 2
          DEFB  $98,$FD         ;;(+00,+00)
          DEFB  $9E             ;;Exponent: $6E, Bytes: 3
          DEFB  $00,$36,$75     ;;(+00)
          DEFB  $A0             ;;Exponent: $70, Bytes: 3
          DEFB  $DB,$E8,$B4     ;;(+00)
          DEFB  $63             ;;Exponent: $73, Bytes: 2
          DEFB  $42,$C4         ;;(+00,+00)
          DEFB  $E6             ;;Exponent: $76, Bytes: 4
          DEFB  $B5,$09,$36,$BE ;;
          DEFB  $E9             ;;Exponent: $79, Bytes: 4
          DEFB  $36,$73,$1B,$5D ;;
          DEFB  $EC             ;;Exponent: $7C, Bytes: 4
          DEFB  $D8,$DE,$63,$BE ;;
          DEFB  $F0             ;;Exponent: $80, Bytes: 4
          DEFB  $61,$A1,$B3,$0C ;;

          DEFB  $04             ;;multiply
          DEFB  $0F             ;;addition
          DEFB  $34             ;;end-calc

          RET                   ; return.


; ---------------------
; THE 'ARCSIN' FUNCTION
; ---------------------
; (Offset $1F: 'asn')
;   The inverse sine function with result in radians.
;   Derived from arctan function above.
;   Error A unless the argument is between -1 and +1 inclusive.
;   Uses an adaptation of the formula asn(x) = atn(x/sqr(1-x*x))
;
;
;                 /|
;                / |
;              1/  |x
;              /a  |
;             /----|    
;               y
;
;   e.g. We know the opposite side (x) and hypotenuse (1) 
;   and we wish to find angle a in radians.
;   We can derive length y by Pythagoras and then use ATN instead. 
;   Since y*y + x*x = 1*1 (Pythagoras Theorem) then
;   y=sqr(1-x*x)                         - no need to multiply 1 by itself.
;   So, asn(a) = atn(x/y)
;   or more fully,
;   asn(a) = atn(x/sqr(1-x*x))

;   Close but no cigar.

;   While PRINT ATN (x/SQR (1-x*x)) gives the same results as PRINT ASN x,
;   it leads to division by zero when x is 1 or -1.
;   To overcome this, 1 is added to y giving half the required angle and the 
;   result is then doubled. 
;   That is, PRINT ATN (x/(SQR (1-x*x) +1)) *2
;
;
;               . /|
;            .  c/ |
;         .     /1 |x
;      . c   b /a  |
;    ---------/----|    
;      1      y
;
;   By creating an isosceles triangle with two equal sides of 1, angles c and 
;   c are also equal. If b+c+c = 180 degrees and b+a = 180 degress then c=a/2.
;
;   A value higher than 1 gives the required error as attempting to find  the
;   square root of a negative number generates an error in Sinclair BASIC.

asn       RST   28H             ;; FP-CALC      x.
          DEFB  $2D             ;;duplicate     x, x.
          DEFB  $2D             ;;duplicate     x, x, x.
          DEFB  $04             ;;multiply      x, x*x.
          DEFB  $A1             ;;stk-one       x, x*x, 1.
          DEFB  $03             ;;subtract      x, x*x-1.
          DEFB  $18             ;;negate        x, 1-x*x.
          DEFB  $25             ;;sqr           x, sqr(1-x*x) = y.
          DEFB  $A1             ;;stk-one       x, y, 1.
          DEFB  $0F             ;;addition      x, y+1.
          DEFB  $05             ;;division      x/y+1.
          DEFB  $21             ;;atn           a/2     (half the angle)
          DEFB  $2D             ;;duplicate     a/2, a/2.
          DEFB  $0F             ;;addition      a.
          DEFB  $34             ;;end-calc      a.

          RET                   ; return.


; ------------------------
; THE 'ARCCOS' FUNCTION
; ------------------------
; (Offset $20: 'acs')
; the inverse cosine function with the result in radians.
; Error A unless the argument is between -1 and +1.
; Result in range 0 to pi.
; Derived from asn above which is in turn derived from the preceding atn.
; It could have been derived directly from atn using acs(x) = atn(sqr(1-x*x)/x).
; However, as sine and cosine are horizontal translations of each other,
; uses acs(x) = pi/2 - asn(x)

; e.g. the arccosine of a known x value will give the required angle b in 
; radians.
; We know, from above, how to calculate the angle a using asn(x). 
; Since the three angles of any triangle add up to 180 degrees, or pi radians,
; and the largest angle in this case is a right-angle (pi/2 radians), then
; we can calculate angle b as pi/2 (both angles) minus asn(x) (angle a).
; 
;
;           /|
;        1 /b|
;         /  |x
;        /a  |
;       /----|    
;         y
;

acs       RST   28H             ;; FP-CALC      x.
          DEFB  $1F             ;;asn           asn(x).
          DEFB  $A3             ;;stk-pi/2      asn(x), pi/2.
          DEFB  $03             ;;subtract      asn(x) - pi/2.
          DEFB  $18             ;;negate        pi/2 - asn(x) = acs(x).
          DEFB  $34             ;;end-calc      acs(x)

          RET                   ; return.


; --------------------------
; THE OLD 'SQUARE ROOT' FUNCTION
; --------------------------
; (Offset $25: 'sqr')
; Error A if argument is negative.
; This routine is remarkable for its brevity - 7 bytes.
; This routine uses Napier's method for calculating square roots which was 
; devised in 1614 and calculates the value as EXP (LN 'x' * 0.5).
;
; This is a little on the slow side as it involves two polynomial series.
; A series of 12 for LN and a series of 8 for EXP.  This was of no concern
; to John Napier since his tables were 'compiled forever'.
;
;;; L1DDB:  RST     28H             ;; FP-CALC              x.
;;;         DEFB    $2D             ;;duplicate             x, x.
;;;         DEFB    $2C             ;;not                   x, 1/0
;;;         DEFB    $00             ;;jump-true             x, (1/0).
;;;         DEFB    $1E             ;;to L1DFD, LAST        exit if argument zero
;;;                                 ;;                      with zero result.
;;;
;;; else continue to calculate as x ** .5
;;;
;;;         DEFB    $A2             ;;stk-half              x, .5.
;;;         DEFB    $34             ;;end-calc              x, .5.


; ------------------------
; THE 'TO POWER' OPERATION
; ------------------------
; (Offset $06: 'to-power')
;   The 'Exponential' operation.
;   This raises the first number X to the power of the second number Y.
;   e.g. PRINT 2 ** 3 gives the result 8
;   As with the ZX80,
;   0 ** 0 = 1
;   0 ** +n = 0
;   0 ** -n = arithmetic overflow.

to_power  RST   28H             ;; FP-CALC              X,Y.
          DEFB  $01             ;;exchange              Y,X.
          DEFB  $2D             ;;duplicate             Y,X,X.
          DEFB  $2C             ;;not                   Y,X,(1/0).
          DEFB  $00             ;;jump-true
          DEFB  $07             ;;forward to L1DEE, XISO if X is zero.

;   else X is non-zero. function 'ln' will catch a negative value of X.

          DEFB  $22             ;;ln                    Y, LN X.

;   Multiply the power by the logarithm of the argument.

          DEFB  $04             ;;multiply              Y * LN X
          DEFB  $34             ;;end-calc

          JP    exp             ; jump back to EXP routine             ->> 
				; to find the 'antiln'

; ---

;   these routines form the three simple results when the number is zero.
;   begin by deleting the known zero to leave Y the power factor.

XISO      DEFB  $02             ;;delete                Y.
          DEFB  $2D             ;;duplicate             Y, Y.
          DEFB  $2C             ;;not                   Y, (1/0).
          DEFB  $00             ;;jump-true     
          DEFB  $09             ;;forward to L1DFB, ONE if Y is zero.

;   the power factor is not zero. If negative then an error exists.

          DEFB  $A0             ;;stk-zero              Y, 0.
          DEFB  $01             ;;exchange              0, Y.
          DEFB  $33             ;;greater-0             0, (1/0).
          DEFB  $00             ;;jump-true             0
          DEFB  $06             ;;to L1DFD, LAST        if Y was any positive 
                                ;;                      number.

;   else force division by zero thereby raising an Arithmetic overflow error.
;   As an alternative, this now raises an error directly.

;;;       DEFB  $A1             ;;stk-one               0, 1.
;;;       DEFB  $01             ;;exchange              1, 0.
;;;       DEFB  $05             ;;division              1/0    >> error 

          DEFB  $34             ;+ end-calc
REPORT_6c RST   08H             ;+ ERROR-1
          DEFB  $05             ;+ Error Report: Number too big

; ---

ONE       DEFB  $02             ;;delete                .
          DEFB  $A1             ;;stk-one               1.

LAST      DEFB  $34             ;;end-calc              last value 1 or 0.

          RET                   ; return.

; ---------------------
; THE 'SPARE LOCATIONS'
; ---------------------

L1DFE:

          DEFB  $FF, $FF	; Two spare bytes.


ORG    $1E00

; ------------------------
; THE 'ZX81 CHARACTER SET'
; ------------------------


; $00 - Character: ' '          CHR$(0)

char_set  DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000

; $01 - Character: mosaic       CHR$(1)

          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000


; $02 - Character: mosaic       CHR$(2)

          DEFB  %00001111
          DEFB  %00001111
          DEFB  %00001111
          DEFB  %00001111
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000


; $03 - Character: mosaic       CHR$(3)

          DEFB  %11111111
          DEFB  %11111111
          DEFB  %11111111
          DEFB  %11111111
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000

; $04 - Character: mosaic       CHR$(4)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000

; $05 - Character: mosaic       CHR$(1)

          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000

; $06 - Character: mosaic       CHR$(1)

          DEFB  %00001111
          DEFB  %00001111
          DEFB  %00001111
          DEFB  %00001111
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000

; $07 - Character: mosaic       CHR$(1)

          DEFB  %11111111
          DEFB  %11111111
          DEFB  %11111111
          DEFB  %11111111
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000
          DEFB  %11110000

; $08 - Character: mosaic       CHR$(1)

          DEFB  %10101010
          DEFB  %01010101
          DEFB  %10101010
          DEFB  %01010101
          DEFB  %10101010
          DEFB  %01010101
          DEFB  %10101010
          DEFB  %01010101

; $09 - Character: mosaic       CHR$(1)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %10101010
          DEFB  %01010101
          DEFB  %10101010
          DEFB  %01010101

; $0A - Character: mosaic       CHR$(10)

          DEFB  %10101010
          DEFB  %01010101
          DEFB  %10101010
          DEFB  %01010101
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000

; $0B - Character: '"'          CHR$(11)

          DEFB  %00000000
          DEFB  %00100100
          DEFB  %00100100
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000

; $0B - Character: '�'          CHR$(12)

          DEFB  %00000000
          DEFB  %00011100
          DEFB  %00100010
          DEFB  %01111000
          DEFB  %00100000
          DEFB  %00100000
          DEFB  %01111110
          DEFB  %00000000

; $0B - Character: '$'          CHR$(13)

          DEFB  %00000000
          DEFB  %00001000
          DEFB  %00111110
          DEFB  %00101000
          DEFB  %00111110
          DEFB  %00001010
          DEFB  %00111110
          DEFB  %00001000

; $0B - Character: ':'          CHR$(14)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010000
          DEFB  %00000000

; $0B - Character: '?'          CHR$(15)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00000000
          DEFB  %00001000
          DEFB  %00000000

; $10 - Character: '('          CHR$(16)

          DEFB  %00000000
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00000100
          DEFB  %00000000

; $11 - Character: ')'          CHR$(17)

          DEFB  %00000000
          DEFB  %00100000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00100000
          DEFB  %00000000

; $12 - Character: '>'          CHR$(18)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010000
          DEFB  %00001000
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00010000
          DEFB  %00000000

; $13 - Character: '<'          CHR$(19)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00010000
          DEFB  %00001000
          DEFB  %00000100
          DEFB  %00000000

; $14 - Character: '='          CHR$(20)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00111110
          DEFB  %00000000
          DEFB  %00111110
          DEFB  %00000000
          DEFB  %00000000

; $15 - Character: '+'          CHR$(21)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00111110
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00000000

; $16 - Character: '-'          CHR$(22)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00111110
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000

; $17 - Character: '*'          CHR$(23)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010100
          DEFB  %00001000
          DEFB  %00111110
          DEFB  %00001000
          DEFB  %00010100
          DEFB  %00000000

; $18 - Character: '/'          CHR$(24)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000010
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00010000
          DEFB  %00100000
          DEFB  %00000000

; $19 - Character: ';'          CHR$(25)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00100000

; $1A - Character: ','          CHR$(26)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00010000

; $1B - Character: '"'          CHR$(27)

          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00000000
          DEFB  %00011000
          DEFB  %00011000
          DEFB  %00000000

; $1C - Character: '0'          CHR$(28)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000110
          DEFB  %01001010
          DEFB  %01010010
          DEFB  %01100010
          DEFB  %00111100
          DEFB  %00000000

; $1D - Character: '1'          CHR$(29)

          DEFB  %00000000
          DEFB  %00011000
          DEFB  %00101000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00111110
          DEFB  %00000000

; $1E - Character: '2'          CHR$(30)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %00000010
          DEFB  %00111100
          DEFB  %01000000
          DEFB  %01111110
          DEFB  %00000000

; $1F - Character: '3'          CHR$(31)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %00001100
          DEFB  %00000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $20 - Character: '4'          CHR$(32)

          DEFB  %00000000
          DEFB  %00001000
          DEFB  %00011000
          DEFB  %00101000
          DEFB  %01001000
          DEFB  %01111110
          DEFB  %00001000
          DEFB  %00000000

; $21 - Character: '5'          CHR$(33)

          DEFB  %00000000
          DEFB  %01111110
          DEFB  %01000000
          DEFB  %01111100
          DEFB  %00000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $22 - Character: '6'          CHR$(34)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000000
          DEFB  %01111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $23 - Character: '7'          CHR$(35)

          DEFB  %00000000
          DEFB  %01111110
          DEFB  %00000010
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00000000

; $24 - Character: '8'          CHR$(36)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $25 - Character: '9'          CHR$(37)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111110
          DEFB  %00000010
          DEFB  %00111100
          DEFB  %00000000

; $26 - Character: 'A'          CHR$(38)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01111110
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00000000

; $27 - Character: 'B'          CHR$(39)

          DEFB  %00000000
          DEFB  %01111100
          DEFB  %01000010
          DEFB  %01111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01111100
          DEFB  %00000000

; $28 - Character: 'C'          CHR$(40)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $29 - Character: 'D'          CHR$(41)

          DEFB  %00000000
          DEFB  %01111000
          DEFB  %01000100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000100
          DEFB  %01111000
          DEFB  %00000000

; $2A - Character: 'E'          CHR$(42)

          DEFB  %00000000
          DEFB  %01111110
          DEFB  %01000000
          DEFB  %01111100
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01111110
          DEFB  %00000000

; $2B - Character: 'F'          CHR$(43)

          DEFB  %00000000
          DEFB  %01111110
          DEFB  %01000000
          DEFB  %01111100
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %00000000

; $2C - Character: 'G'          CHR$(44)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000000
          DEFB  %01001110
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $2D - Character: 'H'          CHR$(45)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01111110
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00000000

; $2E - Character: 'I'          CHR$(46)

          DEFB  %00000000
          DEFB  %00111110
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00001000
          DEFB  %00111110
          DEFB  %00000000

; $2F - Character: 'J'          CHR$(47)

          DEFB  %00000000
          DEFB  %00000010
          DEFB  %00000010
          DEFB  %00000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $30 - Character: 'K'          CHR$(48)

          DEFB  %00000000
          DEFB  %01000100
          DEFB  %01001000
          DEFB  %01110000
          DEFB  %01001000
          DEFB  %01000100
          DEFB  %01000010
          DEFB  %00000000

; $31 - Character: 'L'          CHR$(49)

          DEFB  %00000000
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %01111110
          DEFB  %00000000

; $32 - Character: 'M'          CHR$(50)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01100110
          DEFB  %01011010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00000000

; $33 - Character: 'N'          CHR$(51)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01100010
          DEFB  %01010010
          DEFB  %01001010
          DEFB  %01000110
          DEFB  %01000010
          DEFB  %00000000

; $34 - Character: 'O'          CHR$(52)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $35 - Character: 'P'          CHR$(53)

          DEFB  %00000000
          DEFB  %01111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01111100
          DEFB  %01000000
          DEFB  %01000000
          DEFB  %00000000

; $36 - Character: 'Q'          CHR$(54)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01010010
          DEFB  %01001010
          DEFB  %00111100
          DEFB  %00000000

; $37 - Character: 'R'          CHR$(55)

          DEFB  %00000000
          DEFB  %01111100
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01111100
          DEFB  %01000100
          DEFB  %01000010
          DEFB  %00000000

; $38 - Character: 'S'          CHR$(56)

          DEFB  %00000000
          DEFB  %00111100
          DEFB  %01000000
          DEFB  %00111100
          DEFB  %00000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $39 - Character: 'T'          CHR$(57)

          DEFB  %00000000
          DEFB  %11111110
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00000000

; $3A - Character: 'U'          CHR$(58)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00111100
          DEFB  %00000000

; $3B - Character: 'V'          CHR$(59)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %00100100
          DEFB  %00011000
          DEFB  %00000000

; $3C - Character: 'W'          CHR$(60)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01000010
          DEFB  %01011010
          DEFB  %00100100
          DEFB  %00000000

; $3D - Character: 'X'          CHR$(61)

          DEFB  %00000000
          DEFB  %01000010
          DEFB  %00100100
          DEFB  %00011000
          DEFB  %00011000
          DEFB  %00100100
          DEFB  %01000010
          DEFB  %00000000

; $3E - Character: 'Y'          CHR$(62)

          DEFB  %00000000
          DEFB  %10000010
          DEFB  %01000100
          DEFB  %00101000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00010000
          DEFB  %00000000

; $3F - Character: 'Z'          CHR$(63)

          DEFB  %00000000
          DEFB  %01111110
          DEFB  %00000100
          DEFB  %00001000
          DEFB  %00010000
          DEFB  %00100000
          DEFB  %01111110
          DEFB  %00000000

.END                                ;TASM assembler instruction.


