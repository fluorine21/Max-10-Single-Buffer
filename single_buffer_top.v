//Top Level module


module single_buffer_top
(
	//Global clock and reset inputs
	input wire clk_in,
	input wire reset,//Also used to cause a frame capture
	
	//Camera Ins and Outs
	input wire pixel_vsync,
	input wire pixel_hsync,
	input wire pixel_clk,
	input wire [7:0] pixel_data,
	output wire pixel_xclk,
	
	//Memory Ins and Out
	output wire [19:0] sram_addr,
	output wire sram_we_n,
	output wire sram_oe_n,
	output wire sram_ce_a_n,
	output wire sram_ub_a_n,
	output wire sram_lb_a_n,
	inout wire [15:0] sram_data_io,
	
	//Microcontroller Ins and Outs
	input wire spi_clk,
	input wire spi_mosi,
	output wire spi_miso,
	input wire spi_select
	
);

//Main clock from the system, derived from input clock
wire sys_clk;

//SRAM Controller// 

//Internal signal definitions
wire sram_start;
wire sram_rw;
wire [15:0] sram_addr;


sram_ctrl sram
(
	.clk(sys_clk),
	.reset_n(reset),
	.start_n(sram_start),
	.rw(sram_rw),
	.addr_in(sram_addr_in),
);



endmodule
