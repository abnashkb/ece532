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
   (output [31:0] M_AXIS_RESULT_tdata,
    input M_AXIS_RESULT_tready,
    output [15:0] M_AXIS_RESULT_tuser,
    output [2:0] M_AXIS_RESULT_tflags,
    output M_AXIS_RESULT_tvalid,
    input [31:0] S_AXIS_A_tdata,
    output S_AXIS_A_tready,
    input [15:0] S_AXIS_A_tuser,
    input S_AXIS_A_tvalid,
    input [31:0] S_AXIS_B_tdata,
    output S_AXIS_B_tready,
    input S_AXIS_B_tvalid,
    input [31:0] S_AXIS_C_tdata,
    output S_AXIS_C_tready,
    input S_AXIS_C_tvalid,
    input aclk,
    input aresetn);
  
  wire [31:0] result;
  wire [18:0] tuser;
  
  
  assign M_AXIS_RESULT_tdata[31] = ~result[31];
  assign M_AXIS_RESULT_tdata[30:0] = result[30:0];
  assign M_AXIS_RESULT_tflags = tuser[2:0];
  assign M_AXIS_RESULT_tuser = tuser[18:3];

  floating_point_multiply_subtract fp_unit
       (.M_AXIS_RESULT_tdata(result),
        .M_AXIS_RESULT_tready(M_AXIS_RESULT_tready),
        .M_AXIS_RESULT_tuser(tuser),
        .M_AXIS_RESULT_tvalid(M_AXIS_RESULT_tvalid),
        .S_AXIS_A_tdata(S_AXIS_A_tdata),
        .S_AXIS_A_tready(S_AXIS_A_tready),
        .S_AXIS_A_tuser(S_AXIS_A_tuser),
        .S_AXIS_A_tvalid(S_AXIS_A_tvalid),
        .S_AXIS_B_tdata(S_AXIS_B_tdata),
        .S_AXIS_B_tready(S_AXIS_B_tready),
        .S_AXIS_B_tvalid(S_AXIS_B_tvalid),
        .S_AXIS_C_tdata(S_AXIS_C_tdata),
        .S_AXIS_C_tready(S_AXIS_C_tready),
        .S_AXIS_C_tvalid(S_AXIS_C_tvalid),
        .aclk(aclk),
        .aresetn(aresetn));
endmodule
