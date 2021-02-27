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

`timescale 1ns/100ps

module testbench(
  input clk,
  output enc1a, //Changed for sim
  output enc1b, //Changed for sim
  output enc2a, //Changed for sim
  output enc2b, //Changed for sim
  output LED0,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output LED5,
  output LED6,
  output LED7,
  output faultn
  );

  reg enc1a, enc1b, enc2a, enc2b;
  wire [15:0] count1, count2;
//  reg resetn;
  wire resetn;
  reg [7:0] resetn_counter = 0;
  wire faultn;
  reg [7:0] fault;

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end

  quad_enc quad1(.resetn(resetn), .clk(clk), .a(enc1a), .b(enc1b), .count(count1), .faultn(fault[0]));
  quad_enc quad2(.resetn(resetn), .clk(clk), .a(enc2a), .b(enc2b), .count(count2), .faultn(fault[1]));


  reg [20:0] cnt;
  initial begin
    enc1a <= 0;
    enc1b <= 0;
    enc2a <= 0;
    enc2b <= 0;
    cnt <= 0;
  end

  reg [3:0] enccntA = 0;
  reg [3:0] enccntB = 4;


  always @(posedge clk)
  begin
    if (!resetn) begin
      cnt <= 0;
      fault[7:2] <= 'b111111;
    end
    faultn <= &fault;
    cnt <= cnt + 1;
    if (cnt <= 20'h85) begin
      enccntA <= enccntA + 1;
      enc1a <= enccntA[3];
      enccntB <= enccntB - 1;
      enc1b <= enccntB[3];
      enc2a <= enc1b;
      enc2b <= enc1a;
    end
    else begin
      cnt <=0;
      enc2a <= ~enc2a;  //Inject fault in encoder 2
      enc2b <= ~enc2b;
    end
  end

  assign {LED0, LED1, LED2, LED3} = count1[3:0];
  assign {LED4, LED5, LED6, LED7} = count2[3:0];


endmodule
