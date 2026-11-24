-- ============================================================================
-- HDMI_TX.VHD - Codificador HDMI 720x480p60 (27 MHz) con audio
--
--   FULL = true : HDMI. En cada borrado horizontal envia una isla de datos con
--                 audio de 48 kHz y, en algunas lineas, ACR, AVI InfoFrame
--                 (VIC 2, 4:3, RGB rango completo) y Audio InfoFrame.
--   FULL = false: DVI (solo imagen).
--
--   hs, vs, de y rgb llegan 2 ciclos despues de h_cnt/v_cnt.
--
--   Reparto de la linea (posiciones de pixel):
--     720-727 control | 728-735 preambulo de datos | 736-737 guarda
--     738...  1 a 3 paquetes de 32 | 2 de guarda | control
--     848-855 preambulo de video | 856-857 guarda de video
--
--   Audio: mono (L = R). 27 MHz / 48 kHz = 562,5 pixeles, exacto, asi que
--   N = 6144 y CTS = 27000 son constantes.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_tx is
    generic (
        FULL : boolean := true
    );
    port (
        clk     : in  std_logic;                      -- 27 MHz
        h_cnt   : in  unsigned(9 downto 0);
        v_cnt   : in  unsigned(9 downto 0);
        hs      : in  std_logic;
        vs      : in  std_logic;
        de      : in  std_logic;
        rgb     : in  std_logic_vector(23 downto 0);
        audio_req : out std_logic;                    -- cambia en cada muestra
        audio     : in  std_logic_vector(15 downto 0); -- con signo; estable
        q0, q1, q2 : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of hdmi_tx is

    type b9x32_t is array (0 to 31) of std_logic_vector(8 downto 0);
    type rom_t   is array (0 to 159) of std_logic_vector(8 downto 0);
    type bytes_t is array (natural range <>) of std_logic_vector(7 downto 0);

    -- un bit por el BCH (x^8 + x^7 + x^6 + 1, LSB primero)
    function bch(e : std_logic_vector(7 downto 0); b : std_logic) return std_logic_vector is
        variable r : std_logic_vector(7 downto 0);
    begin
        r := '0' & e(7 downto 1);
        if (e(0) xor b) = '1' then
            r := r xor x"83";
        end if;
        return r;
    end function;

    function parity(v : std_logic_vector) return std_logic is
        variable p : std_logic := '0';
    begin
        for i in v'range loop
            p := p xor v(i);
        end loop;
        return p;
    end function;

    -- paquete completo -> 32 x 9 bits: (8..5) canal 2, (4..1) canal 1, (0) cabecera
    function mk_packet(hb : bytes_t(0 to 2); pb : bytes_t(0 to 27)) return b9x32_t is
        variable r : b9x32_t := (others => (others => '0'));
        variable h : std_logic_vector(31 downto 0);
        variable s : std_logic_vector(63 downto 0);
        variable e : std_logic_vector(7 downto 0);
    begin
        h(23 downto 0) := hb(2) & hb(1) & hb(0);
        e := x"00";
        for i in 0 to 23 loop
            e := bch(e, h(i));
        end loop;
        h(31 downto 24) := e;
        for i in 0 to 31 loop
            r(i)(0) := h(i);
        end loop;
        for k in 0 to 3 loop
            for b in 0 to 6 loop
                s(8*b+7 downto 8*b) := pb(7*k + b);
            end loop;
            e := x"00";
            for i in 0 to 55 loop
                e := bch(e, s(i));
            end loop;
            s(63 downto 56) := e;
            for i in 0 to 31 loop
                r(i)(1 + k) := s(2*i);
                r(i)(5 + k) := s(2*i + 1);
            end loop;
        end loop;
        return r;
    end function;

    -- ACR: CTS = 27000 = $06978, N = 6144 = $01800 (4 subpaquetes iguales)
    constant ACR : b9x32_t := mk_packet(
        (x"01", x"00", x"00"),
        (x"00", x"00", x"69", x"78", x"00", x"18", x"00",
         x"00", x"00", x"69", x"78", x"00", x"18", x"00",
         x"00", x"00", x"69", x"78", x"00", x"18", x"00",
         x"00", x"00", x"69", x"78", x"00", x"18", x"00"));
    -- AVI: RGB, 4:3, VIC 2, rango completo, sin recorte (underscan)
    --   suma 82+02+0D+12+18+88+02 = 145 -> PB0 = BB
    constant AVI : b9x32_t := mk_packet(
        (x"82", x"02", x"0D"),
        (x"BB", x"12", x"18", x"88", x"02", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00"));
    -- Audio InfoFrame: 2 canales.  suma 84+01+0A+01 = 90 -> PB0 = 70
    constant AIF : b9x32_t := mk_packet(
        (x"84", x"01", x"0A"),
        (x"70", x"01", x"00", x"00", x"00", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00",
         x"00", x"00", x"00", x"00", x"00", x"00", x"00"));
    -- Control general: Clear_AVMUTE (quita el silencio de imagen y sonido)
    constant GCP : b9x32_t := mk_packet(
        (x"03", x"00", x"00"),
        (x"10", x"00", x"00", x"00", x"00", x"00", x"00",
         x"10", x"00", x"00", x"00", x"00", x"00", x"00",
         x"10", x"00", x"00", x"00", x"00", x"00", x"00",
         x"10", x"00", x"00", x"00", x"00", x"00", x"00"));
    -- Muestra de audio: solo cabeceras (sin / con inicio de bloque)
    constant Z28 : bytes_t(0 to 27) := (others => x"00");
    constant AS0 : b9x32_t := mk_packet((x"02", x"01", x"00"), Z28);
    constant AS1 : b9x32_t := mk_packet((x"02", x"01", x"10"), Z28);

    function mk_rom return rom_t is
        variable r : rom_t := (others => (others => '0'));
    begin
        for i in 0 to 31 loop
            r(i)      := AS0(i);
            r(i)(1)   := AS1(i)(0);      -- la cabecera de AS1, en el bit 1
            r(32 + i) := ACR(i);
            r(64 + i) := AVI(i);
            r(96 + i) := AIF(i);
            r(128 + i) := GCP(i);
        end loop;
        return r;
    end function;
    signal ROM : rom_t := mk_rom;
    attribute syn_romstyle : string;
    attribute syn_romstyle of ROM : signal is "distributed_rom";

    function terc4(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when "0000" => return "1010011100";
            when "0001" => return "1001100011";
            when "0010" => return "1011100100";
            when "0011" => return "1011100010";
            when "0100" => return "0101110001";
            when "0101" => return "0100011110";
            when "0110" => return "0110001110";
            when "0111" => return "0100111100";
            when "1000" => return "1011001100";
            when "1001" => return "0100111001";
            when "1010" => return "0110011100";
            when "1011" => return "1011000110";
            when "1100" => return "1010001110";
            when "1101" => return "1001110001";
            when "1110" => return "0101100011";
            when others => return "1011000011";
        end case;
    end function;

    -- modo de cada pixel: 0 video/control, 1 preambulo datos, 2 guarda datos,
    --                     3 datos, 4 preambulo video, 5 guarda video
    signal m0, m1, m2 : unsigned(2 downto 0) := (others => '0');

    -- muestras
    signal tcnt  : unsigned(9 downto 0) := (others => '0');
    signal tlong : std_logic := '0';
    signal req   : std_logic := '0';
    signal tick  : std_logic := '0';
    type fifo_t is array (0 to 3) of std_logic_vector(15 downto 0);
    signal fifo : fifo_t := (others => (others => '0'));
    signal wp, rp : unsigned(1 downto 0) := (others => '0');
    signal cnt  : unsigned(2 downto 0) := (others => '0');
    signal frame : unsigned(7 downto 0) := (others => '0');   -- 0..191
    signal smp  : std_logic_vector(15 downto 0);

    -- isla
    signal isl   : std_logic := '0';                          -- dentro de paquetes
    signal pos   : unsigned(6 downto 0) := (others => '0');   -- slot & pixel
    signal npk   : unsigned(1 downto 0) := (others => '0');   -- paquetes de la linea
    signal stat  : unsigned(2 downto 0) := (others => '0');   -- 0 nada, 1 ACR, 2 AVI, 3 AIF, 4 GCP
    signal typ   : unsigned(2 downto 0);                      -- tipo del slot actual
    signal pend  : unsigned(1 downto 0);
    signal endh  : unsigned(1 downto 0) := (others => '0');   -- guarda de salida
    signal pre   : std_logic;
    signal gin   : std_logic;

    signal sub   : std_logic_vector(55 downto 0);
    signal ecc   : std_logic_vector(7 downto 0) := (others => '0');
    signal d0, d1, d2 : std_logic_vector(8 downto 0) := (others => '0');
    signal f0, f1, f2 : std_logic := '0';                     -- no es el primer pixel
    signal csl, csr, pl, pr : std_logic;

    -- salida
    signal e0, e1, e2 : std_logic_vector(9 downto 0);
    signal a0, a1, a2 : std_logic_vector(9 downto 0) := (others => '0');
    signal asel  : std_logic := '0';
    signal c0, c1, c2 : std_logic_vector(1 downto 0);

begin

    -- ---- muestreo a 48 kHz (562 / 563 pixeles) ----
    audio_req <= req;
    process (clk)
    begin
        if rising_edge(clk) then
            tick <= '0';
            if (tlong = '0' and tcnt = 561) or (tlong = '1' and tcnt = 562) then
                tcnt <= (others => '0');
                tlong <= not tlong;
                req <= not req;
                tick <= '1';
            else
                tcnt <= tcnt + 1;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if tick = '1' then
                fifo(to_integer(wp)) <= audio;
            end if;
        end if;
    end process;
    smp <= fifo(to_integer(rp));

    -- ---- reparto de la linea ----
    pend <= "10" when cnt >= 2 else cnt(1 downto 0);
    typ  <= stat when pos(6 downto 5) = 0 else "000";
    pre  <= '1' when h_cnt >= 728 and h_cnt <= 735 else '0';
    gin  <= '1' when h_cnt = 736 or h_cnt = 737 else '0';

    process (h_cnt, v_cnt, pre, gin, isl, endh, npk)
    begin
        m0 <= "000";
        if FULL then
            if npk /= 0 and pre = '1' then
                m0 <= "001";
            elsif (npk /= 0 and gin = '1') or endh /= 0 then
                m0 <= "010";
            elsif isl = '1' then
                m0 <= "011";
            elsif v_cnt < 479 or v_cnt = 524 then
                if h_cnt >= 848 and h_cnt <= 855 then
                    m0 <= "100";
                elsif h_cnt = 856 or h_cnt = 857 then
                    m0 <= "101";
                end if;
            end if;
        end if;
    end process;

    process (clk)
        variable pop : std_logic;
    begin
        if rising_edge(clk) then
            pop := '0';
            if endh /= 0 then
                endh <= endh - 1;
            end if;
            if h_cnt = 724 then
                -- decidir los paquetes de esta linea
                if v_cnt(4 downto 0) = 0 then
                    stat <= "001";
                    npk  <= pend + 1;
                elsif v_cnt = 10 or v_cnt = 490 then
                    stat <= "010";
                    npk  <= pend + 1;
                elsif v_cnt = 11 or v_cnt = 491 then
                    stat <= "011";
                    npk  <= pend + 1;
                elsif v_cnt = 489 then           -- justo tras el flanco de VSYNC
                    stat <= "100";
                    npk  <= pend + 1;
                else
                    stat <= "000";
                    npk  <= pend;
                end if;
            end if;
            if h_cnt = 737 and npk /= 0 then
                isl <= '1';
                pos <= (others => '0');
            elsif isl = '1' then
                pos <= pos + 1;
                if pos(4 downto 0) = 31 then
                    if typ = 0 then
                        pop := '1';
                    end if;
                    if pos(6 downto 5) + 1 = npk then
                        isl  <= '0';
                        endh <= "10";
                    end if;
                end if;
            end if;

            -- cola de muestras
            if tick = '1' then
                wp <= wp + 1;
            end if;
            if pop = '1' then
                rp <= rp + 1;
                if frame = 191 then
                    frame <= (others => '0');
                else
                    frame <= frame + 1;
                end if;
            end if;
            if tick = '1' and pop = '0' then
                cnt <= cnt + 1;
            elsif tick = '0' and pop = '1' then
                cnt <= cnt - 1;
            end if;
        end if;
    end process;

    -- ---- estado de canal IEC 60958: copia libre, 48 kHz, 16 bits ----
    csl <= '1' when frame = 2 or frame = 20 or frame = 25 or frame = 33 else '0';
    csr <= '1' when frame = 2 or frame = 21 or frame = 25 or frame = 33 else '0';
    pl  <= parity(smp) xor csl;
    pr  <= parity(smp) xor csr;
    sub <= pr & csr & "00" & pl & csl & "00" & smp & x"00" & smp & x"00";

    process (pos, typ, sub, ecc, frame)
        variable w : std_logic_vector(8 downto 0);
        variable i : integer range 0 to 31;
    begin
        i := to_integer(pos(4 downto 0));
        w := (others => '0');
        if typ <= 4 then
            w := ROM(to_integer(typ & pos(4 downto 0)));
        end if;
        if typ = 0 then
            -- cabecera de la ROM; solo el subpaquete 0 lleva datos
            d0 <= (others => '0');
            if frame = 0 then
                d0(0) <= w(1);
            else
                d0(0) <= w(0);
            end if;
            if i < 28 then
                d0(1) <= sub(2*i);
                d0(5) <= sub(2*i + 1);
            else
                d0(1) <= ecc(2*(i - 28));
                d0(5) <= ecc(2*(i - 28) + 1);
            end if;
        else
            d0 <= w;
        end if;
    end process;
    f0 <= '0' when pos = 0 else '1';

    process (clk)
        variable e : std_logic_vector(7 downto 0);
        variable i : integer range 0 to 31;
    begin
        if rising_edge(clk) then
            i := to_integer(pos(4 downto 0));
            if isl = '0' or i = 31 then
                ecc <= (others => '0');
            elsif i < 28 then
                e := bch(ecc, sub(2*i));
                ecc <= bch(e, sub(2*i + 1));
            end if;
            -- alinear con hs / vs / de (2 ciclos)
            m1 <= m0;  m2 <= m1;
            d1 <= d0;  d2 <= d1;
            f1 <= f0;  f2 <= f1;
        end if;
    end process;

    -- ---- codificadores de video y control ----
    c0 <= vs & hs;
    c1 <= "01" when m2 = 1 or m2 = 4 else "00";
    c2 <= "01" when m2 = 1 else "00";
    enc0 : entity work.tmds_encoder_2 port map (clk => clk, disp_ena => de, control => c0, d_in => rgb(7 downto 0),   q_out => e0);
    enc1 : entity work.tmds_encoder_2 port map (clk => clk, disp_ena => de, control => c1, d_in => rgb(15 downto 8),  q_out => e1);
    enc2 : entity work.tmds_encoder_2 port map (clk => clk, disp_ena => de, control => c2, d_in => rgb(23 downto 16), q_out => e2);

    process (clk)
    begin
        if rising_edge(clk) then
            asel <= '0';
            if m2 = 3 then
                asel <= '1';
                a0 <= terc4(f2 & d2(0) & vs & hs);
                a1 <= terc4(d2(4 downto 1));
                a2 <= terc4(d2(8 downto 5));
            elsif m2 = 2 then
                asel <= '1';
                a0 <= terc4("11" & vs & hs);
                a1 <= "0100110011";
                a2 <= "0100110011";
            elsif m2 = 5 then
                asel <= '1';
                a0 <= "1011001100";
                a1 <= "0100110011";
                a2 <= "1011001100";
            end if;
        end if;
    end process;

    q0 <= a0 when asel = '1' else e0;
    q1 <= a1 when asel = '1' else e1;
    q2 <= a2 when asel = '1' else e2;

end architecture;
