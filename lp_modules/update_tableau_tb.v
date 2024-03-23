`timescale 1ns / 1ps

parameter FP_ONE = 32'h3F800000; // 1.0 in IEEE754 single precision
parameter FP_TWO = 32'h40000000; // 2.0 in IEEE754 single precision
parameter FP_THREE = 32'h40400000; // 3.0 in IEEE754 single precision
parameter FP_FOUR = 32'h40800000; // 4.0 in IEEE754 single precision



module update_tableau_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns

    // Inputs
    reg [31:0] s_axis_pivot_column_tdata;
    reg s_axis_pivot_column_tvalid;
    wire s_axis_pivot_column_tready;
    reg [31:0] s_axis_pivot_row_tdata;
    wire [15:0] s_axis_pivot_row_address;
    reg [31:0] s_axis_tableau_tdata;
    reg s_axis_tableau_tvalid;
    wire s_axis_tableau_tready;
    wire [31:0] m_axis_result;
    wire m_axis_result_tvalid;
    reg m_axis_result_tready;
    reg [15:0] num_rows;
    reg [15:0] num_cols;
    reg clk;
    reg resetn;

    // Instantiate the module under test
    update_tableau dut (
        .s_axis_pivot_column_tdata(s_axis_pivot_column_tdata),
        .s_axis_pivot_column_tvalid(s_axis_pivot_column_tvalid),
        .s_axis_pivot_column_tready(s_axis_pivot_column_tready),
        .s_axis_pivot_row_tdata(s_axis_pivot_row_tdata),
        .s_axis_pivot_row_address(s_axis_pivot_row_address),
        .s_axis_tableau_tdata(s_axis_tableau_tdata),
        .s_axis_tableau_tvalid(s_axis_tableau_tvalid),
        .s_axis_tableau_tready(s_axis_tableau_tready),
        .m_axis_result(m_axis_result),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .m_axis_result_tready(m_axis_result_tready),
        .num_rows(num_rows),
        .num_cols(num_cols),
        .clk(clk),
        .resetn(resetn),
        .cont(), // Unused outputs in testbench
        .terminate() // Unused outputs in testbench
    );

    // Clock generation
    always #((CLK_PERIOD)/2) clk = ~clk;

    // Stimulus
    initial begin
        // Initialize inputs
        clk = 0;
        resetn = 0;
        s_axis_pivot_column_tvalid = 0;
        s_axis_tableau_tvalid = 0;
        num_rows = 3;
        num_cols = 4;
        // Release reset
        #100 resetn = 1;
        // Apply stimulus
        #10 s_axis_tableau_tvalid = 1;
        #10 s_axis_pivot_row_tdata = 1; // Example value for pivot row data
        #10 s_axis_pivot_column_tvalid = 1;
        #10 s_axis_pivot_column_tdata = 2; // Example value for pivot column data
        #1000 $stop;
    end
endmodule
