`timescale 1ns / 1ps

module find_pivot_col_new_tb ();
	parameter T = 10; //clk period
	parameter DATAW = 32;
	
	reg clk_tb;
	reg areset_tb;
	
	
	//fsm inputs/outputs
	reg start_tb;
	wire terminate_tb;
	wire cont_tb;
	
	//tableau size
	reg [15:0] num_cols_tb;
	
	//axi signals for objective row data
	reg [DATAW-1:0] axi_objrow_data_tb;
	reg axi_objrow_valid_tb;
	wire axi_objrow_ready_tb;
	
	//lp algo outputs
	wire [15:0] pivot_col_tb; //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	wire [DATAW-1:0] value_pivot_col_last_row_tb;
	
	
	/*reg [DATAW-1:0] fifo_data_tb;
	reg fifo_full_tb;
	reg fifo_empty_tb;
	wire [15:0] pivot_col_tb; //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	wire [DATAW-1:0] value_pivot_col_last_row_tb;
	wire found_pivot_col_tb;
	wire done_tb;*/

	/*find_pivot_col #(.FIFO_WIDTH(64)) inst0 //bit width of fifo, using double precision = 64 bits
		(.clk(clk_tb),
		.areset(areset_tb),
		.fifo_data(fifo_data_tb), //element at front of fifo
		.fifo_full(fifo_full_tb),
		.fifo_empty(fifo_empty_tb),
		.pivot_col(pivot_col_tb), //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
		.value_pivot_col_last_row(value_pivot_col_last_row_tb),
		.found_pivot_col(found_pivot_col_tb),
		.done(done_tb)
		);*/
		
	find_pivot_col_new inst0 (.clk(clk_tb),
	.areset(areset_tb),
	
	//fsm inputs/outputs
	.start(start_tb),
	.terminate(terminate_tb),
	.cont(cont_tb),
	
	//tableau size
	.num_cols(num_cols_tb),
	
	//axi signals for objective row data
	.axi_objrow_data(axi_objrow_data_tb),
	.axi_objrow_valid(axi_objrow_valid_tb),
	.axi_objrow_ready(axi_objrow_ready_tb),
	
	//lp algo outputs
	.pivot_col(pivot_col_tb), //what width to use? depends on # of columns we have though. assume max 16384 = 2^14 so 14 bits --> round up to 16
	.value_pivot_col_last_row(value_pivot_col_last_row_tb)
	);
	
	initial begin
		clk_tb = 1'b0;
		areset_tb = 1'b1; //start high to reset at start of simulation to prevent x output from FFs (lack a default val)
		axi_objrow_data_tb = 32'b0;
        axi_objrow_valid_tb = 1'b0;
        num_cols_tb = 16'b0;
        start_tb = 1'b0;
		if (pivot_col_tb != 16'b0)
			$error("ERROR: pivot_col_tb is not 0 during reset");
		#(T*2); //wait 2 clk cycles
		//bring reset back down
		areset_tb = 1'b0;
		num_cols_tb = 16'h02;
		start_tb = 1'b1;
		#(T*2); //wait 2 clk cycles
        @(posedge clk_tb); //wait for rising edge of clk
		//test 1 - provide negative value on fifo_data_tb
		axi_objrow_valid_tb = 1'b1;// = 1'b0; //fifo is not empty
		axi_objrow_data_tb = 32'b11000001001000000000000000000000; //-10//-64'h00000000000000ff; //
		#T;
		//test 2 - provide positive value on fifo_data_tb
		axi_objrow_data_tb = 32'b01000000100000000000000000000000; //4
		#T;
		axi_objrow_valid_tb = 1'b0; //fifo is empty	
		#(T*2);
	$finish;
	end
	
	//clock
	always begin
		#(T/2) clk_tb = ~clk_tb; //so clock period is 20 time units
	end
		
endmodule