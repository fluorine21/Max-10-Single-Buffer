//pixel output test bench

`timescale 1 ns / 1 ps
module pixel_output_tb();

localparam SELECT_ACTIVE = 1'b0;

reg clk;
reg reset;

wire spi_start;
wire spi_rw;
wire [15:0] spi_addr;

reg [15:0] spi_data;

reg spi_clk;
reg spi_mosi;
wire spi_miso;
reg spi_select;

reg [15:0] stop_addr;
reg spi_ready;

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



initial begin

//Set up all of the signals
clk = 1'b0;
reset = 1'b1;
spi_data = 16'hAAFF;
spi_clk = 1'b0;
spi_mosi = 1'b0;
spi_select = 1'b0;
stop_addr = 16'h1F;
spi_ready = 1'b1;

//Reset everything
repeat(10) clk_cycle();
reset = 1'b0;
repeat(10) clk_cycle();
reset = 1'b1;
repeat(10) clk_cycle();

test_frame_size();
test_send_frame();

end

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

//read 1F bytes
read_byte(16'h1F);

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


task clk_cycle;
begin

	repeat(2)  #1 clk = ~clk;

end
endtask

endmodule
