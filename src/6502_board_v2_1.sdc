# Relojes reales de la placa
create_clock -name clk27 -period 37.037 -waveform {0 18.518} [get_ports {CLOCK_27_i}]
# 27 / 4 = 6,75 MHz
create_generated_clock -name sysclk -source [get_ports {CLOCK_27_i}] -master_clock clk27 -divide_by 4 [get_pins {clk_inst/clkdiv_inst/CLKOUT}]
# 6,75 / 2 = 3,375 MHz (CPU)
create_generated_clock -name cpuclk -source [get_pins {clk_inst/clkdiv_inst/CLKOUT}] -master_clock sysclk -divide_by 2 [get_pins {tmp_clk_s0/Q}]
# 27 / 28 = 0,964 MHz (SID)
create_generated_clock -name clk1m -source [get_ports {CLOCK_27_i}] -master_clock clk27 -divide_by 28 [get_pins {clk_1mhz_s1/Q}]
