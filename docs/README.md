# Documentación del Módulo de Vídeo

Análisis y planificación del subsistema de vídeo para el computador 6502 en
Sipeed Tang Nano 9K (Gowin GW1NR-9).

## Documentos

| # | Documento | Contenido |
|---|-----------|-----------|
| 01 | [Requerimientos](01-REQUERIMIENTOS.md) | Objetivo, recursos medidos, RF/RNF, riesgos |
| 02 | [Plan de Implementación](02-PLAN-IMPLEMENTACION.md) | Fases 0–14, presupuestos, decisiones pendientes |
| 03 | [Formatos y Memoria](03-FORMATOS-Y-MEMORIA.md) | Byte de atributo, OAM, COLL_POINT, paleta, mapa de memoria |
| 04 | [Modo Texto](04-MODO-TEXTO.md) | Segunda ROM de fuente (1bpp), expansión a 2bpp, uso desde 6502 |
| 05 | [Análisis del Bitmap](05-ANALISIS-BITMAP.md) | Viabilidad, resoluciones, coste, decisión pendiente |
| 06 | [Reporte del scroll](06-REPORTE-SCROLL.md) | Por qué costó, bug de raíz del video_bus, estado aparcado |
| **07** | **[Manual de Programación](07-MANUAL-PROGRAMACION.md)** | **Guía para escribir juegos: registros, sprites, tiles, scroll, HUD, colisión, recetas y plantilla** |

## Resumen ejecutivo

**Objetivo:** añadir un módulo de vídeo (tiles + sprites + texto + bitmap) sin
eliminar ningún módulo existente.

**Viabilidad:** verificada con datos de síntesis reales.

| Recurso | Uso final | Libre | ¿Alcanza? |
|---------|-----------|-------|-----------|
| Lógica | 6.409 (74%) | ~2.231 | ✅ |
| BSRAM | 26/26 | 0 | ⚠️ **agotada** |
| PLL | 1 | 1 | ✅ |
| DSP | 2/10 | 8 | ✅ |

**Estado: COMPLETO** ✅ — Fases 1–12 implementadas y validadas en hardware.
El motor de vídeo soporta tiles multicolor, fondo transparente, sprites (line buffer,
prioridad, flips X/Y, **escalado 2×**, **X de 9 bits**), STATUS (vblank/overflow/
solid-hit/ready), **modo texto con fuente en BSRAM**, **scroll H/V** sobre mapa 64×32,
**split de raster (3 bandas)**, y **colisión sprite↔tile sólido** con punto de
colisión configurable y auto-escala 1×/2×.

> **El módulo de vídeo está cerrado.** Lo descartado explícitamente (bitmap, tilemap
doble, colisión sprite↔sprite por hardware, rotación, integración con el monitor)
está en `02-PLAN-IMPLEMENTACION.md` §7.

**Modelo:** coprocesador gráfico estilo VIC-II/NES. El software escribe
memoria y registros; el hardware genera la señal de forma autónoma.

**Modos:** tiles+sprites (juegos), texto (consola), bitmap (dibujo).

**Especificación de color:** 2bpp, 4 colores por tile, 4 paletas de fondo + 4 de
sprite × 4 colores = **hasta 32 colores simultáneos** (16 fondo + 16 sprite). Paletas
**escribibles por el CPU** (`$D813-$D815`). **BG_COLOR = la entrada 15 de la paleta de fondo.**

**Riesgo principal:** ruido de audio con TMDS a 252 MHz junto a los pines de
audio (76–77). Debe validarse.

**Decisiones resueltas:** HDMI (no VGA), 320×240 lógicos, puerto indirecto de VRAM
(`$D800`), juegos cargados de SD a RAM, fuente de caracteres en BSRAM.
Ver `02-PLAN-IMPLEMENTACION.md` §6.

> **Nota:** el recurso crítico es la **BSRAM**. Tras la Fase 7 queda **0 bloques
> libres** (26/26). El modo bitmap exigiría **reutilizar** la memoria de tiles,
> no añadirla (ver `05-ANALISIS-BITMAP.md`).

## Artefactos de referencia

- Síntesis real del diseño actual: `impl/pnr/6502_board_v3.rpt.txt`
- Recursos por módulo: `impl/gwsynthesis/6502_board_v3_syn_resource.html`
- Script de síntesis: `impl/run_syn.tcl`
