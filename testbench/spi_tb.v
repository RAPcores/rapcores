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

`include "../src/spi.v"
`timescale 1ns/100ps

module testbench(
    input             clk,
    output             SCK,
    output             CS,
    output            COPI,
    output            CIPO,
    output reg [63:0] word_send_data,
    output            word_received,
    output reg [63:0] word_data_received
  );

  wire CS = 0; // selected
  wire COPI = 0;
  wire CIPO;

  // SCK can't be faster than every two clocks
  reg [1:0] SCK_r = 0;
  wire SCK = (SCK_r == 1'b11);
  always @(posedge clk) SCK_r = SCK_r + 1'b1;

  // Locals
  reg [63:0] word_data_received;
  reg [63:0] word_send_data;

  // TB
  reg [63:0] word_data_tb;



  SPIWord word_proc (
                .clk(clk),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received));

  initial begin
    word_send_data = 64'h00000000005fffff;
    word_data_tb = 64'h00000000deadbeef;
  end

  always @(posedge clk) begin
    //COPI <= word_send_data[1]
  end

endmodule
