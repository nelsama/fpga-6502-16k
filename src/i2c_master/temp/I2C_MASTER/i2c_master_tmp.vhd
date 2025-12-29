--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9
--Device Version: C
--Created Time: Fri Oct 17 17:03:42 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component I2C_MASTER_Top
	port (
		I_CLK: in std_logic;
		I_RESETN: in std_logic;
		I_TX_EN: in std_logic;
		I_WADDR: in std_logic_vector(2 downto 0);
		I_WDATA: in std_logic_vector(7 downto 0);
		I_RX_EN: in std_logic;
		I_RADDR: in std_logic_vector(2 downto 0);
		O_RDATA: out std_logic_vector(7 downto 0);
		O_IIC_INT: out std_logic;
		SCL: inout std_logic;
		SDA: inout std_logic
	);
end component;

your_instance_name: I2C_MASTER_Top
	port map (
		I_CLK => I_CLK,
		I_RESETN => I_RESETN,
		I_TX_EN => I_TX_EN,
		I_WADDR => I_WADDR,
		I_WDATA => I_WDATA,
		I_RX_EN => I_RX_EN,
		I_RADDR => I_RADDR,
		O_RDATA => O_RDATA,
		O_IIC_INT => O_IIC_INT,
		SCL => SCL,
		SDA => SDA
	);

----------Copy end-------------------
