--
--Written by GowinSynthesis
--Tool Version "V1.9.12 (64-bit)"
--Sun Dec 28 11:45:49 2025

--Source file index table:
--file0 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/SPIMASTER/data/spi_master_top.v"
--file1 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/SPIMASTER/data/spi_master.vp"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw1n;
use gw1n.components.all;

entity SPI_MASTER_Top is
port(
  I_CLK :  in std_logic;
  I_RESETN :  in std_logic;
  I_TX_EN :  in std_logic;
  I_WADDR :  in std_logic_vector(2 downto 0);
  I_WDATA :  in std_logic_vector(7 downto 0);
  I_RX_EN :  in std_logic;
  I_RADDR :  in std_logic_vector(2 downto 0);
  O_RDATA :  out std_logic_vector(7 downto 0);
  O_SPI_INT :  out std_logic;
  MISO_MASTER :  in std_logic;
  MOSI_MASTER :  out std_logic;
  SS_N_MASTER :  out std_logic_vector(3 downto 0);
  SCLK_MASTER :  out std_logic;
  MISO_SLAVE :  out std_logic;
  MOSI_SLAVE :  in std_logic;
  SS_N_SLAVE :  in std_logic;
  SCLK_SLAVE :  in std_logic);
end SPI_MASTER_Top;
architecture beh of SPI_MASTER_Top is
  signal u_spi_master_rx_latch_flag : std_logic ;
  signal u_spi_master_reg_tmt : std_logic ;
  signal u_spi_master_pending_data : std_logic ;
  signal u_spi_master_reg_trdy : std_logic ;
  signal u_spi_master_reg_toe : std_logic ;
  signal u_spi_master_reg_rrdy : std_logic ;
  signal u_spi_master_reg_roe : std_logic ;
  signal u_spi_master_n93 : std_logic ;
  signal u_spi_master_n93_15 : std_logic ;
  signal u_spi_master_n94 : std_logic ;
  signal u_spi_master_n94_15 : std_logic ;
  signal u_spi_master_n95 : std_logic ;
  signal u_spi_master_n95_15 : std_logic ;
  signal u_spi_master_n96 : std_logic ;
  signal u_spi_master_n96_19 : std_logic ;
  signal u_spi_master_n97 : std_logic ;
  signal u_spi_master_n97_19 : std_logic ;
  signal u_spi_master_n93_17 : std_logic ;
  signal u_spi_master_n94_17 : std_logic ;
  signal u_spi_master_n95_17 : std_logic ;
  signal u_spi_master_n96_21 : std_logic ;
  signal u_spi_master_n97_21 : std_logic ;
  signal u_spi_master_n631 : std_logic ;
  signal u_spi_master_n638 : std_logic ;
  signal u_spi_master_n646 : std_logic ;
  signal u_spi_master_n459 : std_logic ;
  signal u_spi_master_n460 : std_logic ;
  signal u_spi_master_n461 : std_logic ;
  signal u_spi_master_n462 : std_logic ;
  signal u_spi_master_n463 : std_logic ;
  signal u_spi_master_n464 : std_logic ;
  signal u_spi_master_n465 : std_logic ;
  signal u_spi_master_n509 : std_logic ;
  signal u_spi_master_n523 : std_logic ;
  signal u_spi_master_n544 : std_logic ;
  signal u_spi_master_n326 : std_logic ;
  signal u_spi_master_n328 : std_logic ;
  signal u_spi_master_pending_data_8 : std_logic ;
  signal u_spi_master_data_cnt_5 : std_logic ;
  signal u_spi_master_MOSI_MASTER : std_logic ;
  signal u_spi_master_reg_trdy_8 : std_logic ;
  signal u_spi_master_n466 : std_logic ;
  signal u_spi_master_n399 : std_logic ;
  signal u_spi_master_n398 : std_logic ;
  signal u_spi_master_n397 : std_logic ;
  signal u_spi_master_n396 : std_logic ;
  signal u_spi_master_n395 : std_logic ;
  signal u_spi_master_n394 : std_logic ;
  signal u_spi_master_n327 : std_logic ;
  signal u_spi_master_n274 : std_logic ;
  signal u_spi_master_n275 : std_logic ;
  signal u_spi_master_n277 : std_logic ;
  signal u_spi_master_n278 : std_logic ;
  signal u_spi_master_n332 : std_logic ;
  signal u_spi_master_n204 : std_logic ;
  signal u_spi_master_n205 : std_logic ;
  signal u_spi_master_n206 : std_logic ;
  signal u_spi_master_n207 : std_logic ;
  signal u_spi_master_O_SPI_INT_d : std_logic ;
  signal u_spi_master_O_SPI_INT_d_4 : std_logic ;
  signal u_spi_master_n219 : std_logic ;
  signal u_spi_master_n219_5 : std_logic ;
  signal u_spi_master_n260 : std_logic ;
  signal u_spi_master_n459_4 : std_logic ;
  signal u_spi_master_n523_4 : std_logic ;
  signal u_spi_master_n326_26 : std_logic ;
  signal u_spi_master_n326_27 : std_logic ;
  signal u_spi_master_n328_17 : std_logic ;
  signal u_spi_master_n328_18 : std_logic ;
  signal u_spi_master_n328_19 : std_logic ;
  signal u_spi_master_data_cnt_5_9 : std_logic ;
  signal u_spi_master_reg_toe_9 : std_logic ;
  signal u_spi_master_reg_rrdy_9 : std_logic ;
  signal u_spi_master_n399_10 : std_logic ;
  signal u_spi_master_n398_8 : std_logic ;
  signal u_spi_master_n396_8 : std_logic ;
  signal u_spi_master_reg_data_out_0 : std_logic ;
  signal u_spi_master_reg_data_out_0_8 : std_logic ;
  signal u_spi_master_reg_data_out_1 : std_logic ;
  signal u_spi_master_reg_data_out_1_8 : std_logic ;
  signal u_spi_master_reg_data_out_7 : std_logic ;
  signal u_spi_master_reg_data_out_7_8 : std_logic ;
  signal u_spi_master_n274_8 : std_logic ;
  signal u_spi_master_n274_9 : std_logic ;
  signal u_spi_master_n274_10 : std_logic ;
  signal u_spi_master_n204_8 : std_logic ;
  signal u_spi_master_n326_28 : std_logic ;
  signal u_spi_master_n326_29 : std_logic ;
  signal u_spi_master_n326_30 : std_logic ;
  signal u_spi_master_n326_31 : std_logic ;
  signal u_spi_master_n328_20 : std_logic ;
  signal u_spi_master_reg_data_out_0_9 : std_logic ;
  signal u_spi_master_reg_data_out_1_9 : std_logic ;
  signal u_spi_master_reg_toe_11 : std_logic ;
  signal u_spi_master_reg_rrdy_11 : std_logic ;
  signal u_spi_master_n524 : std_logic ;
  signal u_spi_master_n232 : std_logic ;
  signal u_spi_master_n495 : std_logic ;
  signal u_spi_master_n260_6 : std_logic ;
  signal u_spi_master_n276 : std_logic ;
  signal u_spi_master_n399_12 : std_logic ;
  signal u_spi_master_n221 : std_logic ;
  signal u_spi_master_n219_7 : std_logic ;
  signal u_spi_master_n14 : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \u_spi_master/reg_txdata\ : std_logic_vector(7 downto 0);
  signal \u_spi_master/reg_control\ : std_logic_vector(7 downto 0);
  signal \u_spi_master/reg_ssmask\ : std_logic_vector(3 downto 0);
  signal \u_spi_master/reg_rxdata\ : std_logic_vector(7 downto 0);
  signal \u_spi_master/rx_shift_data\ : std_logic_vector(7 downto 0);
  signal \u_spi_master/clock_cnt\ : std_logic_vector(4 downto 0);
  signal \u_spi_master/c_status\ : std_logic_vector(2 downto 0);
  signal \u_spi_master/n_status\ : std_logic_vector(2 downto 0);
  signal \u_spi_master/data_cnt\ : std_logic_vector(5 downto 0);
  signal \u_spi_master/tx_shift_data\ : std_logic_vector(7 downto 1);
  signal \u_spi_master/reg_data_out\ : std_logic_vector(7 downto 0);
  signal NN : std_logic;
begin
\u_spi_master/reg_txdata_6_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_5_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_4_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_3_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_2_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_1_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_txdata_0_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_7_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_6_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_5_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_4_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_3_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_2_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_1_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_control_0_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_control\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_spi_master_n638,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_ssmask_3_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_ssmask\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_spi_master_n646,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_ssmask_2_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_ssmask\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_spi_master_n646,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_ssmask_1_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_ssmask\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_spi_master_n646,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_ssmask_0_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_ssmask\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_spi_master_n646,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_7_s0\: DFFCE
port map (
  Q => O_RDATA(7),
  D => \u_spi_master/reg_data_out\(7),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_6_s0\: DFFCE
port map (
  Q => O_RDATA(6),
  D => \u_spi_master/reg_data_out\(6),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_5_s0\: DFFCE
port map (
  Q => O_RDATA(5),
  D => \u_spi_master/reg_data_out\(5),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_4_s0\: DFFCE
port map (
  Q => O_RDATA(4),
  D => \u_spi_master/reg_data_out\(4),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_3_s0\: DFFCE
port map (
  Q => O_RDATA(3),
  D => \u_spi_master/reg_data_out\(3),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_2_s0\: DFFCE
port map (
  Q => O_RDATA(2),
  D => \u_spi_master/reg_data_out\(2),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_1_s0\: DFFCE
port map (
  Q => O_RDATA(1),
  D => \u_spi_master/reg_data_out\(1),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/rdata_0_s0\: DFFCE
port map (
  Q => O_RDATA(0),
  D => \u_spi_master/reg_data_out\(0),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_7_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(7),
  D => \u_spi_master/rx_shift_data\(7),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_6_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(6),
  D => \u_spi_master/rx_shift_data\(6),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_5_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(5),
  D => \u_spi_master/rx_shift_data\(5),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_4_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(4),
  D => \u_spi_master/rx_shift_data\(4),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_3_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(3),
  D => \u_spi_master/rx_shift_data\(3),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_2_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(2),
  D => \u_spi_master/rx_shift_data\(2),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_1_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(1),
  D => \u_spi_master/rx_shift_data\(1),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rxdata_0_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_rxdata\(0),
  D => \u_spi_master/rx_shift_data\(0),
  CLK => I_CLK,
  CE => u_spi_master_rx_latch_flag,
  CLEAR => u_spi_master_n14);
\u_spi_master/SS_N_MASTER_2_s0\: DFFP
port map (
  Q => SS_N_MASTER(2),
  D => u_spi_master_n205,
  CLK => I_CLK,
  PRESET => u_spi_master_n14);
\u_spi_master/SS_N_MASTER_1_s0\: DFFP
port map (
  Q => SS_N_MASTER(1),
  D => u_spi_master_n206,
  CLK => I_CLK,
  PRESET => u_spi_master_n14);
\u_spi_master/SS_N_MASTER_0_s0\: DFFP
port map (
  Q => SS_N_MASTER(0),
  D => u_spi_master_n207,
  CLK => I_CLK,
  PRESET => u_spi_master_n14);
\u_spi_master/rx_shift_data_7_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(7),
  D => \u_spi_master/rx_shift_data\(6),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_6_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(6),
  D => \u_spi_master/rx_shift_data\(5),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_5_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(5),
  D => \u_spi_master/rx_shift_data\(4),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_4_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(4),
  D => \u_spi_master/rx_shift_data\(3),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_3_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(3),
  D => \u_spi_master/rx_shift_data\(2),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_2_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(2),
  D => \u_spi_master/rx_shift_data\(1),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_1_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(1),
  D => \u_spi_master/rx_shift_data\(0),
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_shift_data_0_s0\: DFFCE
port map (
  Q => \u_spi_master/rx_shift_data\(0),
  D => MISO_MASTER,
  CLK => I_CLK,
  CE => u_spi_master_n232,
  CLEAR => u_spi_master_n14);
\u_spi_master/rx_latch_flag_s0\: DFFC
port map (
  Q => u_spi_master_rx_latch_flag,
  D => u_spi_master_n260_6,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/clock_cnt_4_s0\: DFFC
port map (
  Q => \u_spi_master/clock_cnt\(4),
  D => u_spi_master_n274,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/clock_cnt_3_s0\: DFFC
port map (
  Q => \u_spi_master/clock_cnt\(3),
  D => u_spi_master_n275,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/clock_cnt_2_s0\: DFFC
port map (
  Q => \u_spi_master/clock_cnt\(2),
  D => u_spi_master_n276,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/clock_cnt_1_s0\: DFFC
port map (
  Q => \u_spi_master/clock_cnt\(1),
  D => u_spi_master_n277,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/clock_cnt_0_s0\: DFFC
port map (
  Q => \u_spi_master/clock_cnt\(0),
  D => u_spi_master_n278,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/c_status_2_s0\: DFFC
port map (
  Q => \u_spi_master/c_status\(2),
  D => \u_spi_master/n_status\(2),
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/c_status_1_s0\: DFFC
port map (
  Q => \u_spi_master/c_status\(1),
  D => \u_spi_master/n_status\(1),
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/c_status_0_s0\: DFFC
port map (
  Q => \u_spi_master/c_status\(0),
  D => \u_spi_master/n_status\(0),
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_tmt_s0\: DFFP
port map (
  Q => u_spi_master_reg_tmt,
  D => u_spi_master_n544,
  CLK => I_CLK,
  PRESET => u_spi_master_n14);
\u_spi_master/reg_txdata_7_s0\: DFFCE
port map (
  Q => \u_spi_master/reg_txdata\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_spi_master_n631,
  CLEAR => u_spi_master_n14);
\u_spi_master/SS_N_MASTER_3_s0\: DFFP
port map (
  Q => SS_N_MASTER(3),
  D => u_spi_master_n204,
  CLK => I_CLK,
  PRESET => u_spi_master_n14);
\u_spi_master/n_status_2_s0\: DLC
port map (
  Q => \u_spi_master/n_status\(2),
  D => u_spi_master_n326,
  G => u_spi_master_n332,
  CLEAR => u_spi_master_n14);
\u_spi_master/n_status_1_s0\: DLC
port map (
  Q => \u_spi_master/n_status\(1),
  D => u_spi_master_n327,
  G => u_spi_master_n332,
  CLEAR => u_spi_master_n14);
\u_spi_master/n_status_0_s0\: DLC
port map (
  Q => \u_spi_master/n_status\(0),
  D => u_spi_master_n328,
  G => u_spi_master_n332,
  CLEAR => u_spi_master_n14);
\u_spi_master/pending_data_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_spi_master_pending_data,
  D => u_spi_master_n631,
  CLK => I_CLK,
  CE => u_spi_master_pending_data_8,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(5),
  D => u_spi_master_n394,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(4),
  D => u_spi_master_n395,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(3),
  D => u_spi_master_n396,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(2),
  D => u_spi_master_n397,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(1),
  D => u_spi_master_n398,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/data_cnt_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/data_cnt\(0),
  D => u_spi_master_n399,
  CLK => I_CLK,
  CE => u_spi_master_data_cnt_5,
  CLEAR => u_spi_master_n14);
\u_spi_master/MOSI_MASTER_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => MOSI_MASTER,
  D => u_spi_master_n459,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_7_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(7),
  D => u_spi_master_n460,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_6_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(6),
  D => u_spi_master_n461,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(5),
  D => u_spi_master_n462,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(4),
  D => u_spi_master_n463,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(3),
  D => u_spi_master_n464,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(2),
  D => u_spi_master_n465,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/tx_shift_data_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_spi_master/tx_shift_data\(1),
  D => u_spi_master_n466,
  CLK => I_CLK,
  CE => u_spi_master_MOSI_MASTER,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_trdy_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => u_spi_master_reg_trdy,
  D => u_spi_master_n495,
  CLK => I_CLK,
  CE => u_spi_master_reg_trdy_8,
  PRESET => u_spi_master_n14);
\u_spi_master/reg_toe_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_spi_master_reg_toe,
  D => u_spi_master_n509,
  CLK => I_CLK,
  CE => u_spi_master_reg_toe_11,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_rrdy_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_spi_master_reg_rrdy,
  D => u_spi_master_n523,
  CLK => I_CLK,
  CE => u_spi_master_reg_rrdy_11,
  CLEAR => u_spi_master_n14);
\u_spi_master/reg_roe_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_spi_master_reg_roe,
  D => u_spi_master_n523,
  CLK => I_CLK,
  CE => u_spi_master_n524,
  CLEAR => u_spi_master_n14);
\u_spi_master/n93_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n93,
  I0 => \u_spi_master/reg_rxdata\(6),
  I1 => \u_spi_master/reg_txdata\(6),
  I2 => I_RADDR(0));
\u_spi_master/n93_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n93_15,
  I0 => u_spi_master_reg_rrdy,
  I1 => \u_spi_master/reg_control\(6),
  I2 => I_RADDR(0));
\u_spi_master/n94_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n94,
  I0 => \u_spi_master/reg_rxdata\(5),
  I1 => \u_spi_master/reg_txdata\(5),
  I2 => I_RADDR(0));
\u_spi_master/n94_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n94_15,
  I0 => u_spi_master_reg_trdy,
  I1 => \u_spi_master/reg_control\(5),
  I2 => I_RADDR(0));
\u_spi_master/n95_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n95,
  I0 => \u_spi_master/reg_rxdata\(4),
  I1 => \u_spi_master/reg_txdata\(4),
  I2 => I_RADDR(0));
\u_spi_master/n95_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n95_15,
  I0 => u_spi_master_reg_tmt,
  I1 => \u_spi_master/reg_control\(4),
  I2 => I_RADDR(0));
\u_spi_master/n96_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n96,
  I0 => \u_spi_master/reg_rxdata\(3),
  I1 => \u_spi_master/reg_txdata\(3),
  I2 => I_RADDR(0));
\u_spi_master/n96_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n96_19,
  I0 => u_spi_master_reg_toe,
  I1 => \u_spi_master/reg_control\(3),
  I2 => I_RADDR(0));
\u_spi_master/n97_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n97,
  I0 => \u_spi_master/reg_rxdata\(2),
  I1 => \u_spi_master/reg_txdata\(2),
  I2 => I_RADDR(0));
\u_spi_master/n97_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_n97_19,
  I0 => u_spi_master_reg_roe,
  I1 => \u_spi_master/reg_control\(2),
  I2 => I_RADDR(0));
\u_spi_master/n93_s11\: MUX2_LUT5
port map (
  O => u_spi_master_n93_17,
  I0 => u_spi_master_n93,
  I1 => u_spi_master_n93_15,
  S0 => I_RADDR(1));
\u_spi_master/n94_s11\: MUX2_LUT5
port map (
  O => u_spi_master_n94_17,
  I0 => u_spi_master_n94,
  I1 => u_spi_master_n94_15,
  S0 => I_RADDR(1));
\u_spi_master/n95_s11\: MUX2_LUT5
port map (
  O => u_spi_master_n95_17,
  I0 => u_spi_master_n95,
  I1 => u_spi_master_n95_15,
  S0 => I_RADDR(1));
\u_spi_master/n96_s13\: MUX2_LUT5
port map (
  O => u_spi_master_n96_21,
  I0 => u_spi_master_n96,
  I1 => u_spi_master_n96_19,
  S0 => I_RADDR(1));
\u_spi_master/n97_s13\: MUX2_LUT5
port map (
  O => u_spi_master_n97_21,
  I0 => u_spi_master_n97,
  I1 => u_spi_master_n97_19,
  S0 => I_RADDR(1));
\u_spi_master/n631_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n631,
  I0 => I_WADDR(1),
  I1 => I_WADDR(2),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\u_spi_master/n638_s0\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_spi_master_n638,
  I0 => I_WADDR(2),
  I1 => I_WADDR(1),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\u_spi_master/n646_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n646,
  I0 => I_WADDR(0),
  I1 => I_WADDR(1),
  I2 => I_WADDR(2),
  I3 => I_TX_EN);
\u_spi_master/O_SPI_INT_d_s\: LUT3
generic map (
  INIT => X"4F"
)
port map (
  F => O_SPI_INT,
  I0 => u_spi_master_O_SPI_INT_d,
  I1 => \u_spi_master/reg_control\(5),
  I2 => u_spi_master_O_SPI_INT_d_4);
\u_spi_master/n459_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n459,
  I0 => \u_spi_master/reg_txdata\(7),
  I1 => \u_spi_master/tx_shift_data\(7),
  I2 => u_spi_master_n459_4);
\u_spi_master/n460_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n460,
  I0 => \u_spi_master/reg_txdata\(6),
  I1 => \u_spi_master/tx_shift_data\(6),
  I2 => u_spi_master_n459_4);
\u_spi_master/n461_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n461,
  I0 => \u_spi_master/reg_txdata\(5),
  I1 => \u_spi_master/tx_shift_data\(5),
  I2 => u_spi_master_n459_4);
\u_spi_master/n462_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n462,
  I0 => \u_spi_master/reg_txdata\(4),
  I1 => \u_spi_master/tx_shift_data\(4),
  I2 => u_spi_master_n459_4);
\u_spi_master/n463_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n463,
  I0 => \u_spi_master/reg_txdata\(3),
  I1 => \u_spi_master/tx_shift_data\(3),
  I2 => u_spi_master_n459_4);
\u_spi_master/n464_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n464,
  I0 => \u_spi_master/reg_txdata\(2),
  I1 => \u_spi_master/tx_shift_data\(2),
  I2 => u_spi_master_n459_4);
\u_spi_master/n465_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_spi_master_n465,
  I0 => \u_spi_master/reg_txdata\(1),
  I1 => \u_spi_master/tx_shift_data\(1),
  I2 => u_spi_master_n459_4);
\u_spi_master/n509_s0\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_spi_master_n509,
  I0 => u_spi_master_reg_trdy,
  I1 => u_spi_master_n631);
\u_spi_master/n523_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n523,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/clock_cnt\(0),
  I2 => u_spi_master_n219_5,
  I3 => u_spi_master_n523_4);
\u_spi_master/n544_s1\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_spi_master_n544,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/c_status\(1),
  I2 => \u_spi_master/c_status\(2),
  I3 => u_spi_master_pending_data);
\u_spi_master/n326_s13\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_spi_master_n326,
  I0 => u_spi_master_n326_26,
  I1 => u_spi_master_n326_27);
\u_spi_master/n328_s10\: LUT4
generic map (
  INIT => X"FFFE"
)
port map (
  F => u_spi_master_n328,
  I0 => u_spi_master_n326_26,
  I1 => u_spi_master_n328_17,
  I2 => u_spi_master_n328_18,
  I3 => u_spi_master_n328_19);
\u_spi_master/pending_data_s3\: LUT4
generic map (
  INIT => X"FF10"
)
port map (
  F => u_spi_master_pending_data_8,
  I0 => \u_spi_master/c_status\(1),
  I1 => \u_spi_master/c_status\(2),
  I2 => \u_spi_master/c_status\(0),
  I3 => u_spi_master_n631);
\u_spi_master/data_cnt_5_s3\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_spi_master_data_cnt_5,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_data_cnt_5_9,
  I2 => u_spi_master_n219_5);
\u_spi_master/MOSI_MASTER_s3\: LUT3
generic map (
  INIT => X"F8"
)
port map (
  F => u_spi_master_MOSI_MASTER,
  I0 => u_spi_master_n219_7,
  I1 => NN,
  I2 => u_spi_master_n459_4);
\u_spi_master/reg_trdy_s3\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_spi_master_reg_trdy_8,
  I0 => u_spi_master_n631,
  I1 => u_spi_master_n495);
\u_spi_master/n466_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_spi_master_n466,
  I0 => \u_spi_master/reg_txdata\(0),
  I1 => u_spi_master_n459_4);
\u_spi_master/n399_s3\: LUT3
generic map (
  INIT => X"07"
)
port map (
  F => u_spi_master_n399,
  I0 => u_spi_master_n399_12,
  I1 => u_spi_master_n399_10,
  I2 => \u_spi_master/data_cnt\(0));
\u_spi_master/n398_s2\: LUT4
generic map (
  INIT => X"0BB0"
)
port map (
  F => u_spi_master_n398,
  I0 => u_spi_master_n398_8,
  I1 => u_spi_master_n399_10,
  I2 => \u_spi_master/data_cnt\(1),
  I3 => \u_spi_master/data_cnt\(0));
\u_spi_master/n397_s2\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => u_spi_master_n397,
  I0 => \u_spi_master/data_cnt\(0),
  I1 => \u_spi_master/data_cnt\(1),
  I2 => \u_spi_master/data_cnt\(2));
\u_spi_master/n396_s2\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => u_spi_master_n396,
  I0 => u_spi_master_n326_27,
  I1 => \u_spi_master/data_cnt\(3),
  I2 => u_spi_master_n396_8);
\u_spi_master/n395_s2\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => u_spi_master_n395,
  I0 => \u_spi_master/data_cnt\(3),
  I1 => u_spi_master_n396_8,
  I2 => \u_spi_master/data_cnt\(4));
\u_spi_master/n394_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => u_spi_master_n394,
  I0 => \u_spi_master/data_cnt\(3),
  I1 => \u_spi_master/data_cnt\(4),
  I2 => u_spi_master_n396_8,
  I3 => \u_spi_master/data_cnt\(5));
\u_spi_master/n327_s13\: LUT4
generic map (
  INIT => X"000E"
)
port map (
  F => u_spi_master_n327,
  I0 => \u_spi_master/c_status\(1),
  I1 => \u_spi_master/c_status\(0),
  I2 => \u_spi_master/c_status\(2),
  I3 => u_spi_master_n326_27);
\u_spi_master/reg_data_out_0_s1\: LUT3
generic map (
  INIT => X"F8"
)
port map (
  F => \u_spi_master/reg_data_out\(0),
  I0 => u_spi_master_reg_data_out_0,
  I1 => \u_spi_master/reg_ssmask\(0),
  I2 => u_spi_master_reg_data_out_0_8);
\u_spi_master/reg_data_out_1_s1\: LUT4
generic map (
  INIT => X"F444"
)
port map (
  F => \u_spi_master/reg_data_out\(1),
  I0 => u_spi_master_reg_data_out_1,
  I1 => u_spi_master_reg_data_out_1_8,
  I2 => \u_spi_master/reg_ssmask\(1),
  I3 => u_spi_master_reg_data_out_0);
\u_spi_master/reg_data_out_2_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_spi_master/reg_data_out\(2),
  I0 => u_spi_master_reg_data_out_0,
  I1 => \u_spi_master/reg_ssmask\(2),
  I2 => u_spi_master_n97_21,
  I3 => u_spi_master_reg_data_out_1_8);
\u_spi_master/reg_data_out_3_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_spi_master/reg_data_out\(3),
  I0 => u_spi_master_reg_data_out_0,
  I1 => \u_spi_master/reg_ssmask\(3),
  I2 => u_spi_master_n96_21,
  I3 => u_spi_master_reg_data_out_1_8);
\u_spi_master/reg_data_out_7_s1\: LUT4
generic map (
  INIT => X"CA00"
)
port map (
  F => \u_spi_master/reg_data_out\(7),
  I0 => u_spi_master_reg_data_out_7,
  I1 => u_spi_master_reg_data_out_7_8,
  I2 => I_RADDR(1),
  I3 => u_spi_master_reg_data_out_1_8);
\u_spi_master/n274_s2\: LUT4
generic map (
  INIT => X"0708"
)
port map (
  F => u_spi_master_n274,
  I0 => u_spi_master_n274_8,
  I1 => u_spi_master_n274_9,
  I2 => u_spi_master_n274_10,
  I3 => \u_spi_master/clock_cnt\(4));
\u_spi_master/n275_s2\: LUT4
generic map (
  INIT => X"0708"
)
port map (
  F => u_spi_master_n275,
  I0 => \u_spi_master/clock_cnt\(2),
  I1 => u_spi_master_n274_8,
  I2 => u_spi_master_n274_10,
  I3 => \u_spi_master/clock_cnt\(3));
\u_spi_master/n277_s2\: LUT3
generic map (
  INIT => X"14"
)
port map (
  F => u_spi_master_n277,
  I0 => u_spi_master_n274_10,
  I1 => \u_spi_master/clock_cnt\(0),
  I2 => \u_spi_master/clock_cnt\(1));
\u_spi_master/n278_s2\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_spi_master_n278,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_n219_5,
  I2 => u_spi_master_n274_10);
\u_spi_master/n332_s5\: LUT4
generic map (
  INIT => X"F2FF"
)
port map (
  F => u_spi_master_n332,
  I0 => u_spi_master_n219_5,
  I1 => \u_spi_master/clock_cnt\(0),
  I2 => \u_spi_master/c_status\(0),
  I3 => u_spi_master_n523_4);
\u_spi_master/n204_s2\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => u_spi_master_n204,
  I0 => u_spi_master_n204_8,
  I1 => \u_spi_master/reg_ssmask\(3));
\u_spi_master/n205_s2\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => u_spi_master_n205,
  I0 => u_spi_master_n204_8,
  I1 => \u_spi_master/reg_ssmask\(2));
\u_spi_master/n206_s2\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => u_spi_master_n206,
  I0 => u_spi_master_n204_8,
  I1 => \u_spi_master/reg_ssmask\(1));
\u_spi_master/n207_s2\: LUT2
generic map (
  INIT => X"B"
)
port map (
  F => u_spi_master_n207,
  I0 => u_spi_master_n204_8,
  I1 => \u_spi_master/reg_ssmask\(0));
\u_spi_master/O_SPI_INT_d_s0\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => u_spi_master_O_SPI_INT_d,
  I0 => \u_spi_master/reg_control\(0),
  I1 => u_spi_master_reg_roe,
  I2 => u_spi_master_reg_toe,
  I3 => \u_spi_master/reg_control\(1));
\u_spi_master/O_SPI_INT_d_s1\: LUT4
generic map (
  INIT => X"0777"
)
port map (
  F => u_spi_master_O_SPI_INT_d_4,
  I0 => \u_spi_master/reg_control\(4),
  I1 => u_spi_master_reg_rrdy,
  I2 => \u_spi_master/reg_control\(3),
  I3 => u_spi_master_reg_trdy);
\u_spi_master/n219_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_spi_master_n219,
  I0 => \u_spi_master/c_status\(2),
  I1 => \u_spi_master/c_status\(1),
  I2 => \u_spi_master/c_status\(0));
\u_spi_master/n219_s2\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_spi_master_n219_5,
  I0 => \u_spi_master/clock_cnt\(1),
  I1 => \u_spi_master/clock_cnt\(2),
  I2 => \u_spi_master/clock_cnt\(3),
  I3 => \u_spi_master/clock_cnt\(4));
\u_spi_master/n260_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_spi_master_n260,
  I0 => \u_spi_master/n_status\(2),
  I1 => \u_spi_master/n_status\(1),
  I2 => \u_spi_master/n_status\(0));
\u_spi_master/n459_s1\: LUT4
generic map (
  INIT => X"1400"
)
port map (
  F => u_spi_master_n459_4,
  I0 => \u_spi_master/c_status\(2),
  I1 => \u_spi_master/c_status\(0),
  I2 => \u_spi_master/c_status\(1),
  I3 => u_spi_master_n260);
\u_spi_master/n523_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_spi_master_n523_4,
  I0 => \u_spi_master/c_status\(1),
  I1 => \u_spi_master/c_status\(2));
\u_spi_master/n326_s14\: LUT4
generic map (
  INIT => X"7F00"
)
port map (
  F => u_spi_master_n326_26,
  I0 => u_spi_master_n219_5,
  I1 => u_spi_master_n326_28,
  I2 => u_spi_master_n326_29,
  I3 => u_spi_master_n523_4);
\u_spi_master/n326_s15\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_spi_master_n326_27,
  I0 => u_spi_master_n219,
  I1 => u_spi_master_n219_5,
  I2 => u_spi_master_n326_30,
  I3 => u_spi_master_n326_31);
\u_spi_master/n328_s11\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_spi_master_n328_17,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/c_status\(1),
  I2 => u_spi_master_pending_data);
\u_spi_master/n328_s12\: LUT4
generic map (
  INIT => X"7F00"
)
port map (
  F => u_spi_master_n328_18,
  I0 => u_spi_master_n219_5,
  I1 => u_spi_master_n326_30,
  I2 => u_spi_master_n326_31,
  I3 => u_spi_master_n219);
\u_spi_master/n328_s13\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_spi_master_n328_19,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_n219_5,
  I2 => u_spi_master_n326_28,
  I3 => u_spi_master_n328_20);
\u_spi_master/data_cnt_5_s4\: LUT4
generic map (
  INIT => X"F43F"
)
port map (
  F => u_spi_master_data_cnt_5_9,
  I0 => NN,
  I1 => \u_spi_master/c_status\(0),
  I2 => \u_spi_master/c_status\(2),
  I3 => \u_spi_master/c_status\(1));
\u_spi_master/reg_toe_s4\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_reg_toe_9,
  I0 => I_WADDR(0),
  I1 => I_WADDR(2),
  I2 => I_WADDR(1),
  I3 => I_TX_EN);
\u_spi_master/reg_rrdy_s4\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_spi_master_reg_rrdy_9,
  I0 => I_RADDR(0),
  I1 => I_RADDR(1),
  I2 => I_RADDR(2),
  I3 => I_RX_EN);
\u_spi_master/n399_s5\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_spi_master_n399_10,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_n219_5,
  I2 => u_spi_master_n326_28);
\u_spi_master/n398_s3\: LUT4
generic map (
  INIT => X"EFF7"
)
port map (
  F => u_spi_master_n398_8,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/c_status\(2),
  I2 => \u_spi_master/c_status\(1),
  I3 => \u_spi_master/data_cnt\(0));
\u_spi_master/n396_s3\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => u_spi_master_n396_8,
  I0 => \u_spi_master/data_cnt\(0),
  I1 => \u_spi_master/data_cnt\(1),
  I2 => \u_spi_master/data_cnt\(2));
\u_spi_master/reg_data_out_0_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_reg_data_out_0,
  I0 => I_RADDR(0),
  I1 => I_RADDR(1),
  I2 => I_RADDR(2),
  I3 => I_RESETN);
\u_spi_master/reg_data_out_0_s3\: LUT4
generic map (
  INIT => X"E000"
)
port map (
  F => u_spi_master_reg_data_out_0_8,
  I0 => \u_spi_master/reg_rxdata\(0),
  I1 => I_RADDR(0),
  I2 => u_spi_master_reg_data_out_0_9,
  I3 => u_spi_master_reg_data_out_1_8);
\u_spi_master/reg_data_out_1_s2\: LUT4
generic map (
  INIT => X"0FBB"
)
port map (
  F => u_spi_master_reg_data_out_1,
  I0 => I_RADDR(1),
  I1 => \u_spi_master/reg_rxdata\(1),
  I2 => u_spi_master_reg_data_out_1_9,
  I3 => I_RADDR(0));
\u_spi_master/reg_data_out_1_s3\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_spi_master_reg_data_out_1_8,
  I0 => I_RADDR(2),
  I1 => I_RESETN);
\u_spi_master/reg_data_out_7_s2\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_reg_data_out_7,
  I0 => \u_spi_master/reg_rxdata\(7),
  I1 => \u_spi_master/reg_txdata\(7),
  I2 => I_RADDR(0));
\u_spi_master/reg_data_out_7_s3\: LUT4
generic map (
  INIT => X"F0EE"
)
port map (
  F => u_spi_master_reg_data_out_7_8,
  I0 => u_spi_master_reg_roe,
  I1 => u_spi_master_reg_toe,
  I2 => \u_spi_master/reg_control\(7),
  I3 => I_RADDR(0));
\u_spi_master/n274_s3\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_spi_master_n274_8,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => \u_spi_master/clock_cnt\(1));
\u_spi_master/n274_s4\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_spi_master_n274_9,
  I0 => \u_spi_master/clock_cnt\(2),
  I1 => \u_spi_master/clock_cnt\(3));
\u_spi_master/n274_s5\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_spi_master_n274_10,
  I0 => \u_spi_master/n_status\(0),
  I1 => \u_spi_master/n_status\(1),
  I2 => \u_spi_master/n_status\(2));
\u_spi_master/n204_s3\: LUT4
generic map (
  INIT => X"0E03"
)
port map (
  F => u_spi_master_n204_8,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/c_status\(1),
  I2 => \u_spi_master/reg_control\(7),
  I3 => \u_spi_master/c_status\(2));
\u_spi_master/n326_s16\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_spi_master_n326_28,
  I0 => \u_spi_master/data_cnt\(2),
  I1 => \u_spi_master/data_cnt\(3),
  I2 => \u_spi_master/data_cnt\(4),
  I3 => \u_spi_master/data_cnt\(5));
\u_spi_master/n326_s17\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n326_29,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => \u_spi_master/data_cnt\(0),
  I2 => \u_spi_master/c_status\(0),
  I3 => \u_spi_master/data_cnt\(1));
\u_spi_master/n326_s18\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_spi_master_n326_30,
  I0 => \u_spi_master/data_cnt\(3),
  I1 => \u_spi_master/data_cnt\(4),
  I2 => \u_spi_master/data_cnt\(5),
  I3 => NN);
\u_spi_master/n326_s19\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_spi_master_n326_31,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => \u_spi_master/data_cnt\(0),
  I2 => \u_spi_master/data_cnt\(1),
  I3 => \u_spi_master/data_cnt\(2));
\u_spi_master/n328_s14\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n328_20,
  I0 => \u_spi_master/c_status\(2),
  I1 => \u_spi_master/data_cnt\(1),
  I2 => \u_spi_master/data_cnt\(0),
  I3 => \u_spi_master/c_status\(1));
\u_spi_master/reg_data_out_0_s4\: LUT4
generic map (
  INIT => X"C0AF"
)
port map (
  F => u_spi_master_reg_data_out_0_9,
  I0 => \u_spi_master/reg_txdata\(0),
  I1 => \u_spi_master/reg_control\(0),
  I2 => I_RADDR(0),
  I3 => I_RADDR(1));
\u_spi_master/reg_data_out_1_s4\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_spi_master_reg_data_out_1_9,
  I0 => \u_spi_master/reg_txdata\(1),
  I1 => \u_spi_master/reg_control\(1),
  I2 => I_RADDR(1));
\u_spi_master/reg_toe_s5\: LUT4
generic map (
  INIT => X"8F88"
)
port map (
  F => u_spi_master_reg_toe_11,
  I0 => I_WDATA(3),
  I1 => u_spi_master_reg_toe_9,
  I2 => u_spi_master_reg_trdy,
  I3 => u_spi_master_n631);
\u_spi_master/reg_rrdy_s5\: LUT4
generic map (
  INIT => X"FF70"
)
port map (
  F => u_spi_master_reg_rrdy_11,
  I0 => I_WDATA(2),
  I1 => u_spi_master_reg_toe_9,
  I2 => u_spi_master_reg_rrdy_9,
  I3 => u_spi_master_n523);
\u_spi_master/n524_s2\: LUT4
generic map (
  INIT => X"F088"
)
port map (
  F => u_spi_master_n524,
  I0 => I_WDATA(2),
  I1 => u_spi_master_reg_toe_9,
  I2 => u_spi_master_reg_rrdy,
  I3 => u_spi_master_n523);
\u_spi_master/n232_s1\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n232,
  I0 => NN,
  I1 => \u_spi_master/clock_cnt\(0),
  I2 => u_spi_master_n219,
  I3 => u_spi_master_n219_5);
\u_spi_master/n495_s1\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_spi_master_n495,
  I0 => u_spi_master_n219,
  I1 => \u_spi_master/n_status\(2),
  I2 => \u_spi_master/n_status\(1),
  I3 => \u_spi_master/n_status\(0));
\u_spi_master/n260_s2\: LUT4
generic map (
  INIT => X"BF00"
)
port map (
  F => u_spi_master_n260_6,
  I0 => \u_spi_master/n_status\(2),
  I1 => \u_spi_master/n_status\(1),
  I2 => \u_spi_master/n_status\(0),
  I3 => u_spi_master_n219);
\u_spi_master/n276_s3\: LUT4
generic map (
  INIT => X"1444"
)
port map (
  F => u_spi_master_n276,
  I0 => u_spi_master_n274_10,
  I1 => \u_spi_master/clock_cnt\(2),
  I2 => \u_spi_master/clock_cnt\(0),
  I3 => \u_spi_master/clock_cnt\(1));
\u_spi_master/n399_s6\: LUT4
generic map (
  INIT => X"0800"
)
port map (
  F => u_spi_master_n399_12,
  I0 => \u_spi_master/c_status\(0),
  I1 => \u_spi_master/data_cnt\(1),
  I2 => \u_spi_master/c_status\(1),
  I3 => \u_spi_master/c_status\(2));
\u_spi_master/reg_data_out_6_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_spi_master/reg_data_out\(6),
  I0 => u_spi_master_n93_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_spi_master/reg_data_out_5_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_spi_master/reg_data_out\(5),
  I0 => u_spi_master_n94_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_spi_master/reg_data_out_4_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_spi_master/reg_data_out\(4),
  I0 => u_spi_master_n95_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_spi_master/SCLK_MASTER_s2\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => NN,
  D => u_spi_master_n221,
  CLK => I_CLK,
  CLEAR => u_spi_master_n14);
\u_spi_master/n221_s3\: LUT4
generic map (
  INIT => X"BF40"
)
port map (
  F => u_spi_master_n221,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_n219,
  I2 => u_spi_master_n219_5,
  I3 => NN);
\u_spi_master/n219_s3\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_spi_master_n219_7,
  I0 => \u_spi_master/clock_cnt\(0),
  I1 => u_spi_master_n219,
  I2 => u_spi_master_n219_5);
\u_spi_master/n14_s2\: INV
port map (
  O => u_spi_master_n14,
  I => I_RESETN);
GND_s0: GND
port map (
  G => GND_0);
VCC_s0: VCC
port map (
  V => VCC_0);
GSR_0: GSR
port map (
  GSRI => VCC_0);
  SCLK_MASTER <= NN;
end beh;
