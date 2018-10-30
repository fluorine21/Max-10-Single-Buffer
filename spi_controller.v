//SPI controller

module spi_controller
(
	input wire clk,
	input wire reset,
	input wire reader_ready, //Ready signal from pixel reader_ready
	input wire reader_done,//Indicates when FFD9 has been sent, needs to be checked after sending
	input wire [15:0] stop_addr,//Last address from pixel writer
	input wire [8:0] reader_data,
	input wire reader_RE, //Data from reader is valid
	
	//SPI inputs
	input wire di_req,
	input wire wr_ack,
	
	//Outputs
	output reg reader_reset, //Asynchronously reset the reader to start over the frame read
	output reg [7:0] data_out,//To SPI controller
	output reg wren//to spi controller
	
);

reg [1:0] global_state;
reg [1:0] state;
reg [1:0] size_count;

localparam [1:0] global_idle = 2'b00,//wait for command
				 send_size = 2'b01,//Send the lenght
				 send_data = 2'b10;//Send the frame
		    
localparam [1:0] get_byte = 2'b00, //Get the byte from the pixel reader and then wait for ready
				 end_byte = 2'b01,//Wait for the pixel reader to be ready with the data and then givr it to the spi controller
				 wren_ack = 2'b10, //Wait for the SPI controller to ack the write
				 cleanup = 2'b11;//Increment counters
				 
always @ (posedge clk or negedge reset) begin
	if(reset == 1'b0) begin
	
	end
	else begin

		case(global_state)
		
		
			send_size: begin
		
				case(state)//Local state machine for sending length
				
					get_byte: begin
						//Figuring out which byte of size needs to be sent
						if(di_req == 1'b1)begin
						
							//if(size_count == 2'b00) begin
							//	data_out <= 8'b0;
							//end
							if(size_count == 2'b00) begin
								data_out <= stop_addr[15:8];
							end
							else if(size_count == 2'b01) begin
								data_out <= stop_addr[7:0];
							end
							else begin
								data_out <= 8'b0;
							end
						
							state <= send_byte;
							
						
						end
					end
					
					send_byte: begin
						//enable write
						wren <= 1'b1;
						//Wait for the acknowledgement
						state <= wren_ack;
						
					end
					
					wren_ack: begin
					
						if(wr_ack == 1'b1) begin//SPI interface has begun transmission
							wren <= 1'b0; //reset the start line
							state <= cleanup;
						end
					
					end
					
					cleanup: begin
						
						//Doon't actually need to wait for anything here, we only change external signals when di_req goes high
						if(size_count == 2'b10) begin //If we're done transmitting the image size
							size_count <= 2'b0;
							global_state <= global_idle;
							state <= get_byte;
							data_out <= 8'b0;
						end
						else begin
							size_count <= size_count + 1'b1;
							state <= get_byte;
						end
					
					end//cleanup case
				endcase //local size sending state machine
			end//sending size case

			
			
			send_data: begin
			
				get_byte: begin //Request a byte from the reader
					
					//Tell the pixel reader we need data
					RE <= 1'b1;
					//Wait for ready to go high and then send
					state <= wait_reader;
				
				end	//Wait for byte
				
				send_byte: begin //Send the byte over to the SPI controller
					RE <= 1'b0;
					if(reader_ready == 1'b1 && di_req == 1'b1) begin //If data is valid and SPI needs a byte
							data_out <= reader_data;
							wren <= 1'b1;
							state <= wait_wren;
					end
				end
				
				wren_ack: begin //wait for write to be acknowledged
					if(wr_ack == 1'b1) begin
						wren <= 1'b0;
						state <= data_cleanup;
					end
				
				end
				
				cleanup: begin
					//Don't actually need to do anything here
					state <= get_byte;
				end
				
				
			
			end//send data
			
			default: begin
				reset_regs();
			end
			
		endcase//global state machine
	
	end


end

task reset_regs;
begin


end
endtask

endmodule