`timescale 1ns / 1ps

module choose_pivot_row_tb #(parameter ELEMW = 32, //bit width of one tableau element (using single precision)
      parameter DATAW = ELEMW)
      (    );

    reg clk_tb;
	reg areset_tb;
	//fsm inputs/outputs
	reg start_tb;
	wire terminate_tb;
	wire cont_tb;
	//tableau size
	reg [15:0] num_rows_tb;
	
	//data
	reg [DATAW-1:0] axi_pivotcol_data_tb;
	reg axi_pivotcol_valid_tb;
	wire axi_pivotcol_ready_tb;
	
	reg [DATAW-1:0] axi_rightcol_data_tb;
	reg axi_rightcol_valid_tb;
	wire axi_rightcol_ready_tb;
	
	
	parameter T = 10; //clk period is 10 ns for 100 MHz clock
    integer num_cycles;
    
    choose_pivot_row choose_pivot_row_inst_tb
    (
    .clk(clk_tb),
	.areset(areset_tb),
	
	//tableau size
	.num_rows(num_rows_tb),
	
	//data
	.axi_pivotcol_data(axi_pivotcol_data_tb),
	.axi_pivotcol_valid(axi_pivotcol_valid_tb),
	.axi_pivotcol_ready(axi_pivotcol_ready_tb),
	
	.axi_rightcol_data(axi_rightcol_data_tb),
	.axi_rightcol_valid(axi_rightcol_valid_tb),
	.axi_rightcol_ready(axi_rightcol_ready_tb) //TODO: add more signals including start, cont, terminate, proper outputs of computation

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
        //aclk_tb = 1'b0;
        areset_tb = 1'b1; //reset at start of simulation to prevent x output from FFs (lack a default val)
        start_tb = 1'b0;
        num_rows_tb = 16'b0; //16'b0100;
		axi_pivotcol_data_tb = 32'b0;
		axi_pivotcol_valid_tb = 1'b0;
		axi_rightcol_data_tb = 32'b0;
		axi_rightcol_valid_tb = 1'b0;
        #(T*3);
		
		//done reset
		areset_tb = 1'b0;
		#(T*2);
		
		//test case 1: send 2 and 2, then 4 and 4. Expect mult0 = 8 and mult1 = 8 and comp LSB b00.
		#(T*1.5);
		axi_pivotcol_data_tb = 32'b01000000000000000000000000000000;
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'b01000000000000000000000000000000;
		axi_rightcol_valid_tb = 1'b1;
		#(T); //#(T*2);
		axi_pivotcol_data_tb = 32'b01000000100000000000000000000000;
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'b01000000100000000000000000000000;
		axi_rightcol_valid_tb = 1'b1;
		#(T); //#(T*2);
		
		//test case 2: send 1 and 3, then 1 and 1. Expect mult0 = 1 and mult1 = 3 and comp LSB b01.
		axi_pivotcol_data_tb = 32'b00111111100000000000000000000000; //dec 1
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'b01000000010000000000000000000000; //dec 3
		axi_rightcol_valid_tb = 1'b1;
		#(T*2); //#(T*2);
		axi_pivotcol_data_tb = 32'b00111111100000000000000000000000; //dec 1
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'b00111111100000000000000000000000; //dec 1
		axi_rightcol_valid_tb = 1'b1;
		#(T); //#(T*2);
				
		//test case 3: invalid input of -1 = 0xbf800000 with the same as above otherwise
		axi_pivotcol_data_tb = 32'hbf800000; //dec -1 -- should reject row 4
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'b01000000010000000000000000000000; //dec 3
		axi_rightcol_valid_tb = 1'b1;
		#(T*2); //#(T*2);
		axi_pivotcol_data_tb = 32'hbf800000; //dec -1 -- should accept row 5 bc both negative
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'hbf800000; //dec -1
		axi_rightcol_valid_tb = 1'b1;
		#(T*2); //#(T*2);
		axi_pivotcol_data_tb = 32'hc0000000; //dec -2 -- should accept row 5 bc both negative
		axi_pivotcol_valid_tb = 1'b1;
		axi_rightcol_data_tb = 32'hc0000000; //dec -2
		axi_rightcol_valid_tb = 1'b1;
		#(T*2); //#(T*2);
		axi_pivotcol_valid_tb = 1'b0;
		axi_rightcol_valid_tb = 1'b0;
		
		#(T*20);
		
		
	$finish;
	end
	
endmodule
