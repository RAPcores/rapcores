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

  parameter NUMWORDS = 3;

  reg CS = 0; // selected
  wire CIPO; // readback tbd

  // SCK can't be faster than every two clocks ~ use 4
  reg [1:0] SCK_r = 0;
  wire SCK;
  assign SCK = (SCK_r == 2'b11 || SCK_r == 2'b10); // even out the wave

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

  // TB data
  reg [63:0] word_data_mem [NUMWORDS-1:0];
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

  initial begin
    word_send_data = 64'h00000000005fffff;
    word_data_mem[0] = 64'hbeefdeaddeadbeef;
    word_data_mem[1] = 64'h00000000005fffff;
    word_data_mem[2] = 64'h00000110a0000000;

    word_data_tb = word_data_mem[0];
    tx_byte = word_data_tb[7:0];
  end

  reg [3:0] bit_count = 4'b0;
  reg [3:0] byte_count = 4'b0;
  reg [3:0] word_count = 4'b0;
  wire COPI = tx_byte[7]; //MSB mode 0

  // shift out the bits
  always @(posedge COPI_tx) begin
    tx_byte = {tx_byte[6:0], 1'b0};
    bit_count = bit_count + 1'b1;
    if (bit_count == 4'b1000) begin
      word_data_tb = {8'b0, word_data_tb[63:8]};
      tx_byte = word_data_tb[7:0];
      bit_count = 4'b0;
      byte_count = byte_count + 1'b1;
      if (byte_count == 4'h08) begin
        word_count = word_count + 1'b1;
        if (word_count <= NUMWORDS-1) begin
          word_data_tb = word_data_mem[word_count];
        end else begin
          CS <= 1; // deselect
        end
        byte_count = 8'b0;
      end
    end
  end

endmodule
