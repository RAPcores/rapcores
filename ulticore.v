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
  input step1,
  input step2,
  input step3,
  input step4,
  input step5,
  input step6,
  input step7,
  input step8,
  input dir1,
  input dir2,
  input dir3,
  input dir4,
  input dir5,
  input dir6,
  input dir7,
  input dir8,
  output LED0,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output LED5,
  output LED6,
  output LED7,
  output faultn,
  input [7:0] invert_dir,
  input [7:0] step_active_high
  );

//  reg enc1a, enc1b, enc2a, enc2b;
  wire [31:0] enc_count1, enc_count2, enc_count3, enc_count4, enc_count5, enc_count6, enc_count7, enc_count8;
  wire [31:0] pos_count1, pos_count2, pos_count3, pos_count4, pos_count5, pos_count6, pos_count7, pos_count8;
//  reg resetn;
  wire resetn;
  reg [7:0] resetn_counter = 0;
//  wire faultn;
  wire [7:0] fault;

  assign faultn = &fault;

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end

  quad_enc quad1(.resetn(resetn), .clk(clk), .a(enc1a), .b(enc1b), .count(enc_count1), .faultn(fault[0]));
  quad_enc quad2(.resetn(resetn), .clk(clk), .a(enc2a), .b(enc2b), .count(enc_count2), .faultn(fault[1]));
  quad_enc quad3(.resetn(resetn), .clk(clk), .a(enc3a), .b(enc3b), .count(enc_count3), .faultn(fault[2]));
  quad_enc quad4(.resetn(resetn), .clk(clk), .a(enc4a), .b(enc4b), .count(enc_count4), .faultn(fault[3]));
  quad_enc quad5(.resetn(resetn), .clk(clk), .a(enc5a), .b(enc5b), .count(enc_count5), .faultn(fault[4]));
  quad_enc quad6(.resetn(resetn), .clk(clk), .a(enc6a), .b(enc6b), .count(enc_count6), .faultn(fault[5]));
  quad_enc quad7(.resetn(resetn), .clk(clk), .a(enc7a), .b(enc7b), .count(enc_count7), .faultn(fault[6]));
  quad_enc quad8(.resetn(resetn), .clk(clk), .a(enc8a), .b(enc8b), .count(enc_count8), .faultn(fault[7]));

  pos_counter pos_counter1(.resetn(resetn), .clk(clk), .step(step1), .dir(dir1), .step_active_high(step_active_high[0]), .invert_dir(invert_dir[0]), .count(pos_count1));
  pos_counter pos_counter2(.resetn(resetn), .clk(clk), .step(step2), .dir(dir2), .step_active_high(step_active_high[1]), .invert_dir(invert_dir[1]), .count(pos_count2));
  pos_counter pos_counter3(.resetn(resetn), .clk(clk), .step(step3), .dir(dir3), .step_active_high(step_active_high[2]), .invert_dir(invert_dir[2]), .count(pos_count3));
  pos_counter pos_counter4(.resetn(resetn), .clk(clk), .step(step4), .dir(dir4), .step_active_high(step_active_high[3]), .invert_dir(invert_dir[3]), .count(pos_count4));
  pos_counter pos_counter5(.resetn(resetn), .clk(clk), .step(step5), .dir(dir5), .step_active_high(step_active_high[4]), .invert_dir(invert_dir[4]), .count(pos_count5));
  pos_counter pos_counter6(.resetn(resetn), .clk(clk), .step(step6), .dir(dir6), .step_active_high(step_active_high[5]), .invert_dir(invert_dir[5]), .count(pos_count6));
  pos_counter pos_counter7(.resetn(resetn), .clk(clk), .step(step7), .dir(dir7), .step_active_high(step_active_high[6]), .invert_dir(invert_dir[6]), .count(pos_count7));
  pos_counter pos_counter8(.resetn(resetn), .clk(clk), .step(step8), .dir(dir8), .step_active_high(step_active_high[7]), .invert_dir(invert_dir[7]), .count(pos_count8));


  assign {LED0} = enc_count1[3:3] ^ pos_count1[3:3];
  assign {LED1} = enc_count2[3:3] ^ pos_count2[3:3];
  assign {LED2} = enc_count3[3:3] ^ pos_count3[3:3];
  assign {LED3} = enc_count4[3:3] ^ pos_count4[3:3];
  assign {LED4} = enc_count5[3:3] ^ pos_count5[3:3];
  assign {LED5} = enc_count6[3:3] ^ pos_count6[3:3];
  assign {LED6} = enc_count7[3:3] ^ pos_count7[3:3];
  assign {LED7} = enc_count8[3:3] ^ pos_count8[3:3];

endmodule

