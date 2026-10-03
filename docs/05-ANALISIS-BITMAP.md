# Módulo de Vídeo — Análisis del Modo Bitmap

**Proyecto:** fpga-6502-16k
**Documento:** Estudio de viabilidad del modo bitmap
**Estado:** Análisis (no implementado)
**Referencia:** `docs/03-FORMATOS-Y-MEMORIA.md` §5 (layout de BSRAM)

---

## 1. Pregunta

¿Cabe un modo bitmap (lienzo de píxeles libre) junto al motor de tiles, con la
memoria disponible?

---

## 2. Principio: es "uno u otro"

Un modo bitmap **no reutiliza el tilemap ni los patrones**: la pantalla es
directamente un mapa de bits. Por tanto no se **suma** memoria; se **sustituye**.

| Modo | Cómo genera la imagen | Memoria usada |
|------|-----------------------|---------------|
| Tiles | `tilemap → patrón → píxel` | tilemap + atributos + patrones |
| Bitmap | `dirección de píxel → bits` | un único bitmap |

---

## 3. Cuenta de memoria

### 3.1 La resolución actual es inviable

Pantalla lógica 320×240 a 2bpp (4 colores):

```
320 × 240 × 2 bits = 153.600 bits = 19.200 bytes = 19,2 KB
```

**No cabe**: toda la VRAM del sistema son ~8 KB.

### 3.2 Qué cabría reutilizando la memoria de tiles

Suma máxima (si se eliminan tilemap + atributos + patrones + fuente):

| Arreglo | Tamaño |
|---------|--------|
| `pat_arr` | 4 KB |
| `tile_arr` | 2 KB |
| `attr_arr` | 2 KB |
| `font_arr` | 1,15 KB |
| **Total** | **~9,15 KB** |

> **Matiz importante:** esa suma **no es un espacio contiguo usable**. Los arrays
> tienen **puertos y decodificadores independientes**. Para el bitmap habría que
> **rediseñar** `video_vram` con **un único array** y **quitar** los de tiles.

### 3.3 Resoluciones posibles (en un array único)

| Bitmap | Tamaño | ¿Cabe en ~9,15 KB? |
|--------|--------|--------------------|
| 320×240 @ 2bpp | 19,2 KB | ❌ |
| 320×120 @ 2bpp | 9,6 KB | ❌ (por poco) |
| 256×192 @ 2bpp (tipo C64) | 12,3 KB | ❌ |
| 160×120 @ 2bpp (4 colores) | 4,8 KB | ✅ (sobran ~4,3 KB) |
| 160×120 @ 3bpp (8 colores) | 7,2 KB | ✅ |
| 160×120 @ 4bpp (16 colores) | 9,6 KB | ❌ (por poco) |
| 160×112 @ 4bpp (16 colores) | 8,96 KB | ✅ |
| 128×128 @ 4bpp (16 colores) | 8,19 KB | ✅ |
| 160×120 @ 1bpp (2 colores) | 2,4 KB | ✅ (holgado) |

**Conclusiones:**

- **160×120 @ 2bpp** cabe con holgura → 4 colores, escalado ×4 a 640×480.
- **160×120 @ 3bpp** cabe → 8 colores, pero **peor para el hardware** (§4).
- **160×120 @ 4bpp** **no cabe por 0,45 KB**; se soluciona bajando a **160×112**.
- **320×240 @ 2bpp** = imposible.

### 3.4 Comparación con el truco del C64

El C64 logra 320×200 con **8 KB** porque **no** usa 2bpp:

- **1 bit por píxel** (2 colores: fondo + tinta) → `320×200/8 = 8 KB`.
- **+ color de tinta por celda** de 8×8 (`1000 bytes`).
- + pocos colores globales.

Aplicado a 320×240 con el mismo truco: **9,6 KB** (bitmap 1bpp) + 1,2 KB
(atributos) ≈ **10,8 KB** → sigue sin caber.

---

## 4. Coste de implementación (independiente de la resolución)

| Componente | Coste |
|-----------|-------|
| Array bitmap único en BSRAM | 5–6 bloques (**no hay: la BSRAM está agotada**) |
| Segundo camino de render (bitmap) | ~100–200 LUTs |
| Mux entre modo tiles y bitmap | ~30 LUTs |
| Registro de modo (`$D805`) | trivial |
| **Pipeline** | **riesgo alto** (un desfase de 1 ciclo rompe la imagen) |

**El bitmap NO es una reutilización gratuita**: exige reescribir `video_vram` y
añadir un segundo renderizador con su mux, además de liberar los bloques de tiles.

### 4.1 Por qué 3bpp es peor que 4bpp o 2bpp

- **2bpp**: 8 píxeles = 16 bits (2 bytes) → alineación perfecta.
- **4bpp**: 8 píxeles = 32 bits (4 bytes) → alineación perfecta.
- **3bpp**: 8 píxeles = 24 bits (3 bytes) → alineado a byte, pero extraer un píxel
  exige combinar dos bytes con desplazamientos variables → **más LUTs y más
  riesgo** en el pipeline.

Recomendación: si se hace bitmap, usar **2bpp** o **4bpp**, no 3bpp.

---

## 5. Decisión pendiente

**D-09:** ¿implementar el modo bitmap?

- **No, por ahora.** El modo tiles + sprites + texto cubre el objetivo de "hacer
  juegos" y **no queda BSRAM**.
- **Sí, reutilizando.** Si se hace, sería un modo **alternativo** (no simultáneo)
  que sustituye los arrays de tiles, con resolución ≤ 160×120 @ 2bpp (o 160×112
  @ 4bpp). Coste: reescritura de `video_vram` + segundo renderizador.

**Prerrequisito común:** liberar BSRAM. Opciones futuras:

| Opción | Bloques liberados |
|--------|-------------------|
| Reducir la ROM del CPU (16 KB → 8 KB) | +6 bloques |
| Optimizar el banco de patrones (256 → 192) | +0,5 bloque |
| Reducir el tilemap/atributos (2048 → 1200 entradas efectivas) | 0 (ya son 1 bloque cada uno) |

La ROM es la mayor fuente de bloques, pero está llena con el monitor en C/cc65
(reducirla es "prácticamente un proyecto aparte").

---

## 6. Conclusión

Un modo bitmap **es técnicamente posible** a baja resolución (160×120 @ 2bpp), pero:

1. **Requiere reutilizar** (sustituir) la memoria de tiles, no añadirla.
2. **Cuesta un segundo renderizador** con su mux y su riesgo de pipeline.
3. **Hoy no hay BSRAM libre** (26/26 tras la Fase 7).

**Recomendación:** mantener el foco en **tiles + sprites + texto** (que cubren el
objetivo de juegos) y reconsiderar el bitmap solo si aparece una fuente de BSRAM
(p. ej. reducir la ROM del CPU).
