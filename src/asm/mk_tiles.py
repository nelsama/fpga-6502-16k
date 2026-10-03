#!/usr/bin/env python3
# mk_tiles.py -- convierte arte ASCII a tablas .byte (2bpp planar).
#
# Uso:  python mk_tiles.py > tiles_data.inc
#
# Caracteres:
#   '.' = color 0 (en el FONDO es TRANSPARENTE)
#   '1' = color 1
#   '2' = color 2
#   '3' = color 3
#
# - tile8(nombre, imagen): un tile 8x8
# - sprite16(nombre, imagen): un sprite 16x16 recortado en 4 cuadrantes 8x8


def _plano(filas, bit_plano):
    out = []
    for fila in filas:
        b = 0
        for x, ch in enumerate(fila):
            if ch == '.':
                continue
            v = int(ch)
            if (v >> bit_plano) & 1:
                b |= (0x80 >> x)
        out.append(b)
    return out


def emitir(nombre, filas):
    p0 = _plano(filas, 0)
    p1 = _plano(filas, 1)
    print(f"{nombre}_p0:")
    print("    .byte " + ", ".join(f"${v:02X}" for v in p0))
    print(f"{nombre}_p1:")
    print("    .byte " + ", ".join(f"${v:02X}" for v in p1))
    print()


def tile8(nombre, imagen):
    assert len(imagen) == 8, f"{nombre}: se esperaban 8 filas"
    for i, f in enumerate(imagen):
        assert len(f) == 8, f"{nombre} fila {i}: {len(f)} cols (esperadas 8): {f!r}"
    emitir(nombre, imagen)


def sprite16(nombre, imagen):
    assert len(imagen) == 16, f"{nombre}: se esperaban 16 filas"
    for i, f in enumerate(imagen):
        assert len(f) == 16, f"{nombre} fila {i}: {len(f)} cols (esperadas 16): {f!r}"
    emitir(nombre + "A", [f[0:8] for f in imagen[0:8]])
    emitir(nombre + "B", [f[8:16] for f in imagen[0:8]])
    emitir(nombre + "C", [f[0:8] for f in imagen[8:16]])
    emitir(nombre + "D", [f[8:16] for f in imagen[8:16]])


# ============================================================================
# CASA 16x16 (4 tiles 8x8). Paleta de fondo usada: paleta 1 (negro/calipso).
#   color 1 = pared, 2 = tejado, 3 = contorno, . = transparente (puerta)
# ============================================================================
CASA = [
    "................",   # 0
    ".......33.......",   # 1
    "......3223......",   # 2
    ".....322223.....",   # 3
    "....32222223....",   # 4
    "...3222222223...",   # 5
    "..322222222223..",   # 6
    ".32222222222223.",   # 7
    "3333333333333333",   # 8
    ".3111111111113..",   # 9
    ".3111111111113..",   # 10
    ".3111......1113.",   # 11  puerta
    ".3111......1113.",   # 12
    ".3111......1113.",   # 13
    ".3111......1113.",   # 14
    ".33333333333333.",   # 15
]


if __name__ == "__main__":
    print("; generado por mk_tiles.py -- no editar a mano")
    print()
    sprite16("casa", CASA)
