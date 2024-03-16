`timescale 1ns / 1ps
`include "axi_stream_type.sv"

module choose_pivot_row
    # (
        //ignore: assuming endianness: lower 32 bits for ith element in row, upper 32 bits for (i+1)th elem
        parameter I_UPPER = 31,
        parameter I_LOWER = 0,
        /*parameter IPLUS1_UPPER = 63,
        parameter IPLUS1_LOWER = 32,*/
        //only 32-bit wide axi data
        parameter DATAW = 32 //bit width of axi data 32 bits
    )
    (
    input clk,
	input resetn,
	
	//tableau size
	input [15:0] num_rows,
	
	//data
    axi_stream_port.in axi_pivotcol,
    axi_stream_port.in axi_rightcol
    	
	//TODO: add more signals including start, cont, terminate, proper outputs of computation

    );
    
    //valid signals
    reg s_axis_a_tvalid_mult0;
    reg s_axis_b_tvalid_mult0;
    reg s_axis_a_tvalid_mult1;
    reg s_axis_b_tvalid_mult1;
    //indices/counters
    reg [15:0] curr_idx_a_mult0;
    reg [15:0] curr_idx_b_mult0;
    reg [15:0] curr_idx_a_mult1;
    reg [15:0] curr_idx_b_mult1;
    //stage 2 indices/counters
    reg [15:0] curr_idx_a_mult2;
    reg [15:0] curr_idx_b_mult2;
    reg [15:0] curr_idx_a_mult3;
    reg [15:0] curr_idx_b_mult3;
    //regs for axi-data
    reg [DATAW-1:0] rowi_pivotcol;
    reg [DATAW-1:0] rowi_rightcol;
    reg [DATAW-1:0] rowi_pivotcol_pre;
    reg [DATAW-1:0] rowi_rightcol_pre;
    //reg [DATAW-1:0] rowiplus1_pivotcol;
    //reg [DATAW-1:0] rowiplus1_rightcol;
    reg axi_pivotcol_valid_reg0;
    reg axi_rightcol_valid_reg0;
    

    wire s_axis_a_tready_mult0;
    wire s_axis_b_tready_mult0;
    wire s_axis_a_tready_mult1;
    wire s_axis_b_tready_mult1;
    //stage 2
    wire s_axis_a_tready_mult2;
    wire s_axis_b_tready_mult2;
    wire s_axis_a_tready_mult3;
    wire s_axis_b_tready_mult3;
       
    reg [DATAW-1:0] data_a_mult0;
    reg [DATAW-1:0] data_b_mult0;
    reg [DATAW-1:0] data_a_mult1;
    reg [DATAW-1:0] data_b_mult1;
    //stage 2
    reg [DATAW-1:0] data_a_mult2;
    reg [DATAW-1:0] data_b_mult2;
    reg [DATAW-1:0] data_a_mult3;
    reg [DATAW-1:0] data_b_mult3;
    
    /*reg [15:0] counter_pivotcol;
    reg [15:0] counter_pivotcol_prop;
    reg [15:0] counter_rightcol;
    reg [15:0] counter_rightcol_prop;
    reg [15:0] counter_pivotcol_prop2;
    reg [15:0] counter_rightcol_prop2;*/
    reg [15:0] counter;
    
    wire m_axis_result_tvalid_mult0;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult0;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult0;
    wire [32:0] m_axis_result_tuser_mult0; //+1 for LSB as invalid_op flag
    wire m_axis_result_tvalid_mult1;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult1;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult1;
    wire [32:0] m_axis_result_tuser_mult1;
    wire m_axis_result_tvalid_comp0;  // output wire m_axis_result_tvalid
    wire m_axis_result_tready_comp0;  // input wire m_axis_result_tready
    wire [7:0] m_axis_result_tdata_comp0;    // output wire [7 : 0] m_axis_result_tdata
    wire [32:0] m_axis_result_tuser_comp0;    // output wire [32 : 0] m_axis_result_tuser, NOT 31:0, extra LSB for invalid_op
    //stage 2
    wire m_axis_result_tvalid_mult2;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult2;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult2;
    wire [32:0] m_axis_result_tuser_mult2; //+1 for LSB as invalid_op flag
    wire m_axis_result_tvalid_mult3;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult3;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult3;
    wire [32:0] m_axis_result_tuser_mult3;
    wire m_axis_result_tvalid_comp1;  // output wire m_axis_result_tvalid
    wire m_axis_result_tready_comp1;  // input wire m_axis_result_tready
    wire [7:0] m_axis_result_tdata_comp1;    // output wire [7 : 0] m_axis_result_tdata
    wire [32:0] m_axis_result_tuser_comp1;    // output wire [32 : 0] m_axis_result_tuser, NOT 31:0, extra LSB for invalid_op
    //stage 2 logic
    reg stg2_first_iteration;
    reg final_comp_busy;
    
    reg demux_sel;
    
    // PRESTAGE: Loading data from axi_pivotcol and axi_rightcol into registers

    // Putting into axi_pivotcol reg

    assign axi_pivotcol.ready =  resetn && (
        ((demux_sel == 1'b0) && s_axis_a_tready_mult0 && s_axis_a_tready_mult1)
        ||
        ((demux_sel == 1'b1) && s_axis_b_tready_mult0 && s_axis_b_tready_mult1)
    );

    always @ (posedge clk) begin
        if (!resetn) begin
            rowi_pivotcol <= {DATAW{1'b0}};
            axi_pivotcol_valid_reg0 <= 1'b0;
        end
        else if (axi_pivotcol.valid && axi_pivotcol.ready) begin
            rowi_pivotcol <= axi_pivotcol.data[I_UPPER:I_LOWER];
            axi_pivotcol_valid_reg0 <= 1'b1;
        end
        else if (~axi_pivotcol.valid) begin
            rowi_pivotcol <= rowi_pivotcol;
            axi_pivotcol_valid_reg0 <= 1'b0; //axi_pivotcol_valid_reg0;
        end
        else begin
            rowi_pivotcol <= rowi_pivotcol;
            axi_pivotcol_valid_reg0 <= axi_pivotcol_valid_reg0;
        end
    end

    assign axi_rightcol.ready =  resetn && (
        ((demux_sel == 1'b0) && s_axis_a_tready_mult0 && s_axis_a_tready_mult1)
        ||
        ((demux_sel == 1'b1) && s_axis_b_tready_mult0 && s_axis_b_tready_mult1)
    );
    
    always @ (posedge clk) begin
        if (!resetn) begin
            rowi_rightcol <= {DATAW{1'b0}};
            axi_rightcol_valid_reg0 <= 1'b0;
        end
        else if (axi_rightcol.valid && axi_rightcol.ready) begin
            rowi_rightcol <= axi_rightcol.data[I_UPPER:I_LOWER];
            axi_rightcol_valid_reg0 <= 1'b1;
        end
        else if (~axi_rightcol.valid) begin
            rowi_rightcol <= rowi_rightcol;
            axi_rightcol_valid_reg0 <= 1'b0; //axi_rightcol_valid_reg0;
        end
        else begin
            rowi_rightcol <= rowi_rightcol;
            axi_rightcol_valid_reg0 <= axi_rightcol_valid_reg0;
        end
    end
        
    //checking data
    always @ (posedge clk) begin
        if (!resetn) begin
            demux_sel <= 1'b0;
            counter <= 16'b0;
            s_axis_a_tvalid_mult0 <= 1'b0;
            s_axis_b_tvalid_mult0 <= 1'b0;
            s_axis_a_tvalid_mult1 <= 1'b0;
            s_axis_b_tvalid_mult1 <= 1'b0;
            data_a_mult0 <= 32'b0;
            data_b_mult0 <= 32'b0;
            data_a_mult1 <= 32'b0;
            data_b_mult1 <= 32'b0;;
            //counter_pivotcol_prop2 <= 16'b0;
            //counter_rightcol_prop2 <= 16'b0;
        end
        else if (axi_rightcol_valid_reg0 && axi_pivotcol_valid_reg0 
                //&& s_axis_a_tready_mult0 && s_axis_a_tready_mult1
                //&& s_axis_b_tready_mult0 && s_axis_b_tready_mult1
                )
             begin
            if ( ~(rowi_pivotcol == 0) && ~(rowi_pivotcol[31] ^ rowi_rightcol[31]) ) begin
                if ((demux_sel == 1'b0) && s_axis_a_tready_mult0 && s_axis_a_tready_mult1) begin
                    //store into port a
                    s_axis_a_tvalid_mult0 <= 1'b1;
                    s_axis_b_tvalid_mult0 <= 1'b0;
                    s_axis_a_tvalid_mult1 <= 1'b1;
                    s_axis_b_tvalid_mult1 <= 1'b0;
                    data_a_mult0 <= rowi_pivotcol;
                    data_a_mult1 <= rowi_rightcol;    
                    demux_sel <= 1'b1;
                    curr_idx_a_mult0 <= counter;
                    curr_idx_a_mult1 <= counter;
                    counter <= counter + 1;         
                end
                else if ((demux_sel == 1'b1) && s_axis_b_tready_mult0 && s_axis_b_tready_mult1 )begin
                    //store into port b
                    s_axis_a_tvalid_mult0 <= 1'b0;
                    s_axis_b_tvalid_mult0 <= 1'b1;
                    s_axis_a_tvalid_mult1 <= 1'b0;
                    s_axis_b_tvalid_mult1 <= 1'b1;
                    data_b_mult0 <= rowi_pivotcol;
                    data_b_mult1 <= rowi_rightcol;    
                    demux_sel <= 1'b0;
                    curr_idx_b_mult0 <= counter;
                    curr_idx_b_mult1 <= counter;
                    counter <= counter + 1;         
                end
                else begin
                    //implied latch of all values except...
                    s_axis_a_tvalid_mult0 <= 1'b0;
                    s_axis_b_tvalid_mult0 <= 1'b0;
                    s_axis_a_tvalid_mult1 <= 1'b0;
                    s_axis_b_tvalid_mult1 <= 1'b0;
                end
            end
            else begin //skip row
                counter <= counter + 1;
                s_axis_a_tvalid_mult0 <= 1'b0;
                s_axis_b_tvalid_mult0 <= 1'b0;
                s_axis_a_tvalid_mult1 <= 1'b0;
                s_axis_b_tvalid_mult1 <= 1'b0;
             end  
        end
        else begin //not ready to write
           //latch all values except...bc no valid data
            s_axis_a_tvalid_mult0 <= 1'b0;
            s_axis_b_tvalid_mult0 <= 1'b0;
            s_axis_a_tvalid_mult1 <= 1'b0;
            s_axis_b_tvalid_mult1 <= 1'b0;
        end 
    end
     
    //stage 1: instantiate multipliers
    floating_point_0 fp_mult_inst0 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(s_axis_a_tvalid_mult0),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult0),            // output wire s_axis_a_tready
      .s_axis_a_tdata(data_a_mult0),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(curr_idx_a_mult0),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(s_axis_b_tvalid_mult0),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult0),            // output wire s_axis_b_tready
      .s_axis_b_tdata(data_b_mult0),              // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(curr_idx_b_mult0),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult0),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult0),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult0)    // output wire [32 : 0] m_axis_result_tuser
    );
    floating_point_0 fp_mult_inst1 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(s_axis_a_tvalid_mult1),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult1),            // output wire s_axis_a_tready
      .s_axis_a_tdata(data_a_mult1),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(curr_idx_a_mult1),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(s_axis_b_tvalid_mult1),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult1),            // output wire s_axis_b_tready
      .s_axis_b_tdata(data_b_mult1),             // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(curr_idx_b_mult1),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult1),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult1),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult1),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult1)    // output wire [32 : 0] m_axis_result_tuser
    );
    
    //3-cycle delay for mult inputs to reach same cycle as comparator 0 output
    reg [DATAW-1:0] delay0_pivotcol_rowi;
    reg [DATAW-1:0] delay1_pivotcol_rowi;
    reg [DATAW-1:0] delay2_pivotcol_rowi;
    reg [DATAW-1:0] delay0_pivotcol_rowiplus1;
    reg [DATAW-1:0] delay1_pivotcol_rowiplus1;
    reg [DATAW-1:0] delay2_pivotcol_rowiplus1;
    reg [DATAW-1:0] delay0_rightcol_rowi;
    reg [DATAW-1:0] delay1_rightcol_rowi;
    reg [DATAW-1:0] delay2_rightcol_rowi;
    reg [DATAW-1:0] delay0_rightcol_rowiplus1;
    reg [DATAW-1:0] delay1_rightcol_rowiplus1;
    reg [DATAW-1:0] delay2_rightcol_rowiplus1;
    
    always @ (posedge clk) begin
        if (!resetn) begin
            delay0_pivotcol_rowi <= {DATAW{1'b0}};
            delay1_pivotcol_rowi <= {DATAW{1'b0}};
            delay2_pivotcol_rowi <= {DATAW{1'b0}};
            delay0_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            delay1_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            delay2_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            delay0_rightcol_rowi <= {DATAW{1'b0}};
            delay1_rightcol_rowi <= {DATAW{1'b0}};
            delay2_rightcol_rowi <= {DATAW{1'b0}};
            delay0_rightcol_rowiplus1 <= {DATAW{1'b0}};
            delay1_rightcol_rowiplus1 <= {DATAW{1'b0}};
            delay2_rightcol_rowiplus1 <= {DATAW{1'b0}};
        end
        else begin
            delay0_pivotcol_rowi <= data_a_mult0; //rowi_pivotcol;
            delay1_pivotcol_rowi <= delay0_pivotcol_rowi;
            delay2_pivotcol_rowi <= delay1_pivotcol_rowi;
            delay0_pivotcol_rowiplus1 <= data_b_mult0;
            delay1_pivotcol_rowiplus1 <= delay0_pivotcol_rowiplus1;
            delay2_pivotcol_rowiplus1 <= delay1_pivotcol_rowiplus1;
            delay0_rightcol_rowi <= data_a_mult1; //rowi_rightcol;
            delay1_rightcol_rowi <= delay0_rightcol_rowi;
            delay2_rightcol_rowi <= delay1_rightcol_rowi;
            delay0_rightcol_rowiplus1 <= data_b_mult1;
            delay1_rightcol_rowiplus1 <= delay0_rightcol_rowiplus1;
            delay2_rightcol_rowiplus1 <= delay1_rightcol_rowiplus1;
        end
    end
    
    //added these assignment temp for testing without comp_inst0 module:
    //assign m_axis_result_tready_mult0 = 1'b1;
    //assign m_axis_result_tready_mult1 = 1'b1;
    
    reg comp_in_valid_a;
    reg comp_in_valid_b;
    
    always @ (posedge clk) begin
        if (!resetn) begin
            comp_in_valid_a <= 1'b0;
            comp_in_valid_b <= 1'b0;
        end
        else begin
            comp_in_valid_a <= m_axis_result_tvalid_mult0;
            comp_in_valid_b <= m_axis_result_tvalid_mult1;
        end
    end
    
    //comparator (greater than or equal to) to select between two candidate pivot rows after cross-multiplication
        floating_point_2 comp_inst0 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(m_axis_result_tvalid_mult0), //comp_in_valid_a),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(m_axis_result_tready_mult0),            // output wire s_axis_a_tready
      .s_axis_a_tdata(m_axis_result_tdata_mult0), //32'h41200000), // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(m_axis_result_tuser_mult0[16:1]),              // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(m_axis_result_tvalid_mult0), //comp_in_valid_b),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(m_axis_result_tready_mult1),            // output wire s_axis_b_tready
      .s_axis_b_tdata(m_axis_result_tdata_mult1), //32'h40000000),  // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(m_axis_result_tuser_mult0[32:17]),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_comp0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_comp0),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_comp0),    // output wire [7 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_comp0)    // output wire [32 : 0] m_axis_result_tuser
    );
    
    //need entire stage 2 ready (final comp1 and multipliers) before can proceed
    assign m_axis_result_tready_comp0 = ~final_comp_busy && s_axis_a_tready_mult2 && s_axis_b_tready_mult2 && s_axis_a_tready_mult3 && s_axis_b_tready_mult3; //1'b1; //temp to see comp output
    
    wire [15:0] tuser_pivotrow_comp0;
    //if LSB of m_axis_result_tdata_comp0 is 1, that means mult0 result tdata >= mult1 result tdata, so i+1 is possible pivot row
    assign tuser_pivotrow_comp0 = m_axis_result_tdata_comp0[0] ? m_axis_result_tuser_comp0[32:17] : m_axis_result_tuser_comp0[16:1];
    
    //stage 2: 3-cycle delay for mult inputs to reach same cycle as comparator 1 output
    reg [DATAW-1:0] stg2_delay0_pivotcol_rowi;
    reg [DATAW-1:0] stg2_delay1_pivotcol_rowi;
    reg [DATAW-1:0] stg2_delay2_pivotcol_rowi;
    reg [DATAW-1:0] stg2_delay0_pivotcol_rowiplus1;
    reg [DATAW-1:0] stg2_delay1_pivotcol_rowiplus1;
    reg [DATAW-1:0] stg2_delay2_pivotcol_rowiplus1;
    reg [DATAW-1:0] stg2_delay0_rightcol_rowi;
    reg [DATAW-1:0] stg2_delay1_rightcol_rowi;
    reg [DATAW-1:0] stg2_delay2_rightcol_rowi;
    reg [DATAW-1:0] stg2_delay0_rightcol_rowiplus1;
    reg [DATAW-1:0] stg2_delay1_rightcol_rowiplus1;
    reg [DATAW-1:0] stg2_delay2_rightcol_rowiplus1;
    
    always @ (posedge clk) begin
        if (!resetn) begin
            stg2_delay0_pivotcol_rowi <= {DATAW{1'b0}};
            stg2_delay1_pivotcol_rowi <= {DATAW{1'b0}};
            stg2_delay2_pivotcol_rowi <= {DATAW{1'b0}};
            stg2_delay0_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            stg2_delay1_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            stg2_delay2_pivotcol_rowiplus1 <= {DATAW{1'b0}};
            stg2_delay0_rightcol_rowi <= {DATAW{1'b0}};
            stg2_delay1_rightcol_rowi <= {DATAW{1'b0}};
            stg2_delay2_rightcol_rowi <= {DATAW{1'b0}};
            stg2_delay0_rightcol_rowiplus1 <= {DATAW{1'b0}};
            stg2_delay1_rightcol_rowiplus1 <= {DATAW{1'b0}};
            stg2_delay2_rightcol_rowiplus1 <= {DATAW{1'b0}};
        end
        else begin
            stg2_delay0_pivotcol_rowi <= data_a_mult2; //rowi_pivotcol;
            stg2_delay1_pivotcol_rowi <= delay0_pivotcol_rowi;
            stg2_delay2_pivotcol_rowi <= delay1_pivotcol_rowi;
            stg2_delay0_pivotcol_rowiplus1 <= data_b_mult2;
            stg2_delay1_pivotcol_rowiplus1 <= delay0_pivotcol_rowiplus1;
            stg2_delay2_pivotcol_rowiplus1 <= delay1_pivotcol_rowiplus1;
            stg2_delay0_rightcol_rowi <= data_a_mult3; //rowi_rightcol;
            stg2_delay1_rightcol_rowi <= delay0_rightcol_rowi;
            stg2_delay2_rightcol_rowi <= delay1_rightcol_rowi;
            stg2_delay0_rightcol_rowiplus1 <= data_b_mult3;
            stg2_delay1_rightcol_rowiplus1 <= delay0_rightcol_rowiplus1;
            stg2_delay2_rightcol_rowiplus1 <= delay1_rightcol_rowiplus1;
        end
    end
    
    //use comparator output to select second stage multipliers inputs, combinational logic is fine for input data since handshaking
    //assign data_a_mult2 = m_axis_result_tdata_comp0[0] ? delay2_pivotcol_rowiplus1 : delay2_pivotcol_rowi;
    //assign data_a_mult3 = m_axis_result_tdata_comp0[0] ? delay2_rightcol_rowiplus1 : delay2_rightcol_rowi;
    always @ (*) begin //use always block to support easy reset and other logic
        if (!resetn) begin
            data_a_mult2 = {DATAW{1'b0}};
            data_b_mult2 = {DATAW{1'b0}};
            data_a_mult3 = {DATAW{1'b0}};
            data_b_mult3 = {DATAW{1'b0}};
            curr_idx_a_mult2 = 16'b0;
            curr_idx_b_mult2 = 16'b0;
            curr_idx_a_mult3 = 16'b0;
            curr_idx_b_mult3 = 16'b0;
        end
        else begin
            data_a_mult2 = m_axis_result_tdata_comp0[0] ? delay2_pivotcol_rowiplus1 : delay2_pivotcol_rowi;
            data_a_mult3 = m_axis_result_tdata_comp0[0] ? delay2_rightcol_rowiplus1 : delay2_rightcol_rowi;
            curr_idx_a_mult2 = tuser_pivotrow_comp0;
            curr_idx_a_mult3 = tuser_pivotrow_comp0;
            //loopback or if first iteration, duplidate data_a ports
            if (stg2_first_iteration) begin
                data_b_mult2 = data_a_mult2;
                data_b_mult3 = data_a_mult3;
                curr_idx_b_mult2 = curr_idx_a_mult2;
                curr_idx_b_mult3 = curr_idx_a_mult3;
            end
            else begin
                data_b_mult2 = m_axis_result_tdata_comp1[0] ? stg2_delay2_pivotcol_rowiplus1 : stg2_delay2_pivotcol_rowi; 
                data_b_mult3 = m_axis_result_tdata_comp1[0] ? stg2_delay2_rightcol_rowiplus1 : stg2_delay2_rightcol_rowi;
                curr_idx_b_mult2 = tuser_pivotrow_comp1;
                curr_idx_b_mult3 = tuser_pivotrow_comp1;
            end
        end
    
    end

     //stage 2: instantiate multipliers
    floating_point_0 fp_mult_inst2 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(m_axis_result_tvalid_comp0 && m_axis_result_tready_comp0),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult2),            // output wire s_axis_a_tready
      .s_axis_a_tdata(data_a_mult2),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(curr_idx_a_mult2),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(m_axis_result_tvalid_comp0 && m_axis_result_tready_comp0),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult2),            // output wire s_axis_b_tready
      .s_axis_b_tdata(data_b_mult2),              // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(curr_idx_b_mult2),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult2),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult2),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult2),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult2)    // output wire [32 : 0] m_axis_result_tuser
    );
    floating_point_0 fp_mult_inst3 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(m_axis_result_tvalid_comp0 && m_axis_result_tready_comp0),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult3),            // output wire s_axis_a_tready
      .s_axis_a_tdata(data_a_mult3),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(curr_idx_a_mult3),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(m_axis_result_tvalid_comp0 && m_axis_result_tready_comp0),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult3),            // output wire s_axis_b_tready
      .s_axis_b_tdata(data_b_mult3),             // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(curr_idx_b_mult3),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult3),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult3),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult3),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult3)    // output wire [32 : 0] m_axis_result_tuser
    );
    
    
    
    //stage 2 comparator (greater than or equal to) to select between two candidate pivot rows after cross-multiplication
        floating_point_2 comp_inst1 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(m_axis_result_tvalid_mult2), //comp_in_valid_a),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(m_axis_result_tready_mult2),            // output wire s_axis_a_tready
      .s_axis_a_tdata(m_axis_result_tdata_mult2), //32'h41200000), // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(m_axis_result_tuser_mult2[16:1]),              // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(m_axis_result_tvalid_mult3), //comp_in_valid_b),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(m_axis_result_tready_mult3),            // output wire s_axis_b_tready
      .s_axis_b_tdata(m_axis_result_tdata_mult3), //32'h40000000),  // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(m_axis_result_tuser_mult3[32:17]),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_comp1),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_comp1),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_comp1),    // output wire [7 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_comp1)    // output wire [32 : 0] m_axis_result_tuser
    );
    
    assign m_axis_result_tready_comp1 = 1'b1; //bc always ready for final comp output
      
    always @ (posedge clk) begin
        if (!resetn) begin
            stg2_first_iteration <= 1'b1;
        end
        else if (stg2_first_iteration && m_axis_result_tvalid_comp1 && m_axis_result_tready_comp1) begin
            stg2_first_iteration <= 1'b0;
        end
        else begin
            stg2_first_iteration <= stg2_first_iteration;
        end
    end
    
    always @ (posedge clk) begin
        if (!resetn) begin
            final_comp_busy <= 1'b0;
        end
        else if (~final_comp_busy && m_axis_result_tvalid_comp0 && m_axis_result_tready_comp0) begin //starting stage 2 by pulling from comp0
            final_comp_busy <= 1'b1;
        end
        else if (final_comp_busy && m_axis_result_tvalid_comp1 && m_axis_result_tready_comp1) begin //done stage 2
            final_comp_busy <= 1'b0; 
        end
        else begin
            final_comp_busy <= final_comp_busy;
        end
    end
    
    //view comp1 selected row index
    wire [15:0] tuser_pivotrow_comp1;
    //if LSB of m_axis_result_tdata_comp0 is 1, that means mult0 result tdata >= mult1 result tdata, so i+1 is possible pivot row
    assign tuser_pivotrow_comp1 = m_axis_result_tdata_comp1[0] ? m_axis_result_tuser_comp1[32:17] : m_axis_result_tuser_comp1[16:1];
        
    
endmodule
