module lp_timer(
    // Clock and reset
    input wire clk,
    input wire resetn,

    // AXI-Lite inputs
    input wire [31:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    
    input wire [31:0] S_AXI_WDATA,
    input wire [3:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,

    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,

    input wire [31:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,           // DONE

    output wire [31:0] S_AXI_RDATA,      // DONE
    output wire [1:0] S_AXI_RRESP,       // DONE
    output wire S_AXI_RVALID,            // DONE
    input wire S_AXI_RREADY,
    
    // LP algorithm signals
    input wire lp_start,
    input wire lp_end
);
    // Useless AXI signals
    assign S_AXI_AWREADY = 1'b0;
    assign S_AXI_WREADY = 1'b0;
    assign S_AXI_BRESP = 2'b0;
    assign S_AXI_BVALID = 1'b0;

    // Constant AXI signals
    assign S_AXI_RRESP = 2'b0;              // "OKAY" response
    assign S_AXI_RDATA = usec_elapsed;

    reg s_axi_arready;
    reg s_axi_rvalid;

    assign S_AXI_ARREADY = s_axi_arready;
    assign S_AXI_RVALID = s_axi_rvalid;

    // Variable AXI signals
    always @ (posedge clk) begin
        if (resetn == 1'b0) begin           // Reset asserted, deassert all signals
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end
        else if (lp_end == 1'b1) begin      // Once algorithm is done, assert ARREADY and RVALID
            s_axi_arready <= 1'b1;
            s_axi_rvalid <= 1'b1;
        end
        else if (lp_start == 1'b1) begin    // Once algorithm starts, deassert those signals
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end
    end

    // Implement timer
    reg start;
    reg [31:0] usec_elapsed;
    reg [31:0] clock_counter;

    always @ (posedge clk) begin
        if (resetn == 1'b0) start <= 1'b0;
        else if (lp_end == 1'b1) start <= 1'b0;
        else if (lp_start == 1'b1) start <= 1'b1;
    end

    always @ (posedge clk) begin
        if (resetn == 1'b0) begin
            usec_elapsed <= 'd0;
            clock_counter <= 'd0;
        end
        else if (lp_start == 1'b1) begin
            usec_elapsed <= 'd0;
            clock_counter <= 'd1;
        end
        // Main counter loop
        else if (start == 1'b1) begin
            // If clock_counter reaches 100, reset clock_counter and increment usec_elapsed
            if (clock_counter == 32'd100) begin
                usec_elapsed <= usec_elapsed + 1;
                clock_counter <= 32'd1;
            end
            else clock_counter <= clock_counter + 1;
        end
    end
    
endmodule