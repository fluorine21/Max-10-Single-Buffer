//Single Buffer Test Bench

`timescale 1ns / 1ps

module single_buffer_tb();


reg clk;
reg reset;
reg camera_vsync;
reg camera_hsync;
reg camera_pclk;
reg [7:0] camera_data;
wire camera_xclk;
wire [15:0] sram_addr;
wire sram_we_n;
wire sram_oe_n;
wire sram_ce_a_n;
wire sram_ub_a_n;
wire sram_lb_a_n;
wire [15:0] sram_data_io;
reg spi_clk;
reg spi_mosi;
wire spi_miso;
reg spi_select;
wire frame_ready;
wire error;

//reg [15:0] sram_data_in;
//assign sram_data_io = sram_we_n == 0 ? 16'bz : sram_data_in;

single_buffer_top sb
(
	//Global clock and reset inputs
	.clk_in(clk),
	.reset(reset),//Also used to cause a frame capture
	
	//Camera Ins and Outs
	.camera_vsync(camera_vsync),
	.camera_hsync(camera_hsync),
	.camera_pclk(camera_pclk),
	.camera_data(camera_data),
	.camera_xclk(camera_xclk),
	
	//Memory Ins and Out
	.sram_addr(sram_addr),
	.sram_we_n(sram_we_n),
	.sram_oe_n(sram_oe_n),
	.sram_ce_a_n(sram_ce_a_n),
	.sram_ub_a_n(sram_ub_a_n),
	.sram_lb_a_n(sram_lb_a_n),
	.sram_data_io(sram_data_io),
	
	//Microcontroller Ins and Outs
	.spi_clk(spi_clk),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_select(spi_select),
	.frame_ready(frame_ready),//1 when a frame can be read from memory
	.error(error)//1 when error has occured
	
);

d_mem mem(

	.reset(reset),
	.oe(sram_oe_n),
	.we(sram_we_n),
	.addr(sram_addr),
	.data_io(sram_data_io)

);

initial begin

//Initialize all input registers
clk = 1'b0;
reset = 1'b1;
camera_vsync = 1'b0;
camera_hsync = 1'b0;
camera_pclk = 1'b0;
camera_data = 8'b0;
//sram_data_in = 16'hAAFF;
spi_clk = 1'b0;
spi_mosi = 1'b0;
spi_select = 1'b0;



//Reset the system
reset_system();

//Send a dummy frame
send_camera_frame();

//Read the frame back
test_frame_size();
test_send_frame();

//Reset everything and try again
reset_system();

//Send a dummy frame
send_camera_frame();

//Read the frame back
test_frame_size();
test_send_frame();

end

task reset_system;
begin

repeat(20) clk_cycle();
reset = 1'b0;
repeat(20) clk_cycle();
reset = 1'b1;
repeat(20) clk_cycle();


end
endtask

task write_pixel;
begin

//Write the camera_data
cycle_camera_and_clk();
//Load the next pixel
camera_data = camera_data + 1'b1;


end
endtask

task send_camera_frame;
begin

//Set VSYNC and HSYNC high
camera_vsync = 1'b1;
camera_hsync = 1'b1;

//Start by writing the frame
repeat(100) write_pixel();

//Send FF D9
camera_data = 8'hFF;
cycle_camera_and_clk();
camera_data = 8'hD9;
cycle_camera_and_clk();

//Cycle the main clock a few times
repeat(20) clk_cycle();

//Set VSYNC and HSYNC low
camera_vsync = 1'b0;
camera_hsync = 1'b0;


end
endtask

task test_frame_size;
begin

//Send 8'h7F
send_byte(8'h7F);

//read 3 bytes
read_byte(16'h03);

//cycle the main clock a few times
repeat(10) clk_cycle();


end
endtask

task test_send_frame;
begin

//Send 8'hBF
send_byte(8'hBF);

//read 103 bytes
read_byte(103);

//cycle the main clock a few times
repeat(10) clk_cycle();


end
endtask

task read_byte;
input [15:0] num;
reg [15:0] i;
begin

//Give the clock a few cycles
repeat(5) clk_cycle();
for(i = 0; i < num; i = i + 1)begin
	
	repeat(5) clk_cycle();
	//Put select active
	//spi_select = SELECT_ACTIVE;
	//cycle the clock 8 times
	repeat(8) cycle_both();
	//Turn off select
	//spi_select = !SELECT_ACTIVE;
	repeat(5) clk_cycle();
	
end
repeat(5) clk_cycle();

end
endtask

task send_byte;
input [7:0] data;
reg [4:0] i;
begin
repeat(5) clk_cycle();
	//put select line active
	//spi_select = SELECT_ACTIVE;
	repeat(2) clk_cycle();
	
	for(i = 0; i < 8; i = i + 1) begin
		//Set the data line
		spi_mosi = data[7 - i];
		//Cycle the clock
		cycle_both();
	end
	//spi_select = !SELECT_ACTIVE;
	repeat(5) clk_cycle();

end
endtask


task cycle_both;
begin

	clk_cycle();
	spi_clk = 1'b1;
	repeat(2) clk_cycle();
	spi_clk = 1'b0;
	clk_cycle();

end
endtask

task cycle_camera_and_clk;
begin

	clk_cycle();
	camera_pclk = 1'b1;
	repeat(2) clk_cycle();
	camera_pclk = 1'b0;
	clk_cycle();
	
end
endtask


task clk_cycle;
begin

	repeat(2)  #1 clk = ~clk;

end
endtask


endmodule

