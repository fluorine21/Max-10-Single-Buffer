//Double MUX for buffer switching

module single_mux
(
//Inputs from controllers

//A group from pixel writer
input wire start_a,
input wire rw_a
input wire [15:0] addr_a,
input wire [15:0] data_a,
//B group from pixel reader
input wire start_b,
input wire rw_b,
input wire [15:0] addr_b,
input wire [15:0] data_b,/

//Sram data and ready input
input wire [15:0] sram_data_out,//To data output of sram controller
input wire sram_ready,//input from sram

input wire select,//0 = A, 1 = B

//Outputs to sram
output wire sram_start,
output wire sram_rw,
output wire [15:0] sram_addr,
output wire [15:0] sram_data,

//Outputs to A and B modules
output wire [15:0] data_b,
output wire ready_a,
output wire ready_b

);


//Assign for sram lines
assign sram_start = select ? start_b : start_a;
assign sram_rw = select ? rw_b : rw_a;
assign sram_addr = select ? addr_b : addr_a;
assign sram_data = select ? data_b : data_a;

//Assign for outputs to A and B modules

assign data_b = select ? sram_data_out : 16'bz;
assign ready_a = select ? 1'b0 : sram_ready;
assign ready_b = select ? sram_ready : 1'b0;


endmodule
