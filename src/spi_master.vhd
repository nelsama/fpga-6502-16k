-- ============================================================================
-- SPI_MASTER.VHD - SPI master propio (sustituye al IP de Gowin)
--
--   Modo 0 (CPOL=0, CPHA=0), MSB primero, 8 bits, SCK = clk/2.
--   Todo en flancos de subida de clk: sin latches ni relojes derivados.
--   Los tiempos (ciclos de clk) son los mismos que los del IP sustituido.
--
--   Escritura (tx_en, 1 ciclo):
--     waddr 1 = TX (un byte en cola; si ya habia otro lo reemplaza -> TOE)
--     waddr 4 = 4 bits de uso libre (sin efecto; se pueden releer)
--   Lectura (rx_en; rdata un ciclo despues, y se mantiene):
--     raddr 0 = RX (leerlo borra RRDY) | 1 = TX | 2 = STATUS | 4 = 4 bits
--   STATUS: E(7) RRDY(6) TRDY(5) TMT(4) TOE(3) ROE(2). ROE y TOE no se borran
--   hasta el reset.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        tx_en : in  std_logic;
        waddr : in  std_logic_vector(2 downto 0);
        wdata : in  std_logic_vector(7 downto 0);
        rx_en : in  std_logic;
        raddr : in  std_logic_vector(2 downto 0);
        rdata : out std_logic_vector(7 downto 0);
        miso  : in  std_logic;
        mosi  : out std_logic;
        sclk  : out std_logic
    );
end entity;

architecture rtl of spi_master is
    -- cnt: 0 = reposo; 1..3 = espera previa; 4..23 = transferencia
    --   4 = bit 7 en MOSI con SCK bajo, 5 = SCK alto, ... 19 = ultimo SCK alto
    signal cnt    : unsigned(4 downto 0) := (others => '0');
    signal txdata : std_logic_vector(7 downto 0) := (others => '0');
    signal sh_tx  : std_logic_vector(7 downto 0) := (others => '0');
    signal sh_rx  : std_logic_vector(7 downto 0) := (others => '0');
    signal rxdata : std_logic_vector(7 downto 0) := (others => '0');
    signal free4  : std_logic_vector(3 downto 0) := (others => '0');
    signal trdy, tmt : std_logic := '1';
    signal pend, rrdy, toe, roe, sck_r, rd_rx : std_logic := '0';
    signal rdata_r : std_logic_vector(7 downto 0) := (others => '0');
begin
    sclk  <= sck_r;
    mosi  <= sh_tx(7);
    rdata <= rdata_r;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt <= (others => '0');
                txdata <= (others => '0');
                sh_tx <= (others => '0');
                sh_rx <= (others => '0');
                rxdata <= (others => '0');
                free4 <= (others => '0');
                trdy <= '1';
                pend <= '0';
                tmt <= '1';
                rrdy <= '0';
                toe <= '0';
                roe <= '0';
                sck_r <= '0';
                rdata_r <= (others => '0');
            else
                -- ---- transferencia ----
                if cnt = 0 then
                    if pend = '1' then
                        cnt <= to_unsigned(1, 5);
                        tmt <= '0';
                    else
                        tmt <= '1';
                    end if;
                elsif cnt = 3 then
                    sh_tx <= txdata;            -- bit 7 a MOSI
                    trdy <= '1';
                    cnt <= to_unsigned(4, 5);
                elsif cnt = 23 then
                    cnt <= (others => '0');
                else
                    if cnt = 1 then
                        pend <= '0';
                    end if;
                    cnt <= cnt + 1;
                    if cnt >= 4 and cnt <= 19 then
                        sck_r <= not cnt(0);
                        if cnt(0) = '0' then    -- SCK sube: muestrear
                            sh_rx <= sh_rx(6 downto 0) & miso;
                        else                    -- SCK baja: siguiente bit
                            sh_tx <= sh_tx(6 downto 0) & '0';
                        end if;
                    end if;
                end if;

                -- ---- lectura ----
                if rx_en = '1' then
                    case raddr is
                        when "000"  => rdata_r <= rxdata; rrdy <= '0';
                        when "001"  => rdata_r <= txdata;
                        when "010"  => rdata_r <= (roe or toe) & rrdy & trdy & tmt & toe & roe & "00";
                        when others => rdata_r <= "0000" & free4;
                    end case;
                end if;

                -- fin de la transferencia (gana a la lectura simultanea)
                if cnt = 20 then
                    rxdata <= sh_rx;
                    rrdy <= '1';
                    roe <= roe or rrdy;
                end if;

                -- ---- escritura ----
                if tx_en = '1' then
                    if waddr = "001" then
                        txdata <= wdata;
                        pend <= '1';
                        if cnt /= 3 then        -- si coincide con la carga, TRDY queda a 1 (como el IP)
                            trdy <= '0';
                        end if;
                        toe <= toe or not trdy;
                    elsif waddr = "100" then
                        free4 <= wdata(3 downto 0);
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
