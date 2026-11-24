; ============================================
; test_psram.asm -- PRUEBA DE LA RAM $4000-$7FFF (PSRAM)
;
; Se carga y ejecuta en $0800 (RAM BSRAM). Se repite sin parar:
;   1. secuencia pseudoaleatoria: escribir los 16 KB y verificarlos
;   2. lo mismo con los datos invertidos, escribiendo hacia abajo
;   3. INC (lectura-modificacion-escritura) de los 16 KB y verificar
;   4. ejecutar codigo desde $7F00 (copia una suma y comprueba el resultado)
;
; Pantalla y UART: "P=pppp E=eeee", pasadas y errores en hexadecimal, y el
;   primer error: A=direccion W=esperado R=leido.
;   Fondo VERDE = sin errores, ROJO = hubo errores.
; Salir: tecla por UART (no Enter) o un pulsador. Vuelve con RTS.
; ============================================

    .setcpu "6502"

VID_LO   = $D800
VID_HI   = $D801
VID_DT   = $D802
PAL_PTR  = $D813
PAL_LO   = $D814
PAL_HI   = $D815
SETUP    = $D816
SETUP_ST = $D817
UART_D   = $C020
UART_ST  = $C021
BTN      = $C005

PTR    = $10            ; y $11
SEED   = $12            ; y $13
S0     = $14            ; y $15 (semilla de la pasada)
PASS   = $16            ; y $17
ERR    = $18            ; y $19
EA     = $1A            ; y $1B direccion del primer error
EW     = $1C
ER     = $1D
XORV   = $1E
COLU   = $1F
TMP    = $20

    .segment "CODE"
    .org $0800

entry:
    SEI
    CLD
    JSR wait_ready
    LDA #0
    STA SETUP
    JSR wait_ready
    LDX #0
    TXA
clr:
    STA PASS,X
    INX
    CPX #8                  ; PASS, ERR, EA, EW, ER
    BNE clr
    LDA #$5A
    STA S0
    LDA #$C3
    STA S0+1
    JSR verde
    JSR show

main:
    ; ---- 1 y 2: aleatorio directo e invertido ----
    LDA #0
    STA XORV
    JSR fill_up
    JSR verify
    LDA #$FF
    STA XORV
    JSR fill_down
    JSR verify

    ; ---- 3: INC de cada byte ----
    JSR inc_all
    JSR verify_inc

    ; ---- 4: ejecutar desde la PSRAM ----
    JSR run_code

    ; siguiente semilla
    LDA S0
    CLC
    ADC #$37
    STA S0
    LDA S0+1
    ADC #$9D
    STA S0+1
    INC PASS
    BNE m1
    INC PASS+1
m1:
    JSR show

    ; salir?
    LDA UART_ST
    AND #$02
    BEQ no_tecla
    LDA UART_D
    CMP #$0D
    BEQ no_tecla
    CMP #$0A
    BNE salir
no_tecla:
    LDA BTN
    AND #$03
    CMP #$03
    BEQ main
salir:
    LDA #15                 ; BG_COLOR de fabrica
    STA PAL_PTR
    LDA #$8C
    STA PAL_LO
    LDA #$04
    STA PAL_HI
    RTS

; ============================================
; dato(PTR) = byte bajo de una mezcla de direccion y semilla, XOR XORV
;   A = dato. Depende de TODOS los bits de la direccion.
; ============================================
dato:
    LDA PTR
    EOR S0
    ASL A
    ADC PTR+1
    EOR S0+1
    ADC PTR
    EOR XORV
    RTS

ptr0:
    LDA #$00
    STA PTR
    LDA #$40
    STA PTR+1
    RTS

; PTR++ ; Z=1 al llegar a $8000
next:
    INC PTR
    BNE nx
    INC PTR+1
nx:
    LDA PTR+1
    CMP #$80
    RTS

fill_up:
    JSR ptr0
    LDY #0
fu:
    JSR dato
    STA (PTR),Y
    JSR next
    BNE fu
    RTS

fill_down:
    LDA #$FF
    STA PTR
    LDA #$7F
    STA PTR+1
    LDY #0
fd:
    JSR dato
    STA (PTR),Y
    LDA PTR
    BNE fd1
    DEC PTR+1
fd1:
    DEC PTR
    LDA PTR+1
    CMP #$3F
    BNE fd
    RTS

verify:
    JSR ptr0
    LDY #0
ve:
    JSR dato
    CMP (PTR),Y
    BEQ ve1
    JSR fallo
ve1:
    JSR next
    BNE ve
    RTS

inc_all:
    JSR ptr0
    LDY #0
ia:
    LDA PTR
    STA ia2+1
    LDA PTR+1
    STA ia2+2
ia2:
    INC $4000               ; direccion automodificada
    JSR next
    BNE ia
    RTS

verify_inc:
    JSR ptr0
    LDY #0
vi:
    JSR dato
    CLC
    ADC #1
    CMP (PTR),Y
    BEQ vi1
    JSR fallo
vi1:
    JSR next
    BNE vi
    RTS

; A = esperado, (PTR) = direccion
fallo:
    STA TMP
    LDA ERR
    ORA ERR+1
    BNE fa1
    LDA PTR
    STA EA
    LDA PTR+1
    STA EA+1
    LDA TMP
    STA EW
    LDA (PTR),Y
    STA ER
    JSR rojo
fa1:
    INC ERR
    BNE fa2
    INC ERR+1
    BNE fa2
    DEC ERR                 ; saturar en $FFFF
    DEC ERR+1
fa2:
    RTS

; ============================================
; codigo en PSRAM: suma 1..100 = 5050 = $13BA
; ============================================
run_code:
    LDX #rc_end-rc_code-1
rc1:
    LDA rc_code,X
    STA $7F00,X
    DEX
    BPL rc1
    JSR $7F00
    LDA $7FF0
    CMP #$BA
    BNE rc_bad
    LDA $7FF1
    CMP #$13
    BEQ rc_ok
rc_bad:
    LDA #$00
    STA PTR
    LDA #$7F
    STA PTR+1
    LDY #0
    LDA #$A9
    JSR fallo
rc_ok:
    RTS

rc_code:                    ; reubicable salvo los datos en $7FF0/$7FF1
    LDA #0
    STA $7FF0
    STA $7FF1
    LDX #100
rc2:
    TXA
    CLC
    ADC $7FF0
    STA $7FF0
    BCC rc3
    INC $7FF1
rc3:
    DEX
    BNE rc2
    RTS
rc_end:

; ============================================
; salida
; ============================================
verde:
    LDA #15
    STA PAL_PTR
    LDA #$60
    STA PAL_LO
    LDA #$00
    STA PAL_HI
    RTS
rojo:
    LDA #15
    STA PAL_PTR
    LDA #$00
    STA PAL_LO
    LDA #$0B
    STA PAL_HI
    RTS

show:
    LDA #4
    STA COLU
    LDX #0
sh1:
    LDA texto,X
    BEQ sh_end
    BMI sh_hex
    JSR out
    INX
    BNE sh1
sh_hex:                     ; $80+direccion de pagina cero -> byte en hex
    AND #$7F
    STX TMP
    TAX
    LDA 0,X
    LDX TMP
    PHA
    LSR A
    LSR A
    LSR A
    LSR A
    JSR nib
    PLA
    AND #$0F
    JSR nib
    INX
    BNE sh1
sh_end:
    LDA #$0D
    JSR putc
    LDA #$0A
    JMP putc

nib:
    CMP #10
    BCC nb
    ADC #6
nb:
    ADC #$30
    ; sigue en out

; caracter A a la pantalla (fila 12) y a la UART. Conserva X.
out:
    PHA
    LDA COLU
    STA VID_LO              ; fila 12*64 = $300 + columna
    LDA #$03
    STA VID_HI
    PLA
    STA VID_DT
    INC COLU
putc:
    PHA
pc1:
    LDA UART_ST
    AND #$01
    BEQ pc1
    PLA
    STA UART_D
    RTS

wait_ready:
    LDA SETUP_ST
    AND #$10
    BEQ wait_ready
    RTS

texto:
    .byte "P=", $80+PASS+1, $80+PASS, " E=", $80+ERR+1, $80+ERR
    .byte " A=", $80+EA+1, $80+EA, " W=", $80+EW, " R=", $80+ER, 0
