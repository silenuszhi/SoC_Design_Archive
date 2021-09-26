`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:31:21 09/10/2014 
// Design Name: 
// Module Name:    uart_rx_op 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_rx
  #(
    parameter VERIFY_ON = 1'b0,
    parameter VERIFY_EVEN = 1'b0
    )
   (
    input            clk,
    input            clk_en,
    input            reset,
    input            uart_rx,
    output reg       dataout_valid,
    output reg [7:0] dataout 
    );

   reg [3:0]         clk_cnt = 4'h0;
   reg               clk_rx_en = 1'b0;   
   reg [1:0]         sample_cnt = 2'b0;
   reg               sample_value = 1'b0;   
   reg [2:0]         data_cnt = 3'b0;
   reg               uart_rx_i = 1'b0;
   reg               uart_rx_i2 = 1'b0;
   reg               uart_rx_i3 = 1'b0;
   reg               verify_ok = 1'b0;
   
   
   localparam [4:0]// synopsys enum state_info
     SM_IDLE = 5'b00001,
     SM_START_BIT  = 5'b00010,
     SM_DATA_BIT = 5'b00100,
     SM_VERIFY_BIT = 5'b01000,
     SM_STOP_BIT = 5'b10000;   

   reg [4:0]         /* synopsys enum state_info */
		     state = SM_IDLE;
   reg [4:0]         /* synopsys enum state_info */
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

   always @ ( posedge clk ) begin
      uart_rx_i2 <= uart_rx_i;
      uart_rx_i3 <= uart_rx_i2;
      uart_rx_i <= uart_rx;      
   end
   
   
   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        state <= SM_IDLE;
      else
        state <= next_state;      
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        data_cnt <= 3'd0;
      else begin
         case(state)
           SM_DATA_BIT:
             if(clk_rx_en && data_cnt != 3'd7)
               data_cnt <= data_cnt + 1'b1;
             else
               data_cnt <= data_cnt;
           default:
             data_cnt <= 3'd0;
         endcase // case (state)
      end
   end
   

   always @ ( /*AUTOSENSE*/clk_rx_en or data_cnt or sample_value
             or state or uart_rx_i2 or uart_rx_i3 or verify_ok) begin
      next_state = state;
      case(state)
        SM_IDLE:
          if( ~uart_rx_i2 && uart_rx_i3)
            next_state = SM_START_BIT;
        SM_START_BIT:
          if(clk_rx_en) begin
             if(~ sample_value)
               next_state = SM_DATA_BIT;        
             else
               next_state = SM_IDLE;
          end        
        SM_DATA_BIT:
          if(clk_rx_en && data_cnt == 3'd7)begin
             if(VERIFY_ON)
               next_state = SM_VERIFY_BIT;
             else
               next_state = SM_STOP_BIT;
          end        
        SM_VERIFY_BIT:
          if(clk_rx_en && verify_ok)
            next_state = SM_STOP_BIT;
          else if (clk_rx_en && ~verify_ok)
            next_state = SM_IDLE;        
        SM_STOP_BIT:
          if(clk_rx_en)
            next_state = SM_IDLE;
        default:
          next_state = SM_IDLE;
      endcase // case (state)        
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         clk_cnt <= 4'h0;
         clk_rx_en <= 1'h0;
         // End of automatics
      end else begin
         case(state)
           SM_IDLE: begin
              clk_cnt <= 4'h0;
              clk_rx_en <= 1'b0;
           end              
           SM_START_BIT: begin
              if(clk_en && clk_cnt != 4'hE)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en && clk_cnt == 4'hE)
                clk_cnt <= 4'h0;
              else
                clk_cnt <= clk_cnt;
              if(clk_en && clk_cnt == 4'hE)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;              
           end   
           SM_STOP_BIT:                 
            begin
              if(clk_en && clk_cnt != 4'hE)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en && clk_cnt == 4'hE)
                clk_cnt <= 4'h0;
              else
                clk_cnt <= clk_cnt;
              if(clk_en && clk_cnt == 4'hE)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;              
            end
           default: begin
              if(clk_en && clk_cnt != 4'hF)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en && clk_cnt == 4'hF)
                clk_cnt <= 4'h0;
              else
                clk_cnt <= clk_cnt;
              if(clk_en && clk_cnt == 4'hF)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;                            
           end
         endcase // case (state)           
      end // else: !if(reset)
   end // always @ ( posedge clk or posedge reset )
   
   always @ ( posedge clk or posedge reset ) begin
      if(reset)begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         sample_cnt <= 2'h0;
         sample_value <= 1'h0;
         // End of automatics
      end else begin
         if(clk_cnt == 4'h0)
           sample_cnt <= 2'b0;         
         else if(clk_cnt > 5 && clk_cnt < 10)
           sample_cnt <= sample_cnt + uart_rx_i3;
         else
           sample_cnt <= sample_cnt;
         if(clk_cnt == 4'h9)
           if(sample_cnt > 2'h1)
             sample_value <= 1'b1;
           else
             sample_value <= 1'b0;
         else
           sample_value <= sample_value;
      end      
   end
   
   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        verify_ok <= 1'b0;
      else begin
         if(state == SM_VERIFY_BIT)
           verify_ok <= (^dataout) ^ VERIFY_EVEN ^~ sample_value;
         else
           verify_ok <= 1'b0;
      end      
   end

   always @ ( posedge clk ) begin
      dataout <= dataout;      
      case(state)
        SM_IDLE:
          dataout <= 8'h0;
        SM_DATA_BIT:
          if(clk_rx_en)
            dataout <= {sample_value,dataout[7:1]};
        default;
      endcase // case (state)      
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        dataout_valid <= 1'b0;
      else
        if(state == SM_STOP_BIT && clk_rx_en)
          dataout_valid <= 1'b1;
        else
          dataout_valid <= 1'b0;      
   end
   
   
endmodule

