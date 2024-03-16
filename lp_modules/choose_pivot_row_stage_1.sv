`timescale 1ns / 1ps
`include "axi_stream_type.sv"

module choose_pivot_row_stage_1
    # (
        parameter DATAW = 32 //bit width of axi data 32 bits
    )
    (
        input clk,
        input resetn,
        axi_stream_port.in axi_pivotcol,
        axi_stream_port.in axi_rightcol,
        output reg terminate,
        output [15:0] pivot_row_index,
        output [DATAW-1:0] pivot_value,
        output [DATAW-1:0] rhs_value,
        output valid_stage_1_out,
        input ready_stage_1_out
    );
     
    reg [15:0] curr_row_index;
    reg demux_sel;
    
    wire ready_data = resetn && !terminate && (
        (!demux_sel && s_axis_a_tready_mult0 && s_axis_a_tready_mult1)
        ||
        (demux_sel && s_axis_b_tready_mult0 && s_axis_b_tready_mult1)
    );
    assign axi_pivotcol.ready = ready_data; 
    assign axi_rightcol.ready = ready_data;

    // Data is only passed on to the multipliers if the AXI input is valid AND
    //      both values are negative or both positive AND
    //      the pivot column value is not 0
    wire valid_data = resetn && axi_pivotcol.valid && axi_rightcol.valid && !terminate;
    // Error if floating point is NaN or +/- infinity
    wire valid_error_data = valid_data && (
        axi_pivotcol.data[30:23] == 8'b11111111 || axi_rightcol.data[30:23] == 8'b11111111
    );
    wire valid_good_data = valid_data && !valid_error_data && (
         ~(axi_pivotcol.data == 0) && ~(axi_pivotcol.data[31] ^ axi_rightcol.data[31])
    );
    assign s_axis_a_tvalid_stage1 = valid_good_data && !demux_sel;
    assign s_axis_b_tvalid_stage1 = valid_good_data && demux_sel;

    always @(posedge clk) begin
        if (!resetn) begin
            curr_row_index <= 0;
            demux_sel <= 0;
            terminate <= 0;
        end
        else if (valid_data && ready_data) begin
            if (valid_good_data) begin
                demux_sel <= ~demux_sel;
            end
            else if (valid_error_data) begin
                terminate <= 1;
            end
            curr_row_index <= curr_row_index + 1;
        end
    end

    // We drop the sign bit because we don't want to multiply by a negative number 
    //  as otherwise we'd need to also flip the inequality sign
    //  Note: the order of rhs vs pivot is important to the indexing in the second half.
    wire [DATAW-1:0] mul_a0_data = {1'b0, axi_rightcol.data[DATAW-2:0]};
    wire [DATAW-1:0] mul_b0_data = {1'b0, axi_pivotcol.data[DATAW-2:0]};
    wire [DATAW-1:0] mul_a1_data = {1'b0, axi_pivotcol.data[DATAW-2:0]};
    wire [DATAW-1:0] mul_b1_data = {1'b0, axi_rightcol.data[DATAW-2:0]};
    wire [DATAW+15:0] tuser_a0 = {mul_a0_data, curr_row_index};
    wire [DATAW+15:0] tuser_b0 = {mul_b0_data, curr_row_index};
    wire [DATAW+15:0] tuser_a1 = {mul_a1_data, curr_row_index};
    wire [DATAW+15:0] tuser_b1 = {mul_b1_data, curr_row_index};

    //valid signals
    wire s_axis_a_tvalid_stage1;
    wire s_axis_b_tvalid_stage1;
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
      .s_axis_a_tvalid(s_axis_a_tvalid_stage1),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult0),            // output wire s_axis_a_tready
      .s_axis_a_tdata(mul_a0_data),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(tuser_a0),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(s_axis_b_tvalid_stage1),            // input wire s_axis_b_tvalid
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
      .s_axis_a_tvalid(s_axis_a_tvalid_stage1),            // input wire s_axis_a_tvalid
      .s_axis_a_tready(s_axis_a_tready_mult1),            // output wire s_axis_a_tready
      .s_axis_a_tdata(mul_a1_data),              // input wire [31 : 0] s_axis_a_tdata
      .s_axis_a_tuser(tuser_a1),                      // input wire [15 : 0] s_axis_a_tuser
      .s_axis_b_tvalid(s_axis_b_tvalid_stage1),            // input wire s_axis_b_tvalid
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
      .m_axis_result_tready(ready_stage_1_out),  // input wire m_axis_result_tready
      .m_axis_result_tdata(m_axis_result_tdata_comp0),    // output wire [7 : 0] m_axis_result_tdata
      .m_axis_result_tuser(m_axis_result_tuser_comp0)    // output wire [32 : 0] m_axis_result_tuser
    );

    // To make sense of this use paper and pencil. Sorry. m_axis_result_tdata_comp0[0] is 1 when the LHS (a) >= RHS (b).
    wire [15:0] pivot_row_index = m_axis_result_tdata_comp0[0] ? m_axis_result_tuser_comp0[16:1] : m_axis_result_tuser_comp0[64:49];
    wire pivot_i = m_axis_result_tuser[96:65];
    wire rhs_i = m_axis_result_tuser[192:161];
    wire pivot_i_plus_1 = m_axis_result_tuser[144:113];
    wire rhs_i_plus_1 = m_axis_result_tuser[48:17];
    
    assign pivot = m_axis_result_tdata_comp0[0] ? pivot_j : pivot_i;
    assign rhs = m_axis_result_tdata_comp0[0] ? rhs_j : rhs_i;
endmodule