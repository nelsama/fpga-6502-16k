; ============================================
; demo_spr12.asm -- PRUEBA DE 12 SPRITES EN LA MISMA LINEA
;
; FILA DE ARRIBA (fija, sprites 0..12, a 2x = 16x16):
;   13 sprites en la misma linea, marcados 1 2 3 4 5 6 7 8 9 A B C D.
;     bitstream de 12 por linea -> se ven del 1 a la C; la D NO aparece
;     bitstream de 8 por linea  -> se ven solo del 1 al 8
;
; FILA DE ABAJO (movil, sprites 13..24, 8x8):
;   12 sprites (1..9 A B C) que van y vienen por toda la pantalla
;   (cruzan X=255). Deben verse los 12, sin parpadeos ni cortes.
;
; Se distinguen por la marca y por el color (4 paletas alternadas).
;
; Salir: cualquier tecla por UART o cualquiera de los pulsadores.
;        Apaga los sprites, restaura las paletas y vuelve con RTS.
;
; Carga y ejecucion: $0800
;
; Zero page:
;   $10 N     $11 FILA   $12 COL   $13 POS   $14 DIR
;   $15 XLO   $16 XHI    $17/$18 CUR   $19 OAM   $1A MARCA
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
UART_RX  = $C020
UART_ST  = $C021
BTN      = $C005

N      = $10
FILA   = $11
COL    = $12
POS    = $13
DIR    = $14
XLO    = $15
XHI    = $16
CUR    = $17            ; y $18
OAM    = $19
MARCA  = $1A

N_ARR  = 13             ; sprites de la fila de arriba
N_ABA  = 12             ; sprites de la fila de abajo
Y_ARR  = 80
Y_ABA  = 160
PASO   = 12             ; separacion en la fila de abajo
POSMAX = 178            ; 178 + 11*12 = 310 (310 + 8 < 320)

    .segment "CODE"
    .org $0800

entry:
    SEI
    CLD
    ; NO se toca la pila: se vuelve con RTS.
    JSR wait_ready
    LDA #0
    STA SETUP               ; limpiar VRAM y recargar la fuente
    JSR wait_ready

    JSR hide_all
    JSR load_patterns
    LDX #0
    JSR load_palette        ; paletas de la demo
    JSR draw_text

    ; ---- fila de arriba: sprite i en X = 8 + i*24, a 2x ----
    LDA #0
    STA N
    STA XHI
    STA OAM
    LDA #8
    STA XLO
top_loop:
    LDA #Y_ARR
    LDY #1
    JSR oam_put             ; Y
    LDA N
    LDY #2
    JSR oam_put             ; TILE = numero de sprite
    LDA #0
    LDY #4
    JSR oam_put             ; COLL_POINT
    LDA #$10                ; SCALE2X
    JSR put_x               ; X + FLAGS
    LDA XLO
    CLC
    ADC #24
    STA XLO
    BCC t1
    INC XHI
t1:
    JSR next_oam
    INC N
    LDA N
    CMP #N_ARR
    BNE top_loop

    ; ---- fila de abajo: campos que no cambian ----
    LDA #8
    STA POS
    LDA #0
    STA DIR
    JSR move_row            ; X y FLAGS antes de activar la Y
    LDA #N_ARR*5
    STA OAM
    LDA #0
    STA N
bot_loop:
    LDA N
    LDY #2
    JSR oam_put
    LDA #0
    LDY #4
    JSR oam_put
    LDA #Y_ABA
    LDY #1
    JSR oam_put
    JSR next_oam
    INC N
    LDA N
    CMP #N_ABA
    BNE bot_loop

    LDA UART_RX             ; descartar lo que quede del comando

; ============================================
; bucle principal: 1 vuelta por frame
; ============================================
main:
    JSR wframe
    JSR move_row

    LDA DIR
    BNE izq
    INC POS
    LDA POS
    CMP #POSMAX
    BNE keys
    LDA #1
    STA DIR
    BNE keys
izq:
    DEC POS
    LDA POS
    CMP #2
    BNE keys
    LDA #0
    STA DIR
keys:
    LDA UART_ST
    AND #$02                ; RX con dato
    BEQ no_tecla
    LDA UART_RX
    CMP #$0D                ; ignorar fin de linea del comando
    BEQ no_tecla
    CMP #$0A
    BNE salir
no_tecla:
    LDA BTN
    AND #$03
    CMP #$03                ; 1 = suelto
    BEQ main
salir:
    JSR hide_all
    LDX #32                 ; paletas de fabrica
    JSR load_palette
    LDA #0
    STA SETUP
    JMP wait_ready          ; (RTS)

; ============================================
; move_row: X y FLAGS de los 12 sprites moviles
; ============================================
move_row:
    LDA #N_ARR*5
    STA OAM
    LDA POS
    STA XLO
    LDA #0
    STA XHI
    STA N
mr1:
    LDA #0                  ; sin escala
    JSR put_x
    LDA XLO
    CLC
    ADC #PASO
    STA XLO
    BCC mr2
    INC XHI
mr2:
    JSR next_oam
    INC N
    LDA N
    CMP #N_ABA
    BNE mr1
    RTS

; ============================================
; put_x: escribe X (XLO) y FLAGS = A | X_bit8 | paleta (N mod 4)
; ============================================
put_x:
    STA MARCA
    LDA XLO
    LDY #0
    JSR oam_put
    LDA XHI
    ASL A
    ASL A
    ORA MARCA
    STA MARCA
    LDA N
    AND #$03
    ORA MARCA
    LDY #3
    ; sigue en oam_put

; ============================================
; oam_put: escribe A en el byte OAM+Y (destruye X)
; ============================================
oam_put:
    TAX
    LDA #$C0
    STA VID_HI
    TYA
    CLC
    ADC OAM
    STA VID_LO
    STX VID_DT
    RTS

next_oam:
    LDA OAM
    CLC
    ADC #5
    STA OAM
    RTS

; ============================================
; hide_all: los 32 sprites a Y = 248
; ============================================
hide_all:
    LDA #0
    STA OAM
ha1:
    LDA #248
    LDY #1
    JSR oam_put
    JSR next_oam
    CMP #160
    BNE ha1
    RTS

; ============================================
; load_patterns: patrones 0..12 (13*8 = 104 filas)
;   plano 0 = cuadro con esquinas transparentes (color 1)
;   plano 1 = marca (color 3 = blanco)
; ============================================
load_patterns:
    LDY #0
lp1:
    STY VID_LO
    LDA #$C8
    STA VID_HI
    TYA
    AND #7
    TAX
    LDA box,X
    STA VID_DT
    LDA #$E8
    STA VID_HI
    STY VID_LO
    LDA glyphs,Y
    STA VID_DT
    INY
    CPY #104
    BNE lp1
    RTS

; ============================================
; load_palette: 16 entradas de sprite (X = 0 demo, 32 fabrica)
; ============================================
load_palette:
    LDA #16
    STA PAL_PTR
    LDY #16
pl1:
    LDA pals,X
    STA PAL_LO
    LDA pals+1,X
    STA PAL_HI
    INX
    INX
    DEY
    BNE pl1
    RTS

; ============================================
; draw_text: textos (fila, columna, cadena, 0); fila $FF = fin
; ============================================
draw_text:
    LDX #0
dt_str:
    LDA texts,X
    CMP #$FF
    BEQ dt_end
    STA FILA
    INX
    LDA texts,X
    STA COL
    INX
    JSR cell_addr
dt_ch:
    LDA texts,X
    INX
    CMP #0
    BEQ dt_str
    TAY
    LDA CUR
    STA VID_LO
    LDA CUR+1
    STA VID_HI
    STY VID_DT              ; tile = ASCII
    LDA CUR
    STA VID_LO
    LDA CUR+1
    ORA #$40
    STA VID_HI
    LDA #0
    STA VID_DT              ; atributo: paleta 0
    INC CUR
    BNE dt_ch
    INC CUR+1
    BNE dt_ch
dt_end:
    RTS

; CUR = FILA*64 + COL
cell_addr:
    LDA #0
    STA CUR
    LDA FILA
    LSR A
    ROR CUR
    LSR A
    ROR CUR
    STA CUR+1
    LDA CUR
    CLC
    ADC COL
    STA CUR
    BCC ca1
    INC CUR+1
ca1:
    RTS

wait_ready:
    LDA SETUP_ST
    AND #$10
    BEQ wait_ready
    RTS

; espera el inicio de un VBLANK
wframe:
    LDA VID_ST
    BMI wframe
wf2:
    LDA VID_ST
    BPL wf2
    RTS

; ============================================
; datos
; ============================================
texts:
    .byte 2, 6, "12 SPRITES EN LA MISMA LINEA", 0
    .byte 7, 6, "FIJOS: SE VEN DEL 1 A LA C", 0
    .byte 8, 6, "(LA D ES EL 13: NO SALE)", 0
    .byte 17, 6, "EN MOVIMIENTO: 12 SPRITES", 0
    .byte 25, 6, "TECLA O PULSADOR: SALIR", 0
    .byte $FF

; 4 paletas: color 1 = cuadro, color 3 = marca
pals:
    .word $000, $D00, $000, $FFF    ; rojo
    .word $000, $03F, $000, $FFF    ; azul
    .word $000, $080, $000, $FFF    ; verde
    .word $000, $B0B, $000, $FFF    ; magenta
    ; de fabrica
    .word $000, $F80, $840, $000
    .word $000, $00F, $0FF, $FFF
    .word $000, $F0F, $F00, $FFF
    .word $000, $0F0, $F80, $FFF

box:
    .byte $7E, $FF, $FF, $FF, $FF, $FF, $FF, $7E

glyphs:
    .byte $00,$10,$30,$10,$10,$10,$38,$00   ; 1
    .byte $00,$38,$04,$18,$20,$20,$3C,$00   ; 2
    .byte $00,$38,$04,$18,$04,$04,$38,$00   ; 3
    .byte $00,$24,$24,$3C,$04,$04,$04,$00   ; 4
    .byte $00,$3C,$20,$38,$04,$04,$38,$00   ; 5
    .byte $00,$18,$20,$38,$24,$24,$18,$00   ; 6
    .byte $00,$3C,$04,$08,$10,$10,$10,$00   ; 7
    .byte $00,$18,$24,$18,$24,$24,$18,$00   ; 8
    .byte $00,$18,$24,$1C,$04,$04,$18,$00   ; 9
    .byte $00,$18,$24,$3C,$24,$24,$24,$00   ; A
    .byte $00,$38,$24,$38,$24,$24,$38,$00   ; B
    .byte $00,$1C,$20,$20,$20,$20,$1C,$00   ; C
    .byte $00,$38,$24,$24,$24,$24,$38,$00   ; D
