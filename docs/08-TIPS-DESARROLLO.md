# Tips de Desarrollo

Cosas importantes a tener en cuenta al **desarrollar** para esta plataforma: tanto
para el **software** (programas 6502 / juegos) como para el **hardware** (VHDL, el
core de vídeo y el resto del sistema).

Este documento es una **lista viva**: se van añadiendo los tropiezos reales para no
repetirlos. No es un manual (ver `07-MANUAL-PROGRAMACION.md`), sino una colección de
**advertencias y atajos** aprendidos en el camino.

---

## Índice

1. [Software 6502 / juegos](#1-software-6502--juegos)
2. [Hardware / VHDL (core de vídeo y sistema)](#2-hardware--vhdl)
3. [Recursos del chip (CLS, BSRAM, etc.)](#3-recursos-del-chip)
4. [Proceso de compilación y flasheo](#4-proceso-de-compilación-y-flasheo)

---

## 1. Software 6502 / juegos

### 1.1 Los sprites NO se apagan solos: hay que borrarlos

**Síntoma:** en pantalla de "GAME OVER" (o al cambiar de escena) siguen apareciendo
los sprites de la partida anterior.

**Causa:** el hardware **no borra el OAM** al cambiar de estado. Los 32 sprites
siguen configurados y se dibujan donde estaban.

**Solución:** al terminar la partida (o al cambiar de escena), **borrar los sprites**:

- **Opción 1 — moverlos fuera de pantalla:** poner **Y ≥ 248** en todos (valor que
  deshabilita el sprite). Es lo más barato.
  ```
  ; invalida los 32 sprites
  LDX #0
  @loop:
      LDA #248            ; Y fuera de pantalla
      STA OAM+1,X         ; OAM + sprite*5 + 1 (campo Y)
      ; (avanzar X de 5 en 5 hasta cubrir los 160 bytes)
      ...
  ```
- **Opción 2 — escritura directa a OAM:** recorrer los 160 bytes (`32 × 5`) y poner
  el campo Y a 248.
- **Opción 3 — limpiar la OAM completa** si vas a rehacer la escena de todas formas.

> **Regla general:** si un sprite deja de ser necesario, **explícitamente** ponlo
> fuera de pantalla o borra su entrada. No asumas que el hardware lo hará.

### 1.2 El color 0 del sprite es transparente

El píxel de color 0 de un sprite **no se dibuja** (deja ver el fondo). Es la
transparencia de sprites. No es un bug.

### 1.3 El fondo: color 0 es transparente (no pinta)

En el tile de fondo, el color 0 es **transparente** (modelo NES): donde el fondo
tiene color 0, se ve el **BG_COLOR** o un sprite. Por eso el "fondo liso" del juego
se logra con **BG_COLOR** (entrada 15 de la paleta de fondo), no con un tile de color.

### 1.4 Actualiza en VBLANK, no a mitad de frame

OAM, scroll, paletas y bandas raster se **actualizan en VBLANK**. Cambiarlos a mitad
del visible produce "tearing" (desgarro) o glitches. Espera el bit VBLANK de
`$D803` antes de escribir.

### 1.5 Orden de los sprites = prioridad

El sprite de **menor índice en el OAM** tiene **mayor prioridad** (se dibuja delante).
Cuando dos sprites se solapan, gana el de índice menor. **Ordena el OAM** según lo
que quieras que se vea delante.

> ⚠️ **No hay transparencia entre sprites**: si el sprite de delante tiene un hueco
> (color 0) sobre otro sprite, en ese hueco se ve el **fondo/BG_COLOR**, no el sprite
> de atrás. Esto es una limitación del bitstream actual (ver §2.5). Para solapamientos
> donde importe, dibuja la zona como **un solo sprite compuesto** o usa tiles.

### 1.6 La colisión sprite↔sprite es por software

El hardware **no** detecta colisiones entre sprites. Guarda las X/Y de tus objetos
en RAM y compáralas tú. El hardware solo da:

- flag **global** de colisión sprite↔tile sólido (`SOLID_HIT`, bit 5 de `$D803`),
- flag **por sprite** de colisión con tile sólido (campo COLL del OAM).

### 1.7 No superes 8 sprites por línea

Es un **límite duro del chip**. Con más de 8 sprites cruzando la misma línea
horizontal, se activa `OVERFLOW` (bit 6 de `$D803`) y **algunos no se dibujan**
(parpadeo/pérdida). Si tu juego tiene muchos objetos en una fila, usa **tiles**.

### 1.8 Máximo 64 patrones de sprite

El campo TILE del OAM es de **6 bits** → patrones 0-63. Si necesitas más gráficos,
reutiliza o cambia patrones por escena (recargando la VRAM en el blank o con el setup).

> ⚠️ **Los patrones 0-2 no arrancan vacíos.** El core los inicializa con formas de
> demo (cara, rombo, X), o con ceros si haces un setup `$D816`. **No están
> reservados**: los 64 son utilizables. Si quieres usar 0-2, **escríbelos** con tu
> arte en vez de asumir que están vacíos. Igual pasa con los **tiles de fondo 0-7**.
>
> Las escrituras del CPU se ignoran mientras `init_done='0'` (arranque y setup
> `$D816`), así que **espera `VIDEO_READY`** (bit 4 de `$D803`) antes de escribir.

### 1.8b `SCALE2X` duplica píxeles, no compone cuadrantes

El bit 4 de `FLAGS` escala el sprite a **16×16**, pero leyendo **un único patrón**:
cada fila y columna sale dos veces. **No** lee `TILE+1/+2/+3`, así que no sirve para
armar un dibujo de 16×16 con 4 patrones distintos.

| Quieres | Cómo |
|---|---|
| El mismo dibujo al doble | `SCALE2X=1`, **1** sprite |
| Un dibujo 16×16 distinto | **4** sprites de 8×8, sin `SCALE2X` |

> Si numeras los patrones en pares o cuádruples esperando que `SCALE2X` los componga,
> verás el primer patrón duplicado y el resto sin usar. Detalle en manual §6.2b.

### 1.9 Bordes: no pongas info crítica en filas 0 y 29

Por **overscan** del monitor/TV, las filas superior e inferior pueden recortarse.
Mantén el contenido importante entre las filas **1 y 28**.

### 1.10 Boot: el auto-boot no se repite tras un reset

El monitor usa un **flag en RAM** (`$3FFE-$3FFF`) para no auto-arrancar `BOOT.INI`
más de una vez por sesión. Como **la RAM no se borra con el reset** (botón S1), tras
resetear el monitor **no vuelve a auto-bootear**. Es esperado. Para forzar otro
auto-boot, hay que limpiar ese flag (o reiniciar la placa por completo).

---

## 2. Hardware / VHDL

### 2.1 El "píxel fantasma" en el borde de sprites (ya resuelto)

Histórico: aparecía una **línea de 1 píxel** entre sprites contiguos. Causa: la
BSRAM de patrones de sprite tiene **1 ciclo de latencia**, y la selección del sprite
no estaba retrasada para alinearse. **Solución:** retrasar la selección 1 ciclo
(`lb_pick_*_d`) para alinearla con `spr_pat_data`. Ver commit `41b68ba`. **No volver
a tocar ese pipeline sin cuidado.**

### 2.2 Un solo puerto de lectura en la BSRAM de sprites

`video_vram` es **SDPB** (semi-dual-port): puerto A escribe, puerto B lee, y hay
**un solo** puerto de lectura por banco. Esto limita:
- **una lectura de patrón de sprite por ciclo**,
- por tanto, **no puedes comparar varios sprites en el mismo ciclo**.

Cualquier función que necesite "mirar varios sprites a la vez" (p. ej. transparencia
entre sprites) requiere **guardar copias en registros** durante el blank.

### 2.3 La RAM del CPU NO se borra con el reset

El reset (`rst_n`, botón S1) reinicia **CPU y vídeo**, pero **no toca la RAM**
(`$0000-$3FFF`). Consecuencias:
- Los programas deben **inicializar su RAM** al arrancar si asumen ceros.
- Flags persistentes en RAM **sobreviven** al reset (ver §1.10).

### 2.4 El reset (S1): polaridad y filtro anti-rebote

- `reset_in` (pin 4 = botón S1) tiene **pull-up**: reposo = '1', pulsado = '0'.
- Pasa por un **debounce de 50 ms**: una pulsación **más corta que 50 ms se
  ignora**. Mantén el botón pulsado ~1 s para asegurar el reset.
- La señal `reset` resultante es **activa-baja** y llega a CPU (`A6502.rst` → `not rst`),
  vídeo (`rst_n`), y todos los periféricos.

### 2.5 La transparencia entre sprites NO cabe (límite de CLS)

Intentamos implementar transparencia real entre sprites (que un sprite transparente
deje ver al de atrás, como NES). **No cabe** en el chip:

| Experimento | Resultado |
|---|---|
| Guardar 1 bit de opacidad (8 FF) | ❌ 16 REG unPlaced |
| Transparencia entre 2 sprites (sondeo, +44 CLS) | ✅ compila (99%) |
| Transparencia entre 3 sprites | ❌ 28 REG unPlaced |
| Transparencia entre 2 sprites (funcional) | ❌ 25 REG unPlaced |

**Conclusión:** el chip está al **~98% de CLS**. La transparencia funcional requiere
liberar CLS (SID/timer/periféricos) o bajar `NSL`. Por ahora, se resuelve por
software (§1.5).

### 2.6 CLS es el recurso crítico, no FF ni LUT

Aunque el conteo nominal de FFs parezca holgado, **cada FF y cada LUT viven dentro
de una CLS**. El chip tiene **4320 CLS** y está al **98%**. Por eso:

- No se pueden "inventar" recursos apilando LUTs (una LUT no es un FF fiable).
- Para añadir cualquier función nueva hay que **liberar CLS** de otro módulo.
- El empaquetado **no es lineal**: añadir 8 FF puede costar 16 CLS o desbordar.

### 2.7 "Píxel fantasma" / desalineación de pipeline

El pipeline del fondo tiene **2 etapas** (latencia fija). Cualquier señal nueva que
participe debe **retrasarse los mismos ciclos** (`x0_log_d`, `lb_pick_*_d`,
`spr_pal_a/b`). Errores de alineación → líneas de 1 píxel o colores mal.

### 2.8 VHDL: no se puede indexar el resultado de una expresión

```vhdl
idx := to_integer((x0_log - xp9)(2 downto 0));   -- ❌ ERROR EX4739
```
Asigna a una variable primero:
```vhdl
dxv := x0_log - xp9;
idx := to_integer(dxv(2 downto 0));              -- ✅
```

### 2.9 El tilemap usa stride 64, no 40

La dirección de celda es `fila*64 + col` (mapa 64×32). Usar 40 produce "basura" en
pantalla. Para escribir una fila, avanza de 64 en 64.

### 2.10 Paletas de fondo por defecto

No todas las paletas son iguales: **pal0** color1 = azul, **pal1** = marrón/naranja,
**pal2** = verde, **pal3** entrada15 = BG_COLOR (azul cielo). Para "fondo azul" usa
**pal0** (no pal1, que es marrón).

---

## 3. Recursos del chip

### 3.1 Presupuesto actual (GW1NR-9, Tang Nano 9K)

| Recurso | Uso | Total | Libre |
|---|---|---|---|
| **CLS** | **4203 (98%)** | 4320 | ~117 ⚠️ **crítico** |
| Register (FF) | 4247 (64%) | 6693 | ~2400 |
| LUT | 5713 | ~8640 | — |
| **BSRAM** | **26 (100%)** | 26 | **0** ⚠️ agotada |
| DSP | 2 | 10 | 8 |
| PLL | 1 | 2 | 1 |

**Los dos recursos agotados: CLS (~98%) y BSRAM (100%).**

### 3.2 Dónde hay margen (si algún día hace falta)

- **SID** — es el único módulo con grasa recortable (~909 FF / ~1185 LUT). Quitar el
  **filtro** libera ~167 FF + 282 LUT + 1 DSP + 2 BSRAM, pero **pierdes los efectos
  de filtro** (barridos, resonancia). No rompe las 3 voces.
- **Timer** — si solo usas `delay_us/ms` y `get_micros` (versión *minimal* de la
  librería), puedes recortar TICK (32 bits), el timer programable y la IRQ.
- **NSL** (`video_core.vhd`) — bajar de 8 a 6-7 libera CLS del line buffer, a costa
  de menos sprites por línea.
- **Periféricos** (i2c/uart/spi) — solo si NO los usas (tú sí los usas).

### 3.3 La PSRAM NO es una vía para liberar recursos

La Tang Nano 9K tiene **8 MB de PSRAM embebida** (pines dedicados). Pero:

- **Lenta:** ~12 ciclos por byte (vs 1 de la BSRAM) → **no sirve como VRAM** en tiempo real.
- **Volátil:** arranca vacía → **no sirve como ROM** (no se puede precargar desde el bitstream).
- **Su controlador consume CLS/LUT** → **empeora** el recurso crítico.
- Para el **CPU** sí podría usarse (tiene `enable` = wait-states), pero el balance de
  CLS es negativo si solo mueves los 16 KB actuales.

---

## 4. Proceso de compilación y flasheo

### 4.1 El bitstream viejo es la causa nº 1 de "no funciona"

Si cambias el VHDL pero **el hardware no refleja el cambio**, lo más probable es que
**no hayas reprogramado la FPGA** o estés cargando un `.fs` viejo. Comprueba los
timestamps de `impl/pnr/6502_board_v3.fs` vs los fuentes. **Siempre: compilar Y
REPROGRAMAR.**

### 4.2 Limpia antes de re-sintetizar

Si solo haces *Place & Route* sin *Synthesize*, Gowin puede **reutilizar el netlist
viejo** y medir el diseño anterior. Para cambios de VHDL: **Clean → Synthesize →
Place & Route**.

### 4.3 Señales de WARN de reloj (normales)

```
WARN (TA1132): 'clk_1mhz' was determined to be a clock but was not created
WARN (TA1132): 'clk_81mhz_safe' ...
```
Son **normales** (clocks generados por lógica, no por PLL). No impiden la compilación.

### 4.4 `Failed to place with 'N REG(s) unPlaced'`

Es el error de **recursos agotados** (CLS al límite). No es un bug de sintaxis: el
diseño **no cabe** en el chip. Hay que **liberar CLS** o reducir la función.

### 4.5 Herramientas de ensamblado (referencia rápida)

- **ca65:** `"D:/cc65/bin/ca65.exe" -t none f.asm -o f.o`
- **ld65:** `ld65 -C f.cfg f.o -o f.bin`
- **ROM:** `python gen_rom.py f.bin ../rom.vhd` (desde `src/asm/`)
- `.cfg` estándar: `ZP start=$0010 size=$0030; ROM start=$8000 size=$4000 fillval=$FF`
- ⚠️ **ca65 no acepta `:` como separador de instrucciones** en la misma línea
  (`LDA #15 : STA X` → error). Usa líneas separadas.

---

## Apéndice — Pendientes / ideas aparcadas

- **Transparencia entre sprites:** requiere liberar CLS (ver §2.5). Aparcado.
- **Coprocesador de punto fijo Q16.16** (~1 DSP + ~250-450 LUT): no cabe con CLS al 98%.
- **Audio por HDMI:** factible en teoría (data islands + InfoFrames), pero no cabe
  (CLS + 1 BSRAM). Hoy el audio sale por el DAC PWM (GPIO).
- **Compatibilidad con TV (no monitor):** el core es DVI puro (TMDS sin InfoFrames);
  solo va en monitores. Añadir HDMI real (AVI InfoFrame + audio) no cabe sin liberar.
