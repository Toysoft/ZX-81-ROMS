; ****************
; ** KEY TABLES **
; ****************

; -------------------------------
; THE 'UNSHIFTED' CHARACTER CODES
; -------------------------------

K_UNSHIFT:
        defb    $3F             ; Z
        defb    $3D             ; X
        defb    $28             ; C
        defb    $3B             ; V
        defb    $26             ; A
        defb    $38             ; S
        defb    $29             ; D
        defb    $2B             ; F
        defb    $2C             ; G
        defb    $36             ; Q
        defb    $3C             ; W
        defb    $2A             ; E
        defb    $37             ; R
        defb    $39             ; T
        defb    $1D             ; 1
        defb    $1E             ; 2
        defb    $1F             ; 3
        defb    $20             ; 4
        defb    $21             ; 5
        defb    $1C             ; 0
        defb    $25             ; 9
        defb    $24             ; 8
        defb    $23             ; 7
        defb    $22             ; 6
        defb    $35             ; P
        defb    $34             ; O
        defb    $2E             ; I
        defb    $3A             ; U
        defb    $3E             ; Y
        defb    $76             ; NEWLINE
        defb    $31             ; L
        defb    $30             ; K
        defb    $2F             ; J
        defb    $2D             ; H
        defb    $00             ; SPACE
        defb    $1B             ; .
        defb    $32             ; M
        defb    $33             ; N
        defb    $27             ; B

; -----------------------------
; THE 'SHIFTED' CHARACTER CODES
; -----------------------------

K_SHIFT:
        defb    $0E             ; :
        defb    $19             ; ;
        defb    $0F             ; ?
        defb    $18             ; /
        defb    $E3             ; STOP
        defb    $E1             ; LPRINT
        defb    $E4             ; SLOW
        defb    $E5             ; FAST
        defb    $E2             ; LLIST
        defb    $C0             ; ""
        defb    $D9             ; OR
        defb    $E0             ; STEP
        defb    $DB             ; <=
        defb    $DD             ; <>
        defb    $75             ; EDIT
        defb    $DA             ; AND
        defb    $de             ; THEN
        defb    $DF             ; TO
        defb    $72             ; cursor-left
        defb    $77             ; RUBOUT
        defb    $74             ; GRAPHICS
        defb    $73             ; cursor-right
        defb    $70             ; cursor-up
        defb    $71             ; cursor-down
        defb    $0B             ; "
        defb    $11             ; )
        defb    $10             ; (
        defb    $0D             ; $
        defb    $DC             ; >=
        defb    $79             ; FUNCTION
        defb    $14             ; =
        defb    $15             ; +
        defb    $16             ; -
        defb    $D8             ; **
        defb    $0C             ; ukp
        defb    $1A             ; ,
        defb    $12             ; >
        defb    $13             ; <
        defb    $17             ; *

; ------------------------------
; THE 'FUNCTION' CHARACTER CODES
; ------------------------------

K_FUNCT:
        defb    $CD             ; LN
        defb    $CE             ; EXP
        defb    $C1             ; AT
        defb    $78             ; KL
        defb    $CA             ; ASN
        defb    $CB             ; ACS
        defb    $CC             ; ATN
        defb    $D1             ; SGN
        defb    $D2             ; ABS
        defb    $C7             ; SIN
        defb    $C8             ; COS
        defb    $C9             ; TAN
        defb    $CF             ; INT
        defb    $40             ; RND
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $C2             ; TAB
        defb    $D3             ; PEEK
        defb    $C4             ; CODE
        defb    $D6             ; CHR$
        defb    $D5             ; STR$
        defb    $78             ; KL
        defb    $D4             ; USR
        defb    $C6             ; LEN
        defb    $C5             ; VAL
        defb    $D0             ; SQR
        defb    $78             ; KL
        defb    $78             ; KL
        defb    $42             ; PI
        defb    $D7             ; NOT
        defb    $41             ; INKEY$

; -----------------------------
; THE 'GRAPHIC' CHARACTER CODES
; -----------------------------

K_GRAPH:
        defb    $08             ; graphic
        defb    $0A             ; graphic
        defb    $09             ; graphic
        defb    $8A             ; graphic
        defb    $89             ; graphic
        defb    $81             ; graphic
        defb    $82             ; graphic
        defb    $07             ; graphic
        defb    $84             ; graphic
        defb    $06             ; graphic
        defb    $01             ; graphic
        defb    $02             ; graphic
        defb    $87             ; graphic
        defb    $04             ; graphic
        defb    $05             ; graphic
        defb    $77             ; RUBOUT
        defb    $78             ; KL
        defb    $85             ; graphic
        defb    $03             ; graphic
        defb    $83             ; graphic
        defb    $8B             ; graphic
        defb    $91             ; inverse )
        defb    $90             ; inverse (
        defb    $8D             ; inverse $
        defb    $86             ; graphic
        defb    $78             ; KL
        defb    $92             ; inverse >
        defb    $95             ; inverse +
        defb    $96             ; inverse -
        defb    $88             ; graphic

; ------------------
; THE 'TOKEN' TABLES
; ------------------

TOKENS_TAB:
        defb    $0F+$80         ; '?'+$80
        defb    $0B, $0B+$80    ; ""
        defb    $26, $39+$80    ; AT
        defb    $39, $26, $27+$80
                                ; TAB
        defb    $0F+$80         ; '?'+$80
        defb    $28, $34, $29, $2A+$80
                                ; CODE
        defb    $3B, $26, $31+$80
                                ; VAL
        defb    $31, $2A, $33+$80
                                ; LEN
        defb    $38, $2E, $33+$80
                                ; SIN
        defb    $28, $34, $38+$80
                                ; COS
        defb    $39, $26, $33+$80
                                ; TAN
        defb    $26, $38, $33+$80
                                ; ASN
        defb    $26, $28, $38+$80
                                ; ACS
        defb    $26, $39, $33+$80
                                ; ATN
        defb    $31, $33+$80    ; LN
        defb    $2A, $3D, $35+$80
                                ; EXP
        defb    $2E, $33, $39+$80
                                ; INT
        defb    $38, $36, $37+$80
                                ; SQR
        defb    $38, $2C, $33+$80
                                ; SGN
        defb    $26, $27, $38+$80
                                ; ABS
        defb    $35, $2A, $2A, $30+$80
                                ; PEEK
        defb    $3A, $38, $37+$80
                                ; USR
        defb    $38, $39, $37, $0D+$80
                                ; STR$
        defb    $28, $2D, $37, $0D+$80
                                ; CHR$
        defb    $33, $34, $39+$80
                                ; NOT
        defb    $17, $17+$80    ; **
        defb    $34, $37+$80    ; OR
        defb    $26, $33, $29+$80
                                ; AND
        defb    $13, $14+$80    ; <=
        defb    $12, $14+$80    ; >=
        defb    $13, $12+$80    ; <>
        defb    $39, $2D, $2A, $33+$80
                                ; THEN
        defb    $39, $34+$80    ; TO
        defb    $38, $39, $2A, $35+$80
                                ; STEP
        defb    $31, $35, $37, $2E, $33, $39+$80
                                ; LPRINT
        defb    $31, $31, $2E, $38, $39+$80
                                ; LLIST
        defb    $38, $39, $34, $35+$80
                                ; STOP
        defb    $38, $31, $34, $3C+$80
                                ; SLOW
        defb    $2B, $26, $38, $39+$80
                                ; FAST
        defb    $33, $2A, $3C+$80
                                ; NEW
        defb    $38, $28, $37, $34, $31, $31+$80
                                ; SCROLL
        defb    $28, $34, $33, $39+$80
                                ; CONT
        defb    $29, $2E, $32+$80
                                ; DIM
        defb    $37, $2A, $32+$80
                                ; REM
        defb    $2B, $34, $37+$80
                                ; FOR
        defb    $2C, $34, $39, $34+$80
                                ; GOTO
        defb    $2C, $34, $38, $3A, $27+$80
                                ; GOSUB
        defb    $2E, $33, $35, $3A, $39+$80
                                ; INPUT
        defb    $31, $34, $26, $29+$80
                                ; LOAD
        defb    $31, $2E, $38, $39+$80
                                ; LIST
        defb    $31, $2A, $39+$80
                                ; LET
        defb    $35, $26, $3A, $38, $2A+$80
                                ; PAUSE
        defb    $33, $2A, $3D, $39+$80
                                ; NEXT
        defb    $35, $34, $30, $2A+$80
                                ; POKE
        defb    $35, $37, $2E, $33, $39+$80
                                ; PRINT
        defb    $35, $31, $34, $39+$80
                                ; PLOT
        defb    $37, $3A, $33+$80
                                ; RUN
        defb    $38, $26, $3B, $2A+$80
                                ; SAVE
        defb    $37, $26, $33, $29+$80
                                ; RAND
        defb    $2E, $2B+$80    ; IF
        defb    $28, $31, $38+$80
                                ; CLS
        defb    $3A, $33, $35, $31, $34, $39+$80
                                ; UNPLOT
        defb    $28, $31, $2A, $26, $37+$80
                                ; CLEAR
        defb    $37, $2A, $39, $3A, $37, $33+$80
                                ; RETURN
        defb    $28, $34, $35, $3E+$80
                                ; COPY
        defb    $37, $33, $29+$80
                                ; RND
        defb    $2E, $33, $30, $2A, $3E, $0D+$80
                                ; INKEY$
        defb    $35, $2E+$80    ; PI

