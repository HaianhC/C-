module TOP(
  input PCLK,
  input Presetn,
  input [31:0] PADDR,
  input PSELx,
  input PENABLE,
  input PWRITE,
  input [31:0] PWDATA,
  input [3:0] PSTRB,
  
  output [7:0] data_out,
  output [31:0] PRDATA,
  
  inout SDA,
  inout SCL
);
reg [7:0] offset;
reg [31:0] t_data;
wire rf_write;
reg [31:0] r_data;

APB_interface APB_interface(
  .PCLK(PCLK),
  .Presetn(Presetn),
  .PADDR(PADDR),
  .PSELx(PSELx),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PWDATA(PWDATA),
  .PRDATA(PRDATA),
  .PSTRB(PSTRB),
  
  .offset(offset),
  .t_data(t_data),
  .rf_write(rf_write),
  
  .r_data(r_data)
);

wire tx_fifo_full;
wire tx_fifo_empty;
wire rx_fifo_full;
wire rx_fifo_empty;

wire start_cond;
wire byte_send;
wire busy;
wire rcvd_dat_valid;

wire tx_fifo_en;
wire rx_fifo_en;

reg [31:0] data;

reg [6:0] addr;
reg [7:0] send_dat_cnt;
wire rw;
wire rst_n_s;


register_bank Register_FILE(
  .offset(offset),
  .clk(PCLK),
  .rst_n(Presetn),
  .write_reg(t_data),
  .read_reg(r_data),
  .data(data),
  .rf_write(rf_write),
  
  .start_cond(start_cond),
  .byte_send(byte_send),
  .busy(busy),
  .rcvd_dat_valid(rcvd_dat_valid),
  
  .tx_fifo_full(tx_fifo_full),
  .tx_fifo_empty(tx_fifo_empty),
  .rx_fifo_full(rx_fifo_full),
  .rx_fifo_empty(rx_fifo_empty),
  
  .tx_fifo_en(tx_fifo_en),
  .rx_fifo_en(rx_fifo_en),
  
  .rw(rw),
  .addr(addr),
  .send_dat_cnt(send_dat_cnt),
  .rst_n_s(rst_n_s)
);

FIFO_FWFT TX_FIFO(
  .clk(PCLK),
  .rst_n(Presetn),
  .data_in(data),
  .en(tx_fifo_en),
  
  .data_out(data_in),
  .full(tx_fifo_full),
  .empty(tx_fifo_empty)
);

reg [7:0] rcvd_dat;
FIFO RX_FIFO(
  .clk(PCLK),
  .rst_n(Presetn),
  .data_in(rcvd_dat),
  .en(rx_fifo_en),
  .data_out(data),
  
  .full(rx_fifo_full),
  .empty(rx_fifo_empty)
);

i2c_top i2c_core(
  .clk(PCLK),
  .rstn(rst_n_s),
  .send_addr(addr),
  .send_dat_cnt(send_dat_cnt),
  .send_en(),
  .busy(busy),
  .rcvd_dat(),
  .rcvd_dat_valid(rcvd_dat_valid),
  .scl(SCL),
  .sda(SDA)
);
endmodule
