module uart_tx 
  (
   input  clk,
   input  reset,
   output reg tx);

   //clk frequency : 115200;

   /**/
   reg [9:0] data = 10'b1101011000;

   always @ ( posedge clk or posedge reset ) begin
      if(reset)
        tx <= 1'b1;      
      else begin
         tx <= data[0];
         data[8:0] <= data[9:1];
      end        
   end   
endmodule // uart_tx
