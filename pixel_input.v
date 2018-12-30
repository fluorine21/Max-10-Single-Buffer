//Pixel input module

module pixel_input
#(parameter VSYNC_ACTIVE = 0)
(
	//Clock and reset
	input wire clk,
	input wire reset,
	
	//Camera Ins and Outs
	input wire camera_vsync, //Should be connected to filtered VSYNC in top level design
	input wire camera_hsync,
	input wire camera_pclk,
	input wire [7:0] camera_data,
	
	//Outputs to MUX
	output wire sram_start,
	output wire sram_rw,
	output wire [15:0] sram_addr,
	output wire [15:0] sram_data,
	input wire sram_ready,
	
	//Our outputs
	output wire frame_end,//Goes high when FFD9 has been recieved
	output wire error,
	output wire [15:0] stop_addr
	
);


wire [16:0] pixel_addr;
wire [7:0] pixel_data;
wire pixel_WE;
wire pixel_capture_reset;
wire internal_vsync;

pixel_capture #(VSYNC_ACTIVE) pc
(
	.reset(pixel_capture_reset),
	.clk(clk),
	.pixel_clk(camera_pclk),
	.vsync(camera_vsync),//to internal vsync
	.hsync(camera_hsync),
	.data_in(camera_data),
	.addr_out(pixel_addr),
	.data_out(pixel_data),
	.WE(pixel_WE)
);


pixel_writer #(VSYNC_ACTIVE) pw
(
	.clk(clk),
	.reset(reset),//Active low

	.pixel_addr(pixel_addr),//Incoming pixel write address
	.pixel_data(pixel_data),//Incoming pixel data
	.pixel_WE(pixel_WE),//Pixel latch
	.sram_ready(sram_ready),
	.pixel_vsync(camera_vsync),

	.sram_addr(sram_addr),
	.sram_data(sram_data),
	.sram_rw(sram_rw),
	.sram_start(sram_start),//
	.frame_end(frame_end),//Pulses when time has come to switch to sending process
	.error(error),//Signals when something has gone wrong (we see VSYNC before FFD9)
	.pixel_capture_reset(pixel_capture_reset),//Needed to reset the pixel capture module
	.stop_addr(stop_addr)//Should be connected to SPI controller, does not reset with module reset
);


endmodule
