-- ============================================================================
-- video_bus.vhd  --  Puente CPU <-> VRAM (Fase 4, Opcion B)
--
-- El CPU escribe la VRAM indirectamente a traves de TRES registros:
--
--     $D800  VID_ADDR_LO  (W) : byte BAJO de la direccion de VRAM (8 bits)
--     $D801  VID_ADDR_HI  (W) : byte ALTO de la direccion (5 bits usados):
--                                 bits 2..0  -> direccion[10..8]
--                                 bits 7..6  -> area ("00" mapa, "01" atributos,
--                                               "10" patrones)
--                                 bit 5      -> pat_hi (solo patrones: byte alto
--                                               de la palabra de 16 bits = plano 1)
--     $D802  VID_DATA     (W) : dato (8 bits). Al escribir aqui se dispara la
--                               escritura real en la VRAM.
--
--   Para escribir un TILEMAP/ATRIBUTO (areas 00/01):
--       STA $D800   ; dir[7:0]
--       STA $D801   ; area<<6 | dir[10:8]
--       STA $D802   ; dato -> dispara la escritura
--
--   ESCRIBIR PATRONES DE SPRITE (area 11, bit 3 de $D801 = 1):
--       STA $D800   ; dir[7:0]  (dir = sprite*8 + fila ; sprite 0..63)
--       STA $D801   ; $C8 | (dir[10:8] & 3)  (area=11, bit3=1, pat_hi=0 -> plano0)
--       STA $D802   ; plano 0 (8 bits)
--       STA $D801   ; $E8 | (dir[10:8] & 3)  (area=11, bit3=1, pat_hi=1 -> plano1)
--       STA $D802   ; plano 1 -> dispara la escritura de la palabra completa
--
--   ESCRIBIR OAM (area 11, bit 3 de $D801 = 0, 16 sprites x 4 bytes):
--       STA $D800   ; byte[5:0] (0..63)
--       STA $D801   ; $C0            (area=11, bit3=0)
--       STA $D802   ; dato -> dispara
--
-- CRUCE DE DOMINIO (RNF-01, igual que el SID):
--   La escritura de VID_DATA se captura en clk_sys como un TOGGLE de 'write_req'
--   y se sincroniza por doble flop al dominio clk_vid, donde se detecta su flanco
--   para generar un pulso de 1 ciclo. La direccion y el dato NO cruzan (ya estan
--   asentados en registros del CPU). Solo el pulso cruza.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_bus is
    port (
        -- Dominio CPU
        clk_sys      : in  std_logic;
        rst_n        : in  std_logic;
        cpu_addr     : in  std_logic_vector(15 downto 0);
        cpu_data_in  : in  std_logic_vector(7 downto 0);
        cpu_rw       : in  std_logic;                 -- 1=lectura, 0=escritura

        -- Dominio de video
        clk_vid      : in  std_logic;

        -- Interfaz hacia el motor de video (un pulso, con area/dir/dato estables)
        vid_we       : out std_logic;                 -- pulso de 1 ciclo de clk_vid
        vid_area     : out std_logic_vector(1 downto 0);
        vid_addr     : out std_logic_vector(10 downto 0);
        vid_data     : out std_logic_vector(7 downto 0);
        vid_hi       : out std_logic;                 -- 1 = byte alto (plano 1)
        vid_spr      : out std_logic;                 -- 1 = area 11 es patron sprite (0=OAM)

        -- Status de video (registro de LECTURA $D803)
        status_in    : in  std_logic_vector(7 downto 0);
        clear_stats  : out std_logic;                 -- pulso: limpiar flags sticky
        cpu_data_out : out std_logic_vector(7 downto 0);  -- dato al bus (STATUS)

        -- Registros de SCROLL (escritura): $D804-$D808
        --   $D804 scroll_x[7:0]   $D805 scroll_x[10:8]
        --   $D806 scroll_y[7:0]   $D807 scroll_y[10:8]
        --   $D808 map_stride (ancho del mapa en celdas)
        sc_x_out    : out std_logic_vector(10 downto 0);
        sc_y_out    : out std_logic_vector(10 downto 0);
        sc_stride   : out std_logic_vector(7 downto 0);

        -- Split de raster (Fase 8): $D809-$D812  (hasta 3 bandas)
        --   $D809 raster_line0 : fin de la banda SUPERIOR.  $FF = sin banda top.
        --   $D80A/$D80B band2_x/lo,hi : scroll de la banda SUPERIOR
        --   $D80C/$D80D band2_y/lo,hi : scroll Y de la banda SUPERIOR
        --   $D80E raster_line1 : fin de la banda MEDIA.  $FF = sin banda bottom.
        --   $D80F/$D810 band3_x lo/hi : scroll de la banda INFERIOR
        --   $D811/$D812 band3_y lo/hi : scroll Y de la banda INFERIOR
        --   La banda MEDIA usa el scroll NORMAL ($D804/$D806).
        rl0_out     : out std_logic_vector(7 downto 0);
        b2x_out     : out std_logic_vector(10 downto 0);
        b2y_out     : out std_logic_vector(10 downto 0);
        rl1_out     : out std_logic_vector(7 downto 0);
        b3x_out     : out std_logic_vector(10 downto 0);
        b3y_out     : out std_logic_vector(10 downto 0);

        -- PALETA ESCRIBIBLE (Fase 13): puerto indirecto con auto-incremento.
        --   $D813 = PAL_PTR  (puntero 0..31: 0-15 fondo, 16-31 sprite)
        --   $D814 = PAL_LO   (color[7:0])
        --   $D815 = PAL_HI   (color[11:8] en bits 3:0) -> escribe y ptr++
        pal_wr_out  : out std_logic;                     -- pulso (dominio CPU->video)
        pal_ptr_out : out std_logic_vector(4 downto 0);
        pal_lo_out  : out std_logic_vector(7 downto 0);
        pal_hi_out  : out std_logic_vector(3 downto 0);

        -- SETUP de video por hardware (Fase 15)
        --   $D816 (W): escribir cualquier valor dispara el setup (limpiar VRAM
        --              + re-expandir la fuente).
        --   $D817 (R): STATUS del setup -> bit4 = VIDEO_READY (1 = terminado),
        --              bit0 = BUSY (1 = setup/init en curso).
        setup_req_out : out std_logic;                   -- pulso (dominio CPU->video)
        setup_busy_in : in  std_logic                    -- 1 = setup/init en curso
    );
end entity;

architecture rtl of video_bus is

    -- ========================================================================
    -- Registros del CPU
    -- ========================================================================
    signal addr_lo_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal addr_hi_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal data_reg    : std_logic_vector(7 downto 0) := (others => '0');

    -- ========================================================================
    -- Toggle de peticion (dominio clk_sys -> dominio clk_vid)
    -- ========================================================================
    signal write_req   : std_logic := '0';
    signal wr_sync1    : std_logic := '0';
    signal wr_sync2    : std_logic := '0';
    signal wr_sync3    : std_logic := '0';
    signal write_pulse : std_logic := '0';

    -- Decodificacion de direccion del CPU
    signal is_vid_lo  : std_logic;
    signal is_vid_hi  : std_logic;
    signal is_vid_dat : std_logic;
    signal is_vid_st  : std_logic;
    signal is_vid_pal : std_logic;

    -- Registros de scroll (dominio CPU)
    signal sc_x_lo_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal sc_x_hi_r   : std_logic_vector(2 downto 0) := (others => '0');
    signal sc_y_lo_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal sc_y_hi_r   : std_logic_vector(2 downto 0) := (others => '0');
    signal sc_stride_r : std_logic_vector(7 downto 0) := x"40";

    -- Split de raster ($D809-$D812)
    signal raster_line0_r : std_logic_vector(7 downto 0) := x"FF";  -- banda top
    signal b2x_lo_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal b2x_hi_r      : std_logic_vector(2 downto 0) := (others => '0');
    signal b2y_lo_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal b2y_hi_r      : std_logic_vector(2 downto 0) := (others => '0');
    signal raster_line1_r : std_logic_vector(7 downto 0) := x"FF";  -- banda bottom
    signal b3x_lo_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal b3x_hi_r      : std_logic_vector(2 downto 0) := (others => '0');
    signal b3y_lo_r      : std_logic_vector(7 downto 0) := (others => '0');
    signal b3y_hi_r      : std_logic_vector(2 downto 0) := (others => '0');

    -- Latido de limpieza de status (pulso al leer $D803)
    signal clear_tgl  : std_logic := '0';
    signal ct_s1      : std_logic := '0';
    signal ct_s2      : std_logic := '0';

    -- PALETA ESCRIBIBLE ($D813-$D815): registros en clk_sys + cruce por toggle.
    signal pal_ptr_r  : std_logic_vector(4 downto 0) := (others => '0');
    signal pal_lo_r   : std_logic_vector(7 downto 0) := (others => '0');
    signal pal_hi_r   : std_logic_vector(3 downto 0) := (others => '0');
    signal pal_req    : std_logic := '0';       -- toggle en clk_sys
    signal pal_active_d : std_logic := '0';
    signal pal_sync1  : std_logic := '0';
    signal pal_sync2  : std_logic := '0';
    signal pal_sync3  : std_logic := '0';
    signal pal_ptr_s   : std_logic_vector(4 downto 0) := (others => '0');  -- ptr latcheado
    signal pal_ptr_v   : std_logic_vector(4 downto 0) := (others => '0');  -- 2FF en clk_vid
    signal pal_ptr_v2  : std_logic_vector(4 downto 0) := (others => '0');
    signal pal_lo_v    : std_logic_vector(7 downto 0) := (others => '0');
    signal pal_lo_v2   : std_logic_vector(7 downto 0) := (others => '0');
    signal pal_hi_v    : std_logic_vector(3 downto 0) := (others => '0');
    signal pal_hi_v2   : std_logic_vector(3 downto 0) := (others => '0');
    signal ct_s3      : std_logic := '0';
    signal dat_active_d : std_logic := '0';

    -- SETUP por hardware ($D816/$D817): peticion en clk_sys + cruce por toggle.
    signal setup_req     : std_logic := '0';       -- toggle en clk_sys
    signal setup_active_d: std_logic := '0';
    signal setup_sync1   : std_logic := '0';
    signal setup_sync2   : std_logic := '0';
    signal is_vid_setup  : std_logic;
    signal is_vid_setupst: std_logic;

begin

    is_vid_lo  <= '1' when cpu_addr = x"D800" else '0';
    is_vid_hi  <= '1' when cpu_addr = x"D801" else '0';
    is_vid_dat <= '1' when cpu_addr = x"D802" else '0';
    is_vid_st  <= '1' when cpu_addr = x"D803" else '0';
    is_vid_pal <= '1' when cpu_addr = x"D815" else '0';   -- PAL_HI dispara la escritura
    is_vid_setup   <= '1' when cpu_addr = x"D816" else '0';   -- dispara setup
    is_vid_setupst <= '1' when cpu_addr = x"D817" else '0';   -- status de setup (lectura)

    -- Registros de scroll: se escriben directamente en clk_sys (valores estables;
    -- el motor los muestrea; un cambio de 1 frame de retraso es irrelevante).
    process (clk_sys)
    begin
        if rising_edge(clk_sys) then
            if rst_n = '0' then
                sc_x_lo_r   <= (others => '0');
                sc_x_hi_r   <= (others => '0');
                sc_y_lo_r   <= (others => '0');
                sc_y_hi_r   <= (others => '0');
                sc_stride_r <= x"40";
                raster_line0_r <= x"FF";
                b2x_lo_r <= (others => '0');
                b2x_hi_r <= (others => '0');
                b2y_lo_r <= (others => '0');
                b2y_hi_r <= (others => '0');
                raster_line1_r <= x"FF";
                b3x_lo_r <= (others => '0');
                b3x_hi_r <= (others => '0');
                b3y_lo_r <= (others => '0');
                b3y_hi_r <= (others => '0');
            elsif cpu_rw = '0' then
                if cpu_addr = x"D804" then
                    sc_x_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D805" then
                    sc_x_hi_r <= cpu_data_in(2 downto 0);
                elsif cpu_addr = x"D806" then
                    sc_y_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D807" then
                    sc_y_hi_r <= cpu_data_in(2 downto 0);
                elsif cpu_addr = x"D808" then
                    sc_stride_r <= cpu_data_in;
                elsif cpu_addr = x"D809" then
                    raster_line0_r <= cpu_data_in;
                elsif cpu_addr = x"D80A" then
                    b2x_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D80B" then
                    b2x_hi_r <= cpu_data_in(2 downto 0);
                elsif cpu_addr = x"D80C" then
                    b2y_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D80D" then
                    b2y_hi_r <= cpu_data_in(2 downto 0);
                elsif cpu_addr = x"D80E" then
                    raster_line1_r <= cpu_data_in;
                elsif cpu_addr = x"D80F" then
                    b3x_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D810" then
                    b3x_hi_r <= cpu_data_in(2 downto 0);
                elsif cpu_addr = x"D811" then
                    b3y_lo_r <= cpu_data_in;
                elsif cpu_addr = x"D812" then
                    b3y_hi_r <= cpu_data_in(2 downto 0);
                end if;
            end if;
        end if;
    end process;

    -- Salidas combinacionales hacia el motor de video
    sc_x_out  <= sc_x_hi_r & sc_x_lo_r;
    sc_y_out  <= sc_y_hi_r & sc_y_lo_r;
    sc_stride <= sc_stride_r;

    -- Split de raster
    rl0_out <= raster_line0_r;
    b2x_out <= b2x_hi_r & b2x_lo_r;
    b2y_out <= b2y_hi_r & b2y_lo_r;
    rl1_out <= raster_line1_r;
    b3x_out <= b3x_hi_r & b3x_lo_r;
    b3y_out <= b3y_hi_r & b3y_lo_r;

    -- ========================================================================
    -- Captura de la escritura del CPU en clk_sys
    --   IMPORTANTE: el CPU mantiene la direccion y r_w durante VARIOS ciclos de
    --   clk_sys (el CPU va a 3,375 MHz y clk_sys a 6,75 MHz). Si el toggle se
    --   invirtiera por NIVEL, se invertiria 2 veces por escritura y volveria a
    --   su estado: el video no veria el flanco y PERDERIA la escritura.
    --   Por eso se detecta el PRIMER ciclo de la escritura (flanco) con
    --   'dat_active_d'.
    -- ========================================================================
    process (clk_sys)
        variable dat_active : std_logic;
        variable pal_active : std_logic;
        variable setup_active : std_logic;
    begin
        if rising_edge(clk_sys) then
            if rst_n = '0' then
                addr_lo_reg <= (others => '0');
                addr_hi_reg <= (others => '0');
                data_reg    <= (others => '0');
                write_req   <= '0';
                dat_active_d <= '0';
                pal_req     <= '0';
                pal_active_d <= '0';
                pal_ptr_s   <= (others => '0');
                setup_req    <= '0';
                setup_active_d <= '0';
            else
                -- '1' si el CPU esta escribiendo AHORA en VID_DATA
                if cpu_rw = '0' and is_vid_dat = '1' then
                    dat_active := '1';
                else
                    dat_active := '0';
                end if;

                -- '1' si el CPU esta escribiendo AHORA en PAL_HI ($D815)
                if cpu_rw = '0' and is_vid_pal = '1' then
                    pal_active := '1';
                else
                    pal_active := '0';
                end if;

                -- '1' si el CPU esta escribiendo AHORA en SETUP ($D816)
                if cpu_rw = '0' and is_vid_setup = '1' then
                    setup_active := '1';
                else
                    setup_active := '0';
                end if;

                if cpu_rw = '0' and is_vid_lo = '1' then
                    addr_lo_reg <= cpu_data_in;
                elsif cpu_rw = '0' and is_vid_hi = '1' then
                    addr_hi_reg <= cpu_data_in;
                elsif cpu_rw = '0' and cpu_addr = x"D813" then
                    pal_ptr_r <= cpu_data_in(4 downto 0);
                elsif cpu_rw = '0' and cpu_addr = x"D814" then
                    pal_lo_r <= cpu_data_in;
                end if;

                -- Escritura de VID_DATA: solo en el PRIMER ciclo (flanco 0->1)
                if (dat_active = '1') and (dat_active_d = '0') then
                    data_reg  <= cpu_data_in;
                    write_req <= not write_req;   -- toggle: UNA vez por escritura
                end if;
                dat_active_d <= dat_active;

                -- Escritura de PAL_HI ($D815): en el PRIMER ciclo -> latchear
                -- el puntero actual y el color, disparar el toggle y auto-incrementar.
                if (pal_active = '1') and (pal_active_d = '0') then
                    pal_hi_r  <= cpu_data_in(3 downto 0);  -- color[11:8]
                    pal_ptr_s <= pal_ptr_r;               -- puntero de esta entrada
                    pal_ptr_r <= std_logic_vector(unsigned(pal_ptr_r) + 1);
                    pal_req   <= not pal_req;             -- toggle: UNA vez
                end if;
                pal_active_d <= pal_active;

                -- SETUP ($D816): en el PRIMER ciclo -> toggle (UNA vez)
                if (setup_active = '1') and (setup_active_d = '0') then
                    setup_req <= not setup_req;
                end if;
                setup_active_d <= setup_active;

                -- lectura del STATUS: dispara la limpieza de flags sticky
                if (cpu_rw = '1') and (is_vid_st = '1') then
                    clear_tgl <= not clear_tgl;
                end if;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Sincronizacion del toggle al dominio clk_vid (3 etapas + deteccion flanco)
    -- ========================================================================
    process (clk_vid)
    begin
        if rising_edge(clk_vid) then
            if rst_n = '0' then
                wr_sync1 <= '0';
                wr_sync2 <= '0';
                wr_sync3 <= '0';
                write_pulse <= '0';
                ct_s1 <= '0';
                ct_s2 <= '0';
                ct_s3 <= '0';
                clear_stats <= '0';
                pal_sync1 <= '0';
                pal_sync2 <= '0';
                pal_sync3 <= '0';
                pal_wr_out <= '0';
                pal_ptr_v  <= (others => '0');
                pal_ptr_v2 <= (others => '0');
                pal_lo_v   <= (others => '0');
                pal_lo_v2  <= (others => '0');
                pal_hi_v   <= (others => '0');
                pal_hi_v2  <= (others => '0');
                setup_sync1 <= '0';
                setup_sync2 <= '0';
                setup_req_out <= '0';
            else
                wr_sync1 <= write_req;
                wr_sync2 <= wr_sync1;
                wr_sync3 <= wr_sync2;

                if wr_sync2 /= wr_sync3 then
                    write_pulse <= '1';
                else
                    write_pulse <= '0';
                end if;

                -- PALETA: sincronizar ptr/lo/hi (2FF) y detector de flanco del toggle
                pal_ptr_v  <= pal_ptr_s;
                pal_ptr_v2 <= pal_ptr_v;
                pal_lo_v   <= pal_lo_r;
                pal_lo_v2  <= pal_lo_v;
                pal_hi_v   <= pal_hi_r;
                pal_hi_v2  <= pal_hi_v;

                pal_sync1 <= pal_req;
                pal_sync2 <= pal_sync1;
                pal_sync3 <= pal_sync2;
                if pal_sync2 /= pal_sync3 then
                    pal_wr_out <= '1';
                else
                    pal_wr_out <= '0';
                end if;

                -- limpieza de status (toggle sincronizado + deteccion de flanco)
                ct_s1 <= clear_tgl;
                ct_s2 <= ct_s1;
                ct_s3 <= ct_s2;
                if ct_s2 /= ct_s3 then
                    clear_stats <= '1';
                else
                    clear_stats <= '0';
                end if;

                -- SETUP: sincronizar el toggle (2FF) y detectar flanco -> pulso.
                --   2 etapas + registro de pulso: suficiente para el cruce
                --   lento (clk_sys 6.75 MHz -> clk_vid 27 MHz).
                setup_sync1 <= setup_req;
                setup_sync2 <= setup_sync1;
                if setup_sync1 /= setup_sync2 then
                    setup_req_out <= '1';
                else
                    setup_req_out <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Salidas de paleta (latch del puntero sincronizado)
    pal_ptr_out <= pal_ptr_v2;
    pal_lo_out  <= pal_lo_v2;
    pal_hi_out  <= pal_hi_v2;

    -- ========================================================================
    -- Salidas hacia el motor de video
    --   area   = addr_hi_reg(7 downto 6)
    --   pat_hi = addr_hi_reg(5)
    --   addr   = addr_hi_reg(2 downto 0) & addr_lo_reg  (11 bits = 3 + 8)
    --
    --   La direccion de VRAM son 11 bits (0..2047). El byte alto aporta los
    --   3 bits superiores (bits 10..8), el byte bajo los 8 inferiores.
    -- ========================================================================
    vid_we   <= write_pulse;
    vid_area <= addr_hi_reg(7 downto 6);
    vid_addr <= addr_hi_reg(2 downto 0) & addr_lo_reg;
    vid_data <= data_reg;
    vid_hi   <= addr_hi_reg(5);
    vid_spr  <= addr_hi_reg(3);   -- area 11: 1 = patron sprite, 0 = OAM

    -- ========================================================================
    -- Lectura del STATUS por el CPU (r_w=1)
    --   $D803: status del video (VBLANK/OVERFLOW/HIT/READY)
    --   $D817: status del setup -> bit0 = BUSY, bit4 = VIDEO_READY
    --   En cualquier otro caso, alta impedancia.
    -- ========================================================================
    cpu_data_out <= status_in when (cpu_rw = '1' and is_vid_st = '1')
                    else ("000" & (not setup_busy_in) & "000" & setup_busy_in)
                         when (cpu_rw = '1' and is_vid_setupst = '1')
                    else (others => 'Z');

end architecture;
