--Copyright (C)2014-2025 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.12 (64-bit)
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9
--Device Version: C
--Created Time: Sun Dec 28 11:45:49 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component SPI_MASTER_Top
	port (
		I_CLK: in std_logic;
		I_RESETN: in std_logic;
		I_TX_EN: in std_logic;
		I_WADDR: in std_logic_vector(2 downto 0);
		I_WDATA: in std_logic_vector(7 downto 0);
		I_RX_EN: in std_logic;
		I_RADDR: in std_logic_vector(2 downto 0);
		O_RDATA: out std_logic_vector(7 downto 0);
		O_SPI_INT: out std_logic;
		MISO_MASTER: in std_logic;
		MOSI_MASTER: out std_logic;
		SS_N_MASTER: out std_logic_vector(3 downto 0);
		SCLK_MASTER: out std_logic;
		MISO_SLAVE: out std_logic;
		MOSI_SLAVE: in std_logic;
		SS_N_SLAVE: in std_logic;
		SCLK_SLAVE: in std_logic
	);
end component;

your_instance_name: SPI_MASTER_Top
	port map (
		I_CLK => I_CLK,
		I_RESETN => I_RESETN,
		I_TX_EN => I_TX_EN,
		I_WADDR => I_WADDR,
		I_WDATA => I_WDATA,
		I_RX_EN => I_RX_EN,
		I_RADDR => I_RADDR,
		O_RDATA => O_RDATA,
		O_SPI_INT => O_SPI_INT,
		MISO_MASTER => MISO_MASTER,
		MOSI_MASTER => MOSI_MASTER,
		SS_N_MASTER => SS_N_MASTER,
		SCLK_MASTER => SCLK_MASTER,
		MISO_SLAVE => MISO_SLAVE,
		MOSI_SLAVE => MOSI_SLAVE,
		SS_N_SLAVE => SS_N_SLAVE,
		SCLK_SLAVE => SCLK_SLAVE
	);

----------Copy end-------------------
