module fifo_tb();
reg clk;
reg [7:0] data_in;
reg en;
reg rst_n;

wire full;
wire empty;
wire [31:0] data_out;

FIFO dut(
.clk(clk),
.data_in(data_in),
.en(en),
.rst_n(rst_n),

.full(full),
.empty(empty),
.data_out(data_out)
);

initial begin
clk = 1'b0;
forever begin 
clk = #10 ~clk;
end
end

initial begin
data_in = 8'd0;
en = 1'b1;
rst_n = 1'b1;

#20;
data_in = 8'd1;

#20;
data_in = 8'd2;

#20;
data_in = 8'd3;

#20;
data_in = 8'd4;

#20;
data_in = 8'd5;

#20;
data_in = 8'd6;

#20;
data_in = 8'd7;

#20;
data_in = 8'd8;

#20;
data_in = 8'd9;

#20;
data_in = 8'd10;

#20;
data_in = 8'd11;

#20;
en = 1'b0;

#200 $finish;
end
endmodule
