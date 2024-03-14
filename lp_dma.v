`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ECE532 Group 1: LP Solver on an FPGA
//
// Create Date: 03/10/2024 05:49:16 PM
// Design Name: LP Subsytem DMA
// Module Name: lp_dma
// Target Devices: Nexys4 Video
//////////////////////////////////////////////////////////////////////////////////

module lp_dma(
    // Inputs
    input aclk,
    input aresetn,
    input [31:0] ddr_base_addr,
    input [31:0] bram_base_addr,
    input [15:0] stride,
    input fetch_start,
    input [15:0] num_rows,

    // AXI4 MASTER SIGNALS going to MIG
    output wire [1:0] M_AXI_ARID,       //DONE
    output wire [31:0] M_AXI_ARADDR,    //DONE
    output wire [7:0] M_AXI_ARLEN,      //DONE
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
    input wire M_AXI_RVALID,

    // AXI Master Write Channels - for BRAM
    output wire [1:0] BRAM_M_AXI_AWID,         // DONE
    output wire [31:0] BRAM_M_AXI_AWADDR,      // ASSIGNED BY FSM
    output wire [7:0] BRAM_M_AXI_AWLEN,        // ASSIGNED BY FSM
    output wire [2:0] BRAM_M_AXI_AWSIZE,       // DONE
    output wire [1:0] BRAM_M_AXI_AWBURST,      // DONE
    output wire  BRAM_M_AXI_AWLOCK,            // DONE
    output wire [3:0] BRAM_M_AXI_AWCACHE,      // DONE
    output wire [2:0] BRAM_M_AXI_AWPROT,       // DONE
    output wire [3:0] BRAM_M_AXI_AWQOS,        // DONE
    output wire  BRAM_M_AXI_AWVALID,           // ASSIGNED BY FSM
    input wire  BRAM_M_AXI_AWREADY,

    output wire [31:0] BRAM_M_AXI_WDATA,       // ASSIGNED BY FSM
    output wire [3:0] BRAM_M_AXI_WSTRB,        // DONE
    output wire  BRAM_M_AXI_WLAST,             // ASSIGNED BY FSM
    output wire  BRAM_M_AXI_WVALID,            // ASSIGNED BY FSM
    input wire  BRAM_M_AXI_WREADY,

    input wire [1:0] BRAM_M_AXI_BID,
    input wire [1:0] BRAM_M_AXI_BRESP,
    input wire  BRAM_M_AXI_BVALID,
    output wire  BRAM_M_AXI_BREADY             // ASSIGNED BY FSM
  );

  // Assign non-changing AXI master signals
  assign M_AXI_ARID = 'b0;
  assign M_AXI_ARSIZE = 3'b010;       // Address is always a 2^2 = 4 byte = 32-bit signal
  assign M_AXI_ARLOCK = 1'b0;
  assign M_AXI_ARCACHE = 4'b0010;
  assign M_AXI_ARPROT = 3'h0;
  assign M_AXI_ARQOS = 4'h0;
  assign M_AXI_ARBURST = 2'b01;       // If reading col --> FIXED (i.e. address stays same), row --> INCR

  // Trivial AXI Signal Assignment
  assign BRAM_M_AXI_AWID = 2'b0;
  assign BRAM_M_AXI_AWSIZE = 3'b010;       // Address is always a 2^2 = 4 byte = 32-bit signal
  assign BRAM_M_AXI_AWBURST = 2'b01;       // Burst type: INCR
  assign BRAM_M_AXI_AWLOCK = 1'b0;
  assign BRAM_M_AXI_AWCACHE = 4'b0010;
  assign BRAM_M_AXI_AWPROT = 3'h0;
  assign BRAM_M_AXI_AWQOS = 4'h0;

  assign BRAM_M_AXI_WSTRB = 4'hF;          // All 4-bytes in data are valid

  // Declare AXI, FIFO, and LP FSM reg signals

  reg fsm_busy;
  reg fsm_done;

  reg [31:0] fsm_axi_araddr;
  reg fsm_axi_arvalid;
  reg fsm_axi_rready;
  reg [7:0] fsm_axi_arlen;

  reg [31:0] fsm_axi_awaddr;
  reg [7:0] fsm_axi_awlen;
  reg fsm_axi_awvalid;

  reg [31:0] fsm_axi_wdata;
  reg fsm_axi_wlast;
  reg fsm_axi_wvalid;

  reg fsm_axi_bready;

  // IO assignment: FIFO (AXIS), LP, and AXI signals
  assign busy = fsm_busy;
  assign done = fsm_done;

  assign M_AXI_ARADDR = fsm_axi_araddr;
  assign M_AXI_ARVALID = fsm_axi_arvalid;
  assign M_AXI_RREADY = fsm_axi_rready;
  assign M_AXI_ARLEN = fsm_axi_arlen;

  // IO assignment: AXI, FIFO, and Control signals
  assign BRAM_M_AXI_AWADDR = fsm_axi_awaddr;
  assign BRAM_M_AXI_AWLEN = fsm_axi_awlen;
  assign BRAM_M_AXI_AWVALID = fsm_axi_awvalid;
  assign BRAM_M_AXI_WDATA = fsm_axi_wdata;
  assign BRAM_M_AXI_WLAST = fsm_axi_wlast;
  assign BRAM_M_AXI_WVALID = fsm_axi_wvalid;
  assign BRAM_M_AXI_BREADY = fsm_axi_bready;

  // Logic start
  reg [15:0] element_counter;
  reg [7:0] burst_element_counter;                        // Keeps track of how many elements we have sent in a burst transaction so far
  reg [15:0] write_element_counter;   // Keeps track of how many elements we have sent in total
  reg [31:0] write_buffer[0:255];     // Buffer to store the data to be written to BRAM
  reg [7:0] write_buffer_counter;      // Counter to keep track of how many elements are in the buffer

  // States definitions
  parameter S0 = 'd0;
  parameter S1_ROW = 'd1,
            S2_ROW = 'd2,
            S3_ROW = 'd3,
            S4_ROW_LAST = 'd4,
            S4_ROW_NOT_LAST = 'd5,
            S5_ROW_LAST = 'd6,
            S5_ROW_NOT_LAST = 'd7,
            S6_ROW = 'd8,
            BUFFER_WRITE_1 = 'd9,
            BUFFER_WRITE_2 = 'd10,
            BUFFER_WRITE_3 = 'd11,
            BUFFER_WRITE_4 = 'd12,
            BUFFER_WRITE_5 = 'd13;

  reg [5:0] current_state;
  reg [5:0] jump_state; // For buffer write to avoid duplicated states

  // Next state comb logic
  always @ (posedge aclk)
  begin
    // Reset asserted
    if (aresetn == 1'b0)
    begin
      current_state <= S0;

      // Reset all signals
      element_counter <= 16'b0;
      burst_element_counter <= 8'b0;
      write_element_counter <= 16'b0;
      write_buffer_counter <= 8'b0;

      fsm_busy <= 1'b0;
      fsm_done <= 1'b0;

      fsm_axi_araddr <= 32'b0;
      fsm_axi_arvalid <= 1'b0;
      fsm_axi_rready <= 1'b0;
      fsm_axi_arlen <= 8'b0;

      fsm_axi_awaddr <= 32'b0;
      fsm_axi_awlen <= 8'b0;
      fsm_axi_awvalid <= 1'b0;
      fsm_axi_wdata <= 32'b0;
      fsm_axi_wlast <= 1'b0;
      fsm_axi_wvalid <= 1'b0;
      fsm_axi_bready <= 1'b0;
    end

    // FSM Code
    else
    begin
      // Determine next state based on current state and assert outputs
      case (current_state)
        S0:
        begin
          // Wait on START signal, on which we assert busy flag
          fsm_done <= 1'b0;       // Clear done signal from final state

          if (fetch_start == 1'b1)
          begin
            fsm_busy <= 1'b1;
            current_state <= S1_ROW;
          end
          else
            current_state <= S0;
        end

        S1_ROW:
        begin
          // Calculate address for the current element based on base address, stride, and element counter
          // Stride is in bytes, so we multiply by 4 to get the actual stride
          fsm_axi_araddr <= ddr_base_addr + (element_counter * (4 * stride));
          fsm_axi_arlen <= 0; // Only fetching one element at a time due to stride

          // Assert ARVALID and wait for ARREADY
          fsm_axi_arvalid <= 1'b1;
          current_state <= S2_ROW;
        end

        S2_ROW:
        begin
          // Wait for ARREADY from memory. Then assert RREADY, deassert ARVALID and wait for RVALID
          if (M_AXI_ARREADY == 1'b1)
          begin
            current_state <= S3_ROW;

            fsm_axi_arvalid <= 1'b0;
            fsm_axi_rready <= 1'b1;
          end
          else
            current_state <= S2_ROW;
        end

        S3_ROW:
        begin
          // Wait for RVALID from memory and then go to write data that you just read to the temp burst buffer
          if (M_AXI_RVALID == 1'b1)
          begin
            if (M_AXI_RLAST == 1'b0)
              current_state <= S4_ROW_NOT_LAST;   // Not RLAST
            else
              current_state <= S4_ROW_LAST;                           // RLAST element

            write_buffer[write_buffer_counter] <= M_AXI_RDATA;
            write_buffer_counter <= write_buffer_counter + 1'b1;

            fsm_axi_rready <= 1'b0;
          end
          else
            current_state <= S3_ROW;
        end

        S4_ROW_NOT_LAST:
        begin
          // Check if the buffer is full.
          if (write_buffer_counter == 255)
          begin
            // If buffer is full, write the buffer to BRAM
            current_state <= BUFFER_WRITE_1;
            jump_state <= S5_ROW_NOT_LAST;
          end
          else
            current_state <= S5_ROW_NOT_LAST;
        end

        S4_ROW_LAST:
        begin
          // Here, we just need to empty the buffer and write whatever is left to BRAM
          current_state <= BUFFER_WRITE_1;
          jump_state <= S5_ROW_LAST;
        end

        BUFFER_WRITE_1:
        begin
          // // Set AWADDR and AWLEN to the correct incremented amount - increment by 4 bytes (next 32-bits)
          fsm_axi_awaddr <= bram_base_addr + (write_element_counter << 'd2);
          fsm_axi_awlen <= write_buffer_counter;
          burst_element_counter <= 8'b0;  // Also need to reset the burst counter and write buffer counter
          write_buffer_counter <= 8'b0;

          fsm_axi_awvalid <= 1'b1;
          current_state <= BUFFER_WRITE_2;
        end

        BUFFER_WRITE_2:
        begin
          // Wait for AWREADY from memory. Then assert WVALID, deassert AWVALID and wait for BVALID
          if (BRAM_M_AXI_AWREADY == 1'b1)
          begin
            current_state <= BUFFER_WRITE_3;
            fsm_axi_awvalid <= 1'b0;
            fsm_axi_bready <= 1'b1;
          end
          else
            current_state <= BUFFER_WRITE_2;
        end

        BUFFER_WRITE_3:
        begin
          current_state <= BUFFER_WRITE_4;
          fsm_axi_wdata <= write_buffer[burst_element_counter];
          fsm_axi_wvalid <= 1'b1;
          fsm_axi_wlast <= (burst_element_counter == fsm_axi_awlen) ? 1'b1 : 1'b0; // If we are on the last beat of the burst, assert WLAST
        end

        BUFFER_WRITE_4:
        begin
          if (BRAM_M_AXI_WREADY == 1'b1)
          begin
            // Deassert wlast and wvalid
            // Check if we are done writing the buffer and loop back if not
            current_state <= (fsm_axi_wlast) ? BUFFER_WRITE_3 : BUFFER_WRITE_5;
            fsm_axi_wvalid <= 1'b0;
            fsm_axi_wlast <= 1'b0;
            // Increment write and burst counters
            write_element_counter <= write_element_counter + 1'b1;
            burst_element_counter <= burst_element_counter + 1'b1;
          end
          else
            current_state <= BUFFER_WRITE_4;
        end

        BUFFER_WRITE_5:
        begin
          // Wait for BVALID, and on BVALID, deassert BREADY
          if (BRAM_M_AXI_BVALID == 1'b1)
          begin
            fsm_axi_bready <= 1'b0;
            // Zero out the write buffer
            for (int i = 0; i < 256; i = i + 1)
              write_buffer[i] <= 32'b0;
            // Jump to the jump_state
            current_state <= jump_state;
          end
          else
            current_state <= BUFFER_WRITE_5;
        end

        S5_ROW_NOT_LAST:
        begin
          current_state <= S3_ROW;
          fsm_axi_rready <= 1'b1;
          element_counter <= element_counter + 1'b1;
        end

        S5_ROW_LAST:
        begin
          current_state <= S6_ROW;
          element_counter <= element_counter + 1'b1;
        end

        S6_ROW:
        begin
          // Check if counter == num_rows (means we are done)
          // If we are done, assert done, reset all signals and go back to waiting on START
          // Otherwise, go back to setting the ARADDR and reading next entry
          if (element_counter == num_rows)
          begin
            // Reset all signals
            element_counter <= 16'b0;

            fsm_busy <= 1'b0;
            fsm_done <= 1'b1;

            fsm_axi_araddr <= 32'b0;
            fsm_axi_arvalid <= 1'b0;
            fsm_axi_rready <= 1'b0;
            fsm_axi_arlen <= 8'b0;

            fsm_axi_awaddr <= 32'b0;
            fsm_axi_awlen <= 8'b0;
            fsm_axi_awvalid <= 1'b0;
            fsm_axi_wdata <= 32'b0;
            fsm_axi_wlast <= 1'b0;
            fsm_axi_wvalid <= 1'b0;
            fsm_axi_bready <= 1'b0;

            // Go back to waiting on START
            current_state <= S0;
          end

          else
          begin
            current_state <= S1_ROW;
          end
        end

        // If we ever land here for some reason, reset current state and all signals
        default:
        begin
          current_state <= S0;

          // Reset all signals
          element_counter <= 16'b0;
          burst_element_counter <= 8'b0;
          write_element_counter <= 16'b0;
          write_buffer_counter <= 8'b0;

          fsm_busy <= 1'b0;
          fsm_done <= 1'b0;

          fsm_axi_araddr <= 32'b0;
          fsm_axi_arvalid <= 1'b0;
          fsm_axi_rready <= 1'b0;
          fsm_axi_arlen <= 8'b0;
        end
      endcase
    end
  end



endmodule
