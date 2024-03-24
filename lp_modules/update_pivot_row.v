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
	input [DATAW-1:0] S_AXIS_PIVOTROW_TDATA,
	input S_AXIS_PIVOTROW_TVALID,
	output S_AXIS_PIVOTROW_TREADY,
	
	//axi writing out signals with results -- no longer using this
	/*output [DATAW-1:0] M_AXIS_PIVOTROW_TDATA, //this may continue changing after cont/term set, which is allowed bc valid will be low
	output M_AXIS_PIVOTROW_TVALID,
	input M_AXIS_PIVOTROW_TREADY,*/
	
	//native BRAM output signals
	output wen,
	output [DATAW-1:0] wdata, //directly assigned to divider output
	output reg [15:0] waddr
	
    );
    
    //keeping to assign to BRAM output signals
	wire M_AXIS_PIVOTROW_TVALID;
	wire M_AXIS_PIVOTROW_TREADY = 1'b1; //set to always ready because using bram 
        
    wire S_AXIS_PIVOTROW_TREADY_div0_a;
    wire S_AXIS_PIVOTROW_TREADY_div0_b;
    //check both ports because second port is fixed factor and so accepting data at both ports must align
    assign S_AXIS_PIVOTROW_TREADY = ~cont && ~terminate && resetn && S_AXIS_PIVOTROW_TREADY_div0_a && S_AXIS_PIVOTROW_TREADY_div0_b;
    
    wire [19:0] m_axis_result_tuser;
    wire m_axis_result_tvalid_div0;
    //reg cont_delayed; //update: no longer need this -- would need this if wanted last value to have extra cycle to handshake
    assign M_AXIS_PIVOTROW_TVALID = m_axis_result_tvalid_div0 
                                   && ~m_axis_result_tuser[0] && ~m_axis_result_tuser[1] 
                                   && ~m_axis_result_tuser[2] && ~m_axis_result_tuser[3] //check no error bits set
                                   && resetn && ~terminate && ~cont; //&& ~cont_delayed;
                                   
                                   
    //BRAM output signals
	assign wen = M_AXIS_PIVOTROW_TVALID;
	
	//data input counter
    reg [15:0] input_counter; 
    always @ (posedge clk) begin
        if (~resetn) begin
            input_counter <= 16'b0;
        end
        else if (S_AXIS_PIVOTROW_TVALID && S_AXIS_PIVOTROW_TREADY) begin //we accepted new data
            input_counter <= input_counter + 1;
        end //else: implied latch   
    end
    
    //instantiate divider    
    floating_point_1 fp_div_inst0 (
      .aclk(clk),                                  // input wire aclk
      .aresetn(resetn),                            // input wire aresetn
      .s_axis_a_tvalid(S_AXIS_PIVOTROW_TVALID),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(S_AXIS_PIVOTROW_TREADY_div0_a),            // output wire s_axis_a_tready
      .s_axis_a_tdata(S_AXIS_PIVOTROW_TDATA),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(input_counter),                   // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(S_AXIS_PIVOTROW_TVALID),            // input wire s_axis_b_tvalid //to align with port A
      .s_axis_b_tready(S_AXIS_PIVOTROW_TREADY_div0_b),            // output wire s_axis_b_tready
      .s_axis_b_tdata(factor_in),              // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid_div0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(M_AXIS_PIVOTROW_TREADY),  // input wire m_axis_result_tready
      .m_axis_result_tdata(wdata),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser)    // output wire [19 : 0] m_axis_result_tuser
    );
        
    //logic to be done with this stage
	always @ (posedge clk) begin
		if (~resetn) begin
			cont <= 1'b0;
			terminate <= 1'b0;
			//factor <= factor_in;
		end
		else if (m_axis_result_tvalid_div0 && M_AXIS_PIVOTROW_TREADY && ~terminate && ~cont) begin
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
	
	//BRAM write addressing
	always @ (posedge clk) begin
	   if (~resetn) begin
	       waddr <= 0;
	   end
	   else if (M_AXIS_PIVOTROW_TVALID) begin
	       waddr <= waddr + 4; //write next 4 bytes
	   end
	end
		    
endmodule