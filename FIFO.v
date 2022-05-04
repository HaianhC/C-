module FIFO(
  input clk,
  input [7:0] data_in,
  input en,
  input rst_n,
  
  output full,
  output empty,
  output reg [31:0] data_out  
);

reg[2:0] count = 0;
reg [7:0] mem [7:0];
reg[2:0] read_count = 0, write_count =0;

assign empty = (count == 0) ? 1'b1  : 1'b0;
assign full = (count  == 8) ? 1'b1  : 1'b0;

always@(posedge clk or negedge rst_n)
begin
  if(~rst_n) begin
    read_count <= 0;
    write_count <= 0;
  end
  else
    begin
      if(~en && count > 2 ) begin
            data_out <= {mem[read_count],mem[read_count-1],mem[read_count-2],mem[read_count-3] };
            read_count <= read_count +4;
      end
      else if(en && count < 8) begin
        mem[write_count]      =     data_in;
        write_count <= write_count + 1;
      end
      if (read_count > write_count) begin
        count <= read_count - write_count;
      end
      else if (read_count < write_count) begin
        count <= read_count - write_count;
      end
    end
end
endmodule