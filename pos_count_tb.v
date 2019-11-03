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

`include "pos_count.v"
`timescale 1ns/100ps

module testbench(
    input reg clk
  );
//  reg clk;
  wire resetn;
  reg step;
  reg dir;
  reg step_active_high;
  reg invert_dir;
  reg [31:0] count;
  reg [7:0] resetn_counter = 0;

//  always #5 clk = (clk === 1'b0);

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end

  pos_count count1(.resetn(resetn), .clk(clk), .step(step), .dir(dir),
    .step_active_high(step_active_high), .invert_dir(invert_dir), .count(count));

  reg [20:0] cnt;
  initial begin
//    resetn = 0;
    step <= 0;
    dir <= 0;
    step_active_high <= 1;
    invert_dir <= 0;
//    cnt <= 0;
  end

//  reg [3:0] enccntA = 0;
//  reg [3:0] enccntB = 4;


  always @(posedge clk)
  begin
    if (!resetn) begin
      cnt <= 0;
//      fault[7:2] <= 'b111111;
    end
//    faultn <= &fault;
    cnt <= cnt + 1;
    if (cnt <= 20'h90) begin
      step <= ~step;
      dir <= 0;
    end
    else begin
      step <= ~step;
      dir <= 1;
    end
  end

//  assign {LED0, LED1, LED2, LED3} = count1[3:0];
//  assign {LED4, LED5, LED6, LED7} = count1[7:4];


endmodule



