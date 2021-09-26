//                              -*- Mode: Verilog -*-
// Filename        : uart_tx_op.v
// Description     : uart_tx module
// Author          : silenuszhi@gmail.com
// Created On      : Tue Sep  9 20:43:45 2014
// Last Modified By: silenuszhi@gmail.com
// Last Modified On: Tue Sep  9 20:43:45 2014
// Update Count    : 0
// Status          : Unknown, Use with caution!

module uart_tx_op
  #(
    parameter VERIFY_ON = 1'b0,
    parameter VERIFY_EVEN = 1'b0
    )
   (
    input       clk,
    input       reset,
    input       clk_en, 
    input [7:0] datain,
    input       shoot,
    output reg  uart_tx = 1'b1,
    output reg  uart_busy
    );

   reg [3:0]    clk_cnt = 4'h0;
   reg          clk_tx_en = 1'b0;
   reg [7:0]    datain_shoot_latch = 8'h0;
   reg [2:0]    bitcnt = 3'h0;
   reg          uart_tx_i = 1'b1;
   reg          uart_tx_i2 = 1'b1;
   
   
   localparam [4:0]// synopsys enum state_info
     SM_IDLE = 5'b00001,
     SM_START_BIT  = 5'b00010,
     SM_DATA_BIT = 5'b00100,
     SM_VERIFY_BIT = 5'b01000,
     SM_STOP_BIT = 5'b10000;   

   reg [4:0]    /* synopsys enum state_info */
		state = SM_IDLE;
   reg [4:0]    /* synopsys enum state_info */
		next_state = SM_IDLE;

   
   /*AUTOASCIIENUM("state","state_asc","SM_")*/   
   // Beginning of automatic ASCII enum decoding
   reg [79:0]           state_asc;              // Decode of state
   always @(state) begin
      case ({state})
        SM_IDLE:       state_asc = "idle      ";
        SM_START_BIT:  state_asc = "start_bit ";
        SM_DATA_BIT:   state_asc = "data_bit  ";
        SM_VERIFY_BIT: state_asc = "verify_bit";
        SM_STOP_BIT:   state_asc = "stop_bit  ";
        default:       state_asc = "%Error    ";
      endcase
   end
   // End of automatics
   /*AUTOASCIIENUM("next_state","nstate_asc","SM_")*/
   // Beginning of automatic ASCII enum decoding
   reg [79:0]           nstate_asc;             // Decode of next_state
   always @(next_state) begin
      case ({next_state})
        SM_IDLE:       nstate_asc = "idle      ";
        SM_START_BIT:  nstate_asc = "start_bit ";
        SM_DATA_BIT:   nstate_asc = "data_bit  ";
        SM_VERIFY_BIT: nstate_asc = "verify_bit";
        SM_STOP_BIT:   nstate_asc = "stop_bit  ";
        default:       nstate_asc = "%Error    ";
      endcase
   end
   // End of automatics

   always @ ( posedge clk or posedge reset ) begin
      if(reset)begin
         state <= SM_IDLE;
      end else begin
         state <= next_state;
      end         
   end

   always @ ( /*AUTOSENSE*/bitcnt or clk_tx_en or shoot or state) begin
      next_state = state;
      case(state)
        SM_IDLE:
          if(shoot)
            next_state = SM_START_BIT;
        SM_START_BIT:
          if(clk_tx_en)
            next_state = SM_DATA_BIT;
        SM_DATA_BIT:
          if(clk_tx_en && bitcnt == 3'h7)
            if(VERIFY_ON)
              next_state = SM_VERIFY_BIT;
            else
              next_state = SM_STOP_BIT;
        SM_VERIFY_BIT:
          if(clk_tx_en)
            next_state = SM_STOP_BIT;
        SM_STOP_BIT:
          if(clk_tx_en)
            next_state = SM_IDLE;
        default:
          next_state = SM_IDLE;
      endcase // case (state)      
   end

   always @ ( posedge clk or posedge reset ) begin
      if (reset) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         clk_cnt <= 4'h0;
         clk_tx_en <= 1'h0;
         // End of automatics
      end else begin
         if (state == SM_IDLE) begin
            clk_cnt <= 4'h0;
            clk_tx_en <= 1'b0;            
         end else begin
            if (clk_en) begin
               clk_cnt <= clk_cnt + 1'b1;
            end
            if (clk_en && clk_cnt == 4'hE)
              clk_tx_en <= 1'b1;
            else
              clk_tx_en <= 1'b0;
         end         
      end      
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        bitcnt <= 3'b0;
      else
        if (state == SM_DATA_BIT) begin
           if(clk_tx_en)
             bitcnt <= bitcnt + 1'b1;
           else
             bitcnt <= bitcnt;
        end else begin
           bitcnt <= 3'h0;
        end      
   end   

   always @ ( posedge clk ) begin
      if(state == SM_IDLE && shoot)
        datain_shoot_latch <= datain;
      if(state == SM_DATA_BIT && clk_tx_en)
        datain_shoot_latch <= {datain_shoot_latch[0],datain_shoot_latch[7:1]}; 
   end
   
   always @ ( posedge clk ) begin
      uart_tx_i2 <= uart_tx_i;
      uart_tx <= uart_tx_i2;      
   end
   
   always @ ( /*AUTOSENSE*/datain_shoot_latch or state) begin
      uart_tx_i = 1'b1;
      case(state)
        SM_START_BIT:
          uart_tx_i = 1'b0;
        SM_DATA_BIT:
          uart_tx_i = datain_shoot_latch[0];
        SM_VERIFY_BIT:
          uart_tx_i = (^datain_shoot_latch) ^ (~VERIFY_EVEN);
        default:
          uart_tx_i = 1'b1;
      endcase // case (state)        
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset)begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         uart_busy <= 1'h0;
         // End of automatics
      end else begin
         if(state == SM_IDLE)
           uart_busy <= 1'b0;
         else
           uart_busy <= 1'b1;
      end      
   end   
   
endmodule // uart_tx_op

