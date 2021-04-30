// SPDX-License-Identifier: ISC
`default_nettype none

/*
PWM module
Parameters:
  - bits - Accumulator resolution
  - delayed - delay output by the value of `delay` wire
  - resetable - allow the accumulator to reset
*/
module pwm #(
    parameter bits = 8,
    parameter resetable = 0,
    parameter delayed = 0
) (
    input  clk,
    input  resetn,
    input  [bits-2:0] delay, // delay should never be more than half the period
    input  [bits-1:0] val,
    output pwm
);

  reg [bits-1:0] accum = 0; // FPGA ONLY

  if (delayed) assign pwm = (accum[bits-2:0] >= delay) & (accum < (val+delay));
  else assign pwm = (accum < val);

  always_ff @(posedge clk)
  if (resetable) begin
    if(!resetn) accum <= 0;
    else if(resetn) accum <= accum + 1'b1;
  end else
    accum <= accum + 1'b1;


endmodule