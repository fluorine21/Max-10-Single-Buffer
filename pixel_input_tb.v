//pixel input tb

`timescale 1 ns / 1 ns

module pixel_input_tb();

reg clk;
reg reset;
reg camera_vsync;
reg camera_hsync;
reg camera_pclk;
reg [7:0] camera_data;
reg pixel_ready;

///////////////////
/////Pixel Input///
///////////////////

wire [15:0] stop_addr;
wire pixel_start;
wire pixel_rw;
wire [15:0] pixel_addr;
wire [15:0] pixel_data;
wire frame_ready;
wire error;



pixel_input #(0) pi
(
	//Clock and reset
	.clk(clk),
	.reset(reset),
	
	//Camera Ins and Outs
	.camera_vsync(camera_vsync), //Should be connected to filtered VSYNC in top level design
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

initial begin

//Set up our signals
camera_vsync = 1'b1;
camera_hsync = 1'b1;
camera_pclk = 1'b0;


//Setting up data
camera_data = 8'b0;
pixel_ready = 1'b1;


//Perform a full reset
clk = 1'b0;
reset = 1'b0;

repeat(10) clk_cycle();

reset = 1'b1;

//Restart the frame
camera_vsync = 1'b0;
repeat(10) clk_cycle();
camera_vsync = 1'b1;
repeat(10) clk_cycle();


//Going to main test vector

write_pixels();

end

task write_pixels;
begin

//Start by writing the frame
repeat(100) write_pixel();

//Send FF D9
camera_data = 8'hFF;
repeat(1) clk_cycle();
camera_pclk = 1'b1;
repeat(3) clk_cycle();
camera_pclk = 1'b0;
repeat(2) clk_cycle();
camera_data = 8'hD9;
repeat(1) clk_cycle();
camera_pclk = 1'b1;
repeat(3) clk_cycle();
camera_pclk = 1'b0;
repeat(20) clk_cycle();

end
endtask

task write_pixel;
begin

//Write the camera_data
camera_pclk = 1'b1;
repeat(3) clk_cycle();
camera_pclk = 1'b0;
repeat(2) clk_cycle();
//Load the next pixel
camera_data = camera_data + 1'b1;
repeat(1) clk_cycle();

end
endtask

task clk_cycle;
begin

repeat(2) #10 clk = ~clk;

end
endtask

endmodule
