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

module testbench #(parameter SPIBITS = 32)(
    input             clk,
    output reg [SPIBITS-1:0] word_send_data,
    output            word_received,
    output reg [SPIBITS-1:0] word_data_received,
    output COPI_tx,
    output [3:0] bit_count,
    output [3:0] byte_count
  );

  parameter NUMWORDS = 3;
  localparam NUMBYTES = SPIBITS/8;

  reg CS = 0; // selected
  wire CIPO; // readback tbd

  // SCK can't be faster than every two clocks ~ use 4
  reg [1:0] SCK_r = 0;
  wire SCK;
  assign SCK = (SCK_r == 2'b11 || SCK_r == 2'b10); // even out the wave

  reg initialized = 0;
  wire resetn;
  reg [7:0] resetn_counter = 0;
  assign resetn = (resetn_counter == 8'hff);
  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter + 1'b1;
  end
  always @(posedge clk) begin
    if (resetn) begin // out of reset load times
      SCK_r <= SCK_r + 1'b1;
      if(SCK_r == 2'b11) initialized <= 1; // we want copi to start shifting after first SCK cycle
    end
  end

  // COPI trigger 1/4 clk before SCK posedge
  wire COPI_tx;
  assign COPI_tx = (SCK_r == 2'b01) && initialized;

  // Locals
  reg [SPIBITS-1:0] word_data_received;
  reg [SPIBITS-1:0] word_send_data;

  // TB data
  reg [SPIBITS-1:0] word_data_mem [NUMWORDS-1:0];
  reg [SPIBITS-1:0] word_data_tb;
  reg [7:0] tx_byte;

  // SPI 64 bit module
  SPI #(.word_bits(SPIBITS)) word_proc (
                .clk(clk),
                .resetn(resetn),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .tx_byte(word_send_data),
                .rx_byte(word_received),
                .rx_byte_ready(word_data_received));

  initial begin
    if (SPIBITS == 64) begin
      word_send_data = 64'h00000000005fffff;
      word_data_mem[0] = 64'hbeefdeaddeadbeef;
      word_data_mem[1] = 64'h00000000005fffff;
      word_data_mem[2] = 64'h00000110a0000000;
    end else if (SPIBITS == 32) begin
      word_send_data = 32'h005fffff;
      word_data_mem[0] = 32'hdeadbeef;
      word_data_mem[1] = 32'h005fffff;
      word_data_mem[2] = 32'ha0000000;
    end
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
      word_data_tb = {8'b0, word_data_tb[SPIBITS-1:8]};
      tx_byte = word_data_tb[7:0];
      bit_count = 4'b0;
      byte_count = byte_count + 1'b1;
      if (byte_count == NUMBYTES) begin
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
