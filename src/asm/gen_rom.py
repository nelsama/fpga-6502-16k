#!/usr/bin/env python3
# Genera rom.vhd a partir de un binario de 16 KB (mismo formato que el monitor)
import sys, os

def main(bin_path, vhd_path):
    with open(bin_path, "rb") as f:
        data = bytearray(f.read())
    if len(data) != 16384:
        print(f"WARN: tamanio {len(data)} bytes (se esperaban 16384)")
    # ====================================================================
    # VECTORES del 6502 (el CPU los lee en $FFFA-$FFFF, que el Data_bus_mux
    # redirige a la ROM fisica $3FFA-$3FFF):
    #   $3FFA-$3FFB : NMI   -> $8000
    #   $3FFC-$3FFD : RESET -> $8000
    #   $3FFE-$3FFF : IRQ   -> $8000
    # Se inyectan a mano para no depender del .org del ensamblador.
    # ====================================================================
    data[0x3FFA] = 0x00
    data[0x3FFB] = 0x80
    data[0x3FFC] = 0x00
    data[0x3FFD] = 0x80
    data[0x3FFE] = 0x00
    data[0x3FFF] = 0x80
    lines = []
    lines.append("-- ======================================================")
    lines.append("-- ROM generada automaticamente (video_test.asm)")
    lines.append("-- Prueba Fase 4: CPU escribe la VRAM ($D800-$D802)")
    lines.append("-- ======================================================")
    lines.append("")
    lines.append("library ieee;")
    lines.append("use ieee.std_logic_1164.all;")
    lines.append("use ieee.numeric_std.all;")
    lines.append("")
    lines.append("ENTITY rom IS")
    lines.append("    port (")
    lines.append("    clk      : in  std_logic;")
    lines.append("    address  : in  std_logic_vector(13 downto 0);")
    lines.append("    data_out : out std_logic_vector(7 downto 0)")
    lines.append("    );")
    lines.append("END entity;")
    lines.append("")
    lines.append("architecture rtl of rom is")
    lines.append("BEGIN")
    lines.append("")
    lines.append("\tPROCESS(clk)")
    lines.append("    variable addr : std_logic_vector(15 downto 0);")
    lines.append("\tBEGIN")
    lines.append("    if rising_edge(clk) then")
    lines.append("        addr:=\"00\"&address;")
    lines.append("        case addr is")
    lines.append("")
    for i, b in enumerate(data):
        lines.append(f"            when x\"{i:04X}\" => data_out<= x\"{b:02X}\";")
    lines.append("            when others => data_out<= x\"FF\";")
    lines.append("")
    lines.append("        end case;")
    lines.append("    end if;")
    lines.append("\tEND PROCESS;")
    lines.append("end architecture;")
    lines.append("")
    with open(vhd_path, "w", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"OK: {vhd_path} generado con {len(data)} entradas")

if __name__ == "__main__":
    bin_path = sys.argv[1] if len(sys.argv) > 1 else "video_test.bin"
    vhd_path = sys.argv[2] if len(sys.argv) > 2 else "../rom.vhd"
    main(bin_path, vhd_path)
