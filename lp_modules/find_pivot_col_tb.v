`timescale 1ns / 1ps

module find_pivot_col_tb ();
	parameter T = 10; //clk period
	parameter DATAW = 32;
	
	reg clk_tb;
	reg resetn_tb;
	
	
	//fsm inputs/outputs
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

    //clock
	always begin
		#(T/2) clk_tb = ~clk_tb; //so clock period is 20 time units
	end
		
	find_pivot_col DUT (.clk(clk_tb),
	.resetn(resetn_tb),
	
	//fsm inputs/outputs
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
	
//	function automatic void run_basic_test;
    initial begin        
        clk_tb = 1'b0;
        resetn_tb = 1'b0; //start low to reset at start of simulation to prevent x output from FFs (lack a default val)
        axi_objrow_data_tb = 32'b0;
        axi_objrow_valid_tb = 1'b0;
        num_cols_tb = 16'b0;
        if (pivot_col_tb != 16'b0)
            $error("ERROR: pivot_col_tb is not 0 during reset");
        #(T*2); //wait 2 clk cycles
        //bring reset back down
        resetn_tb = 1'b1;
        num_cols_tb = 16'h05;
        #(T*2); //wait 2 clk cycles
        @(posedge clk_tb); //wait for rising edge of clk
        //test 1 - provide positive value on fifo_data_tb
        axi_objrow_data_tb = 32'b01000000100000000000000000000000; //4
        #T;
        
        //test 2 - provide negative value on fifo_data_tb
        axi_objrow_valid_tb = 1'b1;// = 1'b0; //fifo is not empty
        axi_objrow_data_tb = 32'b11000001001000000000000000000000; //-10//-64'h00000000000000ff; //
        #T;
        
        //test 3 - provide negative 0
        axi_objrow_data_tb = 32'h80000000; 
        #T;
        
        
        //test 4 - provide - INF
        axi_objrow_data_tb = 32'hff800000;
        #T;
        
        axi_objrow_valid_tb = 1'b0; //fifo is empty	
        #(T*2);
        $finish;  
    end
	

//	function automatic void main;
//	   run_basic_test();
//	endfunction;
	
//	initial
//	   main();
//	begin
endmodule