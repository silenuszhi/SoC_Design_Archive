`timescale 1ns/1ps
module tb_uart (/*AUTOARG*/) ;

   reg clk = 1'b0;
   reg reset = 1'b0;

   always #3840 clk = ~clk;   

   uart_tx dut
     (
      // Outputs
      .tx                               (tx),
      // Inputs
      .clk                              (clk),
      .reset                            (reset));

   initial begin
      reset = 1'b1;
      #100;
      reset = 1'b0;
   end
   
   
endmodule // tb_uart
