`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2024 04:13:18 PM
// Design Name: 
// Module Name: fifo_dma
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

module fifo_dma(
    // Clock and Reset
    input wire aclk,
    input wire aresetn,

    // FIFO signals
    input wire rst_busy,                // When FIFO is being reset, can take up to 60 clock cycles to clear buffer, so wait until busy flag unasserted when resetting
    input wire fifo_full,               // When FIFO is full
    input wire M_AXIS_TREADY,           // FIFO Signal that it is ready to accept data
    output wire [31:0] M_AXIS_TDATA,    // FIFO write data (AXIS)
    output wire M_AXIS_TVALID,          // FIFO write data valid (AXIS)
    
    // LP control unit signals
    input wire [31:0] addr_offset,      // Can be either from DDR or BRAM
    input wire [15:0] num_elements,     // Should be equal to number of rows
    input wire [15:0] stride,           // Should be equal to number of cols
    input wire start,
    output wire busy,                   // Busy signal - asserted for as long as writing one row to FIFO takes, deasserted when doing nothing
    output wire done,                   // Done signal - asserted for one clock cycle after FIFO is done with an operation
    
    // AXI4 MASTER SIGNALS going to MIG
    output wire [1:0] M_AXI_ARID,       //DONE
    output wire [31:0] M_AXI_ARADDR,    //DONE
    output wire [7:0] M_AXI_ARLEN,      //DONE - ALWAYS FETCH ONE DATA ELEMENT AT A TIME
    output wire [2:0] M_AXI_ARSIZE,     //DONE
    output wire [1:0] M_AXI_ARBURST,    //DONE - INCR BURST TYPE
    output wire M_AXI_ARLOCK,           //DONE
    output wire [3:0] M_AXI_ARCACHE,    //DONE
    output wire [2:0] M_AXI_ARPROT,     //DONE
    output wire [3:0] M_AXI_ARQOS,      //DONE
    output wire M_AXI_ARVALID,
    input wire M_AXI_ARREADY,
    
    output wire M_AXI_RREADY,           
    input wire [1:0] M_AXI_RID,         // DON'T CARE
    input wire [31:0] M_AXI_RDATA,
    input wire [1:0] M_AXI_RRESP,       // DON'T CARE
    input wire M_AXI_RLAST,
    input wire M_AXI_RVALID
);
    // Assign non-changing AXI master signals
    assign M_AXI_ARID = 'b0;
    assign M_AXI_ARSIZE = 3'b010;       // Address is always a 2^2 = 4 byte = 32-bit signal
    assign M_AXI_ARLOCK = 1'b0;
    assign M_AXI_ARCACHE = 4'b0010;
    assign M_AXI_ARPROT = 3'h0;
    assign M_AXI_ARQOS = 4'h0;
    assign M_AXI_ARBURST = 2'b01;       // Must be INCR in order for SmartConnect not to crash
    assign M_AXI_ARLEN = 8'h00;         // Always fetch 0 + 1 = 1 elements at a time

    // Declare AXI, FIFO, and LP FSM reg signals
    reg [31:0] fsm_axis_tdata;
    reg fsm_axis_tvalid;
    
    reg fsm_busy;
    reg fsm_done;
    
    reg [31:0] fsm_axi_araddr;
    reg fsm_axi_arvalid;
    reg fsm_axi_rready;

    // IO assignment: FIFO (AXIS), LP, and AXI signals
    assign M_AXIS_TDATA = fsm_axis_tdata;
    assign M_AXIS_TVALID = fsm_axis_tvalid;
    
    assign busy = fsm_busy;
    assign done = fsm_done;
    
    assign M_AXI_ARADDR = fsm_axi_araddr;
    assign M_AXI_ARVALID = fsm_axi_arvalid;
    assign M_AXI_RREADY = fsm_axi_rready;

    // Logic start
    reg [15:0] element_counter;
  
    // States definitions
    parameter S0 = 'd0;
    parameter S1_COL = 'd1, 
              S2_COL = 'd2, 
              S3_COL = 'd3, 
              S4_COL = 'd4, 
              S5_COL = 'd5,
              S6_COL = 'd6;

    reg [5:0] current_state;

    // Next state comb logic
    always @ (posedge aclk) begin
        // Reset asserted
        if (aresetn == 1'b0) begin
            current_state <= S0;
            
            // Reset all signals
            element_counter <= 16'b0;
            
            fsm_axis_tdata <= 32'b0;
            fsm_axis_tvalid <= 1'b0;
            
            fsm_busy <= 1'b0;
            fsm_done <= 1'b0;
            
            fsm_axi_araddr <= 32'b0;
            fsm_axi_arvalid <= 1'b0;
            fsm_axi_rready <= 1'b0;
        end
        
        // If FIFO is resetting itself, FSM waits
        else if (rst_busy) begin
            current_state <= current_state;
        end

        // FSM Code
        else begin
            // Determine next state based on current state and assert outputs
            case (current_state)
                S0: begin
                    // Wait on START signal, on which we assert busy flag then go to FIFO wait stage
                    fsm_done <= 1'b0;       // Clear done signal from final state
                    
                    if (start == 1'b1) begin
                        fsm_busy <= 1'b1;
                        current_state <= S1_COL;
                    end
                    else current_state <= S0;
                end
                
                /***************** COL INDEXING STATES BELOW ********************/
                
                S1_COL: begin
                    // Set ARADDR & ARLEN to the correct incremented amount - increment by 4 bytes (next 32-bits)
                    fsm_axi_araddr <= addr_offset + (stride * (element_counter << 'd2));

                    // Assert ARVALID and wait for ARREADY
                    fsm_axi_arvalid <= 1'b1;
                    current_state <= S2_COL;
                end
                
                S2_COL: begin
                    // Wait for ARREADY from memory. Then assert RREADY, deassert ARVALID and wait for RVALID
                    if (M_AXI_ARREADY == 1'b1) begin
                        current_state <= S3_COL;
                        
                        fsm_axi_arvalid <= 1'b0;
                        fsm_axi_rready <= 1'b1;
                    end
                    else current_state <= S2_COL;
                end
                
                S3_COL: begin
                    // Wait for RVALID from memory and then go to write data that you just read to FIFO
                    if (M_AXI_RVALID == 1'b1) begin
                        current_state <= S4_COL;                           // RLAST element
                        
                        fsm_axis_tdata <= M_AXI_RDATA;      // Set AXIS TDATA and then wait for FIFO to free up
                        
                        fsm_axi_rready <= 1'b0;
                    end
                    else current_state <= S3_COL;
                end

                S4_COL: begin
                    // Wait till FIFO not full, assert TVALID and then wait for TREADY
                    if (fifo_full == 1'b0) begin
                        current_state <= S5_COL;
                        
                        fsm_axis_tvalid <= 1'b1;
                    end
                    else current_state <= S4_COL;
                end

                S5_COL: begin
                    // Wait till FIFO asserts TREADY (and is not full) to accept the write.
                    // Then increment counter, and check if this RLAST is the last in the entire read sequence
                    if (M_AXIS_TREADY == 1'b1) begin
                        current_state <= S6_COL;
                        
                        // Deassert TVALID
                        fsm_axis_tvalid <= 1'b0;
                        
                        element_counter <= element_counter + 1'b1;
                    end
                    else current_state <= S5_COL;
                end

                S6_COL: begin
                    // Check if counter == num_elements (means we are done)
                    // If we are done, assert done, reset all signals and go back to waiting on START
                    // Otherwise, go back to setting the ARADDR and reading next entry
                    if (element_counter == num_elements) begin
                        // Reset all signals
                        element_counter <= 16'b0;
                        
                        fsm_busy <= 1'b0;
                        fsm_done <= 1'b1;
                        
                        fsm_axis_tdata <= 32'b0;
                        fsm_axis_tvalid <= 1'b0;
                        
                        fsm_axi_araddr <= 32'b0;
                        fsm_axi_arvalid <= 1'b0;
                        fsm_axi_rready <= 1'b0;
                        
                        // Go back to waiting on START
                        current_state <= S0;
                    end
                    
                    else begin
                        current_state <= S1_COL;
                    end
                end
                
                // If we ever land here for some reason, reset current state and all signals
                default: begin
                    current_state <= S0;
                
                    // Reset all signals
                    element_counter <= 16'b0;
                        
                    fsm_busy <= 1'b0;
                    fsm_done <= 1'b0;
                    
                    fsm_axis_tdata <= 32'b0;
                    fsm_axis_tvalid <= 1'b0;
                    
                    fsm_axi_araddr <= 32'b0;
                    fsm_axi_arvalid <= 1'b0;
                    fsm_axi_rready <= 1'b0;
                end
            endcase
        end
    end
endmodule