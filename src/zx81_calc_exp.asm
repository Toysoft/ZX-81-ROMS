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

to_power:
        rst     FP_CALC         ;; FP-CALC              X,Y.
        defb    $01             ;;exchange              Y,X.
        defb    $2D             ;;duplicate             Y,X,X.
        defb    $2C             ;;not                   Y,X,(1/0).
        defb    $00             ;;jump-true
        defb    XISO - ASMPC    ;;forward to L1DEE, XISO if X is zero.

;   else X is non-zero. function 'ln' will catch a negative value of X.

        defb    $22             ;;ln                    Y, LN X.

;   Multiply the power by the logarithm of the argument.

        defb    $04             ;;multiply              Y * LN X
        defb    $34             ;;end-calc

        jp      exp             ; jump back to EXP routine             ->>
                                ; to find the 'antiln'

; ---

;   These routines form the three simple results when the number is zero.
;   begin by deleting the known zero to leave Y the power factor.

XISO:
        defb    $02             ;;delete                Y.
        defb    $2D             ;;duplicate             Y, Y.
        defb    $2C             ;;not                   Y, (1/0).
        defb    $00             ;;jump-true
        defb    ONE - ASMPC     ;;forward to L1DFB, ONE if Y is zero.

;   the power factor is not zero. If negative then an error exists.

        defb    $A0             ;;stk-zero              Y, 0.
        defb    $01             ;;exchange              0, Y.
        defb    $33             ;;greater-0             0, (1/0).
        defb    $00             ;;jump-true             0
        defb    LAST - ASMPC    ;;to L1DFD, LAST        if Y was any positive
                                ;;                      number.

;   else force division by zero thereby raising an Arithmetic overflow error.
;   There are some one and two-byte alternatives but perhaps the most formal
;   might have been to use end-calc; rst 08; defb 05.

        defb    $A1             ;;stk-one               0, 1.
        defb    $01             ;;exchange              1, 0.
        defb    $05             ;;division              1/0    >> error

; ---

ONE:
        defb    $02             ;;delete                .
        defb    $A1             ;;stk-one               1.

LAST:
        defb    $34             ;;end-calc              last value 1 or 0.

        ret                     ; return.

