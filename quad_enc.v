/*
 *
 *  UltiCores -- IP Cores for Mechatronic Control Systems
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
 *
 */

module quad_enc(
  input resetn,
  input clk,
  input a,
  input b,
  output reg faultn,
  output reg [15:0] count
  );

//  wire faultn;

  reg [2:0] a_stable, b_stable;  //Hold sample before compare for stability

  wire step_a = a_stable[1] ^ a_stable[2];  //Step if a changed
  wire step_b = b_stable[1] ^ b_stable[2];  //Step if b changed
  wire step = step_a ^ step_b;  //Step if a xor b stepped
  wire direction = a_stable[1] ^ b_stable[2];  //Direction determined by comparing current sample to last

  always @(posedge clk) begin
    a_stable <= {a_stable[1:0], a};  //Shift new a in. Last 2 samples shift to bits 2 and 1 
    b_stable <= {b_stable[1:0], b};  //Shift new b in

    if (!resetn) begin
      count <= 0;  //reset count
      faultn <= 1; //reset faultn
    end
    else begin
      if (step_a && step_b)  //We do not know direction if both inputs triggered on single clock
        faultn <= 0;
      if (step) begin
        if (direction) 
          count <= count + 1;
        else 
          count <= count - 1;
          faultn <= faultn;
      end
    end
  end
endmodule
