library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;


entity hdmi_impl is
	port (
        vga_clk_x5 : in  STD_LOGIC;
		vga_clk : in  STD_LOGIC;

		vga_red_in : in std_logic_vector(7 downto 0);
		vga_green_in : in std_logic_vector(7 downto 0);
		vga_blue_in : in std_logic_vector(7 downto 0);

		vga_hsync_in : in STD_LOGIC;
		vga_vsync_in : in STD_LOGIC;

        vga_disp_ena_in : in STD_LOGIC;

        tmds_c0_p_out : out STD_LOGIC;
        tmds_c0_n_out : out STD_LOGIC;

        tmds_c1_p_out : out STD_LOGIC;
        tmds_c1_n_out : out STD_LOGIC;

        tmds_c2_p_out : out STD_LOGIC;
        tmds_c2_n_out : out STD_LOGIC;

        tmds_ck_p_out : out STD_LOGIC;
        tmds_ck_n_out : out STD_LOGIC

	);

end hdmi_impl;

architecture Behavioral of hdmi_impl is

signal tmds_out_c0_blue   : STD_LOGIC_VECTOR(9 DOWNTO 0);
signal tmds_out_c1_green   : STD_LOGIC_VECTOR(9 DOWNTO 0);
signal tmds_out_c2_red   : STD_LOGIC_VECTOR(9 DOWNTO 0);

signal tmds_serial_c0_blue : std_logic;
signal tmds_serial_c1_green : std_logic;
signal tmds_serial_c2_red : std_logic;

signal control_syncs : STD_LOGIC_VECTOR(1 DOWNTO 0);

COMPONENT OSER10
GENERIC (
	GSREN:string:="false";
	LSREN:string:="false"
 );

PORT(
	Q:OUT std_logic;
	D0:IN std_logic;
	D1:IN std_logic;
	D2:IN std_logic;
	D3:IN std_logic;
	D4:IN std_logic;
	D5:IN std_logic;
	D6:IN std_logic;
	D7:IN std_logic;
	D8:IN std_logic;
	D9:IN std_logic;
	FCLK:IN std_logic;
	PCLK:IN std_logic;
	RESET:IN std_logic
 );
END COMPONENT;

COMPONENT ELVDS_OBUF
 PORT (
     O:OUT std_logic;
     OB:OUT std_logic;
     I:IN std_logic
 );
END COMPONENT;


begin

control_syncs<=vga_vsync_in&vga_hsync_in;

tmds_encoder_c0_blue : entity work.tmds_encoder_2
port map(
		clk=>vga_clk,
		disp_ena=>vga_disp_ena_in,
        control=>control_syncs,
		d_in=>vga_blue_in,
		q_out=>tmds_out_c0_blue
	);

tmds_encoder_c1_green : entity work.tmds_encoder_2
port map(
		clk=>vga_clk,
		disp_ena=>vga_disp_ena_in,
		control=>"00",
		d_in=>vga_green_in,
		q_out=>tmds_out_c1_green
	);

tmds_encoder_c2_red : entity work.tmds_encoder_2
port map(
		clk=>vga_clk,
		disp_ena=>vga_disp_ena_in,
		control=>"00",
		d_in=>vga_red_in,
		q_out=>tmds_out_c2_red
	);



blue_serial :OSER10
GENERIC MAP (
    GSREN=>"false",
    LSREN=>"false"
 )
PORT MAP (
     Q=>tmds_serial_c0_blue,
     D0=>tmds_out_c0_blue(0),
     D1=>tmds_out_c0_blue(1),
     D2=>tmds_out_c0_blue(2), 
     D3=>tmds_out_c0_blue(3),
     D4=>tmds_out_c0_blue(4),
     D5=>tmds_out_c0_blue(5),
     D6=>tmds_out_c0_blue(6),
     D7=>tmds_out_c0_blue(7),
     D8=>tmds_out_c0_blue(8),
     D9=>tmds_out_c0_blue(9), 
     FCLK=>vga_clk_x5,
     PCLK=>vga_clk,
     RESET=>'0'
 );

green_serial :OSER10
GENERIC MAP (
    GSREN=>"false",
    LSREN=>"false"
 )
PORT MAP (
     Q=>tmds_serial_c1_green,
     D0=>tmds_out_c1_green(0),
     D1=>tmds_out_c1_green(1),
     D2=>tmds_out_c1_green(2), 
     D3=>tmds_out_c1_green(3),
     D4=>tmds_out_c1_green(4),
     D5=>tmds_out_c1_green(5),
     D6=>tmds_out_c1_green(6),
     D7=>tmds_out_c1_green(7),
     D8=>tmds_out_c1_green(8),
     D9=>tmds_out_c1_green(9), 
     FCLK=>vga_clk_x5,
     PCLK=>vga_clk,
     RESET=>'0'
 );

red_serial :OSER10
GENERIC MAP (
    GSREN=>"false",
    LSREN=>"false"
 )
PORT MAP (
     Q=>tmds_serial_c2_red,
     D0=>tmds_out_c2_red(0),
     D1=>tmds_out_c2_red(1),
     D2=>tmds_out_c2_red(2), 
     D3=>tmds_out_c2_red(3),
     D4=>tmds_out_c2_red(4),
     D5=>tmds_out_c2_red(5),
     D6=>tmds_out_c2_red(6),
     D7=>tmds_out_c2_red(7),
     D8=>tmds_out_c2_red(8),
     D9=>tmds_out_c2_red(9), 
     FCLK=>vga_clk_x5,
     PCLK=>vga_clk,
     RESET=>'0'
 );

hdmi_buf_c0_blue : ELVDS_OBUF
 PORT MAP(
     O=>tmds_c0_p_out,
     OB=>tmds_c0_n_out,
     I=> tmds_serial_c0_blue
 );

hdmi_buf_c1_green : ELVDS_OBUF
 PORT MAP(
     O=>tmds_c1_p_out,
     OB=>tmds_c1_n_out,
     I=> tmds_serial_c1_green
 );

hdmi_buf_c2_red : ELVDS_OBUF
 PORT MAP(
     O=>tmds_c2_p_out,
     OB=>tmds_c2_n_out,
     I=> tmds_serial_c2_red
 );

hdmi_buf_ck: ELVDS_OBUF
 PORT MAP(
     O=>tmds_ck_p_out,
     OB=>tmds_ck_n_out,
     I=> vga_clk
 );
end Behavioral;