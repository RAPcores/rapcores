/*  UltiCores -- IP Cores for Mechatronic Control Systems
 *
 *  Copyright (C) 2019 UltiMachine <info@ultimachine.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* quad_enc.v
 * Quadrature decoder inspired by https://www.fpga4fun.com/QuadratureDecoder.html
 * Converted to 32 bit. Added reset and fault logic. Changed some names to fit us.
 */

`default_nettype none

module quad_enc(
  input wire resetn,
  input wire  clk,
  input wire  a,
  input wire  b,
  output reg signed [31:0] count,
  input [7:0] multiplier
  );

//  wire faultn;

  reg [2:0] a_stable, b_stable;  //Hold sample before compare for stability

  wire step_a = a_stable[1] ^ a_stable[2];  //Step if a changed
  wire step_b = b_stable[1] ^ b_stable[2];  //Step if b changed
  wire step = step_a ^ step_b;  //Step if a xor b stepped
  wire direction = a_stable[1] ^ b_stable[2];  //Direction determined by comparing current sample to last
  wire signed [7:0] increment = (direction) ? multiplier : -multiplier;

  always @(posedge clk) begin
    a_stable <= {a_stable[1:0], a};  //Shift new a in. Last 2 samples shift to bits 2 and 1
    b_stable <= {b_stable[1:0], b};  //Shift new b in

    if (!resetn) begin
      count <= 0;  //reset count
    end
    else begin
      if (step) begin
        count <= count + increment;
        `ifdef FORMAL
          assert(direction && (increment == multiplier) || (increment == -multiplier));
        `endif
      end
    end
  end
endmodule
