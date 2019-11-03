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

// Parts lifted from picorv32 - regfile

//`include "quad_enc.v"
`timescale 1ns/100ps

module ulticore(
  input clk, 
  input enc1a,
  input enc1b,
  input enc2a,
  input enc2b,
  input enc3a,
  input enc3b,
  input enc4a,
  input enc4b,
  input enc5a,
  input enc5b,
  input enc6a,
  input enc6b,
  input enc7a,
  input enc7b,
  input enc8a,
  input enc8b,
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

//  reg enc1a, enc1b, enc2a, enc2b;
  wire [31:0] count1, count2, count3, count4, count5, count6, count7, count8;
//  reg resetn;
  wire resetn;
  reg [7:0] resetn_counter = 0;
  wire faultn;
  wire [7:0] fault;

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end

  quad_enc quad1(.resetn(resetn), .clk(clk), .a(enc1a), .b(enc1b), .count(count1), .faultn(fault[0]));
  quad_enc quad2(.resetn(resetn), .clk(clk), .a(enc2a), .b(enc2b), .count(count2), .faultn(fault[1]));
  quad_enc quad3(.resetn(resetn), .clk(clk), .a(enc3a), .b(enc3b), .count(count3), .faultn(fault[2]));
  quad_enc quad4(.resetn(resetn), .clk(clk), .a(enc4a), .b(enc4b), .count(count4), .faultn(fault[3]));
  quad_enc quad5(.resetn(resetn), .clk(clk), .a(enc5a), .b(enc5b), .count(count5), .faultn(fault[4]));
  quad_enc quad6(.resetn(resetn), .clk(clk), .a(enc6a), .b(enc6b), .count(count6), .faultn(fault[5]));
  quad_enc quad7(.resetn(resetn), .clk(clk), .a(enc7a), .b(enc7b), .count(count7), .faultn(fault[6]));
  quad_enc quad8(.resetn(resetn), .clk(clk), .a(enc8a), .b(enc8b), .count(count8), .faultn(fault[7]));


  assign {LED0} = count1[3:3];
  assign {LED1} = count2[3:3];
  assign {LED2} = count3[3:3];
  assign {LED3} = count4[3:3];
  assign {LED4} = count5[3:3];
  assign {LED5} = count6[3:3];
  assign {LED6} = count7[3:3];
  assign {LED7} = count8[3:3];

endmodule

