//Pixel Capture Module

module pixel_capture
#(
parameter VSYNC_ACTIVE = 0
)
(
input wire reset,
input wire clk,
input wire pixel_clk,
input wire vsync,//to internal vsync
input wire hsync,
input [7:0] data_in,
output reg [16:0] addr_out,
output reg [7:0] data_out,
output reg WE
);

reg [1:0] state;
localparam [1:0] state_idle = 2'b00,
					  state_wait = 2'b01;

initial begin

	addr_out <= 17'b0;
	data_out <= 8'b0;
	state <= state_idle;
	WE <= 1'b0;
end




always @ (posedge clk or negedge reset or negedge vsync) begin
	if(reset == 1'b0 || vsync == VSYNC_ACTIVE) begin
		addr_out <= 17'b0;
		data_out <= 8'b0;
		state <= state_idle;
		WE <= 1'b0;
	end
	else begin
		case(state)
		
			state_idle: begin
			
				//If we see a valid pixel
				if(pixel_clk == 1'b1 && hsync == 1'b1) begin
					data_out <= data_in; //Push it onto the data output
					WE <= 1'b1;//start the write
					state <= state_wait;
				end
			
			
			end
			
			state_wait: begin
				//wait for pixelclk to go low
				if(pixel_clk == 1'b0) begin
					//reset WE
					WE <= 1'b0;
					addr_out <= addr_out + 1'b1; //advance to the next address
					state <= state_idle;//go to the idle state
				end
			
			end
		
		
		endcase
	end

end



endmodule

