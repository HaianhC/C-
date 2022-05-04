module FIFO_FWFT(
  input clk,
  input rst_n,
  input [31:0] data_in,
  input en,
  
  output [7:0] data_out,
  output empty,
  output full
);

reg [7:0] mem [7:0];
reg [2:0] count = 0;
reg [2:0] write_count = 0;
reg [2:0] read_count = 0;
assign empty = (count == 0) ? 1'b1  : 1'b0;
assign full = (count == 8) ? 1'b1 : 1'b0;
always@(posedge clk or negedge rst_n)
begin
  if(~rst_n) begin
    write_count <= 0;
    read_count <= 0;
  end
  else
    if(en && count != 0)
      begin
        read_count <= read_count + 1;
      end
    else if(~en && count < 4)
      begin
        mem[write_count]      =     data_in[7:0];
        mem[write_count+1]    =     data_in[15:8];
        mem[write_count+2]    =     data_in[23:16];
        mem[write_count+3]    =     data_in[31:24];
        write_count <= write_count + 4;
      end
end
assign data_out = mem[read_count];
endmodule