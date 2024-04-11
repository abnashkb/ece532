`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2024 05:48:07 PM
// Design Name: 
// Module Name: fifo_redirect
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


module fifo_redirect(
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Control logic input - see if you can implement it without FIFO full signal
    input wire [15:0] tableau_num_cols,
    input wire [31:0] tableau_total_size,
    output wire busy,                           // DONE
    output wire done,                           // DONE
    output wire start,                          // DONE
    
    // AXI Stream from update block
    input wire [31:0] S_AXIS_TDATA,
    input wire S_AXIS_TVALID,
    output wire S_AXIS_TREADY,                  // DONE
    
    // FIFO signals (writing to three different FIFOs)
    output wire [31:0] M_AXIS_TDATA,            // DONE
    
    output wire M_AXIS_TVALID_DDR,
    output wire M_AXIS_TVALID_OBJ_ROW,
    output wire M_AXIS_TVALID_RHS_COL,
    
    input wire M_AXIS_TREADY_DDR,
    input wire M_AXIS_TREADY_OBJ_ROW,
    input wire M_AXIS_TREADY_RHS_COL,
    
    input wire rst_busy_ddr,
    input wire rst_busy_obj_row,
    input wire rst_busy_rhs_col
);

    // IO Assignment of the TDATA signal
    assign M_AXIS_TDATA = S_AXIS_TDATA;

    /********************************************************************************/
    /***************************** TOP LEVEL FSM ************************************/
    /********************************************************************************/
    
    // Top level FSM reg signals
    reg [31:0] FSM_element_counter;
    reg [15:0] FSM_row_end_counter;
    
    reg FSM_busy;          // Control signals
    reg FSM_done;
    reg FSM_start;
    
    reg FSM_s_axis_tready;  // S_AXIS signals

    reg FSM_DDR_m_axis_tvalid;  // M_AXIS signals
    reg FSM_RHS_m_axis_tvalid;
    reg FSM_OBJ_m_axis_tvalid;
    
    // IO Assignment of Control, S_AXIS, and M_AXIS signals
    assign busy = FSM_busy;
    assign done = FSM_done;
    assign start = FSM_start;
    
    assign S_AXIS_TREADY = FSM_s_axis_tready;
    
    assign M_AXIS_TVALID_DDR = FSM_DDR_m_axis_tvalid;
    assign M_AXIS_TVALID_RHS_COL = FSM_RHS_m_axis_tvalid;
    assign M_AXIS_TVALID_OBJ_ROW = FSM_OBJ_m_axis_tvalid;

    // State definitions
    parameter S0 = 'd0, S1 = 'd1, S2 = 'd2, S3 = 'd3;
    
    reg [2:0] current_state;
    
    // FSM Logic
    always @ (posedge aclk) begin
        // Reset asserted
        if (aresetn == 1'b0) begin
            current_state <= S0;
            
            // Reset all signals
            FSM_element_counter <= 32'd1;
            FSM_row_end_counter <= 16'd1;
            
            FSM_busy <= 1'b0;
            FSM_done <= 1'b0;
            FSM_start <= 1'b0;
            
            FSM_s_axis_tready <= 1'b0;

            FSM_DDR_m_axis_tvalid <= 1'b0;
            FSM_RHS_m_axis_tvalid <= 1'b0;
            FSM_OBJ_m_axis_tvalid <= 1'b0;
        end
        
        // If any FIFO is resetting itself, FSM waits
        else if (rst_busy_ddr || rst_busy_obj_row || rst_busy_rhs_col) current_state <= current_state;
        
        // Next state logic
        else begin
            case (current_state)
                S0: begin
                    // Identical to the reset stage, except we move on to the next state on the next edge
                    current_state <= S1;
                    
                    // Reset all signals
                    FSM_element_counter <= 32'd1;
                    FSM_row_end_counter <= 16'd1;
                    
                    FSM_busy <= 1'b0;
                    FSM_done <= 1'b0;
                    FSM_start <= 1'b0;
                    
                    FSM_s_axis_tready <= 1'b0;

                    FSM_DDR_m_axis_tvalid <= 1'b0;
                    FSM_RHS_m_axis_tvalid <= 1'b0;
                    FSM_OBJ_m_axis_tvalid <= 1'b0;
                end
                
                S1: begin
                    // Deassert TREADY from final states and wait for TVALID, on which assert busy and determine if M_X_TVALID should be asserted
                    // Also add the start signal code (start asserted when S_AXIS_TVALID == 1 and element_counter == 1)
                    FSM_s_axis_tready <= 1'b0;
                    
                    if (S_AXIS_TVALID == 1'b1) begin
                        current_state <= S2;
                        
                        // If all upper bits of element_counter are 0 and LSB is 1 (i.e. element_counter == 1), assert start for one clock cycle
                        if ((~(| FSM_element_counter[31:1])) && (FSM_element_counter[0] == 1'b1)) FSM_start <= 1'b1;
                        
                        FSM_busy <= 1'b1;
                        
                        FSM_DDR_m_axis_tvalid <= 1'b1;          // We write every element to DDR
                        
                        // Check if data is in the OBJ ROW --> write to OBJ ROW
                        if (FSM_element_counter <= tableau_num_cols) begin
                            FSM_OBJ_m_axis_tvalid <= 1'b1;
                        end
                        
                        // Check if data is in the RHS COL --> write to RHS COL
                        if (FSM_row_end_counter == tableau_num_cols) begin
                            FSM_RHS_m_axis_tvalid <= 1'b1;
                            FSM_row_end_counter <= 16'd0;   // Reset row_end counter
                        end
                    end
                    else current_state <= S1;
                end
                
                S2: begin
                    // Deassert start, and wait for all TVALID's to finish (i.e. all M_X_TREADY asserted), on which we assert S_AXIS_TREADY.
                    FSM_start <= 1'b0;

                    // If any of these if statements execute, we assume slave captured data successfully
                    if (M_AXIS_TREADY_DDR == 1'b1) FSM_DDR_m_axis_tvalid <= 1'b0;
                    if (M_AXIS_TREADY_RHS_COL == 1'b1) FSM_RHS_m_axis_tvalid <= 1'b0;
                    if (M_AXIS_TREADY_OBJ_ROW == 1'b1) FSM_OBJ_m_axis_tvalid <= 1'b0;

                    // All TVALID's finish
                    if ((FSM_DDR_m_axis_tvalid == 1'b0) && (FSM_RHS_m_axis_tvalid == 1'b0) && (FSM_OBJ_m_axis_tvalid == 1'b0)) begin
                        current_state <= S3;
                        
                        FSM_s_axis_tready <= 1'b1;
                    end
                    else current_state <= S2;
                end
                
                S3: begin
                    // Need at least one clock cycle delay before deasserting TREADY and reading next TVALID. In here we can increment counters and check for completion
                    FSM_s_axis_tready <= 1'b0;
                    
                    // We received and wrote all data in tableau
                    if (FSM_element_counter == tableau_total_size) begin
                        current_state <= S0;            // Go back to reset state

                        FSM_done <= 1'b1;               // Assert done signal
                        FSM_busy <= 1'b0;               // Deassert busy signal
                    end

                    // Not done, increment counters and go back to waiting on TVALID
                    else begin
                        current_state <= S1;
                        
                        FSM_element_counter <= FSM_element_counter + 1;
                        FSM_row_end_counter <= FSM_row_end_counter + 1;
                    end
                end
                
                default: begin
                    current_state <= S0;
            
                    // Reset all signals
                    FSM_element_counter <= 32'd1;
                    FSM_row_end_counter <= 16'd1;
                    
                    FSM_busy <= 1'b0;
                    FSM_done <= 1'b0;
                    FSM_start <= 1'b0;
                    
                    FSM_s_axis_tready <= 1'b0;

                    FSM_DDR_m_axis_tvalid <= 1'b0;
                    FSM_RHS_m_axis_tvalid <= 1'b0;
                    FSM_OBJ_m_axis_tvalid <= 1'b0;
                end
            endcase
        end
    end
endmodule