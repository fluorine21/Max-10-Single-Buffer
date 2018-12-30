//MUX and SRAM controller

module mux_and_sram
(
	//SRAM Controller Signals
	input wire sram_clk,
	input wire reset,
	
	//MUX Input
	input wire select,
	
	input wire start_a,
	input wire rw_a,
	input wire [15:0] addr_a,
	input wire [15:0] data_a,
	
	input wire start_b,
	input wire rw_b,
	input wire [15:0] addr_b,
	input wire [15:0] data_b,
	
	//MUX output
	output wire [15:0] data_out,
	output wire ready_a,
	output wire ready_b,

	//SRAM Signals
	output wire [15:0] sram_addr,
	output wire sram_we_n,
	output wire sram_oe_n,
	output wire sram_ce_a_n,
	output wire sram_ub_a_n,
	output wire sram_lb_a_n,
	inout wire [15:0] sram_data_io 
);

wire sram_start;
wire sram_rw;
wire [15:0] sram_controller_addr;
wire [15:0] sram_controller_data;
wire sram_ready;
wire [15:0] sram_data_out;

//SRAM Controller
sram_ctrl sram
(
	.clk(sram_clk),//special 1/2 sysclock for sram
	.reset_n(reset),
	.start_n(sram_start),
	.rw(sram_rw),
	.addr_in(sram_controller_addr),
	.data_write(sram_controller_data),
	//outputs
	.ready(sram_ready),
	.data_read(sram_data_out),//Data from SRAM
	.sram_addr(sram_addr),
	.we_n(sram_we_n),
	.oe_n(sram_oe_n),
	.ce_a_n(sram_ce_a_n),
	.ub_a_n(sram_ub_a_n), 
	.lb_a_n(sram_lb_a_n),
	//inout
	.data_io(sram_data_io)
);

wire pixel_start;
wire pixel_rw;
wire [15:0] pixel_sram_addr;
wire [15:0] pixel_sram_data;
wire spi_start;
wire spi_rw;
wire [15:0] spi_addr;
wire [15:0] spi_data;
wire [15:0] spi_data_in;
wire pixel_ready;
wire spi_ready;
wire mux_select;

//MUX
single_mux mux
(
	//Inputs from controllers

	//A group
	.start_a(start_a),
	.rw_a(rw_a),
	.addr_a(addr_a),
	.data_a(data_a),
	//B group
	.start_b(start_b),
	.rw_b(rw_b),
	.addr_b(addr_b),
	.data_b(data_b),

	//Sram data and ready input
	.sram_data_out(sram_data_out),//Data from SRAM
	.sram_ready(sram_ready),

	.select(select),//0 = A, 1 = B

	//Outputs to sram
	.sram_start(sram_start),
	.sram_rw(sram_rw),
	.sram_addr(sram_controller_addr),
	.sram_data(sram_controller_data),

	//Outputs to A and B modules
	.data_out_b(data_out),
	.ready_a(ready_a),
	.ready_b(ready_b)
);


endmodule
