-- ============================================================================
-- HDMI_PHY.VHD - Relojes y salida serie HDMI
--
--   27 MHz -> PLL x5 = 135 MHz -> CLKDIV /5 = 27 MHz de pixel. El OSER10 exige
--   que PCLK salga de FCLK por un CLKDIV, para que su fase sea fija: el pin de
--   27 MHz no sirve como reloj de pixel.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity hdmi_phy is
    port (
        clk_27    : in  std_logic;
        clk_pixel : out std_logic;
        q0, q1, q2 : in std_logic_vector(9 downto 0);
        tmds_c0_p, tmds_c0_n : out std_logic;
        tmds_c1_p, tmds_c1_n : out std_logic;
        tmds_c2_p, tmds_c2_n : out std_logic;
        tmds_ck_p, tmds_ck_n : out std_logic
    );
end entity;

architecture rtl of hdmi_phy is
    component CLKDIV
        generic (
            DIV_MODE : string := "2";
            GSREN    : string := "false"
        );
        port (
            CLKOUT : out std_logic;
            HCLKIN : in  std_logic;
            RESETN : in  std_logic;
            CALIB  : in  std_logic
        );
    end component;
    component OSER10
        generic (
            GSREN : string := "false";
            LSREN : string := "false"
        );
        port (
            Q : out std_logic;
            D0, D1, D2, D3, D4, D5, D6, D7, D8, D9 : in std_logic;
            FCLK, PCLK, RESET : in std_logic
        );
    end component;
    component ELVDS_OBUF
        port (
            O, OB : out std_logic;
            I     : in  std_logic
        );
    end component;

    signal clk_135, clk_pix, lock : std_logic;
    signal rsr : std_logic_vector(3 downto 0) := "1111";
    signal s0, s1, s2, sc : std_logic;
begin
    clk_pixel <= clk_pix;

    pll_x5 : entity work.clk_27x5
        port map (clkout => clk_135, clkoutp => open, lock => lock, clkin => clk_27);

    div5 : CLKDIV
        generic map (DIV_MODE => "5", GSREN => "false")
        port map (CLKOUT => clk_pix, HCLKIN => clk_135, RESETN => lock, CALIB => '0');

    process (clk_pix, lock)
    begin
        if lock = '0' then
            rsr <= "1111";
        elsif rising_edge(clk_pix) then
            rsr <= rsr(2 downto 0) & '0';
        end if;
    end process;

    ser0 : OSER10 port map (Q => s0, D0 => q0(0), D1 => q0(1), D2 => q0(2), D3 => q0(3), D4 => q0(4),
        D5 => q0(5), D6 => q0(6), D7 => q0(7), D8 => q0(8), D9 => q0(9), FCLK => clk_135, PCLK => clk_pix, RESET => rsr(3));
    ser1 : OSER10 port map (Q => s1, D0 => q1(0), D1 => q1(1), D2 => q1(2), D3 => q1(3), D4 => q1(4),
        D5 => q1(5), D6 => q1(6), D7 => q1(7), D8 => q1(8), D9 => q1(9), FCLK => clk_135, PCLK => clk_pix, RESET => rsr(3));
    ser2 : OSER10 port map (Q => s2, D0 => q2(0), D1 => q2(1), D2 => q2(2), D3 => q2(3), D4 => q2(4),
        D5 => q2(5), D6 => q2(6), D7 => q2(7), D8 => q2(8), D9 => q2(9), FCLK => clk_135, PCLK => clk_pix, RESET => rsr(3));

    -- el reloj sale por un serializador igual que los datos: mismo retardo
    serc : OSER10 port map (Q => sc, D0 => '1', D1 => '1', D2 => '1', D3 => '1', D4 => '1',
        D5 => '0', D6 => '0', D7 => '0', D8 => '0', D9 => '0', FCLK => clk_135, PCLK => clk_pix, RESET => rsr(3));

    buf0 : ELVDS_OBUF port map (O => tmds_c0_p, OB => tmds_c0_n, I => s0);
    buf1 : ELVDS_OBUF port map (O => tmds_c1_p, OB => tmds_c1_n, I => s1);
    buf2 : ELVDS_OBUF port map (O => tmds_c2_p, OB => tmds_c2_n, I => s2);
    bufc : ELVDS_OBUF port map (O => tmds_ck_p, OB => tmds_ck_n, I => sc);
end architecture;
