`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/20/2024 02:56:58 PM
// Design Name: 
// Module Name: update_mult_sub_block
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


module update_mult_sub_block(
    input aclk,
    input aresetn,
    input start,
    input halt0,
    input halt1,
    input [31:0] s_axis_tdata,
    input [3:0] s_axis_tstrb,
    input s_axis_tlast,
    input s_axis_tvalid,
    input [31:0] pivot_row_s_axis_tdata,
    input [3:0] pivot_row_s_axis_tstrb,
    input pivot_row_s_axis_tlast,
    input pivot_row_s_axis_tvalid,
    input [31:0] s_fifo_axis_tdata,
    input [3:0] s_fifo_axis_tstrb,
    input s_fifo_axis_tlast,
    input s_fifo_axis_tvalid,
    
    // Outputs
    output s_axis_tready,
    output pivot_row_s_axis_tready,
    output s_fifo_axis_tready,
    output terminate,
    output op_continue
    );
    
    update_mult_sub_s_axis_intf_0 axis_intf(
      .s00_axis_tdata(s_axis_tdata),
      .s00_axis_tstrb(s_axis_tstrb),
      .s00_axis_tlast(s_axis_tlast),
      .s00_axis_tvalid(s_axis_tvalid),
      .s00_axis_tready(s_axis_tready),
      .s00_axis_aclk(aclk),
      .s00_axis_aresetn(aresetn)
    );
    
    update_mult_sub_s_axis_intf_0 pivot_row_axis_intf(
      .s00_axis_tdata(pivot_row_s_axis_tdata),
      .s00_axis_tstrb(pivot_row_s_axis_tstrb),
      .s00_axis_tlast(pivot_row_s_axis_tlast),
      .s00_axis_tvalid(pivot_row_s_axis_tvalid),
      .s00_axis_tready(pivot_row_s_axis_tready),
      .s00_axis_aclk(aclk),
      .s00_axis_aresetn(aresetn)
    );
    
    update_mult_sub_s_axis_intf_0 fifo_axis_intf(
      .s00_axis_tdata(s_fifo_axis_tdata),
      .s00_axis_tstrb(s_fifo_axis_tstrb),
      .s00_axis_tlast(s_fifo_axis_tlast),
      .s00_axis_tvalid(s_fifo_axis_tvalid),
      .s00_axis_tready(s_fifo_axis_tready),
      .s00_axis_aclk(aclk),
      .s00_axis_aresetn(aresetn)
    );
    
endmodule