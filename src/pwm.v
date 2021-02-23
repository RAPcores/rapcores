`default_nettype none

/*
 Simple PWM module
*/
module pwm #(
    parameter bits = 8,
    parameter resetable = 0
) (
    input  clk,
    input  resetn,
    input  [bits-1:0] val,
    output pwm
);

  reg [bits-1:0] accum = 0;
  assign pwm = (accum < val);

  always @(posedge clk)
  if (resetable) begin
    if(!resetn) accum <= 0;
    else if(resetn) accum <= accum + 1'b1;
  end else
    accum <= accum + 1'b1;


endmodule
