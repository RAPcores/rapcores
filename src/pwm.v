`default_nettype none

/*
 Simple PWM module
*/
module pwm #(
    parameter bits = 8
) (
    input  clk,
    input  resetn,
    input  [bits-1:0] val,
    output pwm
);

  reg [bits-1:0] accum;
  assign pwm = (accum < val);

  always @(posedge clk)
  if(!resetn)
    accum = 0;
  else
    accum <= accum + 1'b1;

endmodule
