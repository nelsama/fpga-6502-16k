-- ============================================================================
-- PSRAM_RAM.VHD - PSRAM interna como RAM del 6502, sin wait-states
--
--   Un acceso por ciclo de CPU (296 ns = 24 clk de 81 MHz):
--     flanco de subida de cpu_clk -> 3 clk de sincronizacion -> peticion
--     lectura: dato valido antes de 225 ns | escritura: termina antes de 165 ns
--   La direccion, we y el dato salen de registros de la CPU y son estables
--   cuando se capturan (25 ns o mas despues del flanco).
--
--   Al configurar la FPGA se pone a cero (2**ZBITS palabras), como arrancaba
--   la BSRAM. El reset de la placa (S1) NO la borra ni la reinicia.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psram_ram is
    generic (
        ZBITS : integer := 14            -- 2**14 palabras = 32 KB a cero
    );
    port (
        clk_mem   : in  std_logic;       -- 81 MHz
        clk_mem_p : in  std_logic;       -- 81 MHz + 90 grados
        lock      : in  std_logic;
        cpu_clk   : in  std_logic;
        sel       : in  std_logic;       -- direccion dentro de la PSRAM
        we        : in  std_logic;
        addr      : in  std_logic_vector(14 downto 0);
        din       : in  std_logic_vector(7 downto 0);
        dout      : out std_logic_vector(7 downto 0);
        ready     : out std_logic;       -- 1 = puesta a cero terminada
        O_psram_ck      : out   std_logic_vector(1 downto 0);
        O_psram_ck_n    : out   std_logic_vector(1 downto 0);
        IO_psram_rwds   : inout std_logic_vector(1 downto 0);
        IO_psram_dq     : inout std_logic_vector(15 downto 0);
        O_psram_reset_n : out   std_logic_vector(1 downto 0);
        O_psram_cs_n    : out   std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of psram_ram is
    signal por    : unsigned(7 downto 0) := (others => '0');
    signal rstn   : std_logic := '0';
    signal lk     : std_logic_vector(1 downto 0) := "00";
    signal cs     : std_logic_vector(2 downto 0) := "000";
    signal zcnt   : unsigned(ZBITS downto 0) := (others => '0');
    signal rd, wr, bw, busy : std_logic := '0';
    signal a      : std_logic_vector(21 downto 0) := (others => '0');
    signal d      : std_logic_vector(7 downto 0) := (others => '0');
    signal dd, q  : std_logic_vector(15 downto 0);
begin
    ready <= zcnt(ZBITS);

    process (clk_mem)
    begin
        if rising_edge(clk_mem) then
            -- reset local: solo al configurar o si el PLL pierde el enganche
            lk <= lk(0) & lock;
            if lk(1) = '0' then
                por <= (others => '0');
                rstn <= '0';
            elsif por /= x"FF" then
                por <= por + 1;
            else
                rstn <= '1';
            end if;

            cs <= cs(1 downto 0) & cpu_clk;

            if rstn = '0' then
                rd <= '0';
                wr <= '0';
            elsif zcnt(ZBITS) = '0' then
                -- puesta a cero, palabra a palabra
                bw <= '0';
                d <= (others => '0');
                a <= (others => '0');
                a(ZBITS downto 1) <= std_logic_vector(zcnt(ZBITS-1 downto 0));
                rd <= '0';
                if wr = '0' then
                    wr <= not busy;
                elsif busy = '0' then         -- aceptada en este flanco
                    wr <= '0';
                    zcnt <= zcnt + 1;
                end if;
            else
                bw <= '1';
                if cs(1) = '1' and cs(2) = '0' then
                    a(14 downto 0) <= addr;
                    a(21 downto 15) <= (others => '0');
                    d <= din;
                    rd <= sel and not we and not busy;
                    wr <= sel and we and not busy;
                elsif busy = '0' then
                    rd <= '0';
                    wr <= '0';
                end if;
            end if;
        end if;
    end process;

    dd   <= d & d;
    dout <= q(15 downto 8) when addr(0) = '1' else q(7 downto 0);

    u_psram : entity work.psram_burst
        generic map (FREQ => 81000000, LATENCY => 3)
        port map (
            clk => clk_mem, clk_p => clk_mem_p, resetn => rstn, fixed => '1',
            read => rd, write => wr, addr => a, len => "0000001",
            din => dd, byte_write => bw,
            dout => q, rvalid => open, wtake => open, busy => busy,
            psram_ck => O_psram_ck(0), psram_cs_n => O_psram_cs_n(0),
            psram_rwds => IO_psram_rwds(0), psram_dq => IO_psram_dq(7 downto 0)
        );

    -- segundo chip: sin usar
    O_psram_ck(1)   <= '0';
    O_psram_cs_n(1) <= '1';
    IO_psram_rwds(1) <= 'Z';
    IO_psram_dq(15 downto 8) <= (others => 'Z');
    O_psram_ck_n    <= "00";
    O_psram_reset_n <= lock & lock;
end architecture;
