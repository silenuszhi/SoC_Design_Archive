`timescale 1ns/1ps

module tb_dff (/*AUTOARG*/) ;

   reg clk = 1'b0;
   reg d = 1'b0;
   reg reset = 1'b0;

   
   dff dut(
      // Outputs
      .q                                (q),
      .qn                               (qn),
      // Inputs
      .clk                              (clk),
      .d                                (d),
      .reset                            (reset));

   always #5 clk = ~clk;   

   initial begin
      
      reset = 1'b1;
      #100;
      reset = 1'b0;
      #100;
      @(negedge clk);
      d = 1'b1;      
      
   end
   
     
   
endmodule // tb_dff
