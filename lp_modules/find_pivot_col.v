`timescale 1ns / 1ps

module find_pivot_col_new 
	# (parameter DATAW = 32) //bit width of fifo, using single precision = 64 bits
	(input clk,
	input areset,
	
	//fsm inputs/outputs
	input start,
	output terminate,
	output cont,
	
	//tableau size
	input [15:0] num_cols,
	
	//axi signals for objective row data
	input  [DATAW-1:0] axi_objrow_data,
	input axi_objrow_valid,
	output axi_objrow_ready,
	
	//lp algo outputs
	output [15:0] pivot_col, //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	output [DATAW-1:0] value_pivot_col_last_row
	);
	
	
	reg [15:0] pivot_col_reg;
	reg [15:0] curr_col_reg; //counter
	reg [DATAW-1:0] value_pivot_col_last_row_reg;
	reg found_pivot_col_reg;
	//reg done_reg;
	reg terminate_reg;
	reg cont_reg;
	reg axi_objrow_ready_reg;
	assign axi_objrow_ready = axi_objrow_ready_reg;
	
	assign pivot_col = pivot_col_reg;
	assign value_pivot_col_last_row = value_pivot_col_last_row_reg;
	assign terminate = terminate_reg;
	//assign done = done_reg;
	assign cont = cont_reg;
	
	always @ (posedge clk, posedge areset) begin
		if (areset) begin
			axi_objrow_ready_reg <= 1'b0;
		end
		else begin
			axi_objrow_ready_reg <= 1'b1; //can stay high, assuming one clk cycle for comparator logic below
		end
	end
	
	always @ (posedge clk or posedge areset)
	begin
		if (areset) begin
			pivot_col_reg <= 16'h0000;
			curr_col_reg <= 16'h0000;
			value_pivot_col_last_row_reg <= 32'h00000000; //most negative
			terminate_reg <= 1'b0;
			cont_reg <= 1'b0;
		end
		else begin
			if (start && (curr_col_reg < num_cols) && axi_objrow_valid && axi_objrow_ready) begin
				curr_col_reg <= curr_col_reg + 1;
				found_pivot_col_reg <= 1'b0;
				//done_reg <= 1'b0;
				cont_reg <= 1'b0;
				//if (axi_objrow_data < value_pivot_col_last_row_reg) begin
				if ((axi_objrow_data[31] == 1'b1) && (axi_objrow_data[30:0] > value_pivot_col_last_row_reg[30:0])) begin
					value_pivot_col_last_row_reg <= axi_objrow_data;
					pivot_col_reg <= curr_col_reg + 1;
				end
			end
			else if ((curr_col_reg == num_cols) && (value_pivot_col_last_row_reg < 0)) begin //streamed entire last row of tableau AND have negative number
				terminate_reg <= 1'b0; //no error
				cont_reg <= 1'b1; //continue onto next stage of LP algo, done with this module
			end
			else begin
				terminate_reg <= 1'b1; //did not find a valid pivot column out of entire last row
				cont_reg <= 1'b0;
			end
		end
	end
	
	

endmodule