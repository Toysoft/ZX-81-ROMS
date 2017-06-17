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


get_argt:
        rst     FP_CALC         ;; FP-CALC         X.
        defb    $30             ;;stk-data
        defb    $EE             ;;Exponent: $7E,
                                ;;Bytes: 4
        defb    $22, $F9, $83, $6E
                                ;;                 X, 1/(2*PI)
        defb    $04             ;;multiply         X/(2*PI) = fraction

        defb    $2D             ;;duplicate
        defb    $A2             ;;stk-half
        defb    $0F             ;;addition
        defb    $24             ;;int

        defb    $03             ;;subtract         now range -.5 to .5

        defb    $2D             ;;duplicate
        defb    $0F             ;;addition         now range -1 to 1.
        defb    $2D             ;;duplicate
        defb    $0F             ;;addition         now range -2 to 2.

;   quadrant I (0 to +1) and quadrant IV (-1 to 0) are now correct.
;   quadrant II ranges +1 to +2.
;   quadrant III ranges -2 to -1.

        defb    $2D             ;;duplicate        Y, Y.
        defb    $27             ;;abs              Y, abs(Y).    range 1 to 2
        defb    $A1             ;;stk-one          Y, abs(Y), 1.
        defb    $03             ;;subtract         Y, abs(Y)-1.  range 0 to 1
        defb    $2D             ;;duplicate        Y, Z, Z.
        defb    $33             ;;greater-0        Y, Z, (1/0).

        defb    $C0             ;;st-mem-0         store as possible sign
                                ;;                 for cosine function.

        defb    $00             ;;jump-true
        defb    ZPLUS - ASMPC   ;;to L1D35, ZPLUS  with quadrants II and III

;   else the angle lies in quadrant I or IV and value Y is already correct.

        defb    $02             ;;delete          Y    delete test value.
        defb    $34             ;;end-calc        Y.

        ret                     ; return.         with Q1 and Q4 >>>

;   The branch was here with quadrants II (0 to 1) and III (1 to 0).
;   Y will hold -2 to -1 if this is quadrant III.

ZPLUS:
        defb    $A1             ;;stk-one         Y, Z, 1
        defb    $03             ;;subtract        Y, Z-1.       Q3 = 0 to -1
        defb    $01             ;;exchange        Z-1, Y.
        defb    $32             ;;less-0          Z-1, (1/0).
        defb    $00             ;;jump-true       Z-1.
        defb    YNEG - ASMPC    ;;to L1D3C, YNEG
                                ;;if angle in quadrant III

;   else angle is within quadrant II (-1 to 0)

        defb    $18             ;;negate          range +1 to 0


YNEG:
        defb    $34             ;;end-calc        quadrants II and III correct.

        ret                     ; return.


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

cos:
        rst     FP_CALC         ;; FP-CALC              angle in radians.
        defb    $35             ;;get-argt              X       reduce -1 to +1

        defb    $27             ;;abs                   ABS X   0 to 1
        defb    $A1             ;;stk-one               ABS X, 1.
        defb    $03             ;;subtract              now opposite angle
                                ;;                      though negative sign.
        defb    $E0             ;;get-mem-0             fetch sign indicator.
        defb    $00             ;;jump-true
        defb    C_ENT - ASMPC   ;;fwd to L1D4B, C-ENT
                                ;;forward to common code if in QII or QIII


        defb    $18             ;;negate                else make positive.
        defb    $2F             ;;jump
        defb    C_ENT - ASMPC   ;;fwd to L1D4B, C-ENT
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

sin:
        rst     FP_CALC         ;; FP-CALC      angle in radians
        defb    $35             ;;get-argt      reduce - sign now correct.

C_ENT:
        defb    $2D             ;;duplicate
        defb    $2D             ;;duplicate
        defb    $04             ;;multiply
        defb    $2D             ;;duplicate
        defb    $0F             ;;addition
        defb    $A1             ;;stk-one
        defb    $03             ;;subtract

        defb    $86             ;;series-06
        defb    $14             ;;Exponent: $64, Bytes: 1
        defb    $E6             ;;(+00,+00,+00)
        defb    $5C             ;;Exponent: $6C, Bytes: 2
        defb    $1F, $0B        ;;(+00,+00)
        defb    $A3             ;;Exponent: $73, Bytes: 3
        defb    $8F, $38, $EE   ;;(+00)
        defb    $E9             ;;Exponent: $79, Bytes: 4
        defb    $15, $63, $BB, $23
                                ;;
        defb    $EE             ;;Exponent: $7E, Bytes: 4
        defb    $92, $0D, $CD, $ED
                                ;;
        defb    $F1             ;;Exponent: $81, Bytes: 4
        defb    $23, $5D, $1B, $EA
                                ;;

        defb    $04             ;;multiply
        defb    $34             ;;end-calc

        ret                     ; return.


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
;   divided by the length of the adjacent side. As the opposite length can
;   be calculates using sin(x) and the adjacent length using cos(x) then
;   the tangent can be defined in terms of the previous two functions.

;   Error 6 if the argument, in radians, is too close to one like pi/2
;   which has an infinite tangent. e.g. PRINT TAN (PI/2)  evaluates as 1/0.
;   Similarly PRINT TAN (3*PI/2), TAN (5*PI/2) etc.

tan:
        rst     FP_CALC         ;; FP-CALC          x.
        defb    $2D             ;;duplicate         x, x.
        defb    $1C             ;;sin               x, sin x.
        defb    $01             ;;exchange          sin x, x.
        defb    $1D             ;;cos               sin x, cos x.
        defb    $05             ;;division          sin x/cos x (= tan x).
        defb    $34             ;;end-calc          tan x.

        ret                     ; return.

; ---------------------
; THE 'ARCTAN' FUNCTION
; ---------------------
; (Offset $21: 'atn')
;   The inverse tangent function with the result in radians.
;   This is a fundamental transcendental function from which others such as
;   asn and acs are directly, or indirectly, derived.
;   It uses the series generator to produce Chebyshev polynomials.

atn:
        ld      a, (hl)         ; fetch exponent
        cp      $81             ; compare to that for 'one'
        jr      c, SMALL        ; forward, if less, to SMALL

        rst     FP_CALC         ;; FP-CALC      X.
        defb    $A1             ;;stk-one
        defb    $18             ;;negate
        defb    $01             ;;exchange
        defb    $05             ;;division
        defb    $2D             ;;duplicate
        defb    $32             ;;less-0
        defb    $A3             ;;stk-pi/2
        defb    $01             ;;exchange
        defb    $00             ;;jump-true
        defb    CASES - ASMPC   ;;to L1D8B, CASES

        defb    $18             ;;negate
        defb    $2F             ;;jump
        defb    CASES - ASMPC   ;;to L1D8B, CASES

; ---

SMALL:
        rst     FP_CALC         ;; FP-CALC
        defb    $A0             ;;stk-zero

CASES:
        defb    $01             ;;exchange
        defb    $2D             ;;duplicate
        defb    $2D             ;;duplicate
        defb    $04             ;;multiply
        defb    $2D             ;;duplicate
        defb    $0F             ;;addition
        defb    $A1             ;;stk-one
        defb    $03             ;;subtract

        defb    $8C             ;;series-0C
        defb    $10             ;;Exponent: $60, Bytes: 1
        defb    $B2             ;;(+00,+00,+00)
        defb    $13             ;;Exponent: $63, Bytes: 1
        defb    $0E             ;;(+00,+00,+00)
        defb    $55             ;;Exponent: $65, Bytes: 2
        defb    $E4, $8D        ;;(+00,+00)
        defb    $58             ;;Exponent: $68, Bytes: 2
        defb    $39, $bc        ;;(+00,+00)
        defb    $5B             ;;Exponent: $6B, Bytes: 2
        defb    $98, $FD        ;;(+00,+00)
        defb    $9E             ;;Exponent: $6E, Bytes: 3
        defb    $00, $36, $75   ;;(+00)
        defb    $A0             ;;Exponent: $70, Bytes: 3
        defb    $DB, $E8, $B4   ;;(+00)
        defb    $63             ;;Exponent: $73, Bytes: 2
        defb    $42, $C4        ;;(+00,+00)
        defb    $E6             ;;Exponent: $76, Bytes: 4
        defb    $B5, $09, $36, $BE
                                ;;
        defb    $E9             ;;Exponent: $79, Bytes: 4
        defb    $36, $73, $1B, $5D
                                ;;
        defb    $EC             ;;Exponent: $7C, Bytes: 4
        defb    $D8, $de, $63, $BE
                                ;;
        defb    $F0             ;;Exponent: $80, Bytes: 4
        defb    $61, $A1, $B3, $0C
                                ;;

        defb    $04             ;;multiply
        defb    $0F             ;;addition
        defb    $34             ;;end-calc

        ret                     ; return.


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
;   c are also equal. If b+c+c = 180 degrees and b+a = 180 degrees then c=a/2.
;
;   A value higher than 1 gives the required error as attempting to find  the
;   square root of a negative number generates an error in Sinclair BASIC.

asn:
        rst     FP_CALC         ;; FP-CALC      x.
        defb    $2D             ;;duplicate     x, x.
        defb    $2D             ;;duplicate     x, x, x.
        defb    $04             ;;multiply      x, x*x.
        defb    $A1             ;;stk-one       x, x*x, 1.
        defb    $03             ;;subtract      x, x*x-1.
        defb    $18             ;;negate        x, 1-x*x.
        defb    $25             ;;sqr           x, sqr(1-x*x) = y.
        defb    $A1             ;;stk-one       x, y, 1.
        defb    $0F             ;;addition      x, y+1.
        defb    $05             ;;division      x/y+1.
        defb    $21             ;;atn           a/2     (half the angle)
        defb    $2D             ;;duplicate     a/2, a/2.
        defb    $0F             ;;addition      a.
        defb    $34             ;;end-calc      a.

        ret                     ; return.


; ------------------------
; THE 'ARCCOS' FUNCTION
; ------------------------
; (Offset $20: 'acs')
;   The inverse cosine function with the result in radians.
;   Error A unless the argument is between -1 and +1.
;   Result in range 0 to pi.
;   Derived from asn above which is in turn derived from the preceding atn. 
;	It could have been derived directly from atn using acs(x) = atn(sqr(1-x*x)/x).
;   However, as sine and cosine are horizontal translations of each other,
;   uses acs(x) = pi/2 - asn(x)

;   e.g. the arccosine of a known x value will give the required angle b in
;   radians.
;   We know, from above, how to calculate the angle a using asn(x).
;   Since the three angles of any triangle add up to 180 degrees, or pi radians,
;   and the largest angle in this case is a right-angle (pi/2 radians), then
;   we can calculate angle b as pi/2 (both angles) minus asn(x) (angle a).
;
;
;            /|
;         1 /b|
;          /  |x
;         /a  |
;        /----|
;          y

acs:
        rst     FP_CALC         ;; FP-CALC      x.
        defb    $1F             ;;asn           asn(x).
        defb    $A3             ;;stk-pi/2      asn(x), pi/2.
        defb    $03             ;;subtract      asn(x) - pi/2.
        defb    $18             ;;negate        pi/2 - asn(x) = acs(x).
        defb    $34             ;;end-calc      acs(x)

        ret                     ; return.


