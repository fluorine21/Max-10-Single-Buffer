//mux_and_sram_tb
`timescale 1 ns / 1 ps
module mux_and_sram_tb();

reg clk;
reg reset;
reg mux_select;

//Pixel writer inputs
reg pixel_start;
reg pixel_rw;
reg [15:0] pixel_addr;
reg [15:0] pixel_data;

//SPI controller inputs
reg spi_start;
reg spi_rw;
reg [15:0] spi_addr;
reg [15:0] dummy_data;

wire [15:0] spi_data;
wire pixel_ready;
wire spi_ready;

wire [15:0] sram_addr;
wire sram_we_n;
wire sram_oe_n;
wire sram_ce_a_n;
wire sram_ub_a_n;
wire sram_lb_a_n;
wire [15:0] sram_data_io;

reg [15:0] sram_sim_data;
reg enable_z;
assign sram_data_io = enable_z ? 16'bz : sram_sim_data;

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

initial begin

//Simulate pixel input writing a pixel
clk = 1'b0;
reset = 1'b1;
mux_select = 1'b0;
pixel_start = 1'b1;
pixel_rw = 1'b0;
pixel_addr = 16'b0;
pixel_data = 16'b0;

spi_start = 1'b1;
spi_rw = 1'b1;
spi_addr = 16'b0;


enable_z = 1'b1;
sram_sim_data = 16'b0;

repeat(5) clk_cycle();

//Try writing some pixels
repeat(20) write_pixel();

//Change to SPI
mux_select = 1'b1;
enable_z = 1'b0;
repeat(20) clk_cycle();

//Try reading some pixels
repeat(20) read_pixel();


end

task write_pixel;
begin

//Tell sram to start the write
pixel_start = 1'b0;
clk_cycle();
pixel_start = 1'b1;
while(pixel_ready == 1'b0)begin
	clk_cycle();
end
//increment the address and data
pixel_addr = pixel_addr + 1'b1;
pixel_data = pixel_data + 1'b1;
clk_cycle();

end
endtask

task read_pixel;
begin

spi_start = 1'b0;
clk_cycle();
spi_start = 1'b1;
while(spi_ready == 1'b0)begin
	clk_cycle();
end
spi_addr = spi_addr + 1'b1;
sram_sim_data = sram_sim_data + 1'b1;
clk_cycle();

end
endtask

task clk_cycle;
begin

repeat(2) #10 clk = ~clk;

end
endtask

endmodule
