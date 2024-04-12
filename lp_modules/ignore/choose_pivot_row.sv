`timescale 1ns / 1ps

//`include "axi_stream_type.sv"

module choose_pivot_row
    # (
        parameter DATAW = 32, //bit width of one tableau element (using single precision). matches only 32-bit wide axi data.
		parameter NUM_ROWS_W = 16
    )
    (
    input clk,
	input resetn, //WARNING: must be asserted for two clk cycles for floating point IP
	
	//tableau size
	input [NUM_ROWS_W-1:0] num_rows,
	
	//data
    axi_stream_port.in axi_rightcol,
	axi_stream_port.in axi_pivotcol,
	
	//result of module
	output reg [NUM_ROWS_W-1:0] pivot_row_index,
	output reg [DATAW-1:0] pivot_col_pivot_row_data,
	
	//outputs to fsm
	output reg terminate,
	output reg cont

    );
	
	reg [NUM_ROWS_W-1:0] counter_a;	//two sep counters to allow for misalignment in incoming data arrival
	reg [NUM_ROWS_W-1:0] counter_b;
	reg [DATAW-1:0] best_ratio;
	wire div_ratio_test_OUT_tvalid;
	wire div_ratio_test_OUT_tready;
	wire [DATAW-1:0] div_ratio_test_OUT_tdata;
	wire [67:0] div_ratio_test_OUT_tuser; //4 LSB for 4 error bits: underflow, overflow, invalid op, and divide by zero
	wire divaready, divbready;
	
	//no longer need to manually check data in pre-stage. easier to avoid dropping data to preserve counter.
	
	//counter if valid data. TODO: maybe throw to dsp via directive.
	always @ (posedge clk) begin
		if (~resetn) begin
			counter_a <= 0;
			counter_b <= 0;
		end
		else begin
			if (axi_rightcol.valid && axi_rightcol.ready) begin
				counter_a <= counter_a + 1;
			end
			if (axi_pivotcol.valid && axi_pivotcol.ready) begin
				counter_b <= counter_b + 1;
			end
		end
	end
	
	assign axi_rightcol.ready = ~cont && ~terminate && resetn && divaready;
	assign axi_pivotcol.ready = ~cont && ~terminate && resetn && divbready;
	
	//instantiate divider for rightcol / pivotcol
	floating_point_3 fp_div_ratio_test (
	  .aclk(clk),                                  // input wire aclk
	  .aresetn(resetn),                            // input wire aresetn
	  .s_axis_a_tvalid(axi_rightcol.valid),            // input wire s_axis_a_tvalid
	  .s_axis_a_tready(divaready),            // output wire s_axis_a_tready
	  .s_axis_a_tdata(axi_rightcol.data),              // input wire [31 : 0] s_axis_a_tdata
	  .s_axis_a_tuser(counter_a),              // input wire [15 : 0] s_axis_a_tuser
	  .s_axis_b_tvalid(axi_pivotcol.valid),            // input wire s_axis_b_tvalid
	  .s_axis_b_tready(divbready),            // output wire s_axis_b_tready
	  .s_axis_b_tdata(axi_pivotcol.data),              // input wire [31 : 0] s_axis_b_tdata
	  .s_axis_b_tuser({axi_pivotcol.data, counter_b}),              // input wire [47 : 0] s_axis_b_tuser
	  .m_axis_result_tvalid(div_ratio_test_OUT_tvalid),  // output wire m_axis_result_tvalid
	  .m_axis_result_tready(div_ratio_test_OUT_tready),  // input wire m_axis_result_tready
	  .m_axis_result_tdata(div_ratio_test_OUT_tdata),    // output wire [31 : 0] m_axis_result_tdata
	  .m_axis_result_tuser(div_ratio_test_OUT_tuser)    // output wire [67 : 0] m_axis_result_tuser
	);
	
	assign div_ratio_test_OUT_tready = 1'b1;
	reg ratio_updated;
	
	//check result against best one so far
	//also assign terminate and continue, checking the tuser error bits too for div
	//this cannot be pipelined because must compare against best so far, which could change while data would be in the pipeline
	always @ (posedge clk) begin
		if (~resetn) begin
			best_ratio <= 32'hffff_ffff; //using infinity for comp, or could use 32'h7f7fffff = max possible legit 32 bit signed fp value = 3.4028235e38
			pivot_row_index <= 0;
			terminate <= 1'b0;
			cont <= 1'b0;
			ratio_updated <= 1'b0;
			pivot_col_pivot_row_data <= 32'b0;
		end
		else if (div_ratio_test_OUT_tvalid && div_ratio_test_OUT_tready && ~cont && ~terminate) begin
			if (
				(div_ratio_test_OUT_tuser[0] || div_ratio_test_OUT_tuser[1] || div_ratio_test_OUT_tuser[2]) //division error occurred, except handle div by zero separately
				||
				((div_ratio_test_OUT_tuser[NUM_ROWS_W+4-1:4] == num_rows) && ~ratio_updated) //reached last value and best_ratio is unchanged
				) begin
				terminate <= 1'b1; //tell fsm to terminate the lp problem
				//cont <= 1'b0; //implied
			end
			else if (div_ratio_test_OUT_tuser[3]) begin
			     //divided by infinity so skip this row -- do not throw terminate
			     if (div_ratio_test_OUT_tuser[NUM_ROWS_W+4-1:4] == num_rows && ratio_updated) begin //if this was last row, do not update algo updates but proceed to next stage
					//terminate <= 1'b0; //implied
					cont <= 1'b1; //tell fsm to continue onto next lp module
				end
				else begin //div by zero in last row so skip, but no valid pivot row found earlier
				    terminate <= 1'b1; //tell fsm to terminate the lp problem
				end
			end
			else if ((~div_ratio_test_OUT_tdata[DATAW-1] || (div_ratio_test_OUT_tdata[DATAW-2:0] == 0)) && (div_ratio_test_OUT_tdata < best_ratio)) begin 
				//MSB should be 0 to show positive ratio, or rest must be all zero (bc could have -0 in IEEE754)
				best_ratio <= div_ratio_test_OUT_tdata;
				pivot_col_pivot_row_data <= div_ratio_test_OUT_tuser[67:36]; //upper 32 bits are pivotcol data
				ratio_updated <= 1'b1;
				pivot_row_index <= div_ratio_test_OUT_tuser[NUM_ROWS_W+4-1:4];
				if (div_ratio_test_OUT_tuser[NUM_ROWS_W+4-1:4] == num_rows) begin //if this was last row AND it had new best ratio
					//terminate <= 1'b0; //implied
					cont <= 1'b1; //tell fsm to continue onto next lp module
				end
			end
			else if ((div_ratio_test_OUT_tuser[NUM_ROWS_W+4-1:4] == num_rows) && ratio_updated) begin //this is last row, it didn't give new best ratio, but a prev row DID update ratio
				//terminate <= 1'b0; //implied
				cont <= 1'b1; //tell fsm to continue onto next lp module
			end
		end
	
	end
	
endmodule