
`timescale 1 ns / 1 ps

module LP_control(
    // Number of LP cores is 4 so log2(4) = 2
    parameter LOG_NUM_LP_CORES = 2;
  )(

    // Inputs
    input aclk,
    input aresetn, // Asynchronous negedge reset
    input mblz_init,
    input fifo_stop,
    input fifo_ready,
    input pivot_col_stop,
    input pivot_col_done,
    input pivot_row_stop,
    input pivot_row_done,
    input update_stop,
    input update_done,
    input comparator_stop,
    input comparator_done,
    input complete,

    // Outputs
    output reg mblz_done,
    output reg stop,
    output reg pivot_col_valid,
    output reg pivot_row_valid,
    output reg update_valid,
    output reg comparator_valid,
    output reg fifo_init,
    output reg [LOG_NUM_LP_CORES-1:0] mux_sel,
    output reg [LOG_NUM_LP_CORES-1:0] demux_sel
  );

  reg computation_started;

  // State machine
  always @(posedge aclk or negedge aresetn)
  begin
    if (~aresetn)
    begin
      mblz_done <= 0;
      stop <= 1;
      pivot_col_valid <= 0;
      pivot_row_valid <= 0;
      update_valid <= 0;
      comparator_valid <= 0;
      fifo_init <= 0;
      computation_started <= 0;
      // Set mux_sel and demux_sel to high impedance
      mux_sel <= 1'bz;
      demux_sel <= 1'bz;
    end
    else
    begin
      if (pivot_col_stop || pivot_row_stop || update_stop || comparator_stop || fifo_stop || mblz_done)
      begin
        stop <= 1;
        fifo_init <= 0;
        // Set mux_sel and demux_sel to high impedance
        mux_sel <= 1'bz;
        demux_sel <= 1'bz;
      end
      else
      begin
        if (mblz_init)
        begin
          // Start fetching data from FIFO
          stop <= 0;
          fifo_init <= 1;
        end
        if (fifo_ready)
        begin
          computation_started <= 1;
          pivot_col_valid <= 1;
          // Allow data for first computation block to be fetched
          mux_sel <= 0;
        end
        if (computation_started)
        begin
          if (pivot_col_done)
          begin
            pivot_col_valid <= 0;
            pivot_row_valid <= 1;
            // Increment mux_sel to fetch data for next computation block
            mux_sel <= mux_sel + 1;
            // Allow data for first computation block to be written back
            demux_sel <= 0;
          end
          if (pivot_row_done)
          begin
            pivot_row_valid <= 0;
            update_valid <= 1;
            // Increment mux_sel to fetch data for next computation block
            mux_sel <= mux_sel + 1;
            // Increment demux_sel to write back data for next computation block
            demux_sel <= demux_sel + 1;
          end
          if (update_done)
          begin
            update_valid <= 0;
            comparator_valid <= 1;
            // Increment mux_sel to fetch data for next computation block
            mux_sel <= mux_sel + 1;
            // Increment demux_sel to write back data for next computation block
            demux_sel <= demux_sel + 1;
          end
          if (comparator_done)
          begin
            comparator_valid <= 0;
            if (complete)
            begin
              mblz_done <= 1;
              stop <= 1;
              computation_started <= 0;
            end
            else
            begin
              pivot_col_valid <= 1;
              // Reset mux_sel to fetch data for first computation block
              mux_sel <= 0;
              // Increment demux_sel to write back data for next computation block
              demux_sel <= demux_sel + 1;
            end
          end
        end
      end
    end
  end



endmodule
