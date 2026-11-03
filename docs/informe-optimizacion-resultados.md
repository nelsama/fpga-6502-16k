# Informe de optimización — video_core.vhd (fusionado: estimaciones + resultados reales)

**Proyecto:** fpga-6502-16k — Tang Nano 9K (GW1NR-9C-QFN88P-6): 8.640 LUT4 / 6.693 FF / 36 BSRAM.
**Restricción:** todos los BSRAM ocupados (26/26). Ninguna propuesta añade BSRAM.
**Commits:** base `bd5e160` → optimización aplicada `109fc5f`.
**Fecha:** noviembre de 2026.

---

## 1. Recursos: antes y después (medido)

| Recurso | `bd5e160` | `109fc5f` | Δ |
|---|---:|---:|---:|
| **CLS** | 4236 / 4320 (98 %) | **4206 / 4320 (98 %)** | **−30** |
| **Register** | 4249 / 6693 | **4218 / 6693** | **−31** |
| Logic | 7265 / 8640 | 7293 / 8640 | +28 |
| BSRAM | 26 / 26 (100 %) | 26 / 26 (100 %) | 0 |

**Conseguido: −31 FF, −30 CLS.**

### Lecciones de la medición

1. **El recurso crítico es CLS, no FF.** Quedan 2445 registros libres; el cuello de botella son las 4320 celdas lógicas.
2. **En GW1N, FF y CLS son ~1:1.** Cada FF vivo consume una CLS. Confirmado: −31 FF → −30 CLS. Reducir registros *vivos* libera CLS.
3. **El código muerto es gratis.** Gowin podaba solo las tablas de demo y los `mod`; quitarlos del fuente ahorró 0 CLS. Solo ahorra quitar registros vivos o reestructurar lógica viva.

---

## 2. Lo aplicado

### 2.1 `coll_flag` de 32 bits → 1 bit sticky ✅ (`109fc5f`, verificado en hardware)

El vector `coll_flag(31 downto 0)` solo alimentaba su OR (`SOLID_HIT`, bit 5 de `$D803`); el CPU nunca lee los flags individuales. Era almacenamiento muerto más un comparador de 32 bits.

```vhdl
-- antes
signal coll_flag : std_logic_vector(31 downto 0) := (others => '0');
solid_hit <= '1' when (coll_flag /= x"00000000") else '0';

-- después
signal solid_hit : std_logic := '0';
if attr_dout(4) = '1' then
    solid_hit <= '1';
end if;   -- se limpia en v_cnt = V_VISIBLE
```

**Ahorro:** 31 FF + árbol OR. **Impacto funcional:** ninguno.

---

## 3. Lo descartado, con evidencia

| # | Propuesta | Veredicto | Motivo |
|---|---|---|---|
| 1 | Quitar ROMs de demo (fases 2 y 3) | ❌ 0 CLS | Gowin ya las podaba (la fase 4 sobreescribe los tiles 0–7). 158 líneas eliminadas, diferencia nula |
| 2 | Paletas 32 → 16 entradas | ⚠️ Reformulada | Rompe bancos separados fondo/sprite. Reformulada como `pal_spr` 16→8 (ver §5) |
| 4 | Quitar sincronizadores doble-flop | ❌ Incorrecta | El CPU corre a **3,375 MHz**, no a 27 MHz. Los sincronizadores son imprescindibles |
| 5 | Repack del line buffer | ⚠️ Revertido | −24 FF pero rompió el verde de los tallos del snake y no se localizó la causa. Se revirtió completo |
| 6 | Shifters de patrón | ⏸️ No intentado | Riesgo medio y sin margen de CLS para iterar |
| 7 | `mod` por slices explícitos | ❌ 0 CLS | Gowin ya lo optimizaba. Solo legibilidad |
| 8 | Quitar split de raster | ⏸️ Pendiente | ~70 CLS, pero es funcionalidad real (parallax). Decisión de producto |

---

## 4. El hallazgo clave: `unPlaced` ≠ falta de registros

`ERROR (PR0003): Failed to place with 'N REG(s) unPlaced'` apareció con 22, 8, 6 y 1 en distintas compilaciones. No es estable ni indica déficit de FF (hay 2445 libres): es **fallo de colocación al 98 % de CLS**. El número reportado es un subproducto del intento.

**Consecuencia probada: el diseño no acepta añadidos.** Tres intentos de color de texto por celda:

| Intento | Mecanismo | Resultado |
|---|---|---|
| A | Bit 7 del tile | ❌ Rompe la fruta: `$80–$FF` son tiles gráficos del Pac-Man, no una copia de fuente |
| B | Bit 2 del atributo, sin alinear | ❌ Selector en celda vecina (`attr_d1` va 1 ciclo por delante de `pat_dout`) → corrompe plano 1 |
| C | Bit 2 del atributo, alineado (`ctxt2`) | ❌ Lógicamente correcto (4215 CLS) pero **cuelga el arranque** en «Montando MicroFS…», determinista |

El intento C es la prueba: 9 CLS extra de lógica determinista no pueden colgar un módulo SPI. Cambió la colocación global y degradó el dominio de la SD.

**Acción antes de tocar lógica:** el P&R de Gowin acepta **seed configurable**. Probar 3–5 seeds del netlist actual: si el intento C arranca con alguno, el problema era colocación, no lógica. Si ninguno arranca, revisar el timing report del dominio SD (¿SDC aplicado a esos relojes?).

---

## 5. Estado real del byte de atributo y plan nuevo

El RTL solo lee 3 bits del atributo: `attr_dout(1:0)` (paleta) y `attr_dout(4)` (sólido). Los bits 2, 3, 5, 6, 7 **llegan a la BSRAM y se descartan**. La doble copia de fuente de `docs/04-MODO-TEXTO.md` tampoco está implementada (`font_color = "11"` fijo).

### Plan para crear ~140 CLS de margen (sin perder split ni sprites)

| # | Optimización | Ahorro est. | Riesgo | Estado |
|---|---|---:|---|---|
| N1 | **Mux de color final a 12 bits** (seleccionar `rgb12`, expandir una sola vez al final) | **0 CLS (medido)** | nulo (idéntico funcional) | aplicado solo por legibilidad |
| N2 | **`pal_spr` 16 → 8 entradas** (sprites de 4 a 2 paletas; fondo intacto) | ~96 CLS | bajo (sw re-mapea paletas) | propuesta |
| N3 | Split 3 → 2 bandas | ~70 CLS | funcional | decisión |
| N4 | `NSL` 8 → 6 | ~60–80 CLS (FF **y** comparadores del picker) | funcional | decisión |
| N5 | `font_color` escribible por CPU (registro ya existe, solo exponerlo en `video_bus`) | 0 CLS en píxel | nulo | propuesta |

**N1 — aplicado y MEDIDO: 0 CLS.** Se reescribió el mux final para trabajar en
12 bits (RGB444) y expandir a 24 una sola vez al final:

```vhdl
rgb12 <= pal_bg(15) when margen2 = '1' else
         spr_rgb    when (spr_active = '1') and (spr_prio2 = '0') else
         pal_rgb    when pixcode /= "00" else
         spr_rgb    when spr_active = '1' else
         pal_bg(15);

rgb24 <= rgb12(11 downto 8) & rgb12(11 downto 8) &
         rgb12(7  downto 4) & rgb12(7  downto 4) &
         rgb12(3  downto 0) & rgb12(3  downto 0);
```

Resultado tras compilar: **4206 CLS / 4218 FF, idénticos a antes** (la señal
`bg_rgb24` se eliminó).

**Por qué no ahorra:** los bits repetidos son cableado y el sintetizador ya
reconocía que `expand(a) vs expand(b)` equivale a `expand(a vs b)`. Es decir,
**Gowin ya aplicaba N1 por su cuenta**. Se mantiene el cambio por legibilidad.

### Regla confirmada tres veces

| Propuesta | Estimación | Medido | Naturaleza |
|---|---:|---:|---|
| Quitar ROMs demo (#1) | 150–300 LUT | **0** | lógica combinacional |
| `mod` → slices (#7) | 0–20 LUT | **0** | lógica combinacional |
| N1 mux 12 bits | 40–60 CLS | **0** | lógica combinacional |
| `coll_flag` → 1 bit | ~31 FF | **−31 FF / −30 CLS** | **registros vivos** |

**Solo ahorra quitar FF vivos** (o reestructurar estructuras de registros, como el
line buffer o los bancos de paleta). Toda propuesta basada en «quitar LUTs» o
«simplificar lógica combinacional» dará 0: el sintetizador ya lo hace.

Con **N2** (~96 FF de paleta de sprite) se reintenta el intento C (color de texto
por celda vía bit 2 del atributo, alineado con `ctxt2`), verificando con varios
seeds. **N5** queda como alternativa de color de texto *global* a coste cero si el
por-celda sigue sin entrar.

---

## 6. Historial de commits

| Commit | Contenido |
|---|---|
| `bd5e160` | Base original que funciona |
| `ac34350` | Arreglo del mapa de caracteres de la fuente C64 (`.` salía como `M`) |
| `109fc5f` | `coll_flag` → 1 bit sticky (−31 FF, −30 CLS) |
