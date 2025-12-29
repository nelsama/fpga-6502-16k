-- ============================================
-- SID 6581 Wrapper para fpga-6502
-- Mapeo de memoria: $D400-$D41F (32 bytes)
-- Compatible con Commodore 64
-- Sincronización corregida entre dominios de reloj
-- ============================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sid_wrapper is
    port (
        clk_fast    : in  std_logic;         -- 27 MHz (para filtros y DAC)
        clk_system  : in  std_logic;         -- 6.75 MHz
        clk_1mhz    : in  std_logic;         -- ~1 MHz (generado externamente)
        rst_n       : in  std_logic;
        
        -- Interface CPU 6502
        cpu_addr    : in  std_logic_vector(15 downto 0);
        cpu_data_in : in  std_logic_vector(7 downto 0);
        cpu_data_out: out std_logic_vector(7 downto 0);
        cpu_rw      : in  std_logic;         -- 1=Read, 0=Write
        
        -- Audio outputs
        audio_out   : out std_logic;         -- PWM output
        audio_data  : out std_logic_vector(17 downto 0)
    );
end entity;

architecture rtl of sid_wrapper is

    -- Señales internas
    signal sid_cs       : std_logic;
    signal sid_we       : std_logic;
    signal sid_dout     : std_logic_vector(7 downto 0);
    signal reset_active : std_logic;
    
    -- Detección de dirección
    signal addr_match   : std_logic;
    signal sid_addr     : std_logic_vector(4 downto 0);
    
    -- Registros para captura en dominio clk_system
    signal addr_reg     : std_logic_vector(4 downto 0) := (others => '0');
    signal data_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal write_req    : std_logic := '0';
    
    -- Sincronización al dominio clk_fast (27 MHz)
    signal write_req_sync1 : std_logic := '0';
    signal write_req_sync2 : std_logic := '0';
    signal write_req_sync3 : std_logic := '0';
    signal write_pulse     : std_logic := '0';
    
    -- Registros sincronizados en dominio clk_fast
    signal addr_sync    : std_logic_vector(4 downto 0) := (others => '0');
    signal data_sync    : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Reset activo alto para el SID
    reset_active <= not rst_n;

    -- Detectar dirección en rango SID: $D400-$D41F (compatible C64)
    addr_match <= '1' when cpu_addr(15 downto 5) = "11010100000" else '0';
    
    -- Dirección interna del SID (5 bits)
    sid_addr <= cpu_addr(4 downto 0);

    -- ============================================
    -- Captura de escritura en dominio clk_system
    -- ============================================
    process(clk_system)
    begin
        if rising_edge(clk_system) then
            if rst_n = '0' then
                addr_reg <= (others => '0');
                data_reg <= (others => '0');
                write_req <= '0';
            else
                -- Detectar escritura al SID
                if addr_match = '1' and cpu_rw = '0' then
                    addr_reg <= sid_addr;
                    data_reg <= cpu_data_in;
                    write_req <= not write_req;  -- Toggle para detectar nuevo write
                end if;
            end if;
        end if;
    end process;

    -- ============================================
    -- Sincronización al dominio clk_fast (27 MHz)
    -- y generación de pulso de escritura
    -- ============================================
    process(clk_fast)
    begin
        if rising_edge(clk_fast) then
            if rst_n = '0' then
                write_req_sync1 <= '0';
                write_req_sync2 <= '0';
                write_req_sync3 <= '0';
                write_pulse <= '0';
                addr_sync <= (others => '0');
                data_sync <= (others => '0');
            else
                -- Sincronizador de 3 etapas
                write_req_sync1 <= write_req;
                write_req_sync2 <= write_req_sync1;
                write_req_sync3 <= write_req_sync2;
                
                -- Detectar cambio (edge) = nuevo write
                if write_req_sync2 /= write_req_sync3 then
                    write_pulse <= '1';
                    addr_sync <= addr_reg;
                    data_sync <= data_reg;
                else
                    write_pulse <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Señales al SID
    sid_cs <= write_pulse;
    sid_we <= write_pulse;
    
    -- ============================================
    -- Instancia del SID 6581
    -- (clk_1mhz viene del puerto externo)
    -- ============================================
    sid_inst : entity work.sid6581
        port map (
            clk_1MHz    => clk_1mhz,
            clk32       => clk_fast,
            clk_DAC     => clk_fast,
            reset       => reset_active,
            cs          => sid_cs,
            we          => sid_we,
            addr        => addr_sync,
            di          => data_sync,
            do          => sid_dout,
            pot_x       => '0',
            pot_y       => '0',
            audio_out   => audio_out,
            audio_data  => audio_data
        );
    
    -- Bus de datos de salida (lectura de registros SID)
    cpu_data_out <= sid_dout when (addr_match = '1' and cpu_rw = '1') else (others => 'Z');

end architecture;
