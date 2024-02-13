`timescale 1ns / 1ps

module find_pivot_col 
	# (parameter FIFO_WIDTH = 64) //bit width of fifo, using double precision = 64 bits
	(input clk,
	input areset,
	input signed [63:0] fifo_data, //element at front of fifo
	input fifo_full,
	input fifo_empty,
	output [15:0] pivot_col, //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	output [63:0] value_pivot_col_last_row,
	output found_pivot_col,
	output done
	);
	
	reg [13:0] pivot_col_reg;
	reg [13:0] curr_col_reg; //counter
	reg signed [63:0] value_pivot_col_last_row_reg;
	reg found_pivot_col_reg;
	reg done_reg;
	
	assign pivot_col = pivot_col_reg;
	assign value_pivot_col_last_row = value_pivot_col_last_row_reg;
	assign found_pivot_col = found_pivot_col_reg;
	assign done = done_reg;
	
	always @ (posedge clk or posedge areset)
	begin
		if (areset) begin
			pivot_col_reg <= 16'h0000;
			curr_col_reg <= 16'h0000;
			value_pivot_col_last_row_reg <= 64'h0000000000000000; //most negative
			found_pivot_col_reg <= 1'b0;
			done_reg <= 1'b0;
		end
		else begin
			if (~fifo_empty) begin
				curr_col_reg <= curr_col_reg + 1;
				found_pivot_col_reg <= 1'b0;
				done_reg <= 1'b0;
				if (fifo_data < value_pivot_col_last_row_reg) begin
					value_pivot_col_last_row_reg <= fifo_data;
					pivot_col_reg <= curr_col_reg + 1;
				end
			end
			else if (fifo_empty && (value_pivot_col_last_row_reg < 0)) begin //streamed entire last row of tableau AND have negative number
				found_pivot_col_reg <= 1'b1;
				done_reg <= 1'b1;
			end
			else begin
				found_pivot_col_reg <= 1'b0; //did not find a valid pivot column out of entire last row
				done_reg <= 1'b1;
			end
		end
	
	end
	
	

endmodule