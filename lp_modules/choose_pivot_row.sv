`include "axi_stream_type.sv"

module choose_pivot_row
    # (
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
    output terminate,
    output cont
);
    wire [15:0] pivot_row_index;
    wire [DATAW-1:0] pivot_value;
    wire [15:0] rhs_value;

    choose_pivot_row_stage_1 #(.DATAW(DATAW)) stage1(
        .clk(clk),
        .resetn(resetn),
        .axi_pivotcol(axi_pivotcol),
        .axi_rightcol(axi_rightcol),
        .terminate(terminate),
        .pivot_value(pivot_value),
        .rhs_value(rhs_value),
        .pivot_row_index(pivot_row_index),
        .valid_stage_1_out(valid_stage_1_out),
        .ready_stage_1_out(ready_stage_1_out)
    );

    axi_stream rhs_stage_2_in;
    axi_stream pivot_stage_2_in;
    rhs_stage_2_in.valid = valid_stage_1_out;
    pivot_stage_2_in.valid = valid_stage_1_out;
    rhs_stage_2_in.data = rhs_value;
    pivot_stage_2_in.data = pivot_value;
    rhs_stage_2_in.ready = ready_stage_1_out;
    pivot_stage_2_in.ready = ready_stage_1_out;

    choose_pivot_row_stage_2 #(.DATAW(DATAW)) stage2(
        .clk(clk),
        .resetn(resetn),
        .terminate(terminate),
        .cont(cont),
        .num_rows(num_rows),
        .axi_rhscol(rhs_stage_2_in),
        .axi_pivotcol(pivot_stage_2_in),
        .pivot_row_index(pivot_row_index)
    );
endmodule