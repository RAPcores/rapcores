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
    input             clk,
    output reg [63:0] word_send_data,
    output            word_received,
    output reg [63:0] word_data_received,
    output COPI_tx,
    output [3:0] bit_count,
    output [3:0] byte_count,
    output step,
    output dir,
    output enable,
  );

  parameter NUMWORDS = 5;

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
  reg [63:0] word_data_received;
  reg [63:0] word_send_data;

  // TB data
  reg [63:0] word_data_mem [NUMWORDS-1:0];
  reg [63:0] word_data_tb;
  reg [7:0] tx_byte;

  // Stepper Config
  wire [2:0] microsteps;
  wire [7:0] current;
  wire [9:0] config_offtime;
  wire [7:0] config_blanktime;
  wire [9:0] config_fastdecay_threshold;
  wire [7:0] config_minimum_on_time;
  wire [10:0] config_current_threshold;
  wire [7:0] config_chargepump_period;
  wire config_invert_highside;
  wire config_invert_lowside;

  wire [63:0] encoder_count;

  wire BUFFER_DTR;
  wire MOVE_DONE;
  wire HALT;
  reg STEPINPUT = 0;
  reg DIRINPUT = 0;
  reg ENINPUT = 0;
  wire STEPOUTPUT;
  wire DIROUTPUT;
  wire ENOUTPUT;

  // SPI 64 bit module
  spi_state_machine spifsm (
    .CLK(clk),
    .resetn(resetn),
    .SCK(SCK),
    .CS(CS),
    .COPI(COPI),
    .CIPO(CIPO),

    .microsteps(microsteps),
    .current(current),
    .config_offtime(config_offtime),
    .config_blanktime(config_blanktime),
    .config_fastdecay_threshold(config_fastdecay_threshold),
    .config_minimum_on_time(config_minimum_on_time),
    .config_current_threshold(config_current_threshold),
    .config_chargepump_period(config_chargepump_period),
    .config_invert_highside(config_invert_highside),
    .config_invert_lowside(config_invert_lowside),

    .encoder_count(encoder_count),

    .step(step),
    .dir(dir),
    .enable(enable),

    `ifdef BUFFER_DTR
      .BUFFER_DTR(BUFFER_DTR),
    `endif
    `ifdef MOVE_DONE
      .MOVE_DONE(MOVE_DONE),
    `endif
    `ifdef HALT
      .HALT(HALT),
    `endif
    `ifdef STEPINPUT
      .STEPINPUT(STEPINPUT),
      .DIRINPUT(DIRINPUT),
      .ENINPUT(ENINPUT),
    `endif
    `ifdef STEPOUTPUT
      .STEPOUTPUT(STEPOUTPUT),
      .DIROUTPUT(DIROUTPUT),
      .ENOUTPUT(ENOUTPUT)
    `endif
  );

  initial begin
    //enable
    word_data_mem[0] = 64'h0a00000000000001;
    //move
    word_data_mem[1] = 64'h0100000000000001;
    word_data_mem[2] = 64'h00000000005fffff;
    word_data_mem[3] = 64'h0100000000000000;
    word_data_mem[4] = 64'h0000000000000000;

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
