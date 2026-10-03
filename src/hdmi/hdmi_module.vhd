library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;


entity hdmi_module is
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

end hdmi_module;

architecture Behavioral of hdmi_module is

signal pixel_data : std_logic_vector(23 downto 0);

signal tx_d_n_vector : std_logic_vector(2 downto 0);
signal tx_d_p_vector : std_logic_vector(2 downto 0);
constant SAMPLE_FREQ : integer := 32000;

begin


    hdmi_impl : entity work.hdmi_impl
    port map(
        vga_clk_x5=>vga_clk_x5,
		vga_clk=>vga_clk,

		vga_red_in=>vga_red_in,
		vga_green_in=>vga_green_in,
		vga_blue_in=>vga_blue_in,

		vga_hsync_in=>vga_hsync_in,
		vga_vsync_in=>vga_vsync_in,

        vga_disp_ena_in=>vga_disp_ena_in,

        tmds_c0_p_out=>tmds_c0_p_out,
        tmds_c0_n_out=>tmds_c0_n_out,

        tmds_c1_p_out=>tmds_c1_p_out,
        tmds_c1_n_out=>tmds_c1_n_out,

        tmds_c2_p_out=>tmds_c2_p_out,
        tmds_c2_n_out=>tmds_c2_n_out,

        tmds_ck_p_out=>tmds_ck_p_out,
        tmds_ck_n_out=>tmds_ck_n_out
    );

end Behavioral;