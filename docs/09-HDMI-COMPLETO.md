# HDMI completo (imagen + audio) en otros proyectos de Tang Nano 9K

Cómo añadir a un proyecto que ya saca imagen por HDMI/DVI el transmisor de esta placa:
720×480p a 60 Hz, identificación de formato y audio de 48 kHz.

**Para quién:** quien integre el módulo en otro proyecto (persona o asistente de IA), con
VHDL y Gowin EDA. Si tu proyecto es Verilog, los `.vhd` se pueden mezclar en el mismo
proyecto de Gowin.

---

## 1. Qué ofrece y qué exige

| Ofrece | |
|---|---|
| Vídeo | 720×480p, 59,94 Hz, VIC 2 (4:3), RGB de rango completo |
| Audio | PCM 48 kHz, 16 bits, 2 canales (la versión actual manda mono por los dos) |
| Modo | `FULL = true` HDMI completo; `FULL = false` DVI (solo imagen) |
| Coste | unos **200 CLS**, 355 de lógica y 130 registros más que DVI. 0 BSRAM, 0 DSP |

| Exige | Por qué |
|---|---|
| Reloj de píxel de **27,000 MHz exactos** | 27 MHz / 48 kHz = 562,5: los valores de audio (N, CTS) son constantes |
| Barrido de **858 × 525** (720 × 480 visibles) | El reparto de los paquetes depende de esas cifras |
| Un PLL para 135 MHz y un `CLKDIV` | Ver §3. La Tang Nano 9K tiene 2 PLL |
| Cristal de 27 MHz | Es el de la placa |

**Otras resoluciones** (640×480, 720p) no valen sin rehacer tiempos, VIC, N y CTS (§8).

## 2. Archivos que hay que copiar

| Archivo | Función |
|---|---|
| `src/hdmi/hdmi_tx.vhd` | Transmisor: paquetes, audio, InfoFrames. Lógica pura, sin primitivas de Gowin |
| `src/hdmi/hdmi_phy.vhd` | PLL, `CLKDIV`, serializadores `OSER10` y salidas diferenciales |
| `src/hdmi/tmds_encoder_2.vhd` | Codificador TMDS (Furkan Cayci) |
| `src/hdmi/clk_27x5.vhd` | PLL 27 → 135 MHz. Usa la versión de este proyecto: tiene salida `lock` |
| `sim/hdmi/` | Banco de pruebas y receptor (§7). Opcional |

Sustituyen a `hdmi_module.vhd` y `hdmi_impl.vhd`: quítalos del proyecto.

## 3. Relojes: lo más importante

```
27 MHz ─▶ [PLL ×5] ─▶ 135 MHz ─┬─▶ FCLK de los OSER10
                               └─▶ [CLKDIV /5] ─▶ clk_pixel (27 MHz) ─▶ PCLK y TODO el vídeo
```

- **`PCLK` tiene que salir de `FCLK` por `CLKDIV`.** No uses el pin de 27 MHz como reloj de
  píxel: tiene la misma frecuencia, pero su fase respecto a los 135 MHz no está garantizada.
- **Todo el vídeo debe funcionar con el `clk_pixel` que entrega `hdmi_phy`.** Lo que antes
  usaba el pin de 27 MHz en el dominio de vídeo se cambia a `clk_pixel`.
- El resto del sistema (CPU, sonido) pasa a ser **asíncrono** respecto al vídeo: revisa los
  cruces (doble registro para bits, toggle para pulsos, dato estable para buses).
- El reloj TMDS también sale por un `OSER10` (patrón `1111100000`), como los datos.
- Los `OSER10` se sueltan del reset con el PLL ya enganchado. `hdmi_phy` ya lo hace.

## 4. Conexión del vídeo

```vhdl
u_tx : entity work.hdmi_tx
    generic map (FULL => true)
    port map (
        clk       => clk_pixel,
        h_cnt     => h_cnt,        -- unsigned(9 downto 0): 0..857
        v_cnt     => v_cnt,        -- unsigned(9 downto 0): 0..524
        hs        => hs_d2,        -- activos en BAJO
        vs        => vs_d2,
        de        => de_d2,
        rgb       => rgb_d2,       -- R(23:16) G(15:8) B(7:0)
        audio_req => audio_req,
        audio     => audio,
        q0 => q0, q1 => q1, q2 => q2
    );

u_phy : entity work.hdmi_phy
    port map (
        clk_27    => clk27,        -- pin 52
        clk_pixel => clk_pixel,    -- SALIDA: reloj de todo el video
        q0 => q0, q1 => q1, q2 => q2,
        tmds_c0_p => tmds_c0_p, tmds_c0_n => tmds_c0_n,
        tmds_c1_p => tmds_c1_p, tmds_c1_n => tmds_c1_n,
        tmds_c2_p => tmds_c2_p, tmds_c2_n => tmds_c2_n,
        tmds_ck_p => tmds_ck_p, tmds_ck_n => tmds_ck_n
    );
```

### 4.1 La regla de los 2 ciclos

**`hs`, `vs`, `de` y `rgb` tienen que llegar exactamente 2 ciclos después que los
contadores** (`h_cnt`, `v_cnt`) que los generaron.

| Tu proyecto | Qué hacer |
|---|---|
| La imagen tarda 2 ciclos desde el contador | Conectar tal cual |
| Tarda menos (N < 2) | Añadir 2 − N registros a `hs`, `vs`, `de` y `rgb` |
| Tarda más (N > 2) | Retrasar los **contadores** que entran en `hdmi_tx` N − 2 ciclos |
| No tienes contadores 858×525 | Créalos en el dominio de vídeo, alineados con tu `de` |

Si no se cumple, el receptor ve los preámbulos desplazados: imagen rota o pantalla negra.

### 4.2 Sincronismos estándar

```vhdl
hs <= '0' when h_cnt >= 736 and h_cnt <= 797 else '1';              -- 62 pixeles
vs <= '0' when (v_cnt > 489 or (v_cnt = 489 and h_cnt >= 736)) and  -- 6 lineas, alineado
               (v_cnt <= 494 or (v_cnt = 495 and h_cnt < 736)) else '1';  -- con hs
de <= '1' when h_cnt < 720 and v_cnt < 480 else '0';
```

Comprueba los tuyos: es fácil tener 63 píxeles o 7 líneas por un `<=` de más. Los monitores
lo perdonan y algunas teles no.

## 5. Conexión del audio

`hdmi_tx` pide una muestra **invirtiendo `audio_req`** cada 1/48000 s y lee `audio` en la
petición siguiente. La muestra debe quedarse quieta mientras tanto, así que se congela en el
dominio del sonido:

```vhdl
process (clk_sonido)
begin
    if rising_edge(clk_sonido) then
        req_s <= req_s(1 downto 0) & audio_req;      -- sincronizar
        if req_s(2) /= req_s(1) then
            audio <= muestra;                        -- 16 bits CON SIGNO
        end if;
    end if;
end process;
```

`clk_sonido` debe ser de **0,5 MHz o más** (necesita varios ciclos entre peticiones).

| Formato de tu sonido | Conversión a 16 bits con signo |
|---|---|
| Con signo, 16 bits | directo |
| Sin signo (binario con offset) | invertir el bit más alto: `(not x(15)) & x(14 downto 0)` |
| Más de 16 bits | quedarse con los 16 más altos |
| Menos bits | rellenar con ceros por la derecha |
| Solo salida PWM / sigma-delta de 1 bit | usar el valor **antes** del DAC |

No hace falta filtro: si tu sonido se genera a otra frecuencia, se toma el último valor. Con
fuentes ricas en agudos (PSG, ruido) un filtro paso bajo previo reduce el *aliasing*.

### 5.1 Estéreo de verdad

La versión actual copia la misma muestra a L y R. Para dos canales, en `hdmi_tx.vhd`:

1. `audio` y la cola `fifo` pasan de 16 a **32 bits** (R & L).
2. `pl` usa la paridad de L y `pr` la de R.
3. En `sub`, cada mitad lleva su canal:

```vhdl
sub <= pr & csr & "00" & pl & csl & "00" & smp_r & x"00" & smp_l & x"00";
```

No cambian ni los paquetes ni los tiempos. **No está probado**: pásalo por el receptor de §7,
que hoy comprueba que L = R y habrá que ajustarlo.

## 6. Restricciones

**Pines** (`.cst`; los nombres son los de tu entidad superior):

```
IO_LOC  "tmds_ck_p" 69,68;
IO_LOC  "tmds_c0_p" 71,70;
IO_LOC  "tmds_c1_p" 73,72;
IO_LOC  "tmds_c2_p" 75,74;
IO_PORT "tmds_ck_p" PULL_MODE=NONE DRIVE=8;     // igual para c0, c1 y c2
```

**Relojes** (`.sdc`):

```tcl
create_clock -name pix -period 37.037 -waveform {0 18.518} [get_nets {clk_pixel}]
# asincrono respecto al resto (ajusta los nombres a tus relojes)
set_clock_groups -asynchronous -group [get_clocks {pix}] -group [get_clocks {tus_relojes}]
```

Pon los dos grupos completos: sin esto Gowin intenta cumplir caminos que no lo necesitan.

**PLL:** la placa tiene 2. Si ya usas los dos, uno de ellos debe ser el de 135 MHz; si ninguno
lo es, hay que reorganizar los relojes antes de empezar.

## 7. Verificación antes de grabar

```
cd sim/hdmi
bash run.sh
```

Simula `hdmi_tx` con GHDL y decodifica los símbolos con un **receptor escrito aparte** (Node).
Tarda unos 2 minutos. Salida esperada: `malos 0`, `CTS 27000 N 6144`, audio `bad: 0` y, en `errores`, solo unos 700
`simbolo inesperado` al principio (la primera línea, antes de enganchar).

Comprueba: preámbulos, guardas, TERC4, BCH, sumas de los InfoFrames, paridad y estado de canal
del audio, bloques de 192 y todos los píxeles. **No** comprueba la señal eléctrica ni §4.1 en tu
proyecto.

En el informe de Gowin:

- `Register as Latch` = 0.
- Reloj `pix` por encima de 27 MHz.
- 2 `CLKDIV` o menos, y los PLL que esperabas.

## 8. Valores que se pueden cambiar

| Qué | Dónde (`hdmi_tx.vhd`) | Nota |
|---|---|---|
| 16:9 en vez de 4:3 | `AVI`: PB2 `x"18"` → `x"28"`, PB4 `x"02"` → `x"03"`, PB0 `x"BB"` → `x"AA"` | PB0 se recalcula siempre |
| RGB limitado | `AVI`: PB3 `x"88"` → `x"84"`, PB0 `x"BB"` → `x"BF"` | Además hay que escalar la imagen a 16-235 |
| Solo imagen | `FULL => false` | Para monitores DVI |

**Suma de un InfoFrame:** PB0 = 256 − ((HB0 + HB1 + HB2 + PB1 + PB2 + …) mod 256).

Cambiar la frecuencia de audio obliga a cambiar el contador de muestras, N, CTS y el estado de
canal. Con 27 MHz, 48 kHz es la más sencilla.

## 9. Cómo está hecho

Cada línea, en los 138 píxeles de borrado:

| Píxel | Contenido |
|---|---|
| 720-727 | control |
| 728-735 | preámbulo de datos |
| 736-737 | guarda |
| 738… | 1 a 3 paquetes de 32 píxeles |
| 2 siguientes | guarda |
| hasta 847 | control |
| 848-855 | preámbulo de vídeo (solo si la línea siguiente es visible) |
| 856-857 | guarda de vídeo |

| Paquete | Cuándo |
|---|---|
| Audio (1 muestra por paquete) | hasta 2 por línea; hacen falta 1,53 de media |
| ACR (N, CTS) | líneas múltiplo de 32 |
| AVI InfoFrame | líneas 10 y 490 |
| Audio InfoFrame | líneas 11 y 491 |
| Control general (quita el mute) | línea 484 |

Los paquetes fijos se calculan al sintetizar, con su BCH. Solo el de audio se calcula al vuelo.

## 10. Lista de comprobación

- [ ] Copiados los 4 archivos; quitados `hdmi_module` e `hdmi_impl`
- [ ] Todo el vídeo usa `clk_pixel` de `hdmi_phy`
- [ ] Cruces de dominio revisados (registros de la CPU, BSRAM de doble puerto)
- [ ] Contadores 858 × 525 y regla de los 2 ciclos
- [ ] Sincronismos de §4.2
- [ ] Audio con signo, congelado con `audio_req`
- [ ] Pines y SDC
- [ ] Simulación de §7 sin errores
- [ ] Probado primero con `FULL => false` y después con `true`

## 11. Si algo falla

| Síntoma | Mira primero |
|---|---|
| Ni con `FULL => false` se ve | Relojes (§3), pines, sincronismos |
| Con `false` se ve y con `true` no | Regla de los 2 ciclos (§4.1) |
| Línea rosa o verde al borde | Monitor solo DVI: usa `FULL => false` |
| Imagen sin sonido | Formato con signo, `audio_req` sincronizado, volumen y entrada de la tele |
| Sonido con chasquidos | `audio` cambia mientras se lee: congélalo (§5) |
| Sonido muy fuerte o distorsionado | Sonido sin signo conectado sin invertir el bit alto |
| Bandas a los lados | Es 4:3; ver §8 |

## 12. Estado de las pruebas

- **Monitor:** imagen y audio correctos en la placa (2026-11-24).
- **Tele Samsung reciente:** pantalla negra. **Sin resolver**; no se sabe si es la señal, el
  formato o la detección. Queda pendiente probar con `FULL => false` y con otros proyectos.
- Solo se ha integrado en este proyecto. Las instrucciones para otros salen de esa integración
  y no se han ejecutado en ninguno.
