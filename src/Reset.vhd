library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reset_generator is
    generic (
        CLK_FREQ    : integer := 6_750_000;  -- Frecuencia del reloj en Hz (50 MHz)
        PULSE_MS    : integer := 50           -- Duración de cada fase en ms
    );
    port (
        clk         : in  std_logic;
        power_seq   : out std_logic           -- Secuencia de power-on
    );
end entity;

architecture behavioral of reset_generator is
    type state_type is (INIT_HIGH, PULSE_LOW, STABLE_HIGH);
    signal state    : state_type := INIT_HIGH;
    
    constant COUNTER_MAX : integer := (CLK_FREQ * PULSE_MS) / 1000;
    signal counter  : integer range 0 to COUNTER_MAX := 0;
    
begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when INIT_HIGH =>
                    power_seq <= '1';
                    if counter < COUNTER_MAX then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state <= PULSE_LOW;
                    end if;
                    
                when PULSE_LOW =>
                    power_seq <= '0';
                    if counter < COUNTER_MAX then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                        state <= STABLE_HIGH;
                    end if;
                    
                when STABLE_HIGH =>
                    power_seq <= '1';
                    -- Se mantiene en este estado permanentemente
                    
            end case;
        end if;
    end process;

end architecture;