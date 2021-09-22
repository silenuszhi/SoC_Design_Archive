module half_adder 
  (
   input a,
   input b,
   output c,
   output x) ;

   assign c = a & b;
   assign x = (a & ~b) | (b & ~a);
   
   
endmodule // half_adder
