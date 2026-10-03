#!/usr/bin/env python3
# mk_sprite.py -- convierte arte ASCII de sprites a tablas .byte (2bpp planar).
#
# Uso:  python mk_sprite.py > sprite_data.inc
#
# Caracteres:
#   '.' = transparente (color 0)
#   '1' = color 1
#   '2' = color 2
#   '3' = color 3
#
# Para un sprite 16x16 se define la imagen COMPLETA (16x16) y el script la
# recorta automaticamente en 4 cuadrantes de 8x8 (A sup-izq, B sup-der,
# C inf-izq, D inf-der), generando las 8 tablas (p0/p1 por cuadrante).


def _plano(filas, bit_plano):
    """Convierte filas de 8 caracteres al plano indicado (0 o 1)."""
    out = []
    for fila in filas:
        b = 0
        for x, ch in enumerate(fila):
            if ch == '.':
                continue
            v = int(ch)               # 0..3
            if (v >> bit_plano) & 1:
                b |= (0x80 >> x)
        out.append(b)
    return out


def _emitir(nombre, filas):
    p0 = _plano(filas, 0)
    p1 = _plano(filas, 1)
    print(f"{nombre}_p0:")
    print("    .byte " + ", ".join(f"${v:02X}" for v in p0))
    print(f"{nombre}_p1:")
    print("    .byte " + ", ".join(f"${v:02X}" for v in p1))
    print()


def sprite16(imagen):
    """imagen: 16 strings de 16 caracteres. Genera A,B,C,D (8x8)."""
    assert len(imagen) == 16, "se esperaban 16 filas"
    A = [f[0:8] for f in imagen[0:8]]
    B = [f[8:16] for f in imagen[0:8]]
    C = [f[0:8] for f in imagen[8:16]]
    D = [f[8:16] for f in imagen[8:16]]
    return A, B, C, D


# ============================================================================
# MUNECO 16x16  (simetrico; el script lo recorta en 4 cuadrantes)
# ============================================================================
MUNECO = [
    ".....333333.....",
    "...3311111133...",
    "..331111111133..",
    "..311221122113..",
    "..311221122113..",
    "..311111111113..",
    "..331133331133..",
    "...3111111113...",
    "....31111113....",
    "...1111111111...",
    "..111111111111..",
    "..111111111111..",
    "..111111111111..",
    "..111111111111..",
    "...11......11...",
    "...11......11...",
]

if __name__ == "__main__":
    print("; generado por mk_sprite.py -- no editar a mano")
    print()
    A, B, C, D = sprite16(MUNECO)
    _emitir("dollA", A)
    _emitir("dollB", B)
    _emitir("dollC", C)
    _emitir("dollD", D)
