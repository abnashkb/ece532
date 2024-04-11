`timescale 1ns / 1ps

module find_pivot_col
	# (
		parameter COL_INDEX_SIZE = 16,
		parameter DATAW = 32
	) 
	(
		input wire clk,
		input wire resetn, // This should connect to the FSM controller (as the start signal)
	
		//fsm outputs
		output reg terminate,
		output reg cont,
		
		//tableau size
		input [COL_INDEX_SIZE-1:0] num_cols,
		
		input [15:0] curr_iteration,
		
		//axi signals for objective row data
		input wire S_AXIS_TVALID,
        output wire S_AXIS_TREADY,
		input wire [DATAW-1:0] S_AXIS_TDATA,
        
		//lp algo outputs
		output reg [COL_INDEX_SIZE-1:0] pivot_col, //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
		output reg [DATAW-1:0] value_pivot_col_last_row // TODO we can remove this
	);

    // IO Assignment

	reg [COL_INDEX_SIZE-1:0] curr_col; //counter
	
	assign S_AXIS_TREADY = !terminate && !cont && resetn;
	
	always @ (posedge clk)
	begin
		if (!resetn) begin
			pivot_col <= 16'h0;
			curr_col <= 16'h0;
			value_pivot_col_last_row <= 32'h0; // Initialize as postive 0
			terminate <= 1'b0;
			cont <= 1'b0;
		end
		else if (terminate || cont) begin end // Do nothing if we're already done
		else if (curr_col == num_cols) begin
			if (value_pivot_col_last_row[31]) begin // If we have a negative number, we've found a pivot column
				cont <= 1'b1;
			end
			else begin
				terminate <= 1'b1;
			end
		end
		else begin
		    
			if (S_AXIS_TVALID && S_AXIS_TREADY) begin
				curr_col <= curr_col + 1;
				if (S_AXIS_TDATA[30:23] == 8'b11111111) begin // It's infinity or NaN
					terminate <= 1'b1; // An error occured!
				end
				// If value is smaller than our current value we update the pivot column
				// We are doing a floating point number comparison
				// Must be > not >= because we don't want to accept a -0 value.
				else if ((S_AXIS_TDATA[31] == 1'b1) && (S_AXIS_TDATA[30:0] > value_pivot_col_last_row[30:0])) begin
					value_pivot_col_last_row <= S_AXIS_TDATA;
					pivot_col <= curr_col;
				end
			end
			// If the data isn't valid and ready, values are latched and nothing happens
		end
	end
endmodule