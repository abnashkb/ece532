`timescale 1ns/1ps

module floating_point_subtract_multiply_tb;

  // Parameters
  parameter CLK_PERIOD = 10; // Clock period in ns
  
  // Inputs and outputs
  wire [31:0] m_axis_result_tdata;
  reg m_axis_result_tready;
  wire [15:0]m_axis_result_tuser;
  wire [2:0] m_axis_result_tflags;
  wire m_axis_result_tvalid;
  reg [31:0] s_axis_a_tdata;
  wire s_axis_a_tready;
  reg [15:0]s_axis_a_tuser;
  reg s_axis_a_tvalid;
  reg [31:0] s_axis_b_tdata;
  wire s_axis_b_tready;
  reg s_axis_b_tvalid;
  reg [31:0] s_axis_c_tdata;
  wire s_axis_c_tready;
  reg s_axis_c_tvalid;
  reg aresetn;
  

  // Clock generation
  reg aclk;
  // Instantiate clock generator
  initial begin
    aclk = 1'b0; // Initialize clock to 0
    forever #((CLK_PERIOD/2)) aclk = ~aclk; // Toggle clock every half period
  end

  // Instantiate the Design Under Test (DUT)
  floating_point_subtract_multiply DUT (
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tuser(m_axis_result_tuser),
    .m_axis_result_tflags(m_axis_result_tflags),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tuser(s_axis_a_tuser),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(s_axis_b_tready),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .s_axis_c_tdata(s_axis_c_tdata),
    .s_axis_c_tready(s_axis_c_tready),
    .s_axis_c_tvalid(s_axis_c_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  // Testbench functionality
  initial begin
    $display("Starting Design Under Test (DUT) testbench");
    
    aresetn = 0;
    s_axis_a_tvalid = 0 ; 
    s_axis_b_tvalid = 0 ;
    s_axis_c_tvalid = 0 ;
    s_axis_a_tdata = 0;
    s_axis_b_tdata = 0;
    s_axis_c_tdata = 0;
      s_axis_a_tuser = 0;
    
    
    # (CLK_PERIOD * 3)
    // Apply inputs
    aresetn = 1;
    


    // Test cases
    repeat (3) begin
        s_axis_a_tvalid = 0 ; 
        s_axis_b_tvalid = 0 ;
        s_axis_c_tvalid = 0 ;
        m_axis_result_tready = 0;
      # (3 * CLK_PERIOD)
      // Generate random inputs
      s_axis_a_tdata = $random;
      s_axis_b_tdata = $random;
      s_axis_c_tdata = $random;
      // Generate random tuser values
      s_axis_a_tuser = $random;
      
      // Drive tvalid for input streams
      s_axis_a_tvalid = 1;
      s_axis_b_tvalid = 1;
      s_axis_c_tvalid = 1;



      

      // Display inputs
      $display("Input: A = %h, B = %h, C = %h", s_axis_a_tdata, s_axis_b_tdata, s_axis_c_tdata);
      
      // Wait for valid output
      while (s_axis_a_tready == 0) begin
        #1;
      end
      
      # CLK_PERIOD
      
      s_axis_a_tvalid = 0 ; 
      s_axis_b_tvalid = 0 ;
      s_axis_c_tvalid = 0 ;

      // Wait for valid output
      while (m_axis_result_tvalid == 0) begin
        #1;
      end
      
      # CLK_PERIOD
      
      // Drive tready for output stream
      m_axis_result_tready = 1;
      
      # CLK_PERIOD
      
      // Display output
      $display("Output: C - AB = %h", m_axis_result_tdata);
      
      // Wait for valid output
      while (m_axis_result_tvalid == 1) begin
        #1;
      end

      // Wait before next test
      #10;
    end

    $display("Design Under Test (DUT) testbench completed");
    // End simulation
    $finish;
  end

endmodule
