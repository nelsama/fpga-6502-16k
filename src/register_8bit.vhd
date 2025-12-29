library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;    

--use work.types.all;


entity register_8bit is 
    port(   clk: in std_logic;
            clk_e: in std_logic;
            data_in : in std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0);
            rst : in std_logic;
            ce : in std_logic

);
end register_8bit;

architecture arch of register_8bit is
    
begin

    process(clk,rst,ce)
        variable reg : std_logic_vector(7 downto 0) :="11111111";
    begin
        if(falling_edge(clk)) then
            if (rst='1') then
                reg:="11111111";
            elsif(clk_e='1') then
                reg := data_in;
            end if;
        end if;
        if (ce='1') then
            data_out<=reg;
        else
            data_out<="ZZZZZZZZ";
        end if;
    end process;


end arch;