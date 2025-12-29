library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_gowin_wrapper is
    port (
        clk_6m75    : in  std_logic;
        rst_n       : in  std_logic;
        cpu_addr    : in  std_logic_vector(15 downto 0);
        cpu_data    : inout std_logic_vector(7 downto 0);
        cpu_rw      : in  std_logic;
        i2c_scl     : inout std_logic;
        i2c_sda     : inout std_logic;
        i2c_irq     : out std_logic
    );
end entity;

architecture rtl of i2c_gowin_wrapper is

    component I2C_MASTER_Top
    port (
        I_CLK    : in std_logic;
        I_RESETN : in std_logic;
        I_TX_EN  : in std_logic;
        I_WADDR  : in std_logic_vector(2 downto 0);
        I_WDATA  : in std_logic_vector(7 downto 0);
        I_RX_EN  : in std_logic;
        I_RADDR  : in std_logic_vector(2 downto 0);
        O_RDATA  : out std_logic_vector(7 downto 0);
        O_IIC_INT: out std_logic;
        SCL      : inout std_logic;
        SDA      : inout std_logic
    );
    end component;

    -- Señales para el IP core
    signal i2c_tx_en, i2c_rx_en : std_logic;
    signal i2c_waddr, i2c_raddr : std_logic_vector(2 downto 0);
    signal i2c_wdata, i2c_rdata : std_logic_vector(7 downto 0);
    signal i2c_cs : std_logic;

begin

    -- Chip Select para I2C ($C010-$C017)
    -- cpu_addr[15:0] = 1100 0000 0001 0000 a 1100 0000 0001 0111
    i2c_cs <= '1' when cpu_addr(15 downto 3) = "1100000000010" else '0';  -- $C010-$C017

    -- Mapeo de direcciones del 6502 a registros I2C
    -- $C010 → I2C_PRESCALE0 (000)
    -- $C011 → I2C_PRESCALE1 (001)  
    -- $C012 → I2C_CONTROL   (010)
    -- $C013 → I2C_TX_RX     (011)
    -- $C014 → I2C_CMD_STAT  (100)
    -- $C015-$C017 → No usados (101,110,111)
    i2c_waddr <= cpu_addr(2 downto 0);  -- Usar bits [2:0] para selección de registro
    i2c_raddr <= cpu_addr(2 downto 0);

    -- Control signals
    i2c_tx_en <= i2c_cs and not cpu_rw;  -- Write enable
    i2c_rx_en <= i2c_cs and cpu_rw;      -- Read enable
    i2c_wdata <= cpu_data;

    -- Bidirectional data bus
    cpu_data <= i2c_rdata when (i2c_cs = '1' and cpu_rw = '1') else (others => 'Z');

    -- I2C Master instance
    i2c_master_inst : I2C_MASTER_Top
        port map (
            I_CLK     => clk_6m75,
            I_RESETN  => rst_n,
            I_TX_EN   => i2c_tx_en,
            I_WADDR   => i2c_waddr,
            I_WDATA   => i2c_wdata,
            I_RX_EN   => i2c_rx_en,
            I_RADDR   => i2c_raddr,
            O_RDATA   => i2c_rdata,
            O_IIC_INT => i2c_irq,
            SCL       => i2c_scl,
            SDA       => i2c_sda
        );

end architecture;