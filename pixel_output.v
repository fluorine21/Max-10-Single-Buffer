//Pixel output module

module pixel_output
(
	//Clocks and resets
	input wire clk,//Global clock, will be used to generate SPI clk
	input wire reset,

	//MUX Signals
	output wire sram_start,
	output wire sram_rw,
	output wire [15:0] sram_addr,
	input wire [15:0] sram_data,
	input wire sram_ready,
	
	//SPI Signals
	input wire spi_clk,
	input wire spi_mosi,
	output wire spi_miso,
	input wire spi_select,
	
	//Stop address from pixel input
	input wire [15:0] stop_addr
);

wire do_valid;
wire di_req;
wire wr_ack;
wire [7:0] data_from_spi;
wire [7:0] data_to_spi;
wire wren;

spi_controller spi_ctrl
(
	.clk(clk),
	.reset(reset),
	
	//SRAM
	.sram_ready(sram_ready), //Ready signal from pixel reader_ready
	.stop_addr(stop_addr),//Last address from pixel writer
	.sram_addr(sram_addr),
	.sram_data(sram_data),//Data from reader is valid

	.sram_start(sram_start),
	.sram_rw(sram_rw),
	
	//SPI inputs
	.do_valid(do_valid),
	.di_req(di_req),
	.wr_ack(wr_ack),
	.spi_data_in(data_from_spi),
	
	//Outputs
	.spi_data_out(data_to_spi),//To SPI controller
	.wren(wren)//to spi controller
	
);

wire int_spi_clk;

spi_slave spi_sl
(
	//Might be clocked at a different speed
	.clk_i(clk), //internal interface clock (clocks di/do registers)
	.spi_ssel_i(spi_select), //spi bus slave select line
	.spi_sck_i(spi_clk),  //spi bus sck clock (clocks the shift register core)
	.spi_mosi_i(spi_mosi), //spi bus mosi input
	.spi_miso_o(spi_miso), //spi bus spi_miso_o output
	.di_req_o(di_req),   //preload lookahead data request line
	.di_i(data_to_spi), //parallel load data in (clocked in on rising edge of clk_i)
	.wren_i(wren), //user data write enable
	.wr_ack_o(wr_ack), //write acknowledge
	.do_valid_o(do_valid), //do_o data valid strobe, valid during one clk_i rising edge.
	.do_o(data_from_spi) //parallel output (clocked out on falling clk_i)
);

//SPI Clock Generation




endmodule

