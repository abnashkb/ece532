`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2024 12:27:18 PM
// Design Name: 
// Module Name: fifo_read_interface
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


module fifo_read_interface #(parameter NUM_ELEMENTS_WIDTH = 16) (
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
    input wire [NUM_ELEMENTS_WIDTH - 1:0] num_elements,
    input wire start,
    output wire busy,                   // Busy signal - asserted for as long as writing one row to FIFO takes, deasserted when doing nothing
    output wire done,                   // Done signal - asserted for one clock cycle after FIFO is done with an operation
    
    // AXI4 MASTER SIGNALS going to MIG
    output wire [1:0] M_AXI_ARID,       //DONE
    output wire [31:0] M_AXI_ARADDR,    //DONE
    output wire [7:0] M_AXI_ARLEN,      //DONE - NON_TRIVIAL: SET BY FSM BY CALCULATING DATA REMAINING TO FETCH
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
    assign M_AXI_ARBURST = 2'b01;       // If reading col --> FIXED (i.e. address stays same), row --> INCR
    
    // Declare AXI, FIFO, and LP FSM reg signals
    reg [31:0] fsm_axis_tdata;
    reg fsm_axis_tvalid;
    
    reg fsm_busy;
    reg fsm_done;
    
    reg [31:0] fsm_axi_araddr;
    reg fsm_axi_arvalid;
    reg fsm_axi_rready;
    reg [7:0] fsm_axi_arlen;
    
    // IO assignment: FIFO (AXIS), LP, and AXI signals
    assign M_AXIS_TDATA = fsm_axis_tdata;
    assign M_AXIS_TVALID = fsm_axis_tvalid;
    
    assign busy = fsm_busy;
    assign done = fsm_done;
    
    assign M_AXI_ARADDR = fsm_axi_araddr;
    assign M_AXI_ARVALID = fsm_axi_arvalid;
    assign M_AXI_RREADY = fsm_axi_rready;
    assign M_AXI_ARLEN = fsm_axi_arlen;
    
    // Logic start
    reg [NUM_ELEMENTS_WIDTH - 1:0] element_counter;
  
    // States definitions
    parameter S0 = 'd0;
    parameter S1_ROW = 'd1, 
              S2_ROW = 'd2, 
              S3_ROW = 'd3, 
              S4_ROW_LAST = 'd4, 
              S4_ROW_NOT_LAST = 'd5, 
              S5_ROW_LAST = 'd6, 
              S5_ROW_NOT_LAST = 'd7, 
              S6_ROW = 'd8;
    
    reg [5:0] current_state;
    
    // Next state comb logic
    always @ (posedge aclk) begin
        // Reset asserted
        if (aresetn == 1'b0) begin
            current_state <= S0;
            
            // Reset all signals
            element_counter <= 'b0;
            
            fsm_axis_tdata <= 32'b0;
            fsm_axis_tvalid <= 1'b0;
            
            fsm_busy <= 1'b0;
            fsm_done <= 1'b0;
            
            fsm_axi_araddr <= 32'b0;
            fsm_axi_arvalid <= 1'b0;
            fsm_axi_rready <= 1'b0;
            fsm_axi_arlen <= 8'b0;
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
                        current_state <= S1_ROW;
                    end
                    else current_state <= S0;
                end
                
                /***************** ROW INDEXING STATES BELOW ********************/
                
                S1_ROW: begin
                    // Set ARADDR & ARLEN to the correct incremented amount - increment by 4 bytes (next 32-bits)
                    fsm_axi_araddr <= addr_offset + (element_counter << 'd2);
                    fsm_axi_arlen <= (num_elements - element_counter < 256) ? (num_elements[7:0] - element_counter[7:0] - 1) : 8'b1111_1111;    // If number of remaining elements to get is >= 256, then full burst (max of 256 beats per burst), otherwise, specify just the remaining elements
                    
                    // Assert ARVALID and wait for ARREADY
                    fsm_axi_arvalid <= 1'b1;
                    current_state <= S2_ROW;
                end
                
                S2_ROW: begin
                    // Wait for ARREADY from memory. Then assert RREADY, deassert ARVALID and wait for RVALID
                    if (M_AXI_ARREADY == 1'b1) begin
                        current_state <= S3_ROW;
                        
                        fsm_axi_arvalid <= 1'b0;
                        fsm_axi_rready <= 1'b1;
                    end
                    else current_state <= S2_ROW;
                end
                
                S3_ROW: begin
                    // Wait for RVALID from memory and then go to write data that you just read to FIFO
                    if (M_AXI_RVALID == 1'b1) begin
                        if (M_AXI_RLAST == 1'b0) current_state <= S4_ROW_NOT_LAST;   // Not RLAST
                        else current_state <= S4_ROW_LAST;                           // RLAST element
                        
                        fsm_axis_tdata <= M_AXI_RDATA;      // Set AXIS TDATA and then wait for FIFO to free up
                        
                        fsm_axi_rready <= 1'b0;
                    end
                    else current_state <= S3_ROW;
                end
                
                S4_ROW_NOT_LAST: begin
                    // Wait till FIFO not full, assert TVALID and then wait for TREADY
                    if (fifo_full == 1'b0) begin
                        current_state <= S5_ROW_NOT_LAST;
                        
                        fsm_axis_tvalid <= 1'b1;
                    end
                    else current_state <= S4_ROW_NOT_LAST;
                end
                
                S4_ROW_LAST: begin
                    // Wait till FIFO not full, assert TVALID and then wait for TREADY
                    if (fifo_full == 1'b0) begin
                        current_state <= S5_ROW_LAST;
                        
                        fsm_axis_tvalid <= 1'b1;
                    end
                    else current_state <= S4_ROW_LAST;
                end
                
                S5_ROW_NOT_LAST: begin
                    // Wait till FIFO asserts TREADY to accept the write.
                    // Then increment counter, enable RREADY, and go back to receive rest of BURST
                    if (M_AXIS_TREADY == 1'b1) begin
                        current_state <= S3_ROW;
                        
                        // Deassert TVALID
                        fsm_axis_tvalid <= 1'b0;
                        
                        fsm_axi_rready <= 1'b1;
                        element_counter <= element_counter + 1'b1;
                    end
                    else current_state <= S5_ROW_NOT_LAST;
                end
                
                S5_ROW_LAST: begin
                    // Wait till FIFO asserts TREADY (and is not full) to accept the write.
                    // Then increment counter, and check if this RLAST is the last in the entire read sequence
                    if (M_AXIS_TREADY == 1'b1) begin
                        current_state <= S6_ROW;
                        
                        // Deassert TVALID
                        fsm_axis_tvalid <= 1'b0;
                        
                        element_counter <= element_counter + 1'b1;
                    end
                    else current_state <= S5_ROW_LAST;
                end
                
                S6_ROW: begin
                    // Check if counter == num_elements (means we are done)
                    // If we are done, assert done, reset all signals and go back to waiting on START
                    // Otherwise, go back to setting the ARADDR and reading next entry
                    if (element_counter == num_elements) begin
                        // Reset all signals
                        element_counter <= 'b0;
                        
                        fsm_busy <= 1'b0;
                        fsm_done <= 1'b1;
                        
                        fsm_axis_tdata <= 32'b0;
                        fsm_axis_tvalid <= 1'b0;
                        
                        fsm_axi_araddr <= 32'b0;
                        fsm_axi_arvalid <= 1'b0;
                        fsm_axi_rready <= 1'b0;
                        fsm_axi_arlen <= 8'b0;
                        
                        // Go back to waiting on START
                        current_state <= S0;
                    end
                    
                    else begin
                        current_state <= S1_ROW;
                    end
                end
                
                // If we ever land here for some reason, reset current state and all signals
                default: begin
                    current_state <= S0;
                
                    // Reset all signals
                    element_counter <= 'b0;
                        
                    fsm_busy <= 1'b0;
                    fsm_done <= 1'b0;
                    
                    fsm_axis_tdata <= 32'b0;
                    fsm_axis_tvalid <= 1'b0;
                    
                    fsm_axi_araddr <= 32'b0;
                    fsm_axi_arvalid <= 1'b0;
                    fsm_axi_rready <= 1'b0;
                    fsm_axi_arlen <= 8'b0;
                end
            endcase
        end
    end
    
endmodule
