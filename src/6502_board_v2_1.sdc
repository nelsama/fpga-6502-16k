# Relojes reales de la placa
create_clock -name clk27 -period 37.037 -waveform {0 18.518} [get_ports {CLOCK_27_i}]
# 27 / 4 = 6,75 MHz
create_generated_clock -name sysclk -source [get_ports {CLOCK_27_i}] -master_clock clk27 -divide_by 4 [get_pins {clk_inst/clkdiv_inst/CLKOUT}]
# 6,75 / 2 = 3,375 MHz (CPU)
create_generated_clock -name cpuclk -source [get_pins {clk_inst/clkdiv_inst/CLKOUT}] -master_clock sysclk -divide_by 2 [get_pins {tmp_clk_s0/Q}]
# 27 / 28 = 0,964 MHz (SID)
create_generated_clock -name clk1m -source [get_ports {CLOCK_27_i}] -master_clock clk27 -divide_by 28 [get_pins {clk_1mhz_s1/Q}]
# PSRAM: 81 MHz y 81 MHz + 90 grados
create_clock -name mem -period 12.346 -waveform {0 6.173} [get_nets {clk_81mhz}]
create_clock -name mem_p -period 12.346 -waveform {3.086 9.259} [get_nets {clk_81mhz_p}]
# DAC de audio (81 MHz, o 27 MHz si el PLL no engancha)
create_clock -name dac -period 12.346 -waveform {0 6.173} [get_nets {clk_81mhz_safe}]
set_clock_groups -asynchronous -group [get_clocks {clk27 sysclk cpuclk clk1m}] -group [get_clocks {mem mem_p}] -group [get_clocks {dac}]
# HDMI: pixel de 27 MHz derivado del PLL de 135 MHz
create_clock -name pix -period 37.037 -waveform {0 18.518} [get_nets {clk_pixel}]
set_clock_groups -asynchronous -group [get_clocks {pix}] -group [get_clocks {clk27 sysclk cpuclk clk1m}]
