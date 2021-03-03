// SPDX-License-Identifier: ISC
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

  reg [bits-1:0] accum = 0; // FPGA ONLY
  assign pwm = (accum < val);

  always @(posedge clk)
  if (resetable) begin
    if(!resetn) accum <= 0;
    else if(resetn) accum <= accum + 1'b1;
  end else
    accum <= accum + 1'b1;


endmodule


/*

 PWM with Delay on the output, useful for constructing
 center-aligned PWM
*/
module pwm_delayed #(
    parameter bits = 8,
    parameter resetable = 0
) (
    input  clk,
    input  resetn,
    input  [bits-2:0] delay, // delay should never be more than half the period
    input  [bits-1:0] val,
    output pwm
);

  reg [bits-1:0] accum = 0; // FPGA ONLY
  assign pwm = (accum[bits-2:0] >= delay) & (accum < (val+delay));

  always @(posedge clk)
  if (resetable) begin
    if(!resetn) accum <= 0;
    else if(resetn) accum <= accum + 1'b1;
  end else
    accum <= accum + 1'b1;


endmodule
