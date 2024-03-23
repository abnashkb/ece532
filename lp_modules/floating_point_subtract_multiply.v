//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Wed Mar  6 12:57:12 2024
//Host        : StaaBuG15 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps


// Block does C - ( A * B ) and passes through a tuser signal from block which includes flags for
// underflow, overflow, and invalid_op
module floating_point_subtract_multiply
   (output [31:0] m_axis_result_tdata,
    input m_axis_result_tready,
    output [15:0] m_axis_result_tuser,
    output [2:0] m_axis_result_tflags,
    output m_axis_result_tvalid,
    input [31:0] s_axis_a_tdata,
    output s_axis_a_tready,
    input [15:0] s_axis_a_tuser,
    input s_axis_a_tvalid,
    input [31:0] s_axis_b_tdata,
    output s_axis_b_tready,
    input s_axis_b_tvalid,
    input [31:0] s_axis_c_tdata,
    output s_axis_c_tready,
    input s_axis_c_tvalid,
    input aclk,
    input aresetn);
  
  wire [31:0] result;
  wire [18:0] tuser;
  
  
  assign m_axis_result_tdata[31] = ~result[31];
  assign m_axis_result_tdata[30:0] = result[30:0];
  assign m_axis_result_tflags = tuser[2:0];
  assign m_axis_result_tuser = tuser[18:3];

  floating_point_multiply_subtract fp_unit
       (.m_axis_result_tdata(result),
        .m_axis_result_tready(m_axis_result_tready),
        .m_axis_result_tuser(tuser),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .s_axis_a_tdata(s_axis_a_tdata),
        .s_axis_a_tready(s_axis_a_tready),
        .s_axis_a_tuser(s_axis_a_tuser),
        .s_axis_a_tvalid(s_axis_a_tvalid),
        .s_axis_b_tdata(s_axis_b_tdata),
        .s_axis_b_tready(s_axis_b_tready),
        .s_axis_b_tvalid(s_axis_b_tvalid),
        .s_axis_c_tdata(s_axis_c_tdata),
        .s_axis_c_tready(s_axis_c_tready),
        .s_axis_c_tvalid(s_axis_c_tvalid),
        .aclk(aclk),
        .aresetn(aresetn));
endmodule
