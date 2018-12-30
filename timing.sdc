# ------------------------------------------
set_time_unit ns
set_decimal_places 3
# ------------------------------------------

create_clock -name clk_in -period 8.333 [get_ports {clk_in}]
create_clock -name spi_clk -period 50.000 [get_ports {spi_clk}]

derive_pll_clocks
derive_clock_uncertainty
