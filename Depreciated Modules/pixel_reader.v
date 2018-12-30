//Pixel reader
//Reads pixels from memory at request of another device
//Pixels MUST be read sequentially




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Version 2, reads automatically after second pixel is read
module pixel_reader_auto
(
input wire clk,
input wire reset,//Needs to be held in reset by buffer controller when not in use
input wire sram_ready,
//input wire [15:0] read_addr, //Don't actually need this any more
input wire [15:0] sram_data,
input wire RE,//Read enable, it set to 1, triggers a read operation, needs to eventually be 0 for module to advance

output reg [15:0] sram_addr,//Read address to sram
output reg [7:0] data_out,//Current pixel
output wire sram_rw,//1 for a read
output reg sram_start,//0 is active
output reg ready, //Set to 1 when data is valid
output reg frame_done//vsync signal, goes high when FFD9 has been read
);


//State Definitons
reg state[1:0]

localparam [1:0] state_read_data = 2'b00,//Requests data from SRAM from start address
				 state_finish_read = 2'b01,//Finishes up the read and puts the first byte out when requested
				 state_wait_first = 2'b10,//Waits for RE to go low and then advances to finish_second
				 state_finish_second = 2'b11;//Puts the second byte out when requested and performs the next read

//Register for holding our current address
reg [15:0] current_addr;

initial begin
	reset_regs();
end

always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
		case(state)//state machine
		
		state_read_data: begin
			//If read enable has gone low, we can advance
			if(RE == 1'b0) begin
				//Reset data ready
				ready <= 1'b0;
				//Push the current address out to the SRAM
				sram_addr <= current_addr;
				state <= state_finish_read;
				sram_start = 1'b0;
			end
			
		end
		
		state_finish_read: begin
			//Reset the start line
			sram_start = 1'b1;
			//If the SRAM is done
			if(sram_ready == 1'b1) begin
				//Store the data
				current_data <= sram_data;
				//If a pixel is being requested
				if(RE == 1'b1) begin
					data_out <= sram_data[7:0];
					ready <= 1'b1;
					state <= state_wait_first;
				end
			end
		end
		
		state_wait_first: begin
			//Wait for RE to go low
			if(RE == 1'b0) begin
				//Wait for request for second pixel
				ready <= 1'b0;
				state <= state_finish_second;
			end
		end
		
		state_finish_second: begin
			//If the second pixel has been requested
			if(RE == 1'b1) begin
				data_out <= current_data[15:8];
				current_addr <= current_addr + 1;
				state <= state_read_data;
				//If we're at the end of the image
				if(current_data == 16'bFFD9) begin
					frame_done <= 1'b1;
				end
			end
		end
		
		default begin
			reset_regs();
		end
	
		endcase//state
	end//not reset
end

assign sram_rw = 1'b1;//1 for a read

task reset_regs;
begin

	state <= state_wait_request;
	current_addr <= 16'b0;
	sram_addr <= 16'b0;
	data_out <= 8'b0;
	sram_start <= 1'b1;
	ready <= 1'b0;
	frame_done <= 1'b0;
	

end
endtask

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Version 1, reads pixel when recieving request
module pixel_reader
(
input wire clk,
input wire reset,//Needs to be connected to SPI controller
input wire sram_ready,
input wire [15:0] read_addr,
input wire [15:0] sram_data,
input wire RE,//Read enable, it set to 1, triggers a read operation

output reg [15:0] sram_addr,//Read address to sram
output reg [7:0] data_out,//Current pixel
output wire sram_rw,//1 for a read
output reg sram_start,//0 is active
output reg ready //Set to 1 when data is valid
);


//State Definitons
reg state[1:0]

localparam [1:0] state_wait_request = 2'b00,
					  state_finish_sram = 2'b01,
					  state_finish_read = 2'b10;


//Register for holding our data being read
reg [15:0] current_data;

initial begin
	reset_regs();
end

always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin
		case(state)//state machine
		
		state_wait_request: begin//Checks to see if RE is active, indicating that something wants a pixel
			if(RE == 1'b1) begin
				
				ready <= 1'b0;//Reser ready line to indicate that a read is in progress
				//If we need the lower portion of the address
				if(read_addr[0] == 1'b0)
					//Start an SRAM read
					sram_addr <= read_addr;
					sram_start <= 1'b0;
					state <= state_finish_sram;
				end
				else begin
					//Set our data output to be the upper byte of the buffer
					data_out <= current_data[15:8];
					state <= state_finish_read;
				end
			end
		end
		
		state_finish_sram: begin
			//Reset the start line
			start <= 1'b1;
			//If the SRAM is done
			if(sram_ready == 1'b1) begin
				//Read in the data
				current_data <= sram_data;
				data_out <= sram_data[7:0];
				//Go back to the idle state
				state <= state_wait_request;
			
			end
		
		end
		
		state_finish_read: begin //Finishes off a higher portion read (one that we already have from the lower portion read)
			//Just set ready back to one and go back to idle
			ready <= 1'b1;
			state <= state_wait_request;
		end
		
		default begin
			reset_regs();
		end
	
		endcase//state
	end//not reset
end

assign sram_rw = 1'b1;

task reset_regs;
begin

	state <= state_wait_request;
	current_data <= 16'b0;
	sram_addr <= 16'b0;
	data_out <= 8'b0;
	sram_start <= 1'b1;
	ready <= 1'b0;
	

end
endtask

endmodule


