`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ECE532 Group 1: LP Solver on an FPGA
// 
// Create Date: 02/20/2024 02:47:55 PM
// Design Name: Update Divider Block
// Module Name: update_divider_block
// Target Devices: Nexys4 Video
//////////////////////////////////////////////////////////////////////////////////


module update_divider_block(
    input aclk,
    input aresetn,
    input start,
    input [31:0] s_axis_tdata,
    input [3:0] s_axis_tstrb,
    input s_axis_tlast,
    input s_axis_tvalid,
    input [15:0] num_cols,
    
    // Outputs
    output s_axis_tready,
    output terminate,
    output op_continue
    );
    
    update_divider_s_axis_intf_0 axis_intf(
      .s00_axis_tdata(s_axis_tdata),
      .s00_axis_tstrb(s_axis_tstrb),
      .s00_axis_tlast(s_axis_tlast),
      .s00_axis_tvalid(s_axis_tvalid),
      .s00_axis_tready(s_axis_tready),
      .s00_axis_aclk(aclk),
      .s00_axis_aresetn(aresetn)
    );
    
endmodule
