library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;    

entity data_bus_mux is 
    port(   
            clk: in std_logic;
            r_w: in std_logic;
            addr_in : in std_logic_vector(15 downto 0);

            ram_data_bus_in : in std_logic_vector(7 downto 0);
            rom_data_bus_in : in std_logic_vector(7 downto 0);
            port1_in : in std_logic_vector(7 downto 0);
            port2_in : in std_logic_vector(7 downto 0);

            rom_addr_out : out std_logic_vector(15 downto 0);  -- NUEVO: dirección para la ROM
            data_bus_out : out std_logic_vector(7 downto 0)
    );
end data_bus_mux;

architecture arch of data_bus_mux is
    
    -- === CONFIGURACIÓN DE MEMORIA ROM (fácil de cambiar) ===
    constant ROM_BASE  : unsigned(15 downto 0) := x"8000";  -- Inicio de ROM
    constant ROM_SIZE  : unsigned(15 downto 0) := x"4000";  -- Tamaño ROM (16KB = 0x4000)
    constant ROM_END   : unsigned(15 downto 0) := ROM_BASE + ROM_SIZE - 1;  -- Fin de ROM (0xBFFF)
    
    -- Segundo bloque ROM ($A000-$BFFF) - contiguo al primero
    constant ROM_BLOCK2_BASE : unsigned(15 downto 0) := x"A000";
    constant ROM_BLOCK2_END  : unsigned(15 downto 0) := x"BFFF";

    constant RAM_BASE  : unsigned(15 downto 0) := x"0000";  -- Inicio de RAM
    constant RAM_SIZE  : unsigned(15 downto 0) := x"4000";  -- Tamaño RAM (16KB = 0x4000)
    constant RAM_END   : unsigned(15 downto 0) := RAM_BASE + RAM_SIZE - 1;  -- Fin de RAM (0x3FFF)
    
    signal addr_unsigned : unsigned(15 downto 0);
    signal rom_physical_addr : unsigned(15 downto 0);
    
begin

    addr_unsigned <= unsigned(addr_in);
    
    -- === MAPEO DE DIRECCIONES PARA ROM ===
    -- ROM de 16KB: $8000-$9FFF (bloque 1) + $A000-$BFFF (bloque 2)
    -- Vectores $FFFA-$FFFF redirigidos a últimos 6 bytes de ROM ($BFFA-$BFFF)
    process(addr_in, addr_unsigned)
    begin
        if (addr_unsigned >= x"FFFA" and addr_unsigned <= x"FFFF") then
            -- Mapeo vectores: $FFFA->$BFFA, $FFFB->$BFFB, ..., $FFFF->$BFFF
            rom_physical_addr <= ROM_BASE + ROM_SIZE - 6 + (addr_unsigned - x"FFFA");
        elsif (addr_unsigned >= ROM_BASE and addr_unsigned <= ROM_END) then
            -- Dirección normal en rango ROM ($8000-$BFFF)
            rom_physical_addr <= addr_unsigned;
        else
            -- Fuera de ROM
            rom_physical_addr <= (others => '0');
        end if;
    end process;
    
    -- Salida de dirección para el módulo ROM
    rom_addr_out <= std_logic_vector(rom_physical_addr);

    -- === MULTIPLEXOR DE DATOS ===
    process(clk, r_w, addr_in, ram_data_bus_in, rom_data_bus_in, port1_in, port2_in)
    begin
        if(falling_edge(clk)) then
            if ((addr_unsigned >= RAM_BASE) and (addr_unsigned <= RAM_END) and r_w='1') then 
                -- RAM: 0x0000 - 0x3FFF
                data_bus_out <= ram_data_bus_in; 
                
            elsif (((addr_unsigned >= ROM_BASE) and (addr_unsigned <= ROM_END)) or 
                   (addr_unsigned >= x"FFFA" and addr_unsigned <= x"FFFF")) and r_w='1' then 
                -- ROM: 0x8000-0xBFFF (16KB) O vectores 0xFFFA-0xFFFF (ambos leen de ROM)
                data_bus_out <= rom_data_bus_in;  
                
            elsif (addr_in = x"C000" and r_w='1') then 
                -- Puerto 1
                data_bus_out <= port1_in;
                
            elsif (addr_in = x"C001" and r_w='1') then 
                -- Puerto 2
                data_bus_out <= port2_in; 
                
            else
                data_bus_out <= "ZZZZZZZZ";
            end if; 
        end if;
    end process;

end arch;
