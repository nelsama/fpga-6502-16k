; ============================================
; demo_raster.asm -- DEMO DE SPLIT DE RASTER (Fase 8)
;
; TRES bandas:
;   - BANDA SUPERIOR (lineas 0..15):   HUD FIJO arriba (band2, scroll 0)
;   - BANDA MEDIA    (lineas 16..215): paisaje con scroll horizontal
;   - BANDA INFERIOR (lineas 216..239): HUD FIJO abajo (band3, scroll 0)
;
; Registros:
;   $D804/$D805  scroll_x (banda media)     -- se anima
;   $D806/$D807  scroll_y (banda media)     -- 0
;   $D809        raster_line0 = 16          -- fin banda top
;   $D80A/$D80B  band2_x = 0                -- HUD top fijo
;   $D80C/$D80D  band2_y = 0
;   $D80E        raster_line1 = 216         -- fin banda media
;   $D80F/$D810  band3_x = 0                -- HUD bottom fijo
;   $D811/$D812  band3_y = 0
;
; Fila de tilemap = linea_logica / 8:
;   banda top   -> filas 0..1   (lineas 0..15)
;   banda media -> filas 2..26  (lineas 16..215)
;   banda bottom-> filas 27..29 (lineas 216..239)
;
; Zero page:
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

    ; Esperar VIDEO_READY (bit 4 de $D803): la init de VRAM termino.
    ;   Sustituye a los retardos a ciegas (d1/d2). Ahora la lectura de $D803
    ;   esta decodificada por el data_bus_mux (Fase 8.1), asi que es fiable.
wait_ready:
    LDA VID_ST
    AND #$10            ; bit 4 = VIDEO_READY
    BEQ wait_ready

    ; scroll de la banda media = 0
    LDA #0
    STA SCX_LO
    STA SCX_HI
    STA $D804
    STA $D805
    STA $D806
    STA $D807

    ; split: banda top hasta fila 2 (linea 24), banda bottom en linea 216
    LDA #24
    STA $D809
    LDA #216
    STA $D80E
    ; HUD top fijo (band2 = 0)
    LDA #0
    STA $D80A
    STA $D80B
    STA $D80C
    STA $D80D
    ; HUD bottom fijo (band3 = 0)
    STA $D80F
    STA $D810
    STA $D811
    STA $D812

    ; ============================================
    ; 1) TERRENO: filas 22..31 (mapa completo 64 ancho)
    ;    fila 22 = cesped, filas 23..31 = tierra texturizada
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
    LDA #$01
    STA TILE
    LDA #$02
    STA PAL
    JMP do_put
is_dirt:
    LDA COL
    AND #$0F
    STA TILE
    LDA COL
    AND #$07
    CMP #3
    BNE d1b
    LDA #$05
    STA TILE
    JMP d_pal
d1b:
    LDA #$00
    STA TILE
d_pal:
    LDA #$01
    STA PAL
do_put:
    JSR put_cell
    INC COL
    LDA COL
    CMP #64
    BNE ground_col
    INC ROW
    LDA ROW
    CMP #32
    BNE ground_loop

    ; ============================================
    ; 2) CIELO: filas 3..21 en TODO el ancho (64)
    ;    (deja el fondo azul limpio; antes quedaba a 0 y el
    ;     scroll horizontal revelaba celdas sin escribir)
    ; ============================================
    LDA #3
    STA ROW
sky_loop:
    LDA #0
    STA COL
sky_col:
    JSR calc_cell
    LDA #$20            ; espacio = celda transparente (BG azul)
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC COL
    LDA COL
    CMP #64
    BNE sky_col
    INC ROW
    LDA ROW
    CMP #22
    BNE sky_loop

    ; ============================================
    ; 2b) ARBOLES: columnas repartidas por las 64 del mapa
    ; ============================================
    LDA #0
    STA I
tree_loop:
    LDX I
    LDA tree_cols,X
    STA COL

    LDA #19
    STA ROW
    JSR calc_cell
    LDA #$02
    STA TILE
    LDA #$02
    STA PAL
    JSR put_cell

    LDA #20
    STA ROW
    JSR calc_cell
    LDA #$02
    STA TILE
    LDA #$02
    STA PAL
    JSR put_cell

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
    CMP #8
    BNE tree_loop

    ; ============================================
    ; 3) NUBES
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
    ADC #3
    STA ROW
    JSR calc_cell
    LDA #$04
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC COL
    JSR calc_cell
    LDA #$04
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC I
    LDA I
    CMP #8
    BNE cloud_loop

    ; ============================================
    ; 3b) FILA 0 (margen del HUD superior): cielo limpio en todo el ancho
    ; ============================================
    LDA #0
    STA ROW
    LDA #0
    STA COL
fila0_loop:
    JSR calc_cell
    LDA #$20            ; espacio = transparente (BG azul)
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC COL
    LDA COL
    CMP #64
    BNE fila0_loop

    ; ============================================
    ; 4) HUD SUPERIOR FIJO: filas 1..2 (fila 0 reservada como margen)
    ;    barra marron + texto "LIVES 03"
    ; ============================================
    LDA #1
    STA ROW
hud_top_row:
    LDA #0
    STA COL
hud_top_col:
    JSR calc_cell
    LDA #$00            ; tierra (marrón)
    STA TILE
    LDA #$01
    STA PAL
    JSR put_cell
    INC COL
    LDA COL
    CMP #40
    BNE hud_top_col
    INC ROW
    LDA ROW
    CMP #3
    BNE hud_top_row

    ; texto "LIVES 03" fila 1, col 2
    LDA #1
    STA ROW
    LDA #2
    STA COL
    LDX #0
hud_top_txt:
    LDA hud_top_msg,X
    BEQ hud_top_done
    PHA
    JSR calc_cell
    PLA
    STA TILE
    LDA #$00            ; paleta 0 (texto con tinta blanca)
    STA PAL
    JSR put_cell
    INC COL
    INX
    JMP hud_top_txt
hud_top_done:

    ; ============================================
    ; 5) HUD INFERIOR FIJO: filas 27..29
    ;    barra marron + texto "SCORE 000000"
    ; ============================================
    LDA #27
    STA ROW
hud_bot_row:
    LDA #0
    STA COL
hud_bot_col:
    JSR calc_cell
    LDA #$00
    STA TILE
    LDA #$01
    STA PAL
    JSR put_cell
    INC COL
    LDA COL
    CMP #40
    BNE hud_bot_col
    INC ROW
    LDA ROW
    CMP #30
    BNE hud_bot_row

    ; texto "SCORE 000000" fila 28, col 2
    LDA #28
    STA ROW
    LDA #2
    STA COL
    LDX #0
hud_bot_txt:
    LDA hud_bot_msg,X
    BEQ hud_bot_done
    PHA
    JSR calc_cell
    PLA
    STA TILE
    LDA #$00
    STA PAL
    JSR put_cell
    INC COL
    INX
    JMP hud_bot_txt
hud_bot_done:

    ; ============================================
    ; 6) SCROLL (solo afecta a la banda media)
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
; put_cell
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
; calc_cell: CUR = ROW*64 + COL   (mapa 64x32, stride potencia de 2)
;   ROW*64 es un simple shift izquierdo de 6 bits.
; ============================================
calc_cell:
    LDA ROW
    STA J
    ; CUR_LO = (ROW<<6) & $FF  =  ROW & $03 << 6  (bits 0-1 de ROW -> bits 6-7)
    LDA J
    AND #$03
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    STA CUR_LO
    ; CUR_HI = ROW >> 2  (bits 2-7 de ROW -> bits 0-5 del byte alto)
    LDA J
    LSR A
    LSR A
    STA CUR_HI
    ; + COL (las 40 columnas visibles; el resto del ancho 64 queda fuera de pantalla)
    LDA CUR_LO
    CLC
    ADC COL
    STA CUR_LO
    BCC cc_n2
    INC CUR_HI
cc_n2:
    RTS

tree_cols:
    .byte 5, 15, 25, 35, 45, 55, 60, 10
cloud_cols:
    .byte 2, 12, 22, 32, 42, 52, 58, 6

; "LIVES 03": L=$4C I=$49 V=$56 E=$45 S=$53 esp=$20 0=$30 3=$33
hud_top_msg:
    .byte $4C,$49,$56,$45,$53,$20,$30,$33,$00

; "SCORE 000000": S=$53 C=$43 O=$4F R=$52 E=$45 esp=$20 0=$30
hud_bot_msg:
    .byte $53,$43,$4F,$52,$45,$20,$30,$30,$30,$30,$30,$30,$00

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
