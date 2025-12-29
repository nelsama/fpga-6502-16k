-- ============================================
-- Timer/RTC Wrapper para fpga-6502
-- Mapeo de memoria: $C030-$C03F
-- ============================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_wrapper is
    port (
        clk         : in  std_logic;         -- 6.75 MHz
        rst_n       : in  std_logic;
        
        -- Interface CPU 6502
        cpu_addr    : in  std_logic_vector(15 downto 0);
        cpu_data_in : in  std_logic_vector(7 downto 0);
        cpu_data_out: out std_logic_vector(7 downto 0);
        cpu_rw      : in  std_logic;         -- 1=Read, 0=Write
        
        -- IRQ
        timer_irq   : out std_logic
    );
end entity;

architecture rtl of timer_wrapper is

    signal timer_cs     : std_logic;
    signal timer_rd     : std_logic;
    signal timer_wr     : std_logic;
    signal timer_addr   : std_logic_vector(3 downto 0);
    signal timer_dout   : std_logic_vector(7 downto 0);

begin

    -- Chip Select: $C030-$C03F
    -- cpu_addr[15:4] = 1100 0000 0011 xxxx
    timer_cs <= '1' when cpu_addr(15 downto 4) = x"C03" else '0';
    
    timer_addr <= cpu_addr(3 downto 0);
    timer_rd <= cpu_rw;
    timer_wr <= not cpu_rw;
    
    -- Instancia Timer/RTC
    timer_inst : entity work.timer_rtc
        generic map (
            CLK_FREQ  => 6_750_000
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            cs        => timer_cs,
            addr      => timer_addr,
            rd        => timer_rd,
            wr        => timer_wr,
            data_in   => cpu_data_in,
            data_out  => timer_dout,
            timer_irq => timer_irq
        );
    
    -- Bus de datos
    cpu_data_out <= timer_dout when (timer_cs = '1' and cpu_rw = '1') else (others => 'Z');

end architecture;
