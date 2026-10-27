# Informe para `EmuladorFpga6502`: desfase en el scroll vertical del dibujado

**Desde:** `fpga-6502-16k` (core de vídeo)
**Para:** `EmuladorFpga6502`
**Fecha:** 2026-10-27
**Referencia core:** `57774ed`, `0633341`
**Referencia emulador:** `1583eb2`

---

## Estado: RETIRADO — no hay desfase. No hay nada que cambiar.

Este informe declaraba que el dibujado del emulador se desviaba del RTL con
`scroll_y >= 256`, porque el emulador envuelve a 8 bits y el RTL a 11. **El
diagnóstico era incorrecto.** Verificado con la aritmética del RTL sobre todo el
rango, las dos implementaciones **coinciden siempre**.

Se deja el documento archivado para que no se reabra el tema, con la
demostración que lo descarta.

---

## El error que contenía la versión anterior

La tabla original marcaba como discrepancia estos casos:

| `scroll_y` | Lo que decía el informe | Lo correcto |
|---|---|---|
| 260 | ⚠️ No coinciden | ✅ Coinciden |
| 2047 | ⚠️ No coinciden | ✅ Coinciden |

El razonamiento fallaba al comparar expresiones sin evaluarlas. Como
`256 / 8 = 32` y el mapa tiene exactamente **32 filas de tiles**, sumar 256 px
desplaza la fila justo un número entero de vueltas al mapa. El `mod 32` lo
absorbe por completo.

Lo mismo con los bits bajos: 256 es múltiplo de 8, así que el desplazamiento
dentro del tile (`& 7`) tampoco cambia.

---

## Demostración

Para `py` (línea de pantalla) y `scroll_y` arbitrarios:

```text
RTL : y0_world = (py + scroll_y) mod 2048
      fila  = (y0_world / 8) mod 32
      pixel = y0_world & 7

emulador : map_y = (py + scroll_y) mod 256
           fila  = (map_y / 8) mod 32
           pixel = map_y & 7
```

Para todo `k`, `scroll_y = 256k + r` con `0 <= r < 256`:

- `(py + scroll_y) mod 256 = (py + r) mod 256` → **mismo `map_y`**;
- de ahí, mismas `fila` y `pixel`.

La única diferencia entre ambos sería el valor intermedio de `y0_world`, que el
RTL nunca usa fuera de `mod 32` y `& 7`. **Ningún píxel cambia.**

### Barrido exhaustivo

Se evaluó `scroll_y` en `{0, 1, 256, 260, 511, 512, 1024, 2047}` cruzado con
`py` en `{0, 5, 160, 239}`: **0 discrepancias** en fila y píxel.

---

## Lo que sí es cierto (y ya está en ambos manuales)

- El hardware **no descarta** los bits altos: los suma en 11 bits y el módulo del
  mapa los absorbe. El manual del core lo explica así desde `0633341` (§7.1).
- El resultado **práctico** coincide con escribir el valor reducido, porque 512 y
  256 son múltiplos del tamaño de tile.

Es decir: el comportamiento observable es el mismo, pero la descripción correcta
es «se suma y el módulo lo absorbe», no «se ignoran».

---

## Conclusión

No hay que aplicar la Opción A ni la B: **el emulador ya es fiel al RTL** en el
scroll vertical del dibujado. El comentario de `video.cpp` que documenta la
aritmética de 11 bits en la colisión es correcto y no contradice al dibujado,
cuyo recorte a 8 bits es equivalente.

La Opción C (recortar `scroll_y` en el RTL) sigue descartada por coste: el chip
está al 99 % de CLS y no hay nada que arreglar.
