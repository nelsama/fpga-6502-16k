-- ============================================================================
-- video_vram.vhd  --  Memoria de video en BSRAM (Fase 5)
--
-- Arreglos independientes, cada uno inferido como BSRAM en modo
-- Semi Dual Port (escritura por el puerto A, lectura por el puerto B):
--
--   tilemap   : 2048 x 8   (1200 usadas)  indice de patron por celda (40x30)
--   attr      : 2048 x 8   (1200 usadas)  atributo por celda (paleta, flips)
--   pattern   : 2048 x 16  (2048 usadas)  patrones de FONDO, 2bpp planar -> 256 tiles
--   spr_pat   : 512 x 16   (64 usadas)    patrones de SPRITE, 2bpp planar
--
--   El OAM (32 sprites x 5 bytes) NO esta aqui: se implementa en registros
--   dentro de video_core, porque son solo 160 bytes y no justifican un bloque
--   BSRAM entero de 2 KB.
--
-- Presupuesto real:
--   tilemap   : 1 bloque
--   attr      : 1 bloque
--   pattern   : 2 bloques (ancho 16 bits)
--   spr_pat   : 1 bloque  (ancho 16 bits)
--   Total VRAM: 5 bloques BSRAM de 2 KB.
--
-- FORMATO DE LOS PATRONES (2bpp planar, 16 bits por fila = "par de planos"):
--   pat_data(15 downto 8) : plano 1 (bit 1 del color)
--   pat_data(7  downto 0) : plano 0 (bit 0 del color)
--   El bit 7 de cada byte es el pixel mas a la IZQUIERDA.
--   Fondo   : direccion = tile*8 + fila   (0..2047, 256 tiles)
--   Sprites : direccion = spr*8  + fila   (0..511)
--
-- El puerto B tiene 1 ciclo de latencia (salida registrada), que es lo que
-- espera el motor de video.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.font_pkg.all;

entity video_vram is
    port (
        -- ====================================================================
        -- Puerto A: escritura (CPU / inicializacion)
        -- ====================================================================
        clk_a     : in  std_logic;
        wr_tile   : in  std_logic;                      -- 1 = escribir tilemap
        wr_attr   : in  std_logic;                      -- 1 = escribir atributos
        wr_pat    : in  std_logic;                      -- 1 = escribir patrones de fondo
        wr_spr    : in  std_logic;                      -- 1 = escribir patrones de sprite
        wr_addr   : in  std_logic_vector(10 downto 0);  -- 0..2047 (fondo) / 0..511 (sprite)
        wr_data   : in  std_logic_vector(15 downto 0);

        -- ====================================================================
        -- Puerto B: lectura (motor de video), 1 ciclo de latencia
        -- ====================================================================
        clk_b       : in  std_logic;
        tile_addr_b : in  std_logic_vector(10 downto 0);
        tile_data_b : out std_logic_vector(7 downto 0);
        attr_addr_b : in  std_logic_vector(10 downto 0);
        attr_data_b : out std_logic_vector(7 downto 0);
        pat_addr_b  : in  std_logic_vector(10 downto 0);
        pat_data_b  : out std_logic_vector(15 downto 0);
        spr_addr_b  : in  std_logic_vector(8 downto 0);  -- 0..511
        spr_data_b  : out std_logic_vector(15 downto 0);

        -- fuente ("segunda ROM"): lectura para el CPU/expansion
        font_addr_b : in  std_logic_vector(9 downto 0);  -- 0..1023
        font_data_b : out std_logic_vector(8 downto 0)
    );
end entity;

architecture rtl of video_vram is

    type tile_arr_t is array (0 to 2047) of std_logic_vector(7 downto 0);
    type attr_arr_t is array (0 to 2047) of std_logic_vector(7 downto 0);
    type pat_arr_t  is array (0 to 2047) of std_logic_vector(15 downto 0);
    type spr_arr_t  is array (0 to 511) of std_logic_vector(15 downto 0);

    signal tile_arr : tile_arr_t;
    signal attr_arr : attr_arr_t;
    signal pat_arr  : pat_arr_t;
    signal spr_arr  : spr_arr_t;

    -- banco de FUENTE (la "segunda ROM"): 1bpp, precargado
    signal font_arr : font_init_t := FONT_INIT;

    signal tile_q : std_logic_vector(7 downto 0);
    signal attr_q : std_logic_vector(7 downto 0);
    signal pat_q  : std_logic_vector(15 downto 0);
    signal spr_q  : std_logic_vector(15 downto 0);
    signal font_q : std_logic_vector(8 downto 0);

begin

    -- ========================================================================
    -- Puerto A: escritura sincrona
    -- ========================================================================
    process (clk_a)
    begin
        if rising_edge(clk_a) then
            if wr_tile = '1' then
                tile_arr(to_integer(unsigned(wr_addr))) <= wr_data(7 downto 0);
            end if;
            if wr_attr = '1' then
                attr_arr(to_integer(unsigned(wr_addr))) <= wr_data(7 downto 0);
            end if;
            if wr_pat = '1' then
                pat_arr(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
            if wr_spr = '1' then
                spr_arr(to_integer(unsigned(wr_addr(8 downto 0)))) <= wr_data;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Puerto B: lectura sincrona (1 ciclo de latencia)
    -- ========================================================================
    process (clk_b)
    begin
        if rising_edge(clk_b) then
            tile_q <= tile_arr(to_integer(unsigned(tile_addr_b)));
            attr_q <= attr_arr(to_integer(unsigned(attr_addr_b)));
            pat_q  <= pat_arr(to_integer(unsigned(pat_addr_b)));
            spr_q  <= spr_arr(to_integer(unsigned(spr_addr_b)));
            font_q <= font_arr(to_integer(unsigned(font_addr_b)));
        end if;
    end process;

    tile_data_b <= tile_q;
    attr_data_b <= attr_q;
    pat_data_b  <= pat_q;
    spr_data_b  <= spr_q;
    font_data_b <= font_q;

end architecture;
