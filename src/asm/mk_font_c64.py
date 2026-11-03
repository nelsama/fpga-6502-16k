#!/usr/bin/env python3
# mk_font_c64.py -- genera font_data.vhd a partir del charset del C64
# (c64_charrom.bin, 4096 bytes = 2 juegos de 2048 bytes).
#
# Uso:
#   python mk_font_c64.py                 -> imprime la tabla .byte (ASCII $20..$7F)
#   python mk_font_c64.py vhd <salida>    -> genera el paquete VHDL precargado
#   python mk_font_c64.py show <chars>    -> muestra glifos (SIRVE PARA VALIDAR EL MAPA)
#
# Se usa el JUEGO 2 (offset $800): mayusculas Y minusculas, ya en formato
# "1 = TINTA", sin invertir.
#
# Direccion en font_arr = (ascii - $20) * 8 + fila   (0..767)
#
# MAPA DEL CHARGEN (juego 2) -- NO coincide con el ASCII:
#
#   $00      @              $20       espacio
#   $01..$08 a b c d e f g h $21..$28 ! " # $ % & ' (
#   $09..$0A i j            $29..$2A ) *
#   $0B..$0C k l            $2B..$2C + ,
#   $0D..$0E m n            $2D..$2E - .
#   $0F..$10 o p            $2F..$30 / 0
#   $11..$14 q r s t        $31..$34 1 2 3 4
#   $15..$16 u v            $35..$36 5 6
#   $17..$1A w x y z        $37..$3A 7 8 9 :
#   $41..$5A A..Z           $3B..$3C ; <
#                           $3D      =
#                           $3E      >
#                           $3F      ?
#   $5B [   $5C (barra)   $5D ]
#
# OJO: las minusculas estan ARRIBA ($01..$1A) y las mayusculas ABAJO ($41..$5A).
# Historicamente este script lo tenia al reves y el resultado era que el tile
# '.' (ASCII $2E) mostraba una 'M': las letras caian en los huecos de los signos.
#
# No existen en el chargen (quedan en blanco): '`', '{', '|', '}', '~'
# (uso Python en el shell de pruebas)

import sys

CHARGEN = "c64_charrom.bin"
GAME2   = 0x800          # segundo juego: mayusculas + minusculas

# ASCII -> codigo dentro del juego 2.
ASCII_TO_C64 = {'@': 0x00}

# minusculas: $01..$1A
for _i in range(26):
    ASCII_TO_C64[chr(ord('a') + _i)] = 0x01 + _i

# espacio y puntuacion $20..$3F (incluye ; < = > ?, que el chargen SI tiene)
for _c in range(0x20, 0x40):
    ASCII_TO_C64[chr(_c)] = _c

# mayusculas: $41..$5A
for _i in range(26):
    ASCII_TO_C64[chr(ord('A') + _i)] = 0x41 + _i

# corchetes, barra invertida, circunflejo y subrayado
ASCII_TO_C64['['] = 0x5B
ASCII_TO_C64['\\'] = 0x5C
ASCII_TO_C64[']'] = 0x5D
ASCII_TO_C64['^'] = 0x5E
ASCII_TO_C64['_'] = 0x5F

MAP = ASCII_TO_C64

MISSING = "\\^_`{|}~"


def load():
    with open(CHARGEN, "rb") as f:
        return f.read()


def glyph(data, code):
    o = GAME2 + code * 8
    return [data[o + i] for i in range(8)]


def build():
    data = load()
    out = [0] * 1024
    for ascii_code in range(0x20, 0x80):
        ch = chr(ascii_code)
        loc = MAP.get(ch)
        rows = glyph(data, loc) if loc is not None else [0] * 8
        for i, b in enumerate(rows):
            out[(ascii_code - 0x20) * 8 + i] = b
    return out


def emit_inc():
    data = build()
    print("; generado por mk_font_c64.py -- fuente 8x8 1bpp, ASCII $20..$7F")
    print("; origen: charset del C64 (juego 2), remapeado a ASCII")
    print("font_data:")
    for i in range(0, len(data), 16):
        fila = ", ".join(f"${b:02X}" for b in data[i:i+16])
        print(f"    .byte {fila}")


def emit_vhd(path):
    data = build()           # 1024 filas: 768 utiles + ceros
    real = 768               # 96 caracteres x 8 filas
    assert all(b == 0 for b in data[real:]), "hay datos fuera de las 768 filas"
    out = []
    out.append("-- ======================================================")
    out.append("-- font_data.vhd -- fuente 8x8 1bpp (charset del C64)")
    out.append("-- 1024 entradas x 9 bits; usadas 768 (96 chars x 8 filas)")
    out.append("-- Juego 2 del chargen ($800), remapeado a ASCII")
    out.append("--")
    out.append("-- La tabla declara las 768 filas reales (0..767); el resto hasta 1023")
    out.append("-- cae en 'others' y queda a cero.")
    out.append("--")
    out.append("-- GENERADO CON mk_font_c64.py -- NO EDITAR A MANO.")
    out.append("-- ======================================================")
    out.append("")
    out.append("library ieee;")
    out.append("use ieee.std_logic_1164.all;")
    out.append("use ieee.numeric_std.all;")
    out.append("")
    out.append("package font_pkg is")
    out.append("    type font_init_t is array (0 to 1023) of std_logic_vector(8 downto 0);")
    out.append("    constant FONT_INIT : font_init_t := (")
    for i in range(0, real, 8):
        cells = " ".join(f'{j} => "0" & x"{data[j]:02X}",' for j in range(i, i + 8))
        out.append("        " + cells)
    out.append('        others => "0" & x"00"')
    out.append("    );")
    out.append("end package;")
    out.append("")
    with open(path, "w", newline="\n") as f:
        f.write("\n".join(out))
    print(f"OK: {path} generado ({real} filas reales de {len(data)})")


def show(char):
    d = load()
    code = MAP.get(char)
    if code is None:
        print(f"--- {char!r}: NO EXISTE en el chargen (queda en blanco)")
        return
    print(f"--- {char!r} (codigo C64 {code:02X}) ---")
    for b in glyph(d, code):
        print("  " + "".join("#" if b & (0x80 >> x) else "." for x in range(8)))


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "vhd":
        emit_vhd(sys.argv[2])
    elif len(sys.argv) > 2 and sys.argv[1] == "show":
        for ch in sys.argv[2]:
            show(ch)
    else:
        emit_inc()
