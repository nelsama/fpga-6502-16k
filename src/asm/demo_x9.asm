; ============================================
; demo_x9.asm -- PRUEBA DE X DE 9 BITS (sprites en todo el ancho)
;
; Un sprite (8x8) recorre TODO el ancho de la pantalla (X=4 .. 312) y vuelve,
; cruzando X=255 (el bit 8 de X, que va en el bit 2 de FLAGS).
;
; OAM del sprite 0 (5 bytes):
;   +0 X (8 bits bajos)
;   +1 Y
;   +2 TILE
;   +3 FLAGS = bit2 = X bit8 | SCALE2X | PALETA
;   +4 COLL_POINT
;
; El sprite se mueve 1 px por frame. Al cruzar 255->256, FLAGS bit2 pasa de
; 0 a 1; al bajar de 256 a 255, vuelve a 0.
;
; Zero page:
;   $10 XLO (byte bajo de X)  $11 XHI (bit 8, 0 o 1)  $12 DIR
; ============================================

    .setcpu "6502"

VID_LO = $D800
VID_HI = $D801
VID_DT = $D802
VID_ST = $D803

XLO   = $10
XHI   = $11
DIR   = $12

    .segment "CODE"
    .org $8000

reset:
    SEI
    CLD
    LDX #$FF
    TXS

wait_ready:
    LDA VID_ST
    AND #$10
    BEQ wait_ready

    ; --- cargar un patron de sprite simple (cuadrado) en sprite 0 ---
    LDY #0
ld_spr:
    LDA #$C8
    STA VID_HI
    TYA
    STA VID_LO
    LDA square_p0,Y
    STA VID_DT
    LDA #$E8
    STA VID_HI
    TYA
    STA VID_LO
    LDA square_p1,Y
    STA VID_DT
    INY
    CPY #8
    BNE ld_spr

    ; --- sprite 0: X=4, Y=120 ---
    LDA #4
    STA XLO
    LDA #0
    STA XHI
    STA DIR            ; 0 = derecha

    ; X (byte 0)
    LDA #$C0
    STA VID_HI
    LDA #0
    STA VID_LO
    LDA XLO
    STA VID_DT
    ; Y (byte 1)
    LDA #$C0
    STA VID_HI
    LDA #1
    STA VID_LO
    LDA #120
    STA VID_DT
    ; TILE (byte 2)
    LDA #$C0
    STA VID_HI
    LDA #2
    STA VID_LO
    LDA #0
    STA VID_DT
    ; FLAGS (byte 3): paleta 0, sin scale, bit2 = bit8 de X
    LDA #$C0
    STA VID_HI
    LDA #3
    STA VID_LO
    LDA #$00
    STA VID_DT

    ; ============================================
    ; bucle principal
    ; ============================================
main_loop:
wvb:
    LDA VID_ST
    AND #$80
    BEQ wvb

    ; --- mover X (9 bits): X = XHI*256 + XLO ---
    LDA DIR
    BNE mov_l
    ; ---- derecha: X++ ----
    INC XLO
    BNE r_lim
    INC XHI            ; acarreo -> bit 8
r_lim:
    ; limite derecho: X >= 312 ?  (XHI=1 y XLO>=56)
    LDA XHI
    BEQ write          ; XHI=0 -> X<256 -> no llegamos
    LDA XLO
    CMP #56
    BCC write
    LDA #1
    STA DIR
    JMP write
mov_l:
    ; ---- izquierda: X-- ----
    LDA XLO
    BNE l_dec
    LDA XHI
    BEQ l_lim            ; XLO=0 y XHI=0 -> X=0, no bajar mas
    LDA #0
    STA XHI            ; pedir prestado
l_dec:
    DEC XLO
l_lim:
    ; limite izquierdo: X <= 4 ?  (XHI=0 y XLO<=4)
    LDA XHI
    BNE write          ; XHI=1 -> X>=256 -> no estamos a la izquierda
    LDA XLO
    CMP #5
    BCS write
    LDA #0
    STA DIR

write:
    ; --- escribir X (byte) + FLAGS (bit2 = XHI) ---
    LDA #$C0
    STA VID_HI
    LDA #0
    STA VID_LO
    LDA XLO
    STA VID_DT
    ; FLAGS: bit2 = XHI (bit 8 de X), paleta 0
    LDA #$C0
    STA VID_HI
    LDA #3
    STA VID_LO
    LDA XHI
    ASL A
    ASL A              ; XHI (0/1) -> bit 2
    STA VID_DT

wvbe:
    LDA VID_ST
    AND #$80
    BNE wvbe
    JMP main_loop

; patron del sprite (cuadrado)
square_p0:
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
square_p1:
    .byte $00, $00, $00, $00, $00, $00, $00, $00

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
