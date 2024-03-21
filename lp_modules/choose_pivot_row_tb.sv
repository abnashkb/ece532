`timescale 1ns / 1ps

module choose_pivot_row_tb ();
	parameter T = 10; //clk period
	parameter DATAW = 32;
	parameter NUM_ROWS_W = 16;
	
	reg clk_tb;
	reg resetn_tb; //WARNING: must be asserted for two clk cycles for floating point IP
	reg [NUM_ROWS_W-1:0] num_rows_tb;
    axi_stream_port axi_rightcol_tb();
	axi_stream_port axi_pivotcol_tb();
	wire [NUM_ROWS_W-1:0] pivot_row_index_tb;
	wire terminate_tb;
	wire cont_tb;
	
	choose_pivot_row choose_pivot_row_DUT
    (
    .clk(clk_tb),
	.resetn(resetn_tb), //WARNING: must be asserted for two clk cycles for floating point IP
	.num_rows(num_rows_tb),
	.axi_rightcol(axi_rightcol_tb),
	.axi_pivotcol(axi_pivotcol_tb),
	.pivot_row_index(pivot_row_index_tb),
	.terminate(terminate_tb),
	.cont(cont_tb)
    );
	
	 //clock
	always begin
		clk_tb = 1'b1;
		#(T/2) clk_tb = 1'b0;
		#(T/2);
	end
	
	initial begin
		//reset at start
        resetn_tb = 1'b0; //start low to reset at start of simulation to prevent x output from FFs (lack a default val)
		num_rows_tb = 16'b0;
		axi_rightcol_tb.data = 32'b0;
		axi_rightcol_tb.valid = 1'b0;
		axi_pivotcol_tb.data = 32'b0;
		axi_pivotcol_tb.valid = 1'b0;
		#(T*3); //must be low for 2 cycles for fp ip
		
		//bring reset back up
		resetn_tb = 1'b1;
		num_rows_tb = 16'h3;
		#(T*1.5);
		
		
		//NOTE: all expected values on internal signals in waveform will appear 29 cycles after once thru divider
		//test case 1: 500/10 -- should end up best, and index of best at 0
		axi_rightcol_tb.data = 32'h43fa0000;
		axi_pivotcol_tb.data = 32'h41200000;
		//#(T);
		axi_rightcol_tb.valid = 1'b1;
		axi_pivotcol_tb.valid = 1'b1;
		#(T); //must be 1.5 for tb to work
		//axi_rightcol_tb.valid = 1'b0;
		//axi_pivotcol_tb.valid = 1'b0;
		//wait (axi_rightcol_tb.ready && axi_pivotcol_tb.ready && clk_tb);
		//#(T*35);
		
		//test case 2: -10/-2 -- should end up best, and index of best at 1
		axi_rightcol_tb.data = 32'hc1200000;
		axi_rightcol_tb.valid = 1'b1;
		axi_pivotcol_tb.data = 32'hc0000000;
		axi_pivotcol_tb.valid = 1'b1;
		//wait (axi_rightcol_tb.ready && axi_pivotcol_tb.ready && clk_tb);
		//axi_rightcol_tb.valid = 1'b0;
		//axi_pivotcol_tb.valid = 1'b0;
		wait (axi_rightcol_tb.ready && axi_pivotcol_tb.ready && clk_tb);
		#(T); //to reach at least next rising clk edge
		
		
		//test case 3: 12/1 -- should stay as test case 2 values for best
		axi_rightcol_tb.data = 32'h41400000;
		axi_rightcol_tb.valid = 1'b1;
		axi_pivotcol_tb.data = 32'h3f800000;
		axi_pivotcol_tb.valid = 1'b1;
		wait (axi_rightcol_tb.ready && axi_pivotcol_tb.ready && clk_tb);
		#T;
		
		//test case 4: 5/2 -- stagger inputs
		axi_rightcol_tb.data = 32'h40a00000;
		axi_rightcol_tb.valid = 1'b1;
		axi_pivotcol_tb.data = 32'h40000000;
		axi_pivotcol_tb.valid = 1'b0;
		wait (axi_rightcol_tb.ready && clk_tb);
		#(T*2);
		axi_rightcol_tb.data = 32'h40a00000;
		axi_rightcol_tb.valid = 1'b0;
		axi_pivotcol_tb.data = 32'h40000000;
		axi_pivotcol_tb.valid = 1'b1;
		wait (axi_pivotcol_tb.ready && clk_tb);
		#T;
		
		//test case 5: 5/0 -- will never get accepted because my num_rows_tb is at 3
		//wait (axi_rightcol_tb.ready && axi_pivotcol_tb.ready && clk_tb);
		axi_rightcol_tb.data = 32'h40a00000;
		axi_rightcol_tb.valid = 1'b1;
		axi_pivotcol_tb.data = 32'h00000000;
		axi_pivotcol_tb.valid = 1'b0;
		#T;
		//wait (axi_rightcol_tb.ready && clk_tb);
		//#T;
		axi_rightcol_tb.data = 32'h40a00000;
		axi_rightcol_tb.valid = 1'b0;
		axi_pivotcol_tb.data = 32'h0000000;
		axi_pivotcol_tb.valid = 1'b1;
		#T;
		//wait (axi_pivotcol_tb.ready && clk_tb);
		//#T;
		
		wait (terminate_tb || cont_tb);
		#(T*10);
	
	$finish;
	end
	
	
endmodule