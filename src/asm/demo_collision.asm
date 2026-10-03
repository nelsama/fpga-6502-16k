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
DIR     = $11
PALF    = $19

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
    ; 1) Columna 20 (filas 2..23): pintarla y marcarla SOLIDA.
    ;    - tilemap  = tile 3 (solido de la init) para VERLA
    ;    - atributo = bit 4 (SOLIDO)
    ;    Celda = fila*64 + 20.
    ; ============================================
    LDA #2
    STA $14            ; fila inicial
mark_rows:
    JSR cell_addr      ; CUR = fila*64 + 20  ($17=lo, $18=hi)
    ; --- tilemap (area 00) = tile 3 ---
    LDA $17
    STA VID_LO
    LDA $18
    STA VID_HI         ; area 00
    LDA #$03
    STA VID_DT
    ; --- atributo (area 01) = bit 4 SOLIDO ---
    LDA $17
    STA VID_LO
    LDA $18
    ORA #$40           ; area 01 = atributos
    STA VID_HI
    LDA #$10           ; bit 4 = SOLIDO (paleta 0)
    STA VID_DT
    INC $14
    LDA $14
    CMP #24
    BNE mark_rows

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
    ; 3) Sprite 0: muneco en (40, 120), paleta 0
    ; ============================================
    LDA #40
    STA XLO
    LDA #0
    STA DIR

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
    ; mover el sprite
    LDA DIR
    BNE mov_l
    INC XLO
    LDA XLO
    CMP #200
    BCC up_x
    LDA #1
    STA DIR
    JMP up_x
mov_l:
    DEC XLO
    LDA XLO
    CMP #20
    BCS up_x
    LDA #0
    STA DIR
up_x:

    ; === COLISION REAL: leer el flag SOLID_HIT (bit 5 de $D803) ===
    ; Si el centro del sprite toco un tile solido en el ultimo barrido, paleta 1.
    LDA VID_ST
    AND #$20            ; bit 5 = SOLID_HIT
    BEQ pal0
    LDA #$01
    STA PALF
    JMP write_spr
pal0:
    LDA #$00
    STA PALF

write_spr:
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

    ; esperar salir del VBLANK (bit 7 = 0)
wvb2:
    LDA VID_ST
    AND #$80
    BNE wvb2
    JMP main_loop

; ============================================
; cell_addr: CUR = fila($14)*64 + columna 20
;   CUR_LO = $17, CUR_HI = $18
;   columna 20 = $14; los 6 bits bajos guardan la col (0..63)
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
    ORA #$14           ; columna 20
    STA $17            ; CUR_LO = (fila&3)<<6 + 20
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
