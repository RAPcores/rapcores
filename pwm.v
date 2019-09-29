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

/* dac.v
 * Delta-Sigma DAC 
 * Inspired by https://github.com/freecores/sigma_delta_dac_dual_loop/blob/master/dsm2/dac_dsm2.vhd
 * and https://github.com/Basman74/Sweet32-CPU/blob/master/VHDL/RTL/simple_PWM.vhd
 * Renamed some wires, etc.
 * could add some filter, etc.
 */

module adc(
  input clk,
  input resetn,
  input enable,
  input [15:0] din,
  output dout
  );

  localparam nbits = 16;
  
  wire signed [nbits+3:0] delta1, delta2, deltaq;
  reg signed [nbits+3:0] c1;
  reg signed [nbits+3:0] c_1;

  always @(posedge clk) begin
    if (!resetn) begin
      delta1 <= 0;
      delta2 <= 0;
      delta1 <= 0;
      c1 <= 1;
      c_1 <= -1;
      dout <= 0;
    end
    else begin
      if (enable) begin
        delta1 <= din - deltaq + delta1;
        delta2 <= din - deltaq + delta1 - deltaq + delta2;
        if (din - deltaq + delta1 - deltaq + delta2) begin
          deltaq <= c1 << nbits;
          dout <= 1;
        end
        else begin
          deltaq <= c_1 << nbits;
          dout <= 0;
        end
      end
    end
  end
endmodule
