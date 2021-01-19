`default_nettype none

/*
Generate a divided clock (square wave)
*/
module clock_divider #(parameter divider_bits = 8)
(
  input resetn,
  input [divider_bits-1:0] divider,
  output tick,
  input clk
);

  reg [divider_bits-1:0] accum;
  reg tick_r;

  assign tick = tick_r;

  always @(posedge clk) begin
    if (!resetn) begin
      accum <= 0;
      tick_r <= 0;
    end else begin
      accum <= accum + 1'b1;
      if (accum == (divider>>1)) begin
        accum <= 0;
        tick_r <= ~tick_r;
      end
    end
  end

endmodule