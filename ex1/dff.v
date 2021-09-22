module dff 
  (input clk,
   input d,
   input reset,
   output reg q,
   output reg qn) ;

   always @ ( posedge clk or posedge reset ) begin
      if(reset)begin
         q <= 1'b0;
         qn <= 1'b1;
      end else begin
         q <= d;
         qn <= ~d;
      end
   end
   
   
endmodule // dff
