-- ============================================================================
-- video_core.vhd  --  Motor de video por TILES desde BSRAM (Fase 3 validada)
--
-- MODELO: coprocesador grafico tipo VIC-II/NES. NO hay framebuffer de pixeles:
-- el motor lee el tilemap y los patrones desde la BSRAM y genera los pixeles al
-- vuelo.
--
-- GEOMETRIA (congelada):
--   Timing de barrido : 858 x 525 @ 27 MHz  ->  720x480 @ 60 Hz
--   Zona util         : 640 x 480, centrada (40 px de margen por lado)
--   Margen            : color de fondo (BG_COLOR)
--   Resolucion logica : 320 x 240      (escalado x2)
--   Celdas            : 40 x 30 tiles de 8x8
--
-- PIPELINE DE FETCH (2 etapas, latencia fija, sin maquina de estados):
--
--   ciclo n-2 : cell_addr = celda de x0(n-2)   -> tilemap + attr   (BSRAM A)
--   ciclo n-1 : tile_dout = tile[celda]        -> pat_addr          (BSRAM B)
--   ciclo n   : pat_dout  = patron de ese tile -> pixel             (salida)
--
--   Para alinear la salida se retrasan 2 ciclos: el indice de bit (bitidx2),
--   el margen (margen2) y las sincronias (hs2/vs2/de2). El color de la celda
--   (attr_d1) se retrasa 1 ciclo porque la BSRAM ya entrega su salida
--   registrada. El resultado es un desplazamiento horizontal de 1 pixel
--   logico, absorbido por los 40 px de margen. No hay desplazamiento vertical.
--
--   Esta es la tecnica que RESOLVIO el bloqueo de las fases anteriores:
--   SIEMPRE se presenta una direccion por ciclo (direccion calculada de la
--   posicion actual) y se retrasa la salida, en lugar de encadenar maquinas
--   de estado con esperas. Es imposible desalinear el pipeline.
--
-- Los 4 patrones de la Fase 2 (damero, marco, diagonal, solido) se cargan
-- en la BSRAM y se dibujan como tiles reales sobre un tilemap 40x30.
--
-- FASE 4 (proxima): esta version NO tiene aun el bus del CPU. Solo es la
-- referencia visual validada en hardware. La ruta CPU->VRAM se anade encima,
-- multiplexando el puerto A de la VRAM (inicializacion vs. CPU), todo en el
-- mismo dominio clk_pixel para no violar la regla de reloj unico de BSRAM.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_core is
    port (
        clk_27      : in  std_logic;
        rst_n       : in  std_logic;

        -- Escritura desde el CPU (ya sincronizada por video_bus: pulso de
        -- 1 ciclo de clk_vid, con area/dir/dato estables).
        vid_we      : in  std_logic;
        vid_area    : in  std_logic_vector(1 downto 0);
        vid_addr    : in  std_logic_vector(10 downto 0);
        vid_data    : in  std_logic_vector(7 downto 0);
        vid_hi      : in  std_logic;
        vid_spr     : in  std_logic;   -- area 11: 1 = patron sprite, 0 = OAM

        -- Registros de SCROLL (escritos por el CPU, dominio de video)
        sc_x_in     : in  std_logic_vector(10 downto 0);  -- offset X (0..2047)
        sc_y_in     : in  std_logic_vector(10 downto 0);  -- offset Y (0..2047)
        sc_we       : in  std_logic;                      -- pulso: cargar scroll
        sc_stride   : in  std_logic_vector(7 downto 0);   -- ancho del mapa

        -- Split de raster (Fase 8), hasta 3 bandas:
        --   raster_line0 : fin de la banda SUPERIOR (banda 2). $FF = sin banda top.
        --   band2_x/y   : scroll de la banda SUPERIOR.
        --   raster_line1 : fin de la banda MEDIA. $FF = sin banda bottom.
        --   band3_x/y   : scroll de la banda INFERIOR.
        --   La banda MEDIA usa el scroll NORMAL (sc_x_in/sc_y_in).
        raster_line0 : in  std_logic_vector(7 downto 0);
        band2_x     : in  std_logic_vector(10 downto 0);
        band2_y     : in  std_logic_vector(10 downto 0);
        raster_line1 : in  std_logic_vector(7 downto 0);
        band3_x     : in  std_logic_vector(10 downto 0);
        band3_y     : in  std_logic_vector(10 downto 0);

        -- Status del video (registro de LECTURA $D803)
        --   bit 7 = VBLANK, bit 6 = SPRITE_OVERFLOW, bit 5 = HIT,
        --   bit 4 = VIDEO_READY (1 = inicializacion de VRAM terminada)
        status_out  : out std_logic_vector(7 downto 0);
        clear_stats : in  std_logic;   -- 1 = limpiar flags sticky (al leer)

        tmds_c0_p   : out std_logic;
        tmds_c0_n   : out std_logic;
        tmds_c1_p   : out std_logic;
        tmds_c1_n   : out std_logic;
        tmds_c2_p   : out std_logic;
        tmds_c2_n   : out std_logic;
        tmds_ck_p   : out std_logic;
        tmds_ck_n   : out std_logic
    );
end entity;

architecture rtl of video_core is

    signal clk_pixel  : std_logic;
    signal clk_serial : std_logic;

    -- ========================================================================
    -- TIMING DE BARRIDO - CONGELADO (858 x 525)
    -- ========================================================================
    constant H_VISIBLE  : integer := 720;
    constant H_SYNC_ON  : integer := 736;
    constant H_SYNC_OFF : integer := 798;
    constant H_TOTAL    : integer := 858;

    constant V_VISIBLE  : integer := 480;
    constant V_SYNC_ON  : integer := 489;
    constant V_SYNC_OFF : integer := 495;
    constant V_TOTAL    : integer := 525;

    constant BG_COLOR   : std_logic_vector(23 downto 0) := x"4080C0";  -- azul cielo

    signal h_cnt : unsigned(9 downto 0) := (others => '0');
    signal v_cnt : unsigned(9 downto 0) := (others => '0');

    -- ========================================================================
    -- SCROLL (Fase 6)
    --   scroll_x / scroll_y : desplazamiento de la camara (en pixeles).
    --   map_stride          : ancho del mapa en celdas (paso de fila).
    --   El CPU los escribe via video_bus ($D804/$D805/$D806).
    -- ========================================================================
    signal scroll_x   : unsigned(10 downto 0) := (others => '0');
    signal scroll_y   : unsigned(10 downto 0) := (others => '0');
    signal map_stride : unsigned(7 downto 0) := to_unsigned(64, 8);

    -- sincronizacion de los registros de scroll (clk_sys -> clk_pixel)
    signal scx_s1, scx_s2 : std_logic_vector(10 downto 0) := (others => '0');
    signal scy_s1, scy_s2 : std_logic_vector(10 downto 0) := (others => '0');
    signal scs_s1, scs_s2 : std_logic_vector(7 downto 0) := x"40";

    -- split de raster (sincronizado)
    signal rl0_s1, rl0_s2 : std_logic_vector(7 downto 0) := x"FF";
    signal b2x_s1, b2x_s2 : std_logic_vector(10 downto 0) := (others => '0');
    signal b2y_s1, b2y_s2 : std_logic_vector(10 downto 0) := (others => '0');
    signal rl1_s1, rl1_s2 : std_logic_vector(7 downto 0) := x"FF";
    signal b3x_s1, b3x_s2 : std_logic_vector(10 downto 0) := (others => '0');
    signal b3y_s1, b3y_s2 : std_logic_vector(10 downto 0) := (others => '0');

    -- banda activa (0 = superior usa band2,
    --                1 = media usa scroll normal,
    --                2 = inferior usa band3)
    signal band_idx       : unsigned(1 downto 0) := "00";

    signal hs : std_logic := '1';
    signal vs : std_logic := '1';
    signal de : std_logic := '0';
    signal margen : std_logic := '0';

    -- ========================================================================
    -- POSICION LOGICA (combinacional, calculada de h_cnt/v_cnt)
    -- ========================================================================
    signal x0_log : unsigned(8 downto 0) := (others => '0');
    signal y0_log : unsigned(8 downto 0) := (others => '0');
    signal x0_world : unsigned(10 downto 0) := (others => '0');
    signal y0_world : unsigned(10 downto 0) := (others => '0');

    -- ========================================================================
    -- DIRECCIONAMIENTO DE CELDA
    -- ========================================================================
    signal x_cell    : unsigned(7 downto 0) := (others => '0');
    signal y_cell    : unsigned(7 downto 0) := (others => '0');
    signal cell_addr : unsigned(10 downto 0) := (others => '0');

    -- ========================================================================
    -- SALIDAS DE LA VRAM (puerto B, 1 ciclo de latencia)
    -- ========================================================================
    signal tile_dout : std_logic_vector(7 downto 0)  := (others => '0');
    signal attr_dout : std_logic_vector(7 downto 0)  := (others => '0');
    signal pat_dout  : std_logic_vector(15 downto 0) := (others => '0');

    -- salida del banco de fuente (1bpp). Lo usa la fase de init para
    -- expandir la fuente a pat_arr. El CPU no lo lee.
    signal font_dout      : std_logic_vector(8 downto 0) := (others => '0');

    -- ========================================================================
    -- PIPELINE - ETAPA 1
    -- ========================================================================
    signal row_t1   : unsigned(2 downto 0) := (others => '0');
    signal bitidx1  : unsigned(2 downto 0) := (others => '0');
    signal attr_d1  : std_logic_vector(1 downto 0) := (others => '0');
    signal margen1  : std_logic := '0';
    signal hs1, vs1, de1 : std_logic := '1';

    signal pat_addr : unsigned(10 downto 0) := (others => '0');

    -- ========================================================================
    -- PIPELINE - ETAPA 2
    -- ========================================================================
    signal bitidx2  : unsigned(2 downto 0) := (others => '0');
    signal margen2  : std_logic := '0';
    signal hs2, vs2, de2 : std_logic := '1';

    -- ========================================================================
    -- COLOR
    -- ========================================================================
    signal pixcode : std_logic_vector(1 downto 0) := (others => '0');
    signal pal_idx : std_logic_vector(3 downto 0) := (others => '0');
    signal pal_rgb : std_logic_vector(11 downto 0) := (others => '0');
    signal rgb24   : std_logic_vector(23 downto 0) := (others => '0');

    type pal_t is array (0 to 15) of std_logic_vector(11 downto 0);
    -- Paletas de FONDO (índice = paleta[3:2] + color[1:0]).
    --
    --   La fuente se expande con COLOR 3, asi que el color 3 de cada paleta
    --   define el color del TEXTO. Los colores 1 y 2 sirven para los TILES.
    --
    --   paleta 0: TEXTO BLANCO  (negro/azul/cian/BLANCO)
    --   paleta 1: TEXTO AMARILLO(negro/rojo/verde/AMARILLO)
    --   paleta 2: TEXTO CIAN   (negro/magenta/naranja/CIAN)
    --   paleta 3: TEXTO VERDE  (negro/gris/marron/VERDE)
    constant PALETTE : pal_t := (
        x"000", x"00A", x"0CF", x"FFF",   -- paleta 0 - TEXTO / cielo (azul / cian / blanco)
        x"000", x"A62", x"AAA", x"FFF",   -- paleta 1 - TERRENO (tierra marron / piedra gris / blanco)
        x"000", x"0A0", x"060", x"0F0",   -- paleta 2 - VEGETACION (verde / verde oscuro / verde)
        x"000", x"888", x"840", x"0F0"    -- paleta 3 - TEXTO VERDE
    );

    -- Paletas de SPRITE (índice = paleta[3:2] + color[1:0]).
    -- El color 0 (transparente) de cada paleta se ignora en el render.
    --   Paleta 0: pensada para personajes -> piel / marron / negro
    --             (indice 1 = piel rojiza, 2 = marron, 3 = negro)
    constant SPR_PALETTE : pal_t := (
        x"000", x"F80", x"840", x"000",   -- paleta 0 - piel / marron / negro
        x"000", x"00F", x"0FF", x"FFF",   -- paleta 1 - azul / cian / blanco
        x"000", x"F0F", x"F00", x"FFF",   -- paleta 2 - magenta / rojo / blanco
        x"000", x"0F0", x"F80", x"FFF"    -- paleta 3 - verde / naranja / blanco
    );

    -- ========================================================================
    -- INICIALIZACION DE LA VRAM
    -- ========================================================================
    signal init_phase : integer range 0 to 4 := 0;
    signal init_cnt   : integer range 0 to 2047 := 0;
    signal col_cnt    : integer range 0 to 63 := 0;
    signal init_done  : std_logic := '0';

    -- fase 4: expansion de la fuente (font_arr 1bpp -> pat_arr 2bpp)
    signal font_init_addr : unsigned(9 downto 0) := (others => '0');
    -- relleno de BIT 0 (plano0) y BIT 1 (plano1): por color 1..3
    type mask4_t is array (0 to 3) of std_logic_vector(7 downto 0);
    constant MASK_LO : mask4_t := (x"00", x"FF", x"00", x"FF");
    constant MASK_HI : mask4_t := (x"00", x"00", x"FF", x"FF");
    -- color de la fuente expandida y retardo de direccion (latencia BSRAM)
    signal font_color : std_logic_vector(1 downto 0) := "11";   -- blanco
    signal font_row_d : std_logic_vector(7 downto 0) := (others => '0');
    signal font_pa_d  : std_logic := '0';
    signal font_cnt_d : unsigned(10 downto 0) := (others => '0');
    signal font_cnt_d2 : unsigned(10 downto 0) := (others => '0');

    signal wr_tile : std_logic := '0';
    signal wr_attr : std_logic := '0';
    signal wr_pat  : std_logic := '0';
    signal wr_spr  : std_logic := '0';
    signal wr_addr : std_logic_vector(10 downto 0) := (others => '0');
    signal wr_data : std_logic_vector(15 downto 0) := (others => '0');

    -- ========================================================================
    -- ESCRITURA DEL CPU (Fase 4, Opcion B)
    --   El CPU escribe 1 byte a la vez. Para los patrones (palabras de 16 bits:
    --   plano 0 en el byte bajo, plano 1 en el byte alto), se retiene el byte
    --   bajo en 'pat_lo' y, al llegar vid_hi=1, se escribe la palabra entera.
    --   Para tilemap/atributos (areas 00/01), el byte se escribe directo en el
    --   byte bajo de la palabra.
    -- ========================================================================
    signal cpu_we_tile : std_logic := '0';
    signal cpu_we_attr : std_logic := '0';
    signal cpu_we_pat  : std_logic := '0';
    signal cpu_we_spr  : std_logic := '0';
    signal cpu_wr_addr : std_logic_vector(10 downto 0) := (others => '0');
    signal cpu_wr_data : std_logic_vector(15 downto 0) := (others => '0');
    signal pat_lo      : std_logic_vector(7 downto 0) := (others => '0');
    signal spr_lo      : std_logic_vector(7 downto 0) := (others => '0');

    -- ========================================================================
    -- OAM EN REGISTROS (Fase 5 ampliada) -- no consume BSRAM
    --   32 sprites de 8x8. Cada sprite ocupa 5 bytes:
    --     +0 X (0..255), +1 Y (0..255), +2 TILE, +3 FLAGS, +4 COLL_POINT
    --   FLAGS: bit7 FLIP_Y, bit6 FLIP_X, bit5 PRIO, bit4 SCALE2X, bits3:0 PALETA.
    --   COLL_POINT: punto de colision sprite<->tile. byte = dy(7:4) & dx(3:0)?
    --               Se usa offset libre: bits 2:0 = dx (0..7), bits 5:3 = dy (0..7).
    --   160 registros de 8 bits.
    -- ========================================================================
    type oam_t is array (0 to 159) of std_logic_vector(7 downto 0);
    signal oam_reg : oam_t := (others => (others => '0'));

    -- ========================================================================
    -- LINE BUFFER DE SPRITES (hasta 8 sprites por linea)
    --   Durante el blank se recolectan los sprites que cruzan la linea; luego,
    --   en el barrido visible, se comparan todos contra el pixel actual.
    --   Cada entrada: X, tile, paleta, fila (todo en registros).
    -- ========================================================================
    constant NSL : integer := 8;   -- sprites maximos por linea

    type lb_x_t   is array (0 to NSL-1) of unsigned(7 downto 0);
    -- attr: tile(6) + prio(1) + flipx(1) + flipy(1) + pal(3 rsv) = 12 bits
    --   bit 11..6 = tile
    --   bit 5     = prio
    --   bit 4     = flipx
    --   bit 3     = flipy
    --   bit 2..0  = reservado (paleta se guarda aparte para simplificar)
    type lb_attr_t is array (0 to NSL-1) of std_logic_vector(11 downto 0);
    type lb_pal_t  is array (0 to NSL-1) of std_logic_vector(3 downto 0);
    type lb_row_t is array (0 to NSL-1) of unsigned(2 downto 0);
    type lb_scale_t is array (0 to NSL-1) of std_logic;   -- 1 = sprite a 2x

    signal lb_x    : lb_x_t := (others => (others => '0'));
    signal lb_attr : lb_attr_t := (others => (others => '0'));
    signal lb_pal  : lb_pal_t := (others => (others => '0'));
    signal lb_row  : lb_row_t := (others => (others => '0'));
    signal lb_scale: lb_scale_t := (others => '0');
    signal lb_n    : unsigned(3 downto 0) := (others => '0');  -- cuantos hay

    -- Indicador de "line buffer listo": se pone a 1 cuando el barrido del OAM
    -- ha terminado (oam_scan >= 32). Mientras esta a 0, la Fase 2 NO debe leer
    -- el buffer (contiene datos de la linea anterior / basura).
    signal lb_ready : std_logic := '0';

    -- Barrido del OAM para llenar el line buffer
    signal lb_slot  : unsigned(3 downto 0) := (others => '0');
    signal oam_scan : unsigned(5 downto 0) := (others => '0');  -- 0..32

    -- Seleccion durante el barrido visible: se elige el sprite de mayor
    -- prioridad (menor indice en el line buffer) que cubre el pixel actual.
    signal lb_pick_x    : unsigned(7 downto 0) := (others => '0');
    signal lb_pick_tile : std_logic_vector(5 downto 0) := (others => '0');
    signal lb_pick_pal  : std_logic_vector(3 downto 0) := (others => '0');
    signal lb_pick_row  : unsigned(2 downto 0) := (others => '0');
    signal lb_pick_prio : std_logic := '0';   -- 1 = sprite DETRAS del fondo
    signal lb_pick_fx   : std_logic := '0';   -- flip X
    signal lb_pick_fy   : std_logic := '0';   -- flip Y
    signal lb_pick_scale: std_logic := '0';   -- 1 = dibujar a 2x
    signal lb_pick_ok   : std_logic := '0';

    -- Version RETRASADA 1 ciclo de la seleccion, para alinear con spr_pat_data
    -- (la BSRAM de patrones tiene 1 ciclo de latencia; sin este retardo, en el
    --  borde entre dos sprites distintos se mezcla el patron de uno con la X
    --  del otro -> linea de 1 pixel entre sprites compuestos).
    signal lb_pick_x_d    : unsigned(7 downto 0) := (others => '0');
    signal lb_pick_fx_d   : std_logic := '0';
    signal lb_pick_scale_d: std_logic := '0';
    signal lb_pick_ok_d   : std_logic := '0';
    signal x0_log_d       : unsigned(8 downto 0) := (others => '0');
    -- paleta del sprite retrasada 2 ciclos (etapa B), para alinear con
    -- spr_pixcode1 / spr_active1. Sin esto, la paleta (combinacional) se
    -- combinaba con un pixel de 2 ciclos antes -> parte del sprite cambiaba
    -- de color y parte no.
    signal spr_pal_a      : std_logic_vector(3 downto 0) := (others => '0');
    signal spr_pal_b      : std_logic_vector(3 downto 0) := (others => '0');

    signal line_y       : unsigned(7 downto 0) := (others => '0');

    -- ========================================================================
    -- COLISION SPRITE <-> TILE SOLIDO (punto = centro del sprite)
    --   Durante el blanking vertical se recorren los 32 sprites y, para cada
    --   uno, se lee el atributo de la celda donde cae su CENTRO. Si el bit 4
    --   (SOLIDO) esta a 1, se marca el flag de colision de ese sprite.
    -- ========================================================================
    signal coll_phase    : integer range 0 to 1 := 0;   -- 0=idle, 1=barrido
    signal coll_idx      : unsigned(5 downto 0) := (others => '0');  -- 0..32
    signal coll_addr     : unsigned(10 downto 0) := (others => '0');
    signal coll_pending  : std_logic := '0';    -- lectura de atributo en curso
    signal coll_flag     : std_logic_vector(31 downto 0) := (others => '0');
    signal attr_rd_addr  : unsigned(10 downto 0) := (others => '0');
    signal solid_hit     : std_logic := '0';   -- OR de coll_flag

    -- Patron del sprite (banco spr_pat de 64 patrones de 8x8)
    signal spr_pat_addr : unsigned(8 downto 0) := (others => '0');   -- 0..511
    signal spr_pat_data : std_logic_vector(15 downto 0) := (others => '0');

    -- Pixel de sprite, alineado al pipeline del fondo
    signal spr_pixcode  : std_logic_vector(1 downto 0) := (others => '0');
    signal spl_pal_sel2 : std_logic_vector(1 downto 0) := (others => '0');
    signal spr_pal_idx  : std_logic_vector(3 downto 0) := (others => '0');
    signal spr_rgb      : std_logic_vector(11 downto 0) := (others => '0');
    signal spr_active   : std_logic := '0';
    signal spr_active1  : std_logic := '0';
    signal spr_pixcode1 : std_logic_vector(1 downto 0) := (others => '0');
    signal spr_prio1    : std_logic := '0';
    signal spr_prio2    : std_logic := '0';

    -- ========================================================================
    -- STATUS (registro de lectura $D803)
    --   VBLANK    : 1 mientras el barrido esta fuera de la zona visible
    --   OVERFLOW  : 1 si hubo mas sprites que huecos en el line buffer (sticky)
    --   HIT       : 1 si dos sprites solaparon en pantalla (sticky)
    --   Los bits sticky se limpian al leer el registro (gestionado en video_bus).
    -- ========================================================================
    signal vblank_f     : std_logic := '0';
    signal overflow_f   : std_logic := '0';
    signal overflow_now : std_logic := '0';
    signal status_reg   : std_logic_vector(7 downto 0) := (others => '0');

    -- ========================================================================
    -- COMPONENTES
    -- ========================================================================
    component hdmi_module
        port (
            vga_clk_x5      : in  std_logic;
            vga_clk         : in  std_logic;
            vga_red_in      : in  std_logic_vector(7 downto 0);
            vga_green_in    : in  std_logic_vector(7 downto 0);
            vga_blue_in     : in  std_logic_vector(7 downto 0);
            vga_hsync_in    : in  std_logic;
            vga_vsync_in    : in  std_logic;
            vga_disp_ena_in : in  std_logic;
            tmds_c0_p_out   : out std_logic;
            tmds_c0_n_out   : out std_logic;
            tmds_c1_p_out   : out std_logic;
            tmds_c1_n_out   : out std_logic;
            tmds_c2_p_out   : out std_logic;
            tmds_c2_n_out   : out std_logic;
            tmds_ck_p_out   : out std_logic;
            tmds_ck_n_out   : out std_logic
        );
    end component;

    component clk_27x5
        port (
            clkout  : out std_logic;
            clkoutp : out std_logic;
            clkin   : in  std_logic
        );
    end component;

begin

    clk_pixel <= clk_27;

    pll_x5 : clk_27x5
        port map (
            clkout  => clk_serial,
            clkoutp => open,
            clkin   => clk_27
        );

    -- ========================================================================
    -- CONTADORES DE TIMING
    -- ========================================================================
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                h_cnt <= (others => '0');
                v_cnt <= (others => '0');
            else
                if h_cnt = H_TOTAL - 1 then
                    h_cnt <= (others => '0');
                    if v_cnt = V_TOTAL - 1 then
                        v_cnt <= (others => '0');
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    hs     <= '0' when (h_cnt >= H_SYNC_ON) and (h_cnt <= H_SYNC_OFF) else '1';
    vs     <= '0' when (v_cnt >= V_SYNC_ON) and (v_cnt <= V_SYNC_OFF) else '1';
    de     <= '1' when (h_cnt < H_VISIBLE) and (v_cnt < V_VISIBLE) else '0';
    margen <= '1' when (h_cnt < 40) or (h_cnt >= 680) else '0';

    -- ========================================================================
    -- POSICION LOGICA (combinacional, acotada) + SCROLL
    --   x0_world / y0_world : posicion en el MUNDO = pantalla + scroll.
    --   Para el sprite/celda se usa la posicion de MUNDO (asi el fondo se
    --   desplaza con la camara). Los sprites siguen en coordenadas de PANTALLA.
    -- ========================================================================
    -- sincronizacion de los registros de scroll (doble flop, clk_sys -> clk_pixel)
    --   y CAPTURA al inicio de frame: asi el scroll es ESTABLE durante todo el
    --   barrido (si cambiara a mitad de linea, el motor leeria celdas mezcladas
    --   y la imagen se romperia).
    process (clk_pixel)
        variable vline : integer;
    begin
        if rising_edge(clk_pixel) then
            scx_s1 <= sc_x_in;
            scx_s2 <= scx_s1;
            scy_s1 <= sc_y_in;
            scy_s2 <= scy_s1;
            scs_s1 <= sc_stride;
            scs_s2 <= scs_s1;
            rl0_s1 <= raster_line0;
            rl0_s2 <= rl0_s1;
            b2x_s1 <= band2_x;
            b2x_s2 <= b2x_s1;
            b2y_s1 <= band2_y;
            b2y_s2 <= b2y_s1;
            rl1_s1 <= raster_line1;
            rl1_s2 <= rl1_s1;
            b3x_s1 <= band3_x;
            b3x_s2 <= b3x_s1;
            b3y_s1 <= band3_y;
            b3y_s2 <= b3y_s1;

            vline := to_integer(v_cnt(9 downto 1));

            -- TRANSICIONES DE BANDA en el ULTIMO ciclo de cada linea
            --   (h_cnt = H_TOTAL-1), para que el prefetch de la linea siguiente
            --   ya use el scroll/banda correctos.

            -- Final del frame: volver a banda 0 (superior).
            if (h_cnt = H_TOTAL - 1) and (v_cnt = V_TOTAL - 1) then
                map_stride <= unsigned(scs_s2);
                if (rl0_s2 = x"FF") then
                    band_idx <= "01";
                    scroll_x <= unsigned(scx_s2);
                    scroll_y <= unsigned(scy_s2);
                else
                    band_idx <= "00";
                    scroll_x <= unsigned(b2x_s2);
                    scroll_y <= unsigned(b2y_s2);
                end if;
            -- Banda MEDIA (1): cruzar raster_line0.
            elsif (h_cnt = H_TOTAL - 1) and (v_cnt < V_VISIBLE) and (band_idx = "00") and
                  (rl0_s2 /= x"FF") and (vline >= to_integer(unsigned(rl0_s2))) then
                band_idx <= "01";
                scroll_x <= unsigned(scx_s2);
                scroll_y <= unsigned(scy_s2);
            -- Banda INFERIOR (2): cruzar raster_line1.
            elsif (h_cnt = H_TOTAL - 1) and (v_cnt < V_VISIBLE) and (band_idx = "01") and
                  (rl1_s2 /= x"FF") and (vline >= to_integer(unsigned(rl1_s2))) then
                band_idx <= "10";
                scroll_x <= unsigned(b3x_s2);
                scroll_y <= unsigned(b3y_s2);
            end if;
        end if;
    end process;

    process (h_cnt, v_cnt, scroll_x, scroll_y)
        variable xi : integer;
        variable yi : integer;
    begin
        xi := to_integer(h_cnt(9 downto 1));
        if xi <= 20 then
            x0_log <= (others => '0');
        elsif xi >= 340 then
            x0_log <= to_unsigned(319, 9);
        else
            x0_log <= to_unsigned(xi - 20, 9);
        end if;

        yi := to_integer(v_cnt(9 downto 1));
        if yi > 239 then
            y0_log <= to_unsigned(239, 9);
        else
            y0_log <= to_unsigned(yi, 9);
        end if;
    end process;

    -- posicion de MUNDO = pantalla + scroll (11 bits, 0..2047)
    x0_world <= resize(x0_log, 11) + scroll_x;
    y0_world <= resize(y0_log, 11) + scroll_y;

    -- ========================================================================
    -- DIRECCION DE CELDA (combinacional) -> tilemap y atributos
    --   MAPA 64x32 (stride 64, potencia de 2 -> multiplicacion = shift, ~0 LUTs)
    --   cell_addr = (y_world/8 mod 32) * 64 + (x_world/8 mod 64)
    --             = (y_cell & x_cell)     (5 bits & 6 bits = 11 bits, 2048 celdas)
    --   El mapa es mas grande que la pantalla (40x30), habilitando scroll
    --   horizontal Y vertical por contenido extra (shooters H y V).
    -- ========================================================================
    x_cell    <= x0_world(10 downto 3) mod 64;
    y_cell    <= y0_world(10 downto 3) mod 32;
    cell_addr <= y_cell(4 downto 0) & x_cell(5 downto 0);

    -- ========================================================================
    -- PIPELINE ETAPA 1
    -- ========================================================================
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            row_t1  <= y0_world(2 downto 0);
            bitidx1 <= x0_world(2 downto 0);
            attr_d1 <= attr_dout(1 downto 0);
            margen1 <= margen;
            hs1 <= hs;
            vs1 <= vs;
            de1 <= de;
        end if;
    end process;

    pat_addr <= shift_left(resize(unsigned(tile_dout), 11), 3) + resize(row_t1, 11);

    -- ========================================================================
    -- PIPELINE ETAPA 2
    -- ========================================================================
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            bitidx2 <= bitidx1;
            margen2 <= margen1;
            hs2 <= hs1;
            vs2 <= vs1;
            de2 <= de1;
        end if;
    end process;

    -- ========================================================================
    -- INICIALIZACION DE LA VRAM
    --   Fase 0: tilemap        -> columna mod 4 (damero, marco, diagonal, solido)
    --   Fase 1: atributos      -> misma paleta que el tile (0..3)
    --   Fase 2: patrones fondo -> 4 tiles x 8 filas = 32 palabras
    --   Fase 3: patron sprite  -> 1 sprite x 8 filas = 8 palabras (un cuadrado)
    -- ========================================================================
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                init_phase <= 0;
                init_cnt   <= 0;
                col_cnt    <= 0;
                init_done  <= '0';
            elsif init_done = '0' then
                if init_phase = 0 then
                    if init_cnt = 1199 then
                        init_phase <= 1;
                        init_cnt   <= 0;
                        col_cnt    <= 0;
                    else
                        init_cnt <= init_cnt + 1;
                        if col_cnt = 39 then
                            col_cnt <= 0;
                        else
                            col_cnt <= col_cnt + 1;
                        end if;
                    end if;
                elsif init_phase = 1 then
                    if init_cnt = 1199 then
                        init_phase <= 2;
                        init_cnt   <= 0;
                    else
                        init_cnt <= init_cnt + 1;
                    end if;
                elsif init_phase = 2 then
                    -- tiles graficos de demo: 8 tiles x 8 filas = 64 filas
                    if init_cnt = 63 then
                        init_phase <= 3;
                        init_cnt   <= 0;
                    else
                        init_cnt <= init_cnt + 1;
                    end if;
                elsif init_phase = 3 then
                    -- 3 patrones de sprite (24 filas, 0..23)
                    if init_cnt = 23 then
                        init_phase <= 4;
                        init_cnt   <= 0;
                    else
                        init_cnt <= init_cnt + 1;
                    end if;
                else
                    -- init_phase = 4: expansion de la FUENTE.
                    -- Se cuentan 772 ciclos: 768 filas utiles + 4 de margen para
                    -- cubrir la latencia de la BSRAM de fuente (2 de entrada,
                    -- 2 de salida) sin perder filas.
                    if init_cnt = 771 then
                        init_done <= '1';
                    else
                        init_cnt <= init_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    wr_tile <= '1' when (init_done = '0') and (init_phase = 0) else '0';
    wr_attr <= '1' when (init_done = '0') and (init_phase = 1) else '0';
    -- fase 2: patrones de tiles 0..3 (en blanco).
    -- fase 4: expansion de la fuente. Solo se escribe mientras el contador
    -- retrasado apunta dentro del rango de la fuente (0..767).
    wr_pat  <= '1' when (init_done = '0') and (init_phase = 2) else
               '1' when (init_done = '0') and (init_phase = 4)
                        and (font_cnt_d2 < 768) else
               '0';
    wr_spr  <= '1' when (init_done = '0') and (init_phase = 3) else '0';

    -- ========================================================================
    -- MUX del puerto A (combinacional): durante init usa init_cnt/dato de init;
    -- despues usa la direccion/dato del CPU, que QUEDAN ASENTADOS en registros
    -- de forma estable mientras cpu_we_* este activo (mismo flanco).
    -- ========================================================================
    -- direccion de LECTURA de la fuente: recorre 0..1023 (char*8+fila)
    font_init_addr <= to_unsigned(init_cnt, 10);

    -- Retardo de 1 ciclo para alinear la LECTURA de la fuente (latencia BSRAM)
    -- con la ESCRITURA en pat_arr: pedimos en N, el dato llega en N+1.
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                font_row_d <= (others => '0');
                font_pa_d  <= '0';
            else
                font_row_d <= font_dout(7 downto 0);
                -- font_row_d captura font_arr[k] en el ciclo k+2; para alinear la
                -- direccion de escritura con ese dato, se retrasa init_cnt DOS
                -- ciclos (font_cnt_d2 = k cuando font_row_d = font_arr[k]).
                font_cnt_d  <= to_unsigned(init_cnt, 11);
                font_cnt_d2 <= font_cnt_d;
                if (init_done = '0') and (init_phase = 4) then
                    font_pa_d <= '1';
                else
                    font_pa_d <= '0';
                end if;
            end if;
        end if;
    end process;

    wr_addr <= std_logic_vector(to_unsigned(init_cnt, 11))
               when (init_done = '0') and (init_phase /= 4) else
               cpu_wr_addr when init_done = '1' else
               -- fase 4: tile = ASCII ($20 + char) -> dir = tile*8 + fila.
               -- Se usa font_cnt_d2 (init_cnt retrasado 2 ciclos) para alinear
               -- con la llegada del dato de la BSRAM de fuente (font_row_d).
               std_logic_vector(to_unsigned(256, 11) + font_cnt_d2);

    process (init_phase, init_cnt, col_cnt, init_done, cpu_wr_data, font_row_d, font_color)
        variable t  : integer range 0 to 7;
        variable r  : integer range 0 to 7;
        variable p0 : std_logic_vector(7 downto 0);
        variable p1 : std_logic_vector(7 downto 0);
    begin
        wr_data <= (others => '0');
        t := 0;
        r := 0;
        p0 := (others => '0');
        p1 := (others => '0');
        if init_done = '1' then
            -- El CPU manda: dato completo de 16 bits.
            wr_data <= cpu_wr_data;
        elsif init_phase = 4 then
            -- FUENTE: expandir el byte 1bpp de font_arr (font_row_d) a 2bpp
            -- planar. El color de la fuente lo elige font_color:
            --   plano0 = byte AND MASK_LO[color]
            --   plano1 = byte AND MASK_HI[color]
            wr_data(7 downto 0)  <= font_row_d and MASK_LO(to_integer(unsigned(font_color)));
            wr_data(15 downto 8) <= font_row_d and MASK_HI(to_integer(unsigned(font_color)));
        elsif init_phase = 3 then
            -- 3 patrones de sprite 8x8, cada uno MULTICOLOR (plano 0 + plano 1).
            --   patron 0 (TILE 0): una "cara" (color 1 = cara, color 2 = ojos)
            --   patron 1 (TILE 1): un rombo (color 1 = borde, color 3 = centro)
            --   patron 2 (TILE 2): una "X" (color 1 = X, color 3 = centro)
            --   plano0 = p0, plano1 = p1. pixcode = p1 & p0 -> color 0..3.
            t := init_cnt / 8;   -- patron 0..2
            r := init_cnt mod 8; -- fila 0..7
            case t is
                when 0 =>        -- CARA
                    case r is
                        when 0 => p0 := x"3C"; p1 := x"00";
                        when 1 => p0 := x"7E"; p1 := x"00";
                        when 2 => p0 := x"FF"; p1 := x"00";
                        when 3 => p0 := x"DB"; p1 := x"24"; -- ojos (color 2)
                        when 4 => p0 := x"FF"; p1 := x"00";
                        when 5 => p0 := x"81"; p1 := x"7E"; -- boca (color 3)
                        when 6 => p0 := x"7E"; p1 := x"00";
                        when others => p0 := x"3C"; p1 := x"00";
                    end case;
                when 1 =>        -- ROMBO
                    case r is
                        when 0 => p0 := x"18"; p1 := x"00";
                        when 1 => p0 := x"3C"; p1 := x"00";
                        when 2 => p0 := x"7E"; p1 := x"00";
                        when 3 => p0 := x"FF"; p1 := x"00";
                        when 4 => p0 := x"7E"; p1 := x"81";
                        when 5 => p0 := x"7E"; p1 := x"00";
                        when 6 => p0 := x"3C"; p1 := x"00";
                        when others => p0 := x"18"; p1 := x"00";
                    end case;
                when others =>   -- X
                    case r is
                        when 0 => p0 := x"81"; p1 := x"00";
                        when 1 => p0 := x"C3"; p1 := x"00";
                        when 2 => p0 := x"66"; p1 := x"00";
                        when 3 => p0 := x"3C"; p1 := x"C3";
                        when 4 => p0 := x"3C"; p1 := x"C3";
                        when 5 => p0 := x"66"; p1 := x"00";
                        when 6 => p0 := x"C3"; p1 := x"00";
                        when others => p0 := x"81"; p1 := x"00";
                    end case;
            end case;
            wr_data(7 downto 0)  <= p0;
            wr_data(15 downto 8) <= p1;
        elsif init_phase < 2 then
            -- tilemap y atributos: fondo de texto.
            --   fase 0 (tilemap)  -> $20 (espacio) = fondo negro liso
            --   fase 1 (attr)     -> 0 = paleta de TEXTO
            if init_phase = 0 then
                wr_data(7 downto 0) <= x"20";
            else
                wr_data(7 downto 0) <= x"00";
            end if;
        else
            -- init_phase = 2: 8 TILES GRAFICOS de demo (tiles $00..$07).
            --   t = tile (0..7), r = fila (0..7). p0 = plano0, p1 = plano1.
            --   p1:p0 = color 0..3.  Formas con fondo (color 0 transparente).
            t := init_cnt / 8;
            r := init_cnt mod 8;
            case t is
                when 0 =>        -- TIERRA solida (color 1) con textura (color 2)
                    case r is
                        when 0 => p0 := x"FF"; p1 := x"00";
                        when 1 => p0 := x"FF"; p1 := x"10";
                        when 2 => p0 := x"FF"; p1 := x"00";
                        when 3 => p0 := x"F7"; p1 := x"00";
                        when 4 => p0 := x"FF"; p1 := x"00";
                        when 5 => p0 := x"EF"; p1 := x"10";
                        when 6 => p0 := x"DF"; p1 := x"00";
                        when others => p0 := x"FF"; p1 := x"00";
                    end case;
                when 1 =>        -- CESPED solido (color 1) con borde (color 2)
                    if (r = 0) or (r = 1) then
                        p0 := x"00"; p1 := x"FF";
                    else
                        p0 := x"FF"; p1 := x"00";
                    end if;
                when 2 =>        -- COPA DE ARBOL (color 1, solida)
                    case r is
                        when 0 => p0 := x"3C"; p1 := x"00";
                        when 1 => p0 := x"7E"; p1 := x"00";
                        when 2 => p0 := x"FF"; p1 := x"00";
                        when 3 => p0 := x"FF"; p1 := x"00";
                        when 4 => p0 := x"FF"; p1 := x"00";
                        when 5 => p0 := x"FF"; p1 := x"00";
                        when 6 => p0 := x"7E"; p1 := x"00";
                        when others => p0 := x"3C"; p1 := x"00";
                    end case;
                when 3 =>        -- TRONCO (color 1 = marron)
                    p0 := x"18"; p1 := x"00";
                when 4 =>        -- NUBE (blanca, forma redondeada)
                    case r is
                        when 0 => p0 := x"00"; p1 := x"00";
                        when 1 => p0 := x"38"; p1 := x"38";
                        when 2 => p0 := x"7C"; p1 := x"7C";
                        when 3 => p0 := x"FE"; p1 := x"FE";
                        when 4 => p0 := x"FF"; p1 := x"FF";
                        when 5 => p0 := x"FF"; p1 := x"FF";
                        when 6 => p0 := x"FE"; p1 := x"FE";
                        when others => p0 := x"7C"; p1 := x"7C";
                    end case;
                when 5 =>        -- PIEDRA (fondo tierra color 1, piedra color 2)
                    case r is
                        when 0 => p0 := x"FF"; p1 := x"00";
                        when 1 => p0 := x"FF"; p1 := x"18";
                        when 2 => p0 := x"FF"; p1 := x"3C";
                        when 3 => p0 := x"FF"; p1 := x"7E";
                        when 4 => p0 := x"FF"; p1 := x"7E";
                        when 5 => p0 := x"FF"; p1 := x"3C";
                        when 6 => p0 := x"FF"; p1 := x"18";
                        when others => p0 := x"FF"; p1 := x"00";
                    end case;
                when 6 =>        -- PIEDRA 2 (color 1 + 2)
                    case r is
                        when 0 => p0 := x"00"; p1 := x"00";
                        when 1 => p0 := x"18"; p1 := x"18";
                        when 2 => p0 := x"3C"; p1 := x"18";
                        when 3 => p0 := x"7E"; p1 := x"18";
                        when 4 => p0 := x"7E"; p1 := x"18";
                        when 5 => p0 := x"3C"; p1 := x"18";
                        when 6 => p0 := x"18"; p1 := x"18";
                        when others => p0 := x"00"; p1 := x"00";
                    end case;
                when others =>   -- MATOJO (color 2, solido)
                    p0 := x"00"; p1 := x"FF";
            end case;
            wr_data(7 downto 0)  <= p0;
            wr_data(15 downto 8) <= p1;
        end if;
    end process;

    -- ========================================================================
    -- LOGICA DE ESCRITURA DEL CPU
    --   vid_we es un pulso de 1 ciclo de clk_pixel. Se registran DIRECTAMENTE
    --   la direccion y el dato de la VRAM en el MISMO flanco en que se activa
    --   el enable de escritura, de modo que la VRAM (que muestrea en ese mismo
    --   flanco) ve la direccion y el dato correctos. Sin registros intermedios
    --   que introduzcan carreras.
    --
    --   areas:
    --     "00" tilemap   -> escritura del byte
    --     "01" atributos -> escritura del byte
    --     "10" patrones fondo -> pat_hi=0 retiene plano 0, pat_hi=1 escribe
    --                             la palabra completa (16 bits)
    --     "11" vid_spr=0  -> OAM (registros, indice = vid_addr[5:0])
    --     "11" vid_spr=1  -> patrones de sprite: pat_hi=0 retiene plano 0,
    --                        pat_hi=1 escribe la palabra completa
    -- ========================================================================
    process (clk_pixel)
        variable we_t   : std_logic;
        variable we_a   : std_logic;
        variable we_p   : std_logic;
        variable we_s   : std_logic;
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                pat_lo      <= (others => '0');
                spr_lo      <= (others => '0');
                cpu_we_tile <= '0';
                cpu_we_attr <= '0';
                cpu_we_pat  <= '0';
                cpu_we_spr  <= '0';
                cpu_wr_addr <= (others => '0');
                cpu_wr_data <= (others => '0');
            else
                we_t := '0';
                we_a := '0';
                we_p := '0';
                we_s := '0';

                if vid_we = '1' then
                    cpu_wr_addr <= vid_addr;

                    if vid_area = "00" then
                        cpu_wr_data <= (15 downto 8 => '0') & vid_data;
                        we_t := '1';
                    elsif vid_area = "01" then
                        cpu_wr_data <= (15 downto 8 => '0') & vid_data;
                        we_a := '1';
                    elsif vid_area = "10" then
                        -- patrones de FONDO
                        if vid_hi = '0' then
                            pat_lo <= vid_data;
                        else
                            cpu_wr_data <= vid_data & pat_lo;
                            we_p := '1';
                        end if;
                    else
                        -- area "11"
                        if vid_spr = '0' then
                            -- OAM (registros, 32 sprites x 5 bytes = 160)
                            oam_reg(to_integer(unsigned(vid_addr(7 downto 0)))) <= vid_data;
                        else
                            -- patrones de SPRITE
                            if vid_hi = '0' then
                                spr_lo <= vid_data;
                            else
                                cpu_wr_data <= vid_data & spr_lo;
                                we_s := '1';
                            end if;
                        end if;
                    end if;
                end if;

                cpu_we_tile <= we_t;
                cpu_we_attr <= we_a;
                cpu_we_pat  <= we_p;
                cpu_we_spr  <= we_s;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- MUX de lectura de atributo: durante el barrido de colision (blanking
    -- vertical) el puerto B lee la celda del CENTRO del sprite; el resto del
    -- tiempo lee la celda del fondo (cell_addr).
    -- ========================================================================
    attr_rd_addr <= coll_addr when (coll_phase = 1) else cell_addr;

    -- ========================================================================
    -- BARRI DO DE COLISION SPRITE<->TILE SOLIDO (punto = centro)
    --   Ocurre una vez por frame, durante el blanking vertical (v_cnt >= V_VISIBLE),
    --   momento en el que el fondo no dibuja y el puerto B de atributos esta libre.
    --   Para cada sprite (0..31):
    --     centro = (sx + 4, sy + 4)  (y el bit 4 del atributo = SOLIDO)
    --     celda = (centro_x/8) + (centro_y/8)*64
    --   La BSRAM de atributo tiene 1 ciclo de latencia: se pide en el ciclo N y
    --   se captura el resultado en N+1.
    -- ========================================================================
    process (clk_pixel)
        variable csx : unsigned(7 downto 0);
        variable csy : unsigned(7 downto 0);
        variable xce : unsigned(5 downto 0);
        variable yce : unsigned(4 downto 0);
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                coll_phase   <= 0;
                coll_idx     <= (others => '0');
                coll_addr    <= (others => '0');
                coll_pending <= '0';
                coll_flag    <= (others => '0');
            elsif coll_phase = 0 then
                -- esperar el inicio del blanking vertical
                if v_cnt = V_VISIBLE and h_cnt = 0 then
                    coll_phase   <= 1;
                    coll_idx     <= (others => '0');
                    coll_pending <= '0';
                    coll_flag    <= (others => '0');
                end if;
            else
                -- coll_phase = 1: barrido de los 32 sprites
                if coll_pending = '1' then
                    -- el dato del atributo ya esta disponible; capturar bit 4
                    if attr_dout(4) = '1' then
                        coll_flag(to_integer(coll_idx - 1)) <= '1';
                    end if;
                    coll_pending <= '0';
                else
                    if coll_idx = 32 then
                        -- fin del barrido
                        coll_phase <= 0;
                    else
                        -- punto de colision configurable por sprite (COLL_POINT, +4)
                        --   bits 2:0 = dx (0..7), bits 5:3 = dy (0..7)
                        --   punto = (sx + dx, sy + dy)
                        csx := unsigned(oam_reg(to_integer(coll_idx) * 5 + 0)) +
                               resize(unsigned(oam_reg(to_integer(coll_idx) * 5 + 4)(2 downto 0)), 8);
                        csy := unsigned(oam_reg(to_integer(coll_idx) * 5 + 1)) +
                               resize(unsigned(oam_reg(to_integer(coll_idx) * 5 + 4)(5 downto 3)), 8);
                        xce := resize(csx srl 3, 6);  -- celda X /8 (6 bits, 0..63)
                        yce := resize(csy srl 3, 5);  -- celda Y /8 (5 bits, 0..31)
                        -- celda = y_celda * 64 + x_celda
                        coll_addr <= yce & xce;
                        coll_pending <= '1';
                        coll_idx <= coll_idx + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- bit global de colision: 1 si cualquier sprite toco un tile solido
    solid_hit <= '1' when (coll_flag /= x"00000000") else '0';

    -- ========================================================================
    -- VRAM
    --   El puerto A se multiplexa: durante la inicializacion (init_done='0')
    --   escribe el bloque de init; despues, el CPU. Como ambos dominios son
    --   el mismo clk_pixel, no hay conflicto de reloj.
    -- ========================================================================
    vram : entity work.video_vram
        port map (
            clk_a   => clk_pixel,
            wr_tile => wr_tile or cpu_we_tile,
            wr_attr => wr_attr or cpu_we_attr,
            wr_pat  => wr_pat  or cpu_we_pat,
            wr_spr  => wr_spr  or cpu_we_spr,
            wr_addr => wr_addr,
            wr_data => wr_data,

            clk_b       => clk_pixel,
            tile_addr_b => std_logic_vector(cell_addr),
            tile_data_b => tile_dout,
            attr_addr_b => std_logic_vector(attr_rd_addr),
            attr_data_b => attr_dout,
            pat_addr_b  => std_logic_vector(pat_addr),
            pat_data_b  => pat_dout,
            spr_addr_b  => std_logic_vector(spr_pat_addr),
            spr_data_b  => spr_pat_data,

            font_addr_b => std_logic_vector(font_init_addr),
            font_data_b => font_dout
        );

    -- ========================================================================
    -- EXTRACCION DEL PIXEL
    -- ========================================================================
    pixcode <= pat_dout(15 - to_integer(bitidx2)) & pat_dout(7 - to_integer(bitidx2));
    pal_idx <= attr_d1 & pixcode;
    pal_rgb <= PALETTE(to_integer(unsigned(pal_idx)));

    -- ========================================================================
    -- EVALUADOR DE SPRITES CON LINE BUFFER
    --   Fase 1 (blank): recorrer el OAM, guardar en el line buffer los sprites
    --   que cruzan la linea actual (hasta 8).
    --   Fase 2 (visible): recorrer el line buffer combinacionalmente y elegir
    --   el primer sprite (menor indice) que cubre el pixel actual.
    --
    --   El OAM esta en registros, asi que el barrido es rapido (1 sprite/ciclo).
    -- ========================================================================
    line_y <= y0_log(7 downto 0);

    -- ---- Fase 1: llenar el line buffer durante el blank ----
    process (clk_pixel)
        variable sy     : unsigned(7 downto 0);
        variable sx     : unsigned(7 downto 0);
        variable stile  : std_logic_vector(5 downto 0);
        variable spal   : std_logic_vector(3 downto 0);
        variable sscale : std_logic;
        variable span   : unsigned(7 downto 0);   -- alto en lineas (8 o 16)
        variable k      : integer range 0 to NSL;
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                lb_n     <= (others => '0');
                oam_scan <= (others => '0');
                lb_ready <= '0';
            else
                if h_cnt = 0 then
                    -- nueva linea: reiniciar la recoleccion y LIMPIAR el buffer
                    -- (las entradas no usadas no deben conservar datos viejos)
                    lb_n     <= (others => '0');
                    oam_scan <= (others => '0');
                    lb_ready <= '0';
                    for k in 0 to NSL-1 loop
                        lb_x(k)    <= (others => '0');
                        lb_attr(k) <= (others => '0');
                        lb_pal(k)  <= (others => '0');
                        lb_row(k)  <= (others => '0');
                        lb_scale(k) <= '0';
                    end loop;
                elsif oam_scan < 32 then
                    -- evaluar el sprite 'oam_scan' (5 bytes por sprite)
                    sy     := unsigned(oam_reg(to_integer(oam_scan) * 5 + 1));
                    sx     := unsigned(oam_reg(to_integer(oam_scan) * 5 + 0));
                    stile  := oam_reg(to_integer(oam_scan) * 5 + 2)(5 downto 0);
                    spal   := oam_reg(to_integer(oam_scan) * 5 + 3)(3 downto 0);
                    sscale := oam_reg(to_integer(oam_scan) * 5 + 3)(4);  -- SCALE2X

                    -- alcance vertical: 8 lineas (1x) o 16 lineas (2x)
                    if sscale = '1' then
                        span := to_unsigned(16, 8);
                    else
                        span := to_unsigned(8, 8);
                    end if;

                    -- si cruza la linea y hay hueco, guardarlo
                    if (sy < 248) and (sy <= line_y) and (sy + span > line_y)
                       and (lb_n < NSL) then
                        lb_x(to_integer(lb_n)) <= sx;
                        -- attr: tile(6) + prio + flipx + flipy
                        lb_attr(to_integer(lb_n)) <= stile &
                                                     oam_reg(to_integer(oam_scan) * 5 + 3)(5) &
                                                     oam_reg(to_integer(oam_scan) * 5 + 3)(6) &
                                                     oam_reg(to_integer(oam_scan) * 5 + 3)(7) &
                                                     "000";
                        lb_pal(to_integer(lb_n)) <= spal;
                        lb_scale(to_integer(lb_n)) <= sscale;
                        -- fila del patron:
                        --   1x: row = line_y - sy            (0..7)
                        --   2x: row = (line_y - sy) / 2      (0..7)
                        if sscale = '1' then
                            if oam_reg(to_integer(oam_scan) * 5 + 3)(7) = '1' then
                                lb_row(to_integer(lb_n)) <= 7 - resize((line_y - sy)/2, 3);
                            else
                                lb_row(to_integer(lb_n)) <= resize((line_y - sy)/2, 3);
                            end if;
                        else
                            -- fila: si FLIP_Y, invertir (7 - row)
                            if oam_reg(to_integer(oam_scan) * 5 + 3)(7) = '1' then
                                lb_row(to_integer(lb_n)) <= 7 - resize(line_y - sy, 3);
                            else
                                lb_row(to_integer(lb_n)) <= resize(line_y - sy, 3);
                            end if;
                        end if;
                        lb_n <= lb_n + 1;
                    end if;
                    oam_scan <= oam_scan + 1;
                else
                    -- barrido terminado: el buffer es estable
                    lb_ready <= '1';
                end if;
            end if;
        end if;
    end process;

    -- ---- Fase 2: elegir el sprite del line buffer que cubre el pixel ----
    --   Solo actua cuando lb_ready='1' (buffer completamente lleno) y considera
    --   UNICAMENTE las primeras 'lb_n' entradas validas. Las restantes pueden
    --   contener datos de lineas anteriores y NO deben leerse.
    process (x0_log, lb_x, lb_attr, lb_pal, lb_row, lb_scale, lb_n, lb_ready)
        variable found : std_logic;
        variable i     : integer range 0 to NSL;
        variable lim   : integer range 0 to NSL;
        variable xwid  : unsigned(8 downto 0);
    begin
        found := '0';
        lb_pick_ok   <= '0';
        lb_pick_x    <= (others => '0');
        lb_pick_tile <= (others => '0');
        lb_pick_pal  <= (others => '0');
        lb_pick_row  <= (others => '0');
        lb_pick_prio <= '0';
        lb_pick_fx   <= '0';
        lb_pick_fy   <= '0';
        lb_pick_scale<= '0';
        lim := to_integer(lb_n);
        if lim > NSL then
            lim := NSL;
        end if;
        if lb_ready = '1' then
            i := 0;
            while (i < lim) and (found = '0') loop
                -- ancho en pantalla: 8 px (1x) o 16 px (2x)
                if lb_scale(i) = '1' then
                    xwid := to_unsigned(16, 9);
                else
                    xwid := to_unsigned(8, 9);
                end if;
                if (resize(unsigned(lb_x(i)), 9) <= x0_log) and
                   (resize(unsigned(lb_x(i)), 9) + xwid > x0_log) then
                    found := '1';
                    lb_pick_ok   <= '1';
                    lb_pick_x    <= lb_x(i);
                    lb_pick_tile <= lb_attr(i)(11 downto 6);
                    lb_pick_prio <= lb_attr(i)(5);
                    lb_pick_fx   <= lb_attr(i)(4);
                    lb_pick_fy   <= lb_attr(i)(3);
                    lb_pick_scale<= lb_scale(i);
                    lb_pick_pal  <= lb_pal(i);
                    lb_pick_row  <= lb_row(i);
                end if;
                i := i + 1;
            end loop;
        end if;
    end process;

    -- direccion del patron del sprite: sprite(6 bits) * 8 + fila  (0..511)
    spr_pat_addr <= resize(shift_left(resize(unsigned(lb_pick_tile), 9), 3), 9)
                    + resize(lb_pick_row, 9);

    -- pixel del sprite (SECUENCIAL, 2 ciclos, alineado con la etapa 2 del fondo):
    --   Etapa A: sx = x0_log - lb_pick_x, extraer bit del patron (spr_pat_data).
    process (clk_pixel)
        variable sx   : unsigned(8 downto 0);
        variable idx  : integer range 0 to 7;
        variable xp9  : unsigned(8 downto 0);
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                spr_active  <= '0';
                spr_pixcode <= (others => '0');
                spr_active1 <= '0';
                spr_pixcode1 <= (others => '0');
                lb_pick_x_d     <= (others => '0');
                lb_pick_fx_d    <= '0';
                lb_pick_scale_d <= '0';
                lb_pick_ok_d    <= '0';
            else
                -- Etapa A -> B
                spr_active1  <= spr_active;
                spr_pixcode1 <= spr_pixcode;

                -- Paleta: 2 registros (etapa A -> B) para alinearla con
                -- spr_pixcode1. spr_pal_a es etapa A, spr_pal_b etapa B.
                spr_pal_a <= lb_pick_pal;
                spr_pal_b <= spr_pal_a;

                -- Retardo de la seleccion para alinearla con spr_pat_data (BSRAM
                -- 1 ciclo de latencia). Evita la linea de 1 px entre sprites.
                lb_pick_x_d     <= lb_pick_x;
                lb_pick_fx_d    <= lb_pick_fx;
                lb_pick_scale_d <= lb_pick_scale;
                lb_pick_ok_d    <= lb_pick_ok;
                x0_log_d        <= x0_log;

                -- Etapa A: calcular a partir de spr_pat_data (ya alineado)
                spr_active  <= '0';
                spr_pixcode <= (others => '0');
                xp9 := resize(lb_pick_x_d, 9);
                if lb_pick_ok_d = '1' and (x0_log_d >= xp9) and
                   ((lb_pick_scale_d = '0' and (x0_log_d < xp9 + 8)) or
                    (lb_pick_scale_d = '1' and (x0_log_d < xp9 + 16))) then
                    sx  := x0_log_d - xp9;
                    if lb_pick_scale_d = '1' then
                        -- 2x: dos pixeles de pantalla por uno de origen (sx/2).
                        idx := to_integer(sx(3 downto 1));
                    else
                        idx := to_integer(sx(2 downto 0));
                    end if;
                    -- FLIP_X: invertir el indice horizontal (7 - idx)
                    if lb_pick_fx_d = '1' then
                        idx := 7 - idx;
                    end if;
                    spr_pixcode <= spr_pat_data(15 - idx) & spr_pat_data(7 - idx);
                    if (spr_pat_data(15 - idx) = '1') or
                       (spr_pat_data(7 - idx) = '1') then
                        spr_active <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- paleta del sprite: 2 bits de paleta + 2 bits de color (banco SEPARADO
    -- del fondo). El color 0 (transparente) ya se descarta via spr_active.
    --   spr_pal_b es la paleta alineada a la etapa B (con spr_pixcode1).
    spl_pal_sel2 <= spr_pal_b(1 downto 0);
    spr_pal_idx  <= spl_pal_sel2 & spr_pixcode1;
    spr_rgb      <= SPR_PALETTE(to_integer(unsigned(spr_pal_idx)));

    -- PRIO retrasado para alinear con spr_active1 (etapa 2)
    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            spr_prio1 <= lb_pick_prio;
            spr_prio2 <= spr_prio1;
        end if;
    end process;

    -- ========================================================================
    -- STATUS: VBLANK / OVERFLOW
    --   HIT (deteccion de colision de pixeles) se descarto por coste: comparar
    --   todos los pares de sprites exige cientos de comparadores (>15k LUTs) y
    --   no cabe. La colision de gameplay se hace por SOFTWARE (comparar las
    --   coordenadas en RAM), que es lo que hace un juego real.
    -- ========================================================================
    -- VBLANK: fuera de la zona visible (v_cnt >= V_VISIBLE)
    vblank_f <= '1' when v_cnt >= V_VISIBLE else '0';

    -- ========================================================================
    -- OVERFLOW -- DIAGNOSTICO TEMPORAL
    --   Se activa directamente cuando lb_n alcanza NSL (es decir, el line
    --   buffer se lleno). Deberia ser equivalente y es mas facil de verificar.
    -- ========================================================================
    overflow_now <= '1' when (lb_n >= NSL) else '0';

    process (clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            if rst_n = '0' then
                overflow_f <= '0';
            elsif h_cnt = 0 then
                -- inicio de linea: el flag refleja el estado de la linea anterior
                overflow_f <= overflow_now;
            elsif overflow_now = '1' then
                overflow_f <= '1';
            end if;
        end if;
    end process;

    -- bit7 VBLANK | bit6 OVERFLOW | bit5 SOLID_HIT | bit4 READY | bit3..0 rsv
    --   bit5 = '1' si CUALQUIER sprite colisiona con un tile solido (bit 4 del
    --   atributo) durante el frame. Se actualiza una vez por frame (blanking).
    status_reg <= vblank_f & overflow_f & solid_hit & init_done & "0000";
    status_out <= status_reg;

    -- ========================================================================
    -- COLOR FINAL: 3 capas (margen, fondo, sprite)
    --   El color 0 del FONDO es TRANSPARENTE (modelo NES): donde el tile de
    --   fondo tiene color 0, no se pinta fondo (se ve BG_COLOR o un sprite).
    --
    --   Prioridad:
    --     - margen            -> BG_COLOR
    --     - sprite PRIO=0 activo -> sprite (delante del fondo)
    --     - fondo visible (color != 0) -> fondo
    --     - sprite PRIO=1 activo -> sprite (detras del fondo, en los huecos)
    --     - si nada            -> BG_COLOR
    -- ========================================================================
    rgb24 <= (BG_COLOR) when margen2 = '1' else
             (spr_rgb(11 downto 8) & spr_rgb(11 downto 8) &
              spr_rgb(7  downto 4) & spr_rgb(7  downto 4) &
              spr_rgb(3  downto 0) & spr_rgb(3  downto 0))
             when (spr_active1 = '1') and (spr_prio2 = '0') else
             (pal_rgb(11 downto 8) & pal_rgb(11 downto 8) &
              pal_rgb(7  downto 4) & pal_rgb(7  downto 4) &
              pal_rgb(3  downto 0) & pal_rgb(3  downto 0))
             when pixcode /= "00" else
             (spr_rgb(11 downto 8) & spr_rgb(11 downto 8) &
              spr_rgb(7  downto 4) & spr_rgb(7  downto 4) &
              spr_rgb(3  downto 0) & spr_rgb(3  downto 0))
             when spr_active1 = '1' else
             (BG_COLOR);

    -- ========================================================================
    -- TRANSMISOR TMDS
    -- ========================================================================
    hdmi_inst : hdmi_module
        port map (
            vga_clk_x5      => clk_serial,
            vga_clk         => clk_pixel,
            vga_red_in      => rgb24(23 downto 16),
            vga_green_in    => rgb24(15 downto 8),
            vga_blue_in     => rgb24(7 downto 0),
            vga_hsync_in    => hs2,
            vga_vsync_in    => vs2,
            vga_disp_ena_in => de2,
            tmds_c0_p_out   => tmds_c0_p,
            tmds_c0_n_out   => tmds_c0_n,
            tmds_c1_p_out   => tmds_c1_p,
            tmds_c1_n_out   => tmds_c1_n,
            tmds_c2_p_out   => tmds_c2_p,
            tmds_c2_n_out   => tmds_c2_n,
            tmds_ck_p_out   => tmds_ck_p,
            tmds_ck_n_out   => tmds_ck_n
        );

end architecture;
