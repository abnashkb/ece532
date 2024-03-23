// Tableau -> C
// Pivot Row -> A
// Pivot Column -> B

module update_tableau(
        input [31:0] s_axis_pivot_column_tdata,
        input s_axis_pivot_column_tvalid,
        output s_axis_pivot_column_tready,
        input [31:0] s_axis_pivot_row_tdata,
        output [15:0] s_axis_pivot_row_address,
        input [31:0] s_axis_tableau_tdata,
        input s_axis_tableau_tvalid,
        output s_axis_tableau_tready,
        output [31:0] m_axis_result,
        output m_axis_result_tvalid,
        input m_axis_result_tready,
        input [15:0] num_rows,
        input [15:0] num_cols,
        input clk,
        input resetn,
        output reg cont,
        output reg terminate
    );

    // Tracks position in tableau
    reg [15:0] row_index;
    reg [15:0] col_index;

    assign s_axis_pivot_row_address = col_index;

    // Handles wrapping around to next row when we reach the end of a row (not this introduces a cycle delay)
    always @(posedge clk) begin
        if (!resetn) begin
            row_index <= 0;
            cont <= 0;
            col_index <= 0;
        end
        else if (ready_to_increment) begin
            col_index <= col_index + 1;
        end
        else if (col_index == num_cols) begin
            row_index <= row_index + 1;
            col_index <= 0;
        end
    end

    // Accept a new pivot_column value whenever we reach the end of a row and we're ready. 
    // We use combinational axi_logic (which is technically illegal).
    reg [31:0] cur_pivot_col_val;
    reg curr_pivot_col_val_is_nan;
    assign s_axis_pivot_column_tready = resetn && (col_index == num_cols || curr_pivot_col_val_is_nan);
    always @(posedge clk) begin
        if (!resetn) begin
            cur_pivot_col_val <= 0;
            curr_pivot_col_val_is_nan <= 1;
        end
        else if (s_axis_pivot_column_tready && s_axis_pivot_column_tvalid) begin
            cur_pivot_col_val <= s_axis_pivot_column_tdata;
            curr_pivot_col_val_is_nan <= 0;
        end
        else if (col_index == num_cols) begin
            cur_pivot_col_val <= 0;
            curr_pivot_col_val_is_nan <= 1;
        end
    end

    assign output cont = row_index == num_rows;

    assign wire ready_to_increment = resetn 
            && s_axis_all_ready
            && s_axis_pivot_row_tvalid
            && s_axis_tableau_tvalid
            && (col_index != num_cols) 
            && (row_index != num_rows) 
            && (!curr_pivot_col_val_is_nan)
            && !terminate
            && !cont;
    assign s_axis_tableau_tready = ready_to_increment;
    assign s_axis_pivot_row_tready = ready_to_increment;

    wire s_axis_a_ready;
    wire s_axis_b_ready;
    wire s_axis_c_ready;
    wire m_axis_result_tflags;
    assign wire s_axis_all_ready = s_axis_a_ready && s_axis_b_ready && s_axis_c_ready; 
    floating_point_subtract_multiply fp_unit (
        .m_axis_result_tdata(m_axis_result),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .m_axis_result_tready(m_axis_result_tready),
        .m_axis_result_tflags(m_axis_result_tflags)
        .s_axis_a_tdata(s_axis_pivot_row_tdata),
        .s_axis_a_tvalid(ready_to_increment),
        .s_axis_a_tready(s_axis_a_ready),
        .s_axis_b_tdata(cur_pivot_col_val),
        .s_axis_b_tvalid(ready_to_increment),
        .s_axis_b_tready(s_axis_b_ready),
        .s_axis_c_tdata(s_axis_tableau_tdata),
        .s_axis_c_tvalid(ready_to_increment),
        .s_axis_c_tready(s_axis_c_ready),
        .aclk(clk),
        .aresetn(resetn)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            terminate <= 0;
        end
        else if (m_axis_result_tflags[0] || m_axis_result_tflags[1] || m_axis_result_tflags[2]) begin
            terminate <= 1;
        end
    end
endmodule