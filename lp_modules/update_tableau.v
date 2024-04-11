// Tableau -> C
// Pivot Row -> A
// Pivot Column -> B

module update_tableau(
        // DEBUGGING
        pc_state,
        pc_valid,
        pc_s_axis_tready,
        
        pivot_row_BRAM_valid,
        
        curr_iteration,
        
        row_index,
        col_index,
        skip_row,
       
        s_axis_a_ready,
        s_axis_b_ready,
        s_axis_c_ready,
        M_AXIS_RESULT_TFLAGS,
        
        pr_data,
        pc_data,
        tableau_data,
        fp_unit_valid_in,
        
        // DEBUGGING END
        
        S_AXIS_PIVOT_COL_TDATA,
        S_AXIS_PIVOT_COL_TVALID,
        S_AXIS_PIVOT_COL_TREADY,
       
        pivot_row_BRAM_data,
        pivot_row_BRAM_address,
        pivot_row_index,
       
        S_AXIS_TABLEAU_TDATA,
        S_AXIS_TABLEAU_TVALID,
        S_AXIS_TABLEAU_TREADY,
       
        M_AXIS_RESULT_TDATA,
        M_AXIS_RESULT_TVALID,
        M_AXIS_RESULT_TREADY,
       
        num_rows_current_iteration,        // Two iterations: all the rows before the pivot row & all the rows after the pivot row, controlled by FSM
        num_cols,

        clk,
        resetn,       // should be asserted for two clock cycles
        start,
       
        cont,
        terminate
    );
    
    // DEBUGGING
    input [31:0] S_AXIS_PIVOT_COL_TDATA;
    input S_AXIS_PIVOT_COL_TVALID;
    output S_AXIS_PIVOT_COL_TREADY;
    
    input [15:0] curr_iteration;
    
    input [31:0] pivot_row_BRAM_data;
    input [15:0] pivot_row_index;
    output [31:0] pivot_row_BRAM_address;
    
    input [31:0] S_AXIS_TABLEAU_TDATA;
    input S_AXIS_TABLEAU_TVALID;
    output S_AXIS_TABLEAU_TREADY;
    
    output [31:0] M_AXIS_RESULT_TDATA;
    output M_AXIS_RESULT_TVALID;
    input M_AXIS_RESULT_TREADY;
    
    input [15:0] num_rows_current_iteration;        // Two iterations: all the rows before the pivot row & all the rows after the pivot row, controlled by FSM
    input [15:0] num_cols;

    input clk;
    input resetn;       // should be asserted for two clock cycles
    input start;        // should be asserted for duration of operation
    
    output reg cont;
    output reg terminate;

    //DEBUGGIN END

    // Tracks position in tableau
    output reg [15:0] row_index;
    output reg [15:0] col_index;
    
    // Floating point unit signals
    output wire s_axis_a_ready;
    output wire s_axis_b_ready;
    output wire s_axis_c_ready;
    output wire [2:0] M_AXIS_RESULT_TFLAGS;
    wire s_axis_all_ready = s_axis_a_ready && s_axis_b_ready && s_axis_c_ready; 

    // Create cont - assert it when we are at the last element and we pass it successfully to the divider
    always @(posedge clk) begin
        if (!resetn) cont <= 0;
        else if ((row_index == num_rows_current_iteration) && (col_index == num_cols) && S_AXIS_TABLEAU_TREADY) cont <= 1;
    end
    
    // Create terminate
    always @(posedge clk) begin
        if (!resetn) terminate <= 0;
        else if (M_AXIS_RESULT_TFLAGS[0] || M_AXIS_RESULT_TFLAGS[1] || M_AXIS_RESULT_TFLAGS[2]) terminate <= 1;
    end
    
    // BRAM pivot row interfacing --> read latency = 2 clock cycles --> need a wait state and a READY signal
    // Ensures data (pivot_row_BRAM_data) is always synced with our col_index;
    reg [2:0] bram_state;
    
    parameter BRAM_READ_LATENCY = 'd2;
    reg [3:0] bram_wait_counter;
    
    assign pivot_row_BRAM_address = {16'd0, ((col_index - 1) << 2)};     // 4 byte address offset addressable
    output reg pivot_row_BRAM_valid;

    always @(posedge clk) begin
        if (!resetn) begin
            bram_wait_counter <= BRAM_READ_LATENCY;
            pivot_row_BRAM_valid <= 0;

            bram_state <= 3'd0;
        end
        else if (bram_state == 3'd0) begin     // Deassert en, decrement wait counter and wait
            bram_wait_counter <= bram_wait_counter - 1;
            
            if (bram_wait_counter == 1) begin  // Note: we wait until counter is 1, not zero
                bram_state <= 3'd1;
            end
            else bram_state <= 3'd0;
        end
        else if (bram_state == 3'd1) begin     // Assert valid data, and reset wait counter
            pivot_row_BRAM_valid <= 1;
            bram_wait_counter <= BRAM_READ_LATENCY;

            bram_state <= 3'd2;
        end
        else if (bram_state == 3'd2) begin     // Wait for every operand to be ready, before moving on to fetching next element
            if (S_AXIS_TABLEAU_TREADY) begin    
                pivot_row_BRAM_valid <= 0;
                
                bram_state <= 3'd0;
            end
        end
    end
    

    // Accept a new pivot_column value whenever we reach the end of a row and we're ready. 
    // We use combinational axi_logic (which is technically illegal).
    // VERIFIED
    output reg [2:0] pc_state;

    output reg pc_s_axis_tready;       // TREADY signal for pivot column AXIS
    output reg pc_valid;               // Indicates that the current pivot column value is valid
    output reg [31:0] pc_data;         // The actual valid pivot column data

    assign S_AXIS_PIVOT_COL_TREADY = pc_s_axis_tready;     // TREADY assignment

    always @(posedge clk) begin
        if ((resetn == 1'b0) && (start == 1'b1)) begin      // Reset (start) asserted
            pc_valid <= 1'b0;
            pc_data <= 'd0;
            pc_s_axis_tready <= 1'b0;

            pc_state <= 3'd0;
        end
        else if ((cont == 1'b1) || (terminate == 1'b1)) begin   // Done or error
            pc_valid <= 1'b0;
            pc_s_axis_tready <= 1'b0;
            pc_data <= 'd0;
            
            pc_state <= 3'd4;
        end
        else begin                              // FSM
            if ((pc_state == 3'd0) && (start == 1'b1)) begin    // Check if we need to grab a new value (i.e. !pc_valid). If so, set TREADY, increment state and wait on TVALID
                if (pc_valid == 1'b0) begin
                    pc_s_axis_tready <= 1'b1;
                    
                    pc_state <= 3'd1;
                end
                else pc_state <= 3'd0;
            end
            else if ((pc_state == 3'd1) && (start == 1'b1)) begin
                if (S_AXIS_PIVOT_COL_TVALID == 1'b1) begin    // Wait on TVALID, then deassert TREADY, grab the new value, assert pc_valid (we have good data!) and increment state
                    pc_s_axis_tready <= 1'b0;
                    pc_data <= S_AXIS_PIVOT_COL_TDATA;
                    pc_valid <= 1'b1;
                    
                    pc_state <= 3'd2;
                end
                else pc_state <= 3'd1;
            end
            else if ((pc_state == 3'd2) && (start == 1'b1)) begin    // Check if we are about to wrap to a new row, in which case, deassert valid, and go grab a new value (state = 0). Otherwise stay in this state
                if ((col_index == num_cols) && (S_AXIS_TABLEAU_TREADY == 1'b1)) begin
                    pc_valid <= 1'b0;
                    
                    pc_state <= 3'd0;
                end
                else pc_state <= 3'd2;
            end
            else begin              // Currently not doing anything
                pc_valid <= 1'b0;
                pc_s_axis_tready <= 1'b0;
                pc_data <= 'd0;
                
                pc_state <= 3'd4;
            end
        end
    end
    
    // Tells the FP unit that data on its input is valid
    assign S_AXIS_TABLEAU_TREADY = resetn 
            && s_axis_all_ready             // FP unit ready to receive new data
            && S_AXIS_TABLEAU_TVALID        // Received valid tableau data
            && pivot_row_BRAM_valid         // Received valid pivot row data
            && pc_valid                     // Current row contains a valid pivot column value
            && start                        // We have started the operation
            && !terminate                   // We have not terminated
            && !cont;                       // We are not done

    // Handles wrapping around to next row when we reach the end of a row
    always @(posedge clk) begin
        if (!resetn) begin
            row_index <= 'd1;
            col_index <= 'd1;
        end
        else if (S_AXIS_TABLEAU_TREADY) begin
            if (col_index == num_cols) begin        // If at the end of a row, loop back and increment row_index
                row_index <= row_index + 1;
                col_index <= 'd1;
            end
            else col_index <= col_index + 1;        // Else, increment col_index
        end
    end
    
    // Check if we're in pivot row: in this case, we do not update any element in the pivot row, equivalent to setting B = 0 in (A*B - C) where C is tableau data
    output wire skip_row;
    assign skip_row = (row_index == pivot_row_index);

    // Invert the result of the FP unit
    wire [31:0] fp_output;

    assign M_AXIS_RESULT_TDATA[31] = ~fp_output[31];
    assign M_AXIS_RESULT_TDATA[30:0] = fp_output[30:0];
    
    // DEBUGGING
    output [31:0] pr_data;
    // output [31:0] pc_data;
    output [31:0] tableau_data;
    output fp_unit_valid_in;
    
    assign pr_data = pivot_row_BRAM_data;
    // assign pc_data = S_AXIS_PIVOT_COL_TDATA;
    assign tableau_data = S_AXIS_TABLEAU_TDATA;
    assign fp_unit_valid_in = S_AXIS_TABLEAU_TREADY;
    
    floating_point_multiply_subtract fp_unit (
        .m_axis_result_tdata(fp_output),
        .m_axis_result_tvalid(M_AXIS_RESULT_TVALID),
        .m_axis_result_tready(M_AXIS_RESULT_TREADY),
        .m_axis_result_tuser(M_AXIS_RESULT_TFLAGS),

        .s_axis_a_tdata(pivot_row_BRAM_data),
        .s_axis_a_tvalid(S_AXIS_TABLEAU_TREADY),
        .s_axis_a_tready(s_axis_a_ready),
        
        .s_axis_b_tdata((skip_row == 1'b1) ? 32'b0 : pc_data),
        .s_axis_b_tvalid(S_AXIS_TABLEAU_TREADY),
        .s_axis_b_tready(s_axis_b_ready),
        
        .s_axis_c_tdata((skip_row == 1'b1) ? pivot_row_BRAM_data : S_AXIS_TABLEAU_TDATA),
        .s_axis_c_tvalid(S_AXIS_TABLEAU_TREADY),
        .s_axis_c_tready(s_axis_c_ready),
        
        .aclk(clk),
        .aresetn(resetn)
    );
endmodule