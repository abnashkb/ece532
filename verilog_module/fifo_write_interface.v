`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2024 03:28:26 PM
// Design Name: 
// Module Name: fifo_write_interface
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


module fifo_write_interface #(parameter NUM_ELEMENTS_WIDTH = 16) (
        // Clock and reset
		input wire  aclk,
		input wire  aresetn,
		
		// FIFO signals
		input wire rst_busy,
		input wire fifo_empty,
		output wire S_AXIS_TREADY,
		input wire [31:0] S_AXIS_TDATA,
		input wire S_AXIS_TVALID,
		
		// Control signals
		input wire [31:0] addr_offset,
		input wire [NUM_ELEMENTS_WIDTH - 1:0] num_elements,
		input wire start,
		output wire busy,                     // Asserted to 1 if we are performing a transaction, asserted to 0 if we are waiting to start a transaction
		output wire done,                     // Asserted for one clock cycle once we are done with a transaction
		
		// AXI Master Write Channels - for BRAM or MIG
		output wire [1:0] M_AXI_AWID,         // DONE
		output wire [31:0] M_AXI_AWADDR,      // ASSIGNED BY FSM
		output wire [7:0] M_AXI_AWLEN,        // ASSIGNED BY FSM
		output wire [2:0] M_AXI_AWSIZE,       // DONE
		output wire [1:0] M_AXI_AWBURST,      // DONE
		output wire  M_AXI_AWLOCK,            // DONE
		output wire [3:0] M_AXI_AWCACHE,      // DONE
		output wire [2:0] M_AXI_AWPROT,       // DONE
		output wire [3:0] M_AXI_AWQOS,        // DONE
		output wire  M_AXI_AWVALID,           // ASSIGNED BY FSM
		input wire  M_AXI_AWREADY,
		
		output wire [31:0] M_AXI_WDATA,       // ASSIGNED BY FSM
		output wire [3:0] M_AXI_WSTRB,        // DONE
		output wire  M_AXI_WLAST,             // ASSIGNED BY FSM
		output wire  M_AXI_WVALID,            // ASSIGNED BY FSM
		input wire  M_AXI_WREADY,
		
		input wire [1:0] M_AXI_BID,
		input wire [1:0] M_AXI_BRESP,
		input wire  M_AXI_BVALID,
		output wire  M_AXI_BREADY             // ASSIGNED BY FSM
    );
    
    // Trivial AXI Signal Assignment
    assign M_AXI_AWID = 2'b0;
    assign M_AXI_AWSIZE = 3'b010;       // Address is always a 2^2 = 4 byte = 32-bit signal
    assign M_AXI_AWBURST = 2'b01;       // Burst type: INCR
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0010;
    assign M_AXI_AWPROT = 3'h0;
    assign M_AXI_AWQOS = 4'h0;
    
    assign M_AXI_WSTRB = 4'hF;          // All 4-bytes in data are valid 
    
    // Declare AXI, FIFO, and Control reg signals for FSM
    reg [31:0] fsm_axi_awaddr;
    reg [7:0] fsm_axi_awlen;
    reg fsm_axi_awvalid;
    
    reg [31:0] fsm_axi_wdata;
    reg fsm_axi_wlast;
    reg fsm_axi_wvalid;
    
    reg fsm_axi_bready;
    
    reg fsm_axis_tready;
    
    reg fsm_busy;
    reg fsm_done;
    
    // IO assignment: AXI, FIFO, and Control signals
    assign M_AXI_AWADDR = fsm_axi_awaddr;
    assign M_AXI_AWLEN = fsm_axi_awlen;
    assign M_AXI_AWVALID = fsm_axi_awvalid;
    assign M_AXI_WDATA = fsm_axi_wdata;
    assign M_AXI_WLAST = fsm_axi_wlast;
    assign M_AXI_WVALID = fsm_axi_wvalid;
    assign M_AXI_BREADY = fsm_axi_bready;
    
    assign S_AXIS_TREADY = fsm_axis_tready;
    
    assign busy = fsm_busy;
    assign done = fsm_done;
    
    // Internal logic and FSM states
    reg [NUM_ELEMENTS_WIDTH - 1:0] element_counter;         // Keeps track of how many elements we have sent in total
    reg [7:0] burst_element_counter;                        // Keeps track of how many elements we have sent in a burst transaction so far
    reg [5:0] current_state;
    
    localparam S0 = 'd0, 
              S1 = 'd1, 
              S2 = 'd2, 
              S3 = 'd3, 
              S4_LAST = 'd4,
              S4_NOT_LAST = 'd5,
              S5_LAST = 'd6,
              S6 = 'd8;
    
    // FSM logic
    always @ (posedge aclk) begin
        // Reset asserted
        if (aresetn == 1'b0) begin
            current_state <= S0;
            
            // Reset all signals
            element_counter <= 'b0;
            burst_element_counter <= 8'b0;
            
            fsm_axi_awaddr <= 32'b0;
            fsm_axi_awlen <= 8'b0;
            fsm_axi_awvalid <= 1'b0;
            fsm_axi_wdata <= 32'b0;
            fsm_axi_wlast <= 1'b0;
            fsm_axi_wvalid <= 1'b0;
            fsm_axi_bready <= 1'b0;
            
            fsm_axis_tready <= 1'b0;
            
            fsm_busy <= 1'b0;
            fsm_done <= 1'b0;
        end
        
        // If FIFO is resetting itself, FSM waits
        else if (rst_busy) current_state <= current_state;
        
        // Next state logic
        else begin
            case (current_state)
                S0: begin
                    // Wait on START signal, on which we assert busy flag then go to AWADDR setting
                    fsm_done <= 1'b0;       // Deassert done signal from final state
                    
                    if (start == 1'b1) begin
                        fsm_busy <= 1'b1;
                        current_state <= S1;
                    end
                    else current_state <= S0;
                end
                
                S1: begin
                    // Set AWADDR and AWLEN to the correct incremented amount - increment by 4 bytes (next 32-bits)
                    fsm_axi_awaddr <= addr_offset + (element_counter << 'd2);
                    fsm_axi_awlen <= (num_elements - element_counter < 256) ? (num_elements[7:0] - element_counter[7:0] - 1) : 8'b1111_1111; // If number of remaining elements to get is >= 256, then full burst (max of 256 beats per burst), otherwise, specify just the remaining elements
                    burst_element_counter <= 8'b0;  // Also need to reset the burst counter
                
                    // Assert AWVALID and wait for AWREADY
                    fsm_axi_awvalid <= 1'b1;
                    current_state <= S2;
                end
                
                S2: begin
                    // Wait for AWREADY from memory. Then deassert AWVALID, assert BREADY, and check FIFO status (i.e. if not empty)
                    // Also assert TREADY for FIFO to indicate we are ready to receive data
                    if (M_AXI_AWREADY == 1'b1) begin
                        current_state <= S3;
                        
                        fsm_axi_awvalid <= 1'b0;
                        fsm_axi_bready <= 1'b1;
                        
                        fsm_axis_tready <= 1'b1;
                    end
                    else current_state <= S2;
                end
                
                S3: begin
                    // Check if FIFO data is TVALID, then set WDATA, WVALID, deassert TREADY, and check if we're going to be sending WLAST
                    // TODO: see if this approach is good enough or if empty signal is actually needed
                    if (S_AXIS_TVALID == 1'b1) begin
                        fsm_axi_wdata <= S_AXIS_TDATA;
                        fsm_axi_wvalid <= 1'b1;
                        
                        fsm_axis_tready <= 1'b0;
                        
                        // We reached WLAST
                        if (burst_element_counter == fsm_axi_awlen) begin
                            fsm_axi_wlast <= 1'b1;
                            current_state <= S4_LAST;
                        end
                        else current_state <= S4_NOT_LAST;
                    end
                    else current_state <= S3;
                end
                
                S4_LAST: begin
                    // Wait for WREADY, and on WREADY, deassert WLAST and WVALID and increment both counters
                    if (M_AXI_WREADY == 1'b1) begin
                        current_state <= S5_LAST;
                        
                        // Deassert WLAST and WVALID
                        fsm_axi_wlast <= 1'b0;
                        fsm_axi_wvalid <= 1'b0;
                        
                        // Increment counters
                        element_counter <= element_counter + 1'b1;
                        burst_element_counter <= burst_element_counter + 1'b1;
                    end
                    else current_state <= S4_LAST;
                end
                
                S4_NOT_LAST: begin
                    // Wait for WREADY, and on WREADY, deassert WVALID, increment both counters, assert TREADY (for FIFO)
                    // and go back to reading more data from FIFO
                    if (M_AXI_WREADY == 1'b1) begin
                        current_state <= S3;
                        
                        fsm_axi_wvalid <= 1'b0;
                        
                        fsm_axis_tready <= 1'b1;
                        
                        // Increment counters
                        element_counter <= element_counter + 1'b1;
                        burst_element_counter <= burst_element_counter + 1'b1;
                    end
                    else current_state <= S4_NOT_LAST;
                end
                
                S5_LAST: begin
                    // Wait for BVALID, and on BVALID, deassert BREADY and then proceed to check if we are done with the entire transaction
                    if (M_AXI_BVALID == 1'b1) begin
                        fsm_axi_bready <= 1'b0;
                        
                        current_state <= S6;
                    end
                    else current_state <= S5_LAST;
                end
                
                S6: begin
                    // Check if counter == num_elements (means we are done)
                    // If done, assert done, reset all signals and go back to waiting on START
                    // Otherwise, go back to setting AWADDR and writing next burst
                    if (element_counter == num_elements) begin
                        // Reset all signals
                        element_counter <= 'b0;
                        burst_element_counter <= 8'b0;
                        
                        fsm_axi_awaddr <= 32'b0;
                        fsm_axi_awlen <= 8'b0;
                        fsm_axi_awvalid <= 1'b0;
                        fsm_axi_wdata <= 32'b0;
                        fsm_axi_wlast <= 1'b0;
                        fsm_axi_wvalid <= 1'b0;
                        fsm_axi_bready <= 1'b0;
                        
                        fsm_axis_tready <= 1'b0;
                        
                        fsm_busy <= 1'b0;
                        fsm_done <= 1'b1;
                        
                        // Go back to waiting on START
                        current_state <= S0;
                    end
                    else current_state <= S1;
                end
                
                default: begin
                    current_state <= S0;
                    
                    // Reset all signals
                    element_counter <= 'b0;
                    burst_element_counter <= 8'b0;
                    
                    fsm_axi_awaddr <= 32'b0;
                    fsm_axi_awlen <= 8'b0;
                    fsm_axi_awvalid <= 1'b0;
                    fsm_axi_wdata <= 32'b0;
                    fsm_axi_wlast <= 1'b0;
                    fsm_axi_wvalid <= 1'b0;
                    fsm_axi_bready <= 1'b0;
                    
                    fsm_axis_tready <= 1'b0;
                    
                    fsm_busy <= 1'b0;
                    fsm_done <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
