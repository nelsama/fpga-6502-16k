-- ============================================
-- UART para fpga-6502
-- Configuración: 9600 baud, 8N1
-- Reloj de entrada: 6.75 MHz
-- ============================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    generic (
        CLK_FREQ    : integer := 6_750_000;  -- Frecuencia del reloj (6.75 MHz)
        BAUD_RATE   : integer := 115200        -- Velocidad en baudios
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface con CPU
        cs          : in  std_logic;         -- Chip select
        addr        : in  std_logic_vector(1 downto 0);  -- 4 registros
        rd          : in  std_logic;         -- Read enable
        wr          : in  std_logic;         -- Write enable
        data_in     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        
        -- Señales UART
        uart_tx     : out std_logic;
        uart_rx     : in  std_logic;
        
        -- Interrupción (opcional)
        uart_irq    : out std_logic
    );
end entity;

architecture rtl of uart is

    -- Cálculo de divisor para baud rate
    constant DIVISOR : integer := CLK_FREQ / BAUD_RATE;
    constant HALF_DIVISOR : integer := DIVISOR / 2;
    
    -- Registros UART (direcciones relativas)
    -- $00 = TX_DATA  (W) / RX_DATA (R)
    -- $01 = STATUS   (R) / CONTROL (W)
    -- $02 = BAUD_LO  (R/W) - Divisor bajo (futuro)
    -- $03 = BAUD_HI  (R/W) - Divisor alto (futuro)
    
    -- Status bits (lectura)
    -- Bit 0: TX_READY  (1 = listo para transmitir)
    -- Bit 1: RX_VALID  (1 = dato recibido disponible)
    -- Bit 2: TX_BUSY   (1 = transmitiendo)
    -- Bit 3: RX_ERROR  (1 = error de frame)
    -- Bit 4: RX_OVERRUN (1 = dato perdido)
    
    -- Control bits (escritura)
    -- Bit 0: TX_IRQ_EN  (habilitar IRQ en TX listo)
    -- Bit 1: RX_IRQ_EN  (habilitar IRQ en RX válido)
    -- Bit 7: RESET_FLAGS (limpiar flags de error)
    
    -- ========== TRANSMISOR ==========
    type tx_state_t is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
    signal tx_state     : tx_state_t := TX_IDLE;
    signal tx_data_reg  : std_logic_vector(7 downto 0);
    signal tx_bit_cnt   : integer range 0 to 7 := 0;
    signal tx_clk_cnt   : integer range 0 to DIVISOR := 0;
    signal tx_ready     : std_logic := '1';
    signal tx_busy      : std_logic := '0';
    signal tx_trigger   : std_logic := '0';
    
    -- ========== RECEPTOR ==========
    type rx_state_t is (RX_IDLE, RX_START, RX_DATA, RX_STOP);
    signal rx_state     : rx_state_t := RX_IDLE;
    signal rx_data_reg  : std_logic_vector(7 downto 0);
    signal rx_buffer    : std_logic_vector(7 downto 0);
    signal rx_bit_cnt   : integer range 0 to 7 := 0;
    signal rx_clk_cnt   : integer range 0 to DIVISOR := 0;
    signal rx_valid     : std_logic := '0';
    signal rx_error     : std_logic := '0';
    signal rx_overrun   : std_logic := '0';
    
    -- Sincronización de RX
    signal rx_sync      : std_logic_vector(2 downto 0) := "111";
    signal rx_filtered  : std_logic := '1';
    
    -- Control
    signal tx_irq_en    : std_logic := '0';
    signal rx_irq_en    : std_logic := '0';
    
begin

    -- ========== SINCRONIZACIÓN DE RX ==========
    -- Evitar metaestabilidad y filtrar ruido
    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(1 downto 0) & uart_rx;
            -- Filtro de mayoría (2 de 3)
            if (rx_sync(0) = '1' and rx_sync(1) = '1') or
               (rx_sync(1) = '1' and rx_sync(2) = '1') or
               (rx_sync(0) = '1' and rx_sync(2) = '1') then
                rx_filtered <= '1';
            else
                rx_filtered <= '0';
            end if;
        end if;
    end process;

    -- ========== TRANSMISOR ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_state <= TX_IDLE;
                uart_tx <= '1';
                tx_ready <= '1';
                tx_busy <= '0';
                tx_trigger <= '0';
            else
                -- Detectar escritura al registro TX
                if cs = '1' and wr = '1' and addr = "00" then
                    tx_data_reg <= data_in;
                    tx_trigger <= '1';
                end if;
                
                case tx_state is
                    when TX_IDLE =>
                        uart_tx <= '1';  -- Línea idle = alto
                        tx_ready <= '1';
                        tx_busy <= '0';
                        
                        if tx_trigger = '1' then
                            tx_trigger <= '0';
                            tx_state <= TX_START;
                            tx_clk_cnt <= 0;
                            tx_ready <= '0';
                            tx_busy <= '1';
                        end if;
                        
                    when TX_START =>
                        uart_tx <= '0';  -- Start bit = bajo
                        if tx_clk_cnt = DIVISOR - 1 then
                            tx_clk_cnt <= 0;
                            tx_bit_cnt <= 0;
                            tx_state <= TX_DATA;
                        else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                        end if;
                        
                    when TX_DATA =>
                        uart_tx <= tx_data_reg(tx_bit_cnt);
                        if tx_clk_cnt = DIVISOR - 1 then
                            tx_clk_cnt <= 0;
                            if tx_bit_cnt = 7 then
                                tx_state <= TX_STOP;
                            else
                                tx_bit_cnt <= tx_bit_cnt + 1;
                            end if;
                        else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                        end if;
                        
                    when TX_STOP =>
                        uart_tx <= '1';  -- Stop bit = alto
                        if tx_clk_cnt = DIVISOR - 1 then
                            tx_state <= TX_IDLE;
                        else
                            tx_clk_cnt <= tx_clk_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- ========== RECEPTOR ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                rx_state <= RX_IDLE;
                rx_valid <= '0';
                rx_error <= '0';
                rx_overrun <= '0';
            else
                -- Limpiar rx_valid cuando se lee el dato
                if cs = '1' and rd = '1' and addr = "00" then
                    rx_valid <= '0';
                end if;
                
                -- Limpiar flags con bit de control
                if cs = '1' and wr = '1' and addr = "01" and data_in(7) = '1' then
                    rx_error <= '0';
                    rx_overrun <= '0';
                end if;
                
                case rx_state is
                    when RX_IDLE =>
                        if rx_filtered = '0' then  -- Detectar start bit
                            rx_state <= RX_START;
                            rx_clk_cnt <= 0;
                        end if;
                        
                    when RX_START =>
                        -- Muestrear en la mitad del bit
                        if rx_clk_cnt = HALF_DIVISOR then
                            if rx_filtered = '0' then
                                -- Start bit válido
                                rx_clk_cnt <= 0;
                                rx_bit_cnt <= 0;
                                rx_state <= RX_DATA;
                            else
                                -- Falso start, volver a idle
                                rx_state <= RX_IDLE;
                            end if;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;
                        
                    when RX_DATA =>
                        if rx_clk_cnt = DIVISOR - 1 then
                            rx_clk_cnt <= 0;
                            rx_data_reg(rx_bit_cnt) <= rx_filtered;
                            if rx_bit_cnt = 7 then
                                rx_state <= RX_STOP;
                            else
                                rx_bit_cnt <= rx_bit_cnt + 1;
                            end if;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;
                        
                    when RX_STOP =>
                        if rx_clk_cnt = DIVISOR - 1 then
                            if rx_filtered = '1' then
                                -- Stop bit válido
                                if rx_valid = '1' then
                                    rx_overrun <= '1';  -- Dato anterior no leído
                                else
                                    rx_buffer <= rx_data_reg;
                                    rx_valid <= '1';
                                end if;
                            else
                                rx_error <= '1';  -- Frame error
                            end if;
                            rx_state <= RX_IDLE;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- ========== CONTROL E IRQ ==========
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_irq_en <= '0';
                rx_irq_en <= '0';
            elsif cs = '1' and wr = '1' and addr = "01" then
                tx_irq_en <= data_in(0);
                rx_irq_en <= data_in(1);
            end if;
        end if;
    end process;
    
    -- Generar IRQ
    uart_irq <= (tx_ready and tx_irq_en) or (rx_valid and rx_irq_en);

    -- ========== BUS DE DATOS ==========
    process(cs, rd, addr, rx_buffer, tx_ready, rx_valid, tx_busy, rx_error, rx_overrun, tx_irq_en, rx_irq_en)
    begin
        data_out <= (others => '0');
        if cs = '1' and rd = '1' then
            case addr is
                when "00" =>  -- RX_DATA
                    data_out <= rx_buffer;
                when "01" =>  -- STATUS
                    data_out <= "000" & rx_overrun & rx_error & tx_busy & rx_valid & tx_ready;
                when "10" =>  -- CONTROL (lectura)
                    data_out <= "000000" & rx_irq_en & tx_irq_en;
                when others =>
                    data_out <= (others => '0');
            end case;
        end if;
    end process;

end architecture;
