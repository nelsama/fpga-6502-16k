# Informe para `EmuladorFpga6502`: desfase en el scroll vertical del dibujado

**Desde:** `fpga-6502-16k` (core de vídeo)
**Para:** `EmuladorFpga6502`
**Fecha:** 2026-10-27
**Referencia core:** `57774ed`
**Referencia emulador:** `1583eb2`

---

## Resumen

Antes de nada: **la corrección de `1583eb2` es correcta**. Adopta bien la explicación
del core sobre el split de raster, tanto en `GUIA-USO.md` como en el comentario de
`Video::barrido_colision()`. Nada que objetar ahí.

Revisando ese cambio apareció otra cosa, esta vez en el **dibujado** y no en la
colisión: el scroll vertical se envuelve a **8 bits** donde el RTL lo hace a **11**.
Afecta solo a `scroll_y > 255`, que el manual declara fuera de rango — así que la
severidad es baja, pero conviene decidirlo explícitamente en vez de dejarlo al azar.

---

## El desfase

**`src/video/video.cpp`, dibujado del fondo (~línea 446):**

```cpp
int map_y = (py + band_scroll_y) & 0xFF; // envuelve módulo 256 (32 tiles × 8)
int tile_row = (map_y / TILE_H) & (MAP_H - 1);
int pix_y = map_y % TILE_H;
```

**`src/hdmi/video_core.vhd` (RTL), líneas 586 y 597:**

```vhdl
y0_world <= resize(y0_log, 11) + scroll_y;   -- 11 bits, 0..2047
...
y_cell   <= y0_world(10 downto 3) mod 32;
row_t1   <= y0_world(2 downto 0);
```

El hardware suma en **11 bits** y envuelve **al tomar la celda** (`mod 32`). El
emulador envuelve a **8 bits antes** de dividir.

Para `scroll_y ≤ 255` los dos coinciden. La diferencia aparece solo con
`scroll_y ≥ 256`, que solo es alcanzable escribiendo los bits 2:0 de `$D807`.

**Nótese que el barrido de colisión sí lo hace bien** (líneas ~276):

```cpp
const int wy = (py + scy) & 0x7FF;   // 11 bits, igual que el RTL
```

Es decir: las dos rutas del emulador no usan el mismo ancho para el scroll vertical.

---

## Qué hace realmente el hardware con `scroll_y >= 256`

Consultado el RTL, **los bits altos no se ignoran**: entran en la suma de 11 bits y
el `mod 32` los absorbe. `scroll_y = 256` equivale a `scroll_y = 0` para la fila de
celda, **pero no para el desplazamiento dentro del tile**, porque `row_t1` sale de
`y0_world(2 downto 0)`.

La diferencia práctica es pequeña (256 es múltiplo de 32, así que cae en el mismo
límite de tile), pero el comportamiento exacto del hardware está en la aritmética de
11 bits, no en un recorte a 8.

---

## Casos concretos

| `scroll_y` | RTL (11 bits) | Emulador (8 bits) | ¿Coinciden? |
|---|---|---|---|
| 0..255 | normal | normal | ✅ Sí |
| 256 | `y0_world = py+256` → fila `(py+256)/8 mod 32` | `(py+0) & 0xFF` → fila `py/8` | ✅ Sí (256 es múltiplo de 32) |
| 260 | fila `(py+260)/8 mod 32`, píxel `(py+260)&7` | fila `(py+4)/8`, píxel `(py+4)&7` | ⚠️ **No** |
| 2047 | fila `(py+2047)/8 mod 32` | fila `(py+255)/8` | ⚠️ **No** |

---

## Opciones

### A. Alinear el emulador con el RTL

Cambiar el dibujado para que use 11 bits, igual que la colisión:

```cpp
int map_y = (py + band_scroll_y) & 0x7FF;
int tile_row = (map_y / TILE_H) & (MAP_H - 1);
int pix_y = map_y % TILE_H;
```

Coste: una línea. Deja el emulador fiel al hardware en todo el rango del registro.

### B. Documentar que `scroll_y` fuera de 0..255 es indefinido

El manual del core dice explícitamente (§7.1) que Y va de **0 a 255** y que «los bits
por encima de esos rangos se ignoran». Si se acepta que nadie va a escribir fuera de
rango, el emulador actual es válido para todo uso legítimo y no hay nada que tocar.

### C. Recortar en el core

Añadir en el RTL un recorte explícito de `scroll_y` a 8 bits, para que el manual y el
hardware digan lo mismo sin ambigüedad. **No recomendado ahora**: toca el RTL y
consume recursos en un chip al 99 % de CLS, por un caso que nadie usa.

---

## Recomendación

**Opción A.** Es una línea, no toca el RTL, y elimina la asimetría entre el dibujado
y la colisión dentro del propio emulador. Aunque en la práctica nadie escriba
`scroll_y > 255`, tener dos anchos distintos para la misma operación es una trampa
para el próximo que lea el código.

Si prefieres no tocarlo, la **opción B** es defendible: basta con dejar escrito en
`GUIA-USO.md` que `scroll_y` se comporta como 8 bits en el emulador y que valores
mayores dan resultados distintos al hardware.

Lo que **no** conviene es dejarlo sin decidir: hoy la documentación del emulador no
menciona el tema, y la del core afirma algo («se ignoran») que el RTL no cumple.

---

## Aclaración sobre el informe anterior

El punto de la documentación **está resuelto** y no requiere más cambios: la
explicación del scroll de banda en la colisión es ahora correcta en ambos proyectos
(core `57774ed`, emulador `1583eb2`). Este informe es un hallazgo **nuevo y distinto**,
sin relación con aquel.
