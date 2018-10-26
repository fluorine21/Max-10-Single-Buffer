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

//SRAM Controller
sram_ctrl sram
(
	.clk(sys_clk),
	.reset_n(reset),
	.start_n(sram_start),
	.rw(sram_rw),
	.addr_in(sram_controller_addr),
	.data_write(sram_controller_data),
	//outputs
	.ready(sram_ready),
	.data_read(sram_data_out),//Data from SRAM
	.sram_addr(sram_addr),
	.we_n(sram_we_n)
	.oe_n(sram_oe_n),
	.ce_a_n(sram_ce_a_n),
	.ub_a_n(sram_ub_a_n), 
	.lb_a_n(sram_lb_a_n),
	//inout
	.data_io(sram_data_io)
);

//MUX
single_mux
(
	//Inputs from controllers

	//A group
	.start_a(pixel_start),
	.rw_a(pixel_rw),
	.addr_a(pixel_sram_addr),
	.data_a(pixel_sram_data),
	//B group
	.start_b(reader_start),
	.rw_b(reader_rw),
	.addr_b(reader_addr),
	.data_b(reader_data),

	//Sram data and ready input
	.sram_data_out(sram_data_out),//Data from SRAM
	.sram_ready(sram_ready),

	.select(mux_select),//0 = A, 1 = B

	//Outputs to sram
	.sram_start(sram_start),
	.sram_rw(sram_rw),
	.sram_addr(sram_controller_addr),
	.sram_data(sram_controller_data),

	//Outputs to A and B modules
	.data_b(reader_data_in),
	.ready_a(pixel_ready),
	.ready_b(reader_ready)
); 

endmodule
