; ============================================
; demo_scale2x.asm -- PRUEBA DE ESCALADO 2x DE SPRITES (Fase 9)
;
; Dos munecos 16x16 (4 sprites de 8x8 cada uno):
;   - Muneco 1x  a la izquierda (16x16)
;   - Muneco 2x  a la derecha, moviendose (32x32)
;
; El muneco 2x coloca sus 4 cuadrantes con paso +16 (no +8) porque cada
; cuadrante escalado mide 16 px. Anclaje: esquina superior izquierda.
;
; FLAGS de OAM: bit7 FLIP_Y, bit6 FLIP_X, bit5 PRIO, bit4 SCALE2X, bits3:0 PAL
;
; Cuadrantes (patrones): A=0, B=1, C=2, D=3
;   rejilla: sup-izq=A sup-der=B    inf-izq=C inf-der=D
;
; Zero page:
;   $10 XLO  $11 XHI  $12 DIR  $20 BIDX  $21 YPOS  $22 TILE  $23 FLAGS
; ============================================

    .setcpu "6502"

VID_LO = $D800
VID_HI = $D801
VID_DT = $D802
VID_ST = $D803

XLO   = $10
XHI   = $11
DIR   = $12
BIDX  = $20
YPOS  = $21
TILE2 = $22
FLAGS = $23
Xpos  = $14

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

    ; ============================================
    ; 1) Cargar los 4 cuadrantes en spr_arr (patrones 0..3)
    ; ============================================
    JSR load_all

    ; ============================================
    ; 2) Muneco 1x (16x16) en (30, 80): sprites OAM 0..3
    ;    A(0) en (30,80)  B(1) en (38,80)
    ;    C(2) en (30,88)  D(3) en (38,88)
    ; ============================================
    LDA #30
    STA Xpos
    LDA #80
    STA YPOS
    LDA #0
    STA TILE2
    LDA #0
    STA BIDX
    LDA #0
    STA FLAGS
    JSR oam_write

    LDA #38
    STA Xpos
    LDA #1
    STA TILE2
    LDA #5
    STA BIDX
    JSR oam_write

    LDA #30
    STA Xpos
    LDA #88
    STA YPOS
    LDA #2
    STA TILE2
    LDA #10
    STA BIDX
    JSR oam_write

    LDA #38
    STA Xpos
    LDA #3
    STA TILE2
    LDA #15
    STA BIDX
    JSR oam_write

    ; ============================================
    ; 3) Muneco 2x (32x32): sprites OAM 4..7, moviendose
    ;    paso +16 entre cuadrantes
    ; ============================================
    LDA #150
    STA XLO
    LDA #0
    STA DIR

init2x:
    ; posicion base del muneco 2x: X = XLO
    ; A(0) (X,Y)  B(1) (X+16,Y)  C(2) (X,Y+16)  D(3) (X+16,Y+16)
    ; X base
    LDA XLO
    STA Xpos
    LDA #60
    STA YPOS
    LDA #0
    STA TILE2
    LDA #20
    STA BIDX
    LDA #$10
    STA FLAGS
    JSR oam_write

    LDA XLO
    CLC
    ADC #16
    STA Xpos
    LDA #1
    STA TILE2
    LDA #25
    STA BIDX
    JSR oam_write

    LDA XLO
    STA Xpos
    LDA #76
    STA YPOS
    LDA #2
    STA TILE2
    LDA #30
    STA BIDX
    JSR oam_write

    LDA XLO
    CLC
    ADC #16
    STA Xpos
    LDA #3
    STA TILE2
    LDA #35
    STA BIDX
    JSR oam_write

    ; ============================================
    ; 4) Animar: mover el muneco 2x horizontalmente
    ; ============================================
move_loop:
wvb:
    LDA VID_ST
    AND #$80
    BEQ wvb
wvb2:
    LDA VID_ST
    AND #$80
    BNE wvb2

    LDA DIR
    BNE go_left
    INC XLO
    LDA XLO
    CMP #220
    BCC redraw
    LDA #1
    STA DIR
    JMP redraw
go_left:
    DEC XLO
    LDA XLO
    CMP #10
    BCS redraw
    LDA #0
    STA DIR
redraw:
    JMP init2x

    .include "demo_scale2x_data.inc"

; ============================================
; oam_write: escribe 4 bytes (X,Y,TILE,FLAGS) en el sprite BIDX
;   usa Xpos, YPOS, TILE2, FLAGS
; ============================================
oam_write:
    LDA #$C0
    STA VID_HI
    LDA BIDX
    STA VID_LO
    LDA Xpos
    STA VID_DT

    LDA #$C0
    STA VID_HI
    LDA BIDX
    CLC
    ADC #1
    STA VID_LO
    LDA YPOS
    STA VID_DT

    LDA #$C0
    STA VID_HI
    LDA BIDX
    CLC
    ADC #2
    STA VID_LO
    LDA TILE2
    STA VID_DT

    LDA #$C0
    STA VID_HI
    LDA BIDX
    CLC
    ADC #3
    STA VID_LO
    LDA FLAGS
    STA VID_DT
    RTS

; ============================================
; load_all: carga los 4 cuadrantes (patrones 0..3) en spr_arr
; ============================================
load_all:
    ; A: patron 0 (dir 0)
    LDY #0
la:
    LDA #$C8
    STA VID_HI
    TYA
    STA VID_LO
    LDA dollA_p0,Y
    STA VID_DT
    LDA #$E8
    STA VID_HI
    TYA
    STA VID_LO
    LDA dollA_p1,Y
    STA VID_DT
    INY
    CPY #8
    BNE la
    ; B: patron 1 (dir 8)
    LDY #0
lb:
    LDA #$C8
    STA VID_HI
    TYA
    CLC
    ADC #8
    STA VID_LO
    LDA dollB_p0,Y
    STA VID_DT
    LDA #$E8
    STA VID_HI
    TYA
    CLC
    ADC #8
    STA VID_LO
    LDA dollB_p1,Y
    STA VID_DT
    INY
    CPY #8
    BNE lb
    ; C: patron 2 (dir 16)
    LDY #0
lc:
    LDA #$C8
    STA VID_HI
    TYA
    CLC
    ADC #16
    STA VID_LO
    LDA dollC_p0,Y
    STA VID_DT
    LDA #$E8
    STA VID_HI
    TYA
    CLC
    ADC #16
    STA VID_LO
    LDA dollC_p1,Y
    STA VID_DT
    INY
    CPY #8
    BNE lc
    ; D: patron 3 (dir 24)
    LDY #0
ld:
    LDA #$C8
    STA VID_HI
    TYA
    CLC
    ADC #24
    STA VID_LO
    LDA dollD_p0,Y
    STA VID_DT
    LDA #$E8
    STA VID_HI
    TYA
    CLC
    ADC #24
    STA VID_LO
    LDA dollD_p1,Y
    STA VID_DT
    INY
    CPY #8
    BNE ld
    RTS

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
