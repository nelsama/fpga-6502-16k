-- RAM de 2 KB en un bloque BSRAM: pagina cero y pila ($0000-$07FF).
-- Misma temporizacion que la RAM de 16 KB a la que sustituye.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_2k is
    port (
        clk  : in  std_logic;
        ce   : in  std_logic;
        wre  : in  std_logic;
        ad   : in  std_logic_vector(10 downto 0);
        din  : in  std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of ram_2k is
    type mem_t is array (0 to 2047) of std_logic_vector(7 downto 0);
    signal mem : mem_t := (others => (others => '0'));
    attribute syn_ramstyle : string;
    attribute syn_ramstyle of mem : signal is "block_ram";
    signal q   : std_logic_vector(7 downto 0) := (others => '0');
begin
    dout <= q;
    process (clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                if wre = '1' then
                    mem(to_integer(unsigned(ad))) <= din;
                else
                    q <= mem(to_integer(unsigned(ad)));
                end if;
            end if;
        end if;
    end process;
end architecture;
