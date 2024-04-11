`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ECE532 Group 1: LP Solver on an FPGA
//
// Create Date: 02/20/2024 01:43:58 PM
// Design Name: LP Control Unit
// Module Name: lp_control_unit
// Target Devices: NexyPIVOT_ROW_CONTINUE Video
//////////////////////////////////////////////////////////////////////////////////


(* use_dsp = "yes" *) module lp_control_unit (
    // Inputs
    input aclk,
    input aresetn,
    input pivot_col_terminate,
    input pivot_row_terminate,
    input update_pivot_row_terminate,
    input update_tableau_terminate,
    input pivot_col_continue,
    input pivot_row_continue,
    input update_pivot_row_continue,
    input update_tableau_continue,
    input bridge_start,
    input [15:0] num_cols,
    input [31:0] ddr_start_addr,
    // Comes from find_pivot_col block (0 indexed)
    input [15:0] pivot_col_idx,
    // Comes from choose_pivot_row block (0 indexed AND starts at row after OBJ ROW)
    input [15:0] pivot_row_idx,
    input ddr_writeback_done,

    // Outputs
    output reg mblaze_done,
    // Active low, 1 cycle
    output reg pivot_col_start,
    // Active high, 1 cycle
    output reg pivot_col_fifo_start,
    // Address of pivot column with the objective row skipped
    output reg [31:0] pivot_col_addr_skip_OR,
    // Address of pivot column including objective row element
    output reg [31:0] pivot_col_addr,
    // Active low, 2 cycles
    output reg pivot_row_start,
    // Active high, 1 cycle
    output reg pivot_row_fifo_start,
    output reg [31:0] pivot_row_addr,
    // This is the index of the pivot row in the tableau where we start indexing at 1
    output reg [15:0] update_tableau_pivot_row_index,
    // Active low, 2 cycles
    output reg update_pivot_row_start,
    // Active high, 1 cycle
    output reg update_pivot_row_fifo_start,
    // Active low, 2 cycles
    output reg update_tableau_start,
    // Active high, for duration of block operation
    output reg update_tableau_busy,
    // Active high, 1 cycle
    output reg update_tableau_fifo_start
  );

  // Initialize states
  parameter START = 'd0,
            PIVOT_COL_TRANSIENT = 'd1,
            PIVOT_COL_CONTINUE = 'd2,
            PIVOT_ROW_TRANSIENT = 'd3,
            PIVOT_ROW_CONTINUE = 'd4,
            UPDATE_PIVOT_ROW_TRANSIENT = 'd5,
            UPDATE_PIVOT_ROW_CONTINUE = 'd6,
            UPDATE_TABLEAU_TRANSIENT = 'd7,
            UPDATE_TABLEAU_WRITEBACK = 'd8;

  reg [3:0] current_state;

  // Create reg to latch previous value of terminate
  reg previous_terminate;

  // Create intermediate value when resolving addresses to solve timing
  reg [31:0] skip_first_row_addr;

  // FSM code
  always @ (posedge aclk)
  begin
    // Register the previous value of terminate
    previous_terminate <= (pivot_col_terminate || pivot_row_terminate || update_pivot_row_terminate || update_tableau_terminate);

    if (aresetn == 1'b0)
    begin
      // Reset all signals
      reset_signals(0);
    end

    // If any terminate asserted, tell MBLAZE to send tableau back, reset all signals, and go back to waiting on MBLAZE start
    // We also need to check if we were in a terminate state before, so we don't send back MBLAZE done signal twice
    else if ((pivot_col_terminate || pivot_row_terminate || update_pivot_row_terminate || update_tableau_terminate) && (previous_terminate == 1'b0))
    begin
      // Send back MBLAZE done
      reset_signals(1);
    end

    // States
    else
    begin
      case (current_state)
        START:
          // Wait on MBLAZE signal, then start the pivot_col block. This is also the resultant state
          // from whenever terminates are asserted, so we should deassert the mblaze_done signal.
        begin
          mblaze_done <= 1'b0;

          // Monitor for MBLAZE start signal
          if (bridge_start == 1'b1)
          begin
            // Start pivot_col operation and go to next state
            current_state <= PIVOT_COL_TRANSIENT;
            // Active low, one cycle
            pivot_col_start <= 1'b0;
            // Active high, one cycle
            pivot_col_fifo_start <= 1'b1;
            // Resolve addr of the second row
            skip_first_row_addr <= ddr_start_addr + (num_cols << 2);
          end
          else
            // Stay in this state
            current_state <= START;
        end

        PIVOT_COL_TRANSIENT:
          // Deassert signals from before, and wait one clock cycle so that we allow pivot_col_cont
          // signal from before to settle to zero lest we erroneously sample it
        begin
          current_state <= PIVOT_COL_CONTINUE;
          pivot_col_start <= 1'b1;
          pivot_col_fifo_start <= 1'b0;
        end

        PIVOT_COL_CONTINUE:
          // Deassert signals from before, and wait until pivot_col block is done. On which, resolve
          // the pivot_col_addr & pivot_col_addr_skip_OR, and start pivot_row operation
        begin
          if (pivot_col_continue == 1'b1)
          begin
            // Start pivot row operation
            current_state <= PIVOT_ROW_TRANSIENT;
            // Address resolving
            pivot_col_addr_skip_OR <= skip_first_row_addr + (pivot_col_idx << 2);
            pivot_col_addr <= ddr_start_addr + (pivot_col_idx << 2);

            pivot_row_start <= 1'b0;
            pivot_row_fifo_start <= 1'b1;
          end
          else
            current_state <= PIVOT_COL_CONTINUE;
        end

        PIVOT_ROW_TRANSIENT:
          // Wait one more cycle for the negative pulse. However, deassert the fifo_start signal.
        begin
          current_state <= PIVOT_ROW_CONTINUE;
          pivot_row_fifo_start <= 1'b0;
        end

        PIVOT_ROW_CONTINUE:
          // Deassert signals from before, and wait until pivot_row block is done. On which,
          // resolve the pivot_row_addr & update_tableau_pivot_row_index, and start update_pivot_row operation
        begin
          pivot_row_start <= 1'b1;

          if (pivot_row_continue == 1'b1)
          begin
            // Start update_pivot_row operation
            current_state <= UPDATE_PIVOT_ROW_TRANSIENT;
            // Address resolving
            pivot_row_addr <= skip_first_row_addr + ((pivot_row_idx * num_cols) << 2);
            update_tableau_pivot_row_index <= pivot_row_idx + 2;

            update_pivot_row_start <= 1'b0;
            update_pivot_row_fifo_start <= 1'b1;
          end
          else
            current_state <= PIVOT_ROW_CONTINUE;
        end

        UPDATE_PIVOT_ROW_TRANSIENT:
          // Wait one more cycle for the negative pulse, However, deassert the fifo_start signal.
        begin
          current_state <= UPDATE_PIVOT_ROW_CONTINUE;
          update_pivot_row_fifo_start <= 1'b0;
        end

        UPDATE_PIVOT_ROW_CONTINUE:
          // Deassert signals from before, and wait until update_pivot_row is done. On which,
          // start the update_tableau_operation.
        begin
          update_pivot_row_start <= 1'b1;

          if (update_pivot_row_continue == 1'b1)
          begin
            // Start update_tableau_operation
            current_state <= UPDATE_TABLEAU_TRANSIENT;
            update_tableau_start <= 1'b0;
            // Busy signal for the tableau
            update_tableau_busy <= 1'b1;
            update_tableau_fifo_start <= 1'b1;
          end
          else
            current_state <= UPDATE_PIVOT_ROW_CONTINUE;
        end

        UPDATE_TABLEAU_TRANSIENT:
          // Wait one more cycle for the negative pulse. However, deassert the fifo_start signal.
        begin
          current_state <= UPDATE_TABLEAU_WRITEBACK;
          update_tableau_fifo_start <= 1'b0;
        end

        UPDATE_TABLEAU_WRITEBACK:
          // Deassert signals from before, and wait until update_tableau AND ddr_writeback are done
          // (unnecessary but should still work). On which, assert mblaze_done, and go back to START.
        begin
          update_tableau_start <= 1'b1;

          // Once we're done, busy is deasserted
          if (update_tableau_continue == 1'b1)
            update_tableau_busy <= 1'b0;

          // Once everything written back to DDR, go back to waiting on pivot column continue
          if ((update_tableau_continue == 1'b1) && (ddr_writeback_done == 1'b1))
          begin
            current_state <= PIVOT_COL_TRANSIENT;
            // Active low, one cycle
            pivot_col_start <= 1'b0;
            // Active high, one cycle
            pivot_col_fifo_start <= 1'b1;
          end
          else
            current_state <= UPDATE_TABLEAU_WRITEBACK;
        end

        default:
          // If we ever default, we should reset all signals and go back to initial state
        begin
          reset_signals(0);
        end
      endcase
    end
  end


  task reset_signals(input reset_mblz_done);
    begin
      // To allow reuse for termination
      mblz_done <= reset_mblz_done;
      current_state <= START;
      pivot_col_start <= 1'b1;
      pivot_col_fifo_start <= 1'b0;
      pivot_col_addr_skip_OR <= 32'd0;
      pivot_col_addr <= 32'd0;
      pivot_row_start <= 1'b1;
      pivot_row_fifo_start <= 1'b0;
      pivot_row_addr <= 32'd0;
      update_tableau_pivot_row_index <= 16'd0;
      update_pivot_row_start <= 1'b1;
      update_pivot_row_fifo_start <= 1'b0;
      update_tableau_start <= 1'b1;
      update_tableau_busy <= 1'b0;
      update_tableau_fifo_start <= 1'b0;
      skip_first_row_addr <= 'd0;
    end
  endtask
endmodule
