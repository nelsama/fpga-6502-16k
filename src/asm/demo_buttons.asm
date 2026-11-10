; ============================================
; demo_buttons.asm -- PRUEBA DE LOS PULSADORES $C005
;
; Lee los dos pulsadores de uso general y los muestra por UART.
;
;   $C005 bit0 = BTN_A (pin 86)   0 = pulsado
;   $C005 bit1 = BTN_B (pin 85)   0 = pulsado
;
; SIN antirrebote en hardware: este programa SI filtra por software
; (espera 20 ms tras detectar el cambio y vuelve a comprobar).
;
; Al arrancar imprime el estado inicial y luego informa de cada pulsacion:
;
;   BTN A pulsado
;   BTN A soltado
;   BTN B pulsado
;   BTN B soltado
;
; Vuelve con RTS cuando se pulsa AMBOS botones a la vez.
;
; Mapa UART ($C020):
;   $C020  W = TX data       R = RX data
;   $C021  R = STATUS        bit0 = TX_READY
;
; Zero page:
;   $10 PREV   estado anterior de $C005 (solo bits 1:0)
;   $11 TMP
; ============================================

    .setcpu "6502"

UART_TX  = $C020
UART_ST  = $C021
BTN      = $C005

PREV  = $10
TMP   = $11

    .segment "CODE"
    .org $0800

entry:
    SEI
    CLD
    ; NO se toca la pila: el monitor vuelve con RTS.

    ; --- mensaje inicial ---
    JSR crlf
    LDX #0
msg1:
    LDA txt_ready,X
    BEQ msg1_done
    JSR putc
    INX
    BNE msg1
msg1_done:
    JSR crlf

    ; --- estado inicial ---
    LDA BTN
    AND #$03
    STA PREV
    JSR crlf
    JSR show_state

main:
    LDA BTN
    AND #$03            ; aislar los dos bits
    CMP PREV
    BEQ main            ; sin cambios -> seguir

    ; --- posible cambio: confirmar tras 20 ms ---
    STA TMP             ; valor candidato
    JSR delay20ms

    LDA BTN
    AND #$03
    CMP TMP
    BNE main            ; rebote: el valor cambio otra vez -> descartar

    ; --- cambio confirmado ---
    STA TMP

    ; que boton cambio?
    LDA PREV
    EOR TMP             ; bits que cambiaron
    AND #$01
    BEQ check_b         ; no cambio A -> mirar B

    ; --- BTN A cambio ---
    LDA TMP
    AND #$01
    BNE a_released
    JSR crlf
    LDX #0
ma_on:
    LDA txt_a_on,X
    BEQ ma_on_done
    JSR putc
    INX
    BNE ma_on
ma_on_done:
    JMP upd

a_released:
    JSR crlf
    LDX #0
ma_off:
    LDA txt_a_off,X
    BEQ ma_off_done
    JSR putc
    INX
    BNE ma_off
ma_off_done:
    JMP upd

    ; --- BTN B cambio ---
check_b:
    LDA TMP
    AND #$02
    BNE b_released
    JSR crlf
    LDX #0
mb_on:
    LDA txt_b_on,X
    BEQ mb_on_done
    JSR putc
    INX
    BNE mb_on
mb_on_done:
    JMP upd

b_released:
    JSR crlf
    LDX #0
mb_off:
    LDA txt_b_off,X
    BEQ mb_off_done
    JSR putc
    INX
    BNE mb_off
mb_off_done:

upd:
    LDA TMP
    STA PREV

    ; --- los DOS pulsados a la vez (bits 1:0 = 00)? salir ---
    CMP #$00
    BNE main

    JSR crlf
    LDX #0
bye:
    LDA txt_bye,X
    BEQ bye_done
    JSR putc
    INX
    BNE bye
bye_done:
    JSR crlf
    RTS

; ============================================
; show_state: imprime "estado = $XX"
; ============================================
show_state:
    LDX #0
ss_loop:
    LDA txt_state,X
    BEQ ss_hex
    JSR putc
    INX
    BNE ss_loop
ss_hex:
    LDA PREV
    JSR put_hex
    JMP crlf

; ============================================
; putc: envia el caracter de A por UART
; ============================================
putc:
    PHA                 ; guardar el caracter
pc_wait:
    LDA UART_ST
    AND #$01            ; TX_READY
    BEQ pc_wait
    PLA
    STA UART_TX
    RTS

; ============================================
; put_hex: imprime A como dos digitos hex
; ============================================
put_hex:
    PHA
    LSR A
    LSR A
    LSR A
    LSR A
    JSR put_nib
    PLA
    AND #$0F
    JMP put_nib

put_nib:
    CMP #10
    BCC pn_digit
    CLC
    ADC #$37            ; 'A'-10 = 55 = $37
    JMP putc
pn_digit:
    CLC
    ADC #$30            ; '0'
    JMP putc

; ============================================
; crlf: nueva linea
; ============================================
crlf:
    LDA #$0D
    JSR putc
    LDA #$0A
    JMP putc

; ============================================
; delay20ms: retardo aproximado de 20 ms
;   A 3,375 MHz son ~67500 ciclos. Bucle de ~13 ciclos:
;   67500 / 13 ~= 5192 -> 3 bytes anidados de 256.
;   Sobra aproximacion: solo sirve para filtrar rebotes.
; ============================================
delay20ms:
    PHA
    TXA
    PHA
    TYA
    PHA                 ; la pila esta en $01xx, segura

    LDX #$20            ; contador externo
    LDY #$00            ; contador medio (256)
d20_mid:
    LDA #$18            ; contador interno (24)
d20_inner:
    SEC
    SBC #$01
    BNE d20_inner
    DEY
    BNE d20_mid
    DEX
    BNE d20_mid

    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

txt_ready:
    .byte $0D,$0A
    .byte "PRUEBA DE PULSADORES $C005", $0D, $0A
    .byte "A = pin 86, B = pin 85 (0 = pulsado)", $0D, $0A
    .byte "Pulsa A y B a la vez para salir.", $00

txt_state:
    .byte "Estado inicial: $", $00

txt_a_on:
    .byte "BTN A pulsado", $00
txt_a_off:
    .byte "BTN A soltado", $00
txt_b_on:
    .byte "BTN B pulsado", $00
txt_b_off:
    .byte "BTN B soltado", $00
txt_bye:
    .byte "Fin.", $00
