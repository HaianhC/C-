module register_bank(
	input clk,
	input rst_n,
	input [7:0] offset,
	input [31:0] write_reg,
	output reg [31:0] read_reg,
	input rf_write,
	
	//status
	input byte_send,
	input busy,
	input rcvd_dat_valid,
	
	//FIFO status
	input tx_fifo_full,
	input tx_fifo_empty,
	input rx_fifo_full,
	input rx_fifo_empty,
	
	inout reg [31:0] data,
	output tx_fifo_en,
	output rx_fifo_en,
	
	//slave addr
	output [6:0] addr,
	
	//control
	output rw,
	output rst_n_s,
	
	//byte count
	output [7:0] send_dat_cnt
	
	
);
reg [7:0] Register [31:0];

initial begin
  //Register <= {default: 8'b0};
end

assign tx_fifo_en = (offset == 12)  ? 1'b1  : 1'b0;
assign rx_fifo_en = (offset == 16)  ? 1'b1  : 1'b0;

always@(posedge clk)
begin
  //update FIFO status
  Register[20][0] <= rx_fifo_empty;
  Register[20][1] <= rx_fifo_full;
  Register[20][2] <= tx_fifo_empty;
  Register[20][3] <= tx_fifo_full;
  //update status
  Register[24][1] <= byte_send;
  Register[24][2] <= busy;
  Register[24][3] <= rcvd_dat_valid;
end

always@(posedge clk or negedge rst_n)
begin
  if(~rst_n) begin
    //set output
    read_reg <= 32'b0;
    
    //set  register
    Register[0] <= 8'b0;
    Register[1] <= 8'b0;
    Register[2] <= 8'b0;
    Register[3] <= 8'b0;
    Register[4] <= 8'b0;
    Register[5] <= 8'b0;
    Register[6] <= 8'b0;
    Register[7] <= 8'b0;
    Register[8] <= 8'b0;
    Register[9] <= 8'b0;
    Register[10] <= 8'b0;
    Register[11] <= 8'b0;
    Register[12] <= 8'b0;
    Register[13] <= 8'b0;
    Register[14] <= 8'b0;
    Register[15] <= 8'b0;
    Register[16] <= 8'b0;
    Register[17] <= 8'b0;
    Register[18] <= 8'b0;
    Register[19] <= 8'b0;
    Register[20] <= 8'b0;
    Register[21] <= 8'b0;
    Register[22] <= 8'b0;
    Register[23] <= 8'b0;
    Register[24] <= 8'b0;
    Register[25] <= 8'b0;
    Register[26] <= 8'b0;
    Register[27] <= 8'b0;
    Register[28] <= 8'b0;
    Register[29] <= 8'b0;
    Register[30] <= 8'b0;
    Register[31] <= 8'b0;
  end
  else
    if(rf_write)
      begin
        Register[offset]      <=    write_reg[7:0];
        Register[offset + 1]  <=    write_reg[15:8];
        Register[offset + 2]  <=    write_reg[23:16];
        Register[offset + 3]  <=    write_reg[31:24];   
      end
    else
      begin
        read_reg <= {Register[offset+3],Register[offset+2],Register[offset+1],Register[offset]};
      end
end

assign data = (rf_write) ? {Register[offset+3],Register[offset+2],Register[offset+1],Register[offset]} : 32'bz; 

assign addr = Register[4][6:0];

assign rw  = Register[0][0];
assign rst_n_s = Register[0][1];

assign send_dat_cnt = Register[8][7:0];
endmodule