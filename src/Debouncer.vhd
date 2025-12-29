library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
    Generic (
        CLK_FREQ : integer := 6_750_000;
        DEBOUNCE_MS : integer := 50
    );
    Port (
        clk : in STD_LOGIC;
        button_in : in STD_LOGIC;
        button_out : out STD_LOGIC
    );
end debounce;

architecture Behavioral of debounce is
    signal count : integer := 0;
    signal stable : STD_LOGIC := '1';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if button_in /= stable then
                if count = (CLK_FREQ * DEBOUNCE_MS) / 1000 then
                    stable <= button_in;
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            else
                count <= 0;
            end if;
        end if;
    end process;
    
    button_out <= stable;
end Behavioral;