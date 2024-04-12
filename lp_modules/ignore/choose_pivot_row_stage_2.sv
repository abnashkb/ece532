`timescale 1ns / 1ps
`include "axi_stream_type.sv"

module choose_pivot_row_stage_2
    # (
        parameter DATAW = 32  //bit width of axi data 32 bits
    )
    (
        input clk,
        input resetn,
        
        //tableau size
        input [15:0] num_rows,
        
        //data
        axi_stream_port.in axi_pivotcol,
        axi_stream_port.in axi_rightcol,
        input [15:0] pivot_row_index,
            
        //TODO: add more signals including start, cont, terminate, proper outputs of computation
        output reg terminate,
        output reg cont,
        output reg [15:0] best_row_index
    );
    reg [DATAW-1:0] best_pivot_value;
    reg [DATAW-1:0] best_rhs_value;

    reg ready;
    reg prev_iter_done;

    assign axi_pivotcol.ready = ready;
    assign axi_rightcol.ready = ready;

    wire valid_and_ready = resetn && axi_pivotcol.valid && axi_rightcol.valid && !terminate && !cont && ready;

    always @(posedge clk) begin
        if (!resetn) begin
            ready <= 0;
        end
        else if (terminate || cont) begin end // Do nothing if we're already done
        else if (valid_and_ready) begin
            ready <= 0;
            prev_iter_done <= 0;
        end
        else if (prev_iter_done
                && s_axis_a_tready_mult0 
                && s_axis_a_tready_mult1 
                && s_axis_b_tready_mult0 
                && s_axis_b_tready_mult1
        ) begin
            ready <= 1;
        end
    end

    // We drop the sign bit because we don't want to multiply by a negative number 
    //  as otherwise we'd need to also flip the inequality sign
    //  Note: the order of rhs vs pivot is important to the indexing in the second half.
    wire [DATAW-1:0] mul_a0_data = axi_rightcol.data;
    wire [DATAW-1:0] mul_b0_data = best_pivot_value.data;
    wire [DATAW-1:0] mul_a1_data = axi_pivotcol.data;
    wire [DATAW-1:0] mul_b1_data = best_rhs_value.data;
    wire [DATAW+15:0] tuser_a0 = {mul_a0_data, pivot_row_index};
    wire [DATAW+15:0] tuser_b0 = {mul_b0_data, best_row_index};
    wire [DATAW+15:0] tuser_a1 = {mul_a1_data, pivot_row_index};
    wire [DATAW+15:0] tuser_b1 = {mul_b1_data, best_row_index};

    //valid signals
    wire s_axis_a_tready_mult0;
    wire s_axis_b_tready_mult0;
    wire s_axis_a_tready_mult1;
    wire s_axis_b_tready_mult1;

    wire m_axis_result_tvalid_mult0;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult0;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult0;
    wire [2*(DATAW+16):0] m_axis_result_tuser_mult0; //+1 for LSB as invalid_op flag
    wire m_axis_result_tvalid_mult1;   // output wire m_axis_result_tvalid
    wire m_axis_result_tready_mult1;  // input wire m_axis_result_tready
    wire [DATAW-1:0] m_axis_result_tdata_mult1;
    wire [2*(DATAW+16):0] m_axis_result_tuser_mult1;
    wire [7:0] m_axis_result_tdata_comp0;    // output wire [7 : 0] m_axis_result_tdata
    wire [32:0] m_axis_result_tuser_comp0;    // output wire [32 : 0] m_axis_result_tuser, NOT 31:0, extra LSB for invalid_op

    //stage 1: instantiate multipliers
    floating_point_0 fp_mult_inst0 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(valid_and_ready),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult0),            // output wire s_axis_a_tready
      .s_axis_a_tdata(mul_a0_data),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(tuser_a0),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(valid_and_ready),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult0),            // output wire s_axis_b_tready
      .s_axis_b_tdata(mul_b0_data),              // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(tuser_b0),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult0),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult0),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult0),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult0)    // output wire [32 : 0] m_axis_result_tuser
    );
    floating_point_0 fp_mult_inst1 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(valid_and_ready),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult1),            // output wire s_axis_a_tready
      .s_axis_a_tdata(mul_a1_data),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(tuser_a1),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(valid_and_ready),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(s_axis_b_tready_mult1),            // output wire s_axis_b_tready
      .s_axis_b_tdata(mul_b1_data),             // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(tuser_b1),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(m_axis_result_tvalid_mult1),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(m_axis_result_tready_mult1),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_mult1),    // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_mult1)    // output wire [32 : 0] m_axis_result_tuser
    );
    //comparator (greater than or equal to) to select between two candidate pivot rows after cross-multiplication
    floating_point_2 comp_inst0 (
      .aclk(clk),                                  // input wire aclk
      .resetnn(resetn),                            // input wire resetnn
      .s_axis_a_tvalid(m_axis_result_tvalid_mult0),             // input wire s_axis_a_tvalid
      .s_axis_a_tready(m_axis_result_tready_mult0),            // output wire s_axis_a_tready
      .s_axis_a_tdata(m_axis_result_tdata_mult0), // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(m_axis_result_tuser_mult0[2*(DATAW+16):1]),              // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(m_axis_result_tvalid_mult1),            // input wire s_axis_b_tvalid
      .s_axis_b_tready(m_axis_result_tready_mult1),            // output wire s_axis_b_tready
      .s_axis_b_tdata(m_axis_result_tdata_mult1),  // input wire [31 : 0] s_axis_b_tdata
      .s_axis_b_tuser(m_axis_result_tuser_mult1[2*(DATAW+16):1]),              // input wire [15 : 0] s_axis_b_tuser
      .m_axis_result_tvalid(valid_stage_1_out),  // output wire m_axis_result_tvalid
      .m_axis_result_tready(!prev_iter_done),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_comp0),    // output wire [7 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_comp0)    // output wire [32 : 0] m_axis_result_tuser
    );

    // To make sense of this use paper and pencil. Sorry. m_axis_result_tdata_comp0[0] is 1 when the LHS (a) >= RHS (b).
    wire pivot_i = m_axis_result_tuser[96:65];
    wire rhs_i = m_axis_result_tuser[192:161];
    wire pivot_i_plus_1 = m_axis_result_tuser[144:113];
    wire rhs_i_plus_1 = m_axis_result_tuser[48:17];

    always @(posedge clk) begin
        if (!resetn) begin
            prev_iter_done <= 0;
            best_rhs_value <= 0;
            best_pivot_value <= 0;
        end
        else if (valid_stage_1_out && !prev_iter_done) begin
            prev_iter_done <= 1;

            best_pivot_value <= m_axis_result_tdata_comp0[0] ? pivot_j : pivot_i;
            best_rhs_value <= m_axis_result_tdata_comp0[0] ? rhs_j : rhs_i;
            best_row_index <= m_axis_result_tdata_comp0[0] ? m_axis_result_tuser_comp0[16:1] : m_axis_result_tuser_comp0[64:49];
        end
    end
endmodule
