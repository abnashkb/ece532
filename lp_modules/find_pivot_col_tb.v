`timescale 1ns / 1ps

module find_pivot_col_tb ();
	parameter T = 20; //clk period
	
	reg clk_tb;
	reg areset_tb;
	reg [63:0] fifo_data_tb;
	reg fifo_full_tb;
	reg fifo_empty_tb;
	wire [15:0] pivot_col_tb; //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	wire [63:0] value_pivot_col_last_row_tb;
	wire found_pivot_col_tb;
	wire done_tb;

	find_pivot_col #(.FIFO_WIDTH(64)) inst0 //bit width of fifo, using double precision = 64 bits
		(.clk(clk_tb),
		.areset(areset_tb),
		.fifo_data(fifo_data_tb), //element at front of fifo
		.fifo_full(fifo_full_tb),
		.fifo_empty(fifo_empty_tb),
		.pivot_col(pivot_col_tb), //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
		.value_pivot_col_last_row(value_pivot_col_last_row_tb),
		.found_pivot_col(found_pivot_col_tb),
		.done(done_tb)
		);
	
	initial begin
		clk_tb = 1'b0;
		areset_tb = 1'b1; //start high to reset at start of simulation to prevent x output from FFs (lack a default val)
		fifo_data_tb = 64'h0000000000000000;
		fifo_full_tb = 1'b0;
		fifo_empty_tb = 1'b1;
		if (pivot_col_tb != 16'h0000)
			$error("ERROR: pivot_col_tb is not 0 during reset");
		#(T*2); //wait 2 clk cycles
		//bring reset back down
		areset_tb = 1'b0;
		#(T*2); //wait 2 clk cycles
        @(posedge clk_tb); //wait for rising edge of clk
		//test 1 - provide negative value on fifo_data_tb
		fifo_empty_tb = 1'b0; //fifo is not empty
		fifo_data_tb = -64'h00000000000000ff;
		#T;
		fifo_empty_tb = 1'b1; //fifo is empty	
		#(T*2);
	$finish;
	end
	
	//clock
	always begin
		#(T/2) clk_tb = ~clk_tb; //so clock period is 20 time units
	end
	
	
	
endmodule