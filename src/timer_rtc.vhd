-- ============================================
-- Timer/RTC Module para fpga-6502
-- Características:
--   - Contador de microsegundos (32-bit)
--   - Timer programable con IRQ
--   - Prescaler configurable
--   - Contador de ticks del sistema
-- 
-- Mapa de registros ($C030-$C03F):
--   $C030 - TICK_0    (R)   Contador ticks byte 0 (LSB)
--   $C031 - TICK_1    (R)   Contador ticks byte 1
--   $C032 - TICK_2    (R)   Contador ticks byte 2
--   $C033 - TICK_3    (R)   Contador ticks byte 3 (MSB)
--   $C034 - TIMER_LO  (R/W) Timer countdown low byte
--   $C035 - TIMER_HI  (R/W) Timer countdown high byte
--   $C036 - TIMER_CTL (R/W) Timer control
--   $C037 - PRESCALER (R/W) Prescaler (divide clock)
--   $C038 - USEC_0    (R)   Microsegundos byte 0 (LSB)
--   $C039 - USEC_1    (R)   Microsegundos byte 1
--   $C03A - USEC_2    (R)   Microsegundos byte 2
--   $C03B - USEC_3    (R)   Microsegundos byte 3 (MSB)
--   $C03C - LATCH_CTL (W)   Latch control (capturar valores)
--   $C03D - reserved
--   $C03E - reserved
--   $C03F - reserved
--
-- TIMER_CTL bits:
--   Bit 0: TIMER_EN     - Enable timer countdown
--   Bit 1: TIMER_IRQ_EN - Enable IRQ on timer=0
--   Bit 2: TIMER_REPEAT - Auto-reload timer
--   Bit 3: TIMER_IRQ    - IRQ pending (write 1 to clear)
--   Bit 7: TIMER_ZERO   - Timer reached zero
--
-- LATCH_CTL:
--   Write $01 - Latch TICK counter
--   Write $02 - Latch USEC counter
--   Write $03 - Latch both
--   Write $80 - Reset TICK counter
--   Write $40 - Reset USEC counter
--
-- Clock: 6.75 MHz = 148.148 ns per tick
-- Para microsegundos: divide por ~7 (6.75 ticks = 1 us)
-- ============================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_rtc is
    generic (
        CLK_FREQ    : integer := 6_750_000   -- 6.75 MHz
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface CPU
        cs          : in  std_logic;
        addr        : in  std_logic_vector(3 downto 0);  -- 16 registros
        rd          : in  std_logic;
        wr          : in  std_logic;
        data_in     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        
        -- IRQ output
        timer_irq   : out std_logic
    );
end entity;

architecture rtl of timer_rtc is

    -- Constante para convertir a microsegundos
    -- 6.75 MHz = 6.75 ticks por microsegundo
    constant TICKS_PER_US : integer := 7;  -- Aproximación (error < 4%)
    
    -- ========== Contador de Ticks (32-bit) ==========
    signal tick_counter     : unsigned(31 downto 0) := (others => '0');
    signal tick_latch       : unsigned(31 downto 0) := (others => '0');
    
    -- ========== Contador de Microsegundos (32-bit) ==========
    signal usec_counter     : unsigned(31 downto 0) := (others => '0');
    signal usec_latch       : unsigned(31 downto 0) := (others => '0');
    signal usec_prescaler   : integer range 0 to TICKS_PER_US-1 := 0;
    
    -- ========== Timer Programable (16-bit) ==========
    signal timer_value      : unsigned(15 downto 0) := (others => '0');
    signal timer_reload     : unsigned(15 downto 0) := (others => '0');
    signal timer_prescaler  : unsigned(7 downto 0) := x"00";  -- Divide adicional
    signal timer_prescnt    : unsigned(7 downto 0) := (others => '0');
    
    -- Timer control bits
    signal timer_en         : std_logic := '0';
    signal timer_irq_en     : std_logic := '0';
    signal timer_repeat     : std_logic := '0';
    signal timer_irq_flag   : std_logic := '0';
    signal timer_zero       : std_logic := '0';
    
begin

    -- ========== Contador de Ticks (siempre corriendo) ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tick_counter <= (others => '0');
            else
                tick_counter <= tick_counter + 1;
            end if;
        end if;
    end process;

    -- ========== Contador de Microsegundos ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                usec_counter <= (others => '0');
                usec_prescaler <= 0;
            else
                -- Reset por software
                if cs = '1' and wr = '1' and addr = x"C" then
                    if data_in(6) = '1' then
                        usec_counter <= (others => '0');
                        usec_prescaler <= 0;
                    end if;
                else
                    -- Incrementar cada microsegundo
                    if usec_prescaler = TICKS_PER_US - 1 then
                        usec_prescaler <= 0;
                        usec_counter <= usec_counter + 1;
                    else
                        usec_prescaler <= usec_prescaler + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ========== Timer Programable ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                timer_value <= (others => '0');
                timer_reload <= (others => '0');
                timer_prescaler <= (others => '0');
                timer_prescnt <= (others => '0');
                timer_en <= '0';
                timer_irq_en <= '0';
                timer_repeat <= '0';
                timer_irq_flag <= '0';
                timer_zero <= '0';
            else
                -- Escritura a registros del timer
                if cs = '1' and wr = '1' then
                    case addr is
                        when x"4" =>  -- TIMER_LO
                            timer_reload(7 downto 0) <= unsigned(data_in);
                            timer_value(7 downto 0) <= unsigned(data_in);
                        when x"5" =>  -- TIMER_HI
                            timer_reload(15 downto 8) <= unsigned(data_in);
                            timer_value(15 downto 8) <= unsigned(data_in);
                        when x"6" =>  -- TIMER_CTL
                            timer_en <= data_in(0);
                            timer_irq_en <= data_in(1);
                            timer_repeat <= data_in(2);
                            -- Clear IRQ flag escribiendo 1
                            if data_in(3) = '1' then
                                timer_irq_flag <= '0';
                            end if;
                            -- Clear zero flag solo si se escribe 1 al bit 7
                            if data_in(7) = '1' then
                                timer_zero <= '0';
                            end if;
                        when x"7" =>  -- PRESCALER
                            timer_prescaler <= unsigned(data_in);
                            timer_prescnt <= (others => '0');
                        when others =>
                            null;
                    end case;
                end if;
                
                -- Timer countdown
                if timer_en = '1' then
                    -- Prescaler del timer
                    if timer_prescnt = timer_prescaler then
                        timer_prescnt <= (others => '0');
                        
                        if timer_value = 0 then
                            timer_zero <= '1';
                            timer_irq_flag <= '1';
                            
                            if timer_repeat = '1' then
                                timer_value <= timer_reload;
                            else
                                timer_en <= '0';
                            end if;
                        else
                            timer_value <= timer_value - 1;
                        end if;
                    else
                        timer_prescnt <= timer_prescnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ========== Latch de contadores ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tick_latch <= (others => '0');
                usec_latch <= (others => '0');
            elsif cs = '1' and wr = '1' and addr = x"C" then
                -- Latch TICK
                if data_in(0) = '1' then
                    tick_latch <= tick_counter;
                end if;
                -- Latch USEC
                if data_in(1) = '1' then
                    usec_latch <= usec_counter;
                end if;
                -- Reset TICK
                if data_in(7) = '1' then
                    tick_latch <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- ========== IRQ Output ==========
    timer_irq <= timer_irq_flag and timer_irq_en;

    -- ========== Bus de lectura ==========
    process(cs, rd, addr, tick_latch, usec_latch, timer_value, 
            timer_en, timer_irq_en, timer_repeat, timer_irq_flag, timer_zero, timer_prescaler)
    begin
        data_out <= (others => '0');
        if cs = '1' and rd = '1' then
            case addr is
                -- TICK counter (latched)
                when x"0" => data_out <= std_logic_vector(tick_latch(7 downto 0));
                when x"1" => data_out <= std_logic_vector(tick_latch(15 downto 8));
                when x"2" => data_out <= std_logic_vector(tick_latch(23 downto 16));
                when x"3" => data_out <= std_logic_vector(tick_latch(31 downto 24));
                
                -- Timer value
                when x"4" => data_out <= std_logic_vector(timer_value(7 downto 0));
                when x"5" => data_out <= std_logic_vector(timer_value(15 downto 8));
                
                -- Timer control/status
                when x"6" => 
                    data_out <= timer_zero & "000" & timer_irq_flag & timer_repeat & timer_irq_en & timer_en;
                
                -- Prescaler
                when x"7" => data_out <= std_logic_vector(timer_prescaler);
                
                -- USEC counter (latched)
                when x"8" => data_out <= std_logic_vector(usec_latch(7 downto 0));
                when x"9" => data_out <= std_logic_vector(usec_latch(15 downto 8));
                when x"A" => data_out <= std_logic_vector(usec_latch(23 downto 16));
                when x"B" => data_out <= std_logic_vector(usec_latch(31 downto 24));
                
                when others => data_out <= (others => '0');
            end case;
        end if;
    end process;

end architecture;
