# Manual de Programación del Core de Vídeo

**Plataforma:** computador 6502 sobre Sipeed Tang Nano 9K (Gowin GW1NR‑9)
**Salida:** HDMI, 320×240 lógicos (720×480 físicos, escalado 2×), 60 Hz
**Modelo:** coprocesador gráfico estilo NES/VIC‑II (tiles + sprites, **sin framebuffer**)
**Público:** programadores y asistentes de IA que escriban juegos en ensamblador 6502.

> Este manual es **autocontenido**: con él puedes escribir un juego sin leer el VHDL.
> Los ejemplos están en ensamblador (ca65 / cc65).

---

## Índice

1. [Visión general y modelo mental](#1-visión-general-y-modelo-mental)
2. [Mapa de memoria](#2-mapa-de-memoria)
3. [Resolución, coordenadas y unidades](#3-resolución-coordenadas-y-unidades)
4. [Colores y paletas](#4-colores-y-paletas)
5. [El fondo: tiles y tilemap](#5-el-fondo-tiles-y-tilemap)
6. [Sprites (OAM)](#6-sprites-oam)
7. [Scroll](#7-scroll)
8. [Split de raster (bandas / HUD)](#8-split-de-raster-bandas--hud)
9. [Modo texto](#9-modo-texto)
10. [Colisión sprite↔tile (sólidos)](#10-colisión-spritetile-sólidos)
11. [STATUS: VBLANK y sincronización](#11-status-vblank-y-sincronización)
12. [Recetas completas](#12-recetas-completas)
13. [Limitaciones y buenas prácticas](#13-limitaciones-y-buenas-prácticas)
14. [Esqueleto de juego](#14-esqueleto-de-juego)

---

## 1. Visión general y modelo mental

El vídeo es un **coprocesador**. El CPU (6502) **no dibuja píxeles**: escribe
**memoria de vídeo** (VRAM) y **registros**; el hardware genera la imagen solo.

Tres capas, de atrás a delante:

```
   ┌─────────────────────────────────────────┐
   │ MARGEN (barra azul, 40 px a cada lado)   │  ← no dibujable
   ├─────────────────────────────────────────┤
   │ FONDO  (tiles 8×8 desde el tilemap)      │  ← capa 1
   ├─────────────────────────────────────────┤
   │ SPRITES (8×8, con prioridad y transparencia) │ ← capa 2
   └─────────────────────────────────────────┘
```

- **Pantalla visible:** 40×30 tiles = 320×240 píxeles lógicos.
- **Mapa de fondo:** 64×32 celdas (más grande que la pantalla → scroll).
- **Tiles:** 256 patrones de 8×8, 2 bpp (4 colores c/u).
- **Sprites:** 32 en OAM, 8×8, 64 patrones, con flips, escala 2×, prioridad.
- **Color 0 de sprite** = transparente. **Color 0 del fondo** = transparente
  (se ve `BG_COLOR` o un sprite detrás).

Todo se controla por **un puerto indirecto de 3 registros** (`$D800/$D801/$D802`)
para memoria, y **registros directos** para scroll/status/bandas.

---

## 2. Mapa de memoria

### 2.1 Registros de vídeo (escritura/lectura directa)

| Dir | Nombre | R/W | Descripción |
|-----|--------|-----|-------------|
| `$D800` | `VID_ADDR_LO` | W | Dirección de VRAM, byte bajo (8 bits) |
| `$D801` | `VID_ADDR_HI` | W | Área + dirección alta (ver §2.2) |
| `$D802` | `VID_DATA` | W | Dato; **escribirlo dispara la escritura** |
| `$D803` | `STATUS` | R | VBLANK / OVERFLOW / SOLID_HIT / VIDEO_READY |
| `$D804` | `SCROLL_X_LO` | W | Scroll X (banda media), byte bajo |
| `$D805` | `SCROLL_X_HI` | W | Scroll X, bits 2:0 |
| `$D806` | `SCROLL_Y_LO` | W | Scroll Y (banda media), byte bajo |
| `$D807` | `SCROLL_Y_HI` | W | Scroll Y, bits 2:0 |
| `$D808` | `MAP_STRIDE` | W | Ancho del mapa (fijo 64; no usar) |
| `$D809` | `RASTER_LINE0` | W | Fin de banda superior. `$FF` = sin banda |
| `$D80A/$D80B` | `BAND2_X` lo/hi | W | Scroll X de la banda superior |
| `$D80C/$D80D` | `BAND2_Y` lo/hi | W | Scroll Y de la banda superior |
| `$D80E` | `RASTER_LINE1` | W | Fin de banda media. `$FF` = sin banda |
| `$D80F/$D810` | `BAND3_X` lo/hi | W | Scroll X de la banda inferior |
| `$D811/$D812` | `BAND3_Y` lo/hi | W | Scroll Y de la banda inferior |

### 2.2 Encoding de `$D801` (área + dirección alta)

`$D801` = `area(7:6)` + `pat_hi(5)` + `bit3` + `dir_alta(2:0)`

| bits 7:6 | bit 5 | bit 3 | Destino | Dirección |
|----------|-------|-------|---------|-----------|
| `00` | – | – | **tilemap** | `0..2047` |
| `01` | – | – | **atributos** (del fondo) | `0..2047` |
| `10` | 0/1 | – | **patrón de fondo** (plano 0/1) | `tile*8+fila` |
| `11` | – | 0 | **OAM** (byte de sprite) | `0..159` |
| `11` | 0/1 | 1 | **patrón de sprite** (plano 0/1) | `sprite*8+fila` |

**Patrón de fondo/sprite:** cada tile/patrón tiene **2 planos** (`pat_hi=0` → plano 0,
`pat_hi=1` → plano 1). Se escriben por separado; la palabra se forma al escribir el plano 1.

---

## 3. Resolución, coordenadas y unidades

- **Píxel lógico** = 2×2 píxeles físicos. Trabajas siempre en **320×240**.
- **Tile/celda** = 8×8 píxeles lógicos.
- **Pantalla visible:** 40 tiles de ancho × 30 de alto.
- **Mapa de fondo:** 64 tiles de ancho × 32 de alto.

```
  Eje X: 0..319 (píxeles)   |  0..39 (tiles visibles)  |  0..63 (mapa)
  Eje Y: 0..239 (píxeles)   |  0..29 (tiles visibles)  |  0..31 (mapa)
```

> **Sprites:** X es de **9 bits** (0-511) para cubrir los 320 px de ancho; Y es de
> 8 bits (0-255, sobra para 240). El bit 8 de X va en FLAGS(2). Ver §6.4.

**Dirección de celda en el tilemap:** `celda = (y_tile * 64) + x_tile`

> ⚠️ **Margen:** los 40 px de los lados (20 px por lado) son de sincronía y no se
> dibujan. El área visible de tiles es 40 de ancho, pero empieza tras el margen.
> En la práctica: la pantalla útil son **40×30 tiles**.

> ⚠️ **Desfase de la fila 0:** por el pipeline, la **fila 0 del tilemap** tiende a
> verse corrida. Para HUD arriba, **reserva la fila 0** y dibuja desde la fila 1.

---

## 4. Colores y paletas

Cada píxel es **2 bpp** → índice de color **0-3** dentro de la paleta de su celda/sprite.

### 4.1 Paletas de FONDO (4 paletas × 4 colores)

Índice = `paleta(3:2 seleccionada por el atributo) + color(1:0 del patrón)`.
En la implementación actual, `attr_arr(1:0)` selecciona una de 4 paletas:

| Paleta | color0 | color1 | color2 | color3 | Uso |
|--------|--------|--------|--------|--------|-----|
| 0 | negro | azul (`$00A`) | cian (`$0CF`) | blanco | texto / cielo |
| 1 | negro | marrón (`$A62`) | gris (`$AAA`) | blanco | terreno |
| 2 | negro | verde (`$0A0`) | verde oscuro (`$060`) | verde | vegetación |
| 3 | negro | gris (`$888`) | marrón (`$840`) | verde | texto verde |

**Color 0 del fondo = transparente** (se ve `BG_COLOR`). El **color 3** es el que usa
la fuente de texto.

### 4.2 Paletas de SPRITE (4 paletas × 4 colores, banco aparte)

| Paleta | color0 | color1 | color2 | color3 |
|--------|--------|--------|--------|--------|
| 0 | **transparente** | piel/rojizo (`$F80`) | marrón (`$840`) | negro |
| 1 | **transparente** | azul (`$00F`) | cian (`$0FF`) | blanco |
| 2 | **transparente** | magenta (`$F0F`) | rojo (`$F00`) | blanco |
| 3 | **transparente** | verde (`$0F0`) | naranja (`$F80`) | blanco |

Se selecciona con los bits 3:0 de FLAGS del sprite (se usan 1:0 → 4 paletas).

### 4.3 Color de fondo global (`BG_COLOR`)

Actual: azul cielo (`$4080C0`, RGB888). Es lo que se ve donde el fondo es color 0 y
no hay sprite.

---

## 5. El fondo: tiles y tilemap

### 5.1 Concepto

- **Patrón de tile:** los 8 bytes (×2 planos) que definen el dibujo de un tile 8×8.
- **Tilemap:** 64×32 celdas; cada celda guarda el **índice de patrón** (0-255).
- **Atributos:** 64×32 bytes; cada uno = paleta + flips + PRIO + SÓLIDO de esa celda.

El fondo se genera: por cada celda, leer `tilemap[celda]` → `pat_arr[tile]` → píxeles.

### 5.2 Escribir una celda (tilemap)

```asm
; Escribe TILE en la celda (col, fila).  celda = fila*64 + col (16 bits)
; Entrada: TILE (índice), COL, ROW
put_cell:
    JSR calc_cell          ; CUR_LO/CUR_HI = fila*64+col
    LDA CUR_LO
    STA $D800              ; addr lo
    LDA CUR_HI
    STA $D801              ; area 00 = tilemap
    LDA TILE
    STA $D802              ; dispara la escritura
    RTS

; calc_cell: CUR = ROW*64 + COL  (stride potencia de 2 -> shifts)
calc_cell:
    LDA ROW
    LSR A
    LSR A
    STA CUR_HI             ; CUR_HI = ROW >> 2
    LDA ROW
    AND #$03
    ASL A : ASL A : ASL A : ASL A : ASL A : ASL A
    STA CUR_LO             ; (ROW & 3) << 6
    LDA CUR_LO
    CLC
    ADC COL
    STA CUR_LO
    BCC cc_done
    INC CUR_HI
cc_done:
    RTS
```

### 5.3 Escribir el atributo de una celda

```asm
; Atributo: bit7 PRIO | bit6 FLIP_Y | bit5 FLIP_X | bit4 SOLIDO | bits3:0 PALETA
put_attr:                  ; A = valor del atributo
    PHA
    LDA CUR_LO
    STA $D800
    LDA CUR_HI
    ORA #$40               ; area 01 = atributos
    STA $D801
    PLA
    STA $D802
    RTS
```

### 5.4 Cargar un patrón de tile (2 planos)

Un patrón ocupa `tile*8` a `tile*8+7`; se escriben **plano 0** y **plano 1**.

```asm
; Carga 8 filas del patrón TILE.  pat0/pat1 = tablas en ROM (8 bytes c/u)
load_tile:
    LDY #0
lt_loop:
    ; plano 0: area 10, pat_hi=0
    LDA #$80               ; area 10
    STA $D801
    LDA tile_dir_lo,Y      ; = (tile*8+fila) & $FF
    STA $D800
    LDA pat0,Y
    STA $D802
    ; plano 1: area 10, pat_hi=1
    LDA #$A0               ; area 10 | pat_hi
    STA $D801
    LDA tile_dir_lo,Y
    STA $D800
    LDA pat1,Y
    STA $D802
    INY
    CPY #8
    BNE lt_loop
    RTS
```

> **2bpp planar:** el color de cada píxel = `(bit del plano1, bit del plano0)`.
> Ej.: sólo plano 0 = color 1; sólo plano 1 = color 2; ambos = color 3; ninguno = 0.

---

## 6. Sprites (OAM)

### 6.1 Estructura (5 bytes por sprite)

| Offset | Campo |
|--------|-------|
| +0 | `X` (bits 0-7 de la X de 9 bits) |
| +1 | `Y` (0-255). **Y ≥ 248 = deshabilitado** |
| +2 | `TILE` (0-63) |
| +3 | `FLAGS` (incluye el bit 8 de X) |
| +4 | `COLL_POINT` |

**FLAGS:** `bit7 FLIP_Y | bit6 FLIP_X | bit5 PRIO | bit4 SCALE2X | bit2 X_bit8 | bits1:0 PALETA`

- `PRIO=1` → sprite **detrás** del fondo (sólo se ve en huecos del fondo).
- `PRIO=0` → sprite **delante** del fondo.
- `SCALE2X=1` → sprite dibujado al doble (16×16 en pantalla).
- **`X_bit8` (bit 2)** = bit 8 de la coordenada X → permite X de **0 a 511**
  (toda la pantalla, 0-319). Ver §6.4.
- Prioridad entre sprites: **menor índice de OAM gana**.

**Dirección del byte en el OAM:** `sprite*5 + offset` (sprite 0..31 → byte 0..159).

### 6.4 Coordenada X de 9 bits

La pantalla tiene 320 px de ancho, pero el byte X del OAM es de 8 bits (0-255).
Para que un sprite llegue a la **mitad derecha** (X 256-319), la X es de **9 bits**:

- **Bits 7:0** → en el byte `X` (+0) del OAM.
- **Bit 8** → en el **bit 2 de FLAGS**.

Ejemplos:

| X deseada | byte X (+0) | FLAGS bit 2 |
|-----------|-------------|-------------|
| 4 | `$04` | 0 |
| 200 | `$C8` | 0 |
| 255 | `$FF` | 0 |
| 256 | `$00` | 1 |
| 312 | `$38` | 1 |

(El bit 2 de FLAGS se combina con la paleta y demás flags; p. ej. paleta 0 + X>255 → FLAGS = `$04`.)

```asm
; mover un sprite 1 px a la derecha con X de 9 bits (XLO = byte X, XHI = bit 8)
    INC XLO
    BNE .lim
    INC XHI           ; acarreo 255->256 -> bit 8
.lim:
    ; escribir byte X y FLAGS (bit2 = XHI)
    LDA XLO : STA $D802   ; (tras poner addr al byte X)
    ; FLAGS = (XHI<<2) | flags/paleta
```

### 6.2 Escribir un campo del OAM

```asm
; Escribe DATA en el campo FIELD del sprite SPR.
; Entrada: SPR (0-31), FIELD (0-4), DATA
oam_put:
    ; byte = SPR*5 + FIELD   -> usar tabla o multiplicación por 5
    LDA SPR
    STA BIDX
    ASL A                  ; *2
    CLC
    ADC BIDX               ; *3
    CLC
    ADC BIDX               ; no... ver nota
    ; (Sencillo: 5 = 4+1)
    RTS
```

**Forma recomendada** (sin multiplicar): mantén una tabla `SPR_BASE` en ROM con
`[0,5,10,15,...,155]` y usa `LDA SPR_BASE,X`.

```asm
oam_put:                   ; A = DATA, X = SPR, Y = FIELD
    PHA
    LDA SPR_BASE,X
    STA BIDX
    TYA
    CLC
    ADC BIDX
    STA BIDX               ; byte = base[spr] + field
    LDA #$C0               ; area 11, bit3=0 -> OAM
    STA $D801
    LDA BIDX
    STA $D800
    PLA
    STA $D802
    RTS
```

### 6.3 Definir un sprite completo (helper de juego)

```asm
; sprite_put: (XSPR, YSPR, TILE, FLAGS, COLL) para el sprite SPR
;   Escribe los 5 campos. Usar dentro del VBLANK.
sprite_put:
    LDA #0
    JSR oam_put            ; +0 X  (X=SPR, Y=0)
    LDA #1
    JSR oam_put            ; +1 Y
    LDA #2
    JSR oam_put            ; +2 TILE
    LDA #3
    JSR oam_put            ; +3 FLAGS
    LDA #4
    JSR oam_put            ; +4 COLL_POINT
    RTS
```

---

## 7. Scroll

El **scroll** desplaza la cámara sobre el mapa 64×32. Es global (por banda, ver §8).

### 7.1 Registros

- `$D804/$D805` = scroll X (0..2047, bits 2:0 en `$D805`).
- `$D806/$D807` = scroll Y (0..2047, bits 2:0 en `$D807`).

### 7.2 Mover la cámara

```asm
; Avanzar la cámara 1 px a la derecha (en VBLANK)
    INC SCX_LO
    BNE sc_ok
    INC SCX_HI
sc_ok:
    LDA SCX_LO
    STA $D804
    LDA SCX_HI
    STA $D805
```

- **Envoltura:** el mapa envuelve en X (mod 64) y en Y (mod 32). Al salir por
  un borde, reaparece por el otro.
- **Velocidad:** cambia `scroll` una vez por frame (en VBLANK) para 1 px/frame máx.

> ⚠️ **Rellena todo el mundo:** las celdas que el scroll pueda alcanzar
> (columnas 0-63, filas 0-31) deben tener contenido, o se verá basura.

---

## 8. Split de raster (bandas / HUD)

Divide la pantalla en **hasta 3 bandas verticales** con scroll independiente.
Ideal para **HUD fijo** arriba y/o abajo.

### 8.1 Registros

| Dir | Registro | Significado |
|-----|----------|-------------|
| `$D809` | `RASTER_LINE0` | Fin de la banda **superior** (línea lógica 0-239). `$FF` = sin banda |
| `$D80A/$D80B` | `BAND2_X` | Scroll de la banda superior |
| `$D80C/$D80D` | `BAND2_Y` | Scroll Y de la banda superior |
| `$D80E` | `RASTER_LINE1` | Fin de la banda **media**. `$FF` = sin banda inferior |
| `$D80F/$D810` | `BAND3_X` | Scroll de la banda inferior |
| `$D811/$D812` | `BAND3_Y` | Scroll Y de la banda inferior |

- **Banda superior** (0 .. `RASTER_LINE0`) → usa `BAND2_*`.
- **Banda media** (`RASTER_LINE0` .. `RASTER_LINE1`) → usa scroll normal (`$D804`).
- **Banda inferior** (`RASTER_LINE1` .. 239) → usa `BAND3_*`.

### 8.2 Ejemplo: HUD fijo arriba y abajo, juego al medio

```asm
; En el arranque:
    LDA #24                ; banda superior = 3 filas de tiles (0 margen + 2 HUD)
    STA $D809
    LDA #216               ; banda inferior empieza en linea 216 (filas 27..29)
    STA $D80E
    ; HUD fijo: scroll 0 en ambas bandas
    LDA #0
    STA $D80A : STA $D80B : STA $D80C : STA $D80D
    STA $D80F : STA $D810 : STA $D811 : STA $D812
```

- La fila de tilemap `n` corresponde a la línea lógica `n*8`.
- Con `RASTER_LINE0=24`, las **filas 0-2** del tilemap son la banda superior
  (fila 0 = margen; usa filas 1-2 para el HUD).
- Con `RASTER_LINE1=216`, las **filas 27-31** son la banda inferior (visibles 27-29).

---

## 9. Modo texto

No es un modo aparte: **el motor de tiles con una fuente cargada como patrones**.
Escribes el **código ASCII** como índice de tile en el tilemap.

- Fuente: charset del C64 (96 caracteres, `$20`-`$7F`), 8×8, 1bpp expandido a 2bpp.
- **`tile = ASCII`** → aparece el glifo (el hardware ya hizo el remapeo del C64).
- Usa la **paleta 0** del fondo (color 3 = tinta = blanco).
- **Rango útil:** `$20` (espacio) a `$7F`. Mayúsculas `$41-$5A`, minúsculas `$61-$7A`
  (están remapeadas internamente), dígitos `$30-$39`, signos `$21-$3F`.

> **Reserva de tiles:** la fuente ocupa `$20`-`$7F`. Los tiles `$00`-`$1F` quedan
> libres para gráficos propios. En un juego real defines tu propio tileset **y** la
> fuente en rangos que no choquen.

### 9.1 La rejilla de texto

El texto vive en el **tilemap** (64×32 celdas). Una pantalla de texto usa las
40 columnas visibles × 30 filas. La **celda del cursor** se calcula igual que
cualquier celda:

```
celda = fila * 64 + columna
```

### 9.2 Variables de la consola (zero page sugeridas)

```
CX = $40        ; columna del cursor (0..39)
CY = $41        ; fila del cursor (0..29)
CTMP = $42      ; temporal
```

### 9.3 `put_xy`: escribir un carácter en una posición

```asm
; A = caracter ASCII, CX = columna, CY = fila
put_xy:
    STA CTMP
    ; celda = CY*64 + CX  (stride 64 = shift)
    LDA CY
    LSR A : LSR A : STA $18      ; celda_hi = CY >> 2
    LDA CY
    AND #$03
    ASL A : ASL A : ASL A : ASL A : ASL A : ASL A
    ORA CX                        ; | CX (0..39, cabe en 6 bits)
    STA $17                       ; celda_lo
    ; escribir en el tilemap (area 00)
    LDA $17 : STA $D800
    LDA $18 : STA $D801
    LDA CTMP : STA $D802          ; tile = ASCII -> glifo
    RTS
```

### 9.4 `put_char`: carácter en el cursor y avanzar

```asm
; A = caracter ASCII. Avanza el cursor; al final de linea, salta.
put_char:
    CMP #$0D               ; CR = fin de linea
    BEQ .cr
    PHA
    LDA CX                 ; posicion actual
    ; (usar put_xy con CX/CY)
    PLA
    JSR put_xy
    ; avanzar columna
    INC CX
    LDA CX
    CMP #40                ; 40 columnas
    BCC .fin
    LDA #0 : STA CX        ; nueva linea
    INC CY
.fin:
    RTS
.cr:
    LDA #0 : STA CX
    INC CY
    RTS
```

### 9.5 `put_str`: imprimir una cadena

```asm
; X = indice en la cadena (terminada en 0)
put_str:
    LDA cadena,X
    BEQ .fin
    JSR put_char
    INX
    JMP put_str
.fin:
    RTS
```

### 9.6 Borrar pantalla (llenar con espacios)

```asm
; Rellena las 40x30 celdas visibles con espacio ($20)
clear_screen:
    LDA #0
    STA $17               ; celda_lo = 0
    LDA #0
    STA $18               ; celda_hi = 0
clr_loop:
    LDA #$20              ; espacio
    STA $D802             ; (addr ya apunta a la celda)
    ; avanzar direccion
    INC $17
    BNE clr_n
    INC $18
clr_n:
    ; 40*30 = 1200 -> fin cuando celda = 1200 ($4B0)
    ; (comparar $18:$17 con $04:$B0)
    LDA $18
    CMP #$04
    BCC clr_again
    LDA $17
    CMP #$B0
    BCC clr_again
    RTS
clr_again:
    ; reescribir la direccion y repetir
    LDA $17 : STA $D800
    LDA $18 : STA $D801
    JMP clr_loop
```

> **Nota:** el puerto indirecto no auto-incrementa; hay que reescribir `$D800/$D801`
> antes de cada `$D802`. El ejemplo lo hace en cada iteración.

### 9.7 Scroll de texto (subir una línea)

Cuando el cursor pasa de la última fila, desplaza todo el texto una fila hacia
arriba y deja la última línea en blanco. Se hace **copiando el tilemap** desde RAM
(o releyendo si tuvieras lectura de VRAM; hoy se mantiene **una copia en RAM**):

```asm
; Idea: el juego mantiene el texto en una RAM de 40x30 (1200 bytes).
; scroll_text: copia fila N+1 sobre fila N (N=0..28), y limpia la fila 29.
; Luego reescribe las celdas de VRAM que cambiaron (o toda la pantalla).
```

> **Recomendación:** como el **CPU no puede leer la VRAM** (el puerto es solo de
> escritura), la consola mantiene su propia **copia del texto en RAM** (1200 B) y
> la vuelca a la VRAM por bloques. Es lo estándar.

### 9.8 HUD de texto con split de raster

Para un marcador **fijo** (score, vidas) sobre el juego, usa el **split de raster**
(§8): reserva una banda (p. ej. la superior) con **scroll 0** y escribe el texto en
las filas del tilemap que caen en esa banda. El texto queda fijo mientras el juego
scrollea.

```asm
; banda superior de 3 filas (raster_line0 = 24): filas 1-2 para el HUD
; escribir "SCORE 000000" en la fila 1, columnas 2..
```

### 9.9 Ejemplo completo: pantalla de título

```asm
start_text:
    JSR clear_screen
    LDA #10 : STA CX       ; columna 10
    LDA #5  : STA CY       ; fila 5
    LDX #0
    JSR put_str_title
    RTS

title:  .byte "MI JUEGO", $0D
        .byte "PULSA FIRE", 0
```

### 9.10 Colores del texto

El color lo da la **paleta de la celda** (bits 1:0 de `attr_arr`), no el tilemap.
Para cambiar el color de un texto, escribe el **atributo** de la celda:

```asm
; poner el texto de la celda (CX,CY) en paleta P (0..3)
; (usar la misma celda; area 01 = atributos)
    ; celda = CY*64 + CX  -> $17/$18
    LDA $17 : STA $D800
    LDA $18 : STA $D801    ; OJO: aqui area 00; para atributo, ORA #$40 en $18
    ; ... ver put_attr del manual §5.3
```

### 9.11 Resumen de la fuente

| Rango ASCII | Contenido |
|-------------|-----------|
| `$20` | espacio |
| `$21`-`$2F` | signos (`!"#$%&'()*+,-./`) |
| `$30`-`$39` | dígitos `0`-`9` |
| `$3A`-`$40` | signos (`:;<=>?@`) |
| `$41`-`$5A` | mayúsculas `A`-`Z` |
| `$5B`-`$60` | signos (`[\]^_` + backtick) |
| `$61`-`$7A` | minúsculas `a`-`z` |
| `$7B`-`$7F` | `{|}~` (algunos en blanco) |

> `CR` (`$0D`) se usa como **fin de línea** en las rutinas de consola (no es un glifo).

---

## 10. Colisión sprite↔tile (sólidos)

### 10.1 Concepto

- Marca celdas del fondo como **sólidas**: bit 4 del **atributo** de la celda.
- El hardware, cada frame, comprueba el **COLL_POINT** de cada sprite y pone el
  flag `SOLID_HIT` (bit 5 de `$D803`) si algún sprite toca una celda sólida.

### 10.2 Marcar una celda sólida

```asm
; Marcar la celda (ROW,COL) como solida (bit 4 del atributo)
    JSR calc_cell
    LDA CUR_LO
    STA $D800
    LDA CUR_HI
    ORA #$40               ; area 01 = atributos
    STA $D801
    LDA #$10               ; bit 4 = SOLIDO
    STA $D802
```

### 10.3 Punto de colisión (COLL_POINT)

- `COLL_POINT`: `bits 2:0 = dx`, `bits 5:3 = dy` (**offset libre 0-7**).
- **Auto-escala (en hardware):** **siempre escribes dx/dy en escala 0-7** (como si el
  sprite fuera 1×). Si el sprite tiene `SCALE2X`, el hardware **escala el punto
  automáticamente**: `dx 0..6 → dx*2`, `dx=7 → 15`. Así **no tienes que saber la
  escala**: los mismos valores dan los mismos puntos lógicos.

| Punto | Byte | 1× alcanza | 2× alcanza |
|-------|------|-----------|-----------|
| centro | `$24` | 4 | 8 |
| pie | `$3C` | 7 | 15 |
| cabeza | `$04` | 0 | 0 |
| borde izq | `$20` | 0 | 0 |
| borde der | `$27` | 7 | 15 |

> **Nota:** en 2× solo se alcanzan las posiciones **pares** + el borde (15). Es
> suficiente para los puntos útiles (bordes, centro, pie, cabeza).

### 10.4 Patrón de uso (varios sprites: deducción en software)

El flag `SOLID_HIT` es **global** (no dice **qué** sprite chocó). Si tienes varios
objetos, cada uno con su posición en RAM, **deduces cuál chocó** comparando su borde
(el que avanza) contra la columna/pared:

```asm
; cada frame, en VBLANK:
;   1) ajustar COLL_POINT segun direccion (borde que avanza)
;   2) LEER SOLID_HIT; si activo, deducir QUE sprite choco comparando su borde
;      con la posicion de la pared, y rebotar SOLO ese.
    LDA $D803
    AND #$20               ; SOLID_HIT
    BEQ no_hay
    ; --- deducir sprite 0 ---
    LDA DIR0
    BNE s0_izq
    LDA X0 : CLC : ADC #7  ; borde derecho
    CMP PARED_X_IZQ        ; ¿llego a la pared?
    BCC s0_no
    LDA DIR0 : EOR #$01 : STA DIR0
s0_no:
    ; (repetir para el sprite 1 con su borde = X+15 si es 2x)
no_hay:
```

> **Regla:** el hardware dice **"alguien chocó"**; el software dice **"quién"**.
> Para 1 solo objeto colisionador, el flag basta sin deducción.

> **Latencia:** 1 frame (la colisión se recalcula en el blanking). Al chocar el
> sprite puede "pasarse" ~1 px; compénsalo con push-out si lo necesitas.

### 10.5 Colisión sprite↔sprite → SOFTWARE

**No hay colisión sprite↔sprite en hardware.** Se hace en software comparando las
cajas (AABB) de los objetos, cuyas posiciones ya tienes en RAM:

```asm
; ¿colisionan el sprite A (xa,ya) y el B (xb,yb)?  (8x8)
    LDA xa : SEC : SBC xb
    ; |dx| < 8 ?  y  |dy| < 8 ?  -> colision
```

---

## 11. STATUS: VBLANK y sincronización

`$D803` (lectura):

| Bit | Nombre | Significado |
|-----|--------|-------------|
| 7 | `VBLANK` | 1 = fuera de la zona visible (seguro escribir VRAM/OAM) |
| 6 | `OVERFLOW` | 1 = más de 8 sprites en una línea (se descartó alguno) |
| 5 | `SOLID_HIT` | 1 = algún sprite tocó un tile sólido este frame |
| 4 | `VIDEO_READY` | 1 = inicialización de VRAM terminada (esperar al arrancar) |

### 11.1 Esperar VIDEO_READY al arrancar

```asm
wait_ready:
    LDA $D803
    AND #$10
    BEQ wait_ready
```

### 11.2 Sincronizar con el frame (VBLANK)

**Regla de oro:** mueve sprites, escribe OAM y scroll **durante el VBLANK**.

```asm
; una iteración = un frame
frame:
wait_vb:
    LDA $D803
    AND #$80
    BEQ wait_vb            ; espera entrar en VBLANK
    ; ---- aquí actualizas todo (OAM, scroll, paletas) ----
    JSR update_game
wait_vb_end:
    LDA $D803
    AND #$80
    BNE wait_vb_end        ; espera salir del VBLANK
    JMP frame
```

> Escribir el OAM a mitad del frame visible **parte el sprite** (unas líneas con
> el valor viejo y otras con el nuevo). Hazlo siempre en VBLANK.

---

## 12. Recetas completas

### 12.1 Dibujar un fondo de un color (lleno)

```asm
; Rellena las 64*32=2048 celdas del mapa con el tile TILE
    LDA #<0
    STA $D800
    LDA #>0
    STA $D801              ; area 00, dir 0
    LDY #0
    LDA #TILE
    LDX #8                 ; 8 * 256 = 2048
fill:
    STA $D802
    INY
    BNE fill
    DEX
    BNE fill
```

### 12.2 Sprite que se mueve y rebota en los bordes

```asm
; en VBLANK: mover X, rebotar en 0 y 312
    LDA SPDIR
    BNE .left
    INC SPX
    LDA SPX
    CMP #232
    BCC .wr
    LDA #1
    STA SPDIR
    JMP .wr
.left:
    DEC SPX
    LDA SPX
    CMP #8
    BCS .wr
    LDA #0
    STA SPDIR
.wr:
    LDX #0                 ; sprite 0
    LDA SPX
    LDY #0                 ; campo X
    JSR oam_put
```

### 12.3 Un objeto 16×16 (4 sprites) a 1×

```asm
; cuadrantes A=0,B=1,C=2,D=3; posicion base (BX,BY)
;  A (BX, BY)     B (BX+8, BY)
;  C (BX, BY+8)   D (BX+8, BY+8)
    ; sprite 0 = A
    ... oam_put(sprites 0..3, X=BX/BX+8, Y=BY/BY+8, TILE=0..3, FLAGS=paleta)
```

### 12.4 Un objeto 16×16 a 2× (32×32)

Igual que 6.3 pero cada sprite con `FLAGS |= $10` (SCALE2X) y **paso +16** entre
cuadrantes (no +8).

### 12.5 Escribir texto

Ver la **sección 9** para la librería de consola completa (`put_xy`, `put_char`,
`put_str`, `clear_screen`, scroll). Resumen mínimo:

```asm
; Imprime "HOLA" en la fila CY, col CX (tile = ASCII)
    LDX #0
txt_loop:
    LDA msg,X
    BEQ txt_done
    JSR put_char           ; usa CX/CY; ver §9.4
    INX
    JMP txt_loop
txt_done:
    RTS
msg:
    .byte "HOLA", 0
```

---

## 13. Limitaciones y buenas prácticas

| Limitación | Valor | Nota |
|------------|-------|------|
| Sprites | 32 en OAM | Más → ampliar hardware |
| Coordenada X | **9 bits (0-511)** | bit 8 en FLAGS(2) → cubre toda la pantalla |
| Coordenada Y | 8 bits (0-255) | pantalla 240 → sobra |
| Sprites por línea | **8** | Más → `OVERFLOW` y se pierde alguno |
| Sprites (patrones) | 64 | 8×8, 2bpp |
| Patrones de fondo | 256 | comparte rango con la fuente (`$20`-`$7F`) |
| Paletas de fondo / sprite | 4 / 4 | cada una de 4 colores |
| Colores en pantalla | hasta 64 | 4 colores por celda × 16 combinaciones |
| Mapa | 64×32 | scroll con envoltura |
| BSRAM | **agotada** | no cabe framebuffer ni tilemap doble |
| Colisión sprite↔sprite | **no hay** | hacer por software (comparar X/Y) |
| Colisión sprite↔tile | flag **global** | no dice qué sprite; deducir por software |
| COLL_POINT | dx, dy **0-7** | auto-escala a 0-15 si el sprite es 2× |
| Rotación de sprites | **no hay** | usar sprites pre-rotados |

**Buenas prácticas:**

1. **Actualiza todo en VBLANK** (OAM, scroll, paletas). Nunca a mitad del frame.
2. **Rellena el mundo** completo (64×32) antes de hacer scroll.
3. **Espera VIDEO_READY** al arrancar antes de tocar la VRAM.
4. **No superes 8 sprites por línea** (o usa `OVERFLOW` para detectarlo).
5. **Colisión de juego = software**: guarda X/Y de los objetos y compáralas.
6. **HUD arriba:** reserva la fila 0 del tilemap (margen) y usa las filas 1+.
7. **Personajes grandes:** usa varios sprites (16×16 = 4) o tiles (para muchos).
8. **Muchos objetos en pantalla** (Space Invaders, etc.): usa **tiles** en el
   tilemap, no sprites.

---

## 14. Esqueleto de juego

```asm
; ============================================
; Plantilla de juego minimo
; ============================================
    .setcpu "6502"

VID_LO = $D800
VID_HI = $D801
VID_DT = $D802
VID_ST = $D803

; --- zero page ---
CUR_LO = $10
CUR_HI = $11
SPX    = $12
SPY    = $13
DIR    = $14

    .segment "CODE"
    .org $8000

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    ; 1) esperar VIDEO_READY
wr:
    LDA VID_ST
    AND #$10
    BEQ wr

    ; 2) inicializar: tiles, tilemap, atributos, sprites, bandas

    ; 3) bucle principal (1 iteracion = 1 frame)
main:
wvb:
    LDA VID_ST
    AND #$80
    BEQ wvb                ; entrar en VBLANK
    JSR update             ; mover objetos, escribir OAM, scroll
wvbe:
    LDA VID_ST
    AND #$80
    BNE wvbe               ; salir de VBLANK
    JMP main

; --- actualizacion por frame ---
update:
    ; mover jugador (leer joy/teclado), mover balas, colisiones,
    ; animar tiles, actualizar HUD, scroll
    RTS

    .org $BFFA
    .word $8000
    .word reset
    .word $8000
```

---

## Apéndice A — Chuletas de referencia

### A.1 Áreas de `$D801`

| `$D801` | Escribe en |
|---------|-----------|
| `$00` | tilemap |
| `$40` | atributos |
| `$80` | patrón fondo plano 0 |
| `$A0` | patrón fondo plano 1 |
| `$C0` | OAM |
| `$C8` | patrón sprite plano 0 |
| `$E8` | patrón sprite plano 1 |

(`$C8`/`$E8` = `$C0`/`$E0` con bit 3 = 1; la dirección alta del patrón va en bits 2:0.)

### A.2 Atributo del fondo

```
bit7 PRIO | bit6 FLIP_Y | bit5 FLIP_X | bit4 SOLIDO | bits3:0 PALETA
```

**FLAGS del sprite**

```
bit7 FLIP_Y | bit6 FLIP_X | bit5 PRIO | bit4 SCALE2X | bit2 X_bit8 | bits1:0 PALETA
```

### A.4 Fórmulas útiles

```
celda      = y_tile*64 + x_tile          (tilemap/atributo)
dir_patron = tile*8 + fila               (patrón de fondo)
dir_spr    = sprite*8 + fila             (patrón de sprite)
byte_oam   = sprite*5 + campo            (campo 0..4)
```

---

*Fin del manual. Para detalles de implementación interna, ver el resto de `docs/`.*
