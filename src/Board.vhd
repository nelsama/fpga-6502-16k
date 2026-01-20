library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;    

--use work.types.all;

entity Board is 
    port(   CLOCK_27_i: in std_logic;                   -- 27 Mhz
            cpu_clk_out : out std_logic;                    -- 3.375 MHz
            reset_in: in std_logic;
            port_1 : inOut std_logic_vector(7 downto 0);
            port_2 : inOut std_logic_vector(7 downto 0);
            i2c_scl : inOut std_logic;
            i2c_sda : inOut std_logic;
            -- UART
            uart_tx : out std_logic;
            uart_rx : in std_logic;
            -- SID Audio
            sid_audio_out : out std_logic;
            -- SPI Flash
            spi_miso : in std_logic;
            spi_mosi : out std_logic;
            spi_sclk : out std_logic;
            spi_cs_n : out std_logic_vector(3 downto 0)
);
end Board;

architecture arch of Board is
    signal cpu_clk :std_logic;
    signal data_bus : std_logic_vector(7 downto 0);
    signal rom_data_bus : std_logic_vector(7 downto 0);
    signal ram_data_bus : std_logic_vector(7 downto 0);
    signal addr_bus : std_logic_vector(15 downto 0);
    signal system_clk,tmp_clk: std_logic := '0';
    signal r_w : std_logic;
    signal port1_ce,port2_ce,conf_p1_ce,conf_p2_ce,ram_ce: std_logic;
    signal port_in1, port_in2 : std_logic_vector(7 downto 0) := "00000000";
    signal port_out1,port_out2 : std_logic_vector(7 downto 0);
    signal cfg_p1_reg,cfg_p2_reg: std_logic_vector(7 downto 0);
    signal reset :std_logic := '1';
    signal btn_reset :std_logic := '1';
    signal ini_reset :std_logic := '1';
    signal debug_pc : std_logic_vector(15 downto 0);
    signal i2c_irq :std_logic := '1';
    signal uart_irq :std_logic := '1';
    signal timer_irq :std_logic := '1';
    signal spi_irq :std_logic := '1';
    signal irq_combined :std_logic := '1';
    signal rom_addr_out  : std_logic_vector(15 downto 0);
    signal sid_audio_data : std_logic_vector(17 downto 0);
    
    -- Generador de reloj 1 MHz para SID
    signal clk_1mhz         : std_logic := '0';
    signal clk_1mhz_counter : integer range 0 to 15 := 0;
    
    -- Reloj de 81 MHz para PWM DAC de 12 bits
    signal clk_81mhz        : std_logic := '0';
    signal pll_lock         : std_logic := '0';
    signal clk_81mhz_safe   : std_logic := '0';


begin

    clk_inst: entity work.Gowin_CLKDIV_6_750_MHz
    port map (
        clkout => system_clk,       -- 6.750 MHz
        hclkin => CLOCK_27_i,
        resetn => '1'
    );

    -- PLL para generar 81 MHz para PWM DAC de 12 bits
    -- 81 MHz / 4096 = 19.78 kHz (frecuencia PWM adecuada)
    pll_inst: entity work.Gowin_PLL_81MHz
    port map (
        clkout => clk_81mhz,
        lock   => pll_lock,
        clkin  => CLOCK_27_i
    );
    
    -- Usar 81 MHz solo cuando el PLL esté bloqueado, sino usar 27 MHz
    clk_81mhz_safe <= clk_81mhz when pll_lock = '1' else CLOCK_27_i;

    init_reset : entity work.reset_generator -- 50 ms
    port map(
        clk=>system_clk,
        power_seq=>ini_reset
    );


    debounce : entity work.debounce
    port map(
        clk=>system_clk,
        button_in=>reset_in,
        button_out=>btn_reset
	);

    reset <= btn_reset and ini_reset;
    --reset <= ini_reset;

    clk_divisor : process(system_clk)
    begin
        if rising_edge(system_clk) then
            tmp_clk <= not tmp_clk;  -- Invierte el bit en cada flanco
        end if;
    end process;

    cpu_clk<=tmp_clk;
    cpu_clk_out<=tmp_clk;

    -- ============================================
    -- Generador de reloj ~1 MHz para el SID
    -- 27 MHz / 28 ≈ 0.96 MHz (toggle cada 14 ciclos)
    -- Generado en el top-level para mejor calidad de señal
    -- ============================================
    clk_1mhz_gen: process(CLOCK_27_i)
    begin
        if rising_edge(CLOCK_27_i) then
            if reset = '0' then
                clk_1mhz_counter <= 0;
                clk_1mhz <= '0';
            else
                if clk_1mhz_counter = 13 then
                    clk_1mhz_counter <= 0;
                    clk_1mhz <= not clk_1mhz;
                else
                    clk_1mhz_counter <= clk_1mhz_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Combinar todas las IRQs (activas en alto desde los módulos)
    -- El CPU 6502 tiene IRQ activa en bajo, así que invertimos
    irq_combined <= not (i2c_irq or uart_irq or timer_irq or spi_irq);

    cpu_6502 : entity work.A6502
    port map(
             clk=>cpu_clk,
             rst=> reset,
             irq=>irq_combined,
             nmi=>'1',
             rdy=>'1',
             d=>data_bus,
             ad=>addr_bus,
             r=>r_w
	);

    i2c_interface : entity work.i2c_gowin_wrapper
    port map(
        clk_6m75=>system_clk,
        rst_n=> reset,
        cpu_addr=>addr_bus,
        cpu_data=>data_bus,
        cpu_rw=>r_w,
        i2c_scl=>i2c_scl,
        i2c_sda=>i2c_sda,
        i2c_irq=>i2c_irq
	);

    -- UART Interface ($C020-$C023)
    uart_interface : entity work.uart_wrapper
    port map(
        clk=>system_clk,
        rst_n=>reset,
        cpu_addr=>addr_bus,
        cpu_data_in=>data_bus,
        cpu_data_out=>data_bus,
        cpu_rw=>r_w,
        uart_tx=>uart_tx,
        uart_rx=>uart_rx,
        uart_irq=>uart_irq
    );

    -- Timer/RTC Interface ($C030-$C03F)
    timer_interface : entity work.timer_wrapper
    port map(
        clk=>system_clk,
        rst_n=>reset,
        cpu_addr=>addr_bus,
        cpu_data_in=>data_bus,
        cpu_data_out=>data_bus,
        cpu_rw=>r_w,
        timer_irq=>timer_irq
    );

    -- SPI Master Interface ($C040-$C047)
    spi_interface : entity work.spi_wrapper
    port map(
        clk=>system_clk,
        rst_n=>reset,
        cpu_addr=>addr_bus,
        cpu_data_in=>data_bus,
        cpu_data_out=>data_bus,
        cpu_rw=>r_w,
        spi_irq=>spi_irq,
        spi_miso=>spi_miso,
        spi_mosi=>spi_mosi,
        spi_sclk=>spi_sclk,
        spi_cs_n=>spi_cs_n
    );

    -- SID 6581 Interface ($D400-$D41F) - Compatible C64
    sid_interface : entity work.sid_wrapper
    port map(
        clk_fast=>CLOCK_27_i,       -- 27 MHz para filtros
        clk_dac=>clk_81mhz_safe,    -- 81 MHz cuando PLL locked, sino 27 MHz
        clk_system=>system_clk,
        clk_1mhz=>clk_1mhz,
        rst_n=>reset,
        cpu_addr=>addr_bus,
        cpu_data_in=>data_bus,
        cpu_data_out=>data_bus,
        cpu_rw=>r_w,
        audio_out=>sid_audio_out,
        audio_data=>sid_audio_data
    );

    ce_sync: process (system_clk) is
    begin
        if falling_edge(system_clk) then

            port1_ce <= '0';
            port2_ce <= '0';
            conf_p1_ce <= '0';
            conf_p2_ce <= '0';
            ram_ce <= '0';


            if addr_bus = x"C000" then
                port1_ce <= '1';
            end if;

            if addr_bus = x"C001" then
                port2_ce <= '1'; 
            end if;

            if addr_bus = x"C002" then
                conf_p1_ce <= '1';
            end if;

            if addr_bus = x"C003" then
                conf_p2_ce <= '1';
            end if;

            if (addr_bus >= x"0000") and (addr_bus <= x"3FFF") then
                ram_ce <= '1';
            end if;
            
        end if;
    end process;

    
    data_bus_mux : entity work.data_bus_mux
    port map(
        clk=>system_clk,
        r_w=>r_w,
        addr_in=>addr_bus,
        ram_data_bus_in=>ram_data_bus,
        rom_data_bus_in=>rom_data_bus,
        port1_in=>port_in1,
        port2_in=>port_in2,
        data_bus_out=>data_bus,
        rom_addr_out=>rom_addr_out
    );

    port1_reg : entity work.register_8bit
    port map(
            clk=>system_clk,
            clk_e=>port1_ce and not r_w,
            data_in=>data_bus,
            data_out=>port_out1,
            rst=>not reset,
            ce=>'1'
    );

    port2_reg : entity work.register_8bit
    port map(
            clk=>system_clk,
            clk_e=>port2_ce and not r_w,
            data_in=>data_bus,
            data_out=>port_out2,
            rst=>not reset,
            ce=>'1'
    );

    conf_p1_reg : entity work.register_8bit
    port map(
            clk=>system_clk,
            clk_e=>conf_p1_ce and not r_w,
            data_in=>data_bus,
            data_out=>cfg_p1_reg,
            rst=>not reset,
            ce=>'1'
    );

    conf_p2_reg : entity work.register_8bit
    port map(
            clk=>system_clk,
            clk_e=>conf_p2_ce and not r_w,
            data_in=>data_bus,
            data_out=>cfg_p2_reg,
            rst=>not reset,
            ce=>'1'
    );


    port_sync: process(system_clk)
    begin
        if falling_edge(system_clk) then
            for i in 0 to 7 loop

                if cfg_p1_reg(i) = '0' then
                    port_1(i) <= port_out1(i);  -- Modo salida
                else
                    port_1(i) <= 'Z';           -- Modo entrada (alta impedancia)
                end if;
                
                if cfg_p2_reg(i) = '0' then
                    port_2(i) <= port_out2(i);  -- Modo salida
                else
                    port_2(i) <= 'Z';           -- Modo entrada (alta impedancia)
                end if;
            end loop;
            port_in1<=port_1;
            port_in2<=port_2;
        end if;
    end process;


    rom: entity work.rom      -- 16k
    port map (
        data_out => rom_data_bus,
        clk => system_clk,
        address => rom_addr_out(13 downto 0)  -- 14 bits para 16KB
    );

    ram: entity work.ram_gowin  -- 16k
    port map (
        dout => ram_data_bus,
        clk => system_clk,
        oce => '1',
        ce => ram_ce,
        reset => '0',
        wre => not r_w,
        ad => addr_bus(13 downto 0),
        din => data_bus
    );

end arch;