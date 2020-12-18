`timescale 1ns/100ps
module rapcore_harness (
    `ifdef LED
      input wire [`LED:1] LED,
    `endif
    `ifdef tinyfpgabx
      input USBPU,  // USB pull-up resistor
    `endif
    `ifdef SPI_INTERFACE
      output wire SCK,
      output reg CS,
      output wire COPI,
      input wire CIPO,
    `endif
    `ifdef DUAL_HBRIDGE
      input wire [`DUAL_HBRIDGE:1] PHASE_A1,  // Phase A
      input wire [`DUAL_HBRIDGE:1] PHASE_A2,  // Phase A
      input wire [`DUAL_HBRIDGE:1] PHASE_B1,  // Phase B
      input wire [`DUAL_HBRIDGE:1] PHASE_B2,  // Phase B
      input wire [`DUAL_HBRIDGE:1] VREF_A,  // VRef
      input wire [`DUAL_HBRIDGE:1] VREF_B,  // VRef
    `endif
    `ifdef ULTIBRIDGE
      input wire CHARGEPUMP,
      output wire analog_cmp1,
      input wire analog_out1,
      output wire analog_cmp2,
      input wire analog_out2,
      input wire [`ULTIBRIDGE:1] PHASE_A1,  // Phase A
      input wire [`ULTIBRIDGE:1] PHASE_A2,  // Phase A
      input wire [`ULTIBRIDGE:1] PHASE_B1,  // Phase B
      input wire [`ULTIBRIDGE:1] PHASE_B2,  // Phase B
      input wire [`ULTIBRIDGE:1] PHASE_A1_H,  // Phase A
      input wire [`ULTIBRIDGE:1] PHASE_A2_H,  // Phase A
      input wire [`ULTIBRIDGE:1] PHASE_B1_H,  // Phase B
      input wire [`ULTIBRIDGE:1] PHASE_B2_H,  // Phase B
    `endif
    `ifdef QUAD_ENC
      output wire [`QUAD_ENC:1] ENC_B,
      output wire [`QUAD_ENC:1] ENC_A,
    `endif
    `ifdef BUFFER_DTR
      input wire BUFFER_DTR,
    `endif
    `ifdef MOVE_DONE
      input wire MOVE_DONE,
    `endif
    `ifdef HALT
      output reg HALT,
    `endif
    `ifdef STEPINPUT
      output wire STEPINPUT,
      output wire DIRINPUT,
      output wire ENINPUT,
    `endif
    `ifdef STEPOUTPUT
      input wire STEPOUTPUT,
      input wire ENOUTPUT,
      input wire DIROUTPUT,
    `endif
    `ifdef LA_IN
      output wire [`LA_IN:1] LA_IN,
    `endif
    `ifdef LA_OUT
      input wire [`LA_OUT:1] LA_OUT,
    `endif
    `ifdef RESETN
      output resetn_in,
    `endif
    input CLK
);

  parameter NUMWORDS = 5;

  reg hi = 1;
  reg lo = 0;

  assign STEPINPUT = lo;
  assign DIRINPUT = lo;
  assign ENINPUT = lo;
  assign HALT = hi;

  // SCK can't be faster than every two clocks ~ use 4
  reg [1:0] SCK_r = 0;
  assign SCK = (SCK_r == 2'b11 || SCK_r == 2'b10); // even out the wave

  reg initialized = 0;
  wire resetn;
  wire SCKready;
  reg [7:0] resetn_counter = 0;
  reg [8:0] sck_counter = 0;
  assign resetn = resetn_counter == 8'h0f;
  assign SCKready = sck_counter == 9'h1ff;
  always @(posedge CLK) begin
    if (!resetn) resetn_counter <= resetn_counter + 1'b1;
    if (!SCKready) sck_counter <= sck_counter + 1'b1;
  end
  always @(posedge CLK) begin
    if (SCKready) begin // out of reset load times
      SCK_r <= SCK_r + 1'b1;
      if(SCK_r == 2'b11) initialized <= 1; // we want copi to start shifting after first SCK cycle
    end
  end
  assign resetn_in = resetn;

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
  assign COPI = tx_byte[7]; //MSB mode 0

  initial CS <= 0;

  // shift out the bits
  always @(posedge COPI_tx) begin
    tx_byte = {tx_byte[6:0], 1'b0};
    bit_count = bit_count + 1'b1;
    if (bit_count == 4'b1000) begin
      word_data_tb = {8'b0, word_data_tb[63:8]};
      tx_byte = word_data_tb[7:0];
      bit_count = 4'b0;
      byte_count = byte_count + 1'b1;
      if (byte_count == 4'h8) begin
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

  reg         [12:0]  target_current1;
  reg         [12:0]  target_current2;
  reg                 analog_cmp1;
  reg                 analog_cmp2;
  reg         [12:0]  current_abs1;
  reg         [12:0]  current_abs2;
  reg signed  [12:0]  current1;
  reg signed  [12:0]  current2;

  always @(posedge CLK) begin
    if (!resetn) begin
      analog_cmp1 <= 1;
      analog_cmp2 <= 1;
    end
    else begin
      if (current1[12] == 1'b1) begin
        current_abs1 = -current1;
      end
      else begin
        current_abs1 = current1;
      end
      if (current2[12] == 1'b1) begin
        current_abs2 = -current2;
      end
      else begin
        current_abs2 = current2;
      end
      analog_cmp1 <= (current_abs1[11:0] >= target_current1[11:0]); // compare unsigned
      analog_cmp2 <= (current_abs2[11:0] >= target_current2[11:0]);
    end
  end

  pwm_duty duty1(
      .clk(CLK),
      .resetn(resetn),
      .pwm(analog_out1),
      .duty(target_current1)
  );
  pwm_duty duty2(
      .clk(CLK),
      .resetn(resetn),
      .pwm(analog_out2),
      .duty(target_current2)
  );
  hbridge_coil hbridge_coil1(
      .clk(CLK),
      .resetn(resetn),
      .low_1(PHASE_A1[1]),
      .high_1(PHASE_A1_H[1]),
      .low_2(PHASE_A2[1]),
      .high_2(PHASE_A2_H[1]),
      .current(current1),
      .polarity_invert_config(1'b0)
  );
  hbridge_coil hbridge_coil2(
      .clk(CLK),
      .resetn(resetn),
      .low_1(PHASE_B1[1]),
      .high_1(PHASE_B1_H[1]),
      .low_2(PHASE_B2[1]),
      .high_2(PHASE_B2_H[1]),
      .current(current2),
      .polarity_invert_config(1'b0)
  );


endmodule
