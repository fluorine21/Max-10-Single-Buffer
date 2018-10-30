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
	input wire spi_select,
	output wire frame_ready,//1 when a frame can be read from memory
	
);

//Main clock from the system, derived from input clock
wire sys_clk;

//SRAM Controller// 

//Internal signal definitions
wire sram_start;
wire sram_rw;
wire [15:0] sram_addr;

///////////////////////
///Memory Components///
///////////////////////

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
	.we_n(sram_we_n)
	.oe_n(sram_oe_n),
	.ce_a_n(sram_ce_a_n),
	.ub_a_n(sram_ub_a_n), 
	.lb_a_n(sram_lb_a_n),
	//inout
	.data_io(sram_data_io)
);

//MUX
single_mux mux
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


/////////////////
///Pixel Input///
/////////////////

pixel_writer pw
(
	.clk(sys_clk),
	.reset,//Active low, needs to be ORd with inverted select.

	.pixel_addr(pixel_addr),//Incoming pixel write address
	.pixel_data(pixel_data),//Incoming pixel data
	.pixel_WE(pixel_WE),//Pixel latch
	.sram_ready(pixel_sram_ready),

	.sram_addr(pixel_sram_addr),
	.sram_data(pixel_sram_data),
	.sram_rw(pixel_rw),
	.sram_start(pixel_start),//
	.frame_end(pixel_writer_vsync),//Pulses when time has come to switch to sending process
	.error(),//Signals when something has gone wrong (we see VSYNC before FFD9)
	.pixel_capture_reset(pixel_capture_reset),//Needed to reser the pixel capture module
	.stop_addr()//Should be connected to SPI controller, does not reset with module reset
);

pixel_capture pc
(
.reset(reset),
.clk(sys_clk),
.pixel_clk(camera_pclk),
.vsync(internal_vsync),//to internal vsync
.hsync(camera_hsync),
.data_in(camera_data),
.addr_out(pixel_addr),
.data_out(pixel_data),
.WE(pixel_WE)
);

//////////////////
///Pixel Output///
//////////////////

pixel_reader pr
(
	.clk(sys_clk),
	.reset(reset),
	.sram_ready(reader_ready),//Sram ready line
	.read_addr(),//pixel to be read
	.sram_data(read_sram_data),//Data from the sram
	.RE(),//Read enable, it set to 1, triggers a read operation

	.sram_addr(pixel_sram_addr),//Read address to sram
	.data_out(),//Current pixel
	.sram_rw(reader_rw),//1 for a read
	.sram_start(reader_start),//0 is active
	.ready() //Set to 1 when data is valid
);

endmodule
