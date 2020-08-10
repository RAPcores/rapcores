`default_nettype none

`include "stepper.v"
`include "spi.v"

module top (
    input  CLK,  // 16MHz clock
    output LED,  // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    input  PIN_1,
    input  PIN_2,
    input  PIN_3,
    output PIN_4,
    output PIN_8,  // Phase A
    output PIN_9,  // Phase A
    output PIN_11,  // Phase B
    output PIN_12,  // Phase B
    output PIN_24,
    output PIN_23,
    output PIN_22,
    output PIN_21,
    output PIN_20,
    output PIN_18,
    output PIN_19,
    output PIN_7,
    output PIN_13
);

  // drive USB pull-up resistor to '0' to disable USB
  assign USBPU = 0;

  // SPI Initialization
  // The standard unit of transfer is 8 bits, MSB
  reg byte_received;  // high when a byte has been received
  reg [7:0] byte_data_received;
  reg [7:0] spi_send_data;
  SPI spi0 (.clk(CLK),
        .SCK(PIN_1),
        .SSEL(PIN_2),
        .MOSI(PIN_3),
        .MISO(PIN_4),
        .send_data(spi_send_data),
        .byte_received(byte_received),
        .byte_data_received(byte_data_received) );

  // Word handler
  // The system operates on 32 bit little endian words
  // This should make it easier to send 32 bit chunks from the host controller
  reg [31:0] word_send_data;
  reg [31:0] word_data_received;
  reg word_received;
  spi_packet word_proc (
                .clk(CLK),
                .send_data(spi_send_data),
                .word_send_data(word_send_data),
                .byte_received(byte_received),
                .word_received(word_received),
                .byte_data_received(byte_data_received),
                .word_data_received(word_data_received));

  // Stepper Setup
  // TODO: Generate statement?
  reg [23:0] move_duration;
  reg move_start = 0;
  reg [23:0] clock_divisor = 24'd50000;
  reg [2:0] microsteps = 1;
  reg step;
  reg dir;
  DualHBridge s0 (.phase_a1 (PIN_8),
                .phase_a2 (PIN_9),
                .phase_b1 (PIN_11),
                .phase_b2 (PIN_12),
                .pwm_a (PIN_7),
                .pwm_b (PIN_13),
                .step (step),
                .dir (dir),
                .microsteps (microsteps));



  always @(posedge word_received) begin
    LED <= !LED;
    case (word_data_received[31:24])
      1: begin
        PIN_21 <= ~PIN_21;
        move_duration[23:0] = word_data_received[23:0];
        move_start = 1;
      end
      3: begin
        clock_divisor[23:0] <= word_data_received[23:0];
      end
      4: begin
        // TODO needs to be power of two
        microsteps[2:0] <= word_data_received[2:0];
      end
    endcase
    PIN_23 <= word_data_received[1];
    PIN_22 <= word_data_received[2];
    word_send_data[31:0] = word_data_received[31:0];
  end

  reg step_clock;
  reg [31:0] clkaccum = 0;
  always @(posedge CLK) begin
    if (clkaccum[23:0] >= clock_divisor[23:0]) begin
      step <= 1;
      clkaccum <= 0;
    end
    else begin
      clkaccum <= clkaccum + 1;
      step <= 0;
    end
  end

endmodule
