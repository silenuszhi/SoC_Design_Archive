`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:46:41 11/28/2014 
// Design Name: 
// Module Name:    imu_package 
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
module rx_package
  #(
    parameter TOGGLE = 1'b1, //use pingpong buffer    
    parameter SOFLENGTH = 2, //sof length
    parameter SOFPATTERN = 16'hEB90,//sof pattern
    parameter EOFDETECTION = 1'b1,//eof detect or not
    parameter EOFLENGTH = 2,//eof length
    parameter EOFPATTERN = 16'h90EB,//eof pattern
    parameter FRAMELENGTHFIXED = 1'b1, //if 1,frame is fixed length
    parameter FRAMECNT = 64,//framecnt
    parameter SUB = 1'b1,//substitution
    parameter SUBPOS = 2,
    parameter SUBLENGTH = 8,//sub stitution length, if not used, leave unconnected, will gen a warning   
    parameter PICKPOS = 8,
    parameter PICKLENGTH = 3 //pick some bytes output
    )
   (
    input                         clk,
    input                         reset,
    input                         enable,

    input                         rx_data_valid,
    input [7:0]                   rx_data, 

    input                         sub_data_valid, 
    input [SUBLENGTH*8-1:0]       sub_data,
   
    output [PICKLENGTH*4-1:0]     pick_data,
    output reg                    pick_data_valid,
    output                        FIFO_clear,
   
    output reg [TOGGLE:0]         frame_datavld = 0, 
    output reg [7:0]              frame_data = 0,
    output reg [10:0]             frame_count = 0, 
    output reg [TOGGLE:0]         frame_interrupt = 0
    );

   reg [SUBLENGTH*8-1:0]           sub_data_r = 0;
   reg [SOFLENGTH*8-1:0]           sof_data = 0;
   reg [SOFLENGTH*8-1:0]           sof_data_r = 0;
   reg [EOFLENGTH*8-1:0]           eof_data = 0;
   reg                             sof_detected = 1'b0;
   reg                             eof_detected = 1'b0;   
   reg [10:0]                      data_recved_cnt = 0;
   reg [2:0]                       sof_cnt = 0;
   wire                            enable_i;
   reg                             toggle = 1'b0;
   reg  [47:0]         pick_buf; 
   

   assign pick_data = {pick_buf[43:40],pick_buf[35:32],pick_buf[27:24],pick_buf[19:16],pick_buf[11:8],pick_buf[3:0]};

   assign FIFO_clear = sof_detected;

   sync_block inst_en
     (
      // Outputs
      .dout                             (enable_i),
      // Inputs
      .clk                              (clk),
      .din                              (enable));

   localparam [3:0]// synopsys enum state_info
     SM_IDLE = 4'b0001,
     SM_SOF = 4'b0010,
     SM_DONE = 4'b0100,	    
     SM_EOF = 4'b1000;

   
   
   reg [3:0]                       /* synopsys enum state_info */
                                   state = SM_IDLE;
   reg [3:0]                       /* synopsys enum state_info */
		                   next_state = SM_IDLE;
   
   /*AUTOASCIIENUM("state","state_asc","SM_")*/   
   // Beginning of automatic ASCII enum decoding
   reg [31:0]           state_asc;              // Decode of state
   always @(state) begin
      case ({state})
        SM_IDLE:  state_asc = "idle";
        SM_SOF:   state_asc = "sof ";
        SM_DONE:  state_asc = "done";
        SM_EOF:   state_asc = "eof ";
        default:  state_asc = "%Err";
      endcase
   end
   // End of automatics
   /*AUTOASCIIENUM("next_state","nstate_asc","SM_")*/
   // Beginning of automatic ASCII enum decoding
   reg [31:0]           nstate_asc;             // Decode of next_state
   always @(next_state) begin
      case ({next_state})
        SM_IDLE:  nstate_asc = "idle";
        SM_SOF:   nstate_asc = "sof ";
        SM_DONE:  nstate_asc = "done";
        SM_EOF:   nstate_asc = "eof ";
        default:  nstate_asc = "%Err";
      endcase
   end
   // End of automatics
   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        state <= SM_IDLE;
      else
        state <= next_state;
   end

   always @ ( /*AUTOSENSE*/enable_i or eof_detected or sof_detected
             or state) begin
      next_state = state;
      case(state)
        SM_IDLE:
          if(enable_i)
            next_state = SM_SOF;
        SM_SOF:
          if(sof_detected)
            next_state = SM_EOF;
        SM_EOF:
          if(eof_detected)
            next_state = SM_DONE;
        SM_DONE:
          next_state = SM_IDLE;
        default:
          next_state = SM_IDLE;
      endcase // case (state)          
   end

   always @ ( posedge clk ) begin
      if(state == SM_SOF)begin
         if(rx_data_valid)
           sof_data <= {sof_data[(SOFLENGTH-1)*8-1:0],rx_data};
      end else if(state == SM_IDLE)
        sof_data <= 0;  

      sof_detected <= 1'b0;
      if(state == SM_SOF)
        if(sof_data == SOFPATTERN)
          sof_detected <= 1'b1;      
   end

   always @ ( posedge clk ) begin
      if(state == SM_EOF)begin
         if(rx_data_valid)
           eof_data <= {eof_data[(EOFLENGTH-1)*8-1:0],rx_data};
      end else if(state == SM_IDLE)
        eof_data <= 0;   

      eof_detected <= 1'b0;
      if(state == SM_EOF)
        if(EOFDETECTION)begin
           if(eof_data == EOFPATTERN)
             eof_detected <= 1'b1;
        end else if(FRAMELENGTHFIXED)begin
           if(data_recved_cnt == FRAMECNT)
             eof_detected <= 1'b1;
        end      
   end

   always @ ( posedge clk ) begin
      if(state == SM_IDLE)
        data_recved_cnt <= 0;
      else if(state == SM_SOF && sof_data == SOFPATTERN)
        data_recved_cnt <= SOFLENGTH;
      else if(rx_data_valid)
        data_recved_cnt <= data_recved_cnt + 1'b1;      
   end

   always @ ( posedge clk ) begin
      if(state == SM_EOF) begin
         if(sof_cnt != SOFLENGTH)
           sof_cnt <= sof_cnt + 1'b1;
      end else
        sof_cnt <= 0;        
   end   

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        frame_datavld <= 2'b0;
      else if(state == SM_EOF) begin
         if(sof_cnt <= SOFLENGTH-1)
           frame_datavld <= {toggle,~toggle};
         else
           frame_datavld <= {rx_data_valid && toggle,rx_data_valid && (~toggle)};
      end        
   end

   always @ ( posedge clk ) begin
      frame_data <= 0;    
      sof_data_r <= {sof_data_r[SOFLENGTH*8-1-8:0],8'h0};  
      if(state == SM_SOF) begin
         if(sof_detected)
           sof_data_r <= sof_data;
      end else if(state == SM_EOF) begin
         if(sof_cnt <= SOFLENGTH-1) begin
            frame_data <= sof_data_r[SOFLENGTH*8-1:SOFLENGTH*8-1-7];            
         end else if(data_recved_cnt >= SUBPOS-1 && (data_recved_cnt < (SUBPOS + SUBLENGTH)) && SUB)begin
            frame_data <= sub_data_r[SUBLENGTH*8-1:SUBLENGTH*8-1-7];            
         end else
           frame_data <= rx_data; 
      end      
   end

   always @ ( posedge clk ) begin
      if(sub_data_valid)
        sub_data_r <= sub_data;
      else if(state == SM_EOF) begin
         if((data_recved_cnt >= (SUBPOS-1)) && rx_data_valid && (data_recved_cnt < (SUBPOS+SUBLENGTH)) && SUB)
           sub_data_r <= {sub_data_r[(SUBLENGTH*8-1-8):0],8'h0};         
      end
   end

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        pick_data_valid <= 1'b0;
      else if(state == SM_EOF && (data_recved_cnt == PICKPOS + PICKLENGTH - 2) && rx_data_valid)
        pick_data_valid <= 1'b1;
      else
        pick_data_valid <= 1'b0;      
   end

   always @ ( posedge clk ) begin
      if(state == SM_EOF)
        if((data_recved_cnt >= PICKPOS - 1) && (data_recved_cnt < PICKPOS - 1 + PICKLENGTH) && rx_data_valid)
          pick_buf <= {pick_buf[PICKLENGTH*8-1-8:0],rx_data};      
   end

   always @ ( posedge clk ) begin
      if(state == SM_DONE)
        frame_count <= data_recved_cnt;      
   end
   

   always @ ( posedge clk or posedge reset ) begin
      if(reset) begin
         frame_interrupt <= 1'b0;
      end else if(state == SM_DONE)
        frame_interrupt <= {toggle,~toggle};      
      else
        frame_interrupt <= 2'b0;        
   end

   always @ ( posedge clk ) begin
      if(state == SM_DONE)
        toggle <= ~toggle;      
   end
   
   
endmodule
