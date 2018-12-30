//Clock dividers
//Copyright (C) <2018>  <James Williams>

////This program is free software: you can redistribute it and/or modify
////it under the terms of the GNU General Public License as published by
////Free Software Foundation, either version 3 of the License, or
////(at your option) any later version.

////This program is distributed in the hope that it will be useful,
////but WITHOUT ANY WARRANTY; without even the implied warranty of
////MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
////GNU General Public License for more details.

 ///You should have received a copy of the GNU General Public License
////along with this program.  If not, see <https://www.gnu.org/licenses/>.


module divide_2(
input clk_in,
input reset,
output reg clk_out
);


always @ (posedge clk_in) begin
	if(reset == 1'b0) begin
		clk_out <= 1'b0;
	end
	else begin
		clk_out <= ~clk_out;
	end
end


endmodule

module divide_4(
input clk_in,
input reset,
output reg clk_out
);

reg count;

always @ (posedge clk_in) begin
	if(reset == 1'b0) begin
		clk_out <= 1'b0;
		count <= 1'b0;
	end
	else begin
		if(!count) begin
			count = 1'b1;
		end
		else begin
		clk_out <= ~clk_out;
			count <= 1'b0;
		end
	end
end


endmodule



