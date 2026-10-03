# Reporte — Por qué costó tanto el scroll (Fase 6)

**Proyecto:** fpga-6502-16k
**Fecha:** 2026-10-03
**Estado:** scroll **VALIDADO en horizontal y vertical** (demos de terreno/árboles/nubes)

---

## 1. Resumen ejecutivo

El objetivo era añadir **scroll por hardware** (registros de offset X/Y). Tras muchas
iteraciones, **el scroll se validó**. El esfuerzo destapó varios bugs:

1. **Un bug de raíz en el `video_bus`** que perdía escrituras y enmascaraba todo.
2. **Un bug de rango en VHDL** (`t: range 0 to 3` en vez de `0..7`) que corrompía los
tiles 4-7.
3. **Varios bugs de software** en el programa de prueba.

**Conclusión:** el scroll **funciona** (horizontal, con envoltura). Fue el canal
CPU→VRAM y bugs puntuales los que enmascararon el desplazamiento.

---

## 2. El bug de raíz: escrituras perdidas en `video_bus`

### 2.1 Qué ocurría

El `video_bus` cruza las escrituras del CPU al dominio de vídeo con un **toggle**:

```vhdl
-- en el dominio clk_sys (6,75 MHz)
if cpu_rw = '0' and is_vid_dat = '1' then
    write_req <= not write_req;      -- toggle
```

Y en el dominio de vídeo se detecta el **flanco** del toggle.

**Problema real:**
- El **CPU corre a 3,375 MHz** y el `video_bus` a **6,75 MHz** (el doble).
- El 6502 mantiene la dirección y `r_w` estables durante **~2 ciclos de `clk_sys`**
  en cada escritura.
- El código antiguo invertía el toggle **en cada ciclo** `clk_sys`. Con 2 ciclos
  activos por escritura, el toggle se invertía **2 veces** y **volvía a su estado
  original** → el dominio de vídeo **no veía ningún flanco** → **la escritura se
  perdía**.

### 2.2 Síntomas

Escrituras perdidas **intermitentes**, dependiendo de la fase entre relojes:

- Contenido que "aparecía y desaparecía".
- "Mallas" y patrones superpuestos.
- Texto que no aparecía.
- Celdas que a veces sí y a veces no.

### 2.3 El arreglo

Detectar **una sola vez** cada escritura, en el **flanco 0→1** de la señal de
escritura a `$D802`, con un registro `dat_active_d`:

```vhdl
if (dat_active = '1') and (dat_active_d = '0') then
    data_reg  <= cpu_data_in;
    write_req <= not write_req;      -- UNA vez por escritura
end if;
```

**Resultado:** llenar la pantalla de `A` (1200 celdas) funcionó a la primera, sin
esperas por software. Este **sí es un arreglo definitivo** y se conserva.

---

## 3. Por qué el diagnóstico fue tan largo (lecciones)

### 3.1 Atribución errónea del problema

Los síntomas de escrituras perdidas **se parecían** a los de un bug de scroll
(posición, contenido desplazado), así que se persiguió el scroll cuando el
problema real era el bus.

### 3.2 Bugs `asm` de la prueba (no del hardware)

En el programa de prueba del scroll se cometieron **varios errores de software**
que difuminaron el diagnóstico:

| Bug | Efecto |
|-----|--------|
| `calc_cell` con desplazamientos mal (6 a la derecha, luego 6 a la izquierda) | mapa escrito en direcciones equivocadas |
| `LDA #$41` fuera del bucle de llenado | el carácter se perdía tras la 1ª iteración |
| `STA $D808` (stride) olvidado en varios tests | el ancho quedaba en 40 |
| Mezclar stride 40 y 64 en los cálculos de celda | texto "corrido" y partido en filas |

**Cada uno** producía una imagen distinta y desviaba el análisis.

### 3.3 Falta de un test de base repetible

El **test mínimo** (escribir `ABC`/`HELLO` en celdas fijas) fue el que **debería
haberse hecho primero**. Cuando se hizo, separó limpiamente:

- "¿funciona la escritura?" → **sí** (aparecía `ABC`).
- "¿funciona el mapa?" → **depende del cálculo asm**.
- "¿funciona el scroll?" → **no se llegó a aislar del todo**.

### 3.4 El método correcto (para la próxima)

1. **Test de escritura mínima** (una letra en una celda) — primera comprobación.
2. **Verificar la aritmética asm en Python** (simular los bucles) **antes** de compilar.
3. **Un cambio por build**, nunca varios a la vez.
4. **`VIDEO_READY` de verdad**, no retardos. (Ver §5.)

---

## 4. Estado del código de scroll (aparcado, no borrado)

### 4.1 Lo que quedó implementado

| Elemento | Dónde | Estado |
|----------|-------|--------|
| Registros `$D804`–`$D808` (scroll_x/y y stride) | `video_bus.vhd` | ✅ escrito por CPU |
| Sincronización clk_sys→clk_pixel (doble flop) | `video_core.vhd` | ✅ |
| Captura del scroll al inicio de frame | `video_core.vhd` | ✅ |
| `x0_world = x0_log + scroll_x` | `video_core.vhd` | ✅ presente |
| `bitidx`/`row` desde `x0_world` (scroll fino) | `video_core.vhd` | ✅ presente |
| **`cell_addr` con stride variable** | `video_core.vhd` | ⚠️ **revertido a 40 fijo** |

### 4.2 Por qué se revertió `cell_addr`

La versión con `cell_addr = y_cell * map_stride + x_cell` usaba un **multiplicador
variable** en el camino combinacional que alimenta la BSRAM. Como el resto de
síntomas estaban sin resolver, **se optó por volver a la forma fija `* 40`** para
descartar que el multiplicador aportara inestabilidad. **No se demostró que fuera
un problema**, solo se eliminó la variable.

### 4.3 Resultado final

El scroll se **validó** con `cell_addr` fijo a 40 y `x0_world = x0_log + scroll_x` /
`y0_world = y0_log + scroll_y`. Funciona suave, con envoltura, tanto en horizontal
como en vertical. El stride variable (mapas de 64+) sigue pendiente si se desea.

### 4.4 Envoltura vertical (`y_cell mod 30`)

Inicialmente solo `x_cell` envolvía (`mod 40`). Al hacer scroll vertical, `y_cell`
se colaba en la fila siguiente (wrap espurio: aparecían tiles de basura). Se añadió
`y_cell <= y0_world(10 downto 3) mod 30`, idéntico al caso horizontal. Sin coste de
recursos (4.572 LUTs, sin cambios respecto a la versión solo-horizontal).

**Nota:** para mapas más altos (ej. 40x50 para shooters verticales) basta cambiar el
`mod 30` por `mod 50` (50*40 = 2000, cabe en las 2048 celdas de `tile_arr`).

---

## 5. Pendiente: lectura de `$D803` (VIDEO_READY)

Quedó una **duda sin resolver**: si la lectura del STATUS (`$D803`) funciona.

- El `Data_bus_mux` **no decodifica** el rango `$D800–$D807`.
- Al leer `$D803`, el mux pone `'Z'` y el `video_bus` pone el STATUS.
- **No se validó** que la lectura llegue limpia al CPU (posible conflicto de drivers).

**Impacto:** los programas usan **retardo por software** en vez de `VIDEO_READY`.
Funciona, pero es frágil. **Recomendación:** añadir la decodificación de `$D800–$D807`
en `Data_bus_mux` o al menos de `$D803`, y pasar a usar `VIDEO_READY`.

---

## 6. Otros bugs resueltos en el camino

### 6.1 Rango insuficiente de `t` (VHDL)

En la fase 2 de inicialización (`video_core.vhd`), la variable `t` (índice de tile)
estaba declarada `integer range 0 to 3`, pero la fase carga **8 tiles** (`t = init_cnt/8`
va de 0 a 7). Al llegar a `init_cnt = 32`, `t` desbordaba su rango y los **tiles 4-7
(entre ellos la nube) se grababan mal**.

**Síntoma:** la nube salía "azul con píxeles sueltos" en vez de blanca.
**Fix:** `t: integer range 0 to 7`.

### 6.2 Velocidad del scroll (software)

El bucle que movía `scroll_x` se incrementaba **docenas de veces por frame** porque
el programa solo comprobaba "VBLANK está activo", no "hubo un frame completo".
**Fix:** esperar el flanco completo (subida y bajada de VBLANK) + un divisor.

### 6.3 Variables zero page solapadas (software)

Se reutilizaba `TMP` entre los bucles y las subrutinas de dibujo, corrompiendo los
índices de árboles/nubes.
**Fix:** variables zero page dedicadas (`TILE`, `PAL`, `ROW`, `COL`, `I`, `J`).

### 6.4 Árbol "flotando" (diseño)

La copa y el tronco se dibujaban lejos del césped. Se reposicionaron: copa filas
19-20, tronco fila 21, césped fila 22.

---

## 7. Línea de tiempo de los hallazgos

| Orden | Hallazgo | Tipo |
|-------|----------|------|
| 1 | "Aparecen y desaparecen" cosa en pantalla | síntoma |
| 2 | `calc_cell` calculaba mal la dirección | bug asm |
| 3 | `LDA #$41` fuera del bucle | bug asm |
| 4 | stride olvidado (`$D808` no escrito) | bug asm |
| 5 | El test de `A` (1200 celdas) **funcionó** | pista clave |
| 6 | El programa vacío mostraba la init | confirmó que el mapa sí se dibujaba |
| 7 | Las letras sueltas (`Z`,`Y`,`A`,`0`) **se vieron** | confirmó que TODO funciona |
| 8 | **`video_bus` perdía escrituras por el toggle** | **bug de raíz** |
| 9 | Tras el fix, "puras A blancas" | resuelto |
| 10 | El scroll salió "rapidísimo" | velocidad (esperar frame completo) |
| 11 | Nube "azul con píxeles" | `t: range 0..3` desbordaba |
| 12 | Scroll suave + demo de terreno/árboles/nubes | **VALIDADO** |
| 13 | `y_cell mod 30`: envoltura vertical limpia | **VALIDADO** |

---

## 8. Conclusión

El scroll **funciona** (horizontal, suave, con envoltura). El esfuerzo se alargó por
**varios bugs encadenados**:

1. **Un bug de raíz en `video_bus`** que perdía escrituras y enmascaró todo.
2. **Un bug de rango en VHDL** (`t: 0..3` en vez de `0..7`).
3. **Varios bugs de software** en el programa de prueba.

Con el `video_bus` arreglado, el rango corregido y el método correcto (un cambio por
build, aritmética verificada en Python), el scroll quedó validado. La demo final
(terreno texturizado, césped, árboles, nubes, cielo azul) sirve como referencia de
capacidades del sistema, y funciona tanto desplazándose en horizontal
(`demo_scroll_h.asm`) como en vertical (`demo_scroll_v.asm`).
