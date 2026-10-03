# Documentación del Módulo de Vídeo

Análisis y planificación del subsistema de vídeo para el computador 6502 en
Sipeed Tang Nano 9K (Gowin GW1NR-9).

## Documentos

| # | Documento | Contenido |
|---|-----------|-----------|
| 01 | [Requerimientos](01-REQUERIMIENTOS.md) | Objetivo, recursos medidos, RF/RNF, riesgos |
| 02 | [Plan de Implementación](02-PLAN-IMPLEMENTACION.md) | Fases 0–11, presupuestos, decisiones pendientes |
| 03 | [Formatos y Memoria](03-FORMATOS-Y-MEMORIA.md) | Byte de atributo, OAM, COLL_POINT, paleta, mapa de memoria |
| 04 | [Modo Texto](04-MODO-TEXTO.md) | Segunda ROM de fuente (1bpp), expansión a 2bpp, uso desde 6502 |
| 05 | [Análisis del Bitmap](05-ANALISIS-BITMAP.md) | Viabilidad, resoluciones, coste, decisión pendiente |
| 06 | [Reporte del scroll](06-REPORTE-SCROLL.md) | Por qué costó, bug de raíz del video_bus, estado aparcado |
| **07** | **[Manual de Programación](07-MANUAL-PROGRAMACION.md)** | **Guía para escribir juegos: registros, sprites, tiles, scroll, HUD, colisión, recetas y plantilla** |

## Resumen ejecutivo

**Objetivo:** añadir un módulo de vídeo (tiles + sprites + texto + bitmap) sin
eliminar ningún módulo existente.

**Viabilidad:** verificada con datos de síntesis reales.

| Recurso | Libre | Necesario | ¿Alcanza? |
|---------|-------|-----------|-----------|
| LUTs | 5.163 (60%) | ~800–1.400 | ✅ |
| BSRAM | 0 bloques | 0 | ⚠️ **agotada** |
| PLL | 1 | 1 | ✅ |
| DSP | 8 | 1 | ✅ |

**Estado:** Fases 1–10 implementadas y validadas en hardware.
El motor de vídeo soporta tiles multicolor, fondo transparente, sprites con
line buffer, prioridad, flips X/Y, **escalado 2×**, STATUS (vblank/overflow/ready),
**modo texto con fuente en BSRAM**, **scroll horizontal/vertical** sobre mapa 64×32,
**split de raster (3 bandas)** y **colisión sprite↔tile sólido**. Análisis del bitmap
pendiente (al final). Rotación de sprites descartada.

**Modelo:** coprocesador gráfico estilo VIC-II/NES. El software escribe
memoria y registros; el hardware genera la señal de forma autónoma.

**Modos:** tiles+sprites (juegos), texto (consola), bitmap (dibujo).

**Especificación de color:** 2bpp, 4 colores por tile, 16 paletas por celda →
hasta 64 colores simultáneos.

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
