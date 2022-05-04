`include "timescale.v"

module i2c_fsm (
  input   logic         clk             ,
  input   logic         rstn            ,

  input   logic         sda_i           ,
  output  reg           sda_o           ,
  output  reg           scl_en          ,

  input   logic [6:0]   send_addr       ,
  input   logic [7:0]   send_dat_in     ,
  input   logic         send_en         ,
  input   logic [7:0]   send_dat_cnt    ,
  input   logic [1:0]   send_rd_wr      , // 0 -> write only
                                          // 1 -> read only
                                          // 2 -> write then read

  input   logic         scl_posedge     ,
  input   logic         scl_negedge     ,
  input   logic         stop_en         ,
  output  logic         start_cond      ,

  output  logic         byte_sent       ,
  output  logic         busy            ,
  output  reg   [7:0]   rcvd_dat        ,
  output  logic         rcvd_dat_valid   
);

  localparam [3:0]  IDLE        = 4'd0  ,
                    START       = 4'd1  ,
                    SEND_ADDR   = 4'd2  ,
                    ACK_CHECK   = 4'd3  ,
                    WRITE_DATA  = 4'd4  ,
                    ACK_GEN     = 4'd5  ,
                    NACK_GEN    = 4'd6  ,
                    READ_DATA   = 4'd7  ,
                    RESTART     = 4'd8  ,
                    STOP        = 4'd9  ;

  reg   [3:0]     cur_state             ;
  reg   [3:0]     next_state            ;
  reg   [3:0]     bit_counter           ;
  reg   [7:0]     byte_cnt              ;
  reg             is_repeated_start     ;
  reg             rcvd_ack              ;

  /////////////////////////////////////////////
  // STATE TRANSITION
  always_ff @(posedge clk or negedge rstn) begin : proc_cur_state_logic
    if (~rstn) begin
      cur_state   <= IDLE       ;
    end else begin
      cur_state   <= next_state ;
    end
  end

  /////////////////////////////////////////////
  // NEXT STATE LOGIC
  always_comb begin : proc_next_state_logic
    next_state  = cur_state;

    case (cur_state)
      IDLE:
        begin
          if (send_en) begin 
            next_state  = START     ;
          end
        end

      START: // START condition
        begin
          if (scl_negedge) begin
            next_state  = SEND_ADDR ;
          end
        end

      RESTART: // REPEATED START condition
        begin
          if (scl_negedge) begin
            next_state  = SEND_ADDR ;
          end
        end

      SEND_ADDR: // Send Slave's address along with R/W bit
        begin
          if (scl_negedge & (bit_counter == 0)) begin
            next_state  = ACK_CHECK ;
          end
        end        

      ACK_CHECK: // Check if slave response with ACK
        begin
          if (scl_negedge) begin
            if (rcvd_ack) begin
              // If ACK is received -> move to READ/WRITE state
              if (is_repeated_start)
                next_state    = RESTART   ;
              else
                if (send_rd_wr[0])
                  next_state  = READ_DATA ;
                else begin
                  if (byte_cnt > 0)
                    next_state  = WRITE_DATA  ;
                  else
                    next_state  = STOP        ;
                end
            end else begin
              // IF NACK is received -> move to STOP
              next_state  = STOP  ;
            end
          end
        end

      ACK_GEN:
        begin
          if (scl_negedge) begin
            next_state  = READ_DATA ;
          end
        end

      NACK_GEN:
        begin
          if (scl_negedge) begin
            next_state  = STOP      ;
          end
        end

      WRITE_DATA:
        begin
          if (scl_negedge) begin
            if (bit_counter == 0) begin
              next_state = ACK_CHECK  ;
            end
          end
        end

      READ_DATA:
        begin
          if (scl_negedge) begin
            if (bit_counter == 0)
              if (byte_cnt > 0)
                next_state = ACK_GEN    ;
              else
                next_state = NACK_GEN   ;
          end
        end

      STOP: // Generate STOP condition then move to IDLE
        if (stop_en) begin
          next_state  = IDLE;
        end

    endcase // cur_state
  end

  /////////////////////////////////////////////
  // DATA PATH
  always_ff @(posedge clk or negedge rstn) begin : proc_data_path
    if (~rstn) begin
      scl_en            <= 1'b0 ;
      sda_o             <= 1'b1 ;
      bit_counter       <= 8'd7 ;
      byte_cnt          <= 8'd0 ;
      is_repeated_start <= 1'b0 ;
      rcvd_ack          <= 1'b0 ;
      rcvd_dat          <= 8'd0 ;
    end else begin
      case (cur_state)
        IDLE:
          begin
            scl_en      <= 1'b0   ; // No SCL
            sda_o       <= 1'b1   ; // Release SDA
            bit_counter <= 8'd7   ; // Reset bit_counter
          end

        START:
          begin
            scl_en      <= 1'b1   ; // SCL starts from here
            sda_o       <= 1'b0   ; // Pull SDA to lows -> START condition
            byte_cnt    <= send_dat_cnt ; // Store number of bytes to send
          end

        RESTART:
          begin
            sda_o       <= 1'b1   ; // By default SDA is released

            if (stop_en) // Reuse this signal
              sda_o     <= 1'b0   ; // RESTART condition
          end

        SEND_ADDR:
          begin
            // Bit counter changes on SCL's negedge
            if (scl_negedge) begin
              if (bit_counter > 0) begin
                bit_counter <= bit_counter - 1;
              end
            end

            // Address first then R/W bit
            if (bit_counter > 0)
              sda_o   <= send_addr[bit_counter - 1];
            else
              sda_o   <= send_rd_wr;
          end

        ACK_CHECK:
          begin
            bit_counter <= 8'd7; // Reset bit_counter
            sda_o       <= 1'b1; // Release SDA
            byte_sent   <= 1'b1; // Indicates 1 byte is sent

            // Check SDA value at posedge of SCL
            if (scl_posedge) begin
              if (sda_i == 1'b0)  // If 0 -> ACK
                rcvd_ack <= 1'b1;
              else                // If 1 -> NACK
                rcvd_ack <= 1'b0;
            end
          end

        ACK_GEN:
          begin
            bit_counter <= 8'd7; // Reset bit_counter
            sda_o       <= 1'b0; // Pull SDA to low -> ACK            
          end

        NACK_GEN:
          begin
            bit_counter <= 8'd7; // Reset bit_counter
            sda_o       <= 1'b1; // Release SDA -> NACK
          end

        WRITE_DATA:
          begin
            byte_sent <= 1'b0   ; // Reset byte_sent
            rcvd_ack  <= 1'b0   ; // Reset rcvd_ack

            // Bit counter changes on SCL's negedge
            if (scl_negedge) begin
              if (bit_counter > 0) begin
                bit_counter <= bit_counter - 1;
              end else if (bit_counter == 0) begin
                byte_cnt    <= byte_cnt - 1   ; // 1 byte sent, decrease byte_cnt

                if ((byte_cnt == send_dat_cnt) & (send_rd_wr == 2'b10))
                  is_repeated_start = 1'b1;
                else
                  is_repeated_start = 1'b0;
              end
            end

            // MSB first
            sda_o   <= send_dat_in[bit_counter];
          end

        READ_DATA:
          begin
            byte_sent <= 1'b0   ; // Reset byte_sent
            rcvd_ack  <= 1'b0   ; // Reset rcvd_ack
            sda_o     <= 1'b1   ; // Release SDA

            // Bit counter changes on SCL's negedge
            if (scl_negedge) begin
              if (bit_counter > 0) begin
                bit_counter <= bit_counter - 1;
              end else if (bit_counter == 0) begin
                byte_cnt  <= byte_cnt - 1 ; // 1 byte received -> decrease byte_cnt
              end
            end

            // Receive from MSB
            rcvd_dat[bit_counter] = sda_i;
          end

        STOP:
          begin
            byte_sent <= 1'b0   ; // Reset byte_sent
            rcvd_ack  <= 1'b0   ; // Reset rcvd_ack
            sda_o     <= 1'b0   ; // First pulls it low

            if (stop_en) begin
              sda_o   <= 1'b1;  // Then release SDA later
              scl_en  <= 1'b0;  // No SCL
            end
          end

      endcase
    end
  end

  /////////////////////////////////////////////
  // OTHERS
  assign start_cond       = cur_state == START;
  assign busy             = cur_state != IDLE;
  assign rcvd_dat_valid   = (cur_state == READ_DATA) & ((next_state == ACK_GEN) || (next_state == NACK_GEN));

endmodule // i2c_fsm
