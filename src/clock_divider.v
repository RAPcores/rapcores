// SPDX-License-Identifier: ISC
`default_nettype none

/*
Generate a divided clock that continually runs.
*/
module clock_divider #(parameter divider_bits = 8)
(
  input resetn,
  input [divider_bits-1:0] divider,
  output tick,
  input clk
);

  reg [divider_bits-1:0] accum;

  assign tick = (accum == divider);

  always @(posedge clk) begin
    if (!resetn) begin
      accum <= 0;
    end else begin
      if (accum == divider) accum <= 0;
      else accum <= accum + 1'b1;
    end
  end

endmodule