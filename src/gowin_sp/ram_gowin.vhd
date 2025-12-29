--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9
--Device Version: C
--Created Time: Fri Oct 10 11:28:02 2025

library IEEE;
use IEEE.std_logic_1164.all;

entity ram_gowin is
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(13 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end ram_gowin;

architecture Behavioral of ram_gowin is

    signal sp_inst_0_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_0_dout: std_logic_vector(3 downto 0);
    signal sp_inst_1_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_1_dout: std_logic_vector(3 downto 0);
    signal sp_inst_2_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_2_dout: std_logic_vector(3 downto 0);
    signal sp_inst_3_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_3_dout: std_logic_vector(3 downto 0);
    signal sp_inst_4_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_4_dout: std_logic_vector(7 downto 4);
    signal sp_inst_5_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_5_dout: std_logic_vector(7 downto 4);
    signal sp_inst_6_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_6_dout: std_logic_vector(7 downto 4);
    signal sp_inst_7_dout_w: std_logic_vector(27 downto 0);
    signal sp_inst_7_dout: std_logic_vector(7 downto 4);
    signal dff_q_0: std_logic;
    signal dff_q_1: std_logic;
    signal mux_o_0: std_logic;
    signal mux_o_1: std_logic;
    signal mux_o_3: std_logic;
    signal mux_o_4: std_logic;
    signal mux_o_6: std_logic;
    signal mux_o_7: std_logic;
    signal mux_o_9: std_logic;
    signal mux_o_10: std_logic;
    signal mux_o_12: std_logic;
    signal mux_o_13: std_logic;
    signal mux_o_15: std_logic;
    signal mux_o_16: std_logic;
    signal mux_o_18: std_logic;
    signal mux_o_19: std_logic;
    signal mux_o_21: std_logic;
    signal mux_o_22: std_logic;
    signal ce_w: std_logic;
    signal gw_gnd: std_logic;
    signal sp_inst_0_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_0_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_0_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_0_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_1_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_1_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_1_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_1_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_2_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_2_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_2_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_2_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_3_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_3_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_3_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_3_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_4_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_4_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_4_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_4_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_5_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_5_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_5_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_5_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_6_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_6_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_6_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_6_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_7_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_7_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_7_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_7_DO_o: std_logic_vector(31 downto 0);

    --component declaration
    component SP
        generic (
            READ_MODE: in bit := '0';
            WRITE_MODE: in bit_vector := "00";
            BIT_WIDTH: in integer := 32;
            BLK_SEL: in bit_vector := "000";
            RESET_MODE: in string := "SYNC";
            INIT_RAM_00: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_01: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_02: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_03: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_04: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_05: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_06: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_07: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_08: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_09: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_10: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_11: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_12: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_13: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_14: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_15: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_16: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_17: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_18: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_19: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_20: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_21: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_22: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_23: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_24: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_25: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_26: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_27: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_28: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_29: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_30: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_31: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_32: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_33: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_34: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_35: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_36: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_37: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_38: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_39: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000"
        );
        port (
            DO: out std_logic_vector(31 downto 0);
            CLK: in std_logic;
            OCE: in std_logic;
            CE: in std_logic;
            RESET: in std_logic;
            WRE: in std_logic;
            BLKSEL: in std_logic_vector(2 downto 0);
            AD: in std_logic_vector(13 downto 0);
            DI: in std_logic_vector(31 downto 0)
        );
    end component;

    -- component declaration
    component DFFE
        port (
            Q: out std_logic;
            D: in std_logic;
            CLK: in std_logic;
            CE: in std_logic
        );
    end component;

    -- component declaration
    component MUX2
        port (
            O: out std_logic;
            I0: in std_logic;
            I1: in std_logic;
            S0: in std_logic
        );
    end component;

begin
    gw_gnd <= '0';

    ce_w <= not wre and ce;
    sp_inst_0_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_0_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_0_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(3 downto 0);
    sp_inst_0_dout(3 downto 0) <= sp_inst_0_DO_o(3 downto 0) ;
    sp_inst_0_dout_w(27 downto 0) <= sp_inst_0_DO_o(31 downto 4) ;
    sp_inst_1_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_1_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_1_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(3 downto 0);
    sp_inst_1_dout(3 downto 0) <= sp_inst_1_DO_o(3 downto 0) ;
    sp_inst_1_dout_w(27 downto 0) <= sp_inst_1_DO_o(31 downto 4) ;
    sp_inst_2_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_2_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_2_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(3 downto 0);
    sp_inst_2_dout(3 downto 0) <= sp_inst_2_DO_o(3 downto 0) ;
    sp_inst_2_dout_w(27 downto 0) <= sp_inst_2_DO_o(31 downto 4) ;
    sp_inst_3_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_3_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_3_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(3 downto 0);
    sp_inst_3_dout(3 downto 0) <= sp_inst_3_DO_o(3 downto 0) ;
    sp_inst_3_dout_w(27 downto 0) <= sp_inst_3_DO_o(31 downto 4) ;
    sp_inst_4_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_4_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_4_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(7 downto 4);
    sp_inst_4_dout(7 downto 4) <= sp_inst_4_DO_o(3 downto 0) ;
    sp_inst_4_dout_w(27 downto 0) <= sp_inst_4_DO_o(31 downto 4) ;
    sp_inst_5_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_5_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_5_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(7 downto 4);
    sp_inst_5_dout(7 downto 4) <= sp_inst_5_DO_o(3 downto 0) ;
    sp_inst_5_dout_w(27 downto 0) <= sp_inst_5_DO_o(31 downto 4) ;
    sp_inst_6_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_6_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_6_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(7 downto 4);
    sp_inst_6_dout(7 downto 4) <= sp_inst_6_DO_o(3 downto 0) ;
    sp_inst_6_dout_w(27 downto 0) <= sp_inst_6_DO_o(31 downto 4) ;
    sp_inst_7_BLKSEL_i <= gw_gnd & ad(13) & ad(12);
    sp_inst_7_AD_i <= ad(11 downto 0) & gw_gnd & gw_gnd;
    sp_inst_7_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(7 downto 4);
    sp_inst_7_dout(7 downto 4) <= sp_inst_7_DO_o(3 downto 0) ;
    sp_inst_7_dout_w(27 downto 0) <= sp_inst_7_DO_o(31 downto 4) ;

    sp_inst_0: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_0_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_0_BLKSEL_i,
            AD => sp_inst_0_AD_i,
            DI => sp_inst_0_DI_i
        );

    sp_inst_1: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "001"
        )
        port map (
            DO => sp_inst_1_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_1_BLKSEL_i,
            AD => sp_inst_1_AD_i,
            DI => sp_inst_1_DI_i
        );

    sp_inst_2: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "010"
        )
        port map (
            DO => sp_inst_2_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_2_BLKSEL_i,
            AD => sp_inst_2_AD_i,
            DI => sp_inst_2_DI_i
        );

    sp_inst_3: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "011"
        )
        port map (
            DO => sp_inst_3_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_3_BLKSEL_i,
            AD => sp_inst_3_AD_i,
            DI => sp_inst_3_DI_i
        );

    sp_inst_4: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_4_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_4_BLKSEL_i,
            AD => sp_inst_4_AD_i,
            DI => sp_inst_4_DI_i
        );

    sp_inst_5: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "001"
        )
        port map (
            DO => sp_inst_5_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_5_BLKSEL_i,
            AD => sp_inst_5_AD_i,
            DI => sp_inst_5_DI_i
        );

    sp_inst_6: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "010"
        )
        port map (
            DO => sp_inst_6_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_6_BLKSEL_i,
            AD => sp_inst_6_AD_i,
            DI => sp_inst_6_DI_i
        );

    sp_inst_7: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 4,
            RESET_MODE => "SYNC",
            BLK_SEL => "011"
        )
        port map (
            DO => sp_inst_7_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_7_BLKSEL_i,
            AD => sp_inst_7_AD_i,
            DI => sp_inst_7_DI_i
        );

    dff_inst_0: DFFE
        port map (
            Q => dff_q_0,
            D => ad(13),
            CLK => clk,
            CE => ce_w
        );

    dff_inst_1: DFFE
        port map (
            Q => dff_q_1,
            D => ad(12),
            CLK => clk,
            CE => ce_w
        );

    mux_inst_0: MUX2
        port map (
            O => mux_o_0,
            I0 => sp_inst_0_dout(0),
            I1 => sp_inst_1_dout(0),
            S0 => dff_q_1
        );

    mux_inst_1: MUX2
        port map (
            O => mux_o_1,
            I0 => sp_inst_2_dout(0),
            I1 => sp_inst_3_dout(0),
            S0 => dff_q_1
        );

    mux_inst_2: MUX2
        port map (
            O => dout(0),
            I0 => mux_o_0,
            I1 => mux_o_1,
            S0 => dff_q_0
        );

    mux_inst_3: MUX2
        port map (
            O => mux_o_3,
            I0 => sp_inst_0_dout(1),
            I1 => sp_inst_1_dout(1),
            S0 => dff_q_1
        );

    mux_inst_4: MUX2
        port map (
            O => mux_o_4,
            I0 => sp_inst_2_dout(1),
            I1 => sp_inst_3_dout(1),
            S0 => dff_q_1
        );

    mux_inst_5: MUX2
        port map (
            O => dout(1),
            I0 => mux_o_3,
            I1 => mux_o_4,
            S0 => dff_q_0
        );

    mux_inst_6: MUX2
        port map (
            O => mux_o_6,
            I0 => sp_inst_0_dout(2),
            I1 => sp_inst_1_dout(2),
            S0 => dff_q_1
        );

    mux_inst_7: MUX2
        port map (
            O => mux_o_7,
            I0 => sp_inst_2_dout(2),
            I1 => sp_inst_3_dout(2),
            S0 => dff_q_1
        );

    mux_inst_8: MUX2
        port map (
            O => dout(2),
            I0 => mux_o_6,
            I1 => mux_o_7,
            S0 => dff_q_0
        );

    mux_inst_9: MUX2
        port map (
            O => mux_o_9,
            I0 => sp_inst_0_dout(3),
            I1 => sp_inst_1_dout(3),
            S0 => dff_q_1
        );

    mux_inst_10: MUX2
        port map (
            O => mux_o_10,
            I0 => sp_inst_2_dout(3),
            I1 => sp_inst_3_dout(3),
            S0 => dff_q_1
        );

    mux_inst_11: MUX2
        port map (
            O => dout(3),
            I0 => mux_o_9,
            I1 => mux_o_10,
            S0 => dff_q_0
        );

    mux_inst_12: MUX2
        port map (
            O => mux_o_12,
            I0 => sp_inst_4_dout(4),
            I1 => sp_inst_5_dout(4),
            S0 => dff_q_1
        );

    mux_inst_13: MUX2
        port map (
            O => mux_o_13,
            I0 => sp_inst_6_dout(4),
            I1 => sp_inst_7_dout(4),
            S0 => dff_q_1
        );

    mux_inst_14: MUX2
        port map (
            O => dout(4),
            I0 => mux_o_12,
            I1 => mux_o_13,
            S0 => dff_q_0
        );

    mux_inst_15: MUX2
        port map (
            O => mux_o_15,
            I0 => sp_inst_4_dout(5),
            I1 => sp_inst_5_dout(5),
            S0 => dff_q_1
        );

    mux_inst_16: MUX2
        port map (
            O => mux_o_16,
            I0 => sp_inst_6_dout(5),
            I1 => sp_inst_7_dout(5),
            S0 => dff_q_1
        );

    mux_inst_17: MUX2
        port map (
            O => dout(5),
            I0 => mux_o_15,
            I1 => mux_o_16,
            S0 => dff_q_0
        );

    mux_inst_18: MUX2
        port map (
            O => mux_o_18,
            I0 => sp_inst_4_dout(6),
            I1 => sp_inst_5_dout(6),
            S0 => dff_q_1
        );

    mux_inst_19: MUX2
        port map (
            O => mux_o_19,
            I0 => sp_inst_6_dout(6),
            I1 => sp_inst_7_dout(6),
            S0 => dff_q_1
        );

    mux_inst_20: MUX2
        port map (
            O => dout(6),
            I0 => mux_o_18,
            I1 => mux_o_19,
            S0 => dff_q_0
        );

    mux_inst_21: MUX2
        port map (
            O => mux_o_21,
            I0 => sp_inst_4_dout(7),
            I1 => sp_inst_5_dout(7),
            S0 => dff_q_1
        );

    mux_inst_22: MUX2
        port map (
            O => mux_o_22,
            I0 => sp_inst_6_dout(7),
            I1 => sp_inst_7_dout(7),
            S0 => dff_q_1
        );

    mux_inst_23: MUX2
        port map (
            O => dout(7),
            I0 => mux_o_21,
            I1 => mux_o_22,
            S0 => dff_q_0
        );

end Behavioral; --ram_gowin
