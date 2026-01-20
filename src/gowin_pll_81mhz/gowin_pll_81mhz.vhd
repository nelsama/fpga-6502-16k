--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--Tool Version: V1.9.9.02
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9
--Device Version: C
--Created Time: Mon Jan 20 2026

library IEEE;
use IEEE.std_logic_1164.all;

entity Gowin_PLL_81MHz is
    port (
        clkout: out std_logic;
        lock:   out std_logic;
        clkin:  in std_logic
    );
end Gowin_PLL_81MHz;

architecture Behavioral of Gowin_PLL_81MHz is

    signal clkoutp_o: std_logic;
    signal clkoutd_o: std_logic;
    signal clkoutd3_o: std_logic;
    signal gw_gnd: std_logic;

    component PLL
        generic (
            FCLKIN: STRING := "27";
            DEVICE: STRING := "GW1NR-9C";
            DYN_IDIV_SEL: STRING := "false";
            IDIV_SEL: INTEGER := 0;
            DYN_FBDIV_SEL: STRING := "false";
            FBDIV_SEL: INTEGER := 2;
            DYN_ODIV_SEL: STRING := "false";
            ODIV_SEL: INTEGER := 4;
            PSDA_SEL: STRING := "0000";
            DYN_DA_EN: STRING := "false";
            DUTYDA_SEL: STRING := "1000";
            CLKOUT_FT_DIR: BIT := '1';
            CLKOUTP_FT_DIR: BIT := '1';
            CLKOUT_DLY_STEP: INTEGER := 0;
            CLKOUTP_DLY_STEP: INTEGER := 0;
            CLKFB_SEL: STRING := "internal";
            CLKOUT_BYPASS: STRING := "false";
            CLKOUTP_BYPASS: STRING := "false";
            CLKOUTD_BYPASS: STRING := "false";
            DYN_SDIV_SEL: INTEGER := 2;
            CLKOUTD_SRC: STRING := "CLKOUT";
            CLKOUTD3_SRC: STRING := "CLKOUT"
        );
        port (
            CLKOUT: out std_logic;
            LOCK: out std_logic;
            CLKOUTP: out std_logic;
            CLKOUTD: out std_logic;
            CLKOUTD3: out std_logic;
            RESET: in std_logic;
            RESET_P: in std_logic;
            CLKIN: in std_logic;
            CLKFB: in std_logic;
            FBDSEL: in std_logic_vector(5 downto 0);
            IDSEL: in std_logic_vector(5 downto 0);
            ODSEL: in std_logic_vector(5 downto 0);
            PSDA: in std_logic_vector(3 downto 0);
            DUTYDA: in std_logic_vector(3 downto 0);
            FDLY: in std_logic_vector(3 downto 0)
        );
    end component;

begin
    gw_gnd <= '0';

    pll_inst: PLL
        generic map (
            FCLKIN => "27",
            DEVICE => "GW1NR-9C",
            DYN_IDIV_SEL => "false",
            IDIV_SEL => 0,              -- Divisor entrada: /1
            DYN_FBDIV_SEL => "false",
            FBDIV_SEL => 23,            -- Multiplicador: ×24 (VCO = 27×24 = 648 MHz)
            DYN_ODIV_SEL => "false",
            ODIV_SEL => 8,              -- Divisor salida: /8 (648/8 = 81 MHz)
            PSDA_SEL => "0000",
            DYN_DA_EN => "false",
            DUTYDA_SEL => "1000",
            CLKOUT_FT_DIR => '1',
            CLKOUTP_FT_DIR => '1',
            CLKOUT_DLY_STEP => 0,
            CLKOUTP_DLY_STEP => 0,
            CLKFB_SEL => "internal",
            CLKOUT_BYPASS => "false",
            CLKOUTP_BYPASS => "false",
            CLKOUTD_BYPASS => "false",
            DYN_SDIV_SEL => 2,
            CLKOUTD_SRC => "CLKOUT",
            CLKOUTD3_SRC => "CLKOUT"
        )
        port map (
            CLKOUT => clkout,
            LOCK => lock,
            CLKOUTP => clkoutp_o,
            CLKOUTD => clkoutd_o,
            CLKOUTD3 => clkoutd3_o,
            RESET => gw_gnd,
            RESET_P => gw_gnd,
            CLKIN => clkin,
            CLKFB => gw_gnd,
            FBDSEL => "000000",
            IDSEL => "000000",
            ODSEL => "000000",
            PSDA => "0000",
            DUTYDA => "0000",
            FDLY => "0000"
        );

end Behavioral;
