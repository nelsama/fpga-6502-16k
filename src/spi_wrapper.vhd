-------------------------------------------------------------------------------
-- SPI_WRAPPER.VHD - Wrapper SPI Master para bus 6502
--
-- Direccion base: $C040 (8 registros)
--
-- Registros CPU:
--   $C040 (0): RX Data     -> IP 0x00 (read only)
--   $C041 (1): TX Data     -> IP 0x01 (write inicia transferencia)
--   $C042 (2): Status      -> IP 0x02 (read only)
--   $C043 (3): Control     -> IP 0x04 (interrupts, etc)
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

    component SPI_MASTER_Top
        port (
            I_CLK       : in  std_logic;
            I_RESETN    : in  std_logic;
            I_TX_EN     : in  std_logic;
            I_WADDR     : in  std_logic_vector(2 downto 0);
            I_WDATA     : in  std_logic_vector(7 downto 0);
            I_RX_EN     : in  std_logic;
            I_RADDR     : in  std_logic_vector(2 downto 0);
            O_RDATA     : out std_logic_vector(7 downto 0);
            O_SPI_INT   : out std_logic;
            MISO_MASTER : in  std_logic;
            MOSI_MASTER : out std_logic;
            SS_N_MASTER : out std_logic_vector(3 downto 0);
            SCLK_MASTER : out std_logic;
            MISO_SLAVE  : out std_logic;
            MOSI_SLAVE  : in  std_logic;
            SS_N_SLAVE  : in  std_logic;
            SCLK_SLAVE  : in  std_logic
        );
    end component;

    -- Decodificacion
    signal cs           : std_logic;
    signal cpu_reg      : std_logic_vector(2 downto 0);
    
    -- Senales al IP
    signal ip_waddr     : std_logic_vector(2 downto 0);
    signal ip_raddr     : std_logic_vector(2 downto 0);
    signal tx_en        : std_logic := '0';
    signal rx_en        : std_logic;
    signal spi_rdata    : std_logic_vector(7 downto 0);
    signal spi_int      : std_logic;
    signal ip_cs_n      : std_logic_vector(3 downto 0);
    
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

    -- Direccion del IP para escritura
    ip_waddr <= "001" when cpu_reg = "001" else  -- TX (0x01)
                "100" when cpu_reg = "011" else  -- Control (0x04)
                "000";

    -- Direccion del IP para lectura (combinacional)
    ip_raddr <= "000" when cpu_reg = "000" else  -- RX (0x00)
                "001" when cpu_reg = "001" else  -- TX (0x01)
                "010" when cpu_reg = "010" else  -- Status (0x02)
                "100" when cpu_reg = "011" else  -- Control (0x04)
                "000";

    -- RX_EN siempre activo cuando leemos del IP (registros 0-3)
    rx_en <= '1' when (cs = '1' and cpu_rw = '1' and cpu_reg(2) = '0') else '0';

    -- Instancia del SPI Master
    spi_master_inst: SPI_MASTER_Top
        port map (
            I_CLK       => clk,
            I_RESETN    => rst_n,
            I_TX_EN     => tx_en,
            I_WADDR     => ip_waddr,
            I_WDATA     => cpu_data_in,
            I_RX_EN     => rx_en,
            I_RADDR     => ip_raddr,
            O_RDATA     => spi_rdata,
            O_SPI_INT   => spi_int,
            MISO_MASTER => spi_miso,
            MOSI_MASTER => spi_mosi,
            SS_N_MASTER => ip_cs_n,
            SCLK_MASTER => spi_sclk,
            MISO_SLAVE  => open,
            MOSI_SLAVE  => '0',
            SS_N_SLAVE  => '1',
            SCLK_SLAVE  => '0'
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
    
    spi_irq <= spi_int;

end rtl;
