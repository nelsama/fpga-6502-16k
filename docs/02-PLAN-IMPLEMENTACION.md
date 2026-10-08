# Módulo de Vídeo — Plan de Implementación

**Proyecto:** fpga-6502-16k
**Documento:** Plan de ejecución por fases
**Referencia:** `docs/01-REQUERIMIENTOS.md`

---

## 1. Estrategia general

### 1.1 Principios

1. **Incremental y verificable.** Cada fase produce algo **visible en pantalla**.
   Si no se ve, la fase no está terminada.
2. **Sintetizar entre fases.** El presupuesto de LUTs/BSRAM se corrige con **datos
   medidos**, no con estimaciones. Esto detecta desviaciones antes de comprometer
   trabajo posterior.
3. **Empezar por el modo complejo.** El modo tiles es el caso difícil; el texto y el
   bitmap se añaden después con coste bajo, porque comparten el pipeline.
4. **No tocar el core existente.** Todo el código nuevo va en módulos propios más
   cambios mínimos en `Board.vhd` y `Data_bus_mux.vhd`.
5. **Sincronización correcta desde el inicio.** RNF-01 no es negociable (ver §5).

### 1.2 Orden de modos

```
Tiles + sprites  ──►  Texto  ──►  Bitmap  ──►  Rotación/escala
  (complejo)         (trivial)     (medio)      (extensión)
```

El modo texto se construye casi gratis sobre el modo tiles (es un subconjunto).
El bitmap requiere un datapath alternativo pero modesto.

---

## 2. Fases

### Fase 0 — Verificación previa (sin vídeo)

**Objetivo:** dejar el diseño actual en un estado conocido y estable antes de
construir sobre él.

| Tarea | Estado | Motivo |
|-------|--------|--------|
| Verificar `clk_81mhz` = 81 MHz | ✅ **Hecho** | Netlist confirma VCO 648 MHz / CLKOUT 81 MHz |
| Regenerar `Gowin_PLL_81MHz` | ✅ **No necesario** | El warning EX0210 es falso positivo; el diseño funciona |
| Medir uso de RAM por el monitor | ⏳ Pendiente | Saber cuánta RAM queda para juegos |

**Entregable:** diseño actual funcionando con relojes verificados.
**Criterio de éxito:** compila con Gowin y el bitstream funciona (✅ cumplido).

> **Nota:** no se modifica el IP de la PLL. El flujo actual (compilar con Gowin,
generar bitstream, programar) funciona correctamente. Documentar el desajuste
`.ipc`/`.vhd` es suficiente (ver R-02).

---

### Fase 1 — Timing, PLL y TMDS (EL VEREDICTO) ✅ COMPLETADA

**Objetivo:** señal de vídeo estable en pantalla. **Es la fase que valida o descarta
el proyecto.** → **VALIDADO**

| Tarea | Detalle | Estado |
|-------|---------|--------|
| Pixel clock | 27 MHz (cristal directo, sin PLL) | ✅ |
| Reloj TMDS | 135 MHz (PLL ×5) | ✅ |
| Contadores H/V | 720×480@60 (858 × 525) | ✅ |
| Codificador TMDS ×3 | `tmds_encoder_2` (open source) | ✅ |
| Serializador | `OSER10` (primitiva nativa) | ✅ |
| Buffers diferenciales | `ELVDS_OBUF` (primitiva nativa) | ✅ |
| Patrón de prueba | Barras de color de 8 franjas | ✅ **VISIBLE** |

**Resultado:** barras de color estables en el monitor. Pipeline completo de vídeo
funcional (relojes, timing, TMDS, serialización, salida diferencial).

**Implementación:** se adoptó el enfoque del proyecto `atari-2600` (mismo Tang Nano
9K), que resultó ser la vía correcta frente al IP cifrado `DVI_TX` de Gowin:

| Pieza | Origen |
|-------|--------|
| `tmds_encoder_2.vhd` | Open source (Furkan Cayci, 2018) |
| `hdmi_impl.vhd` / `hdmi_module.vhd` | Proyecto atari-2600 |
| `clk_27x5.vhd` | Proyecto atari-2600 |
| `video_test.vhd` | Nuevo (timing + barras) |

**Coste real medido:** +102 LUTs (3.323 → 3.425), 0 BSRAM, 1 PLL, 3 `OSER10`.

**Hallazgo clave sobre el timing:** el cristal de 27 MHz coincide EXACTAMENTE con
el modo 720×480@60 (858 × 525 × 60 = 27.027.000 Hz), por lo que no se necesita PLL
para el pixel clock. Un intento previo con 640×480 (800 × 525) daba 64,3 Hz y el
monitor lo rechazaba como "modo no compatible".

**Hallazgo sobre el `.cst`:** los pares TMDS se declaran con `IO_LOC` (P,N) y
`IO_PORT` **sin** `IO_TYPE`; el tipo `LVCMOS33D` (diferencial) lo infiere la
primitiva `ELVDS_OBUF`. Declarar `IO_TYPE=LVCMOS33` produce el error `CT1136`
(conflicto de `BANK_VCCIO`).

**Pendiente de esta fase:** verificar el riesgo R-01 (ruido de audio con TMDS activo).

---

### Fase 2 — Shifter + paleta ✅ COMPLETADA

**Objetivo:** sustituir las barras de color por el motor de tiles.

| Tarea | Detalle | Estado |
|-------|---------|--------|
| Geometría lógica | 360×240 (45×30 celdas) | ✅ |
| Escalado ×2 | Truncar un bit | ✅ |
| Fetch de patrón | 2bpp planar | ✅ |
| Paleta | 4 paletas × 4 colores | ✅ |
| Tiles hardcoded | 4 patrones de prueba | ✅ **VISIBLES** |

**Resultado:** los 4 patrones se ven en pantalla con sus colores correctos,
repetidos a lo ancho y a lo alto. El pipeline de tiles funciona.

**Implementación:** `src/hdmi/video_core.vhd`

**Coste real medido:** +180 LUTs (3.425 → 3.605). Acumulado: 3.605/8.640 (42%).

**Diseño del pipeline:** se abandonó el shifter secuencial (latencia ambigua, fuente
de bugs de alineación) en favor de **extracción directa del bit** a partir de
`x_in_tile`. Latencia fija de 2 ciclos, imposible de desalinear.

**Defecto de alineación — RESUELTO:**

> La imagen aparecía desplazada ~1,5 columnas respecto a la ventana visible.
> **Solución adoptada:** zona útil de **640×480 centrada** con **40 px de margen
> a cada lado** pintados con `BG_COLOR`. El margen absorbe el error de
> alineación en ambas direcciones, de modo que los bordes de la zona útil
> nunca se cortan. La geometría pasa a **40 columnas** (320 px lógicos ×2).
>
> Verificado en hardware: 40 columnas completas, sin cortes.

**Coste final de la fase:** +207 LUTs (3.425 → 3.632). Acumulado: 3.632/8.640 (43%).

**Siguiente:** Fase 3 (tilemap y tileset en BSRAM, 192 patrones).

---

### Fase 3 — Tilemap y tileset en BSRAM ✅ COMPLETADA

**Objetivo:** un mapa estático de 40×30 en pantalla, leído desde BSRAM.

| Tarea | Detalle | Estado |
|-------|---------|--------|
| VRAM en BSRAM (SDPB) | Puerto A escritura, puerto B lectura | ✅ |
| Fetch de tilemap | Índice de celda por píxel | ✅ |
| Fetch de patrones | 2bpp planar (2 planos en 16 bits) | ✅ |
| Atributos | Paleta por celda (4 bits) | ✅ |
| Pipeline de fetch | 2 etapas, latencia fija, sin FSM | ✅ |
| Síntesis | 3.630 LUT, 23/26 BSRAM | ✅ |
| **Validación visual en hardware** | Mismos 4 patrones que la Fase 2 | ✅ **VISIBLE** |

**Resultado:** los 4 patrones de la Fase 2 (damero verde, marco calipso, diagonal
amarillo claro, sólido) se ven en pantalla **leídos de la BSRAM** como tiles reales sobre
un tilemap 40×30, en franjas verticales de 8 columnas, hasta el fondo de la pantalla,
con los 40 px de margen azul a cada lado. El motor de tiles funciona.

**Vídeo anterior (framebuffer 1bpp):** durante la depuración se usó temporalmente un
framebuffer de píxeles 1bpp que consumía 26/26 BSRAM. Era una herramienta de diagnóstico,
**no** el producto. Se ha retirado: el modelo definitivo es tiles, no framebuffer.

#### Arquitectura del motor de tiles

**VRAM (`src/hdmi/video_vram.vhd`)** — tres arreglos independientes en SDPB:

| Arreglo | Tamaño | Uso | BSRAM |
|---------|--------|-----|-------|
| `tilemap` | 2048×8 | 40×30 índices de patrón | 1 |
| `attr` | 2048×8 | 40×30 atributos (paleta+flips) | 1 |
| `pattern` | 2048×16 | 192 patrones × 8 filas | 2 |
| **Total** | | | **4** |

**Pipeline de fetch (`src/hdmi/video_core.vhd`)** — latencia fija de 2 ciclos:

```
ciclo n-2 : cell_addr = celda de x0(n-2)  ->  tilemap + attr   (SDPB A)
ciclo n-1 : tile_dout = tile[celda]       ->  pat_addr          (SDPB B)
ciclo n   : pat_dout  = patrón del tile   ->  pixel             (salida)
```

La salida se alinea retrasando 2 ciclos el índice de bit (`bitidx2`), el margen
(`margen2`) y las sincronías (`hs2/vs2/de2`). El color de celda (`attr_d1`) se retrasa
solo 1 ciclo, porque la BSRAM ya entrega su salida registrada.

**Esta es la técnica que resolvió el bloqueo de las fases anteriores:** siempre se
presenta **una dirección por ciclo**, calculada directamente de la posición actual, y se
**retrasa la salida**; en lugar de encadenar una máquina de estados con esperas. El
pipeline es imposible de desalinear.

**Consecuencia geométrica:** el resultado es un desplazamiento de **1 píxel lógico**
hacia la derecha (1 ciclo de reloj de píxel), absorbido por los 40 px de margen. **No hay
desplazamiento vertical.** Ver §2, nota de alineación de la Fase 2.

**Formato de patrón almacenado:** `pat_arr(dir)` es una palabra de 16 bits = el "par de
planos" de una fila: `(15:8)` = plano 1, `(7:0)` = plano 0. Dirección = `tile*8 + fila`.
Así el plano 0 y el plano 1 de una misma fila se leen en **una sola** lectura de BSRAM,
en lugar de dos encadenadas (que era la fuente del bug de latencia). El coste es 1 bloque
BSRAM extra (16 bits de ancho), de ahí 2 bloques para los patrones.

**Direcciones a 11 bits:** el tilemap/atributos usan 1200 de 2048 posiciones y los
patrones 1536 de 2048. **Lección aplicada:** ninguna dirección ni contador debe quedar
corto (el bug del "corte en fila 25" fue un contador de 13 bits desbordado en 8192).

**Coste real medido:** 3.588 → 3.630 LUTs (+42). Acumulado: 3.630/8.640 (43%).
**BSRAM:** 26/26 → **23/26**. El framebuffer 1bpp consumía los 26 bloques; el motor de
tiles deja **3 bloques libres** (6 KB) para sprites/OAM y el modo bitmap.

**Siguiente:** validar en hardware y pasar a la Fase 4 (mapeo de memoria).

---

### Fase 4 — Mapeo de memoria: el CPU controla la VRAM ✅ COMPLETADA

**Objetivo:** el CPU escribe VRAM y se ve en pantalla. → **VALIDADO**

| Tarea | Detalle | Estado |
|-------|---------|--------|
| Bus CPU→VRAM | Registros `$D800`/`$D801`/`$D802` (Opción B) | ✅ |
| **Sincronizar el `we`** | Doble flop del toggle `write_req` (mismo que el SID) | ✅ |
| Rutina de prueba | ROM propia que llena patrones + tilemap + atributos | ✅ |
| **Validación en hardware** | Los 4 patrones se ven, dibujados por el CPU | ✅ **VISIBLE** |
| vblank en `$D806` | Bit de status | ⏳ pospuesto |
| NMI | Para sincronizar volcados | ⏳ pospuesto |

**Resultado:** el CPU escribe la VRAM a través de los registros y el motor de
video muestra el resultado. La imagen de la Fase 3 ahora la genera **el 6502**,
no el bloque de inicialización del FPGA.

**Implementación:** `src/hdmi/video_bus.vhd` (nuevo) + puertos de escritura en
`video_core.vhd` + instancia en `Board.vhd`.

#### Diseño del bus (Opción B — registros indirectos)

El CPU controla la VRAM por tres registros en `$D800`:

| Registro | Dirección | Uso |
|----------|-----------|-----|
| `VID_ADDR_LO` | `$D800` | byte bajo de la dirección de VRAM |
| `VID_ADDR_HI` | `$D801` | area (bits 7:6) + pat_hi (bit 5) + dir alta (bits 2:0) |
| `VID_DATA` | `$D802` | dato; al escribir se dispara la escritura real |

- **`area`**: `00`=tilemap, `01`=atributos, `10`=patrones
- **`pat_hi`** (solo patrones): `0`=plano 0 (byte bajo de la palabra de 16 bits),
  `1`=plano 1 (byte alto). Los patrones se escriben en dos `VID_DATA` seguidos.

**Cruce de dominio (RNF-01):** el `we` del CPU se captura en `clk_sys` como un
*toggle* y se sincroniza por doble flop al dominio `clk_vid` (27 MHz), donde se
convierte en un pulso de 1 ciclo. Direcciones y datos quedan asentados en
registros del CPU: **solo el pulso cruza**. Es exactamente el patrón del SID.

**Detalle clave aprendido:** la escritura del CPU se registra en el **mismo flanco**
en que se activa el enable de escritura de la VRAM, sin registros intermedios que
introduzcan carreras de un ciclo. La BSRAM de vídeo usa un único reloj (`clk_pixel`)
en ambos puertos, igual que el Atari-2600.

**Programa de prueba:** `src/asm/video_test.asm`, ensamblado con `cc65`
(`ca65`/`ld65`) y convertido a `rom.vhd` con `src/asm/gen_rom.py`. El `rom.vhd`
actual es la ROM de prueba; el monitor original está respaldado en
`src/rom - monitor.vhd`.

**Coste real medido:** 3.630 → 3.681 LUTs (+51). Acumulado: 3.681/8.640 (43%).
**BSRAM:** 23/26 → 24/26 (el bloque extra del buffer de patrones de 16 bits).

**Pendiente (pospuesto a conveniencia):**
- `STATUS` con bit de vblank (`$D806`) para que el juego sepa cuándo es seguro
  volcar la VRAM sin artefactos.
- NMI de vblank.
- Escribir VRAM **durante** el barrido visible y verificar que el motor maneja la
  colisión (hoy el volcado de test ocurre al arrancar, fuera de conflicto real).

**Siguiente:** Fase 5 (sprites y OAM).

---

### Fase 5 — Sprites y OAM ✅ COMPLETADA

**Objetivo:** sprite sobre fondo con transparencia y prioridad. → **VALIDADO**

| Tarea | Estado |
|-------|--------|
| OAM en registros (32 sprites × 4 B) | ✅ |
| Line buffer (8 sprites por línea) | ✅ |
| Transparencia (color 0) | ✅ |
| Multicolor (4 colores por sprite, 2bpp) | ✅ |
| Paleta de sprites independiente del fondo | ✅ |
| CPU define patrones de sprite (2 planos) | ✅ |
| Color 0 del fondo transparente (modelo NES) | ✅ |
| PRIO (sprite delante/detrás del fondo) | ✅ |
| STATUS: VBLANK + SPRITE_OVERFLOW | ✅ |
| **Flip X/Y** | ✅ **completado** |
| HIT (colisión de píxeles) | ❌ **descartado por coste** (ver §5.4) |

**Resultado:** sprites de 8×8 multicolor con transparencia, paleta propia, movimiento por
CPU, prioridad configurable y detección de overflow. Los objetos de 16×16 se componen
con 4 sprites de 8×8. Validado en hardware con pruebas de VBLANK y OVERFLOW.

**Entregable cumplido:** sprites moviéndose sobre el escenario, con transparencia y
prioridad, y un muñeco 16×16 compuesto que pasa delante/detrás de una casa.

#### Arquitectura de sprites

**OAM (`video_core.vhd`)** — en **registros** (no BSRAM, ahorra un bloque):

| Campo | Bytes |
|-------|-------|
| 32 sprites × 4 bytes | X, Y, TILE, FLAGS |

**FLAGS (byte 3):**

```
 bit 7   bit 6   bit 5   bit 4   bit 3..0
 FLIP_Y  FLIP_X  PRIO    -       PALETA
```

**Line buffer** — 8 sprites por línea (`NSL = 8`), en registros. Dos fases:

1. **Blank** (`h_cnt` 0..31): barrer los 32 sprites del OAM, guardar los que cruzan
   la línea actual (X, tile, paleta, prio, fila).
2. **Visible**: recorrer el buffer y elegir el primer sprite (menor índice) que cubre
   el píxel actual.

**Lección crítica (bug resuelto):** las entradas del buffer NO usadas conservaban datos
 de la línea anterior y se dibujaban como fantasmas ("piernas estiradas"). La Fase 2
 debe considerar **solo las `lb_n` entradas válidas** y el buffer debe **limpiarse** al
 iniciar cada línea.

**Dirección de patrones de sprite:** banco propio (`spr_arr`, 128×16, 1 bloque BSRAM),
separado del banco de fondo. Dirección = `sprite*8 + fila`.

**Colores:** 2bpp planar, igual que el fondo. El color se obtiene de la paleta de
sprite (`SPR_PALETTE`, 4 paletas × 4 colores). El color 0 es **transparente**.

**Flips X/Y (completado):** el line buffer guarda `flipx`/`flipy` por entrada.
FLIP_Y invierte la fila al llenar el buffer (`7 - row`); FLIP_X invierte el índice
horizontal al extraer el píxel (`7 - idx`). Coste: ~110 LUTs.

> **Bug resuelto (importante):** los sprites cuyo `x + 8` cruzaba 256
desaparecían. Causa: `unsigned(lb_x) + 8` se calculaba en **8 bits** y se truncaba
(250+8 → 2). Solución: extender a **9 bits** antes de sumar. Es el mismo tipo de
bug que el de `x0_log` (siempre 9 bits, 0..319).

#### Prioridad de capas (color final)

```
1. margen                       -> BG_COLOR
2. sprite PRIO=0 activo         -> sprite (delante del fondo)
3. fondo visible (color != 0)   -> fondo
4. sprite PRIO=1 activo         -> sprite (detrás del fondo, en los huecos)
5. nada                         -> BG_COLOR
```

El **color 0 del fondo es transparente** (modelo NES): donde el tile no dibuja color,
se ve un sprite de detrás o el `BG_COLOR`.

#### Registro STATUS ($D803, lectura)

| Bit | Campo | Descripción |
|-----|-------|-------------|
| 7 | `VBLANK` | 1 = en vblank (seguro escribir VRAM) |
| 6 | `SPRITE_OVERFLOW` | 1 = hubo más de 8 sprites en una línea |
| 5..0 | reservado | |

- **VBLANK**: directo de `v_cnt`.
- **OVERFLOW**: se recalcula en cada línea (no sticky, no depende de la lectura).

#### Herramientas de dibujo

Los sprites y tiles NO se dibujan a mano en bytes. Se definen con **arte ASCII** y se
convierten automáticamente:

- `src/asm/mk_sprite.py`: sprite 16×16 → 4 cuadrantes 8×8 (2 planos).
- `src/asm/mk_tiles.py`: tiles y sprites genéricos (2 planos).

Caracteres: `.`=transparente, `1`/`2`/`3`=colores.

#### Coste real medido

| Hito | LUTs | BSRAM |
|------|------|-------|
| Fase 4 (CPU→VRAM) | 3.681 (43%) | 24/26 |
| **Fase 5 (sprites + line buffer + STATUS)** | **~4.500 (53%)** | **25/26** |

El sistema de sprites costó ~+800 LUTs y +1 bloque BSRAM (banco de patrones de sprite).

#### Hallazgos de la fase

1. **La BSRAM se agotó** al usar un segundo puerto de lectura de patrones (`pat2`,
   duplicaba 2 bloques). Solución: banco de patrones de sprite propio y pequeño.
2. **El OAM en registros** evita gastar un bloque BSRAM (solo 64-128 bytes).
3. **El hit flag de hardware NO cabe**: comparar todos los pares de 32 sprites pide
   >15.000 LUTs (el chip tiene 8.640). La colisión se hace por **software**.
4. **La prioridad por índice de OAM** funciona de serie (menor índice gana entre
   sprites con el mismo PRIO).

---

### Fase 6 — Scroll y split de raster ✅ COMPLETADA (horizontal y vertical)

**Objetivo:** scroll fluido. → **VALIDADO** (horizontal y vertical, con envoltura)

| Tarea | Estado |
|-------|--------|
| Registros de scroll X/Y (`$D804`–`$D807`) | ✅ |
| `x0_world = x0_log + scroll_x` / `y0_world = y0_log + scroll_y` | ✅ |
| Captura del scroll al inicio de frame | ✅ |
| Envoltura horizontal (`x_cell mod 64`) | ✅ |
| Envoltura vertical (`y_cell mod 32`) | ✅ |
| **Split de raster (scroll por línea)** | ⏳ **movido a Fase 8** |
| Tilemap doble (sin tearing en mapa grande) | ⏳ opcional, requiere BSRAM |

**Entregable cumplido:** demos de paisaje (cielo azul, nubes, árboles, césped,
terreno texturizado) desplazándose suavemente en horizontal (`demo_scroll_h.asm`)
y en vertical (`demo_scroll_v.asm`).

> **Bug de raíz resuelto:** el `video_bus` perdía escrituras (toggle invertido 2×
> por escritura). Ver `06-REPORTE-SCROLL.md`.

---

### Fase 7 — Modo texto ✅ COMPLETADA

**Objetivo:** consola en pantalla. → **VALIDADO**

| Tarea | Estado |
|-------|--------|
| Charset (96 ASCII) en "segunda ROM" BSRAM 1bpp | ✅ |
| Expansión 1bpp→2bpp en la fase de init | ✅ |
| `tile = ASCII` (escribir ASCII en el tilemap) | ✅ |
| Fondo negro por defecto (tilemap = espacios) | ✅ |
| Bit `VIDEO_READY` en STATUS ($D803 bit 4) | ✅ |
| Paleta 0 reservada para texto | ✅ |
| Rutina `put_char` / `put_str` (software) | ✅ (en la prueba) |

**Entregable cumplido:** `HELLO 6502!`, alfabeto completo (mayús + minús),
dígitos y símbolos visibles en pantalla.

**Coste real:** ~+70 LUTs y **+1 bloque BSRAM** (el último libre). Ver
[`04-MODO-TEXTO.md`](04-MODO-TEXTO.md) para el detalle completo.

**Diseño:** el modo texto **no es un modo de vídeo nuevo**. Es el motor de tiles
con una fuente cargada en los patrones: `tilemap[celda] = ASCII`. La expansión de
la fuente la hace **hardware** durante la inicialización (no el CPU), de modo que
no toca el pipeline de render y no requiere handshake de lectura.

**Lección crítica:** un `elsif` mal anidado dejaba `init_done` en 0 para siempre,
reteniendo el puerto A de la VRAM y **descartando silenciosamente todas las
escrituras del CPU**. Síntoma: fondo correcto pero sin texto.

---

### Fase 8 — Split de raster (scroll por línea) ✅ COMPLETADA

**Objetivo:** varias "bandas" con scroll independiente en la misma pantalla
(barra de estado fija, parallax, HUD de texto arriba y abajo).

**Estado:** VALIDADO — 3 bandas (HUD superior fijo + paisaje scrolleando + HUD
inferior fijo).

#### Registros implementados ($D809–$D812)

| Dir | Registro | Descripción |
|-----|----------|-------------|
| `$D809` | `raster_line0` | Fin de la banda SUPERIOR (línea lógica). `$FF` = sin banda top |
| `$D80A/$D80B` | `band2_x` lo/hi | Scroll X de la banda superior |
| `$D80C/$D80D` | `band2_y` lo/hi | Scroll Y de la banda superior |
| `$D80E` | `raster_line1` | Fin de la banda MEDIA. `$FF` = sin banda bottom |
| `$D80F/$D810` | `band3_x` lo/hi | Scroll X de la banda inferior |
| `$D811/$D812` | `band3_y` lo/hi | Scroll Y de la banda inferior |

La banda MEDIA usa el scroll normal (`$D804`/`$D806`).

#### Modelo de funcionamiento

```
final de frame ──> banda 0 (band2_x/y)
    (vline >= raster_line0) ──> banda 1 (scroll normal)
    (vline >= raster_line1) ──> banda 2 (band3_x/y)
```

Las transiciones ocurren en el ULTIMO ciclo de cada línea (`h_cnt = H_TOTAL-1`),
para que el prefetch de BSRAM de la línea siguiente ya use el scroll correcto.

**Coste real:** 4.572 → 4.699 LUTs (**+127 LUTs**). **BSRAM: 0.** DSP: 0.

#### Lección crítica (desfase de fila 0)

El pipeline presenta la celda con un desfase de **+1 fila** en el borde superior
(la fila 0 del tilemap queda "fuera" y todo se corre una fila arriba). Es un
artefacto del prefetch (documentado en `video_core.vhd`, L17-24). **Solución
práctica:** reservar la fila 0 como margen y dibujar el HUD superior en las filas
1-2 (como hacen los sistemas de tiles reales). No requiere lógica extra. La demo
usa `raster_line0 = 24` (banda superior de 3 filas: 0 de margen + 2 de HUD).

---

### Fase 9 — Escalado 2× de sprites ✅ COMPLETADA

**Objetivo:** sprites al doble de tamaño (16×16 y 32×32 efectivos) por hardware.
(La rotación queda descartada: encarece el datapath y no es prioridad.)

**Estado:** VALIDADO — bit 4 de FLAGS (`SCALE2X`) escala el sprite 8×8 a 16×16
en pantalla. La escala es **por sprite de 8×8** con anclaje en la esquina superior
izquierda; un objeto 16×16 a 2× se compone con 4 sprites y paso +16.

| Tarea | Estado |
|-------|--------|
| Bit 4 de FLAGS = `SCALE2X` | ✅ |
| Line buffer: array `lb_scale` + cobertura 16 líneas / 16 px | ✅ |
| Fila del patrón `= (line_y - sy)/2` (con FLIP_Y) | ✅ |
| Índice X del patrón `= sx/2` | ✅ |

**Coste real:** 4.536 → 4.729 LUTs (**+193 LUTs**). **BSRAM: 0.**

> **Bug corregido (borde entre sprites):** la BSRAM de patrones tiene 1 ciclo de
> latencia, pero la Etapa A combinaba `spr_pat_data` (ciclo N-1) con `lb_pick_x`/
> `x0_log` (ciclo N) → en el borde entre sprites distintos se mezclaba un píxel
> del patrón anterior = **línea de 1 px**. Fix: retrasar 1 ciclo `lb_pick_x`,
> `lb_pick_fx`, `lb_pick_scale`, `lb_pick_ok` y `x0_log` (`*_d`). Este bug estaba
> latente también en los sprites compuestos 1×.

> **Bug corregido (píxel fantasma en el borde derecho):** tras el fix anterior
> quedaba una **etapa B** redundante en el pipeline del sprite que retrasaba el
> píxel de sprite **1 ciclo de más** respecto al fondo (sprite en N+3, fondo en
> N+2). El sprite se pintaba 1 px desplazado y asomaba un píxel de columna
> equivocada en su borde derecho (visible sobre todo con contenido en la
> columna 7 y en la junta de sprites compuestos). Fix: **eliminar la etapa B**
> (`spr_active1`/`spr_pixcode1`); el mux final usa la salida de la Etapa A
> (`spr_active`/`spr_pixcode`) y la paleta `spr_pal_b`, que ya llega a N+2, igual
> que el fondo. Sprite y fondo quedan alineados. El manual (§6) no cambia porque
> era un detalle interno de render, no de interfaz.

---

### Fase 10 — Colisión sprite↔tile sólido ✅ COMPLETADA (punto = centro)

**Objetivo:** que el hardware detecte cuándo un sprite entra en una celda “sólida”.

**Diseño:**
- **Bit 4 del byte de atributo** del fondo = `SOLIDO`.
- Una vez por frame (durante el **blanking vertical**), el hardware recorre los
  **32 sprites**, calcula la celda del **centro** de cada uno (`(sx+4)/8`, `(sy+4)/8`)
  y lee el bit 4 de su atributo.
- **Resultado global:** bit 5 de `$D803` (`SOLID_HIT`) = 1 si cualquier sprite tocó
  un tile sólido ese frame (no sticky; se recalcula cada frame).

**Coste real:** 4.729 → 5.163 LUTs (**+434 LUTs**). **BSRAM: 0.**

> **Nota:** el puerto B de atributos se multiplexa (`attr_rd_addr`): la celda del
> fondo el resto del tiempo, la celda del sprite durante el barrido de colisión.
> El flag se lee con 1 frame de latencia respecto a la posición (normal en juegos).

> **Nota:** el puerto B de atributos se multiplexa (`attr_rd_addr`): la celda del
> fondo el resto del tiempo, la celda del sprite durante el barrido de colisión.
> El flag se lee con 1 frame de latencia respecto a la posición (normal en juegos).

---

### Fase 11 — Punto de colisión configurable + auto-escala (OAM 5 bytes) ✅ COMPLETADA

**Objetivo:** que el punto de colisión sprite↔tile sea **configurable por sprite** y
**cambiable en tiempo real** (p. ej. borde derecho al ir a la derecha, izquierdo al
ir a la izquierda), **sin que el software se preocupe por la escala** 1×/2×.

**Diseño:**
- **OAM ampliado de 4 a 5 bytes por sprite** (32 × 5 = **160 bytes**).
  - +0 X, +1 Y, +2 TILE, +3 FLAGS, **+4 COLL_POINT**.
- **COLL_POINT**: `bits 2:0 = dx`, `bits 5:3 = dy` (**offset libre 0-7**).
- **Auto-escala C+ (en hardware):** el software **siempre usa 0-7**; si el sprite es
  2×, el hardware escala el offset: `dx 0..6 → dx*2`, `dx=7 → 15`. Así `dx=0/4/7`
  dan **borde izquierdo / centro / borde derecho** tanto en 1× como en 2×.
  El software **no necesita saber la escala**.
- El CPU escribe COLL_POINT como cualquier byte de OAM (índice `sprite*5 + 4`).

**Ejemplos de offset (idénticos para 1× y 2×):**

| Punto | dx, dy | Byte |
|-------|--------|------|
| centro | 4,4 | `$24` |
| pie | 4,7 | `$3C` |
| cabeza | 4,0 | `$04` |
| borde izq | 0,4 | `$20` |
| borde der | 7,4 | `$27` |

**Coste real:** 5.163 → 5.986 LUTs (estructura OAM 5 bytes) → **+240 LUTs** por la
auto-escala C+ → **6.224 (72%)**. **BSRAM: 0.**

> **Nota de latencia:** la colisión se recalcula una vez por frame (blanking), así
> que reaccionar al flag tiene **1 frame de latencia** → el sprite puede “pasarse”
> ~1 px al chocar. **En el hardware no se compensa**; el juego lo resuelve con un
> **push-out** de 1 px al rebotar (estándar en juegos). El hardware solo responde
> “el punto tocó sólido” (sí/no).

#### Colisión sprite↔sprite → POR SOFTWARE

Se evaluó hacer la colisión sprite↔sprite por hardware (2 detectores vs 8-14
objetivos). **No cabe**: el acceso indexado al OAM (`oam_reg(índice variable)`) se
sintetiza como **muxes enormes**, y un segundo barrido duplicaba esos muxes
(~+2.200 celdas, excediendo el dispositivo).

**Decisión:** la colisión **sprite↔sprite se hace por software** (comparar X/Y de los
objetos en RAM). El hardware solo aporta la colisión **sprite↔tile** (flag global
`SOLID_HIT`), y el software **deduce cuál sprite chocó** comparando su posición.

---

### Fase 12 — Coordenada X de sprites de 9 bits ✅ COMPLETADA

**Objetivo:** que los sprites puedan situarse en **todo el ancho** de la pantalla
(320 px), no solo en X ≤ 255.

**Problema:** el byte X del OAM es de 8 bits (0-255); la pantalla mide 320 px, así
que la mitad derecha (256-319) era inalcanzable para sprites.

**Diseño:**
- **X = 9 bits** (0-511). El **bit 8** se guarda en el **bit 2 de FLAGS** (libre).
- Afecta a: render de sprites, line buffer (`lb_x` de 9 bits) y colisión.
- El software mantiene X en 9 bits (2 bytes) y escribe el bit 8 en FLAGS.

**Coste real:** 6.409 celdas (**74%**), +185 celdas respecto a la versión previa.
**BSRAM: 0.**

---

## 3. Resumen del plan

### 3.1 Recursos REALES medidos (no estimados)

| Hito | LUTs | BSRAM | DSP | Fecha |
|------|------|-------|-----|-------|
| Base (sin vídeo) | 3.323 | 20/26 | 2 | — |
| Fase 1 (TMDS) | 3.425 | 20/26 | 2 | — |
| Fase 2 (tiles constantes) | 3.632 | 20/26 | 2 | — |
| Framebuffer 1bpp (diagnóstico, retirado) | 3.588 | **26/26** | 2 | — |
| **Fase 3 (tiles desde BSRAM)** | **3.630** | **23/26** | **2** | 2026-10-01 |
| **Fase 4 (CPU → VRAM)** | **3.681** | **24/26** | **2** | 2026-10-02 |
| **Fase 5 (sprites + line buffer + STATUS)** | **~4.500** | **25/26** | **2** | 2026-10-02 |
| **Fase 5 (flips X/Y + fix 9 bits)** | **4.610** | **25/26** | **2** | 2026-10-02 |
| **Fase 6 (scroll H/V)** | **4.572** | **26/26** | **2** | 2026-10-03 |
| **Fase 7 (fuente BSRAM + expansión + VIDEO_READY)** | **4.523** | **26/26** | **2** | 2026-10-02 |
| **Fase 8 (split de raster 3 bandas)** | **4.699** | **26/26** | **2** | 2026-10-03 |
| **Fase 9 (escalado 2×) + fix borde sprites** | **4.729** | **26/26** | **2** | 2026-10-03 |
| **Fase 10 (colisión sprite↔tile, punto centro)** | **5.163** | **26/26** | **2** | 2026-10-03 |
| **Fase 11 (COLL_POINT + OAM 5 bytes + auto-escala C+)** | **6.224 (72%)** | **26/26** | **2** | 2026-10-03 |
| **Fase 12 (X de sprites de 9 bits)** | **6.409 (74%)** | **26/26** | **2** | 2026-10-03 |

**Margen actual: ~2.231 celdas (26%) y 0 bloques BSRAM libres (agotada).**

### 3.2 Estimación de fases restantes

**Advertencia:** las cifras siguientes son estimaciones. Sintetizar al final de cada fase
y sustituirlas por las reales de §3.1.

| Fase | Contenido | LUTs acumuladas | BSRAM | Riesgo |
|------|-----------|-----------------|-------|--------|
| **8** | **Split de raster (3 bandas)** | **4.699 (real)** | **26/26** | **Bajo** ✅ |
| **9** | **Escalado 2× de sprites** | **4.729 (real)** | **26/26** | **Bajo** ✅ |
| **10** | **Colisión sprite↔tile sólido (centro)** | **5.163 (real)** | **26/26** | **Bajo** ✅ |
| — | Colisión sprite↔sprite (contra 1-2 objetivos) | +900–1.900 LUT | 26/26 | Medio |
| — | OAM 32→64 sprites | +600–900 LUT | 26/26 | Medio |
| — | Line buffer 8→16 | +500–600 LUT | 26/26 | Medio |
| — | Punto de colisión configurable (OAM 5 bytes) | +50-100 LUT | 26/26 | Bajo |
| A | **Análisis del modo bitmap (al final)** | **ver `05-ANALISIS-BITMAP.md`** | **repartir BSRAM** | **Alto** |

**Margen actual: ~3.477 LUTs (40%).**

> Las estimaciones se han rebajado tras medir que el motor de tiles cuesta solo +42 LUTs
> (la mayor parte del coste ya estaba en el pipeline de la Fase 2).
>
> **El recurso crítico es la BSRAM, no las LUTs.** El modo bitmap o el tilemap doble
> (los que necesitan BSRAM) son los únicos que pueden no caber: compiten por bloques
> ya ocupados. La rotación de sprites queda **descartada**; el escalado 2× no usa BSRAM.

---

## 4. Criterios de parada

El plan puede detenerse en cualquier fase con un sistema funcional:

| Punto de parada | Sistema resultante |
|-----------------|--------------------|
| Tras fase 1 | Salida de vídeo (sin contenido útil) |
| Tras fase 2 | Motor de tiles con patrones fijos |
| Tras fase 3 | **Visualizador de imágenes estáticas** (tiles desde BSRAM) ✅ |
| **Tras fase 4** | **Sistema programable completo** (mínimo para juegos simples) ✅ |
| **Tras fase 5** | **Sistema de juegos funcional** (objetivo principal) ✅ |
| **Tras fase 6** | **Juegos con scroll** (H/V) ✅ |
| Tras fase 7 | Juegos con scroll + consola de texto ✅ |
| **Tras fase 8** | **Juegos con HUD fijo y parallax** (split de raster) ✅ |
| **Tras fase 9** | Sistema de juegos + sprites escalados 2× ✅ |
| **Tras fase 10** | **Sistema de juegos con colisión contra tiles** (plataformas) ✅ |
| (Análisis A) | Sistema de juegos + herramientas de dibujo (bitmap) |

**El objetivo mínimo viable es la fase 5.** A partir de ahí ya se pueden desarrollar
juegos reales. Las fases 6–10 añaden capacidades de juego (scroll, texto, split de
raster, escalado, colisión).

---

## 5. Reglas de implementación (no negociables)

### 5.1 Sincronización entre dominios de reloj

```vhdl
-- TODO cruce de dominio (CPU 6,75 MHz → vídeo 25,175 MHz) requiere doble flop:
process(clk_pixel)
begin
    if rising_edge(clk_pixel) then
        sig_meta <= sig_cpu;   -- etapa 1 (metaestabilidad)
        sig_sync <= sig_meta;  -- etapa 2 (estable)
    end if;
end process;
```

**Prohibido:** decodificadores de dirección combinacionales que generen señales de
habilitación hacia el motor de vídeo. Es el bug que tiene hoy el SID.

### 5.2 Escritura a VRAM

- Preferentemente **en vblank**.
- Si se escribe fuera de vblank, el bypass de escritura de la PDP debe gestionar
  la colisión de misma dirección.

### 5.3 Verificación

- Sintetizar **al final de cada fase**.
- Registrar las cifras reales en este documento (actualizar §3).
- Si el consumo real supera la estimación en más del 50%, **revisar el plan** antes
  de continuar.

---

## 6. Decisiones pendientes

| # | Decisión | Opciones | Estado |
|---|----------|----------|--------|
| D-01 | **Salida de vídeo** | HDMI (pines reservados, +LUTs, +ruido) vs. VGA | ✅ **HDMI** (fase 1) |
| D-02 | Resolución lógica | 320×240 (2× exacto) vs. 256×240 | ✅ **320×240** |
| D-03 | Tilemap | Simple vs. doble (scroll sin tearing) | ⏳ **opcional** — doble requiere +1 BSRAM (agotada) |
| D-04 | Patrones | Todo en VRAM vs. base en ROM + dinámicos | ✅ **todo en VRAM** |
| D-05 | Tiles | 256 @ 2bpp vs. 128 | ✅ **256** (fuente ocupa `$20..$7F`) |
| D-06 | Vídeo y RAM de juego | ¿VRAM en `$4000` o RAM extra? | ✅ **puerto indirecto `$D800`** (opción B) |
| D-07 | Código del juego | En ROM vs. cargado de SD a RAM | ✅ **SD → RAM** (monitor en ROM) |
| D-08 | **Fuente de caracteres** | ROM CPU vs. RAM del juego vs. BSRAM | ✅ **BSRAM** (último bloque, Fase 7) |
| D-09 | **Rotación de sprites** | ¿Implementar o no? | ✅ **DESCARTADA** (no prioritaria) |
| D-10 | **Escalado de sprites** | ¿2× por hardware? | ✅ **SÍ — Fase 9** |
| D-11 | **Split de raster** | ¿Implementar? | ✅ **SÍ — Fase 8** |
| D-12 | **Modo bitmap** | Resolución/profundidad | ❌ **DESCARTADO** (BSRAM agotada; ver §7.1) |

---

## 7. Cierre del proyecto (módulo de vídeo)

**Estado: COMPLETO.** El core de vídeo está implementado, validado en hardware y
documentado (Fases 1–12). El objetivo del proyecto —un subsistema de vídeo para
juegos retro sin eliminar ningún módulo— está **cumplido**.

**Capacidades finales:**

| Capacidad | Fase |
|-----------|------|
| Salida HDMI/TMDS 720×480 | 1 |
| Motor de tiles 2bpp + tilemap | 2–3 |
| CPU → VRAM (puerto indirecto `$D800`) | 4 |
| Sprites + line buffer + PRIO + flips X/Y | 5 |
| Scroll H/V (mapa 64×32, stride potencia de 2) | 6 |
| Modo texto (fuente C64 + librería de consola) | 7 |
| Split de raster (3 bandas, HUD fijo) | 8 |
| Lectura fiable de `$D803` | 8.1 |
| Escalado 2× de sprites | 9 |
| Colisión sprite↔tile sólido | 10 |
| Punto de colisión configurable + auto-escala 1×/2× | 11 |
| Coordenada X de sprites de 9 bits | 12 |

**Recursos finales:** ~6.409 celdas de lógica (74%), BSRAM 26/26, DSP 2/10.

**Manual de programación:** `07-MANUAL-PROGRAMACION.md`.

### 7.1 Fuera de alcance (descartado)

Se descarta explícitamente, por decisión, el siguiente trabajo:

| Tema | Motivo |
|------|--------|
| Colisión sprite↔sprite por hardware | No cabe (muxes del OAM). Se hace por software. |
| Modo bitmap | Requiere repartir BSRAM (agotada). |
| Tilemap doble | Requiere +1 BSRAM (agotada). |
| Rotación de sprites por hardware | Coste desproporcionado; no prioritaria. |
| Color de texto por celda | `attr_arr` ya lo permite; se hará en software si se necesita. |
| Integración con el monitor (SD→RAM) | Fuera del alcance del módulo de vídeo. |
| Medición del SID con TMDS activo | Fuera del alcance del módulo de vídeo. |
| Colchón vertical anti-overscan | El eje Y no tiene margen (las 30 filas las dibuja el hardware pegadas al límite visible). Compensarlo por hardware exigiría recortar filas útiles o cambiar el timing. Se documenta y se deja al software (no usar filas 0 y 29). |

**El módulo de vídeo se considera cerrado.**

**Descartado:** rotación de sprites; colchón vertical anti-overscan.

> **Nota (overscan):** el eje X sí tiene margen (20 px lógicos por lado, con clamp),
> pero el **eje Y no**: la zona visible de 480 líneas físicas = 240 lógicos = 30 filas
> de tile justas. Por eso las filas **0 y 29** caen en los bordes absolutos y pueden
> recortarse según el monitor. No es un fallo de diseño sino una decisión consciente
> (recortar filas útiles o tocar el timing no compensa). Convención: **contenido entre
> las filas 1 y 28**; las filas 0 y 29 como margen. Ver `07-MANUAL-PROGRAMACION.md` §3.

---

## 8. Notas sobre el documento

- Las cifras de recursos base provienen de una síntesis real ejecutada sobre el
  diseño actual: `impl/pnr/6502_board_v3.rpt.txt`.
- Las estimaciones de las fases de vídeo son **aproximadas** y deben corregirse
  con síntesis reales.
- Este documento se actualiza al final de cada fase.
