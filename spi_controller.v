//new SPI controller that isn't such garbage

module spi_controller
(
	input wire clk,
	input wire reset,
	
		
	//SRAM
	input wire sram_ready, //Ready signal from pixel reader_ready
	input wire [15:0] stop_addr,//Last address from pixel writer
	output reg [15:0] sram_addr,
	input wire [15:0] sram_data,//Data from reader is valid
	output reg sram_start,
	output sram_rw,
	
	//SPI inputs
	input wire do_valid,//1 if incomming spi data
	input wire di_req,
	input wire wr_ack,
	input wire [7:0] spi_data_in,
	
	//Outputs
	output reg [7:0] spi_data_out,//To SPI controller
	output reg wren//to spi controller
	
);
reg [15:0] next_pixel;
reg [15:0] next_pixel_next;
//Input latching
//reg sram_ready,
//reg [15:0] stop_addr,
//reg [15:0] sram_data,


//State machine calculations

reg [1:0] global_state_next;
reg [2:0] state_next;
reg [1:0] size_count_next;
reg [15:0] sram_addr_next;
reg sram_start_next;
reg [7:0] spi_data_out_next;
reg wren_next;


reg [1:0] global_state;
reg [2:0] state;
reg [1:0] size_count;

initial begin
	reset_regs();
end

//Global state defs
localparam [1:0] global_idle = 2'b00,//wait for command
				 send_size   = 2'b01,//Send the lenght
				 send_data   = 2'b10;//Send the frame
		    
//Local state defs
localparam [2:0] get_word   = 3'b000,//Get the word from the sram
				 send_first_byte = 3'b001,//Send 0th byte
				 wren_ack  = 3'b010,//Wait for the SPI controller to ack the write
				 send_second_byte = 3'b011,//send 1st byte
				 cleanup    = 3'b100;//Increment counters and get next word


//State Machine Combinational Logic
always @ * begin

	//Default values
	
	global_state_next <= global_state;
	state_next <= state;
	size_count_next <= size_count;
	sram_addr_next <= sram_addr;
	sram_start_next <= sram_start;
	spi_data_out_next <= spi_data_out;
	wren_next <= wren;
	next_pixel_next <= next_pixel;
	
	//State machine
	case(global_state)

		//Idle state
		global_idle: begin
			if(do_valid == 1'b1) begin//If we have a valid byte
					if(spi_data_in == 8'h7F) begin//If we're supposed to send the image size
						state_next <= get_word;
						global_state_next <= send_size;
						size_count_next <= 2'b0;
						
						//Set up the SRAM to record the first two pixels
						sram_addr_next <= 16'b0;
						sram_start_next <= 1'b0;
						
					end
					else if(spi_data_in == 8'hBF) begin//If we're supposed to send the image
						state_next <= send_first_byte;
						global_state_next <= send_data;
						//Increment addr as we're about to start the next read
						sram_addr_next <= sram_addr + 1'b1;

					end
			end
		end

		send_size: begin

			case(state)//Local state machine for sending length
			
				get_word: begin
					//Figuring out which byte of size needs to be sent
					sram_start_next <= 1'b1;//Reset the sram start line
						if(size_count == 2'b00) begin
							spi_data_out_next <= (stop_addr[15:8] << 1);
						end
						else if(size_count == 2'b01) begin
							spi_data_out_next <= (stop_addr[7:0] << 1);
						end
						else begin
							spi_data_out_next <= 8'b0;
						end
					
						state_next <= send_first_byte;
						
					
				end
				
				send_first_byte: begin
					if(di_req == 1'b1)begin
					//enable write
					wren_next <= 1'b1;
					//Wait for the acknowledgement
					state_next <= wren_ack;
					end
					
				end
				
				wren_ack: begin
				
					if(wr_ack == 1'b1) begin//SPI interface has begun transmission
						wren_next <= 1'b0; //reset the start line
						state_next <= cleanup;
					end
				
				end
				
				cleanup: begin
					
					//Don't actually need to wait for anything here, we only change external signals when di_req goes high
					if(size_count == 2'b10) begin //If we're done transmitting the image size
						size_count_next <= 2'b0;
						global_state_next <= global_idle;
						state_next <= get_word;
						spi_data_out_next <= 8'b0;
					end
					else begin
					//If the SRAM has our byte
						if(sram_ready == 1'b1) begin
							next_pixel_next <= sram_data;
						end
						size_count_next <= size_count + 1'b1;
						state_next <= get_word;
					end
				
				end//cleanup case
				
				
				default: begin
					global_state_next <= global_idle;
					state_next <= get_word;
				end
				
			endcase //local size sending state machine
		end//sending size case

		
		
		send_data: begin
			case(state)
				
				send_first_byte: begin //Send the 0 byte over to the SPI controller
					
					
					if(di_req == 1'b1) begin //If data is valid and SPI needs a byte
							spi_data_out_next <= next_pixel[7:0];
							wren_next <= 1'b1;
							state_next <= wren_ack;
							//Request the next byte from SRAM while we're doing this
							sram_start_next <= 1'b0;
					end
				end
				
				wren_ack: begin //wait for write to be acknowledged
					sram_start_next <= 1'b1;
					if(wr_ack == 1'b1) begin
						wren_next <= 1'b0;
						state_next <= send_second_byte;
					end
				
				end
				
				send_second_byte: begin //Send the 1 byte over to the SPI controller
					if(di_req == 1'b1) begin //If data is valid and SPI needs a byte
						spi_data_out_next <= next_pixel[15:8];
						wren_next <= 1'b1;
						state_next <= cleanup;
					end
				end
				
				
				
				cleanup: begin
					//If we've acked
					if(wr_ack == 1'b1 && sram_ready == 1'b1) begin
						//Store the next pixel
						next_pixel_next <= sram_data;
						//reset wren
						wren_next <= 1'b0;
						//If the image is over
						if(sram_addr == stop_addr + 1) begin
							sram_addr_next <= 16'b0;
							state_next <= get_word;
							global_state_next <= global_idle;
						end
						else begin
							//Increment the address
							sram_addr_next <= sram_addr + 1'b1;
							//Send the next byte
							state_next <= send_first_byte;
						end
					end
				end
				
				default begin
					global_state_next <= global_idle;
					state_next <= get_word;
				end
			
			endcase
		
		end//send data
		
		default: begin
			global_state_next <= global_idle;
			state_next <= get_word;
		end
		
	endcase//global state machine
end
				 
always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
		reset_regs();
	end
	else begin

		global_state <= global_state_next;
		state <= state_next;
		size_count <= size_count_next;
		sram_addr <= sram_addr_next;
		sram_start <= sram_start_next;
		spi_data_out <= spi_data_out_next;
		wren <= wren_next;
		next_pixel <= next_pixel_next;
	
	end//not reset


end//clock block

task reset_regs;
begin
	
	global_state <= global_idle;
	state <= get_word;
	size_count <= 2'b00;
	sram_addr <= 16'b0;
	sram_start <= 1'b1;
	spi_data_out <= 8'b0;
	wren <= 1'b0;
	next_pixel <= 16'b0;

end
endtask

assign sram_rw = 1'b1;//1 for a read

endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//SPI controller

//module spi_controller_old
//(
//	input wire clk,
//	input wire reset,
//	input wire reader_ready, //Ready signal from pixel reader_ready
//	input wire reader_done,//Indicates when FFD9 has been sent, needs to be checked after sending
//	input wire [15:0] stop_addr,//Last address from pixel writer
//	input wire [8:0] reader_data,
//	input wire reader_RE, //Data from reader is valid
//	
//	//SPI inputs
//	input wire di_req,
//	input wire wr_ack,
//	
//	//Outputs
//	output reg reader_reset, //Asynchronously reset the reader to start over the frame read
//	output reg [7:0] data_out,//To SPI controller
//	output reg wren//to spi controller
//	
//);
//
//reg [1:0] global_state;
//reg [1:0] state;
//reg [1:0] size_count;
//
////Global state machine defs
//localparam [1:0] global_idle = 2'b00,//wait for command
//				 send_size = 2'b01,//Send the lenght
//				 send_data = 2'b10;//Send the frame
//		    
//			
//localparam [1:0] get_byte = 2'b00, //Get the byte from the pixel reader and then wait for ready
//				 end_byte = 2'b01,//Wait for the pixel reader to be ready with the data and then givr it to the spi controller
//				 wren_ack = 2'b10, //Wait for the SPI controller to ack the write
//				 cleanup = 2'b11;//Increment counters
//				 
//always @ (posedge clk or negedge reset) begin
//	if(reset == 1'b0) begin
//	
//	end
//	else begin
//
//		case(global_state)
//		
//		
//			send_size: begin
//		
//				case(state)//Local state machine for sending length
//				
//					get_byte: begin
//						//Figuring out which byte of size needs to be sent
//						if(di_req == 1'b1)begin
//						
//							//if(size_count == 2'b00) begin
//							//	data_out <= 8'b0;
//							//end
//							if(size_count == 2'b00) begin
//								data_out <= stop_addr[15:8];
//							end
//							else if(size_count == 2'b01) begin
//								data_out <= stop_addr[7:0];
//							end
//							else begin
//								data_out <= 8'b0;
//							end
//						
//							state <= send_byte;
//							
//						
//						end
//					end
//					
//					send_byte: begin
//						//enable write
//						wren <= 1'b1;
//						//Wait for the acknowledgement
//						state <= wren_ack;
//						
//					end
//					
//					wren_ack: begin
//					
//						if(wr_ack == 1'b1) begin//SPI interface has begun transmission
//							wren <= 1'b0; //reset the start line
//							state <= cleanup;
//						end
//					
//					end
//					
//					cleanup: begin
//						
//						//Doon't actually need to wait for anything here, we only change external signals when di_req goes high
//						if(size_count == 2'b10) begin //If we're done transmitting the image size
//							size_count <= 2'b0;
//							global_state <= global_idle;
//							state <= get_byte;
//							data_out <= 8'b0;
//						end
//						else begin
//							size_count <= size_count + 1'b1;
//							state <= get_byte;
//						end
//					
//					end//cleanup case
//				endcase //local size sending state machine
//			end//sending size case
//
//			
//			
//			send_data: begin
//			
//				get_byte: begin //Request a byte from the reader
//					
//					//Tell the pixel reader we need data
//					RE <= 1'b1;
//					//Wait for ready to go high and then send
//					state <= wait_reader;
//				
//				end	//Wait for byte
//				
//				send_byte: begin //Send the byte over to the SPI controller
//					RE <= 1'b0;
//					if(reader_ready == 1'b1 && di_req == 1'b1) begin //If data is valid and SPI needs a byte
//							data_out <= reader_data;
//							wren <= 1'b1;
//							state <= wait_wren;
//					end
//				end
//				
//				wren_ack: begin //wait for write to be acknowledged
//					if(wr_ack == 1'b1) begin
//						wren <= 1'b0;
//						state <= data_cleanup;
//					end
//				
//				end
//				
//				cleanup: begin
//					//Don't actually need to do anything here
//					state <= get_byte;
//				end
//				
//				
//			
//			end//send data
//			
//			default: begin
//				reset_regs();
//			end
//			
//		endcase//global state machine
//	
//	end
//
//
//end
//
//task reset_regs;
//begin
// 
//	global_state <= global_idle;
//    state <= get_word;
//	size_count <= 2'b0;
//	sram_addr <= 16'b0;
//	spi_data_out <= 16'b0;
//end
//endtask
//
//endmodule