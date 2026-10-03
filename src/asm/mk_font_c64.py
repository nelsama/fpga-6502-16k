#!/usr/bin/env python3
# mk_font_c64.py -- genera font_data.vhd a partir del charset ORIGINAL del C64
# (characters.901225-01.bin, 4096 bytes = 2 juegos de 2048 bytes).
#
# Uso:
#   python mk_font_c64.py                 -> imprime la tabla .byte (ASCII $20..$7F)
#   python mk_font_c64.py vhd <salida>    -> genera el paquete VHDL precargado
#   python mk_font_c64.py show <chars>    -> muestra glifos (diagnostico)
#
# Se usa el JUEGO 2 (offset $800), que contiene mayusculas Y minusculas y ya
# esta en el formato correcto (1 = TINTA), SIN necesidad de invertir.
#
# Direccion en font_arr = (ascii - $20) * 8 + fila   (0..767)
#
# Mapeo verificado contra el binario original:
#   espacio : $20        @      : $00
#   signos  : $21..$3F (coinciden con ASCII)
#   A-Z     : $41..$5A (coinciden con ASCII)
#   a-z     : $01..$1A (en ASCII estan en $61..$7A -> remapear)

import sys

CHARGEN = "c64_charrom.bin"
GAME2   = 0x800          # segundo juego: mayusculas + minusculas


def ascii_map():
    """ASCII -> codigo dentro del juego 2."""
    m = {}
    # Signos y digitos: coinciden con ASCII en el rango $20..$3F
    for i in range(ord(' '), ord('@')):    # $20..$3F
        m[chr(i)] = i
    m['@'] = 0x00
    # Mayusculas: $41..$5A (coinciden con ASCII)
    for i in range(26):
        m[chr(ord('A') + i)] = 0x41 + i
    # Minusculas: en el juego 2 estan en $01..$1A
    for i in range(26):
        m[chr(ord('a') + i)] = 0x01 + i
    # Signos adicionales presentes (no todo el ASCII esta en el C64)
    m['['] = 0x1B
    m[']'] = 0x1D
    return m


MAP = ascii_map()


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
        # El juego 2 ya usa 1 = tinta (mismo formato que el nuestro).
        rows = glyph(data, loc) if loc is not None else [0] * 8
        for i, b in enumerate(rows):
            out[(ascii_code - 0x20) * 8 + i] = b
    return out


def emit_inc():
    data = build()
    print("; generado por mk_font_c64.py -- fuente 8x8 1bpp, ASCII $20..$7F")
    print("; origen: charset original del C64 (juego 2), remapeado a ASCII")
    print("font_data:")
    for i in range(0, len(data), 16):
        fila = ", ".join(f"${b:02X}" for b in data[i:i+16])
        print(f"    .byte {fila}")


def emit_vhd(path):
    data = build()
    lines = []
    lines.append("-- ======================================================")
    lines.append("-- font_data.vhd -- fuente 8x8 1bpp (charset original del C64)")
    lines.append("-- 1024 entradas x 9 bits; usadas 768 (96 chars x 8 filas)")
    lines.append("-- Juego 2 del chargen ($800), remapeado a ASCII")
    lines.append("-- ======================================================")
    lines.append("")
    lines.append("library ieee;")
    lines.append("use ieee.std_logic_1164.all;")
    lines.append("use ieee.numeric_std.all;")
    lines.append("")
    lines.append("package font_pkg is")
    lines.append("    type font_init_t is array (0 to 1023) of std_logic_vector(8 downto 0);")
    lines.append("    constant FONT_INIT : font_init_t := (")
    for i, b in enumerate(data):
        comma = "," if i < len(data) - 1 else ""
        lines.append(f'        {i} => "0" & x"{b:02X}"{comma}')
    lines.append("    );")
    lines.append("end package;")
    lines.append("")
    with open(path, "w", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"OK: {path} generado ({len(data)} entradas)")


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "vhd":
        emit_vhd(sys.argv[2])
    elif len(sys.argv) > 2 and sys.argv[1] == "show":
        d = load()
        for ch in sys.argv[2]:
            loc = MAP.get(ch, 0)
            print(f"--- {ch!r} (code {loc:02X}) ---")
            for b in glyph(d, loc):
                print("  " + "".join("#" if b & (0x80 >> x) else "." for x in range(8)))
    else:
        emit_inc()
