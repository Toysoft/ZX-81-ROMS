#ifdef ROM_sg81
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

sqr:
        rst     FP_CALC         ;; FP-CALC              x
        defb    $C3             ;;st-mem-3              x.   (seed for guess)
        defb    $34             ;;end-calc      x.

;   HL now points to exponent of argument on calculator stack.

        ld      a, (hl)         ; Test for zero argument
        and     a               ;

        ret     z               ; Return with zero on the calculator stack.

;   Test for a positive argument

        inc     hl              ; Address byte with sign bit.
        bit     7, (hl)         ; Test the bit.

        jr      nz, REPORT_Ab   ; back to REPORT_A
                                ; 'Invalid argument'

;   This guess is based on a Usenet discussion.
;   Halve the exponent to achieve a good guess.(accurate with .25 16 64 etc.)

        ld      hl, MEMBOT+4*5  ; Address first byte of mem-3 (mem-4???)

        ld      a, (hl)         ; fetch exponent of mem-3
        xor     $80             ; toggle sign of exponent of mem-3
        sra     a               ; shift right, bit 7 unchanged.
        inc     a               ;
        jr      z, ASIS         ; forward with say .25 -> .5
        jp      p, ASIS         ; leave increment if value > .5
        dec     a               ; restore to shift only.
ASIS:
        xor     $80             ; restore sign.
        ld      (hl), a         ; and put back 'halved' exponent.

;   Now re-enter the calculator.

        rst     FP_CALC         ;; FP-CALC              x

SLOOP:
        defb    $2D             ;;duplicate             x,x.
        defb    $E3             ;;get-mem-3             x,x,guess
        defb    $C4             ;;st-mem-4              x,x,guess
        defb    $05             ;;div                   x,x/guess.
        defb    $E3             ;;get-mem-3             x,x/guess,guess
        defb    $0F             ;;addition              x,x/guess+guess
        defb    $A2             ;;stk-half              x,x/guess+guess,.5
        defb    $04             ;;multiply              x,(x/guess+guess)*.5
        defb    $C3             ;;st-mem-3              x,newguess
        defb    $E4             ;;get-mem-4             x,newguess,oldguess
        defb    $03             ;;subtract              x,newguess-oldguess
        defb    $27             ;;abs                   x,difference.
        defb    $33             ;;greater-0             x,(0/1).
        defb    $00             ;;jump-true             x.

        defb    SLOOP - ASMPC   ;;to sloop              x.

        defb    $02             ;;delete                .
        defb    $E3             ;;get-mem-3             retrieve final guess.
        defb    $34             ;;end-calc              sqr x.

        ret                     ; return with square root on stack

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

#else
; ------------------------------
; THE OLD 'SQUARE ROOT' FUNCTION
; ------------------------------
; (Offset $25: 'sqr')
;   Error A if argument is negative.
;   This routine is remarkable for its brevity - 7 bytes.
;   The ZX81 code was originally 9K and various techniques had to be
;   used to shoe-horn it into an 8K Rom chip.


sqr:
        rst     FP_CALC         ;; FP-CALC              x.
        defb    $2D             ;;duplicate             x, x.
        defb    $2C             ;;not                   x, 1/0
        defb    $00             ;;jump-true             x, (1/0).
        defb    LAST - ASMPC    ;;to L1DFD, LAST        exit if argument zero
                                ;;                      with zero result.

;   else continue to calculate as x ** .5

        defb    $A2             ;;stk-half              x, .5.
        defb    $34             ;;end-calc              x, .5.
#endif

