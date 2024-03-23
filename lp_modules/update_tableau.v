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
        input [15:0] num_rows_m_1,
        input [15:0] num_cols,
        input clk,
        input resetn,
        output reg cont,
        output reg terminate
    );

    // Tracks position in tableau
    reg [15:0] row_index;
    reg [15:0] col_index;
    
    // The value of the pivot column for the current row. is_nan flag is true when the value is unset.
    reg [31:0] cur_pivot_col_val;
    reg curr_pivot_col_val_unset;
    
    wire s_axis_a_ready;
    wire s_axis_b_ready;
    wire s_axis_c_ready;
    wire [2:0] m_axis_result_tflags;
    wire s_axis_all_ready = s_axis_a_ready && s_axis_b_ready && s_axis_c_ready; 
    
    // Create cont
    always @(posedge clk) begin
        if (!resetn) cont <= 0;
        else if (row_index == num_rows_m_1) cont <= 1;
    end
    
    // Create terminate
    always @(posedge clk) begin
        if (!resetn) terminate <= 0;
        else if (m_axis_result_tflags[0] || m_axis_result_tflags[1] || m_axis_result_tflags[2]) terminate <= 1;
    end
    
    // Ensures data (s_axis_pivot_row_tdata) is always synced with our col_index;
    assign s_axis_pivot_row_address = col_index;

    // Accept a new pivot_column value whenever we reach the end of a row and we're ready. 
    // We use combinational axi_logic (which is technically illegal).

    assign s_axis_pivot_column_tready = resetn && (col_index == num_cols || curr_pivot_col_val_unset);
    always @(posedge clk) begin
        if (!resetn) begin
            cur_pivot_col_val <= 0;
            curr_pivot_col_val_unset <= 1;
        end
        else if (s_axis_pivot_column_tready && s_axis_pivot_column_tvalid) begin
            cur_pivot_col_val <= s_axis_pivot_column_tdata;
            curr_pivot_col_val_unset <= 0;
        end
        else if (col_index == num_cols) begin
            cur_pivot_col_val <= 0;
            curr_pivot_col_val_unset <= 1;
        end
    end

    
    wire s_axis_tableau_tready = resetn 
            && s_axis_all_ready
            && s_axis_tableau_tvalid // This ensures ready is only high when valid is high
            && (col_index != num_cols) 
            && (row_index != num_rows_m_1) 
            && (!curr_pivot_col_val_unset)
            && !terminate
            && !cont;

    // Handles wrapping around to next row when we reach the end of a row (not this introduces a cycle delay)
    always @(posedge clk) begin
        if (!resetn) begin
            row_index <= 0;
            col_index <= 0;
        end
        else if (s_axis_tableau_tready) begin
            col_index <= col_index + 1;
        end
        else if (col_index == num_cols) begin
            row_index <= row_index + 1;
            col_index <= 0;
        end
    end



    floating_point_subtract_multiply fp_unit (
        .m_axis_result_tdata(m_axis_result),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .m_axis_result_tready(m_axis_result_tready),
        .m_axis_result_tflags(m_axis_result_tflags),
        .s_axis_a_tdata(s_axis_pivot_row_tdata),
        .s_axis_a_tvalid(s_axis_tableau_tready),
        .s_axis_a_tready(s_axis_a_ready),
        .s_axis_b_tdata(cur_pivot_col_val),
        .s_axis_b_tvalid(s_axis_tableau_tready),
        .s_axis_b_tready(s_axis_b_ready),
        .s_axis_c_tdata(s_axis_tableau_tdata),
        .s_axis_c_tvalid(s_axis_tableau_tready),
        .s_axis_c_tready(s_axis_c_ready),
        .aclk(clk),
        .aresetn(resetn)
    );
endmodule