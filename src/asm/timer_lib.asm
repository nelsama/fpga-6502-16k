; ============================================
; TIMER/RTC Library para fpga-6502
; 
; Funciones de timing precisas:
;   - Delays en microsegundos y milisegundos
;   - Medición de tiempo transcurrido
;   - Timer con interrupciones
;   - Timestamps de alta resolución
;
; Clock: 6.75 MHz (148.148 ns por tick)
; Precisión microsegundos: ~4% error
; ============================================

; ============================================
; Direcciones de registros
; ============================================
TICK_0      = $C030     ; Contador ticks byte 0 (LSB)
TICK_1      = $C031     ; Contador ticks byte 1
TICK_2      = $C032     ; Contador ticks byte 2
TICK_3      = $C033     ; Contador ticks byte 3 (MSB)
TIMER_LO    = $C034     ; Timer countdown low
TIMER_HI    = $C035     ; Timer countdown high
TIMER_CTL   = $C036     ; Timer control/status
TIMER_PRE   = $C037     ; Timer prescaler
USEC_0      = $C038     ; Microsegundos byte 0 (LSB)
USEC_1      = $C039     ; Microsegundos byte 1
USEC_2      = $C03A     ; Microsegundos byte 2
USEC_3      = $C03B     ; Microsegundos byte 3 (MSB)
LATCH_CTL   = $C03C     ; Latch control

; ============================================
; Bits de TIMER_CTL
; ============================================
TIMER_EN        = $01   ; Enable timer
TIMER_IRQ_EN    = $02   ; Enable IRQ
TIMER_REPEAT    = $04   ; Auto-reload
TIMER_IRQ_FLAG  = $08   ; IRQ pending (write 1 to clear)
TIMER_ZERO      = $80   ; Timer reached zero

; ============================================
; Bits de LATCH_CTL
; ============================================
LATCH_TICK      = $01   ; Latch tick counter
LATCH_USEC      = $02   ; Latch usec counter
LATCH_BOTH      = $03   ; Latch both
RESET_TICK      = $80   ; Reset tick counter
RESET_USEC      = $40   ; Reset usec counter

; ============================================
; Variables en Zero Page (ajustar según necesidad)
; ============================================
TIMER_TMP       = $E0   ; 4 bytes temporales para timer
DELAY_CNT       = $E4   ; 2 bytes para delay

; ============================================
; timer_latch_tick
; Captura el valor actual del contador de ticks
; Debe llamarse antes de leer TICK_0-3
; ============================================
timer_latch_tick:
    LDA #LATCH_TICK
    STA LATCH_CTL
    RTS

; ============================================
; timer_latch_usec
; Captura el valor actual del contador de microsegundos
; Debe llamarse antes de leer USEC_0-3
; ============================================
timer_latch_usec:
    LDA #LATCH_USEC
    STA LATCH_CTL
    RTS

; ============================================
; timer_latch_all
; Captura ambos contadores simultáneamente
; ============================================
timer_latch_all:
    LDA #LATCH_BOTH
    STA LATCH_CTL
    RTS

; ============================================
; timer_reset_usec
; Reinicia el contador de microsegundos a 0
; ============================================
timer_reset_usec:
    LDA #RESET_USEC
    STA LATCH_CTL
    RTS

; ============================================
; timer_get_usec
; Lee el contador de microsegundos a TIMER_TMP (4 bytes)
; ============================================
timer_get_usec:
    JSR timer_latch_usec
    LDA USEC_0
    STA TIMER_TMP
    LDA USEC_1
    STA TIMER_TMP+1
    LDA USEC_2
    STA TIMER_TMP+2
    LDA USEC_3
    STA TIMER_TMP+3
    RTS

; ============================================
; timer_get_tick
; Lee el contador de ticks a TIMER_TMP (4 bytes)
; ============================================
timer_get_tick:
    JSR timer_latch_tick
    LDA TICK_0
    STA TIMER_TMP
    LDA TICK_1
    STA TIMER_TMP+1
    LDA TICK_2
    STA TIMER_TMP+2
    LDA TICK_3
    STA TIMER_TMP+3
    RTS

; ============================================
; delay_us
; Delay en microsegundos (1-65535 us)
; Entrada: A = low byte, X = high byte
; Máximo: 65535 us = ~65.5 ms
; ============================================
delay_us:
    STA DELAY_CNT
    STX DELAY_CNT+1
    
    ; Obtener tiempo inicial
    JSR timer_latch_usec
    LDA USEC_0
    STA TIMER_TMP
    LDA USEC_1
    STA TIMER_TMP+1
    
delay_us_loop:
    ; Obtener tiempo actual
    JSR timer_latch_usec
    
    ; Calcular diferencia (16-bit)
    SEC
    LDA USEC_0
    SBC TIMER_TMP
    TAX             ; X = diferencia low
    LDA USEC_1
    SBC TIMER_TMP+1
    TAY             ; Y = diferencia high
    
    ; Comparar con delay deseado
    CPY DELAY_CNT+1
    BCC delay_us_loop   ; Si high < target high, seguir
    BNE delay_us_done   ; Si high > target high, terminó
    CPX DELAY_CNT
    BCC delay_us_loop   ; Si low < target low, seguir
    
delay_us_done:
    RTS

; ============================================
; delay_ms
; Delay en milisegundos (1-255 ms)
; Entrada: A = milisegundos
; ============================================
delay_ms:
    TAX             ; X = contador ms
delay_ms_loop:
    LDA #<1000      ; 1000 us = 1 ms
    LDY #>1000
    STY DELAY_CNT+1
    STA DELAY_CNT
    
    ; Llamar delay_us con 1000
    LDA #<1000
    LDX #>1000
    JSR delay_us
    
    DEX
    BNE delay_ms_loop
    RTS

; ============================================
; delay_100us
; Delay de 100 microsegundos (rápido)
; ============================================
delay_100us:
    LDA #100
    LDX #0
    JMP delay_us

; ============================================
; delay_1ms
; Delay de 1 milisegundo (rápido)
; ============================================
delay_1ms:
    LDA #<1000
    LDX #>1000
    JMP delay_us

; ============================================
; delay_10ms
; Delay de 10 milisegundos
; ============================================
delay_10ms:
    LDA #10
    JMP delay_ms

; ============================================
; delay_100ms
; Delay de 100 milisegundos
; ============================================
delay_100ms:
    LDA #100
    JMP delay_ms

; ============================================
; timer_start
; Inicia el timer programable
; Entrada: A = low byte, X = high byte del valor
;          Y = control flags (TIMER_EN, TIMER_IRQ_EN, TIMER_REPEAT)
; ============================================
timer_start:
    ; Guardar valor
    STA TIMER_LO
    STX TIMER_HI
    
    ; Activar con flags
    TYA
    ORA #TIMER_EN       ; Asegurar que está habilitado
    STA TIMER_CTL
    RTS

; ============================================
; timer_start_ms
; Inicia timer con valor en milisegundos
; Entrada: A = milisegundos (1-255)
;          X = flags (0 = one-shot, TIMER_REPEAT = repetir)
; Nota: Usa prescaler para extender el rango
; ============================================
timer_start_ms:
    PHA
    
    ; Configurar prescaler para ~1ms por tick
    ; Con 6.75 MHz y prescaler=6, cada tick = ~1.037 us
    ; Necesitamos ~1000 ticks para 1 ms
    LDA #6
    STA TIMER_PRE
    
    ; Calcular valor: ms * 1000 (aproximado con shift)
    ; Para simplificar: valor = ms * 1024 ≈ ms * 1000
    ; ms << 10 = ms * 1024
    PLA
    STA TIMER_LO        ; valor = ms (prescaler hace el resto)
    LDA #0
    STA TIMER_HI
    
    ; Activar
    TXA
    ORA #TIMER_EN
    STA TIMER_CTL
    RTS

; ============================================
; timer_stop
; Detiene el timer
; ============================================
timer_stop:
    LDA #0
    STA TIMER_CTL
    RTS

; ============================================
; timer_wait
; Espera hasta que el timer llegue a 0
; ============================================
timer_wait:
    LDA TIMER_CTL
    AND #TIMER_ZERO
    BEQ timer_wait
    
    ; Limpiar flag
    LDA #TIMER_IRQ_FLAG
    STA TIMER_CTL
    RTS

; ============================================
; timer_check
; Verifica si el timer llegó a 0
; Retorna: C=1 si terminó, C=0 si no
; ============================================
timer_check:
    LDA TIMER_CTL
    AND #TIMER_ZERO
    BEQ timer_not_done
    SEC
    RTS
timer_not_done:
    CLC
    RTS

; ============================================
; timer_clear_irq
; Limpia el flag de IRQ del timer
; ============================================
timer_clear_irq:
    LDA #TIMER_IRQ_FLAG
    STA TIMER_CTL
    RTS

; ============================================
; Ejemplo: Medir tiempo de ejecución
; ============================================
; Para medir cuánto tarda una rutina:
;
;   JSR timer_reset_usec    ; Resetear contador
;   JSR mi_rutina           ; Ejecutar código
;   JSR timer_get_usec      ; Leer tiempo
;   ; TIMER_TMP contiene microsegundos transcurridos
;
; ============================================

; ============================================
; Ejemplo: Blink LED cada 500ms con timer
; ============================================
; blink_setup:
;     LDA #<50000         ; 50000 ticks
;     LDX #>50000
;     LDY #(TIMER_EN | TIMER_REPEAT | TIMER_IRQ_EN)
;     JSR timer_start
;     RTS
;
; ; En el handler de IRQ:
; timer_irq_handler:
;     LDA TIMER_CTL
;     AND #TIMER_IRQ_FLAG
;     BEQ not_timer_irq
;     
;     ; Toggle LED
;     LDA $C000           ; Leer puerto
;     EOR #$01            ; Toggle bit 0
;     STA $C000           ; Escribir puerto
;     
;     ; Clear IRQ
;     JSR timer_clear_irq
;     
; not_timer_irq:
;     RTI
; ============================================
