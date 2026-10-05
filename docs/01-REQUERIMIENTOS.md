# Módulo de Vídeo — Documento de Requerimientos

**Proyecto:** fpga-6502-16k
**Plataforma:** Sipeed Tang Nano 9K — Gowin GW1NR-9 (`GW1NR-LV9QN88PC6/I5`, Device Version C)
**Documento:** Especificación de requerimientos del subsistema de vídeo
**Estado:** Análisis / pre-implementación

> ⚠️ **DOCUMENTO HISTÓRICO (intención inicial).** Las cifras de este documento (número
> de paletas, colores, registros, sprites, etc.) son la **ambición inicial**, no el
> hardware implementado. El **estado real** está en `02-PLAN-IMPLEMENTACION.md`
> (fases) y sobre todo en **`07-MANUAL-PROGRAMACION.md`** (registros y capacidades
> reales). Cuando haya discrepancia, manda el manual.

---

## 1. Objetivo

Añadir al computador 6502 existente un **subsistema de vídeo** que permita desarrollar
juegos retro, **sin eliminar ninguno de los módulos actuales** (CPU, RAM, ROM, SID,
GPIO, I2C, UART, Timer, SPI).

El diseño sigue el modelo de **coprocesador gráfico** (estilo VIC-II / NES PPU):
el software configura registros y memoria; el hardware genera la señal de vídeo de
forma continua y autónoma.

---

## 2. Recursos disponibles (medidos, no estimados)

Fuente: `impl/pnr/6502_board_v3.rpt.txt` — síntesis y place&route ejecutados sobre el
diseño actual (sin vídeo).

| Recurso | Uso actual | Total | Libre |
|---------|-----------|-------|-------|
| **Logic (LUT + ALU)** | 3.323 (2.684 LUT + 639 ALU) | 8.640 | **5.317 (61%)** |
| **Registros** | 1.676 | 6.693 | 5.017 (74%) |
| **CLS** (células lógicas) | 2.231 | 4.320 | 2.089 (48%) |
| **BSRAM** | 20 bloques (8 SP + 12 pROM) | 26 | **6 bloques (~12 KB)** |
| **DSP** | 2 (MULT18X18) | 10 | 8 (80%) |
| **PLL** | 1 | 2 | **1** |
| **Redes globales PRIMARY** | 4 | 8 | 4 |
| **Redes globales LW** | 5 | 8 | 3 |
| **GCLK_PIN** | 3 | 3 | 0 (no aplica al vídeo, ver §9) |

### 2.1 Consumo por módulo (referencia)

| Módulo | LUT | Registros | BSRAM | DSP |
|--------|-----|-----------|-------|-----|
| CPU 6502 (`cpu65xx`) | 639 | 112 | 2 | — |
| SID (3 voces + filtros + coeffs) | ~1.139 | ~880 | 2 | 4 |
| Timer | 238 | 184 | — | — |
| I2C | 217 | 124 | — | — |
| UART | 132 | 90 | — | — |
| SPI | 95 | 77 | — | — |
| ROM | — | — | 8 | — |
| RAM | 25 | 2 | 8 | — |

---

## 3. Requerimientos funcionales

### RF-01 — Modos de vídeo

El módulo debe soportar tres modos **mutuamente excluyentes**, seleccionables por registro:

| Modo | Descripción | Uso |
|------|-------------|-----|
| `00` | **Tiles + sprites** | Juegos |
| `01` | **Texto** | Consola en pantalla (reemplazo del UART) |
| `10` | **Bitmap 1bpp** | Lienzo / editor gráfico |

### RF-02 — Modo tiles + sprites

- Fondo construido por **tilemap de 40×30 celdas** (320×240 px lógicos).
- **Tile = 8×8 píxeles**, 2 bits por píxel (**2bpp planar**, 16 bytes por patrón).
- **256 patrones** de tile.
- **Atributo por celda** de 8 bits (ver §4).
- **Sprites**: hasta 64 entradas de OAM, patrón de 16×16 @ 2bpp.

### RF-03 — Modo texto

- Comparte estructuras con el modo tiles (el char map **es** un tilemap).
- **40×30 caracteres**, charset de 256 glifos de 8×8 @ 2bpp.
- Sin sprites, sin scroll.
- Debe permitir escribir un carácter con una sola escritura.

### RF-04 — Modo bitmap

- **320×240 a 1bpp** (9.600 B) + atributo de color por celda de 8×8 (1.200 B).
- Acceso a píxel individual desde el CPU.
- Debe permitir implementar herramientas de dibujo.

### RF-05 — Paleta y color

- **Paletas de 32 entradas × 12 bits RGB** (4.096 colores elegibles).
  *(Idea inicial: 64 entradas. Implementado: 32 = 16 fondo + 16 sprite.)*
- Paletas en **registros del FPGA**, no en BSRAM. **Escribibles por el CPU** (`$D813-$D815`).
- **Bancos separados** de paleta para fondo y sprites (4 paletas × 4 colores cada banco).
- Color 0 de los **sprites = transparente** (por convención).
- Color 0 del **fondo** tambien es transparente (se ve `BG_COLOR` o un sprite detras). **`BG_COLOR` = una entrada de la paleta de fondo** (la 15), escribible por el CPU. Ver manual §4.3. (Nota: la idea inicial era un registro `BG_COLOR` dedicado; se implemento como entrada de paleta por coste de recursos.)
- Resultado: **hasta 32 colores simultáneos** en pantalla (16 fondo + 16 sprite). *(Idea inicial: 64; implementado: 32.)*

### RF-06 — Transformaciones de sprite

- **FlipX / FlipY** (gratis, cableado).
- **Escalado entero** (2×, 3×, 4×) mediante cambio de paso.
- **Rotación** mediante vector de paso precalculado (DDA por línea) + tabla de seno/coseno.
- **8 orientaciones** del grupo diedral (flip + transposición de dirección).

### RF-07 — Acceso del CPU a la VRAM

- **VRAM mapeada en `$4000–$7FFF`** (16 KB de espacio de direcciones actualmente sin decodificar, ver §8).
- Acceso **directo** desde el CPU (modelo A, estilo C64), no por registros indirectos.
- La VRAM reside en **BSRAM Pseudo Dual Port**: puerto A = CPU, puerto B = motor.

### RF-08 — Animación de tiles

- Método primario: **reescritura del patrón** desde el CPU (método 1), con frames
  almacenados en ROM.
- Debe soportar **reescritura parcial de filas** para reducir ciclos.
- Opcional (fase posterior): **tabla de slots de animación** para animaciones largas.

### RF-09 — Sincronización con el software

- Registro `STATUS` con bit de **vblank**.
- Opción de **NMI en vblank**.
- Ventana de vblank: ~4.800 ciclos de CPU (`45 líneas × 800 px`).

### RF-10 — Escalado y salida

- **Timing de barrido:** 858 × 525 @ 27 MHz → 720×480 @ 60 Hz. *Congelado:*
  es el timing validado en la Fase 1 y no debe modificarse.
- **Zona visible:** 720 × 480.
- **Zona útil:** **640 × 480**, centrada con **40 px de margen a cada lado**.
  El margen se pinta con el color de fondo (`BG_COLOR`).
- **Resolución lógica:** **320 × 240** (40 × 30 celdas de 8×8).
- **Escalado:** ×2 (trivial: `x_logico = x_util(9 downto 1)`).

```
  ┌──────────── 720 px ────────────────┐
  │  40 │          640 px          │ 40 │
  │ BG  │    zona útil (40 cols)   │ BG │
  └──────────── 480 px ────────────────┘
```

**Por qué el margen centrado:** absorbe el error de alineación del pipeline
en ambas direcciones, de modo que los bordes de la zona útil nunca se cortan
(ver el defecto diferido de la Fase 2).

**Pixel clock:** 27 MHz (crystal directo, sin PLL para el pixel clock).
**Reloj serie TMDS:** 135 MHz (PLL ×5).
**Salida:** HDMI (TMDS) vía `OSER10` + `ELVDS_OBUF` — **implementado y verificado**.

### RF-10b — Presupuesto de VRAM (320×240, 192 patrones)

| Estructura | Cálculo | Tamaño |
|-----------|---------|--------|
| Tilemap | 40×30 × 1 B | 1.200 B |
| Atributos | 40×30 × 1 B | 1.200 B |
| Patrones de tile (192 @ 2bpp) | 192 × 16 | 3.072 B |
| Patrones de sprite (32 @ 16×16 @ 2bpp) | 32 × 64 | 2.048 B |
| OAM | 64 × 4 B | 256 B |
| **Total modo tiles** | | **7.776 B** |
| **Disponible** | | 12.288 B |
| **Margen** | | **4.512 B (37%)** |

**Justificación de 192 patrones:** un juego de plataformas usa 95-125 patrones de
fondo, y un RPG con autotiling 140-185. La fuente de texto es el mayor consumidor
(44 patrones para A-Z + 0-9 + símbolos). 192 cubre esos casos con margen, a un
coste de 1 KB extra frente a 128.

### RF-11 — Registros de control

Mapa propuesto (a confirmar en fase de diseño). **OJO: es una idea inicial; el mapa
REAL implementado (registros `$D800-$D815`, OAM 32×5, paletas escribibles, BG_COLOR =
pal_bg(15), etc.) está en `07-MANUAL-PROGRAMACION.md` §2.1.**

| Dirección | Nombre | Función |
|-----------|--------|---------|
| `$D800` | `VRAM_ADDR_LO` | Dirección VRAM, byte bajo |
| `$D801` | `VRAM_ADDR_HI` | Dirección VRAM, byte alto |
| `$D802` | `VRAM_DATA` | Datos R/W, autoincrementa dirección |
| `$D803` | `SCROLL_X` | Scroll horizontal fino |
| `$D804` | `SCROLL_Y` | Scroll vertical fino |
| `$D805` | `CTRL` | bits 1:0 modo, bit 7 enable vídeo |
| `$D806` | `STATUS` | bit 7 vblank, bits 4:0 colisión sprites |
| `$D807` | `BG_COLOR` | Color de fondo global |
| `$D808` | `SPRITE_ADDR` | Selección de sprite |
| `$D810–$D82F` | `OAM` | 64 sprites × 4 bytes (X, Y, tile, flags) |
| `$D830–$D87F` | `PALETTE` | 64 entradas × 12 bits |

---

## 4. Especificación del byte de atributo (fondo)

Cada celda del tilemap tiene un **byte de atributo** asociado:

```
  bit 7    bit 6    bit 5    bit 4    bit 3    bit 2    bit 1    bit 0
┌────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│ PRIO   │ FLIP_Y │ FLIP_X │   PALETA (4 bits)                          │
└────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

| Bits | Campo | Descripción |
|------|-------|-------------|
| 7 | `PRIO` | Prioridad: 0 = detrás de sprites, 1 = delante |
| 6 | `FLIP_Y` | Volteo vertical |
| 5 | `FLIP_X` | Volteo horizontal |
| 4:0 | `PALETA` | Índice de paleta (0–15 de las 16 disponibles; 4 bits usados) |

**Multiplicadores de variedad:** 256 patrones × 4 orientaciones × 16 paletas
= **16.384 combinaciones visuales**.

### 4.1 Byte de flags de sprite (OAM)

```
  bit 7    bit 6    bit 5    bit 4    bit 3    bit 2    bit 1    bit 0
┌────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│ FLIP_Y │ FLIP_X │ PRIO   │  ÁNGULO/ESCALA (5 bits: 4 ángulo + 1 escala) │
└────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

(A confirmar en diseño detallado: reparto exacto de bits de ángulo y escala.)

---

## 5. Presupuesto de BSRAM

### 5.1 Modo tiles + sprites (320×240, 192 patrones)

| Estructura | Cálculo | Tamaño |
|-----------|---------|--------|
| Tilemap | 40×30 × 1 B | 1.200 B |
| Atributos | 40×30 × 1 B | 1.200 B |
| Patrones de tile | 192 × 16 B (2bpp planar) | 3.072 B |
| OAM | 64 × 4 B | 256 B |
| Patrones de sprite | 32 × 64 B (16×16 @ 2bpp) | 2.048 B |
| **Total** | | **7.776 B** |

### 5.2 Modo texto (40×30)

| Estructura | Tamaño |
|-----------|--------|
| Char map | 1.200 B |
| Atributos | 1.200 B |
| Charset | 2.048–3.072 B |
| **Total** | **~4.400–5.500 B** |

Comparte el char map con el tilemap y el charset con el tileset.

### 5.3 Modo bitmap

| Estructura | Cálculo | Tamaño |
|-----------|---------|--------|
| Framebuffer | 320×240 ÷ 8 | 9.600 B |
| Atributos | 40×30 × 1 B | 1.200 B |
| **Total** | | **10.800 B** |

✅ **Cabe**, con ~1,5 KB de margen.

### 5.4 Resumen

| Modo | Bytes | Bloques BSRAM | ¿Cabe en 6 (12,3 KB)? |
|------|-------|---------------|----------------------|
| Tiles + sprites | 7.776 | 4 | ✅ holgado |
| Texto | ~5.500 | 3 | ✅ |
| Bitmap 320×240 | 10.800 | 6 | ✅ |

Los modos son excluyentes y **comparten los mismos bloques físicos**.

**Margen del modo principal (tiles):** 12.288 − 7.776 = **4.512 B (37%)**, suficiente
para un doble tilemap (scroll sin tearing) o para un bankswitch de tilesets.

---

## 6. Presupuesto de LUTs (estimado)

| Componente | LUTs estimadas |
|-----------|----------------|
| Timing + escalado + paleta + TMDS | 900–1.500 |
| Modo tiles (fetch + sprites) | 850–1.400 |
| Modo texto | 50–150 |
| Modo bitmap | 250–400 |
| Mux de modo + control | 50–100 |
| Sincronización VRAM (doble flop) | 50–100 |
| **Total estimado** | **~2.150–3.650** |
| **Disponible** | **5.317** |

Margen estimado: **~1.700–3.100 LUTs**.

> **Nota:** estas cifras son estimaciones. Deben corregirse sintetizando entre fases
> (§9 del plan).

---

## 7. Requerimientos no funcionales

### RNF-01 — Sincronización entre dominios de reloj

**Crítico.** El CPU corre a 6,75 MHz y el motor de vídeo a 25,175 MHz.
Las señales de escritura a VRAM **deben** sincronizarse con doble flop al dominio
del pixel clock.

> Esto es un bug conocido en el diseño actual: en `sid_wrapper.vhd` el decodificador
> de dirección del SID (`addr_match`) es combinacional y sin sincronizar, y `sid_cs`
> puede activarse en lecturas. En vídeo, el mismo error produciría tiles corruptos
> intermitentes. **No repetirlo.**

### RNF-02 — BSRAM Pseudo Dual Port

El patrón de acceso es **1 escritor (CPU) + 1 lector (motor)**, que es exactamente
el caso que la PDP del GW1NR-9 soporta de forma nativa. **No se requiere True Dual Port.**

- Direcciones distintas: acceso simultáneo permitido.
- Misma dirección: usar el bypass de escritura o evitar la colisión.
- Escritura y lectura simultánea en la misma celda: sincronizar o escribir en vblank.

### RNF-03 — No eliminar ningún módulo existente

La CPU, RAM, ROM, SID, GPIO, I2C, UART, Timer y SPI deben permanecer funcionales.

### RNF-04 — PTH/hardware

El ruido de audio es el riesgo principal de hardware (ver §9).

---

## 8. Espacio de direcciones del CPU

### 8.1 Estado actual

| Rango | Tamaño | Estado |
|-------|--------|--------|
| `$0000–$3FFF` | 16 KB | RAM (BSRAM) |
| **`$4000–$7FFF`** | **16 KB** | **LIBRE — sin decodificar** |
| `$8000–$BFFF` | 16 KB | ROM (programa) |
| `$C000–$C0FF` | ~64 B | I/O |
| `$D400–$D41F` | 32 B | SID |
| `$D800–$D87F` | 128 B | **Vídeo (nuevo)** |

> **Hallazgo:** `$4000–$7FFF` no está conectado a nada. En `Data_bus_mux.vhd:64-86`,
> las lecturas solo cubren RAM, ROM, `$C000` y `$C001`; todo lo demás devuelve
> `"ZZZZZZZZ"` (bus flotante). Como RAM física, solo existen los 16 KB de
> `$0000–$3FFF`.

### 8.2 Requerimiento

Mapear la **VRAM en `$4000–$7FFF`**. Esto resuelve simultáneamente:

1. El CPU accede a los gráficos sin registros indirectos (menos ciclos).
2. No se requiere BSRAM adicional para "RAM de juego".
3. El hueco muerto de `$4000–$7FFF` deja de existir.

---

## 9. Riesgos identificados

### R-01 — Ruido de audio con TMDS

Los pines TMDS (68–75) están **físicamente adyacentes** a los pins de audio (76–77):

```
  75 ── hdmi_tmds_c2_p   |   76 ── audio_out_l   |   77 ── audio_out_r
```

El TMDS conmuta a **135 MHz** (5 × 27 MHz), no a 252 MHz como se estimó inicialmente
(el diseño final usa 720×480@60 con pixel clock de 27 MHz, no 640×480 a 25,175).

**Estado:** el vídeo funciona (barras de color visibles). **Pendiente de evaluar** el
efecto sobre el audio del SID con el TMDS activo.

**Mitigaciones disponibles:**
- Mejorar el filtro RC (añadir segundo polo).
- Reducir `DRIVE` a 4 mA en `audio_out_l`/`audio_out_r`.
- Desacople del riel del banco 1.

### R-02 — Desajuste entre `.ipc` y `.vhd` de la PLL (cosmético)

`src/gowin_pll_81mhz/gowin_pll_81mhz.vhd` fue generado con herramienta **1.9.9.02**,
mientras el resto del proyecto usa **1.9.12**. El sintetizador emite un warning:

```
WARN (EX0210): Invalid VCO frequency to instance "pll_inst",
  suitable range is from 400MHz to 1200MHz
```

**Estado: el diseño funciona correctamente.** Verificado contra el netlist sintetizado
(`impl/gwsynthesis/6502_board_v3.vg`), que aplica los genéricos reales:

```
defparam pll_inst_s4.FBDIV_SEL=23;
defparam pll_inst_s4.IDIV_SEL=0;
defparam pll_inst_s4.ODIV_SEL=8;
```

Resultado: VCO = 648 MHz, CLKOUT = **81 MHz** — ambos dentro de rango. El warning es
un **falso positivo** de validación de la versión 1.9.12 (usa una fórmula interna
distinta a la que aplica).

**Origen del desajuste:** el `.vhd` fue editado a mano y sus genéricos (`FBDIV_SEL=23`,
`ODIV_SEL=8`) no coinciden con el `.ipc` que lo generó (`FBCLK_DIVIDE=3`,
`CLKOUT_DIVIDE=4`, que darían 27 MHz).

**Riesgo real (bajo):** si alguien regenerara la IP desde la GUI de Gowin, obtendría
27 MHz en vez de 81 y el audio del SID se rompería sin causa aparente.

**Acción:** documentar. No es necesario regenerar el IP mientras el flujo de Gowin
compile y el bitstream funcione. Opcionalmente, sincronizar el `.ipc`
(`CLKOUT_DIVIDE=8`, `FBCLK_DIVIDE=23`) para eliminar el warning y el riesgo futuro.

### R-03 — BSRAM ajustada en modo bitmap

El modo bitmap consume 10.800 B de 12 KB libres. Entra, pero con solo ~1,5 KB de margen.
Es el modo con menor holgura.

### R-04 — GCLK_PIN saturado (NO es bloqueante)

`GCLK_PIN | 3/3 | 100%`. Los tres pines con capacidad de reloj global están ocupados:

| Pin | Señal | Uso |
|-----|-------|-----|
| 52 | `CLOCK_27_i` | Cristal de 27 MHz (uso legítimo) |
| 4 | `reset_in` | Reset global |
| 36 | `spi_sclk` | **Salida** de datos con fanout |

**No es un bloqueante:** los relojes de vídeo **nacen de la PLL libre**, no de pines
externos, y usan **redes globales PRIMARY/LW** (4 y 3 libres respectivamente), que son
un recurso independiente del GCLK_PIN.

### R-05 — Contención de bus CPU ↔ motor

Ambos acceden a la misma BSRAM. Mitigación: Pseudo Dual Port + sincronización, y
preferentemente escribir durante vblank.

---

## 10. Fuera de alcance (por ahora)

- Rotación/escalado **por píxel** con matrices (inviable: 4 multiplicaciones por píxel
  contra 4 DSP físicos a 25 MHz).
- Sprite engine completo estilo Atari Lynx (requeriría doble buffer de ~19 KB,
  no cabe en BSRAM).
- Framebuffer de color 2bpp a 320×240 (19.200 B, no cabe).
- Más de 256 patrones simultáneos (requeriría 8 KB de patrones).
- Rotación de **tiles** en tiempo real (solo precalculado en software).

---

## 11. Glosario

| Término | Significado |
|---------|-------------|
| **Tile** | Bloque de 8×8 píxeles |
| **Patrón** | Los píxeles de un tile (16 B a 2bpp) |
| **Celda** | Posición en el tilemap (1 B de índice) |
| **Tilemap** | Mapa de 40×30 índices |
| **Atributo** | Byte por celda: paleta + flips + prioridad |
| **OAM** | Tabla de sprites (Object Attribute Memory) |
| **bpp** | Bits por píxel |
| **PDP** | Pseudo Dual Port (BSRAM) |
| **DDA** | Digital Differential Analyzer (acumulación en vez de multiplicación) |
| **BSRAM** | Block RAM del FPGA |
