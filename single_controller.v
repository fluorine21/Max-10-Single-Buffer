//Single Buffer Controller

module single_ctrl
#(
parameter  VSYNC_ACTIVE = 0
)
(
input wire clk,
input wire reset,
input wire pixel_vsync,//From pixel_writer module
output select//0 for read frame 1 for write
);



reg state;

//State machine definitions
localparam state_wait_pixel_end = 1'b0,//Wait for the pixel reader to tell us its done
				     state_halt = 1'b1;//Wait until reset to take a new image

always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
	
		case(state)
		
			state_wait_pixel_end: begin
				if(pixel_vsync == VSYNC_ACTIVE) begin
					state <= state_halt;
				end
			
			end
			
			state_halt: begin
				//Wait here until reset
			end
			
			default: begin
				state <= state_wait_pixel_end;
			end
		
		endcase
	
	end


end

task reset_regs;
begin

state <= state_wait_pixel_end;

end
endtask

assign select = state;//same encoding

endmodule
