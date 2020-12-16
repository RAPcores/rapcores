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
    output reg [63:0] word_send_data,
    output            word_received,
    output reg [63:0] word_data_received,
    output COPI_tx,
    output [3:0] bit_count,
    output [3:0] byte_count
  );

  wire CS = 0; // selected
  wire CIPO; // readback tbd

  // SCK can't be faster than every two clocks ~ use 4
  reg [1:0] SCK_r = 0;
  wire SCK;
  assign SCK = (SCK_r == 2'b11 || SCK_r == 2'b10);
  reg initialized = 0;
  always @(posedge clk) begin
    SCK_r <= SCK_r + 1'b1;
    if(SCK_r == 2'b11) initialized <= 1; // we want copi to start shifting after first SCK cycle
  end

  // COPI trigger 1/4 clk before SCK posedge
  wire COPI_tx;
  assign COPI_tx = (SCK_r == 2'b01) && initialized;

  // Locals
  reg [63:0] word_data_received;
  reg [63:0] word_send_data;

  wire COPI;

  // TB data
  reg [63:0] word_data_tb;
  reg [7:0] tx_byte;

  // SPI 64 bit module
  SPIWord word_proc (
                .clk(clk),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received));

  //reg [7:0] tx_byte;

  reg [3:0] bit_count;

  initial begin
    word_send_data = 64'h00000000005fffff;
    word_data_tb = 64'hbeefdeaddeadbeef;
    tx_byte = word_data_tb[7:0];
  end

  reg [3:0] bit_count = 4'b0;
  assign COPI = tx_byte[7];
  reg started = 0;

  always @(posedge COPI_tx) begin
    //if (started) begin
      tx_byte = {tx_byte[6:0], 1'b0};
      bit_count = bit_count + 1'b1;
      if (bit_count == 4'b1000) begin
        word_data_tb = {8'b0, word_data_tb[63:8]};
        tx_byte = word_data_tb[7:0];
        bit_count = 4'b0;
      end
    //end else started = 1;
  end

endmodule
