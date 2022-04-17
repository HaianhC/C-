module gen_clk_tb;
 // Inputs
 reg clk_in;
 reg resetN;
 // Outputs
 wire clk_out;
 wire scl_posedge;
 wire scl_negedge;
 // Instantiate the Unit Under Test (UUT)
 // Test the clock divider in Verilog
 gen_clk uut (
  .clk_in(clk_in),
  .resetN(resetN), 

  .scl_posedge(scl_posedge),
  .scl_negedge(scl_negedge),
  .clk_out(clk_out)
 );
 initial begin
  // Initialize Inputs
  clk_in = 0;
  resetN = 0;
  #10;  resetN = 1;
  // create input clock 50MHz
        forever #10 clk_in = ~clk_in;
 end
      
endmodule
