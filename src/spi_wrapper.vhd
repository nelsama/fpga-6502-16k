-------------------------------------------------------------------------------
-- SPI_WRAPPER.VHD - Wrapper SPI Master para bus 6502
--
-- Direccion base: $C040 (8 registros)
--
-- Registros CPU:
--   $C040 (0): RX Data     -> reg 0x00 (read only)
--   $C041 (1): TX Data     -> reg 0x01 (write inicia transferencia)
--   $C042 (2): Status      -> reg 0x02 (read only)
--   $C043 (3): Control     -> 4 bits de uso libre (sin efecto)
--   $C044 (4): Slave Sel   -> LOCAL (mascara CS, bit0=CS0, bit1=CS1, etc)
--   $C045 (5): CS Control  -> LOCAL (bit0=1 activa CS seleccionado)
--
-- Status: ROE(2), TOE(3), TMT(4), TRDY(5), RRDY(6), E(7)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_wrapper is
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        cpu_addr    : in  std_logic_vector(15 downto 0);
        cpu_data_in : in  std_logic_vector(7 downto 0);
        cpu_data_out: out std_logic_vector(7 downto 0);
        cpu_rw      : in  std_logic;
        spi_irq     : out std_logic;
        spi_miso    : in  std_logic;
        spi_mosi    : out std_logic;
        spi_sclk    : out std_logic;
        spi_cs_n    : out std_logic_vector(3 downto 0)
    );
end spi_wrapper;

architecture rtl of spi_wrapper is

    -- Decodificacion
    signal cs           : std_logic;
    signal cpu_reg      : std_logic_vector(2 downto 0);
    
    -- Senales al SPI master
    signal ip_waddr     : std_logic_vector(2 downto 0);
    signal ip_raddr     : std_logic_vector(2 downto 0);
    signal tx_en        : std_logic := '0';
    signal rx_en        : std_logic;
    signal spi_rdata    : std_logic_vector(7 downto 0);
    
    -- Registros locales para CS
    signal ss_mask      : std_logic_vector(3 downto 0) := "0000";
    signal cs_enable    : std_logic := '0';
    
    -- Control de escritura
    signal write_done   : std_logic := '0';
    
    -- Salida combinacional
    signal data_out     : std_logic_vector(7 downto 0);

begin

    -- Decodificacion: $C040-$C047
    cs <= '1' when cpu_addr(15 downto 3) = "1100000001000" else '0';
    cpu_reg <= cpu_addr(2 downto 0);

    -- Direccion del registro para escritura
    ip_waddr <= "001" when cpu_reg = "001" else  -- TX (0x01)
                "100" when cpu_reg = "011" else  -- Control (0x04)
                "000";

    -- Direccion del registro para lectura (combinacional)
    ip_raddr <= "000" when cpu_reg = "000" else  -- RX (0x00)
                "001" when cpu_reg = "001" else  -- TX (0x01)
                "010" when cpu_reg = "010" else  -- Status (0x02)
                "100" when cpu_reg = "011" else  -- Control (0x04)
                "000";

    -- RX_EN siempre activo cuando leemos del SPI master (registros 0-3)
    rx_en <= '1' when (cs = '1' and cpu_rw = '1' and cpu_reg(2) = '0') else '0';

    -- SPI master propio (sin latches)
    spi_master_inst: entity work.spi_master
        port map (
            clk   => clk,
            rst_n => rst_n,
            tx_en => tx_en,
            waddr => ip_waddr,
            wdata => cpu_data_in,
            rx_en => rx_en,
            raddr => ip_raddr,
            rdata => spi_rdata,
            miso  => spi_miso,
            mosi  => spi_mosi,
            sclk  => spi_sclk
        );

    -- CS manual
    spi_cs_n(0) <= '0' when (cs_enable = '1' and ss_mask(0) = '1') else '1';
    spi_cs_n(1) <= '0' when (cs_enable = '1' and ss_mask(1) = '1') else '1';
    spi_cs_n(2) <= '0' when (cs_enable = '1' and ss_mask(2) = '1') else '1';
    spi_cs_n(3) <= '0' when (cs_enable = '1' and ss_mask(3) = '1') else '1';

    -- Proceso de escritura
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_en <= '0';
                write_done <= '0';
                ss_mask <= "0000";
                cs_enable <= '0';
            else
                tx_en <= '0';
                
                if cs = '1' and cpu_rw = '0' then
                    if write_done = '0' then
                        write_done <= '1';
                        
                        case cpu_reg is
                            when "001" =>  -- TX
                                tx_en <= '1';
                            when "011" =>  -- Control
                                tx_en <= '1';
                            when "100" =>  -- Slave Select (local)
                                ss_mask <= cpu_data_in(3 downto 0);
                            when "101" =>  -- CS Enable (local)
                                cs_enable <= cpu_data_in(0);
                            when others =>
                                null;
                        end case;
                    end if;
                else
                    write_done <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Mux de lectura COMBINACIONAL
    process(cpu_reg, spi_rdata, ss_mask, cs_enable)
    begin
        case cpu_reg is
            when "000" => data_out <= spi_rdata;              -- RX
            when "001" => data_out <= spi_rdata;              -- TX
            when "010" => data_out <= spi_rdata;              -- Status
            when "011" => data_out <= spi_rdata;              -- Control
            when "100" => data_out <= "0000" & ss_mask;       -- SS (local)
            when "101" => data_out <= "0000000" & cs_enable;  -- CS Enable (local)
            when others => data_out <= x"00";
        end case;
    end process;

    -- Salida al bus
    cpu_data_out <= data_out when (cs = '1' and cpu_rw = '1') else (others => 'Z');
    
    spi_irq <= '0';   -- el IP tampoco la activaba nunca (su registro de control no era accesible)

end rtl;
