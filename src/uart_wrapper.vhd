-- ============================================
-- UART Wrapper para fpga-6502
-- Mapeo de memoria: $C020-$C023
-- ============================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_wrapper is
    port (
        clk         : in  std_logic;         -- 6.75 MHz
        rst_n       : in  std_logic;
        
        -- Interface CPU 6502
        cpu_addr    : in  std_logic_vector(15 downto 0);
        cpu_data_in : in  std_logic_vector(7 downto 0);
        cpu_data_out: out std_logic_vector(7 downto 0);
        cpu_rw      : in  std_logic;         -- 1=Read, 0=Write
        
        -- Señales UART externas
        uart_tx     : out std_logic;
        uart_rx     : in  std_logic;
        
        -- Interrupción
        uart_irq    : out std_logic
    );
end entity;

architecture rtl of uart_wrapper is

    signal uart_cs      : std_logic;
    signal uart_rd      : std_logic;
    signal uart_wr      : std_logic;
    signal uart_addr    : std_logic_vector(1 downto 0);
    signal uart_dout    : std_logic_vector(7 downto 0);

begin

    -- Chip Select: $C020-$C023
    -- cpu_addr[15:2] = 1100 0000 0010 00xx
    uart_cs <= '1' when cpu_addr(15 downto 2) = "11000000001000" else '0';
    
    uart_addr <= cpu_addr(1 downto 0);
    uart_rd <= cpu_rw;
    uart_wr <= not cpu_rw;
    
    -- Instancia UART
    uart_inst : entity work.uart
        generic map (
            CLK_FREQ  => 6_750_000,
            BAUD_RATE => 115200
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            cs        => uart_cs,
            addr      => uart_addr,
            rd        => uart_rd,
            wr        => uart_wr,
            data_in   => cpu_data_in,
            data_out  => uart_dout,
            uart_tx   => uart_tx,
            uart_rx   => uart_rx,
            uart_irq  => uart_irq
        );
    
    -- Bus de datos
    cpu_data_out <= uart_dout when (uart_cs = '1' and cpu_rw = '1') else (others => 'Z');

end architecture;
