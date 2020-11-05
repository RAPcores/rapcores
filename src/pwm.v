`default_nettype none

/*
 Simple PWM module
*/
module PWM #(
    parameter bits = 8
) (
    input  clk,
    input  [bits-1:0] val,
    output pwm
);

  reg [bits-1:0] accum = 0;
  assign pwm = (accum <= val);

  always @(posedge clk) accum <= accum + 1'b1;

endmodule
