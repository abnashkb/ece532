`timescale 1ns / 1ps

module update_pivot_row_tb ();
    parameter T = 10; //clk period is 10 ns for 100 MHz clock
    parameter DATAW = 32;
   
    reg clk_tb;
	reg resetn_tb;
	//fsm inputs/outputs
	wire terminate_tb;
	wire cont_tb;
	//tableau size
	reg [15:0] num_cols_tb;
	//data from prev stage of lp
	reg [DATAW-1:0] factor_in_tb; //elem in pivot row and pivot col
	//axi data in signals
	reg [DATAW-1:0] axi_pivotrowIN_data_tb;
	reg axi_pivotrowIN_valid_tb;
	wire axi_pivotrowIN_ready_tb;
	//axi writing out signals with results
	wire [DATAW-1:0] axi_pivotrowOUT_data_tb;
	wire axi_pivotrowOUT_valid_tb;
	reg axi_pivotrowOUT_ready_tb;
	
	
	//instantiate module    
    update_pivot_row inst0
    (
        .clk(clk_tb),
	    .resetn(resetn_tb),	
	//fsm inputs/outputs
	   .terminate(terminate_tb),
       .cont(cont_tb),
	//tableau size
	.num_cols(num_cols_tb),
	//data from prev stage of lp
	.factor_in(factor_in_tb), //elem in pivot row and pivot col
	//axi data in signals
	.axi_pivotrowIN_data(axi_pivotrowIN_data_tb),
	.axi_pivotrowIN_valid(axi_pivotrowIN_valid_tb),
	.axi_pivotrowIN_ready(axi_pivotrowIN_ready_tb),
	//axi writing out signals with results
	.axi_pivotrowOUT_data(axi_pivotrowOUT_data_tb),
	.axi_pivotrowOUT_valid(axi_pivotrowOUT_valid_tb),
	.axi_pivotrowOUT_ready(axi_pivotrowOUT_ready_tb)

    );
            
    //clock
	always begin
		//#(T/2) aclk_tb = ~aclk_tb;
		clk_tb = 1'b1;
		#(T/2) clk_tb = 1'b0;
		#(T/2);
	end
	
	//testing
	initial begin
	   //reset
        resetn_tb = 1'b0; //reset at start of simulation to prevent x output from FFs (lack a default val)
        num_cols_tb = 16'b0; //16'b0100;
        factor_in_tb = 32'b0; //32'b01000000001000000000000000000000;
        axi_pivotrowIN_data_tb = 32'b0;
        axi_pivotrowIN_valid_tb = 1'b0;
        axi_pivotrowOUT_ready_tb = 1'b0;
        #(T*2); //MUST RESET FOR 2 CYCLES
        
        //done reset
        resetn_tb = 1'b1;
        num_cols_tb = 16'h4;
        factor_in_tb = 32'b01000000000000000000000000000000; //2
        axi_pivotrowOUT_ready_tb = 1'b1;
        #(T*1.5); //extra 0.5 cycle for next test case data to arrive before rising edge
        
        //test case 0: 4 DIV 2 = 2
        axi_pivotrowIN_data_tb = 32'b01000000100000000000000000000000; //4
        axi_pivotrowIN_valid_tb = 1'b1;
        #(T);
        
        //test case 1: 5.5 DIV 2
        axi_pivotrowIN_data_tb = 32'b01000000101100000000000000000000;
        axi_pivotrowIN_valid_tb = 1'b1;
        #(T);
        
        //test case 2: 0.5 DIV 2 
        axi_pivotrowIN_data_tb = 32'b00111111000000000000000000000000;
        axi_pivotrowIN_valid_tb = 1'b1;
        #(T);
        
        //test case 3: -0.5 DIV 2
        axi_pivotrowIN_data_tb = 32'b10111111000000000000000000000000;
        axi_pivotrowIN_valid_tb = 1'b1;
        #(T);
        
        //test case 4: -0.5 DIV 0 -- should raise terminate and have output valid set low
        axi_pivotrowIN_data_tb = 32'b10111111000000000000000000000000;
        factor_in_tb = 32'b0;
        axi_pivotrowIN_valid_tb = 1'b1;
        #(T);
        axi_pivotrowIN_valid_tb = 1'b0;
        
        #(T*50);
	
	$finish;
	end

endmodule
