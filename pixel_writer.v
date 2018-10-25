//Pixel writer
//Writes incomming pixels to memory
//Also packaged two pixels into one and writes them
//Should write to half of the current addr (shifted over by 1)

module pixel_reader
(
input wire clk,
input wire reset,//Active low, needs to be ORd with inverted select.

input wire [15:0] pixel_addr,//Incoming pixel write address
input wire [7:0] pixel_data,//Incoming pixel data
input wire pixel_WE,//Pixel latch
input wire sram_ready,

output reg [15:0] sram_addr,
output reg [15:0] sram_data,
output sram_we,
output reg sram_start,//
output reg frame_end,//Pulses when time has come to switch to sending process
output reg error,//Signals when something has gone wrong (we see VSYNC before FFD9)
output reg pixel_capture_reset//Needed to reser the pixel capture module
);

`define PIXEL_ACTIVE 1'b0;

reg [2:0] state;
reg [1:0] global_state;


//Defining internal states
localparam [2:0] state_wait_first = 3'b000,//wait for first pixel
					  state_wait_first_end = 3'b001,//Wait for first pixel to end (WE goes low)
					  state_wait_second = 3'b010, //Wait for first pixel
					  state_start_write = 3'b011, //Start pixel write to SRAM
					  state_end_write = 3'100; //Wait for SRAM ready and WE to go low, also check addr
					  
//Defining global states
localparam [1:0] state_wait_frame_end = 2'b00,//Waiting for VSYNC to go active
					  state_wait_frame = 2'b01,//Waitinf for VSYNC to turn off
					  state_frame_capture = 2'b10;//Capturing the frame
	
//Initial start_up values	
initial begin
	reset_regs();
end					  


always @ (negedge clk or negedge reset) begin
	
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
		case (global_state)
		
			//Reset state needed to catch the frame
			state_wait_frame_end: begin
				//Reset the pixel counter.
				pixel_capture_reset <= 1'b0;
				if(pixel_vsync == PIXEL_ACTIVE)
					global_state <= state_wait_frame;
				end
			end
		
			//Waiting for the frame to begin
			state_wait_frame: begin
				//Reset the pixel counter.
				pixel_capture_reset <= 1'b0;
			//If the frame is starting
					if(pixel_vsync != PIXEL_ACTIVE)
						//Turn on pixel capture
						pixel_capture_reset <= 1'b1;
						
						//Capture the frame
						global_state <= state_frame_capture;
						//state <= state_wait_first;
						
						//Turn off our vsync
						frame_end <= 1'b0;
					end
			
			end
			
			//Writing the frame to memory
			case state_frame_capture: begin
			
		
				//State machine
				case(state)
				
				state_wait_first: begin
					pixel_
					//If we see VSYNC active for some reason, then something has gone wrong
					if(pixel_vsync == PIXEL_ACTIVE) begin
						//Wait for the frame to start again
						global_state <= state_wait_frame;
						//Set the error flag
						error <= 1'b1;
					end
					//If we see an incomming pixel
					else if(pixel_WE == 1'b1) begin
						//Store it in the lower portion of the sram data buffer
						sram_data[7:0] <= pixel_data; 
						//store the address divided by 2 in our address buffer
						sram_addr <= (pixel_addr >> 1);
						
						//Advance to the next state
						state <= state_wait_first_end;
					end
				
				end
				
				state_wait_first_end: begin
					//If the write has ended
					if(pixel_WE == 1'b0)
						//Advance to the next state
						state <= state_wait_second;
					end
				
				end
				
				state_wait_second: begin
					//If we see the second pixel
					if(pixel_WE == 1'b1) begin
						//Write the pixel to the upper half of the data buffer
						sram_data[15:8] = pixel_data;
						
						//Advance to next state
						state <= state_start_write;
					end
				end
				
				state_start_write: begin
					//Start the write process
					sram_start <= 1'b0;
					//Wait for the write to end
					state <= state_end_write;
				
				end
				
				state_end_write: begin
					//if the memory is done and the pixel write went low
					if(sram_ready && pixel_WE == 1'b0) begin 
						//If the frame is done
						if(sram_data == 16'hFFD9) begin
							frame_end <= 1'b1;
							//Wait for the frame to end
							global_state <= state_wait_frame;
							state <= state_wait_first;
						end
						else begin
						//Reset
						state <= state_wait_first;
						end
					end		
				end
		
		
				endcase//local case
			
			end//local clause
		endcase//global case
		
	end//not reset

end//always


//Task for resetting everything
task reset_regs;
begin
	sram_addr <= 16'b0;
	sram_data <= 16'b0;
	sram_start <= 1'b1;//active low
	
	frame_end <= 1'b0;
	
	//Initializing our state
	state <= state_wait_first;
	global_state <= state_wait_frame_end;
	
	error <= 1'b0;
	
	pixel_capture_reset <= 1'b0;//Keep pixel capture in reset if we are reset
	
endtask


assign sram_we = 1'b0; //0 for a write

endmodule
