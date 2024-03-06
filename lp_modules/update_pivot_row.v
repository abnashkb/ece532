`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2024 04:59:19 PM
// Design Name: 
// Module Name: update_pivot_row
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module update_pivot_row  
    #(parameter ELEMW = 32, //bit width of one tableau element (using single precision)
      parameter DATAW = ELEMW //ELEMW*2 //bit width of axi data 64 bits
        )
    (
    input clk,
	input areset,
	
	//fsm inputs/outputs
	input start,
	output terminate,
	output cont,
	
	//tableau size
	input [15:0] num_cols,
	
	//data from prev stage of lp
	input [ELEMW-1:0] factor, //elem in pivot row and pivot col
	
	//axi data in signals
	input [DATAW-1:0] axi_pivotrowIN_data,
	input axi_pivotrowIN_valid,
	output axi_pivotrowIN_ready,
	
	//axi writing out signals with results
	output [DATAW-1:0] axi_pivotrowOUT_data,
	output axi_pivotrowOUT_valid,
	input axi_pivotrowOUT_ready

    );
    
    //registers
    reg terminate_reg;
	reg cont_reg;
	assign terminate = terminate_reg;
	assign cont = cont_reg;
    
    //output valid only if both divider results are ready
    wire m_axis_result_tvalid_div0;
    //wire m_axis_result_tvalid_div1;
    assign axi_pivotrowOUT_valid = m_axis_result_tvalid_div0; //&& m_axis_result_tvalid_div1;
    
    //NVM NOT NEEDED BC SLAVE WILL ONLY READ WHEN VALID IS HIGH: prevent one divider from writing to axi interface until both are valid
    //wire axi_pivotrowOUT_ready_combined;
    //assign axi_pivotrowOUT_ready_combined = axi_pivotrowOUT_ready && m_axis_result_tvalid_div0 && m_axis_result_tvalid_div1;
    wire axi_pivotrowIN_ready_div0_a;
    wire axi_pivotrowIN_ready_div0_b;
    //wire axi_pivotrowIN_ready_div1_a;
    //wire axi_pivotrowIN_ready_div1_b;
    assign axi_pivotrowIN_ready = axi_pivotrowIN_ready_div0_a && axi_pivotrowIN_ready_div0_b; //&& axi_pivotrowIN_ready_div1_a && axi_pivotrowIN_ready_div1_b;
    
    //to keep division going, by using the s_axis_b_tvalid signal
    wire keep_dividing;
    assign keep_dividing = ~cont_reg; //bc cont_reg set to 1 means continue onto next stage after update_pivot_row
    
    reg [15:0] input_counter;
    
    always @ (posedge clk, posedge areset) begin
        if (areset) begin
            input_counter <= 16'b0;
        end
        else if (axi_pivotrowIN_valid && axi_pivotrowIN_ready && (num_cols > input_counter)) begin //we accepted new data
            input_counter <= input_counter + 1;
        end
        else begin
            input_counter <= input_counter;
        end    
    end
    
    reg [15:0] output_counter;
    
    always @ (posedge clk, posedge areset) begin
        if (areset) begin
            output_counter <= 16'b0;
        end
        else if (axi_pivotrowOUT_valid && axi_pivotrowOUT_ready && (num_cols > output_counter)) begin //we generated updated data
            output_counter <= output_counter + 1;
        end
        else begin
            output_counter <= output_counter;
        end    
    end
    
    floating_point_1 fp_div_inst0 (
      .aclk(clk),                                  // input wire aclk
      .aresetn(~areset),                            // input wire aresetn
      .s_axis_a_tvalid(axi_pivotrowIN_valid),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(axi_pivotrowIN_ready_div0_a),            // output wire s_axis_a_tready
      .s_axis_a_tdata(axi_pivotrowIN_data[ELEMW-1:0]),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(keep_dividing),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(axi_pivotrowIN_ready_div0_b),            // output wire s_axis_b_tready
      .s_axis_b_tdata(factor),              // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid_div0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(axi_pivotrowOUT_ready),  // input wire m_axis_result_tready
      .m_axis_result_tdata(axi_pivotrowOUT_data[ELEMW-1:0]),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser)    // output wire [3 : 0] m_axis_result_tuser
    );
    
    /*floating_point_1 fp_div_inst1 (
      .aclk(clk),                                  // input wire aclk
      .aresetn(~areset),                            // input wire aresetn
      .s_axis_a_tvalid(axi_pivotrowIN_valid),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(axi_pivotrowIN_ready_div1_a),            // output wire s_axis_a_tready
      .s_axis_a_tdata(axi_pivotrowIN_data[63:32]),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(keep_dividing),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(axi_pivotrowIN_ready_div1_b),            // output wire s_axis_b_tready
      .s_axis_b_tdata(factor),              // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid_div1),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(axi_pivotrowOUT_ready),  // input wire m_axis_result_tready
      .m_axis_result_tdata(axi_pivotrowOUT_data[63:32]),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser)    // output wire [3 : 0] m_axis_result_tuser
    );*/
    
    //logic to be done with this stage
	always @ (*) begin
		if (areset) begin
			cont_reg <= 1'b0;
			terminate_reg <= 1'b0;
		end
		else if ((num_cols <= input_counter) && (num_cols <= output_counter)) begin
			cont_reg <= 1'b1;
			terminate_reg <= 1'b0; //TODO: use error detection from dividers
		end	
	end
    
endmodule
