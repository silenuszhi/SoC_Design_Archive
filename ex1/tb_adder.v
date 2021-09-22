`timescale 1ns/1ps

module tb_half_adder () ;

   wire c_tb;
   wire x_tb;
   
   reg a_tb;
   reg b_tb;   

   half_adder dut 
     (
      // Outputs
      .c                                (c_tb),
      .x                                (x_tb),
      // Inputs
      .a                                (a_tb),
      .b                                (b_tb));



   initial begin
      a_tb = 1'b0;
      b_tb = 1'b0;
      #100;
      a_tb = 1'b1;        
   end   
   

   
endmodule // tb_half_adder
