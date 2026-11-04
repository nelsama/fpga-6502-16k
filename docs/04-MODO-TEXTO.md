# Módulo de Vídeo — Fase 7: Modo Texto

**Proyecto:** fpga-6502-16k
**Documento:** Implementación del modo texto (segunda ROM de fuente)
**Referencia:** `docs/02-PLAN-IMPLEMENTACION.md` §Fase 7
**Estado:** ✅ Implementado y validado en hardware

---

## 1. Idea central

**El modo texto NO es un modo de vídeo nuevo.** Es el motor de tiles existente,
con una **fuente de caracteres cargada en los patrones** y una convención de
software:

```
tilemap[celda] = codigo ASCII  ->  patron ASCII  ->  glifo en pantalla
```

Si el patrón `N` es el dibujo del carácter ASCII `N`, entonces **escribir texto
es escribir el código ASCII en el tilemap**. Una sola escritura de 8 bits por
carácter.

**Consecuencia:** cero LUTs de render nuevas, cero cambios en el pipeline, y el
CPU nunca manipula patrones al imprimir.

---

## 2. La "segunda ROM" de fuente (`font_arr`)

### 2.1 Qué es

Un banco BSRAM **precargado** con los dibujos de los 96 caracteres ASCII
imprimibles (`$20`–`$7F`), en **1bpp** (1 bit por píxel, 2 colores).

| Propiedad | Valor |
|-----------|-------|
| Formato | 1bpp (1 byte = 1 fila de 8 píxeles) |
| Caracteres | 96 (`$20`–`$7F`) |
| Entradas | 2048 (0..2047), de 9 bits |
| Usadas | 768 (96 chars × 8 filas); el resto a 0 |
| BSRAM | **1 bloque** (2048×9, el mismo de antes) |
| Dirección | `char*8 + fila`, con `char = ascii - $20` |

El bloque es de 2048×9 porque es la **forma mínima** que se mapea a un bloque de
BSRAM; las 1280 filas sobrantes se reservaron para una segunda copia de la fuente
que **no llegó a implementarse** (ver §2.5).

### 2.4 Fuente: charset original del C64

La fuente es el **charset original del C64** (`characters.901225-01.bin`,
4096 bytes), integrado con `src/asm/mk_font_c64.py`.

**El archivo tiene DOS juegos de 2048 bytes:**

| Juego | Offset | Contenido | Formato |
|-------|--------|-----------|---------|
| 1 | `$000` | mayúsculas + gráficos | `1` = **fondo** (borde blanco) |
| **2** | **`$800`** | **mayúsculas + minúsculas** | `1` = **tinta** (mismo que el nuestro) |

Se usa el **juego 2**, que además de tener las minúsculas, **ya está en el formato
correcto** (no hay que invertir).

**Mapeo ASCII → código del juego 2 (verificado):**

| ASCII | Código C64 | Nota |
|-------|-----------|------|
| espacio | `$20` | |
| `!`..`?` | `$21`..`$3F` | coinciden con ASCII |
| `@` | `$00` | arroba clásica del C64 |
| `A`..`Z` | `$41`..`$5A` | coinciden con ASCII |
| `a`..`z` | `$01`..`$1A` | **remapeadas** (en ASCII están en `$61`..`$7A`) |
| `[`, `]` | `$1B`, `$1D` | |

Los caracteres ASCII que **no existen** en el C64 (`\`, `^`, `_`, `{`, `}`, `|`,
`~`) quedan **en blanco**.

### 2.2 Por qué 1bpp y no 2bpp

El formato nativo de la VRAM es 2bpp planar (16 bits por fila). Guardar la
fuente directamente en 2bpp costaría el doble:

| Formato | 96 caracteres | ¿Cabe en 1 bloque (1.152 B)? |
|---------|---------------|------------------------------|
| 1bpp | 768 B | ✅ |
| 2bpp | 1.536 B | ❌ (necesitaría 2 bloques) |

Como hay **un solo bloque libre**, la fuente va en 1bpp y se **expande a 2bpp**
durante el arranque.

### 2.3 Direccionamiento y formato

```
font_arr[dir] = un byte, 1bpp:
   bit 7 = pixel mas a la IZQUIERDA
   bit 0 = pixel mas a la DERECHA
   1 = tinta, 0 = fondo
```

El array se declara de **9 bits** para que Gowin lo mapee en **un solo bloque**
(la forma nativa del bloque BSRAM de la GW1NR-9 es de 2048 posiciones de 9 bits).

---

### 2.5 Dos copias de la fuente con distinto color de trazo — ❌ NO IMPLEMENTADO

> ⚠️ **Esta sección describe un diseño previsto que NO está en el RTL.** Se deja
> como referencia por si se retoma (está bloqueado por falta de CLS, ver
> `docs/informe-optimizacion-resultados.md`).

**Estado real:** la fase de expansión genera **una sola copia**. El color del trazo
lo elige el registro `$D818` (`FONT_COLOR`), que **al arrancar vale 3**: entonces
`plano0 = plano1 = byte` del glifo y el trazo de **todas** las letras es
`pixcode 11` → `pal_bg[pal][3]`.

| Copia | Tiles | Trazo | Estado |
|-------|-------|-------|--------|
| A | `$00`..`$7F` (tile = ASCII) | `11` → entrada 3 | ✅ **implementada** |
| B | `$80`..`$DF` | `01` → entrada 1 | ❌ **no existe** |

**Hoy el bit 7 del tile NO selecciona color.** Es parte del índice de tile, y los
tiles `$80`–`$FF` son **otros patrones** (el Pac-Man los usa para la fruta y otros
gráficos). Intentar usarlo como selector de color rompe esos gráficos: comprobado
en hardware.

#### Diseño previsto (no implementado)

| Copia | Tiles | Trazo (`pixcode`) | Entrada de paleta |
|-------|-------|-------------------|-------------------|
| A | `$00`..`$7F` (tile = ASCII) | `11` | `pal_bg[pal][3]` |
| B | `$80`..`$DF` (tile = ASCII OR `$80`) | `01` | `pal_bg[pal][1]` |

La copia B vive en `ASCII OR $80`, así que para dibujar una `A` con el trazo en la
entrada 1 de la paleta se escribiría el tile `$41 OR $80 = $C1`.

**Por qué no se implementó:** cuesta ~3 FF de pipeline más comparadores, y el
diseño está al 98 % de CLS. Los tres intentos de añadir color de texto fallaron
(ver el informe de optimización).

## 3. Expansión 1bpp → 2bpp (fase de inicialización)

### 3.1 Por qué en hardware y no en software

La expansión la hace **una fase de la máquina de inicialización de la VRAM**
(como las fases del tilemap, atributos y sprites). Ventajas:

- **No requiere que el CPU lea `font_arr`** (evita un handshake de lectura
  entre dominios de reloj).
- **No está en el camino del render** → no puede desalinear el pipeline.
- Ocurre **una vez**, al encender.

### 3.2 La expansión

La fuente se expande **una sola vez** (la copia B de la sección 2.5 no está
implementada). Por cada carácter (0..95) y cada fila (0..7):

```
byte = font_arr[char*8 + fila]                 (1bpp, 8 bits)

COPIA A (única) -> tiles 0..127  (tile = ASCII)
  plano0 = byte AND MASK_LO[color]
  plano1 = byte AND MASK_HI[color]
  pat_arr[ascii*8 + fila] = plano1 & plano0
```

Máscaras según el color elegido (`font_color_in`, registro `$D818`, **3 por defecto**):

| color | MASK_LO | MASK_HI |
|-------|---------|---------|
| 0 | `$00` | `$00` |
| 1 | `$FF` | `$00` |
| 2 | `$00` | `$FF` |
| 3 | `$FF` | `$FF` |

Con `$D818 = 3` (valor al arrancar), `plano0 = plano1 = byte`, así que el trazo es
**`pixcode 11`** → `pal_bg[pal][3]`. Con 1 o 2 el trazo pasa a color 1 o 2 de la
paleta de la celda, y con 0 desaparece (transparente). El valor es **global** para
toda la fuente; para cambiarlo hay que re-expandir con `SETUP` (`$D816`).

Son **4 colores de trazo en total** (uno por valor de `$D818`), más los 4 de la
paleta por celda, pero **no simultáneos**: `$D818` cambia los 4 a la vez.

El fondo del glifo es `pixcode 00`, **transparente**: se ve el color de fondo
global (`BG_COLOR`, entrada 15) o lo que haya detrás.

**Mapeo de tiles:** el patrón escrito en `ascii*8+fila` hace que **tile = ASCII**
(comportamiento clásico). El bit 7 del tile es parte del índice y **no** selecciona
color.

### 3.3 Alineación (latencia BSRAM) — CRÍTICO

`font_arr` y `pat_arr` tienen 1 ciclo de latencia. La fase usa un **pipeline con
doble registro** de la dirección:

```
ciclo N   : init_cnt = k, font_init_addr = k    -> BSRAM captura k
ciclo N+1 : font_dout = font_arr[k]
ciclo N+2 : font_row_d = font_arr[k]            (dato, registrado)
            font_cnt_d2 = k                      (init_cnt retrasado 2 ciclos)
         -> se escribe pat_arr[k] con el dato expandido
```

**El retardo DEBE ser de 2 ciclos** (`font_cnt_d` y `font_cnt_d2` en cascada).
Con 1 ciclo, cada fila se escribe en la dirección de la **fila siguiente**: la
última fila de un carácter "asoma" por arriba del carácter siguiente (síntoma:
píxeles o líneas de más sobre `h`, `k`, `q`, `r`, `z`, que son los que tienen
filas vacías al principio).

La fase 4 recorre las **768 filas** de la fuente (96 caracteres × 8 filas).

La dirección de lectura es `font_init_addr`; la de escritura es `font_cnt_d2`
(retrasada 2 ciclos, que es lo que tarda la fuente: 1 ciclo de la BSRAM de
`video_vram` + 1 de `font_row_d`).

> ⚠️ **No usar `init_cnt mod 768`.** `init_cnt` es un entero que si no se usa
> como dirección el sintetizador **trunca a 8 bits**, y el módulo sobre un
> contador truncado desalinea la fila leída con la escrita: cada glifo aparece
> corrido un byte y el texto sale con letras cambiadas.

---

## 4. Máquina de estados de la inicialización

La VRAM se llena al encender en **5 fases**:

| Fase | Escribe en | Contenido |
|------|-----------|-----------|
| 0 | `tile_arr` | tilemap: `$20` (espacio) en las 2048 celdas |
| 1 | `attr_arr` | atributos: `0` (paleta de TEXTO) |
| 2 | `pat_arr` (0..63) | patrones de tiles 0..7: **a cero** |
| 3 | `spr_arr` | patrones de sprite 0..2: **a cero** |
| 4 | `pat_arr` (`$00..$1FF`) | **expansión de la fuente** (copias A y B) |

> Las fases 2 y 3 escriben ceros. Antes ponían arte de demo preincorporado
> (8 tiles: tierra, césped, árbol, nube… y 3 sprites: cara, rombo, X), pero se
> **eliminó**: no servía para nada. La fase 4 sobrescribía los tiles 0–7, y todo
> el software escribe sus propios patrones antes de dibujar. Quitarlo liberó
> bastante lógica, que en este chip era necesaria para poder colocar el diseño.

Al terminar la fase 4, se pone **`init_done = '1'`**.

### 4.0 Un SETUP (`$D816`) se salta las fases 2 y 3

Si la secuencia la dispara el CPU por `$D816`, tras limpiar tilemap y atributos
(fases 0 y 1) **se salta directamente a la fase 4**, para no reiniciar los
patrones de fondo ni de sprite: el juego puede tener ahí su propio arte.

### 4.1 `init_done` y el puerto A

Mientras `init_done='0'`, **el puerto A de escritura de la VRAM lo controla el
hardware** (las fases). Las escrituras del CPU se **descartan**.

**Por eso el CPU debe esperar a que la VRAM esté lista antes de escribir.**

### 4.2 Bit `VIDEO_READY` en STATUS

Se añadió el **bit 4** de `$D803`:

| Bit | Campo |
|-----|-------|
| 7 | VBLANK |
| 6 | SPRITE_OVERFLOW |
| 5 | — |
| **4** | **VIDEO_READY** (1 = init terminada) |
| 3..0 | — |

El software espera este bit antes de escribir la VRAM:

```asm
wait_ready:
    LDA $D803
    AND #$10          ; bit 4
    BEQ wait_ready
```

---

## 5. Uso desde el 6502

### 5.1 Imprimir un carácter

```asm
; A = codigo ASCII, CUR = celda del cursor (fila*40 + columna)
put_char:
    STA TMP
    LDA CUR_LO
    STA $D800         ; direccion lo
    LDA CUR_HI
    STA $D801         ; area 00 = tilemap
    LDA TMP
    STA $D802         ; escribir ASCII -> muestra el glifo
    INC CUR_LO
    BNE pc_n
    INC CUR_HI
pc_n:
    RTS
```

### 5.2 Imprimir una cadena

```asm
; X = indice; cadena terminada en 0
    LDX #0
loop:
    LDA mensaje,X
    BEQ fin
    JSR put_char
    INX
    JMP loop
fin:
```

### 5.3 Colores del texto

El color lo determina la **paleta de la celda** (bits 1:0 de `attr_arr`), no el
tilemap. La paleta 0 está reservada para texto:

```
paleta 0 - TEXTO : color0=negro, color1=gris, color2=blanco, color3=blanco
```

Para texto en otro color habría que reasignar paletas o escribir atributos por
celda (pendiente, ver §7).

---

## 6. Validación en hardware

Se escribió un programa de prueba (`src/asm/video_test.asm`) que imprime:

```
fila 2:  HELLO 6502!
fila 4:  ABCDEFGHIJKLMNOPQRSTUVWXYZ
fila 6:  0123456789 .,:;!?-+*/=()
fila 8:  abcdefghijklmnopqrstuvwxyz
```

**Resultado:** ✅ correcto. Mayúsculas, minúsculas, dígitos y símbolos, en
blanco sobre negro, sin desplazamientos ni glitches.

### 6.1 Recursos tras la Fase 7

| Recurso | Uso |
|---------|-----|
| LUTs | ~4.523 / 8.640 (52%) |
| **BSRAM** | **26/26 (100%)** |
| DSP | 2/10 |

La Fase 7 costó **~+70 LUTs** (lógica de expansión y mux) y **+1 bloque BSRAM**
(el banco de fuente, que consume el último bloque libre).

---

## 7. Limitaciones y trabajo futuro

| Tema | Estado |
|------|--------|
| Fuente de 96 caracteres ASCII imprimibles | ✅ |
| Color fijo (blanco, paleta 0) | ✅ |
| **Color de texto por celda** | ⏳ pendiente (`attr_arr` ya lo permite) |
| **Cursor / scroll de texto** | ⏳ pendiente (software) |
| **Integración con el monitor** | ⏳ requiere espacio en ROM (llena) |
| Fuente estilo C64/retro exacta | ⏳ opcional (sustituir `mk_font.py`) |
| 40 vs 80 columnas | 40 columnas (resolución lógica 320×240) |

### 7.1 Herramientas

- **`src/asm/mk_font.py`**: genera una fuente 8×8 en 1bpp desde arte ASCII
  (alternativa propia al charset del C64).
- **`src/asm/mk_font_c64.py`**: genera la fuente desde el **charset original del
  C64** (`c64_charrom.bin`), con el mapeo PETSCII→ASCII.
  - `python mk_font_c64.py vhd ../hdmi/font_data.vhd` → paquete VHDL precargado.
  - `python mk_font_c64.py` → tabla `.byte` para el ensamblador.
  - `python mk_font_c64.py show abc` → diagnóstico (dibuja glifos en consola).

---

## 8. Lecciones críticas (bugs resueltos)

1. **`init_done` nunca llegaba a 1.** La fase 4 quedó **mal anidada** (fuera del
   `elsif init_done='0'`), así que la máquina se quedaba atascada y **el puerto A
   de la VRAM seguía retenido por el hardware**. Síntoma: el CPU escribía el
   tilemap pero **no aparecía nada**. Lección: **verificar el anidamiento de los
   `elsif` en máquinas de estados grandes**.

2. **El CPU arranca antes que el vídeo.** La init del vídeo tarda ~3.224 ciclos de
   `clk_pixel` (~120 µs). El CPU (a 3,375 MHz) empieza a ejecutar antes; cualquier
   escritura durante la init se pierde. Solución: **bit `VIDEO_READY` en STATUS**.

3. **Relojes del sistema (para futuras fases):**
   - `CLOCK_27_i` = 27 MHz (vídeo, PLL ×5 = 135 MHz para TMDS).
   - `system_clk` = 6,75 MHz (periféricos, `video_bus`).
   - `cpu_clk` = 3,375 MHz.

4. **BSRAM: una sola forma por array.** Declarar `font_arr` como `2048×9` (no
   `2048×8`) es lo que permite que **Gowin lo mapee en un solo bloque**. Un array
   declarado y no usado se **optimiza y desaparece** (por eso hay que medir con la
   lectura conectada).

5. **El charset del C64 tiene dos juegos de 2 KB.** El juego 1 (`$000`) no tiene
   minúsculas y usa `1 = fondo`. El **juego 2** (`$800`) tiene mayúsculas **y**
   minúsculas, y usa `1 = tinta` (nuestro formato). Usar el juego equivocado da
   "texto invertido" y "líneas blancas por fila".

6. **Latencia de BSRAM: contarla con precisión.** En la expansión de fuente, el
   retardo de la dirección de escritura debe ser **2 ciclos** (no 1). Con 1 ciclo,
   cada fila se escribe una posición corrida y las filas finales de un carácter
   se cuelan en el siguiente. El síntoma (píxeles de más en `h`, `k`, `q`, `r`,
   `z`) es sutil pero inconfundible.

---

## 9. Archivos modificados/creados

| Archivo | Cambio |
|---------|--------|
| `src/asm/mk_font.py` | Generador de fuente propia (arte ASCII → 1bpp). |
| `src/asm/mk_font_c64.py` | **Generador desde el charset original del C64.** |
| `src/asm/c64_charrom.bin` | **Charset original del C64** (4096 B). |
| `src/hdmi/font_data.vhd` | Paquete con la fuente precargada (2048×9). |
| `src/hdmi/video_vram.vhd` | Añadido `font_arr` + puerto de lectura. |
| `src/hdmi/video_core.vhd` | Fase 4 (expansión), paleta de texto, `VIDEO_READY`. |
| `src/asm/video_test.asm` | Prueba de modo texto. |
| `6502_board_v3.gprj` | Registrado `font_data.vhd`. |
