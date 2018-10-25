//Single Buffer Controller

module single_ctrl
(
input wire clk,
input wire reset,
input wire pixel_vsync,//Directly from the camera (to a pin)
output wire select,//0 for read frame 1 for write
output reg internal_vsync //Filtered VSYNC
);

reg state;

//State machine definitions
localparam [1:0] = state_wait_pixel_end = 1'b0,
						 state_halt = 1'b1;

always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
	
		case(state)
		
		state_wait_pixel: begin
			if(pixel_vsync)
				state <= state_halt;
			end
		
		end
		
		state_halt: begin
			//Wait here until reset
		end
	
	end


end

`define wait_cycles 0
reg [1:0] vsync_state;

localparam [1:0] = state_first_wait = 2'b00,
				   state_switch = 2'01,
				   state_second_wait = 2'b10;

//State machine for the transmission process
always @ (posedge clk) begin

	case(vsync_state)
		
		state_first_wait: begin
			//If the capture trigger is active
			if(pixel_vsync) begin
				if(vsync_count >= wait_cycles) begin
					vsync_count <= 0;
					vsync_state <= state_switch;
				end
				else begin
					vsync_count <= cap_count + 1'b1;
				end
			end
			//If not active, reset the counter
			else begin
				vsync_count <= 0;
			end
		
		end
	
		state_switch: begin
			//Perform the buffer switch
			internal_vsync <= 1'b1;
			//Wait for the frame to start
			vsync_state <= state_second_wait;
		end
		
		state_second_wait: begin
		//Once vsync deactivates
			if(!pixel_vsync) begin
				internal_vsync <= 1'b0;
				vsync_state <= state_first_wait;
			end
		end
		
		default: begin
			vsync_state <= state_first_wait;
		end
		
	endcase
end

task reset_regs;
begin

state <= state_wait_pixel;

end
endtask

assign select = statel;//same encoding

endmodule
