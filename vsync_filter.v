//Digital filter for VSYNC input


module vsync_filter
#(
	parameter wait_cycles = 0,
	parameter VSYNC_ACTIVE = 0
)
(
	input wire clk,
	input wire reset,
	input wire vsync_in,
	output reg vsync_out
);

reg [1:0] vsync_state;
reg [1:0] vsync_count;

localparam [1:0]	state_first_wait = 2'b00,
						state_switch = 2'b01,
						state_second_wait = 2'b10;
				   
				   
initial begin
	reset_regs();
end

//State machine for the transmission process
always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
		//Internal state machine
		case(vsync_state)
			
			state_first_wait: begin
				//If the capture trigger is active
				if(vsync_in == VSYNC_ACTIVE) begin
					if(vsync_count >= wait_cycles) begin
						vsync_count <= 0;
						vsync_state <= state_switch;
					end
					else begin
						vsync_count <= vsync_count + 1'b1;
					end
				end
				//If not active, reset the counter
				else begin
					vsync_count <= 0;
				end
			
			end
		
			state_switch: begin
				//Perform the buffer switch
				vsync_out <= VSYNC_ACTIVE;
				//Wait for the frame to start
				vsync_state <= state_second_wait;
			end
			
			state_second_wait: begin
			//Once vsync deactivates
				if(vsync_in != VSYNC_ACTIVE) begin
					vsync_out <= !VSYNC_ACTIVE;
					vsync_state <= state_first_wait;
				end
			end
			
			default: begin
				vsync_state <= state_first_wait;
			end
			
		endcase
	end//not reset
end

task reset_regs;
begin
	vsync_state <= state_first_wait;
	vsync_count <= 2'b0;
end
endtask

endmodule
