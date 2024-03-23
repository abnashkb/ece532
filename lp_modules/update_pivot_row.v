`timescale 1ns / 1ps

module update_pivot_row  
    #(
        parameter DATAW = 32 //bit width of one tableau element (using single precision)
    )
    (
    input clk,
	input resetn,
	
	//fsm inputs/outputs
	output reg terminate,
	output reg cont,
	
	//tableau size
	input [15:0] num_cols,
	
	//data from prev stage of lp
	input [DATAW-1:0] factor_in, //elem in pivot row and pivot col
	
	//axi data in signals
	input [DATAW-1:0] axi_pivotrowIN_data,
	input axi_pivotrowIN_valid,
	output axi_pivotrowIN_ready,
	
	//axi writing out signals with results
	output [DATAW-1:0] axi_pivotrowOUT_data, //this may continue changing after cont/term set, which is allowed bc valid will be low
	output axi_pivotrowOUT_valid,
	input axi_pivotrowOUT_ready,
	
	//native BRAM output signals
	output wen,
	output [DATAW-1:0] wdata,
	output reg [15:0] widx
	
    );
        
    //store incoming factor into register in case it changes after module has started -- should not happen though
    //reg [DATAW-1:0] factor;
        
    wire axi_pivotrowIN_ready_div0_a;
    wire axi_pivotrowIN_ready_div0_b;
    //check both ports because second port is fixed factor and so accepting data at both ports must align
    assign axi_pivotrowIN_ready = ~cont && ~terminate && resetn && axi_pivotrowIN_ready_div0_a && axi_pivotrowIN_ready_div0_b;
    
    wire [19:0] m_axis_result_tuser;
    wire m_axis_result_tvalid_div0;
    //reg cont_delayed; //update: no longer need this -- would need this if wanted last value to have extra cycle to handshake
    assign axi_pivotrowOUT_valid = m_axis_result_tvalid_div0 
                                   && ~m_axis_result_tuser[0] && ~m_axis_result_tuser[1] 
                                   && ~m_axis_result_tuser[2] && ~m_axis_result_tuser[3] //check no error bits set
                                   && resetn && ~terminate && ~cont; //&& ~cont_delayed;
    reg [15:0] input_counter; 
    always @ (posedge clk) begin
        if (~resetn) begin
            input_counter <= 16'b0;
        end
        else if (axi_pivotrowIN_valid && axi_pivotrowIN_ready) begin //we accepted new data
            input_counter <= input_counter + 1;
        end //else: implied latch   
    end
        
    floating_point_1 fp_div_inst0 (
      .aclk(clk),                                  // input wire aclk
      .aresetn(resetn),                            // input wire aresetn
      .s_axis_a_tvalid(axi_pivotrowIN_valid),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(axi_pivotrowIN_ready_div0_a),            // output wire s_axis_a_tready
      .s_axis_a_tdata(axi_pivotrowIN_data),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(input_counter),                   // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(axi_pivotrowIN_valid),            // input wire s_axis_b_tvalid //to align with port A
      .s_axis_b_tready(axi_pivotrowIN_ready_div0_b),            // output wire s_axis_b_tready
      .s_axis_b_tdata(factor_in),              // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid_div0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(axi_pivotrowOUT_ready),  // input wire m_axis_result_tready
      .m_axis_result_tdata(axi_pivotrowOUT_data),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser)    // output wire [19 : 0] m_axis_result_tuser
    );
        
    //logic to be done with this stage
	always @ (posedge clk) begin
		if (~resetn) begin
			cont <= 1'b0;
			terminate <= 1'b0;
			//factor <= factor_in;
		end
		else if (m_axis_result_tvalid_div0 && axi_pivotrowOUT_ready && ~terminate && ~cont) begin
		  //check for error
		  if (m_axis_result_tuser[0] || m_axis_result_tuser[1] || m_axis_result_tuser[2] || m_axis_result_tuser[3]) begin
		      terminate <= 1'b1;
		  end
		  //check for last value
		  else if (m_axis_result_tuser[19:4] == num_cols-1) begin 
		      cont <= 1'b1;
		  end
	   end //else: latch
	end
	
	//valid signal
	/*always @ (posedge clk) begin
	   if (~resetn) begin
	       cont_delayed <= 1'b0;
	   end
	   //check if cont is high
	   else begin
	       cont_delayed <= cont;
	   end
	end*/
	
	//BRAM write addressing
	always @ (posedge clk) begin
	   if (~resetn) begin
	       widx <= 0;
	   end
	   else if (axi_pivotrowOUT_valid) begin
	       widx <= widx + 1; //write next 4 bytes, just need to supply index
	   end
	end
	
	//BRAM output signals
	assign wen = axi_pivotrowOUT_valid;
	assign wdata = axi_pivotrowOUT_data;
	    
endmodule
