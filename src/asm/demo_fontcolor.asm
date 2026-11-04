; ============================================
; demo_fontcolor.asm -- DEMOSTRACION DE COLORES DE TEXTO
;
; ORDEN DE EJECUCION:
;   1. SETUP       -> limpia la VRAM (no depende del soft anterior)
;   2. Paletas     -> color 3 de cada paleta de fondo: rojo/verde/amarillo
;   3. Texto       -> lineas con 3 paletas distintas: 3 colores SIMULTANEOS
;   4. Pausa
;   5. font_color  -> cambia el color global ($D818), redibuja (color 2)
;   6. font_color  -> cambia otra vez (color 1), redibuja
;   7. font_color  -> vuelve a 3 y sale al monitor
;
; COLOR: formato RGB444 (12 bits) = RRRR GGGG BBBB
;   El puerto lleva lo=$D814 (bits 7:0 = GGGG BBBB) y
;   hi=$D815 (bits 3:0 = RRRR). Ver manual §4.4.
;
;   entrada = paleta*4 + color
;   pal 0: 1=naranja 2=verde 3=rojo
;   pal 1: 5=cian 6=magenta 7=verde
;   pal 2: 9=amarillo 10=blanco 11=amarillo
;   pal 3: sin tocar (entrada 15 = BG_COLOR)
;
; Zero page:
;   FILA=$11  COL=$12  SM=$13  TMP=$14  CUR_LO=$17  CUR_HI=$18
; ============================================

    .setcpu "6502"

VID_LO   = $D800
VID_HI   = $D801
VID_DT   = $D802
VID_ST   = $D803
PAL_PTR  = $D813
PAL_LO   = $D814
PAL_HI   = $D815
SETUP    = $D816
SETUP_ST = $D817
FONT_COL = $D818

FILA   = $11
COL    = $12
SM     = $13
TMP    = $14

    .segment "CODE"
    .org $0800

entry:
    SEI
    CLD
    ; NO se toca la pila: el monitor vuelve con RTS.

    JSR wait_ready
    JSR do_setup            ; 1) limpiar la VRAM
    JSR set_palettes        ; 2) rojo / verde / amarillo

    ; ---- 3) texto con color de trazo 3 y 3 paletas ----
    LDA #3
    STA FONT_COL
    JSR do_setup
    JSR draw_screen
    JSR pause4

    ; ---- 4) color de trazo 2 (global) ----
    LDA #2
    STA FONT_COL
    JSR do_setup
    JSR draw_screen
    JSR pause4

    ; ---- 5) color de trazo 1 (global) ----
    LDA #1
    STA FONT_COL
    JSR do_setup
    JSR draw_screen
    JSR pause4

    ; ---- 6) dejar el color normal y salir ----
    LDA #3
    STA FONT_COL
    JSR do_setup
    JSR draw_screen

    RTS

; ============================================
; wait_ready: VIDEO_READY (bit4 de $D817)
; ============================================
wait_ready:
    LDA SETUP_ST
    AND #$10
    BEQ wait_ready
    RTS

; ============================================
; do_setup: SETUP + esperar
; ============================================
do_setup:
    LDA #0
    STA SETUP
    JMP wait_ready

; ============================================
; set_palettes: colores LEGIBLES en las entradas 1, 2 y 3 de las paletas 0,1,2
;
;   Las paletas de fabrica usan colores 1 y 2 pensados para GRAFICOS, y muchos
;   son oscuros o se confunden con el fondo azul ($48C). Aqui se ponen colores
;   claros para que cada paso de la demo se distinga bien.
;
;   entrada = paleta*4 + color
;     pal 0: 1=naranja 2=verde    3=rojo
;     pal 1: 5=cian    6=magenta  7=verde
;     pal 2: 9=amarillo 10=blanco 11=amarillo
;     pal 3: NO se toca (entrada 15 = BG_COLOR)
; ============================================
set_palettes:
    ; --- pal 0, col 1 = NARANJA $F80 ---
    LDA #1
    STA PAL_PTR
    LDA #$80
    STA PAL_LO
    LDA #$0F
    STA PAL_HI

    ; --- pal 0, col 2 = VERDE $0F0 ---
    LDA #2
    STA PAL_PTR
    LDA #$F0
    STA PAL_LO
    LDA #$00
    STA PAL_HI

    ; --- pal 0, col 3 = ROJO $F00 ---
    LDA #3
    STA PAL_PTR
    LDA #$00
    STA PAL_LO
    LDA #$0F
    STA PAL_HI

    ; --- pal 1, col 1 = CIAN $0FF ---
    LDA #5
    STA PAL_PTR
    LDA #$FF
    STA PAL_LO
    LDA #$00
    STA PAL_HI

    ; --- pal 1, col 2 = MAGENTA $F0F ---
    LDA #6
    STA PAL_PTR
    LDA #$F0
    STA PAL_LO
    LDA #$0F
    STA PAL_HI

    ; --- pal 1, col 3 = VERDE $0F0 (ya lo era, se reescribe por claridad) ---
    LDA #7
    STA PAL_PTR
    LDA #$F0
    STA PAL_LO
    LDA #$00
    STA PAL_HI

    ; --- pal 2, col 1 = AMARILLO $FF0 ---
    LDA #9
    STA PAL_PTR
    LDA #$F0
    STA PAL_LO
    LDA #$0F
    STA PAL_HI

    ; --- pal 2, col 2 = BLANCO $FFF ---
    LDA #10
    STA PAL_PTR
    LDA #$FF
    STA PAL_LO
    LDA #$0F
    STA PAL_HI

    ; --- pal 2, col 3 = AMARILLO $FF0 ---
    LDA #11
    STA PAL_PTR
    LDA #$F0
    STA PAL_LO
    LDA #$0F
    STA PAL_HI
    RTS

; ============================================
; draw_screen: 3 lineas de texto, una por paleta (0,1,2)
; ============================================
draw_screen:
    LDA #0
    STA SM
    LDA #6
    STA FILA
ds_loop:
    JSR draw_line
    LDA FILA
    CLC
    ADC #8
    STA FILA
    INC SM
    LDA SM
    CMP #3
    BNE ds_loop
    RTS

; ============================================
; draw_line: texto "COLOR DE TEXTO" con paleta SM
; ============================================
draw_line:
    LDA #4
    STA COL
    LDY #0
dl_loop:
    LDA dl_msg,Y
    BEQ dl_end              ; fin de cadena ($00)
    JSR put_char
    LDA COL
    CLC
    ADC #2
    STA COL
    INY
    JMP dl_loop
dl_end:
    RTS

dl_msg:
    .byte $43, $4F, $4C, $4F, $52      ; "COLOR"
    .byte $20                          ; " "
    .byte $44, $45                       ; "DE"
    .byte $20                          ; " "
    .byte $54, $45, $58, $54, $4F      ; "TEXTO"
    .byte $00

; ============================================
; put_char: tile A en (FILA, COL), atributo = paleta SM
; ============================================
put_char:
    PHA
    JSR cell_addr

    LDA $17
    STA VID_LO
    LDA $18
    STA VID_HI
    PLA
    STA VID_DT
    PHA

    LDA $17
    STA VID_LO
    LDA $18
    ORA #$40
    STA VID_HI
    LDA SM
    STA VID_DT

    PLA
    RTS

; ============================================
; cell_addr: CUR = FILA*64 + COL  -> $17/$18
; ============================================
cell_addr:
    LDA FILA
    STA $17
    LDA #0
    STA $18
    ASL $17
    ROL $18
    ASL $17
    ROL $18
    ASL $17
    ROL $18
    ASL $17
    ROL $18
    ASL $17
    ROL $18
    ASL $17
    ROL $18
    LDA $17
    CLC
    ADC COL
    STA $17
    LDA $18
    ADC #0
    STA $18
    RTS

; ============================================
; pause4: 4 pausas de ~30 frames
; ============================================
pause4:
    JSR pause
    JSR pause
    JSR pause
    JMP pause

; ============================================
; pause: ~30 frames
; ============================================
pause:
    LDA #0
    STA TMP
pv:
    JSR wframe
    INC TMP
    LDA TMP
    CMP #30
    BNE pv
    RTS

; wframe: espera el flanco de entrada en VBLANK
wframe:
    LDA VID_ST
    AND #$80
    BEQ wframe
wf2:
    LDA VID_ST
    AND #$80
    BNE wf2
    RTS
