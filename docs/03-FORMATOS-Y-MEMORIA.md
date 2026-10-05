# Módulo de Vídeo — Especificación del Byte de Atributo y Mapa de Memoria

**Proyecto:** fpga-6502-16k
**Documento:** Especificación detallada de formatos
**Referencia:** `docs/01-REQUERIMIENTOS.md`

---

## 1. Formatos de datos del fondo

### 1.1 Tile (8×8, 2bpp planar)

Un tile de 8×8 a 2bpp ocupa **16 bytes**: dos planos de 8 bytes cada uno.

```
Byte 0–7:   Plano 0 (bit 0 del color de cada píxel)
Byte 8–15:  Plano 1 (bit 1 del color de cada píxel)
```

El color de cada píxel se obtiene combinando los bits de ambos planos:

| Plano 1 | Plano 0 | Índice de color |
|---------|---------|-----------------|
| 0 | 0 | **0** (fondo / transparente en sprite) |
| 0 | 1 | **1** |
| 1 | 0 | **2** |
| 1 | 1 | **3** |

**Ventaja del planar:** el shifter lee **2 bytes** y produce 8 píxeles de 8 bits.
Es más eficiente que el formato chunky (que requeriría 4 lecturas).

### 1.2 Ejemplo de construcción

Diseño visual deseado (`0`=fondo, `1`..`3`=colores):

```
  0 0 1 1 1 1 0 0
  0 1 2 2 2 2 1 0
  1 2 3 3 3 3 2 1
  1 2 3 3 3 3 2 1
  1 2 2 2 2 2 2 1
  0 1 2 2 2 2 1 0
  0 0 1 1 1 1 0 0
  0 0 0 0 0 0 0 0
```

Se descompone en dos planos:

```
Fila 0:  00111100
   Plano 0 (bit 0):  0 0 1 1 1 1 0 0  → 00111100
   Plano 1 (bit 1):  0 0 0 0 0 0 0 0  → 00000000
   (color 0 = 00, color 1 = 01, color 2 = 10, color 3 = 11)
```

Cada fila se descompone en un byte de cada plano. El patrón completo son
8 bytes de plano 0 seguidos de 8 bytes de plano 1.

### 1.3 Presupuesto

| Formato | Bytes por tile | 256 tiles |
|---------|---------------|-----------|
| 1bpp | 8 | 2.048 B |
| **2bpp (elegido)** | **16** | **4.096 B** |
| 3bpp | 24 | 6.144 B |
| 4bpp | 32 | 8.192 B |

---

## 2. Byte de atributo del fondo

**Un byte por celda** del tilemap (40×30 = 1.200 bytes).

```
   bit 7     bit 6     bit 5     bit 4   bit 3   bit 2   bit 1   bit 0
 ┌─────────┬─────────┬─────────┬───────┬───────┬───────┬───────┬───────┐
 │  PRIO   │ FLIP_Y  │ FLIP_X  │             PALETA (4 bits)           │
 └─────────┴─────────┴─────────┴───────┴───────┴───────┴───────┴───────┘
```

| Bits | Campo | Valores | Efecto |
|------|-------|---------|--------|
| 7 | `PRIO` | 0 / 1 | **1** = delante de los sprites; **0** = detrás |
| 6 | `FLIP_Y` | 0 / 1 | Volteo vertical (invertir orden de filas) |
| 5 | `FLIP_X` | 0 / 1 | Volteo horizontal (invertir bits del byte) |
| **4** | **`SOLIDO`** | 0 / 1 | **1** = celda sólida (colisión sprite↔tile, Fase 10) |
| 3:0 | `PALETA` | 0–15 | Índice de paleta |

> **Nota de diseño:** el bit 4 se usa ahora como flag `SOLIDO` para la colisión
> sprite↔tile (Fase 10). La paleta de fondo queda en 16 valores (bits 3:0).

### 2.0 Colisión sprite↔tile (Fase 10)

El bit 4 del atributo (`SOLIDO`) habilita la detección de colisión: una vez por
frame, el hardware recorre los 32 sprites y, para el **centro** de cada uno, lee
el atributo de su celda. Si el bit 4 = 1, el sprite “toca” un tile sólido.
El resultado global es el bit 5 de `$D803` (`SOLID_HIT`).

### 2.1 Cómo el motor aplica el atributo

```
 1. Lee el índice de tile de la celda       → tilemap[celda]
 2. Lee el atributo de la celda             → atrib[celda]
 3. Lee el patrón (2 planos)                → patrones[tile]
 4. Aplica FLIP_X (invertir bits)           si bit 5
 5. Selecciona fila con FLIP_Y              si bit 6
 6. Por cada píxel:
       índice = (plano1_bit, plano0_bit)    → 0..3
       color  = PALETA_FONDO[atrib.PALETA][índice]
 7. Mezcla con sprites según PRIO
```

### 2.2 Efecto multiplicador

| Factor | Valores | Origen |
|--------|---------|--------|
| Patrones | 256 | Tileset |
| Orientaciones | 4 | FLIP_X + FLIP_Y |
| Paletas | 16 | Campo PALETA |
| **Combinaciones** | **16.384** | |

Esto permite que **el mismo patrón repetido en 900 celdas se vea de 16 maneras
distintas** cambiando solo el byte de atributo de cada celda.

---

## 3. Byte de flags de sprite (OAM) — IMPLEMENTADO

OAM de **32 entradas** × **5 bytes**, en **registros** (no BSRAM):

| Offset | Campo | Descripción |
|--------|-------|-------------|
| +0 | `X` | Coordenada X (0–255) |
| +1 | `Y` | Coordenada Y (0–255); **Y >= 248 = sprite deshabilitado** |
| +2 | `TILE` | Índice de patrón de sprite (0–63) |
| +3 | `FLAGS` | Ver abajo |
| +4 | `COLL_POINT` | Punto de colisión sprite↔tile (dx, dy) — ver §3.3 |

Dirección de un campo en el OAM (escritura indirecta): **`sprite * 5 + offset`**
(sprite 0..31, offset 0..4 ⇒ byte 0..159).

```
   FLAGS
   bit 7     bit 6     bit 5   bit 4   bit 3   bit 2   bit 1   bit 0
 ┌─────────┬─────────┬───────┬───────┬───────┬───────┬───────┬───────┐
 │ FLIP_Y  │ FLIP_X  │  PRIO │SCALE2X│        PALETA (4 bits)          │
 └─────────┴─────────┴───────┴───────┴───────┴───────┴───────┴───────┘
```

| Campo | Bits | Estado | Efecto |
|-------|------|--------|--------|
| `FLIP_Y` | 7 | ✅ | Volteo vertical |
| `FLIP_X` | 6 | ✅ | Volteo horizontal |
| `PRIO` | 5 | ✅ | **1** = sprite DETRÁS del fondo; 0 = delante |
| `SCALE2X` | 4 | ✅ | **1** = sprite al doble (16×16 en pantalla) |
| `PALETA` | 3:0 | ✅ (usa 1:0) | Paleta de sprite (4 disponibles) |

### 3.1 Convenciones de sprite (implementadas)

| Aspecto | Convención |
|---------|-----------|
| Color 0 | **Transparente** |
| Tamaño base | **8×8** (un patrón) |
| Objeto grande | 16×16 = **4 sprites de 8×8** en rejilla 2×2 |
| Objeto a 2× | 16×16 = 4 sprites con `SCALE2X`, separados **+16** px |
| Patrones | 64 disponibles (banco `spr_arr`, 512×16 = 1 bloque BSRAM) |
| Sprites en pantalla | 32 en OAM; **8 por línea** (line buffer) |
| Prioridad | Menor índice de OAM gana entre sprites con el mismo PRIO |

### 3.2 Registro STATUS ($D803, lectura)

| Bit | Campo | Descripción |
|-----|-------|-------------|
| 7 | `VBLANK` | 1 = en vblank (seguro escribir VRAM) |
| 6 | `SPRITE_OVERFLOW` | 1 = más de 8 sprites en una línea |
| **5** | **`SOLID_HIT`** | 1 = algún sprite tocó un tile sólido (colisión, Fase 10/11) |
| **4** | **`VIDEO_READY`** | **1 = inicialización de la VRAM terminada** |
| 3:0 | — | reservado |

> **IMPORTANTE:** el CPU debe esperar `VIDEO_READY=1` antes de escribir la VRAM.
> Durante la init, el puerto A lo controla el hardware y las escrituras del CPU
> se **descartan**. Ver `04-MODO-TEXTO.md` §4.

### 3.3 COLL_POINT — punto de colisión configurable (Fase 11)

El byte **+4** del sprite define **qué píxel del sprite** se usa para la colisión
sprite↔tile. Codificación (**offset libre 0-7 en cada eje**):

```
   bit 7   bit 6   bit 5   bit 4   bit 3   bit 2   bit 1   bit 0
 ┌───────┬───────┬───────┬───────────────────────┬───────────────┐
 │   -   │   -   │     dy (0..7)             │    dx (0..7)   │
 └───────┴───────┴───────────────────────┴───────────────┘
```

El punto de colisión (en píxeles de pantalla) es **`(X + dx, Y + dy)`**.

| Punto deseado | dx, dy | Byte `COLL_POINT` |
|---------------|--------|-------------------|
| centro | 4,4 | `$24` |
| pie (abajo-centro) | 4,7 | `$3C` |
| cabeza (arriba-centro) | 4,0 | `$04` |
| borde izquierdo | 0,4 | `$20` |
| borde derecho | 7,4 | `$27` |
| esquina sup-izq | 0,0 | `$00` |
| esquina inf-der | 7,7 | `$3F` |

**Cómo funciona la detección:** una vez por frame (blanking vertical), el hardware
recorre los 32 sprites, evalúa `(X+dx, Y+dy)`, mira la celda de 8×8 correspondiente y
lee el bit 4 (`SOLIDO`) de su atributo. Si está a 1, activa `SOLID_HIT`.

**Uso típico (juego):**

```asm
; Cada frame, tras decidir la direccion, ajustar el punto al borde que avanza:
;   si va a la derecha -> borde derecho (dx=7)
;   si va a la izquierda -> borde izquierdo (dx=0)
; y al detectar SOLID_HIT, invertir direccion (+ push-out de 1 px si se desea).
```

> **Latencia:** 1 frame (la colisión se recalcula en el blanking). El sprite puede
> "pasarse" ~1 px al chocar; se compensa en el juego con un push-out de 1 px.

---

## 4. Paleta

### 4.1 Estructura

```
Paletas: 32 entradas × 12 bits (RGB 4-4-4), en registros (escribibles por CPU)
         = 48 bytes; no consume BSRAM

  ├── Paletas de FONDO:  4 paletas × 4 colores = 16 entradas (pal_bg)
  └── Paletas de SPRITE: 4 paletas × 4 colores = 16 entradas (pal_spr)
```

> El CPU las reescribe por el puerto indirecto `$D813-$D815` (auto-incremento).
> Entrada = `paleta*4 + color` dentro de su banco (0-15 fondo, 16-31 sprite).

### 4.2 Bancos separados (decisión de diseño)

**Fondo y sprites usan bancos de paleta independientes.** Motivos:

1. **Transparencia:** el color 0 es transparente en **ambos** bancos; tener bancos
   separados permite que un sprite reutilice el mismo patrón con otra paleta sin
   afectar al fondo.
2. **Reutilización:** un mismo patrón de sprite con distinta paleta da variedad
   sin gastar patrones ("enemigo azul / enemigo rojo").
3. **Coste:** son registros, no BSRAM.

### 4.3 Color de fondo global

**BG_COLOR = la entrada 15 de la paleta de fondo** (`pal_bg(15)`). Cambiar el "cielo"
de un nivel entero cuesta dos escrituras (`$D813=15`, `$D814`, `$D815`). Ver manual §4.3.

> Nota: la primera idea era un registro `BG_COLOR` dedicado; se implemento como la
> entrada 15 de la paleta para no gastar FFs (el registro propio no cabia).

### 4.3.1 Paletas de fondo actuales (IMPLEMENTADAS)

La `PALETTE` de fondo tiene **4 paletas de 4 colores** (valores por defecto;
reescribibles por CPU):

| Paleta | color0 | color1 | color2 | color3 |
|--------|--------|--------|--------|--------|
| 0 | transparente | azul (`$00A`) | cian (`$0CF`) | blanco |
| 1 | transparente | marrón (`$A62`) | gris (`$AAA`) | blanco |
| 2 | transparente | verde (`$0A0`) | verde oscuro (`$060`) | verde |
| 3 | transparente | gris (`$888`) | marrón (`$840`) | **BG_COLOR** (entrada 15) |

La fuente se expande con **color 3**, así que el color 3 de cada paleta define el
color del texto. **El color 0 es siempre transparente** (en todas las paletas). El
color de la celda se elige con los bits 1:0 de `attr_arr`.

Detalle completo y paletas de sprite: manual `07-MANUAL-PROGRAMACION.md` §4.1-4.4.

### 4.4 Colores simultáneos

| Nivel | Colores |
|-------|---------|
| Por patrón (2bpp) | 4 |
| Por celda (4 paletas de fondo) | 4 × 4 = 16 |
| Sprites (4 paletas propias) | 4 × 4 = 16 |
| **Simultáneos en pantalla** | **hasta 32** (16 fondo + 16 sprite) |
| Elegibles (color 12 bits) | 4.096 |

Comparación: NES = 25, C64 = 16, Master System = 32.

---

## 5. Mapa de memoria

### 5.1 Espacio de direcciones del CPU

| Rango | Tamaño | Contenido | Estado |
|-------|--------|-----------|--------|
| `$0000–$3FFF` | 16 KB | RAM (BSRAM) | Existente |
| **`$4000–$7FFF`** | **16 KB** | **VRAM** | **NUEVO** |
| `$8000–$BFFF` | 16 KB | ROM (programa) | Existente |
| `$C000–$C003` | 4 B | GPIO | Existente |
| `$C010–$C017` | 8 B | I2C | Existente |
| `$C020–$C023` | 4 B | UART | Existente |
| `$C030–$C03F` | 16 B | Timer | Existente |
| `$C040–$C047` | 8 B | SPI | Existente |
| `$D400–$D41F` | 32 B | SID | Existente |
| **`$D800–$D87F`** | **128 B** | **Vídeo** | **NUEVO** |
| `$FFFA–$FFFF` | 6 B | Vectores | Existente |

### 5.2 Registros de vídeo (IMPLEMENTADOS)

| Dirección | Nombre | R/W | Descripción |
|-----------|--------|-----|-------------|
| `$D800` | `VID_ADDR_LO` | W | Dirección VRAM, byte bajo (8 bits) |
| `$D801` | `VID_ADDR_HI` | W | Area (7:6) + pat_hi (5) + dir alta (2:0) |
| `$D802` | `VID_DATA` | W | Dato; **escribirlo dispara la escritura** |
| `$D803` | `STATUS` | R | READY (4) + VBLANK (7) + OVERFLOW (6) |
| `$D804` | `SCROLL_X_LO` | W | Scroll X (banda media), byte bajo |
| `$D805` | `SCROLL_X_HI` | W | Scroll X, byte alto (bits 2:0) |
| `$D806` | `SCROLL_Y_LO` | W | Scroll Y (banda media), byte bajo |
| `$D807` | `SCROLL_Y_HI` | W | Scroll Y, byte alto (bits 2:0) |
| `$D808` | `MAP_STRIDE` | W | Ancho del mapa en celdas (por defecto **64**) |

### 5.3 Registros de split de raster (Fase 8, IMPLEMENTADOS)

Hasta 3 bandas verticales, cada una con scroll independiente:

| Dirección | Nombre | R/W | Descripción |
|-----------|--------|-----|-------------|
| `$D809` | `RASTER_LINE0` | W | Fin de la banda SUPERIOR (línea lógica 0..239). `$FF` = sin banda top |
| `$D80A` | `BAND2_X_LO` | W | Scroll X de la banda superior, byte bajo |
| `$D80B` | `BAND2_X_HI` | W | Scroll X de la banda superior, bits 2:0 |
| `$D80C` | `BAND2_Y_LO` | W | Scroll Y de la banda superior, byte bajo |
| `$D80D` | `BAND2_Y_HI` | W | Scroll Y de la banda superior, bits 2:0 |
| `$D80E` | `RASTER_LINE1` | W | Fin de la banda MEDIA. `$FF` = sin banda bottom |
| `$D80F` | `BAND3_X_LO` | W | Scroll X de la banda inferior, byte bajo |
| `$D810` | `BAND3_X_HI` | W | Scroll X de la banda inferior, bits 2:0 |
| `$D811` | `BAND3_Y_LO` | W | Scroll Y de la banda inferior, byte bajo |
| `$D812` | `BAND3_Y_HI` | W | Scroll Y de la banda inferior, bits 2:0 |

La banda MEDIA usa el scroll normal (`$D804`/`$D806`). Si `RASTER_LINE0 = $FF`,
no hay banda superior y todo arranca en la banda media (equivale a 2 bandas).

> **Desfase de fila 0:** el pipeline presenta la fila 0 del tilemap corrida una
> fila arriba (artefacto del prefetch). Para un HUD superior, reserva la fila 0
> como margen y dibuja en las filas 1-2 (ver `02-PLAN-IMPLEMENTACION.md`, Fase 8).

#### Encoding de `$D801`

| bits 7:6 (area) | bit 5 (pat_hi) | Destino |
|-----------------|----------------|---------|
| `00` | - | tilemap |
| `01` | - | atributos |
| `10` | 0 / 1 | patrón de fondo (plano 0 / plano 1) |
| `11` + bit3=0 | - | OAM (byte 0..127) |
| `11` + bit3=1 | 0 / 1 | patrón de sprite (plano 0 / plano 1) |

> **Nota histórica:** el plan original proponía un mapeo lineal `$4000-$7FFF`. Se
> implementó en su lugar un **puerto indirecto** (`$D800-$D802`) por simplicidad del
> decodificador y para evitar el conflicto `EX3794` de dos relojes en la misma BSRAM.
> El puerto indirecto usa un **toggle sincronizado por doble flop** al dominio de vídeo
> (mismo patrón que el SID), respetando RNF-01.

### 5.4 Registro `STATUS` (`$D803`) — IMPLEMENTADO

| Bits | Campo | Descripción |
|------|-------|-------------|
| 7 | `VBLANK` | 1 = en vblank (seguro escribir VRAM) |
| 6 | `SPRITE_OVERFLOW` | Más de 8 sprites en una línea (se recalcula por línea) |
| 5 | **`SOLID_HIT`** | 1 = algún sprite tocó un tile sólido (colisión sprite↔tile, Fase 10) |
| **4** | **`VIDEO_READY`** | 1 = inicialización de la VRAM terminada |
| 3:0 | — | reservado |

---

## 6. Layout de la VRAM (IMPLEMENTADO)

Arreglos BSRAM direccionados por separado. La VRAM son **6 bloques**:

| Arreglo | Tamaño del arreglo | Posiciones usadas | BSRAM |
|---------|--------------------|-------------------|-------|
| Tilemap | 2048×8 | 2048 (64×32) | 1 |
| Atributos | 2048×8 | 2048 (64×32) | 1 |
| Patrones de fondo | 2048×16 | 1536 + 768 (fuente) | 2 |
| Patrones de sprite | 512×16 | 512 (64×8) | 1 |
| **Fuente (`font_arr`)** | **1024×9** | **768 (96×8), 1bpp** | **1** |
| **Total** | | | **6** |

> El **OAM NO está en BSRAM**: son 32 sprites × 4 bytes en registros.

Presupuesto medido del diseño completo: **26/26 BSRAM** (8 del stack de la CPU, 12 del
ROM, 6 de la VRAM). **No queda ningún bloque libre.**

### 6.0 Fuente de caracteres (`font_arr`)

| Propiedad | Valor |
|-----------|-------|
| Formato | 1bpp (1 byte = fila de 8 píxeles, bit 7 = izquierda) |
| Caracteres | 96 (`$20`–`$7F`) |
| Dirección | `char*8 + fila`, con `char = ascii - $20` |
| Destino tras expansión | `pat_arr[ascii*8 + fila]` (2bpp) → `tile = ASCII` |

Ver [`04-MODO-TEXTO.md`](04-MODO-TEXTO.md).

### 6.1 Direccionamiento interno del motor

El mapa es de **64×32 celdas** (2.048, el máximo de `tile_arr`), mayor que la
pantalla visible (40×30). Esto habilita **scroll horizontal y vertical** sobre
contenido extra. El stride 64 es **potencia de 2**, así que `y_cell * 64` es una
concatenación de bits (sin multiplicador, ~0 LUTs).

```
cell_addr = (y_cell(4:0) & x_cell(5:0))    (0..2047)   -> tilemap y atributos (mapa 64x32)
              con x_cell = (x_world/8) mod 64
                  y_cell = (y_world/8) mod 32
pat_addr  = tile * 8 + fila                (0..2047)   -> patrón de FONDO (16 bits)
spr_addr  = sprite_pat * 8 + fila          (0..511)    -> patrón de SPRITE (16 bits)
oam_byte = sprite * 5 + campo              (0..159)    -> X, Y, TILE, FLAGS, COLL_POINT
```

> **Banco de sprites:** 512 palabras = **64 patrones** (0..63), banco aparte del de
> fondo. El campo TILE del OAM es de 6 bits (0..63).

> **Ojo con el mundo vacío:** al ser el mapa más grande que la pantalla, el
> software debe **rellenar todas las celdas** (64×32) que pueda alcanzar el scroll.
> Las columnas 40–63 y las filas 30–31 también se muestran al desplazarse; si
> quedan sin escribir, aparece basura de la init.

### 6.2 Distribución de una palabra de patrón (16 bits)

```
  bit 15             bit 8   bit 7             bit 0
 ┌─────────────────────────┬────────────────────────┐
 │  Plano 1 (color bit 1)  │  Plano 0 (color bit 0) │
 └─────────────────────────┴────────────────────────┘
```

Leer el "par de planos" de una fila en **una sola** lectura de BSRAM (en lugar de dos
encadenadas) elimina la latencia acumulada. Es la decisión que hace que el pipeline
tenga latencia fija y sea imposible de desalinear. Coste: 1 bloque BSRAM extra para los
patrones (ancho de 16 bits).

### 6.3 Propuesta de reparto lineal para el CPU (Fase 4)

El CPU solo tiene un puerto de escritura, así que puede verse la VRAM como un espacio
lineal trasladado a `$4000–$7FFF`, con la misma distribución de §6.

| Offset | Rango CPU | Tamaño | Contenido |
|--------|-----------|--------|-----------|
| `$0000` | `$4000` | 2.048 B | Tilemap (1.200 usados) |
| `$0800` | `$4800` | 2.048 B | Atributos (1.200 usados) |
| `$1000` | `$5000` | 4.096 B | Patrones (3.072 usados) |
| `$2000` | `$6000` | ... | Libre |

> **Nota:** los límites de 2 KB coinciden exactamente con los bloques BSRAM, por lo que
> el decodificador del CPU se reduce a **mirar los bits de dirección**:
> `$4000–$47FF` → tilemap, `$4800–$4FFF` → atributos, `$5000–$5FFF` → patrones.

---

## 7. Ejemplos de uso desde el 6502

### 7.1 Escribir una celda del tilemap

```asm
; dibujar un tile en la celda (col=10, fila=5)
; offset = fila*40 + col = 5*40 + 10 = 210 ($D2)
    LDA #$D2
    STA $D800              ; VRAM_ADDR_LO
    LDA #$40               ; base $4000 -> byte alto = $40
    STA $D801              ; VRAM_ADDR_HI
    LDA #TILE_ARBOL
    STA $D802              ; escribe el índice
```

### 7.2 Rellenar todo el fondo con un patrón

```asm
; llenar las 1200 celdas con el patrón 5
    LDA #$00 : STA $D800   ; dirección base
    LDA #$40 : STA $D801   ; $4000
    LDX #$00
    LDA #TILE_AGUA         ; valor a repetir
.fill_lo:
    STA $D802              ; autoincrementa
    INX : BNE .fill_lo
    LDX #$00
.fill_hi:                  ; 1200 = 4*256 + 176
    STA $D802
    INX : CPX #176
    BNE .fill_hi
```

### 7.3 Mover un sprite

```asm
    LDA player_x : STA $D810   ; OAM sprite 0, X
    LDA player_y : STA $D811   ; OAM sprite 0, Y
    LDA #SPR_PLAYER : STA $D812
    LDA #%00000000 : STA $D813 ; flags
```

### 7.4 Esperar vblank

```asm
.wait_vblank:
    LDA $D806
    AND #%10000000
    BEQ .wait_vblank
    RTS
```

### 7.5 Definir un color de paleta

```asm
; paleta 0, color 1 = RGB 4-4-4 (naranja: R=$F, G=$8, B=$0)
    LDA #$F0 : STA $D830       ; byte alto (R,G)
    LDA #$08 : STA $D831       ; byte bajo (B, ...)
```

### 7.6 Animación de tile (método 1, reescritura parcial)

```asm
; solo cambiar las filas 2-5 del patrón #40 (ahorra la mitad de escrituras)
    LDA #<(PATRON_40 + 2)
    STA $D800
    LDA #>(PATRON_40 + 2)
    STA $D801
    LDY #$00
.loop:
    LDA frame_data,Y
    STA $D802
    INY : CPY #$04
    BNE .loop
```

### 7.7 Modo texto: imprimir un carácter (Fase 7)

```asm
; A = codigo ASCII; CUR = celda del cursor (fila*40 + columna).
; Requiere: esperar VIDEO_READY ($D803 bit 4) al menos una vez tras el arranque.
put_char:
    STA TMP
    LDA CUR_LO
    STA $D800         ; direccion lo (area 00 = tilemap)
    LDA CUR_HI
    STA $D801
    LDA TMP
    STA $D802         ; tile = ASCII -> glifo en pantalla
    INC CUR_LO
    BNE pc_n
    INC CUR_HI
pc_n:
    RTS
```

El fondo por defecto ya es negro (tilemap lleno de `$20` en la init). No hace
falta definir patrones al imprimir: la fuente ya está expandida en `pat_arr`.

### 7.8 Esperar a que el vídeo esté listo

```asm
wait_ready:
    LDA $D803
    AND #%00010000     ; VIDEO_READY (bit 4)
    BEQ wait_ready
```

Obligatorio antes de la primera escritura a la VRAM: durante la init, el puerto A
lo tiene el hardware y las escrituras del CPU se descartan.

---

## 8. Pendiente de definir

| Tema | Estado |
|------|--------|
| Reparto exacto de bits ángulo/escala en OAM | Provisional (§3) |
| Mapa definitivo de paleta (no cabe en `$D800–$D87F`) | Provisional (§5.2) |
| Alineación del layout VRAM a bloques BSRAM | ✅ Resuelto (§6.3) |
| Registro de "relleno" (escribir N veces un valor) | Opcional |
| Tabla de slots de animación | Opcional (fase 9+) |
| Modo texto: 40 vs. 80 columnas | ✅ **40 columnas** (implementado) |
| Color de texto por celda | ⏳ pendiente (§7 de 04-MODO-TEXTO) |
| Cursor / scroll de texto | ⏳ pendiente (software) |
