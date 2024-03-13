`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ECE532 Group 1: LP Solver on an FPGA
// 
// Create Date: 02/20/2024 02:28:13 PM
// Design Name: Pivot Row Block
// Module Name: pivot_row_block
// Target Devices: Nexys4 Video
//////////////////////////////////////////////////////////////////////////////////


module pivot_row_block(
    // Inputs
    input aclk,
    input aresetn,
    input start,
    input halt,
    input [31:0] s_axis_tdata,
    input [3:0] s_axis_tstrb,
    input s_axis_tlast,
    input s_axis_tvalid,
    input [31:0] pivot_col_s_axis_tdata,
    input [3:0] pivot_col_s_axis_tstrb,
    input pivot_col_s_axis_tlast,
    input pivot_col_s_axis_tvalid,
    
    // Outputs
    output s_axis_tready,
    output pivot_col_s_axis_tready,
    output terminate,
    output op_continue,
    output pivot_row_idx
    );
    
    pivot_row_s_axis_intf_0 axis_intf (
      .s00_axis_tdata(s_axis_tdata),      // input wire [31 : 0] s00_axis_tdata
      .s00_axis_tstrb(s_axis_tstrb),      // input wire [3 : 0] s00_axis_tstrb
      .s00_axis_tlast(s_axis_tlast),      // input wire s00_axis_tlast
      .s00_axis_tvalid(s_axis_tvalid),    // input wire s00_axis_tvalid
      .s00_axis_tready(s_axis_tready),    // output wire s00_axis_tready
      .s00_axis_aclk(aclk),        // input wire s00_axis_aclk
      .s00_axis_aresetn(aresetn)  // input wire s00_axis_aresetn
    );
    
    pivot_row_s_axis_intf_0 pivot_col_axis_intf (
      .s00_axis_tdata(pivot_col_s_axis_tdata),      // input wire [31 : 0] s00_axis_tdata
      .s00_axis_tstrb(pivot_col_s_axis_tstrb),      // input wire [3 : 0] s00_axis_tstrb
      .s00_axis_tlast(pivot_col_s_axis_tlast),      // input wire s00_axis_tlast
      .s00_axis_tvalid(pivot_col_s_axis_tvalid),    // input wire s00_axis_tvalid
      .s00_axis_tready(pivot_col_s_axis_tready),    // output wire s00_axis_tready
      .s00_axis_aclk(aclk),        // input wire s00_axis_aclk
      .s00_axis_aresetn(aresetn)  // input wire s00_axis_aresetn
    );

endmodule
