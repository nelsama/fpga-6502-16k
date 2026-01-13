# fpga-6502-16k

Computador retro basado en el procesador **MOS 6502** implementado en una **Sipeed Tang Nano 9K** (Gowin GW1NR-9). Incluye CPU, memoria RAM/ROM expandida, puertos GPIO bidireccionales, comunicación I2C, UART y **chip de sonido SID 6581**.

> 🆕 **Versión 16K**: ROM ampliada a 16KB ($8000-$BFFF) para mayor espacio de programa.

## 🏗️ Arquitectura del Sistema

```
┌──────────────────────────────────────────────────────────────────┐
│                         Board.vhd (Top-Level)                    │
│                                                                  │
│  CLOCK_27MHz ──▶ [CLKDIV] ──▶ 6.75 MHz ──▶ /2 ──▶ 3.375 MHz     │
│                      │                                           │
│                      └──▶ /7 ──▶ ~1 MHz (SID)                    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                      CPU 6502 (cpu65xx_fast)                │ │
│  │              Cycle-exact, table-driven implementation       │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                       [Data Bus Mux]                             │
│      ┌───────────────────────┼───────────────────────┐           │
│      ▼         ▼       ▼     ▼     ▼         ▼       ▼           │
│ ┌────────┐┌────────┐┌────────────┐┌────────┐┌──────────┐         │
│ │  RAM   ││  ROM   ││ Puertos I/O││SID 6581││SPI Master│         │
│ │ 16 KB  ││ 16 KB  ││GPIO+I2C+UAR││ Audio  ││ SD Card  │         │
│ └────────┘└────────┘└────────────┘└───┬────┘└────┬─────┘         │
│                                       │ PWM      │ SPI           │
│                                  [Audio Out] [SD Card]           │
└──────────────────────────────────────────────────────────────────┘
```

## 🗺️ Mapa de Memoria

| Rango | Tamaño | Descripción |
|-------|--------|-------------|
| `$0000 - $3FFF` | 16 KB | **RAM** (Zero Page, Stack, memoria de trabajo) |
| `$4000 - $7FFF` | 16 KB | *No usado* |
| `$8000 - $BFFF` | 16 KB | **ROM** (Código del programa) |
| `$C000` | 1 byte | **Puerto 1** - Datos (bidireccional) |
| `$C001` | 1 byte | **Puerto 2** - Datos (bidireccional) |
| `$C002` | 1 byte | **Config Puerto 1** (0=salida, 1=entrada) |
| `$C003` | 1 byte | **Config Puerto 2** (0=salida, 1=entrada) |
| `$C010 - $C017` | 8 bytes | **Registros I2C Master** |
| `$C020 - $C023` | 4 bytes | **Registros UART** |
| `$C030 - $C03F` | 16 bytes | **Timer de precisión** |
| `$C040 - $C047` | 8 bytes | **SPI Master** (SD Card) |
| `$D400 - $D41F` | 32 bytes | **SID 6581** (compatible C64) |
| `$FFFA - $FFFF` | 6 bytes | **Vectores** (mapeados a ROM $BFFA-$BFFF) |

### Registros I2C

| Dirección | Registro |
|-----------|----------|
| `$C010` | Prescaler LSB |
| `$C011` | Prescaler MSB |
| `$C012` | Control |
| `$C013` | TX/RX Data |
| `$C014` | Command/Status |

### Registros UART (115200 baud, 8N1)

| Dirección | Lectura | Escritura |
|-----------|---------|----------|
| `$C020` | RX Data | TX Data |
| `$C021` | Status | Control |

### Registros Timer/RTC

| Dirección | Registro | Descripción |
|-----------|----------|-------------|
| `$C030` | TICK_0 | Contador ticks byte 0 (LSB) |
| `$C031` | TICK_1 | Contador ticks byte 1 |
| `$C032` | TICK_2 | Contador ticks byte 2 |
| `$C033` | TICK_3 | Contador ticks byte 3 (MSB) |
| `$C034` | TIMER_LO | Timer countdown low (R/W) |
| `$C035` | TIMER_HI | Timer countdown high (R/W) |
| `$C036` | TIMER_CTL | Control/Status |
| `$C037` | PRESCALER | Prescaler del timer |
| `$C038` | USEC_0 | Microsegundos byte 0 (LSB) |
| `$C039` | USEC_1 | Microsegundos byte 1 |
| `$C03A` | USEC_2 | Microsegundos byte 2 |
| `$C03B` | USEC_3 | Microsegundos byte 3 (MSB) |
| `$C03C` | LATCH_CTL | Control de latch |

**TIMER_CTL bits:** EN(0), IRQ_EN(1), REPEAT(2), IRQ_FLAG(3), ZERO(7)

**Status bits (lectura):** TX_READY(0), RX_VALID(1), TX_BUSY(2), RX_ERROR(3), RX_OVERRUN(4)

### Registros SPI Master (SD Card)

Interfaz SPI para tarjeta microSD usando pines TF Card del Tang Nano 9K.
Utiliza el IP SPI Master de Gowin con control de CS manual.

| Dirección | Registro | Tipo | Descripción |
|-----------|----------|------|-------------|
| `$C040` | RX_DATA | IP (R) | Dato recibido del SPI |
| `$C041` | TX_DATA | IP (W) | Dato a transmitir (escribir inicia TX) |
| `$C042` | STATUS | IP (R) | Estado de la transferencia |
| `$C043` | CONTROL | IP (R/W) | Control de interrupciones |
| `$C044` | SS_MASK | Local (R/W) | Máscara de Slave Select (bit0=CS0, etc) |
| `$C045` | CS_ENABLE | Local (R/W) | bit0=1 activa los CS seleccionados |
| `$C046-$C047` | - | - | Reservado |

**Status Register ($C042) bits:**
- Bit 2: ROE - Rx Overrun Error
- Bit 3: TOE - Tx Overrun Error  
- Bit 4: TMT - Tx shift register empty
- Bit 5: TRDY - Tx register ready
- Bit 6: RRDY - Rx register ready (dato disponible)
- Bit 7: E - Error (ROE | TOE)

**Chip Selects disponibles:**
- CS[0]: SD Card (pin 38)
- CS[1]: Externo (pin 25)
- CS[2]: Externo (pin 26)
- CS[3]: Externo (pin 27)

**Secuencia de uso típica:**
```asm
; 1. Configurar CS para SD Card (CS0)
    LDA #$01
    STA $C044       ; SS_MASK = bit 0

; 2. Activar CS
    LDA #$01
    STA $C045       ; CS_ENABLE = 1

; 3. Enviar byte (ej: 0xFF para clock)
    LDA #$FF
    STA $C041       ; TX_DATA - inicia transferencia

; 4. Esperar que termine (RRDY = 1)
wait:
    LDA $C042       ; STATUS
    AND #$40        ; bit 6 = RRDY
    BEQ wait

; 5. Leer respuesta
    LDA $C040       ; RX_DATA

; 6. Desactivar CS al terminar
    LDA #$00
    STA $C045       ; CS_ENABLE = 0
```

**Nota:** El IP Gowin tiene el registro Slave Select en dirección 0x10, 
inaccesible con I_WADDR de 3 bits. Por eso el wrapper maneja CS manualmente
con registros locales ($C044, $C045)

### Registros SID 6581 (Compatible C64)

El chip de sonido SID está mapeado en `$D400-$D41F`, igual que en el Commodore 64.

| Dirección | Registro | Descripción |
|-----------|----------|-------------|
| `$D400` | FREQ_LO_1 | Voz 1 - Frecuencia low byte |
| `$D401` | FREQ_HI_1 | Voz 1 - Frecuencia high byte |
| `$D402` | PW_LO_1 | Voz 1 - Pulse width low byte |
| `$D403` | PW_HI_1 | Voz 1 - Pulse width high (bits 0-3) |
| `$D404` | CTRL_1 | Voz 1 - Control (Gate, Sync, Ring, Test, Waveform) |
| `$D405` | AD_1 | Voz 1 - Attack/Decay |
| `$D406` | SR_1 | Voz 1 - Sustain/Release |
| `$D407-$D40D` | | Voz 2 (misma estructura) |
| `$D40E-$D414` | | Voz 3 (misma estructura) |
| `$D415` | FC_LO | Filtro - Cutoff frequency low (bits 0-2) |
| `$D416` | FC_HI | Filtro - Cutoff frequency high |
| `$D417` | RES_FILT | Resonancia (4-7) / Selección filtro (0-3) |
| `$D418` | MODE_VOL | Modo filtro (4-7) / Volumen master (0-3) |
| `$D419` | POT_X | Paddle X (solo lectura) |
| `$D41A` | POT_Y | Paddle Y (solo lectura) |
| `$D41B` | OSC3 | Oscilador 3 random (solo lectura) |
| `$D41C` | ENV3 | Envelope voz 3 (solo lectura) - *Compatible C64* |
| `$D41D` | ENV1 | Envelope voz 1 (solo lectura) ⚡ |
| `$D41E` | ENV2 | Envelope voz 2 (solo lectura) ⚡ |
| `$D41F` | ENV_MAX | Máximo de ENV1/ENV2/ENV3 (solo lectura) ⚡ |

> ⚡ **Extensión VU Meter**: Los registros $D41D-$D41F son extensiones que exponen los envelopes
> de las 3 voces individualmente más el máximo combinado. Esto permite implementar visualizadores
> de audio (VU meters) en software. **$D41C mantiene compatibilidad total con el C64 original.**

**Ejemplo de uso para VU meter:**
```asm
; Leer nivel de audio global (máximo de las 3 voces)
    LDA $D41F       ; ENV_MAX -> A = 0-255

; Leer envelopes individuales
    LDA $D41D       ; ENV1 (voz 1)
    LDA $D41E       ; ENV2 (voz 2)  
    LDA $D41C       ; ENV3 (voz 3) - compatible C64
```

**Control Register ($D404, $D40B, $D412) bits:**
- Bit 0: GATE (iniciar/detener envelope)
- Bit 1: SYNC (sincronizar con voz anterior)
- Bit 2: RING (modulación en anillo)
- Bit 3: TEST (desactivar oscilador)
- Bit 4: TRIANGLE
- Bit 5: SAWTOOTH  
- Bit 6: PULSE
- Bit 7: NOISE

## ⚡ Frecuencias de Reloj

| Señal | Frecuencia | Uso |
|-------|------------|-----|
| `CLOCK_27_i` | 27 MHz | Entrada del cristal, DAC SID |
| `system_clk` | 6.75 MHz | Reloj del sistema |
| `cpu_clk` | **3.375 MHz** | Reloj del CPU 6502 |
| `clk_1mhz` | ~0.96 MHz | Reloj del SID 6581 (27MHz/28) |

## 🔧 Componentes

### CPU 6502
- **Core**: `cpu65xx_fast.vhd` de Peter Wendrich (proyecto FPGA64)
- **Tipo**: Implementación cycle-exact dirigida por tablas
- **Características**: Soporte completo de IRQ, NMI, pipeline opcional

### Memoria
- **RAM**: 16 KB usando Block RAM de Gowin (8 bloques BSRAM)
- **ROM**: 16 KB con programa hardcoded (16 bloques BSRAM, generada con Python)
- **Uso BSRAM**: 24/26 bloques (92%)

### Puertos GPIO
- **Puerto 1**: 8 bits (LVCMOS33, pines 70-77)
- **Puerto 2**: 6 bits (LVCMOS18, pines 10-16)
- Cada pin configurable individualmente como entrada o salida

### Interfaz I2C
- IP Core `I2C_MASTER_Top` de Gowin
- Señal de interrupción disponible

### Sistema de Reset
- Generador de power-on reset (50ms)
- Debouncer para botón de reset externo

### Chip de Sonido SID 6581
- **Implementación**: NetSID (VHDL) con DAC Delta-Sigma
- **Modelo**: SID 6581 (NMOS original, no 8580)
- **3 voces** con formas de onda: Triangle, Sawtooth, Pulse, Noise
- **Filtro multimodo**: Low-pass, Band-pass, High-pass, Notch
- **ADSR envelope** por voz con aproximación exponencial por tramos
- **Salida**: PWM Delta-Sigma (pin 33)
- **Reloj SID**: ~1 MHz (derivado de 27 MHz)
- **Reloj DAC**: 27 MHz
- **Direccionamiento**: $D400-$D41F (compatible C64)
- **Sincronización**: Cross-domain entre CPU (6.75 MHz) y SID (27 MHz)

**¿Por qué 6581 y no 8580?**

| Característica | 6581 (este) | 8580 |
|----------------|-------------|------|
| Proceso | NMOS (12V) | HMOS (9V) |
| DC Offset | ✅ Presente | ❌ Eliminado |
| Filtros | "Sucios", más resonantes | Más limpios |
| Sonido | Clásico C64 (1982-1986) | C64C posterior |

El 6581 tiene un "bug" de DC offset que permite reproducir samples digitales, convirtiéndose en una característica distintiva del sonido Commodore 64 original.

**Circuito de audio recomendado:**
```
Pin 33 ──[3.3kΩ]──┬──[4.7nF]── GND
                  │
                  └── Amplificador/Altavoz
```

## 📌 FPGA Target

| Parámetro | Valor |
|-----------|-------|
| **Placa** | Sipeed Tang Nano 9K |
| **Familia** | Gowin GW1NR |
| **Part Number** | GW1NR-LV9QN88PC6/I5 |
| **Dispositivo** | GW1NR-9C |
| **Paquete** | QN88 |

### Pinout

| Señal | Pin | Tipo | Descripción |
|-------|-----|------|-------------|
| `CLOCK_27_i` | 52 | LVCMOS33 | Reloj de entrada 27 MHz |
| `reset_in` | 4 | LVCMOS18 | Botón de reset (pull-up) |
| `cpu_clk_out` | 35 | LVCMOS33 | Salida reloj CPU 3.375 MHz |
| `uart_tx` | 32 | LVCMOS33 | UART TX → USB-TTL RX |
| `uart_rx` | 31 | LVCMOS33 | UART RX ← USB-TTL TX |
| `sid_audio_out` | 33 | LVCMOS33 | SID Audio PWM output |
| `i2c_scl` | 48 | LVCMOS33 | I2C Clock (pull-up) |
| `i2c_sda` | 49 | LVCMOS33 | I2C Data (pull-up) |
| `port_1[0:7]` | 70-77 | LVCMOS33 | GPIO Puerto 1 (8 bits) |
| `port_2[0:5]` | 10-16 | LVCMOS18 | GPIO Puerto 2 (6 bits) |

## 📂 Estructura del Proyecto

```
src/
├── Board.vhd                 # Top-level entity
├── A6502.vhd                 # Wrapper del CPU
├── Data_bus_mux.vhd          # Multiplexor del bus de datos
├── rom.vhd                   # ROM con programa (8KB)
├── register_8bit.vhd         # Registro para puertos GPIO
├── Reset.vhd                 # Generador de reset
├── Debouncer.vhd             # Anti-rebote
├── i2c_master_interface.vhd  # Wrapper I2C
├── uart.vhd                  # Módulo UART (TX/RX)
├── uart_wrapper.vhd          # Wrapper UART para bus 6502
├── timer_rtc.vhd             # Timer de precisión
├── timer_wrapper.vhd         # Wrapper Timer para bus 6502
├── sid_wrapper.vhd           # Wrapper SID para bus 6502
├── 6502/
│   └── cpu65xx_fast.vhd      # Core del CPU 6502
├── NetSID/                   # Chip de sonido SID 6581
│   └── src/
│       ├── sid_6581.vhd      # Core principal SID
│       ├── sid_voice.vhd     # Generador de voz
│       ├── sid_filters.vhd   # Filtros analógicos
│       ├── sid_components.vhd # Componentes auxiliares
│       └── dac.vhd           # DAC Delta-Sigma para audio
├── gowin_clkdiv_*/           # IP divisor de reloj
├── gowin_sp/                 # IP RAM
├── i2c_master/               # IP I2C Master
└── asm/                      # Librerías en ensamblador 6502
    └── timer_lib.asm         # Funciones de timer/delay
impl/                         # Archivos de implementación (generados)
*.gprj                        # Archivo de proyecto Gowin
```

## 🛠️ Compilación y Uso

1. Abrir el proyecto `6502_board_v2_1.gprj` en **Gowin EDA**
2. Ejecutar síntesis
3. Ejecutar Place & Route
4. Generar bitstream
5. Programar la FPGA con el archivo `.fs`

## 🧰 Herramientas Requeridas

- **Gowin EDA** (GOWIN FPGA Designer)
- **Gowin Programmer** para cargar el bitstream

## 📜 Créditos

- **CPU 6502 Core**: Peter Wendrich ([FPGA64 Project](http://www.syntiac.com/fpga64.html))
- **SID 6581 Core**: NetSID Project (implementación VHDL del chip de sonido)

## 📄 Licencia

[Especificar licencia aquí]

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue antes de enviar pull requests.