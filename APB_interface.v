module APB_inter(
//APB bus
  input	PCLK,
  input	Presetn,
  input	[31:0] PADDR,
  //input	PPROT,
  input	PSELx,
  input PENABLE,
  input PWRITE,
  input	[31:0] PWDATA,
  input [3:0] PSTRB,
  
//  input PREADY,
  output reg [31:0] PRDATA,
//Register bank  
  output [7:0] offset,
  output [31:0] t_data,
  output rf_write,
  input [31:0] r_data
  //output PRLVERR,
    
);

parameter ADDR_BASE = 8'b0000_0010;

reg [1:0] cur_state;
reg [1:0] next_state;
reg [7:0] mem [3:0];
reg [31:0] addr;

initial
begin
	mem[0] = 8'b0;
	mem[1] = 8'b0;
	mem[2] = 8'b0;
	mem[3] = 8'b0;
end

localparam [1:0] IDLE 	= 2'b00,
                 WRITE  = 2'b01,
				 READ 	= 2'b10;
//FSM
always@(posedge PCLK or negedge Presetn)
begin
	if(~Presetn)
		begin
			cur_state <= IDLE;
		end
	else 
		begin
			cur_state <= next_state;
		end
end
always@*
begin
	next_state = cur_state;
	case(cur_state)
		IDLE:
			begin
				if(PSELx)
				begin
					if(PWRITE) next_state = WRITE;
					else next_state = READ;
				end
		end
		WRITE:
			begin
//				if(byte_cnt == 0)
					next_state = IDLE;
			end
		READ:
			begin
//				if(byte_cnt == 0)
					next_state = IDLE;
			end
	endcase
end
//Data path
always@(posedge PCLK or negedge Presetn)
begin
	if(~Presetn)
		begin		
//			byte_cnt <= 'b0;
		end
	else
	begin
		case(cur_state)
			IDLE:
			begin
				mem[0] = 8'b0;
	            mem[1] = 8'b0;
	            mem[2] = 8'b0;
	            mem[3] = 8'b0;
			end
			WRITE:
			begin
				if(PADDR[7:0] == ADDR_BASE)
				begin
					if(PENABLE)
					begin
					   if(PSTRB[0]) mem[0] <= PWDATA[7:0];
					   if(PSTRB[1]) mem[1] <= PWDATA[15:8];
					   if(PSTRB[2]) mem[2] <= PWDATA[23:16];
					   if(PSTRB[3]) mem[3] <= PWDATA[31:24];
					end
				end
			end
			READ:
			begin
				if(PENABLE)
				begin
					PRDATA <= r_data;
				end
			end
		endcase
	end
end

assign offset = PADDR[15:8];
assign rf_write = ( PADDR[15:8] < 16) ?  1'b1 :  1'b0;
assign t_data = (PWRITE)  ? {mem[3],mem[2],mem[1],mem[0]}  : 'bz;

endmodule