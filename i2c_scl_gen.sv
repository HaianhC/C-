`include "timescale.v"

module i2c_scl_gen (
  input       logic         clk             ,
  input       logic         rstn            ,

  input       logic         scl_en          ,
  input       logic [8:0]   cfg_div         ,

  input       logic         start_cond      ,

  output      reg           scl_o           ,
  output      logic         scl_negedge     ,
  output      logic         scl_posedge     ,
  output      logic         stop_en         
);

  logic       comb_rstn       ;
  logic       toggle          ;
  logic       scl_pre         ;

  reg   [8:0] counter         ;

  assign comb_rstn = rstn & scl_en ;

  always_ff @(posedge clk or negedge comb_rstn) begin : clk_divider
    if (~comb_rstn) begin
      counter     <= 8'd1;
      scl_o       <= 1'b1;
    end else begin
      counter <= counter + 1;
      if (counter >= (cfg_div - 1))
        counter <= 8'd0;

      scl_o       <= scl_pre        ;
    end
  end

  assign toggle       = counter < cfg_div[8:1];
  assign scl_pre      = scl_en ? (start_cond ? toggle : ~toggle)            : 1'b1;
  assign scl_negedge  = scl_en ? (counter == (cfg_div - 1))                 : 1'b0;
  assign scl_posedge  = scl_en ? (counter == cfg_div[8:1])                  : 1'b0;
  assign stop_en      = scl_en ? (counter == (cfg_div[8:1] + cfg_div[8:2])) : 1'b0;

endmodule // i2c_scl_gen
