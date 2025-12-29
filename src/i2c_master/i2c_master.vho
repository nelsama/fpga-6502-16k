--
--Written by GowinSynthesis
--Tool Version "V1.9.12 (64-bit)"
--Fri Oct 17 17:03:42 2025

--Source file index table:
--file0 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/I2CMASTER/data/I2C_MASTER_TOP.v"
--file1 "\C:/Gowin/Gowin_V1.9.12_x64/IDE/ipcore/I2CMASTER/data/I2C_MASTER.vp"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw1n;
use gw1n.components.all;

entity I2C_MASTER_Top is
port(
  I_CLK :  in std_logic;
  I_RESETN :  in std_logic;
  I_TX_EN :  in std_logic;
  I_WADDR :  in std_logic_vector(2 downto 0);
  I_WDATA :  in std_logic_vector(7 downto 0);
  I_RX_EN :  in std_logic;
  I_RADDR :  in std_logic_vector(2 downto 0);
  O_RDATA :  out std_logic_vector(7 downto 0);
  O_IIC_INT :  out std_logic;
  SCL :  inout std_logic;
  SDA :  inout std_logic);
end I2C_MASTER_Top;
architecture beh of I2C_MASTER_Top is
  signal SCL_in : std_logic ;
  signal SDA_in : std_logic ;
  signal u_i2c_master_rxack : std_logic ;
  signal u_i2c_master_tip : std_logic ;
  signal u_i2c_master_byte_controller_core_txd : std_logic ;
  signal u_i2c_master_byte_controller_shift : std_logic ;
  signal u_i2c_master_byte_controller_ld : std_logic ;
  signal u_i2c_master_byte_controller_done : std_logic ;
  signal u_i2c_master_bit_controller_sSCL : std_logic ;
  signal u_i2c_master_bit_controller_sSDA : std_logic ;
  signal u_i2c_master_bit_controller_dSCL : std_logic ;
  signal u_i2c_master_bit_controller_dSDA : std_logic ;
  signal u_i2c_master_bit_controller_sta_condition : std_logic ;
  signal u_i2c_master_bit_controller_sto_condition : std_logic ;
  signal u_i2c_master_bit_controller_cmd_stop : std_logic ;
  signal u_i2c_master_bit_controller_i2c_al : std_logic ;
  signal u_i2c_master_bit_controller_core_rxd : std_logic ;
  signal u_i2c_master_bit_controller_core_ack : std_logic ;
  signal u_i2c_master_bit_controller_dscl_oen : std_logic ;
  signal u_i2c_master_bit_controller_clk_en : std_logic ;
  signal u_i2c_master_al : std_logic ;
  signal u_i2c_master_byte_controller_irxack : std_logic ;
  signal u_i2c_master_bit_controller_scl_padoen_o : std_logic ;
  signal u_i2c_master_bit_controller_sda_padoen_o : std_logic ;
  signal u_i2c_master_n169 : std_logic ;
  signal u_i2c_master_n169_19 : std_logic ;
  signal u_i2c_master_n170 : std_logic ;
  signal u_i2c_master_n170_19 : std_logic ;
  signal u_i2c_master_n171 : std_logic ;
  signal u_i2c_master_n171_19 : std_logic ;
  signal u_i2c_master_n172 : std_logic ;
  signal u_i2c_master_n172_15 : std_logic ;
  signal u_i2c_master_n173 : std_logic ;
  signal u_i2c_master_n173_15 : std_logic ;
  signal u_i2c_master_n174 : std_logic ;
  signal u_i2c_master_n174_15 : std_logic ;
  signal u_i2c_master_n175 : std_logic ;
  signal u_i2c_master_n175_19 : std_logic ;
  signal u_i2c_master_n176 : std_logic ;
  signal u_i2c_master_n176_19 : std_logic ;
  signal u_i2c_master_n169_21 : std_logic ;
  signal u_i2c_master_n170_21 : std_logic ;
  signal u_i2c_master_n171_21 : std_logic ;
  signal u_i2c_master_n172_17 : std_logic ;
  signal u_i2c_master_n173_17 : std_logic ;
  signal u_i2c_master_n174_17 : std_logic ;
  signal u_i2c_master_n175_21 : std_logic ;
  signal u_i2c_master_n176_21 : std_logic ;
  signal u_i2c_master_n323 : std_logic ;
  signal u_i2c_master_n330 : std_logic ;
  signal u_i2c_master_n338 : std_logic ;
  signal u_i2c_master_n346 : std_logic ;
  signal u_i2c_master_n354 : std_logic ;
  signal u_i2c_master_n136 : std_logic ;
  signal u_i2c_master_n218 : std_logic ;
  signal u_i2c_master_n230 : std_logic ;
  signal u_i2c_master_byte_controller_n19 : std_logic ;
  signal u_i2c_master_byte_controller_n20 : std_logic ;
  signal u_i2c_master_byte_controller_n21 : std_logic ;
  signal u_i2c_master_byte_controller_n22 : std_logic ;
  signal u_i2c_master_byte_controller_n23 : std_logic ;
  signal u_i2c_master_byte_controller_n24 : std_logic ;
  signal u_i2c_master_byte_controller_n25 : std_logic ;
  signal u_i2c_master_byte_controller_n26 : std_logic ;
  signal u_i2c_master_bit_controller_n13 : std_logic ;
  signal u_i2c_master_bit_controller_n31 : std_logic ;
  signal u_i2c_master_bit_controller_n32 : std_logic ;
  signal u_i2c_master_bit_controller_n33 : std_logic ;
  signal u_i2c_master_bit_controller_n34 : std_logic ;
  signal u_i2c_master_bit_controller_n35 : std_logic ;
  signal u_i2c_master_bit_controller_n36 : std_logic ;
  signal u_i2c_master_bit_controller_n37 : std_logic ;
  signal u_i2c_master_bit_controller_n38 : std_logic ;
  signal u_i2c_master_bit_controller_n39 : std_logic ;
  signal u_i2c_master_bit_controller_n40 : std_logic ;
  signal u_i2c_master_bit_controller_n41 : std_logic ;
  signal u_i2c_master_bit_controller_n42 : std_logic ;
  signal u_i2c_master_bit_controller_n43 : std_logic ;
  signal u_i2c_master_bit_controller_n44 : std_logic ;
  signal u_i2c_master_bit_controller_n45 : std_logic ;
  signal u_i2c_master_bit_controller_n46 : std_logic ;
  signal u_i2c_master_bit_controller_n93 : std_logic ;
  signal u_i2c_master_bit_controller_n96 : std_logic ;
  signal u_i2c_master_bit_controller_n110 : std_logic ;
  signal u_i2c_master_bit_controller_n123 : std_logic ;
  signal u_i2c_master_bit_controller_n129 : std_logic ;
  signal u_i2c_master_al_8 : std_logic ;
  signal u_i2c_master_byte_controller_CORE_CMD_0 : std_logic ;
  signal u_i2c_master_byte_controller_ACK_OUT : std_logic ;
  signal u_i2c_master_bit_controller_cnt_15 : std_logic ;
  signal u_i2c_master_bit_controller_n228 : std_logic ;
  signal u_i2c_master_bit_controller_n227 : std_logic ;
  signal u_i2c_master_bit_controller_n225 : std_logic ;
  signal u_i2c_master_bit_controller_n224 : std_logic ;
  signal u_i2c_master_bit_controller_n222 : std_logic ;
  signal u_i2c_master_bit_controller_n221 : std_logic ;
  signal u_i2c_master_bit_controller_n220 : std_logic ;
  signal u_i2c_master_bit_controller_n219 : std_logic ;
  signal u_i2c_master_bit_controller_n218 : std_logic ;
  signal u_i2c_master_bit_controller_n217 : std_logic ;
  signal u_i2c_master_bit_controller_n215 : std_logic ;
  signal u_i2c_master_bit_controller_n214 : std_logic ;
  signal u_i2c_master_bit_controller_n213 : std_logic ;
  signal u_i2c_master_bit_controller_n212 : std_logic ;
  signal u_i2c_master_byte_controller_n198 : std_logic ;
  signal u_i2c_master_byte_controller_n104 : std_logic ;
  signal u_i2c_master_n159 : std_logic ;
  signal u_i2c_master_n155 : std_logic ;
  signal u_i2c_master_n154 : std_logic ;
  signal u_i2c_master_n153 : std_logic ;
  signal u_i2c_master_n152 : std_logic ;
  signal u_i2c_master_bit_controller_n250 : std_logic ;
  signal u_i2c_master_byte_controller_n210 : std_logic ;
  signal u_i2c_master_byte_controller_n209 : std_logic ;
  signal u_i2c_master_byte_controller_n208 : std_logic ;
  signal u_i2c_master_byte_controller_n207 : std_logic ;
  signal u_i2c_master_byte_controller_n206 : std_logic ;
  signal u_i2c_master_byte_controller_n205 : std_logic ;
  signal u_i2c_master_byte_controller_n204 : std_logic ;
  signal u_i2c_master_byte_controller_n203 : std_logic ;
  signal u_i2c_master_byte_controller_n201 : std_logic ;
  signal u_i2c_master_byte_controller_n200 : std_logic ;
  signal u_i2c_master_byte_controller_n199 : std_logic ;
  signal u_i2c_master_bit_controller_n230 : std_logic ;
  signal u_i2c_master_byte_controller_n50 : std_logic ;
  signal u_i2c_master_bit_controller_n203 : std_logic ;
  signal u_i2c_master_n354_4 : std_logic ;
  signal u_i2c_master_bit_controller_n13_4 : std_logic ;
  signal u_i2c_master_bit_controller_n13_5 : std_logic ;
  signal u_i2c_master_bit_controller_n31_4 : std_logic ;
  signal u_i2c_master_bit_controller_n32_4 : std_logic ;
  signal u_i2c_master_bit_controller_n34_4 : std_logic ;
  signal u_i2c_master_bit_controller_n35_4 : std_logic ;
  signal u_i2c_master_bit_controller_n37_4 : std_logic ;
  signal u_i2c_master_bit_controller_n38_4 : std_logic ;
  signal u_i2c_master_bit_controller_n39_4 : std_logic ;
  signal u_i2c_master_bit_controller_n40_4 : std_logic ;
  signal u_i2c_master_bit_controller_n41_4 : std_logic ;
  signal u_i2c_master_bit_controller_n42_4 : std_logic ;
  signal u_i2c_master_bit_controller_n43_4 : std_logic ;
  signal u_i2c_master_bit_controller_n44_4 : std_logic ;
  signal u_i2c_master_bit_controller_n123_4 : std_logic ;
  signal u_i2c_master_byte_controller_ACK_OUT_6 : std_logic ;
  signal u_i2c_master_bit_controller_n231 : std_logic ;
  signal u_i2c_master_bit_controller_n228_8 : std_logic ;
  signal u_i2c_master_bit_controller_n228_9 : std_logic ;
  signal u_i2c_master_bit_controller_n227_8 : std_logic ;
  signal u_i2c_master_bit_controller_n227_9 : std_logic ;
  signal u_i2c_master_bit_controller_n225_8 : std_logic ;
  signal u_i2c_master_bit_controller_n222_8 : std_logic ;
  signal u_i2c_master_bit_controller_n222_9 : std_logic ;
  signal u_i2c_master_bit_controller_n221_8 : std_logic ;
  signal u_i2c_master_bit_controller_n220_8 : std_logic ;
  signal u_i2c_master_bit_controller_n219_8 : std_logic ;
  signal u_i2c_master_bit_controller_n218_8 : std_logic ;
  signal u_i2c_master_bit_controller_n217_8 : std_logic ;
  signal u_i2c_master_bit_controller_n217_9 : std_logic ;
  signal u_i2c_master_bit_controller_n214_8 : std_logic ;
  signal u_i2c_master_bit_controller_n214_9 : std_logic ;
  signal u_i2c_master_bit_controller_n213_8 : std_logic ;
  signal u_i2c_master_reg_data_out_0 : std_logic ;
  signal u_i2c_master_reg_data_out_0_8 : std_logic ;
  signal u_i2c_master_bit_controller_n250_7 : std_logic ;
  signal u_i2c_master_bit_controller_n250_8 : std_logic ;
  signal u_i2c_master_byte_controller_n210_8 : std_logic ;
  signal u_i2c_master_byte_controller_n210_9 : std_logic ;
  signal u_i2c_master_byte_controller_n210_10 : std_logic ;
  signal u_i2c_master_byte_controller_n209_8 : std_logic ;
  signal u_i2c_master_byte_controller_n209_9 : std_logic ;
  signal u_i2c_master_byte_controller_n209_10 : std_logic ;
  signal u_i2c_master_byte_controller_n208_8 : std_logic ;
  signal u_i2c_master_byte_controller_n207_8 : std_logic ;
  signal u_i2c_master_byte_controller_n207_9 : std_logic ;
  signal u_i2c_master_byte_controller_n206_8 : std_logic ;
  signal u_i2c_master_byte_controller_n205_8 : std_logic ;
  signal u_i2c_master_byte_controller_n204_8 : std_logic ;
  signal u_i2c_master_byte_controller_n204_9 : std_logic ;
  signal u_i2c_master_byte_controller_n203_8 : std_logic ;
  signal u_i2c_master_byte_controller_n203_9 : std_logic ;
  signal u_i2c_master_byte_controller_n201_8 : std_logic ;
  signal u_i2c_master_byte_controller_n201_9 : std_logic ;
  signal u_i2c_master_byte_controller_n200_8 : std_logic ;
  signal u_i2c_master_byte_controller_n200_9 : std_logic ;
  signal u_i2c_master_byte_controller_n199_8 : std_logic ;
  signal u_i2c_master_bit_controller_n230_8 : std_logic ;
  signal u_i2c_master_bit_controller_n230_9 : std_logic ;
  signal u_i2c_master_bit_controller_n230_10 : std_logic ;
  signal u_i2c_master_bit_controller_n203_20 : std_logic ;
  signal u_i2c_master_bit_controller_n13_6 : std_logic ;
  signal u_i2c_master_bit_controller_n13_7 : std_logic ;
  signal u_i2c_master_bit_controller_n123_5 : std_logic ;
  signal u_i2c_master_byte_controller_CORE_CMD_0_8 : std_logic ;
  signal u_i2c_master_bit_controller_n227_10 : std_logic ;
  signal u_i2c_master_bit_controller_n227_11 : std_logic ;
  signal u_i2c_master_bit_controller_n227_12 : std_logic ;
  signal u_i2c_master_bit_controller_n226 : std_logic ;
  signal u_i2c_master_bit_controller_n225_9 : std_logic ;
  signal u_i2c_master_bit_controller_n225_10 : std_logic ;
  signal u_i2c_master_bit_controller_n222_10 : std_logic ;
  signal u_i2c_master_bit_controller_n222_11 : std_logic ;
  signal u_i2c_master_bit_controller_n218_9 : std_logic ;
  signal u_i2c_master_bit_controller_n218_10 : std_logic ;
  signal u_i2c_master_bit_controller_n214_10 : std_logic ;
  signal u_i2c_master_bit_controller_n214_11 : std_logic ;
  signal u_i2c_master_bit_controller_n250_9 : std_logic ;
  signal u_i2c_master_bit_controller_n250_10 : std_logic ;
  signal u_i2c_master_byte_controller_n210_11 : std_logic ;
  signal u_i2c_master_byte_controller_n210_12 : std_logic ;
  signal u_i2c_master_byte_controller_n210_13 : std_logic ;
  signal u_i2c_master_byte_controller_n209_11 : std_logic ;
  signal u_i2c_master_byte_controller_n208_9 : std_logic ;
  signal u_i2c_master_byte_controller_n207_10 : std_logic ;
  signal u_i2c_master_byte_controller_n207_11 : std_logic ;
  signal u_i2c_master_byte_controller_n205_9 : std_logic ;
  signal u_i2c_master_byte_controller_n203_10 : std_logic ;
  signal u_i2c_master_byte_controller_n201_10 : std_logic ;
  signal u_i2c_master_byte_controller_n200_10 : std_logic ;
  signal u_i2c_master_bit_controller_n230_11 : std_logic ;
  signal u_i2c_master_bit_controller_n230_12 : std_logic ;
  signal u_i2c_master_bit_controller_n203_21 : std_logic ;
  signal u_i2c_master_bit_controller_n226_10 : std_logic ;
  signal u_i2c_master_bit_controller_n250_11 : std_logic ;
  signal u_i2c_master_bit_controller_n250_12 : std_logic ;
  signal u_i2c_master_byte_controller_n209_12 : std_logic ;
  signal u_i2c_master_bit_controller_n203_22 : std_logic ;
  signal u_i2c_master_bit_controller_n216 : std_logic ;
  signal u_i2c_master_bit_controller_n226_12 : std_logic ;
  signal u_i2c_master_bit_controller_n230_14 : std_logic ;
  signal u_i2c_master_byte_controller_CORE_CMD_0_10 : std_logic ;
  signal u_i2c_master_bit_controller_n36_6 : std_logic ;
  signal u_i2c_master_bit_controller_n223 : std_logic ;
  signal u_i2c_master_byte_controller_CORE_CMD_0_12 : std_logic ;
  signal u_i2c_master_bit_controller_SCL_OEN : std_logic ;
  signal u_i2c_master_irq_flag : std_logic ;
  signal u_i2c_master_bit_controller_i2c_busy : std_logic ;
  signal u_i2c_master_bit_controller_sda_chk : std_logic ;
  signal u_i2c_master_n220 : std_logic ;
  signal u_i2c_master_byte_controller_n51 : std_logic ;
  signal u_i2c_master_byte_controller_sr_6 : std_logic ;
  signal u_i2c_master_byte_controller_n52 : std_logic ;
  signal u_i2c_master_bit_controller_n102 : std_logic ;
  signal u_i2c_master_bit_controller_n231_11 : std_logic ;
  signal u_i2c_master_bit_controller_c_state_16 : std_logic ;
  signal u_i2c_master_n16 : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \u_i2c_master/prescale_reg0\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/prescale_reg1\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/control_reg\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/transmit_reg\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/command_reg\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/byte_controller/core_cmd\ : std_logic_vector(3 downto 0);
  signal \u_i2c_master/byte_controller/c_state\ : std_logic_vector(4 downto 1);
  signal \u_i2c_master/byte_controller/receive_reg\ : std_logic_vector(7 downto 0);
  signal \u_i2c_master/byte_controller/dcnt\ : std_logic_vector(2 downto 0);
  signal \u_i2c_master/bit_controller/cnt\ : std_logic_vector(15 downto 0);
  signal \u_i2c_master/bit_controller/c_state\ : std_logic_vector(16 downto 0);
  signal \u_i2c_master/reg_data_out\ : std_logic_vector(7 downto 0);
begin
SCL_iobuf: IOBUF
port map (
  O => SCL_in,
  IO => SCL,
  I => GND_0,
  OEN => u_i2c_master_bit_controller_scl_padoen_o);
SDA_iobuf: IOBUF
port map (
  O => SDA_in,
  IO => SDA,
  I => GND_0,
  OEN => u_i2c_master_bit_controller_sda_padoen_o);
\u_i2c_master/prescale_reg0_6_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_5_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_4_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_3_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_2_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_1_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_0_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_7_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_6_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_5_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_4_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_3_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_2_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_1_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg1_0_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg1\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_i2c_master_n330,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_7_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_6_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_5_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_4_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_3_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_2_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_1_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/control_reg_0_s0\: DFFCE
port map (
  Q => \u_i2c_master/control_reg\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_i2c_master_n338,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_7_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_6_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(6),
  D => I_WDATA(6),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_5_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(5),
  D => I_WDATA(5),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_4_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(4),
  D => I_WDATA(4),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_3_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_2_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(2),
  D => I_WDATA(2),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_1_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(1),
  D => I_WDATA(1),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/transmit_reg_0_s0\: DFFCE
port map (
  Q => \u_i2c_master/transmit_reg\(0),
  D => I_WDATA(0),
  CLK => I_CLK,
  CE => u_i2c_master_n346,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/command_reg_3_s0\: DFFCE
port map (
  Q => \u_i2c_master/command_reg\(3),
  D => I_WDATA(3),
  CLK => I_CLK,
  CE => u_i2c_master_n354,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_7_s0\: DFFCE
port map (
  Q => O_RDATA(7),
  D => \u_i2c_master/reg_data_out\(7),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_6_s0\: DFFCE
port map (
  Q => O_RDATA(6),
  D => \u_i2c_master/reg_data_out\(6),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_5_s0\: DFFCE
port map (
  Q => O_RDATA(5),
  D => \u_i2c_master/reg_data_out\(5),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_4_s0\: DFFCE
port map (
  Q => O_RDATA(4),
  D => \u_i2c_master/reg_data_out\(4),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_3_s0\: DFFCE
port map (
  Q => O_RDATA(3),
  D => \u_i2c_master/reg_data_out\(3),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_2_s0\: DFFCE
port map (
  Q => O_RDATA(2),
  D => \u_i2c_master/reg_data_out\(2),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_1_s0\: DFFCE
port map (
  Q => O_RDATA(1),
  D => \u_i2c_master/reg_data_out\(1),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rdata_0_s0\: DFFCE
port map (
  Q => O_RDATA(0),
  D => \u_i2c_master/reg_data_out\(0),
  CLK => I_CLK,
  CE => I_RX_EN,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/rxack_s0\: DFFC
port map (
  Q => u_i2c_master_rxack,
  D => u_i2c_master_byte_controller_irxack,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/tip_s0\: DFFC
port map (
  Q => u_i2c_master_tip,
  D => u_i2c_master_n218,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/O_IIC_INT_s0\: DFFC
port map (
  Q => O_IIC_INT,
  D => u_i2c_master_n230,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/prescale_reg0_7_s0\: DFFCE
port map (
  Q => \u_i2c_master/prescale_reg0\(7),
  D => I_WDATA(7),
  CLK => I_CLK,
  CE => u_i2c_master_n323,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CORE_CMD_3_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/core_cmd\(3),
  D => u_i2c_master_byte_controller_n199,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CORE_CMD_2_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/core_cmd\(2),
  D => u_i2c_master_byte_controller_n200,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CORE_CMD_1_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/core_cmd\(1),
  D => u_i2c_master_byte_controller_n201,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CORE_TXD_s0\: DFFC
port map (
  Q => u_i2c_master_byte_controller_core_txd,
  D => u_i2c_master_byte_controller_n203,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/shift_s0\: DFFC
port map (
  Q => u_i2c_master_byte_controller_shift,
  D => u_i2c_master_byte_controller_n204,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/ld_s0\: DFFC
port map (
  Q => u_i2c_master_byte_controller_ld,
  D => u_i2c_master_byte_controller_n205,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CMD_ACK_s0\: DFFC
port map (
  Q => u_i2c_master_byte_controller_done,
  D => u_i2c_master_byte_controller_n206,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/c_state_4_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/c_state\(4),
  D => u_i2c_master_byte_controller_n207,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/c_state_3_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/c_state\(3),
  D => u_i2c_master_byte_controller_n208,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/c_state_2_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/c_state\(2),
  D => u_i2c_master_byte_controller_n209,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/c_state_1_s0\: DFFC
port map (
  Q => \u_i2c_master/byte_controller/c_state\(1),
  D => u_i2c_master_byte_controller_n210,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/sSCL_s0\: DFFP
port map (
  Q => u_i2c_master_bit_controller_sSCL,
  D => SCL_in,
  CLK => I_CLK,
  PRESET => u_i2c_master_n16);
\u_i2c_master/bit_controller/sSDA_s0\: DFFP
port map (
  Q => u_i2c_master_bit_controller_sSDA,
  D => SDA_in,
  CLK => I_CLK,
  PRESET => u_i2c_master_n16);
\u_i2c_master/bit_controller/dSCL_s0\: DFFP
port map (
  Q => u_i2c_master_bit_controller_dSCL,
  D => u_i2c_master_bit_controller_sSCL,
  CLK => I_CLK,
  PRESET => u_i2c_master_n16);
\u_i2c_master/bit_controller/dSDA_s0\: DFFP
port map (
  Q => u_i2c_master_bit_controller_dSDA,
  D => u_i2c_master_bit_controller_sSDA,
  CLK => I_CLK,
  PRESET => u_i2c_master_n16);
\u_i2c_master/bit_controller/sta_condition_s0\: DFFC
port map (
  Q => u_i2c_master_bit_controller_sta_condition,
  D => u_i2c_master_bit_controller_n93,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/sto_condition_s0\: DFFC
port map (
  Q => u_i2c_master_bit_controller_sto_condition,
  D => u_i2c_master_bit_controller_n96,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cmd_stop_s0\: DFFCE
port map (
  Q => u_i2c_master_bit_controller_cmd_stop,
  D => u_i2c_master_bit_controller_n110,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_clk_en,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/AL_s0\: DFFC
port map (
  Q => u_i2c_master_bit_controller_i2c_al,
  D => u_i2c_master_bit_controller_n123,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/DOUT_s0\: DFFCE
port map (
  Q => u_i2c_master_bit_controller_core_rxd,
  D => u_i2c_master_bit_controller_sSDA,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_n129,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/CMD_ACK_s0\: DFFC
port map (
  Q => u_i2c_master_bit_controller_core_ack,
  D => u_i2c_master_bit_controller_n250,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/dscl_oen_s0\: DFF
port map (
  Q => u_i2c_master_bit_controller_dscl_oen,
  D => u_i2c_master_bit_controller_scl_padoen_o,
  CLK => I_CLK);
\u_i2c_master/bit_controller/clk_en_s0\: DFFP
port map (
  Q => u_i2c_master_bit_controller_clk_en,
  D => u_i2c_master_bit_controller_n13,
  CLK => I_CLK,
  PRESET => u_i2c_master_n16);
\u_i2c_master/command_reg_7_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/command_reg\(7),
  D => u_i2c_master_n152,
  CLK => I_CLK,
  CE => u_i2c_master_n136,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/command_reg_6_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/command_reg\(6),
  D => u_i2c_master_n153,
  CLK => I_CLK,
  CE => u_i2c_master_n136,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/command_reg_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/command_reg\(5),
  D => u_i2c_master_n154,
  CLK => I_CLK,
  CE => u_i2c_master_n136,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/command_reg_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/command_reg\(4),
  D => u_i2c_master_n155,
  CLK => I_CLK,
  CE => u_i2c_master_n136,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/command_reg_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/command_reg\(0),
  D => u_i2c_master_n159,
  CLK => I_CLK,
  CE => u_i2c_master_n136,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/al_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_i2c_master_al,
  D => u_i2c_master_bit_controller_i2c_al,
  CLK => I_CLK,
  CE => u_i2c_master_al_8,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_6_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(6),
  D => u_i2c_master_byte_controller_n20,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(5),
  D => u_i2c_master_byte_controller_n21,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(4),
  D => u_i2c_master_byte_controller_n22,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(3),
  D => u_i2c_master_byte_controller_n23,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(2),
  D => u_i2c_master_byte_controller_n24,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(1),
  D => u_i2c_master_byte_controller_n25,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(0),
  D => u_i2c_master_byte_controller_n26,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/dcnt_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/dcnt\(2),
  D => u_i2c_master_byte_controller_n50,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/CORE_CMD_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/core_cmd\(0),
  D => u_i2c_master_byte_controller_n104,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_CORE_CMD_0,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/ACK_OUT_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => u_i2c_master_byte_controller_irxack,
  D => u_i2c_master_byte_controller_n198,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_ACK_OUT,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/sr_7_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/receive_reg\(7),
  D => u_i2c_master_byte_controller_n19,
  CLK => I_CLK,
  CE => u_i2c_master_byte_controller_sr_6,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_15_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(15),
  D => u_i2c_master_bit_controller_n31,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_14_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(14),
  D => u_i2c_master_bit_controller_n32,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_13_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(13),
  D => u_i2c_master_bit_controller_n33,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_12_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(12),
  D => u_i2c_master_bit_controller_n34,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_11_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(11),
  D => u_i2c_master_bit_controller_n35,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_10_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(10),
  D => u_i2c_master_bit_controller_n36,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_9_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(9),
  D => u_i2c_master_bit_controller_n37,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_8_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(8),
  D => u_i2c_master_bit_controller_n38,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_7_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(7),
  D => u_i2c_master_bit_controller_n39,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_6_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(6),
  D => u_i2c_master_bit_controller_n40,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(5),
  D => u_i2c_master_bit_controller_n41,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(4),
  D => u_i2c_master_bit_controller_n42,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(3),
  D => u_i2c_master_bit_controller_n43,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(2),
  D => u_i2c_master_bit_controller_n44,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(1),
  D => u_i2c_master_bit_controller_n45,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/cnt_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/cnt\(0),
  D => u_i2c_master_bit_controller_n46,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_cnt_15,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_16_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(16),
  D => u_i2c_master_bit_controller_n212,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_15_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(15),
  D => u_i2c_master_bit_controller_n213,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_14_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(14),
  D => u_i2c_master_bit_controller_n214,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_13_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(13),
  D => u_i2c_master_bit_controller_n215,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_12_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(12),
  D => u_i2c_master_bit_controller_n216,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_11_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(11),
  D => u_i2c_master_bit_controller_n217,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_10_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(10),
  D => u_i2c_master_bit_controller_n218,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_9_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(9),
  D => u_i2c_master_bit_controller_n219,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_8_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(8),
  D => u_i2c_master_bit_controller_n220,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_7_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(7),
  D => u_i2c_master_bit_controller_n221,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_6_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(6),
  D => u_i2c_master_bit_controller_n222,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(5),
  D => u_i2c_master_bit_controller_n223,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(4),
  D => u_i2c_master_bit_controller_n224,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(3),
  D => u_i2c_master_bit_controller_n225,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(2),
  D => u_i2c_master_bit_controller_n226_12,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(1),
  D => u_i2c_master_bit_controller_n227,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/c_state_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/bit_controller/c_state\(0),
  D => u_i2c_master_bit_controller_n228,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/SCL_OEN_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => u_i2c_master_bit_controller_scl_padoen_o,
  D => u_i2c_master_bit_controller_n203,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_SCL_OEN,
  PRESET => u_i2c_master_n16);
\u_i2c_master/bit_controller/SDA_OEN_s1\: DFFPE
generic map (
  INIT => '1'
)
port map (
  Q => u_i2c_master_bit_controller_sda_padoen_o,
  D => u_i2c_master_bit_controller_n230,
  CLK => I_CLK,
  CE => u_i2c_master_bit_controller_c_state_16,
  PRESET => u_i2c_master_n16);
\u_i2c_master/n169_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n169,
  I0 => \u_i2c_master/prescale_reg0\(7),
  I1 => \u_i2c_master/prescale_reg1\(7),
  I2 => I_RADDR(0));
\u_i2c_master/n169_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n169_19,
  I0 => \u_i2c_master/control_reg\(7),
  I1 => \u_i2c_master/byte_controller/receive_reg\(7),
  I2 => I_RADDR(0));
\u_i2c_master/n170_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n170,
  I0 => \u_i2c_master/prescale_reg0\(6),
  I1 => \u_i2c_master/prescale_reg1\(6),
  I2 => I_RADDR(0));
\u_i2c_master/n170_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n170_19,
  I0 => \u_i2c_master/control_reg\(6),
  I1 => \u_i2c_master/byte_controller/receive_reg\(6),
  I2 => I_RADDR(0));
\u_i2c_master/n171_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n171,
  I0 => \u_i2c_master/prescale_reg0\(5),
  I1 => \u_i2c_master/prescale_reg1\(5),
  I2 => I_RADDR(0));
\u_i2c_master/n171_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n171_19,
  I0 => \u_i2c_master/control_reg\(5),
  I1 => \u_i2c_master/byte_controller/receive_reg\(5),
  I2 => I_RADDR(0));
\u_i2c_master/n172_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n172,
  I0 => \u_i2c_master/prescale_reg0\(4),
  I1 => \u_i2c_master/prescale_reg1\(4),
  I2 => I_RADDR(0));
\u_i2c_master/n172_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n172_15,
  I0 => \u_i2c_master/control_reg\(4),
  I1 => \u_i2c_master/byte_controller/receive_reg\(4),
  I2 => I_RADDR(0));
\u_i2c_master/n173_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n173,
  I0 => \u_i2c_master/prescale_reg0\(3),
  I1 => \u_i2c_master/prescale_reg1\(3),
  I2 => I_RADDR(0));
\u_i2c_master/n173_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n173_15,
  I0 => \u_i2c_master/control_reg\(3),
  I1 => \u_i2c_master/byte_controller/receive_reg\(3),
  I2 => I_RADDR(0));
\u_i2c_master/n174_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n174,
  I0 => \u_i2c_master/prescale_reg0\(2),
  I1 => \u_i2c_master/prescale_reg1\(2),
  I2 => I_RADDR(0));
\u_i2c_master/n174_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n174_15,
  I0 => \u_i2c_master/control_reg\(2),
  I1 => \u_i2c_master/byte_controller/receive_reg\(2),
  I2 => I_RADDR(0));
\u_i2c_master/n175_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n175,
  I0 => \u_i2c_master/prescale_reg0\(1),
  I1 => \u_i2c_master/prescale_reg1\(1),
  I2 => I_RADDR(0));
\u_i2c_master/n175_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n175_19,
  I0 => \u_i2c_master/control_reg\(1),
  I1 => \u_i2c_master/byte_controller/receive_reg\(1),
  I2 => I_RADDR(0));
\u_i2c_master/n176_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n176,
  I0 => \u_i2c_master/prescale_reg0\(0),
  I1 => \u_i2c_master/prescale_reg1\(0),
  I2 => I_RADDR(0));
\u_i2c_master/n176_s15\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_n176_19,
  I0 => \u_i2c_master/control_reg\(0),
  I1 => \u_i2c_master/byte_controller/receive_reg\(0),
  I2 => I_RADDR(0));
\u_i2c_master/n169_s13\: MUX2_LUT5
port map (
  O => u_i2c_master_n169_21,
  I0 => u_i2c_master_n169,
  I1 => u_i2c_master_n169_19,
  S0 => I_RADDR(1));
\u_i2c_master/n170_s13\: MUX2_LUT5
port map (
  O => u_i2c_master_n170_21,
  I0 => u_i2c_master_n170,
  I1 => u_i2c_master_n170_19,
  S0 => I_RADDR(1));
\u_i2c_master/n171_s13\: MUX2_LUT5
port map (
  O => u_i2c_master_n171_21,
  I0 => u_i2c_master_n171,
  I1 => u_i2c_master_n171_19,
  S0 => I_RADDR(1));
\u_i2c_master/n172_s11\: MUX2_LUT5
port map (
  O => u_i2c_master_n172_17,
  I0 => u_i2c_master_n172,
  I1 => u_i2c_master_n172_15,
  S0 => I_RADDR(1));
\u_i2c_master/n173_s11\: MUX2_LUT5
port map (
  O => u_i2c_master_n173_17,
  I0 => u_i2c_master_n173,
  I1 => u_i2c_master_n173_15,
  S0 => I_RADDR(1));
\u_i2c_master/n174_s11\: MUX2_LUT5
port map (
  O => u_i2c_master_n174_17,
  I0 => u_i2c_master_n174,
  I1 => u_i2c_master_n174_15,
  S0 => I_RADDR(1));
\u_i2c_master/n175_s13\: MUX2_LUT5
port map (
  O => u_i2c_master_n175_21,
  I0 => u_i2c_master_n175,
  I1 => u_i2c_master_n175_19,
  S0 => I_RADDR(1));
\u_i2c_master/n176_s13\: MUX2_LUT5
port map (
  O => u_i2c_master_n176_21,
  I0 => u_i2c_master_n176,
  I1 => u_i2c_master_n176_19,
  S0 => I_RADDR(1));
\u_i2c_master/n323_s0\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_n323,
  I0 => I_WADDR(0),
  I1 => I_WADDR(1),
  I2 => I_WADDR(2),
  I3 => I_TX_EN);
\u_i2c_master/n330_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_n330,
  I0 => I_WADDR(1),
  I1 => I_WADDR(2),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\u_i2c_master/n338_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_n338,
  I0 => I_WADDR(0),
  I1 => I_WADDR(2),
  I2 => I_WADDR(1),
  I3 => I_TX_EN);
\u_i2c_master/n346_s0\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_n346,
  I0 => I_WADDR(2),
  I1 => I_WADDR(1),
  I2 => I_WADDR(0),
  I3 => I_TX_EN);
\u_i2c_master/n354_s0\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_n354,
  I0 => I_WADDR(0),
  I1 => I_WADDR(1),
  I2 => u_i2c_master_n354_4,
  I3 => I_WADDR(2));
\u_i2c_master/n136_s0\: LUT4
generic map (
  INIT => X"FF0E"
)
port map (
  F => u_i2c_master_n136,
  I0 => u_i2c_master_byte_controller_done,
  I1 => u_i2c_master_bit_controller_i2c_al,
  I2 => I_TX_EN,
  I3 => u_i2c_master_n354);
\u_i2c_master/n218_s0\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_i2c_master_n218,
  I0 => \u_i2c_master/command_reg\(5),
  I1 => \u_i2c_master/command_reg\(4));
\u_i2c_master/n230_s0\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n230,
  I0 => u_i2c_master_irq_flag,
  I1 => \u_i2c_master/control_reg\(6));
\u_i2c_master/byte_controller/n19_s0\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => u_i2c_master_byte_controller_n19,
  I0 => \u_i2c_master/transmit_reg\(7),
  I1 => \u_i2c_master/byte_controller/receive_reg\(6),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n20_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n20,
  I0 => \u_i2c_master/byte_controller/receive_reg\(5),
  I1 => \u_i2c_master/transmit_reg\(6),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n21_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n21,
  I0 => \u_i2c_master/byte_controller/receive_reg\(4),
  I1 => \u_i2c_master/transmit_reg\(5),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n22_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n22,
  I0 => \u_i2c_master/byte_controller/receive_reg\(3),
  I1 => \u_i2c_master/transmit_reg\(4),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n23_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n23,
  I0 => \u_i2c_master/byte_controller/receive_reg\(2),
  I1 => \u_i2c_master/transmit_reg\(3),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n24_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n24,
  I0 => \u_i2c_master/byte_controller/receive_reg\(1),
  I1 => \u_i2c_master/transmit_reg\(2),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n25_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n25,
  I0 => \u_i2c_master/byte_controller/receive_reg\(0),
  I1 => \u_i2c_master/transmit_reg\(1),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/byte_controller/n26_s0\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => u_i2c_master_byte_controller_n26,
  I0 => u_i2c_master_bit_controller_core_rxd,
  I1 => \u_i2c_master/transmit_reg\(0),
  I2 => u_i2c_master_byte_controller_ld);
\u_i2c_master/bit_controller/n13_s0\: LUT3
generic map (
  INIT => X"8F"
)
port map (
  F => u_i2c_master_bit_controller_n13,
  I0 => u_i2c_master_bit_controller_n13_4,
  I1 => u_i2c_master_bit_controller_n13_5,
  I2 => \u_i2c_master/control_reg\(7));
\u_i2c_master/bit_controller/n31_s0\: LUT4
generic map (
  INIT => X"3A8A"
)
port map (
  F => u_i2c_master_bit_controller_n31,
  I0 => \u_i2c_master/prescale_reg1\(7),
  I1 => u_i2c_master_bit_controller_n31_4,
  I2 => \u_i2c_master/control_reg\(7),
  I3 => \u_i2c_master/bit_controller/cnt\(15));
\u_i2c_master/bit_controller/n32_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n32,
  I0 => \u_i2c_master/prescale_reg1\(6),
  I1 => u_i2c_master_bit_controller_n32_4,
  I2 => \u_i2c_master/bit_controller/cnt\(14),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n33_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n33,
  I0 => \u_i2c_master/prescale_reg1\(5),
  I1 => \u_i2c_master/bit_controller/cnt\(13),
  I2 => u_i2c_master_bit_controller_n13_4,
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n34_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n34,
  I0 => \u_i2c_master/prescale_reg1\(4),
  I1 => u_i2c_master_bit_controller_n34_4,
  I2 => \u_i2c_master/bit_controller/cnt\(12),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n35_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n35,
  I0 => \u_i2c_master/prescale_reg1\(3),
  I1 => u_i2c_master_bit_controller_n35_4,
  I2 => \u_i2c_master/bit_controller/cnt\(11),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n36_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n36,
  I0 => \u_i2c_master/prescale_reg1\(2),
  I1 => u_i2c_master_bit_controller_n36_6,
  I2 => \u_i2c_master/bit_controller/cnt\(10),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n37_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n37,
  I0 => \u_i2c_master/prescale_reg1\(1),
  I1 => \u_i2c_master/bit_controller/cnt\(9),
  I2 => u_i2c_master_bit_controller_n37_4,
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n38_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n38,
  I0 => \u_i2c_master/prescale_reg1\(0),
  I1 => u_i2c_master_bit_controller_n38_4,
  I2 => \u_i2c_master/bit_controller/cnt\(8),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n39_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n39,
  I0 => \u_i2c_master/prescale_reg0\(7),
  I1 => \u_i2c_master/bit_controller/cnt\(7),
  I2 => u_i2c_master_bit_controller_n39_4,
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n40_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n40,
  I0 => \u_i2c_master/prescale_reg0\(6),
  I1 => u_i2c_master_bit_controller_n40_4,
  I2 => \u_i2c_master/bit_controller/cnt\(6),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n41_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n41,
  I0 => \u_i2c_master/prescale_reg0\(5),
  I1 => u_i2c_master_bit_controller_n41_4,
  I2 => \u_i2c_master/bit_controller/cnt\(5),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n42_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n42,
  I0 => \u_i2c_master/prescale_reg0\(4),
  I1 => \u_i2c_master/bit_controller/cnt\(4),
  I2 => u_i2c_master_bit_controller_n42_4,
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n43_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n43,
  I0 => \u_i2c_master/prescale_reg0\(3),
  I1 => u_i2c_master_bit_controller_n43_4,
  I2 => \u_i2c_master/bit_controller/cnt\(3),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n44_s0\: LUT4
generic map (
  INIT => X"AA3C"
)
port map (
  F => u_i2c_master_bit_controller_n44,
  I0 => \u_i2c_master/prescale_reg0\(2),
  I1 => u_i2c_master_bit_controller_n44_4,
  I2 => \u_i2c_master/bit_controller/cnt\(2),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n45_s0\: LUT4
generic map (
  INIT => X"AAC3"
)
port map (
  F => u_i2c_master_bit_controller_n45,
  I0 => \u_i2c_master/prescale_reg0\(1),
  I1 => \u_i2c_master/bit_controller/cnt\(1),
  I2 => \u_i2c_master/bit_controller/cnt\(0),
  I3 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n46_s0\: LUT3
generic map (
  INIT => X"A3"
)
port map (
  F => u_i2c_master_bit_controller_n46,
  I0 => \u_i2c_master/prescale_reg0\(0),
  I1 => \u_i2c_master/bit_controller/cnt\(0),
  I2 => u_i2c_master_bit_controller_n13);
\u_i2c_master/bit_controller/n93_s0\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n93,
  I0 => u_i2c_master_bit_controller_sSDA,
  I1 => u_i2c_master_bit_controller_sSCL,
  I2 => u_i2c_master_bit_controller_dSDA);
\u_i2c_master/bit_controller/n96_s0\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n96,
  I0 => u_i2c_master_bit_controller_dSDA,
  I1 => u_i2c_master_bit_controller_sSDA,
  I2 => u_i2c_master_bit_controller_sSCL);
\u_i2c_master/bit_controller/n110_s0\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n110,
  I0 => \u_i2c_master/byte_controller/core_cmd\(3),
  I1 => \u_i2c_master/byte_controller/core_cmd\(2),
  I2 => \u_i2c_master/byte_controller/core_cmd\(0),
  I3 => \u_i2c_master/byte_controller/core_cmd\(1));
\u_i2c_master/bit_controller/n123_s0\: LUT4
generic map (
  INIT => X"FF40"
)
port map (
  F => u_i2c_master_bit_controller_n123,
  I0 => u_i2c_master_bit_controller_sSDA,
  I1 => u_i2c_master_bit_controller_sda_chk,
  I2 => u_i2c_master_bit_controller_sda_padoen_o,
  I3 => u_i2c_master_bit_controller_n123_4);
\u_i2c_master/bit_controller/n129_s0\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_bit_controller_n129,
  I0 => u_i2c_master_bit_controller_dSCL,
  I1 => u_i2c_master_bit_controller_sSCL);
\u_i2c_master/al_s3\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_i2c_master_al_8,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/command_reg\(7));
\u_i2c_master/byte_controller/CORE_CMD_0_s3\: LUT4
generic map (
  INIT => X"FAFC"
)
port map (
  F => u_i2c_master_byte_controller_CORE_CMD_0,
  I0 => u_i2c_master_byte_controller_CORE_CMD_0_10,
  I1 => u_i2c_master_bit_controller_core_ack,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_byte_controller_CORE_CMD_0_12);
\u_i2c_master/byte_controller/ACK_OUT_s3\: LUT3
generic map (
  INIT => X"F8"
)
port map (
  F => u_i2c_master_byte_controller_ACK_OUT,
  I0 => u_i2c_master_bit_controller_core_ack,
  I1 => u_i2c_master_byte_controller_ACK_OUT_6,
  I2 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/bit_controller/cnt_15_s3\: LUT3
generic map (
  INIT => X"EF"
)
port map (
  F => u_i2c_master_bit_controller_cnt_15,
  I0 => u_i2c_master_bit_controller_sSCL,
  I1 => u_i2c_master_bit_controller_n13,
  I2 => u_i2c_master_bit_controller_dscl_oen);
\u_i2c_master/bit_controller/n228_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n228,
  I0 => \u_i2c_master/byte_controller/core_cmd\(3),
  I1 => \u_i2c_master/byte_controller/core_cmd\(2),
  I2 => u_i2c_master_bit_controller_n228_8,
  I3 => u_i2c_master_bit_controller_n228_9);
\u_i2c_master/bit_controller/n227_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n227,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_n227_8,
  I2 => u_i2c_master_bit_controller_n227_9);
\u_i2c_master/bit_controller/n225_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n225,
  I0 => \u_i2c_master/bit_controller/c_state\(3),
  I1 => \u_i2c_master/bit_controller/c_state\(2),
  I2 => u_i2c_master_bit_controller_n225_8);
\u_i2c_master/bit_controller/n224_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n224,
  I0 => \u_i2c_master/bit_controller/c_state\(2),
  I1 => \u_i2c_master/bit_controller/c_state\(3),
  I2 => u_i2c_master_bit_controller_n225_8);
\u_i2c_master/bit_controller/n222_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n222,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(4),
  I2 => u_i2c_master_bit_controller_n222_8,
  I3 => u_i2c_master_bit_controller_n222_9);
\u_i2c_master/bit_controller/n221_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n221,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(4),
  I2 => u_i2c_master_bit_controller_n221_8,
  I3 => u_i2c_master_bit_controller_n222_9);
\u_i2c_master/bit_controller/n220_s2\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n220,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(6),
  I2 => u_i2c_master_bit_controller_n220_8);
\u_i2c_master/bit_controller/n219_s2\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_bit_controller_n219,
  I0 => \u_i2c_master/byte_controller/core_cmd\(2),
  I1 => \u_i2c_master/byte_controller/core_cmd\(3),
  I2 => u_i2c_master_bit_controller_n228_9,
  I3 => u_i2c_master_bit_controller_n219_8);
\u_i2c_master/bit_controller/n218_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n218,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(8),
  I2 => u_i2c_master_bit_controller_n227_8,
  I3 => u_i2c_master_bit_controller_n218_8);
\u_i2c_master/bit_controller/n217_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n217,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_n217_8,
  I2 => u_i2c_master_bit_controller_n217_9);
\u_i2c_master/bit_controller/n215_s2\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_bit_controller_n215,
  I0 => \u_i2c_master/byte_controller/core_cmd\(3),
  I1 => \u_i2c_master/byte_controller/core_cmd\(2),
  I2 => u_i2c_master_bit_controller_n228_9,
  I3 => u_i2c_master_bit_controller_n219_8);
\u_i2c_master/bit_controller/n214_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n214,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_n214_8,
  I2 => u_i2c_master_bit_controller_n214_9,
  I3 => \u_i2c_master/bit_controller/c_state\(13));
\u_i2c_master/bit_controller/n213_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n213,
  I0 => \u_i2c_master/bit_controller/c_state\(15),
  I1 => \u_i2c_master/bit_controller/c_state\(14),
  I2 => u_i2c_master_bit_controller_n213_8);
\u_i2c_master/bit_controller/n212_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n212,
  I0 => \u_i2c_master/bit_controller/c_state\(14),
  I1 => \u_i2c_master/bit_controller/c_state\(15),
  I2 => u_i2c_master_bit_controller_n213_8);
\u_i2c_master/byte_controller/n198_s2\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_byte_controller_n198,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_core_rxd);
\u_i2c_master/byte_controller/n104_s2\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_byte_controller_n104,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/command_reg\(7),
  I2 => u_i2c_master_byte_controller_CORE_CMD_0_12);
\u_i2c_master/n159_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n159,
  I0 => I_TX_EN,
  I1 => I_WDATA(0));
\u_i2c_master/n155_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n155,
  I0 => I_TX_EN,
  I1 => I_WDATA(4));
\u_i2c_master/n154_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n154,
  I0 => I_TX_EN,
  I1 => I_WDATA(5));
\u_i2c_master/n153_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n153,
  I0 => I_TX_EN,
  I1 => I_WDATA(6));
\u_i2c_master/n152_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n152,
  I0 => I_TX_EN,
  I1 => I_WDATA(7));
\u_i2c_master/reg_data_out_0_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_i2c_master/reg_data_out\(0),
  I0 => u_i2c_master_reg_data_out_0,
  I1 => u_i2c_master_n176_21,
  I2 => u_i2c_master_irq_flag,
  I3 => u_i2c_master_reg_data_out_0_8);
\u_i2c_master/reg_data_out_1_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_i2c_master/reg_data_out\(1),
  I0 => u_i2c_master_tip,
  I1 => u_i2c_master_reg_data_out_0_8,
  I2 => u_i2c_master_n175_21,
  I3 => u_i2c_master_reg_data_out_0);
\u_i2c_master/reg_data_out_5_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_i2c_master/reg_data_out\(5),
  I0 => u_i2c_master_al,
  I1 => u_i2c_master_reg_data_out_0_8,
  I2 => u_i2c_master_n171_21,
  I3 => u_i2c_master_reg_data_out_0);
\u_i2c_master/reg_data_out_6_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_i2c_master/reg_data_out\(6),
  I0 => u_i2c_master_bit_controller_i2c_busy,
  I1 => u_i2c_master_reg_data_out_0_8,
  I2 => u_i2c_master_n170_21,
  I3 => u_i2c_master_reg_data_out_0);
\u_i2c_master/reg_data_out_7_s1\: LUT4
generic map (
  INIT => X"F888"
)
port map (
  F => \u_i2c_master/reg_data_out\(7),
  I0 => u_i2c_master_rxack,
  I1 => u_i2c_master_reg_data_out_0_8,
  I2 => u_i2c_master_n169_21,
  I3 => u_i2c_master_reg_data_out_0);
\u_i2c_master/bit_controller/n250_s1\: LUT4
generic map (
  INIT => X"0E00"
)
port map (
  F => u_i2c_master_bit_controller_n250,
  I0 => u_i2c_master_bit_controller_n250_7,
  I1 => u_i2c_master_bit_controller_n250_8,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_clk_en);
\u_i2c_master/byte_controller/n210_s2\: LUT4
generic map (
  INIT => X"00F4"
)
port map (
  F => u_i2c_master_byte_controller_n210,
  I0 => u_i2c_master_byte_controller_n210_8,
  I1 => u_i2c_master_byte_controller_n210_9,
  I2 => u_i2c_master_byte_controller_n210_10,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/byte_controller/n209_s2\: LUT4
generic map (
  INIT => X"00F4"
)
port map (
  F => u_i2c_master_byte_controller_n209,
  I0 => u_i2c_master_byte_controller_n209_8,
  I1 => u_i2c_master_byte_controller_n209_9,
  I2 => u_i2c_master_byte_controller_n209_10,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/byte_controller/n208_s2\: LUT4
generic map (
  INIT => X"0C0A"
)
port map (
  F => u_i2c_master_byte_controller_n208,
  I0 => u_i2c_master_byte_controller_ACK_OUT_6,
  I1 => u_i2c_master_byte_controller_n208_8,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_core_ack);
\u_i2c_master/byte_controller/n207_s2\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_byte_controller_n207,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_byte_controller_n207_8,
  I2 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/byte_controller/n206_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_byte_controller_n206,
  I0 => u_i2c_master_byte_controller_n206_8,
  I1 => u_i2c_master_bit_controller_i2c_al,
  I2 => u_i2c_master_bit_controller_core_ack,
  I3 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/byte_controller/n205_s2\: LUT4
generic map (
  INIT => X"00F8"
)
port map (
  F => u_i2c_master_byte_controller_n205,
  I0 => u_i2c_master_byte_controller_CORE_CMD_0_10,
  I1 => u_i2c_master_byte_controller_CORE_CMD_0_12,
  I2 => u_i2c_master_byte_controller_n205_8,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/byte_controller/n204_s2\: LUT4
generic map (
  INIT => X"F400"
)
port map (
  F => u_i2c_master_byte_controller_n204,
  I0 => u_i2c_master_byte_controller_n204_8,
  I1 => u_i2c_master_byte_controller_n209_9,
  I2 => u_i2c_master_byte_controller_n210_9,
  I3 => u_i2c_master_byte_controller_n204_9);
\u_i2c_master/byte_controller/n203_s2\: LUT4
generic map (
  INIT => X"004F"
)
port map (
  F => u_i2c_master_byte_controller_n203,
  I0 => \u_i2c_master/byte_controller/c_state\(3),
  I1 => u_i2c_master_byte_controller_n203_8,
  I2 => u_i2c_master_byte_controller_n203_9,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/byte_controller/n201_s2\: LUT4
generic map (
  INIT => X"030A"
)
port map (
  F => u_i2c_master_byte_controller_n201,
  I0 => u_i2c_master_byte_controller_n201_8,
  I1 => u_i2c_master_byte_controller_n201_9,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_byte_controller_CORE_CMD_0_12);
\u_i2c_master/byte_controller/n200_s2\: LUT4
generic map (
  INIT => X"008F"
)
port map (
  F => u_i2c_master_byte_controller_n200,
  I0 => \u_i2c_master/byte_controller/core_cmd\(2),
  I1 => u_i2c_master_byte_controller_n200_8,
  I2 => u_i2c_master_byte_controller_n200_9,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/byte_controller/n199_s2\: LUT4
generic map (
  INIT => X"008F"
)
port map (
  F => u_i2c_master_byte_controller_n199,
  I0 => \u_i2c_master/byte_controller/core_cmd\(3),
  I1 => u_i2c_master_byte_controller_n200_8,
  I2 => u_i2c_master_byte_controller_n199_8,
  I3 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/bit_controller/n230_s1\: LUT4
generic map (
  INIT => X"EFFF"
)
port map (
  F => u_i2c_master_bit_controller_n230,
  I0 => u_i2c_master_bit_controller_n230_14,
  I1 => u_i2c_master_bit_controller_n230_8,
  I2 => u_i2c_master_bit_controller_n230_9,
  I3 => u_i2c_master_bit_controller_n230_10);
\u_i2c_master/byte_controller/n50_s1\: LUT4
generic map (
  INIT => X"FEF1"
)
port map (
  F => u_i2c_master_byte_controller_n50,
  I0 => \u_i2c_master/byte_controller/dcnt\(0),
  I1 => \u_i2c_master/byte_controller/dcnt\(1),
  I2 => u_i2c_master_byte_controller_ld,
  I3 => \u_i2c_master/byte_controller/dcnt\(2));
\u_i2c_master/bit_controller/n203_s10\: LUT4
generic map (
  INIT => X"EFFF"
)
port map (
  F => u_i2c_master_bit_controller_n203,
  I0 => u_i2c_master_bit_controller_n231,
  I1 => u_i2c_master_bit_controller_n220_8,
  I2 => u_i2c_master_bit_controller_n230_10,
  I3 => u_i2c_master_bit_controller_n203_20);
\u_i2c_master/n354_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_n354_4,
  I0 => I_TX_EN,
  I1 => \u_i2c_master/control_reg\(7));
\u_i2c_master/bit_controller/n13_s1\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_bit_controller_n13_4,
  I0 => \u_i2c_master/bit_controller/cnt\(4),
  I1 => u_i2c_master_bit_controller_n13_6,
  I2 => u_i2c_master_bit_controller_n13_7,
  I3 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n13_s2\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_bit_controller_n13_5,
  I0 => \u_i2c_master/bit_controller/cnt\(13),
  I1 => \u_i2c_master/bit_controller/cnt\(14),
  I2 => \u_i2c_master/bit_controller/cnt\(15));
\u_i2c_master/bit_controller/n31_s1\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n31_4,
  I0 => \u_i2c_master/bit_controller/cnt\(13),
  I1 => \u_i2c_master/bit_controller/cnt\(14),
  I2 => u_i2c_master_bit_controller_n13_4);
\u_i2c_master/bit_controller/n32_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_bit_controller_n32_4,
  I0 => \u_i2c_master/bit_controller/cnt\(13),
  I1 => u_i2c_master_bit_controller_n13_4);
\u_i2c_master/bit_controller/n34_s1\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n34_4,
  I0 => \u_i2c_master/bit_controller/cnt\(9),
  I1 => \u_i2c_master/bit_controller/cnt\(10),
  I2 => \u_i2c_master/bit_controller/cnt\(11),
  I3 => u_i2c_master_bit_controller_n37_4);
\u_i2c_master/bit_controller/n35_s1\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n35_4,
  I0 => \u_i2c_master/bit_controller/cnt\(9),
  I1 => \u_i2c_master/bit_controller/cnt\(10),
  I2 => u_i2c_master_bit_controller_n37_4);
\u_i2c_master/bit_controller/n37_s1\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n37_4,
  I0 => \u_i2c_master/bit_controller/cnt\(4),
  I1 => u_i2c_master_bit_controller_n13_7,
  I2 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n38_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_bit_controller_n38_4,
  I0 => \u_i2c_master/bit_controller/cnt\(7),
  I1 => u_i2c_master_bit_controller_n39_4);
\u_i2c_master/bit_controller/n39_s1\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n39_4,
  I0 => \u_i2c_master/bit_controller/cnt\(4),
  I1 => \u_i2c_master/bit_controller/cnt\(5),
  I2 => \u_i2c_master/bit_controller/cnt\(6),
  I3 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n40_s1\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n40_4,
  I0 => \u_i2c_master/bit_controller/cnt\(4),
  I1 => \u_i2c_master/bit_controller/cnt\(5),
  I2 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n41_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_bit_controller_n41_4,
  I0 => \u_i2c_master/bit_controller/cnt\(4),
  I1 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n42_s1\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n42_4,
  I0 => \u_i2c_master/bit_controller/cnt\(0),
  I1 => \u_i2c_master/bit_controller/cnt\(1),
  I2 => \u_i2c_master/bit_controller/cnt\(2),
  I3 => \u_i2c_master/bit_controller/cnt\(3));
\u_i2c_master/bit_controller/n43_s1\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_bit_controller_n43_4,
  I0 => \u_i2c_master/bit_controller/cnt\(0),
  I1 => \u_i2c_master/bit_controller/cnt\(1),
  I2 => \u_i2c_master/bit_controller/cnt\(2));
\u_i2c_master/bit_controller/n44_s1\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => u_i2c_master_bit_controller_n44_4,
  I0 => \u_i2c_master/bit_controller/cnt\(0),
  I1 => \u_i2c_master/bit_controller/cnt\(1));
\u_i2c_master/bit_controller/n123_s1\: LUT4
generic map (
  INIT => X"0700"
)
port map (
  F => u_i2c_master_bit_controller_n123_4,
  I0 => u_i2c_master_bit_controller_n123_5,
  I1 => u_i2c_master_bit_controller_n214_9,
  I2 => u_i2c_master_bit_controller_cmd_stop,
  I3 => u_i2c_master_bit_controller_sto_condition);
\u_i2c_master/byte_controller/ACK_OUT_s4\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_byte_controller_ACK_OUT_6,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(3),
  I2 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/bit_controller/n231_s3\: LUT4
generic map (
  INIT => X"0010"
)
port map (
  F => u_i2c_master_bit_controller_n231,
  I0 => \u_i2c_master/bit_controller/c_state\(13),
  I1 => \u_i2c_master/bit_controller/c_state\(16),
  I2 => u_i2c_master_bit_controller_n214_9,
  I3 => u_i2c_master_bit_controller_n214_8);
\u_i2c_master/bit_controller/n228_s3\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_bit_controller_n228_8,
  I0 => \u_i2c_master/byte_controller/core_cmd\(1),
  I1 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/bit_controller/n228_s4\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n228_9,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_n214_9,
  I2 => u_i2c_master_bit_controller_n123_5);
\u_i2c_master/bit_controller/n227_s3\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n227_8,
  I0 => \u_i2c_master/bit_controller/c_state\(10),
  I1 => \u_i2c_master/bit_controller/c_state\(11),
  I2 => \u_i2c_master/bit_controller/c_state\(12),
  I3 => u_i2c_master_bit_controller_n123_5);
\u_i2c_master/bit_controller/n227_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_i2c_master_bit_controller_n227_9,
  I0 => u_i2c_master_bit_controller_n227_10,
  I1 => \u_i2c_master/bit_controller/c_state\(0),
  I2 => u_i2c_master_bit_controller_n227_11,
  I3 => u_i2c_master_bit_controller_n227_12);
\u_i2c_master/bit_controller/n225_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n225_8,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(4),
  I2 => u_i2c_master_bit_controller_n225_9,
  I3 => u_i2c_master_bit_controller_n225_10);
\u_i2c_master/bit_controller/n222_s3\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n222_8,
  I0 => \u_i2c_master/bit_controller/c_state\(6),
  I1 => \u_i2c_master/bit_controller/c_state\(7),
  I2 => \u_i2c_master/bit_controller/c_state\(5));
\u_i2c_master/bit_controller/n222_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_i2c_master_bit_controller_n222_9,
  I0 => u_i2c_master_bit_controller_n123_5,
  I1 => u_i2c_master_bit_controller_n222_10,
  I2 => u_i2c_master_bit_controller_n222_11,
  I3 => u_i2c_master_bit_controller_n227_12);
\u_i2c_master/bit_controller/n221_s3\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n221_8,
  I0 => \u_i2c_master/bit_controller/c_state\(5),
  I1 => \u_i2c_master/bit_controller/c_state\(7),
  I2 => \u_i2c_master/bit_controller/c_state\(6));
\u_i2c_master/bit_controller/n220_s3\: LUT4
generic map (
  INIT => X"6000"
)
port map (
  F => u_i2c_master_bit_controller_n220_8,
  I0 => \u_i2c_master/bit_controller/c_state\(6),
  I1 => \u_i2c_master/bit_controller/c_state\(7),
  I2 => u_i2c_master_bit_controller_n227_11,
  I3 => u_i2c_master_bit_controller_n222_9);
\u_i2c_master/bit_controller/n219_s3\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => u_i2c_master_bit_controller_n219_8,
  I0 => \u_i2c_master/byte_controller/core_cmd\(1),
  I1 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/bit_controller/n218_s3\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_bit_controller_n218_8,
  I0 => u_i2c_master_bit_controller_n218_9,
  I1 => u_i2c_master_bit_controller_n227_11,
  I2 => u_i2c_master_bit_controller_n218_10);
\u_i2c_master/bit_controller/n217_s3\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n217_8,
  I0 => \u_i2c_master/bit_controller/c_state\(8),
  I1 => \u_i2c_master/bit_controller/c_state\(9),
  I2 => \u_i2c_master/bit_controller/c_state\(10));
\u_i2c_master/bit_controller/n217_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_i2c_master_bit_controller_n217_9,
  I0 => u_i2c_master_bit_controller_n227_11,
  I1 => u_i2c_master_bit_controller_n218_10,
  I2 => u_i2c_master_bit_controller_n123_5,
  I3 => u_i2c_master_bit_controller_n222_10);
\u_i2c_master/bit_controller/n214_s3\: LUT4
generic map (
  INIT => X"FEE9"
)
port map (
  F => u_i2c_master_bit_controller_n214_8,
  I0 => \u_i2c_master/bit_controller/c_state\(13),
  I1 => \u_i2c_master/bit_controller/c_state\(14),
  I2 => \u_i2c_master/bit_controller/c_state\(15),
  I3 => \u_i2c_master/bit_controller/c_state\(16));
\u_i2c_master/bit_controller/n214_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_i2c_master_bit_controller_n214_9,
  I0 => u_i2c_master_bit_controller_n214_10,
  I1 => u_i2c_master_bit_controller_n227_11,
  I2 => u_i2c_master_bit_controller_n214_11,
  I3 => u_i2c_master_bit_controller_n218_10);
\u_i2c_master/bit_controller/n213_s3\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n213_8,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => \u_i2c_master/bit_controller/c_state\(13),
  I2 => \u_i2c_master/bit_controller/c_state\(16),
  I3 => u_i2c_master_bit_controller_n214_9);
\u_i2c_master/reg_data_out_0_s2\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_reg_data_out_0,
  I0 => I_RADDR(2),
  I1 => I_RESETN);
\u_i2c_master/reg_data_out_0_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_reg_data_out_0_8,
  I0 => I_RADDR(1),
  I1 => I_RADDR(0),
  I2 => I_RESETN,
  I3 => I_RADDR(2));
\u_i2c_master/bit_controller/n250_s2\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_bit_controller_n250_7,
  I0 => u_i2c_master_bit_controller_n250_9,
  I1 => u_i2c_master_bit_controller_n227_11,
  I2 => u_i2c_master_bit_controller_n214_11,
  I3 => u_i2c_master_bit_controller_n218_10);
\u_i2c_master/bit_controller/n250_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n250_8,
  I0 => \u_i2c_master/bit_controller/c_state\(5),
  I1 => \u_i2c_master/bit_controller/c_state\(8),
  I2 => u_i2c_master_bit_controller_n250_10,
  I3 => u_i2c_master_bit_controller_n227_8);
\u_i2c_master/byte_controller/n210_s3\: LUT4
generic map (
  INIT => X"4200"
)
port map (
  F => u_i2c_master_byte_controller_n210_8,
  I0 => \u_i2c_master/byte_controller/c_state\(2),
  I1 => \u_i2c_master/byte_controller/c_state\(1),
  I2 => u_i2c_master_byte_controller_n204_8,
  I3 => u_i2c_master_byte_controller_n210_11);
\u_i2c_master/byte_controller/n210_s4\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => u_i2c_master_byte_controller_n210_9,
  I0 => \u_i2c_master/byte_controller/c_state\(3),
  I1 => \u_i2c_master/byte_controller/c_state\(1),
  I2 => u_i2c_master_byte_controller_n210_12);
\u_i2c_master/byte_controller/n210_s5\: LUT3
generic map (
  INIT => X"E0"
)
port map (
  F => u_i2c_master_byte_controller_n210_10,
  I0 => u_i2c_master_byte_controller_n205_8,
  I1 => u_i2c_master_byte_controller_n210_13,
  I2 => \u_i2c_master/command_reg\(5));
\u_i2c_master/byte_controller/n209_s3\: LUT4
generic map (
  INIT => X"1800"
)
port map (
  F => u_i2c_master_byte_controller_n209_8,
  I0 => \u_i2c_master/byte_controller/c_state\(2),
  I1 => u_i2c_master_byte_controller_n204_8,
  I2 => \u_i2c_master/byte_controller/c_state\(1),
  I3 => u_i2c_master_byte_controller_n210_11);
\u_i2c_master/byte_controller/n209_s4\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_byte_controller_n209_9,
  I0 => \u_i2c_master/byte_controller/c_state\(1),
  I1 => \u_i2c_master/byte_controller/core_cmd\(0),
  I2 => \u_i2c_master/byte_controller/c_state\(2),
  I3 => u_i2c_master_byte_controller_CORE_CMD_0_8);
\u_i2c_master/byte_controller/n209_s5\: LUT3
generic map (
  INIT => X"0E"
)
port map (
  F => u_i2c_master_byte_controller_n209_10,
  I0 => u_i2c_master_byte_controller_n209_11,
  I1 => u_i2c_master_byte_controller_n205_8,
  I2 => \u_i2c_master/command_reg\(5));
\u_i2c_master/byte_controller/n208_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_byte_controller_n208_8,
  I0 => \u_i2c_master/byte_controller/core_cmd\(0),
  I1 => u_i2c_master_byte_controller_n208_9,
  I2 => u_i2c_master_byte_controller_n204_8,
  I3 => u_i2c_master_byte_controller_CORE_CMD_0_8);
\u_i2c_master/byte_controller/n207_s3\: LUT4
generic map (
  INIT => X"FD03"
)
port map (
  F => u_i2c_master_byte_controller_n207_8,
  I0 => u_i2c_master_byte_controller_n207_10,
  I1 => \u_i2c_master/byte_controller/c_state\(4),
  I2 => \u_i2c_master/byte_controller/c_state\(3),
  I3 => u_i2c_master_byte_controller_n207_11);
\u_i2c_master/byte_controller/n207_s4\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_byte_controller_n207_9,
  I0 => \u_i2c_master/byte_controller/c_state\(2),
  I1 => \u_i2c_master/byte_controller/c_state\(1),
  I2 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/byte_controller/n206_s3\: LUT3
generic map (
  INIT => X"E3"
)
port map (
  F => u_i2c_master_byte_controller_n206_8,
  I0 => \u_i2c_master/command_reg\(6),
  I1 => \u_i2c_master/byte_controller/c_state\(4),
  I2 => \u_i2c_master/byte_controller/c_state\(3));
\u_i2c_master/byte_controller/n205_s3\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => u_i2c_master_byte_controller_n205_8,
  I0 => u_i2c_master_bit_controller_core_ack,
  I1 => \u_i2c_master/byte_controller/core_cmd\(0),
  I2 => u_i2c_master_byte_controller_n205_9);
\u_i2c_master/byte_controller/n204_s3\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_byte_controller_n204_8,
  I0 => \u_i2c_master/byte_controller/dcnt\(0),
  I1 => \u_i2c_master/byte_controller/dcnt\(1),
  I2 => \u_i2c_master/byte_controller/dcnt\(2));
\u_i2c_master/byte_controller/n204_s4\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_byte_controller_n204_9,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_core_ack);
\u_i2c_master/byte_controller/n203_s3\: LUT4
generic map (
  INIT => X"F400"
)
port map (
  F => u_i2c_master_byte_controller_n203_8,
  I0 => u_i2c_master_bit_controller_core_ack,
  I1 => u_i2c_master_byte_controller_n210_12,
  I2 => u_i2c_master_byte_controller_n203_10,
  I3 => \u_i2c_master/byte_controller/receive_reg\(7));
\u_i2c_master/byte_controller/n203_s4\: LUT4
generic map (
  INIT => X"133F"
)
port map (
  F => u_i2c_master_byte_controller_n203_9,
  I0 => u_i2c_master_byte_controller_n210_9,
  I1 => u_i2c_master_byte_controller_ACK_OUT_6,
  I2 => u_i2c_master_bit_controller_core_ack,
  I3 => \u_i2c_master/command_reg\(3));
\u_i2c_master/byte_controller/n201_s3\: LUT4
generic map (
  INIT => X"00D4"
)
port map (
  F => u_i2c_master_byte_controller_n201_8,
  I0 => \u_i2c_master/byte_controller/c_state\(3),
  I1 => u_i2c_master_byte_controller_n210_12,
  I2 => u_i2c_master_byte_controller_n203_10,
  I3 => u_i2c_master_byte_controller_n201_10);
\u_i2c_master/byte_controller/n201_s4\: LUT3
generic map (
  INIT => X"53"
)
port map (
  F => u_i2c_master_byte_controller_n201_9,
  I0 => u_i2c_master_byte_controller_n207_10,
  I1 => \u_i2c_master/byte_controller/core_cmd\(1),
  I2 => u_i2c_master_byte_controller_CORE_CMD_0_10);
\u_i2c_master/byte_controller/n200_s3\: LUT4
generic map (
  INIT => X"C073"
)
port map (
  F => u_i2c_master_byte_controller_n200_8,
  I0 => u_i2c_master_byte_controller_CORE_CMD_0_10,
  I1 => u_i2c_master_byte_controller_n200_10,
  I2 => u_i2c_master_byte_controller_n205_9,
  I3 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/byte_controller/n200_s4\: LUT4
generic map (
  INIT => X"00F1"
)
port map (
  F => u_i2c_master_byte_controller_n200_9,
  I0 => u_i2c_master_byte_controller_n205_8,
  I1 => u_i2c_master_byte_controller_n209_11,
  I2 => \u_i2c_master/command_reg\(5),
  I3 => u_i2c_master_byte_controller_n210_8);
\u_i2c_master/byte_controller/n199_s3\: LUT4
generic map (
  INIT => X"001F"
)
port map (
  F => u_i2c_master_byte_controller_n199_8,
  I0 => u_i2c_master_byte_controller_n210_13,
  I1 => u_i2c_master_byte_controller_n205_8,
  I2 => \u_i2c_master/command_reg\(5),
  I3 => u_i2c_master_byte_controller_n209_8);
\u_i2c_master/bit_controller/n230_s3\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n230_8,
  I0 => \u_i2c_master/bit_controller/c_state\(10),
  I1 => \u_i2c_master/bit_controller/c_state\(11),
  I2 => u_i2c_master_bit_controller_n123_5,
  I3 => u_i2c_master_bit_controller_n218_8);
\u_i2c_master/bit_controller/n230_s4\: LUT4
generic map (
  INIT => X"7077"
)
port map (
  F => u_i2c_master_bit_controller_n230_9,
  I0 => u_i2c_master_bit_controller_n227_9,
  I1 => u_i2c_master_bit_controller_n227_8,
  I2 => u_i2c_master_bit_controller_n230_12,
  I3 => u_i2c_master_bit_controller_n214_9);
\u_i2c_master/bit_controller/n230_s5\: LUT3
generic map (
  INIT => X"07"
)
port map (
  F => u_i2c_master_bit_controller_n230_10,
  I0 => u_i2c_master_bit_controller_n217_9,
  I1 => u_i2c_master_bit_controller_n217_8,
  I2 => u_i2c_master_bit_controller_i2c_al);
\u_i2c_master/bit_controller/n203_s11\: LUT4
generic map (
  INIT => X"0DDD"
)
port map (
  F => u_i2c_master_bit_controller_n203_20,
  I0 => u_i2c_master_bit_controller_n226,
  I1 => u_i2c_master_bit_controller_n230_11,
  I2 => u_i2c_master_bit_controller_n203_21,
  I3 => u_i2c_master_bit_controller_n225_10);
\u_i2c_master/bit_controller/n13_s3\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n13_6,
  I0 => \u_i2c_master/bit_controller/cnt\(9),
  I1 => \u_i2c_master/bit_controller/cnt\(10),
  I2 => \u_i2c_master/bit_controller/cnt\(11),
  I3 => \u_i2c_master/bit_controller/cnt\(12));
\u_i2c_master/bit_controller/n13_s4\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n13_7,
  I0 => \u_i2c_master/bit_controller/cnt\(5),
  I1 => \u_i2c_master/bit_controller/cnt\(6),
  I2 => \u_i2c_master/bit_controller/cnt\(7),
  I3 => \u_i2c_master/bit_controller/cnt\(8));
\u_i2c_master/bit_controller/n123_s2\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n123_5,
  I0 => \u_i2c_master/bit_controller/c_state\(13),
  I1 => \u_i2c_master/bit_controller/c_state\(14),
  I2 => \u_i2c_master/bit_controller/c_state\(15),
  I3 => \u_i2c_master/bit_controller/c_state\(16));
\u_i2c_master/byte_controller/CORE_CMD_0_s6\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => u_i2c_master_byte_controller_CORE_CMD_0_8,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(3));
\u_i2c_master/bit_controller/n227_s5\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_bit_controller_n227_10,
  I0 => \u_i2c_master/bit_controller/c_state\(1),
  I1 => \u_i2c_master/bit_controller/c_state\(6),
  I2 => \u_i2c_master/bit_controller/c_state\(7));
\u_i2c_master/bit_controller/n227_s6\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n227_11,
  I0 => \u_i2c_master/bit_controller/c_state\(2),
  I1 => \u_i2c_master/bit_controller/c_state\(3),
  I2 => \u_i2c_master/bit_controller/c_state\(4),
  I3 => \u_i2c_master/bit_controller/c_state\(5));
\u_i2c_master/bit_controller/n227_s7\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_bit_controller_n227_12,
  I0 => \u_i2c_master/bit_controller/c_state\(8),
  I1 => \u_i2c_master/bit_controller/c_state\(9),
  I2 => \u_i2c_master/bit_controller/c_state\(10));
\u_i2c_master/bit_controller/n226_s4\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => u_i2c_master_bit_controller_n226,
  I0 => u_i2c_master_bit_controller_n226_10,
  I1 => u_i2c_master_bit_controller_n227_11,
  I2 => u_i2c_master_bit_controller_n123_5,
  I3 => u_i2c_master_bit_controller_n227_12);
\u_i2c_master/bit_controller/n225_s4\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_bit_controller_n225_9,
  I0 => \u_i2c_master/bit_controller/c_state\(5),
  I1 => \u_i2c_master/bit_controller/c_state\(8),
  I2 => u_i2c_master_bit_controller_n218_10);
\u_i2c_master/bit_controller/n225_s5\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n225_10,
  I0 => \u_i2c_master/bit_controller/c_state\(9),
  I1 => \u_i2c_master/bit_controller/c_state\(10),
  I2 => u_i2c_master_bit_controller_n123_5,
  I3 => u_i2c_master_bit_controller_n222_10);
\u_i2c_master/bit_controller/n222_s5\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => u_i2c_master_bit_controller_n222_10,
  I0 => \u_i2c_master/bit_controller/c_state\(11),
  I1 => \u_i2c_master/bit_controller/c_state\(12));
\u_i2c_master/bit_controller/n222_s6\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n222_11,
  I0 => \u_i2c_master/bit_controller/c_state\(0),
  I1 => \u_i2c_master/bit_controller/c_state\(1),
  I2 => \u_i2c_master/bit_controller/c_state\(2),
  I3 => \u_i2c_master/bit_controller/c_state\(3));
\u_i2c_master/bit_controller/n218_s4\: LUT3
generic map (
  INIT => X"E9"
)
port map (
  F => u_i2c_master_bit_controller_n218_9,
  I0 => \u_i2c_master/bit_controller/c_state\(8),
  I1 => \u_i2c_master/bit_controller/c_state\(9),
  I2 => \u_i2c_master/bit_controller/c_state\(12));
\u_i2c_master/bit_controller/n218_s5\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n218_10,
  I0 => \u_i2c_master/bit_controller/c_state\(0),
  I1 => \u_i2c_master/bit_controller/c_state\(1),
  I2 => \u_i2c_master/bit_controller/c_state\(6),
  I3 => \u_i2c_master/bit_controller/c_state\(7));
\u_i2c_master/bit_controller/n214_s5\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => u_i2c_master_bit_controller_n214_10,
  I0 => \u_i2c_master/bit_controller/c_state\(8),
  I1 => \u_i2c_master/bit_controller/c_state\(12));
\u_i2c_master/bit_controller/n214_s6\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_bit_controller_n214_11,
  I0 => \u_i2c_master/bit_controller/c_state\(9),
  I1 => \u_i2c_master/bit_controller/c_state\(10),
  I2 => \u_i2c_master/bit_controller/c_state\(11));
\u_i2c_master/bit_controller/n250_s4\: LUT4
generic map (
  INIT => X"F335"
)
port map (
  F => u_i2c_master_bit_controller_n250_9,
  I0 => u_i2c_master_bit_controller_n250_11,
  I1 => u_i2c_master_bit_controller_n123_5,
  I2 => \u_i2c_master/bit_controller/c_state\(8),
  I3 => \u_i2c_master/bit_controller/c_state\(12));
\u_i2c_master/bit_controller/n250_s5\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => u_i2c_master_bit_controller_n250_10,
  I0 => u_i2c_master_bit_controller_n218_10,
  I1 => u_i2c_master_bit_controller_n250_12);
\u_i2c_master/byte_controller/n210_s6\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_byte_controller_n210_11,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(3),
  I2 => \u_i2c_master/byte_controller/core_cmd\(0),
  I3 => u_i2c_master_bit_controller_core_ack);
\u_i2c_master/byte_controller/n210_s7\: LUT3
generic map (
  INIT => X"01"
)
port map (
  F => u_i2c_master_byte_controller_n210_12,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(2),
  I2 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/byte_controller/n210_s8\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_byte_controller_n210_13,
  I0 => u_i2c_master_byte_controller_done,
  I1 => \u_i2c_master/command_reg\(7),
  I2 => u_i2c_master_byte_controller_CORE_CMD_0_8,
  I3 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/byte_controller/n209_s6\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => u_i2c_master_byte_controller_n209_11,
  I0 => u_i2c_master_byte_controller_done,
  I1 => u_i2c_master_byte_controller_n209_12,
  I2 => u_i2c_master_byte_controller_CORE_CMD_0_8,
  I3 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/byte_controller/n208_s4\: LUT4
generic map (
  INIT => X"FEE9"
)
port map (
  F => u_i2c_master_byte_controller_n208_9,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(2),
  I2 => \u_i2c_master/byte_controller/c_state\(1),
  I3 => \u_i2c_master/byte_controller/c_state\(3));
\u_i2c_master/byte_controller/n207_s5\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_byte_controller_n207_10,
  I0 => u_i2c_master_byte_controller_done,
  I1 => \u_i2c_master/command_reg\(5),
  I2 => \u_i2c_master/command_reg\(4),
  I3 => \u_i2c_master/command_reg\(7));
\u_i2c_master/byte_controller/n207_s6\: LUT4
generic map (
  INIT => X"F7AC"
)
port map (
  F => u_i2c_master_byte_controller_n207_11,
  I0 => u_i2c_master_bit_controller_core_ack,
  I1 => \u_i2c_master/command_reg\(6),
  I2 => \u_i2c_master/byte_controller/c_state\(4),
  I3 => \u_i2c_master/byte_controller/c_state\(3));
\u_i2c_master/byte_controller/n205_s4\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_byte_controller_n205_9,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(2),
  I2 => \u_i2c_master/byte_controller/c_state\(1),
  I3 => \u_i2c_master/byte_controller/c_state\(3));
\u_i2c_master/byte_controller/n203_s5\: LUT4
generic map (
  INIT => X"0017"
)
port map (
  F => u_i2c_master_byte_controller_n203_10,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(2),
  I2 => \u_i2c_master/byte_controller/core_cmd\(0),
  I3 => \u_i2c_master/byte_controller/c_state\(1));
\u_i2c_master/byte_controller/n201_s5\: LUT4
generic map (
  INIT => X"770F"
)
port map (
  F => u_i2c_master_byte_controller_n201_10,
  I0 => \u_i2c_master/command_reg\(6),
  I1 => \u_i2c_master/byte_controller/c_state\(3),
  I2 => \u_i2c_master/byte_controller/core_cmd\(1),
  I3 => u_i2c_master_bit_controller_core_ack);
\u_i2c_master/byte_controller/n200_s5\: LUT3
generic map (
  INIT => X"3E"
)
port map (
  F => u_i2c_master_byte_controller_n200_10,
  I0 => u_i2c_master_byte_controller_n208_9,
  I1 => u_i2c_master_bit_controller_core_ack,
  I2 => \u_i2c_master/byte_controller/core_cmd\(0));
\u_i2c_master/bit_controller/n230_s6\: LUT2
generic map (
  INIT => X"9"
)
port map (
  F => u_i2c_master_bit_controller_n230_11,
  I0 => \u_i2c_master/bit_controller/c_state\(1),
  I1 => \u_i2c_master/bit_controller/c_state\(11));
\u_i2c_master/bit_controller/n230_s7\: LUT4
generic map (
  INIT => X"0BBB"
)
port map (
  F => u_i2c_master_bit_controller_n230_12,
  I0 => u_i2c_master_bit_controller_n214_8,
  I1 => u_i2c_master_byte_controller_core_txd,
  I2 => u_i2c_master_bit_controller_sda_padoen_o,
  I3 => u_i2c_master_bit_controller_n123_5);
\u_i2c_master/bit_controller/n203_s12\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n203_21,
  I0 => \u_i2c_master/bit_controller/c_state\(4),
  I1 => \u_i2c_master/bit_controller/c_state\(5),
  I2 => u_i2c_master_bit_controller_n203_22,
  I3 => u_i2c_master_bit_controller_n218_10);
\u_i2c_master/bit_controller/n226_s5\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => u_i2c_master_bit_controller_n226_10,
  I0 => \u_i2c_master/bit_controller/c_state\(0),
  I1 => \u_i2c_master/bit_controller/c_state\(6),
  I2 => \u_i2c_master/bit_controller/c_state\(7),
  I3 => \u_i2c_master/bit_controller/c_state\(12));
\u_i2c_master/bit_controller/n250_s6\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n250_11,
  I0 => \u_i2c_master/bit_controller/c_state\(13),
  I1 => \u_i2c_master/bit_controller/c_state\(14),
  I2 => \u_i2c_master/bit_controller/c_state\(15),
  I3 => \u_i2c_master/bit_controller/c_state\(16));
\u_i2c_master/bit_controller/n250_s7\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => u_i2c_master_bit_controller_n250_12,
  I0 => \u_i2c_master/bit_controller/c_state\(2),
  I1 => \u_i2c_master/bit_controller/c_state\(3),
  I2 => \u_i2c_master/bit_controller/c_state\(9),
  I3 => \u_i2c_master/bit_controller/c_state\(4));
\u_i2c_master/byte_controller/n209_s7\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => u_i2c_master_byte_controller_n209_12,
  I0 => \u_i2c_master/command_reg\(7),
  I1 => \u_i2c_master/command_reg\(4));
\u_i2c_master/bit_controller/n203_s13\: LUT3
generic map (
  INIT => X"E9"
)
port map (
  F => u_i2c_master_bit_controller_n203_22,
  I0 => \u_i2c_master/bit_controller/c_state\(2),
  I1 => \u_i2c_master/bit_controller/c_state\(3),
  I2 => \u_i2c_master/bit_controller/c_state\(8));
\u_i2c_master/bit_controller/n216_s3\: LUT4
generic map (
  INIT => X"0400"
)
port map (
  F => u_i2c_master_bit_controller_n216,
  I0 => \u_i2c_master/bit_controller/c_state\(1),
  I1 => \u_i2c_master/bit_controller/c_state\(11),
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_n226);
\u_i2c_master/bit_controller/n226_s6\: LUT4
generic map (
  INIT => X"0400"
)
port map (
  F => u_i2c_master_bit_controller_n226_12,
  I0 => \u_i2c_master/bit_controller/c_state\(11),
  I1 => \u_i2c_master/bit_controller/c_state\(1),
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_n226);
\u_i2c_master/bit_controller/n230_s8\: LUT3
generic map (
  INIT => X"28"
)
port map (
  F => u_i2c_master_bit_controller_n230_14,
  I0 => u_i2c_master_bit_controller_n226,
  I1 => \u_i2c_master/bit_controller/c_state\(1),
  I2 => \u_i2c_master/bit_controller/c_state\(11));
\u_i2c_master/byte_controller/CORE_CMD_0_s7\: LUT4
generic map (
  INIT => X"00FE"
)
port map (
  F => u_i2c_master_byte_controller_CORE_CMD_0_10,
  I0 => \u_i2c_master/command_reg\(5),
  I1 => \u_i2c_master/command_reg\(4),
  I2 => \u_i2c_master/command_reg\(6),
  I3 => u_i2c_master_byte_controller_done);
\u_i2c_master/bit_controller/n36_s2\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => u_i2c_master_bit_controller_n36_6,
  I0 => \u_i2c_master/bit_controller/cnt\(9),
  I1 => \u_i2c_master/bit_controller/cnt\(4),
  I2 => u_i2c_master_bit_controller_n13_7,
  I3 => u_i2c_master_bit_controller_n42_4);
\u_i2c_master/bit_controller/n223_s3\: LUT4
generic map (
  INIT => X"2000"
)
port map (
  F => u_i2c_master_bit_controller_n223,
  I0 => u_i2c_master_bit_controller_n110,
  I1 => u_i2c_master_bit_controller_i2c_al,
  I2 => u_i2c_master_bit_controller_n214_9,
  I3 => u_i2c_master_bit_controller_n123_5);
\u_i2c_master/byte_controller/CORE_CMD_0_s8\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => u_i2c_master_byte_controller_CORE_CMD_0_12,
  I0 => \u_i2c_master/byte_controller/c_state\(4),
  I1 => \u_i2c_master/byte_controller/c_state\(3),
  I2 => u_i2c_master_byte_controller_n207_9);
\u_i2c_master/reg_data_out_4_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_i2c_master/reg_data_out\(4),
  I0 => u_i2c_master_n172_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_i2c_master/reg_data_out_3_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_i2c_master/reg_data_out\(3),
  I0 => u_i2c_master_n173_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_i2c_master/reg_data_out_2_s2\: LUT3
generic map (
  INIT => X"20"
)
port map (
  F => \u_i2c_master/reg_data_out\(2),
  I0 => u_i2c_master_n174_17,
  I1 => I_RADDR(2),
  I2 => I_RESETN);
\u_i2c_master/bit_controller/SCL_OEN_s5\: LUT4
generic map (
  INIT => X"1110"
)
port map (
  F => u_i2c_master_bit_controller_SCL_OEN,
  I0 => u_i2c_master_bit_controller_n228_9,
  I1 => u_i2c_master_bit_controller_n227,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_clk_en);
\u_i2c_master/irq_flag_s4\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => u_i2c_master_irq_flag,
  D => u_i2c_master_n220,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/dcnt_1_s3\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/dcnt\(1),
  D => u_i2c_master_byte_controller_n51,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/byte_controller/dcnt_0_s3\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => \u_i2c_master/byte_controller/dcnt\(0),
  D => u_i2c_master_byte_controller_n52,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/BUSY_s4\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => u_i2c_master_bit_controller_i2c_busy,
  D => u_i2c_master_bit_controller_n102,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/bit_controller/sda_chk_s3\: DFFC
generic map (
  INIT => '0'
)
port map (
  Q => u_i2c_master_bit_controller_sda_chk,
  D => u_i2c_master_bit_controller_n231_11,
  CLK => I_CLK,
  CLEAR => u_i2c_master_n16);
\u_i2c_master/n220_s5\: LUT4
generic map (
  INIT => X"00FE"
)
port map (
  F => u_i2c_master_n220,
  I0 => u_i2c_master_irq_flag,
  I1 => u_i2c_master_byte_controller_done,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => \u_i2c_master/command_reg\(0));
\u_i2c_master/byte_controller/n51_s3\: LUT4
generic map (
  INIT => X"FBF4"
)
port map (
  F => u_i2c_master_byte_controller_n51,
  I0 => \u_i2c_master/byte_controller/dcnt\(0),
  I1 => u_i2c_master_byte_controller_shift,
  I2 => u_i2c_master_byte_controller_ld,
  I3 => \u_i2c_master/byte_controller/dcnt\(1));
\u_i2c_master/byte_controller/sr_6_s4\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_i2c_master_byte_controller_sr_6,
  I0 => u_i2c_master_byte_controller_ld,
  I1 => u_i2c_master_byte_controller_shift);
\u_i2c_master/byte_controller/n52_s3\: LUT3
generic map (
  INIT => X"BE"
)
port map (
  F => u_i2c_master_byte_controller_n52,
  I0 => u_i2c_master_byte_controller_ld,
  I1 => \u_i2c_master/byte_controller/dcnt\(0),
  I2 => u_i2c_master_byte_controller_shift);
\u_i2c_master/bit_controller/n102_s5\: LUT3
generic map (
  INIT => X"0E"
)
port map (
  F => u_i2c_master_bit_controller_n102,
  I0 => u_i2c_master_bit_controller_sta_condition,
  I1 => u_i2c_master_bit_controller_i2c_busy,
  I2 => u_i2c_master_bit_controller_sto_condition);
\u_i2c_master/bit_controller/n231_s5\: LUT4
generic map (
  INIT => X"0A0C"
)
port map (
  F => u_i2c_master_bit_controller_n231_11,
  I0 => u_i2c_master_bit_controller_n231,
  I1 => u_i2c_master_bit_controller_sda_chk,
  I2 => u_i2c_master_bit_controller_i2c_al,
  I3 => u_i2c_master_bit_controller_clk_en);
\u_i2c_master/bit_controller/c_state_16_s4\: LUT2
generic map (
  INIT => X"E"
)
port map (
  F => u_i2c_master_bit_controller_c_state_16,
  I0 => u_i2c_master_bit_controller_i2c_al,
  I1 => u_i2c_master_bit_controller_clk_en);
\u_i2c_master/n16_s2\: INV
port map (
  O => u_i2c_master_n16,
  I => I_RESETN);
GND_s2: GND
port map (
  G => GND_0);
VCC_s1: VCC
port map (
  V => VCC_0);
GSR_0: GSR
port map (
  GSRI => VCC_0);
end beh;
