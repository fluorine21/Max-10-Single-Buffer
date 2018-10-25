//Double MUX for buffer switching

module double_mux
(
//Inputs from controllers

//A group
input wire start_a,
input wire rw_a
input wire [15:0] addr_a,
input wire [15:0] data_a,
//B group
input wire start_b,
input wire rw_b,
input wire [15:0] addr_b,
input wire [15:0] data_b,

//Sram data and ready input
input wire [15:0] sram_data,
input wire sram_ready,

input wire select,//0 = A, 1 = B

//Outputs to sram
output wire sram_start,
output wire sram_rw,
output wire [15:0] sram_addr,
output wire [15:0] sram_data,

//Outputs to A and B modules
output wire [15:0] data_a,
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


endmodule
