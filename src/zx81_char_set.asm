; ------------------------
; THE 'ZX81 CHARACTER SET'
; ------------------------

;; char-set - begins with space character.

; $00 - Character: ' '          CHR$(0)

char_set:
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000

; $01 - Character: mosaic       CHR$(1)

        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000


; $02 - Character: mosaic       CHR$(2)

        defb    %00001111
        defb    %00001111
        defb    %00001111
        defb    %00001111
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000


; $03 - Character: mosaic       CHR$(3)

        defb    %11111111
        defb    %11111111
        defb    %11111111
        defb    %11111111
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000

; $04 - Character: mosaic       CHR$(4)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000

; $05 - Character: mosaic       CHR$(5)

        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000

; $06 - Character: mosaic       CHR$(6)

        defb    %00001111
        defb    %00001111
        defb    %00001111
        defb    %00001111
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000

; $07 - Character: mosaic       CHR$(7)

        defb    %11111111
        defb    %11111111
        defb    %11111111
        defb    %11111111
        defb    %11110000
        defb    %11110000
        defb    %11110000
        defb    %11110000

; $08 - Character: mosaic       CHR$(8)

        defb    %10101010
        defb    %01010101
        defb    %10101010
        defb    %01010101
        defb    %10101010
        defb    %01010101
        defb    %10101010
        defb    %01010101

; $09 - Character: mosaic       CHR$(9)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %10101010
        defb    %01010101
        defb    %10101010
        defb    %01010101

; $0A - Character: mosaic       CHR$(10)

        defb    %10101010
        defb    %01010101
        defb    %10101010
        defb    %01010101
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000

; $0B - Character: '"'          CHR$(11)

        defb    %00000000
        defb    %00100100
        defb    %00100100
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000

; $0B - Character: ukp          CHR$(12)

        defb    %00000000
        defb    %00011100
        defb    %00100010
        defb    %01111000
        defb    %00100000
        defb    %00100000
        defb    %01111110
        defb    %00000000

; $0B - Character: '$'          CHR$(13)

        defb    %00000000
        defb    %00001000
        defb    %00111110
        defb    %00101000
        defb    %00111110
        defb    %00001010
        defb    %00111110
        defb    %00001000

; $0B - Character: ':'          CHR$(14)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00010000
        defb    %00000000
        defb    %00000000
        defb    %00010000
        defb    %00000000

; $0B - Character: '?'          CHR$(15)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %00000100
        defb    %00001000
        defb    %00000000
        defb    %00001000
        defb    %00000000

; $10 - Character: '('          CHR$(16)

        defb    %00000000
        defb    %00000100
        defb    %00001000
        defb    %00001000
        defb    %00001000
        defb    %00001000
        defb    %00000100
        defb    %00000000

; $11 - Character: ')'          CHR$(17)

        defb    %00000000
        defb    %00100000
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00100000
        defb    %00000000

; $12 - Character: '>'          CHR$(18)

        defb    %00000000
        defb    %00000000
        defb    %00010000
        defb    %00001000
        defb    %00000100
        defb    %00001000
        defb    %00010000
        defb    %00000000

; $13 - Character: '<'          CHR$(19)

        defb    %00000000
        defb    %00000000
        defb    %00000100
        defb    %00001000
        defb    %00010000
        defb    %00001000
        defb    %00000100
        defb    %00000000

; $14 - Character: '='          CHR$(20)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00111110
        defb    %00000000
        defb    %00111110
        defb    %00000000
        defb    %00000000

; $15 - Character: '+'          CHR$(21)

        defb    %00000000
        defb    %00000000
        defb    %00001000
        defb    %00001000
        defb    %00111110
        defb    %00001000
        defb    %00001000
        defb    %00000000

; $16 - Character: '-'          CHR$(22)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00111110
        defb    %00000000
        defb    %00000000
        defb    %00000000

; $17 - Character: '*'          CHR$(23)

        defb    %00000000
        defb    %00000000
        defb    %00010100
        defb    %00001000
        defb    %00111110
        defb    %00001000
        defb    %00010100
        defb    %00000000

; $18 - Character: '/'          CHR$(24)

        defb    %00000000
        defb    %00000000
        defb    %00000010
        defb    %00000100
        defb    %00001000
        defb    %00010000
        defb    %00100000
        defb    %00000000

; $19 - Character: ';'          CHR$(25)

        defb    %00000000
        defb    %00000000
        defb    %00010000
        defb    %00000000
        defb    %00000000
        defb    %00010000
        defb    %00010000
        defb    %00100000

; $1A - Character: ','          CHR$(26)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00001000
        defb    %00001000
        defb    %00010000

; $1B - Character: '.'          CHR$(27)

        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00000000
        defb    %00011000
        defb    %00011000
        defb    %00000000

; $1C - Character: '0'          CHR$(28)

        defb    %00000000
        defb    %00111100
        defb    %01000110
        defb    %01001010
        defb    %01010010
        defb    %01100010
        defb    %00111100
        defb    %00000000

; $1D - Character: '1'          CHR$(29)

        defb    %00000000
        defb    %00011000
        defb    %00101000
        defb    %00001000
        defb    %00001000
        defb    %00001000
        defb    %00111110
        defb    %00000000

; $1E - Character: '2'          CHR$(30)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %00000010
        defb    %00111100
        defb    %01000000
        defb    %01111110
        defb    %00000000

; $1F - Character: '3'          CHR$(31)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %00001100
        defb    %00000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $20 - Character: '4'          CHR$(32)

        defb    %00000000
        defb    %00001000
        defb    %00011000
        defb    %00101000
        defb    %01001000
        defb    %01111110
        defb    %00001000
        defb    %00000000

; $21 - Character: '5'          CHR$(33)

        defb    %00000000
        defb    %01111110
        defb    %01000000
        defb    %01111100
        defb    %00000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $22 - Character: '6'          CHR$(34)

        defb    %00000000
        defb    %00111100
        defb    %01000000
        defb    %01111100
        defb    %01000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $23 - Character: '7'          CHR$(35)

        defb    %00000000
        defb    %01111110
        defb    %00000010
        defb    %00000100
        defb    %00001000
        defb    %00010000
        defb    %00010000
        defb    %00000000

; $24 - Character: '8'          CHR$(36)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %00111100
        defb    %01000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $25 - Character: '9'          CHR$(37)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000010
        defb    %00111110
        defb    %00000010
        defb    %00111100
        defb    %00000000

; $26 - Character: 'A'          CHR$(38)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000010
        defb    %01111110
        defb    %01000010
        defb    %01000010
        defb    %00000000

; $27 - Character: 'B'          CHR$(39)

        defb    %00000000
        defb    %01111100
        defb    %01000010
        defb    %01111100
        defb    %01000010
        defb    %01000010
        defb    %01111100
        defb    %00000000

; $28 - Character: 'C'          CHR$(40)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000000
        defb    %01000000
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $29 - Character: 'D'          CHR$(41)

        defb    %00000000
        defb    %01111000
        defb    %01000100
        defb    %01000010
        defb    %01000010
        defb    %01000100
        defb    %01111000
        defb    %00000000

; $2A - Character: 'E'          CHR$(42)

        defb    %00000000
        defb    %01111110
        defb    %01000000
        defb    %01111100
        defb    %01000000
        defb    %01000000
        defb    %01111110
        defb    %00000000

; $2B - Character: 'F'          CHR$(43)

        defb    %00000000
        defb    %01111110
        defb    %01000000
        defb    %01111100
        defb    %01000000
        defb    %01000000
        defb    %01000000
        defb    %00000000

; $2C - Character: 'G'          CHR$(44)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000000
        defb    %01001110
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $2D - Character: 'H'          CHR$(45)

        defb    %00000000
        defb    %01000010
        defb    %01000010
        defb    %01111110
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %00000000

; $2E - Character: 'I'          CHR$(46)

        defb    %00000000
        defb    %00111110
        defb    %00001000
        defb    %00001000
        defb    %00001000
        defb    %00001000
        defb    %00111110
        defb    %00000000

; $2F - Character: 'J'          CHR$(47)

        defb    %00000000
        defb    %00000010
        defb    %00000010
        defb    %00000010
        defb    %01000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $30 - Character: 'K'          CHR$(48)

        defb    %00000000
        defb    %01000100
        defb    %01001000
        defb    %01110000
        defb    %01001000
        defb    %01000100
        defb    %01000010
        defb    %00000000

; $31 - Character: 'L'          CHR$(49)

        defb    %00000000
        defb    %01000000
        defb    %01000000
        defb    %01000000
        defb    %01000000
        defb    %01000000
        defb    %01111110
        defb    %00000000

; $32 - Character: 'M'          CHR$(50)

        defb    %00000000
        defb    %01000010
        defb    %01100110
        defb    %01011010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %00000000

; $33 - Character: 'N'          CHR$(51)

        defb    %00000000
        defb    %01000010
        defb    %01100010
        defb    %01010010
        defb    %01001010
        defb    %01000110
        defb    %01000010
        defb    %00000000

; $34 - Character: 'O'          CHR$(52)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $35 - Character: 'P'          CHR$(53)

        defb    %00000000
        defb    %01111100
        defb    %01000010
        defb    %01000010
        defb    %01111100
        defb    %01000000
        defb    %01000000
        defb    %00000000

; $36 - Character: 'Q'          CHR$(54)

        defb    %00000000
        defb    %00111100
        defb    %01000010
        defb    %01000010
        defb    %01010010
        defb    %01001010
        defb    %00111100
        defb    %00000000

; $37 - Character: 'R'          CHR$(55)

        defb    %00000000
        defb    %01111100
        defb    %01000010
        defb    %01000010
        defb    %01111100
        defb    %01000100
        defb    %01000010
        defb    %00000000

; $38 - Character: 'S'          CHR$(56)

        defb    %00000000
        defb    %00111100
        defb    %01000000
        defb    %00111100
        defb    %00000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $39 - Character: 'T'          CHR$(57)

        defb    %00000000
        defb    %11111110
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00000000

; $3A - Character: 'U'          CHR$(58)

        defb    %00000000
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %00111100
        defb    %00000000

; $3B - Character: 'V'          CHR$(59)

        defb    %00000000
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %00100100
        defb    %00011000
        defb    %00000000

; $3C - Character: 'W'          CHR$(60)

        defb    %00000000
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01000010
        defb    %01011010
        defb    %00100100
        defb    %00000000

; $3D - Character: 'X'          CHR$(61)

        defb    %00000000
        defb    %01000010
        defb    %00100100
        defb    %00011000
        defb    %00011000
        defb    %00100100
        defb    %01000010
        defb    %00000000

; $3E - Character: 'Y'          CHR$(62)

        defb    %00000000
        defb    %10000010
        defb    %01000100
        defb    %00101000
        defb    %00010000
        defb    %00010000
        defb    %00010000
        defb    %00000000

; $3F - Character: 'Z'          CHR$(63)

        defb    %00000000
        defb    %01111110
        defb    %00000100
        defb    %00001000
        defb    %00010000
        defb    %00100000
        defb    %01111110
        defb    %00000000
