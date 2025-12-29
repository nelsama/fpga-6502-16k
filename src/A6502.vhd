
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;    

--use work.types.all;

entity A6502 is 
	generic (
		pipelineOpcode : boolean:= false;
		pipelineAluMux : boolean:= false;
		pipelineAluOut : boolean:= false
	);
    port(   clk: in std_logic;
             rst: in std_logic;
             irq: in std_logic;
             nmi: in std_logic;
             rdy: in std_logic;
             d: inout std_logic_vector(7 downto 0);
             ad: out std_logic_vector(15 downto 0);
             r: out std_logic
                );
end A6502;

architecture arch of A6502 is


    signal cpuDi: std_logic_vector(7 downto 0);
    signal cpuDo: std_logic_vector(7 downto 0);
    signal cpuWe: std_logic;

    signal tmpDo: unsigned(7 downto 0);
    signal tmpAddr: unsigned(15 downto 0);


begin

    r <= not cpuWe;
    
    cpuDi <= d when cpuWe = '0' else "ZZZZZZZZ";
    d <= cpuDo when cpuWe = '1' else "ZZZZZZZZ";
        
	cpuInstance: entity work.cpu65xx(fast)
		generic map (
			pipelineOpcode => pipelineOpcode,
			pipelineAluMux => pipelineAluMux,
			pipelineAluOut => pipelineAluOut
		)
		port map (
			clk => clk,
			enable => '1',
			reset => not rst,
			nmi_n => nmi,
			irq_n => irq,

			di => unsigned(cpuDi),
			do => tmpDo,
			addr => tmpAddr,
			we => cpuWe

		);

    cpuDo<=std_logic_vector(tmpDo);
    ad<=std_logic_vector(tmpAddr);

end arch;
