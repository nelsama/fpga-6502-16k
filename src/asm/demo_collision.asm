; ============================================
; demo_collision.asm -- PRUEBA DE COLISION SPRITE <-> TILE SOLIDO (Fase 10)
;
; Fondo: el que carga la init de VRAM (damero/marco/diagonal/solido).
; Marcamos la COLUMNA 20 (filas 2..23) como SOLIDA (bit 4 del atributo = 1).
;
; Un sprite (muneco) se mueve horizontalmente. Cuando su CENTRO cae sobre
; una celda solida, el flag SOLID_HIT (bit 5 de $D803) se pone a 1 y el
; muneco cambia de paleta (a rojo) para verlo visualmente.
;
; El barrido de colision corre una vez por frame (blanking vertical).
; SOLID_HIT se actualiza cada frame (no es sticky: refleja el ultimo frame).
;
; Zero page:
;   $10 XLO  $11 DIR
; ============================================

    .setcpu "6502"

VID_LO = $D800
VID_HI = $D801
VID_DT = $D802
VID_ST = $D803

XLO     = $10
DIR0    = $11
PALF    = $19
XLO2    = $1A
HITF    = $1C
DIR2    = $1D

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
    ; 0) Cargar el tile 64 = bloque solido azul oscuro (color 1, paleta 0).
    ;    direccion del patron = tile*8 + fila = 512 + Y
    ;      dir(7:0) = Y ; dir(10:8) = 010 (=2, por el bit 9)
    ;    VID_HI: area "10" ($80) | dir_hi ; +bit5 = pat_hi
    ;    plano0 = $FF (color 1), plano1 = $00
    ; ============================================
    LDY #0
ld_tile:
    ; plano 0
    LDA #$82            ; area 10, pat_hi=0, dir_hi=2
    STA VID_HI
    TYA
    STA VID_LO
    LDA #$FF
    STA VID_DT
    ; plano 1
    LDA #$A2            ; area 10, pat_hi=1, dir_hi=2
    STA VID_HI
    TYA
    STA VID_LO
    LDA #$00
    STA VID_DT
    INY
    CPY #8
    BNE ld_tile

    ; ============================================
    ; 1) Dos columnas SOLIDAS: 14 y 26 (filas 2..23), tile 64.
    ;    - tilemap  = tile 64 (bloque azul oscuro)
    ;    - atributo = bit 4 (SOLIDO)
    ; ============================================
    LDA #14
    STA $1C            ; columna 1
    JSR mark_column
    LDA #26
    STA $1C            ; columna 2
    JSR mark_column

    ; ============================================
    ; 2) Cargar patron del muneco (sprite 8x8, patron 0)
    ; ============================================
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

    ; ============================================
    ; 3) Sprite 0: cuadrado en (140, 120), entre las dos columnas
    ; ============================================
    LDA #140
    STA XLO
    LDA #0
    STA DIR0           ; 0 = derecha
    STA PALF           ; paleta del sprite = 0 (fija)

    ; X
    LDA #$C0
    STA VID_HI
    LDA #0
    STA VID_LO
    LDA XLO
    STA VID_DT
    ; Y
    LDA #$C0
    STA VID_HI
    LDA #1
    STA VID_LO
    LDA #120
    STA VID_DT
    ; TILE
    LDA #$C0
    STA VID_HI
    LDA #2
    STA VID_LO
    LDA #0
    STA VID_DT
    ; FLAGS
    LDA #$C0
    STA VID_HI
    LDA #3
    STA VID_LO
    LDA #$00
    STA VID_DT
    ; COLL_POINT: empezando hacia la derecha -> borde derecho (dx=7,dy=4) = $24
    ;   (dx en bits 2:0, dy en bits 5:3). dy=4 = %100 -> bits 5:3 = 100 = $20; dx=7 = $07
    LDA #$C0
    STA VID_HI
    LDA #4
    STA VID_LO
    LDA #$27            ; dy=4 (bits 5:3=100 -> $20) | dx=7 -> $27
    STA VID_DT

    ; ============================================
    ; 3b) Sprite 1: cuadrado a 2x (16x16), otro color (paleta 1),
    ;     en fila mas arriba (Y=60) para no chocar con el sprite 0.
    ;     OAM del sprite 1 = bytes 5..9.
    ; ============================================
    LDA #150
    STA XLO2            ; posicion inicial del 2x
    LDA #0
    STA DIR2

    ; X  (byte 5)
    LDA #$C0
    STA VID_HI
    LDA #5
    STA VID_LO
    LDA XLO2
    STA VID_DT
    ; Y  (byte 6)
    LDA #$C0
    STA VID_HI
    LDA #6
    STA VID_LO
    LDA #60
    STA VID_DT
    ; TILE (byte 7)
    LDA #$C0
    STA VID_HI
    LDA #7
    STA VID_LO
    LDA #0
    STA VID_DT
    ; FLAGS (byte 8): SCALE2X (bit4) + paleta 1 (bits 1:0 = 01) = $11
    LDA #$C0
    STA VID_HI
    LDA #8
    STA VID_LO
    LDA #$11
    STA VID_DT
    ; COLL_POINT (byte 9): borde derecho dx=7, dy=4 -> $27
    ;   (gracias a C+, dx=7 sirve igual para 1x y 2x)
    LDA #$C0
    STA VID_HI
    LDA #9
    STA VID_LO
    LDA #$27
    STA VID_DT

    ; ============================================
    ; 4) Bucle principal
    ; ============================================
main_loop:
    ; esperar VBLANK (bit 7 = 1)
wvb:
    LDA VID_ST
    AND #$80
    BEQ wvb

    ; =================== ESTAMOS EN VBLANK ===================
    ; El hardware levanta SOLID_HIT (bit5 de $D803) si ALGUN sprite toco un
    ; tile solido. El software DEDUCE cual/cuales chocaron comparando su borde
    ; (el que avanza) contra las columnas solidas (X=112 col.14, X=208 col.26).
    LDA VID_ST
    AND #$20            ; bit 5 = SOLID_HIT
    STA HITF            ; guardar el flag del frame

    ; ---- Sprite 0 (1x): borde = X+7 (der) o X (izq) ----
    LDA DIR0
    BNE chk0_l
    ; va a la derecha -> choca con la columna DERECHA si X+7 >= 206
    LDA XLO
    CLC
    ADC #7
    CMP #206
    BCC do0            ; no llego a la columna -> no rebota
    LDA DIR0
    EOR #$01
    STA DIR0
    JMP do0
chk0_l:
    ; va a la izquierda -> choca con la columna IZQ si X <= 118
    LDA XLO
    CMP #119
    BCS do0            ; X>=119 -> aun no llego -> no rebota
    LDA DIR0
    EOR #$01
    STA DIR0
do0:
    ; ---- Sprite 1 (2x): borde = X+15 (der) o X (izq) ----
    LDA DIR2
    BNE chk1_l
    LDA XLO2
    CLC
    ADC #15
    CMP #206
    BCC do1
    LDA DIR2
    EOR #$01
    STA DIR2
    JMP do1
chk1_l:
    LDA XLO2
    CMP #119
    BCS do1
    LDA DIR2
    EOR #$01
    STA DIR2
do1:

move:
    ; mover el sprite 0 segun DIR0
    LDA DIR0
    BNE mov0_l
    INC XLO
    JMP up_x
mov0_l:
    DEC XLO
up_x:
    ; escribir X del sprite 0
    LDA #$C0
    STA VID_HI
    LDA #0
    STA VID_LO
    LDA XLO
    STA VID_DT
    ; escribir FLAGS (paleta) del sprite 0
    LDA #$C0
    STA VID_HI
    LDA #3
    STA VID_LO
    LDA PALF
    STA VID_DT

    ; escribir COLL_POINT segun la direccion:
    ;   derecha (DIR0=0) -> borde derecho dx=7 -> $27 (dy=4)
    ;   izquierda (DIR0=1) -> borde izquierdo dx=0 -> $20 (dy=4)
    LDA DIR0
    BNE cp_left
    LDA #$27
    JMP cp_write
cp_left:
    LDA #$20
cp_write:
    STA $1B             ; valor de COLL_POINT
    LDA #$C0
    STA VID_HI
    LDA #4
    STA VID_LO
    LDA $1B
    STA VID_DT

    ; ============================================
    ; Sprite 1 (2x): mover segun DIR2 (el rebote lo decide la deduccion de
    ;   colision de arriba, comparando su borde con las columnas).
    ; ============================================
    LDA DIR2
    BNE mv2_l
    INC XLO2
    JMP wr2
mv2_l:
    DEC XLO2
wr2:
    ; escribir X del sprite 1 (byte 5)
    LDA #$C0
    STA VID_HI
    LDA #5
    STA VID_LO
    LDA XLO2
    STA VID_DT

    ; esperar salir del VBLANK (bit 7 = 0)
wvb2:
    LDA VID_ST
    AND #$80
    BNE wvb2
    JMP main_loop

; ============================================
; mark_column: marca como sólida (y pinta tile 3) las filas 2..23
;   de la columna en $1C.
; ============================================
mark_column:
    LDA #2
    STA $14            ; fila
mc_row:
    JSR cell_addr      ; CUR = fila*64 + $1C  ($17=lo, $18=hi)
    ; tilemap = tile 64
    LDA $17
    STA VID_LO
    LDA $18
    STA VID_HI
    LDA #64
    STA VID_DT
    ; atributo = bit 4 SOLIDO
    LDA $17
    STA VID_LO
    LDA $18
    ORA #$40
    STA VID_HI
    LDA #$10
    STA VID_DT
    INC $14
    LDA $14
    CMP #24
    BNE mc_row
    RTS

; ============================================
; cell_addr: CUR = fila($14)*64 + columna($1C)
;   CUR_LO = $17, CUR_HI = $18
; ============================================
cell_addr:
    LDA $14
    LSR A
    LSR A
    STA $18            ; CUR_HI = fila>>2
    LDA $14
    AND #$03
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    STA $17            ; (fila&3)<<6
    LDA $17
    CLC
    ADC $1C            ; + columna (0..63)
    STA $17
    BCC ca_done
    INC $18
ca_done:
    RTS

; patron del sprite: CUADRADO solido (todo color 1) para ver fallos
square_p0:
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
square_p1:
    .byte $00, $00, $00, $00, $00, $00, $00, $00

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
