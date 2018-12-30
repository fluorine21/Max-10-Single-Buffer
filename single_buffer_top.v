//Top Level module


module single_buffer_top
(
	//Global clock and reset inputs
	input wire clk_in,
	input wire reset,//Also used to cause a frame capture
	
	//Camera Ins and Outs
	input wire camera_vsync,
	input wire camera_hsync,
	input wire camera_pclk,
	input wire [7:0] camera_data,
	output wire camera_xclk,
	
	//Memory Ins and Out
	output wire [15:0] sram_addr,
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
	input wire spi_select,
	output wire frame_ready,//1 when a frame can be read from memory
	output wire error//1 when error has occured
	
);

//Uncomment if you want to use PLL for XCLK
//`define USE_PLL

localparam VSYNC_ACTIVE = 1'b0;

//PLL defs
wire clk;
assign clk = clk_in;

//VSYNC filter
wire internal_vsync;
vsync_filter #(0, VSYNC_ACTIVE) vf
(
	.clk(clk),
	.reset(reset),
	.vsync_in(camera_vsync),
	.vsync_out(internal_vsync)
);


//pll120_60 pll
//(
//	.areset(reset),
//	.inclk0(clk_in),
//	.c0(clk)
//);


//Buffer Controller

wire mux_select;
single_ctrl #(1) s_ctrl
(
	.clk(clk),
	.reset(reset),
	.pixel_vsync(frame_ready),//From pixel_writer module
	.select(mux_select)//0 for read frame 1 for write
);



/////////////////////////
/////Memory Components///
/////////////////////////

wire pixel_start;
wire pixel_rw;
wire [15:0] pixel_addr;
wire [15:0] pixel_data;
wire pixel_ready;

wire spi_start;
wire spi_rw;
wire [15:0] spi_addr;
wire [15:0] spi_data;
wire spi_ready;

wire [15:0] dummy_data;

assign dummy_data = 16'b0;

mux_and_sram ms
(
	//SRAM Controller Signals
	.sram_clk(clk),//Needs to be half of sys_clk
	.reset(reset),
	
	//MUX Input
	.select(mux_select),
	
	.start_a(pixel_start),
	.rw_a(pixel_rw),
	.addr_a(pixel_addr),
	.data_a(pixel_data),
	
	.start_b(spi_start),
	.rw_b(spi_rw),
	.addr_b(spi_addr),
	.data_b(dummy_data),
	
	//MUX output
	.data_out(spi_data),
	.ready_a(pixel_ready),
	.ready_b(spi_ready),

	//SRAM Signals
	.sram_addr(sram_addr),
	.sram_we_n(sram_we_n),
	.sram_oe_n(sram_oe_n),
	.sram_ce_a_n(sram_ce_a_n),
	.sram_ub_a_n(sram_ub_a_n),
	.sram_lb_a_n(sram_lb_a_n),
	.sram_data_io(sram_data_io) 
);


///////////////////
/////Pixel Input///
///////////////////

wire [15:0] stop_addr;

pixel_input #(VSYNC_ACTIVE) pi
(
	//Clock and reset
	.clk(clk),
	.reset(reset),
	
	//Camera Ins and Outs
	.camera_vsync(internal_vsync), //Should be connected to filtered VSYNC in top level design
	.camera_hsync(camera_hsync),
	.camera_pclk(camera_pclk),
	.camera_data(camera_data),
	
	//Outputs to MUX
	.sram_start(pixel_start),
	.sram_rw(pixel_rw),
	.sram_addr(pixel_addr),
	.sram_data(pixel_data),
	.sram_ready(pixel_ready),
	
	//Our outputs
	.frame_end(frame_ready),//Goes high when FFD9 has been recieved
	.error(error),
	.stop_addr(stop_addr)
	
);

////////////////////
/////Pixel Output///
////////////////////

pixel_output po
(
	//Clocks and resets
	.clk(clk),//Global clock, will be used to generate SPI clk
	.reset(reset),

	//MUX Signals
	.sram_start(spi_start),
	.sram_rw(spi_rw),
	.sram_addr(spi_addr),
	.sram_data(spi_data),
	.sram_ready(spi_ready),
	
	//SPI Signals
	.spi_clk(spi_clk),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_select(spi_select),
	
	//Stop address from pixel input
	.stop_addr(stop_addr)
);


`ifdef USE_PLL
//XCLK generation
pll120_30 pll
(
	.areset(reset),
	.inclk0(clk_in),
	.c0(camera_xclk)
);
`else
divide_4 d4
(
	.clk_in(clk_in),
	.reset(reset),
	.clk_out(camera_xclk)
);
`endif

endmodule


