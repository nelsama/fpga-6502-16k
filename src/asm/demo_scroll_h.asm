; ============================================
; video_test.asm -- DEMO DE SCROLL v2
;
; Mapa 40x30, scroll horizontal.
;   - Cielo: BG_COLOR (azul), sin tiles (espacio transparente)
;   - Nubes blancas en el cielo
;   - Cesped (fila 22) y tierra texturizada (filas 23..29)
;   - Arboles (copa verde + tronco marron)
;
; Zero page (SIN solapamiento):
;   $10 CUR_LO   $11 CUR_HI
;   $12 TILE     $13 PAL
;   $14 ROW      $15 COL
;   $16 I        $17 J
;   $18 SCX_LO   $19 SCX_HI  $1A SLOW
; ============================================

    .setcpu "6502"

VID_LO = $D800
VID_HI = $D801
VID_DT = $D802
VID_ST = $D803

CUR_LO = $10
CUR_HI = $11
TILE    = $12
PAL     = $13
ROW     = $14
COL     = $15
I       = $16
J       = $17
SCX_LO  = $18
SCX_HI  = $19
SLOW    = $1A

    .segment "CODE"
    .org $8000

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    LDX #$00
    LDY #$00
d1:
    DEX
    BNE d1
    DEY
    BNE d1
    LDY #$00
d2:
    DEX
    BNE d2
    DEY
    BNE d2

    LDA #0
    STA SCX_LO
    STA SCX_HI
    STA $D804
    STA $D805

    ; ============================================
    ; 1) TERRENO: filas 22..29
    ;    fila 22 = cesped, filas 23-29 = tierra texturizada
    ; ============================================
    LDA #22
    STA ROW
ground_loop:
    LDA #0
    STA COL
ground_col:
    JSR calc_cell
    LDA ROW
    CMP #22
    BNE is_dirt
    ; cesped
    LDA #$01
    STA TILE
    LDA #$02
    STA PAL
    JMP do_put
is_dirt:
    ; tierra con variacion por columna
    LDA COL
    AND #$0F
    STA TILE            ; base
    LDA COL
    AND #$07
    CMP #3
    BNE d1b
    LDA #$05            ; piedra
    STA TILE
    JMP d_pal
d1b:
    LDA #$00            ; tierra
    STA TILE
d_pal:
    LDA #$01
    STA PAL
do_put:
    JSR put_cell
    INC COL
    LDA COL
    CMP #40
    BNE ground_col
    INC ROW
    LDA ROW
    CMP #30
    BNE ground_loop

    ; ============================================
    ; 2) ARBOLES: columnas 5, 15, 25, 35
    ;    copa filas 15-16, tronco fila 17
    ; ============================================
    LDA #0
    STA I
tree_loop:
    LDX I
    LDA tree_cols,X
    STA COL

    ; copa fila 19
    LDA #19
    STA ROW
    JSR calc_cell
    LDA #$02
    STA TILE
    LDA #$02
    STA PAL
    JSR put_cell

    ; copa fila 20
    LDA #20
    STA ROW
    JSR calc_cell
    LDA #$02
    STA TILE
    LDA #$02
    STA PAL
    JSR put_cell

    ; tronco fila 21 (sobre el pasto fila 22)
    LDA #21
    STA ROW
    JSR calc_cell
    LDA #$03
    STA TILE
    LDA #$01
    STA PAL
    JSR put_cell

    INC I
    LDA I
    CMP #4
    BNE tree_loop

    ; ============================================
    ; 3) NUBES: bloque 2x1 blanco en filas 3 y 7, cols 2 y 12
    ; ============================================
    LDA #0
    STA I
cloud_loop:
    LDX I
    LDA cloud_cols,X
    STA COL
    LDA I
    AND #$01
    ASL A
    ASL A
    CLC
    ADC #3                ; fila 3 si I par, fila 7 si I impar
    STA ROW
    JSR calc_cell
    LDA #$04
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    ; celda vecina (COL+1) tambien nube
    INC COL
    JSR calc_cell
    LDA #$04
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC I
    LDA I
    CMP #4
    BNE cloud_loop

    ; ============================================
    ; 4) SCROLL
    ; ============================================
    LDA #0
    STA SLOW
scroll_loop:
wvb:
    LDA VID_ST
    AND #$80
    BEQ wvb
wvb2:
    LDA VID_ST
    AND #$80
    BNE wvb2
    ; scroll a 1 px por frame (velocidad maxima con VBLANK)
    INC SCX_LO
    BNE sn
    INC SCX_HI
sn:
    LDA SCX_LO
    STA $D804
    LDA SCX_HI
    STA $D805
    JMP scroll_loop

done:
    JMP done

; ============================================
; put_cell: escribe TILE con PAL en CUR (tilemap + attr)
; ============================================
put_cell:
    LDA CUR_LO
    STA VID_LO
    LDA CUR_HI
    STA VID_HI
    LDA TILE
    STA VID_DT
    LDA CUR_LO
    STA VID_LO
    LDA CUR_HI
    ORA #$40
    STA VID_HI
    LDA PAL
    STA VID_DT
    RTS

; ============================================
; calc_cell: CUR = ROW*40 + COL   (16 bits)
; ============================================
calc_cell:
    ; CUR = ROW*32 + ROW*8 + COL
    LDA ROW
    STA J                ; J = ROW (preservado en zero page aparte)
    ; low = ROW*32
    LDA J
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    STA CUR_LO
    LDA J
    LSR A
    LSR A
    LSR A
    STA CUR_HI
    ; + ROW*8
    LDA J
    ASL A
    ASL A
    ASL A
    CLC
    ADC CUR_LO
    STA CUR_LO
    BCC cc_n
    INC CUR_HI
cc_n:
    ; + COL
    LDA CUR_LO
    CLC
    ADC COL
    STA CUR_LO
    BCC cc_n2
    INC CUR_HI
cc_n2:
    RTS

tree_cols:
    .byte 5, 15, 25, 35
cloud_cols:
    .byte 2, 12, 22, 32

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
