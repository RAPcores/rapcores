`default_nettype none

`include "buildconfig.v"
`include "stepper.v"
`include "spi.v"

module top (
    input  CLK,  // 16MHz clock
    output LED,  // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    `ifdef SPI_INTERFACE
      input  SCK,
      input  CS,
      input  COPI,
      output CIPO,
    `endif
    output PIN_8,  // Phase A
    output PIN_9,  // Phase A
    output PIN_10,  // Phase B
    output PIN_11,  // Phase B
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

  // Word handler
  // The system operates on 32 bit little endian words
  // This should make it easier to send 32 bit chunks from the host controller
  reg [63:0] word_send_data;
  reg [63:0] word_data_received;
  wire word_received;
  SPIWord word_proc (
                .clk(CLK),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received));

  // Stepper Setup
  // TODO: Generate statement?
  reg [2:0] microsteps = 2;
  reg step;
  reg dir;
  DualHBridge s0 (.phase_a1 (PIN_8),
                .phase_a2 (PIN_9),
                .phase_b1 (PIN_10),
                .phase_b2 (PIN_11),
                .step (step),
                .dir (dir),
                .microsteps (microsteps));

  //
  // State Machine for handling SPI Messages
  //

  reg awaiting_more_words = 0;
  reg [7:0] message_word_count = 0;
  reg [7:0] message_header;
  always @(posedge word_received) begin
    LED <= !LED;
    word_send_data[63:0] <= word_data_received[63:0]; // Debug Echo
    if (!awaiting_more_words) begin
      message_header = word_data_received[63:56];
      case (message_header)
        // 0x01 - Coordinated Move
        // Header: 24 bits for direction
        // Word 1: Increment (signed)
        // Word 2: Increment Increment (signed)
        1: begin
          // TODO get direction bits here
          awaiting_more_words <= 1;
          dir <= word_data_received[0];
        end
        // 0x03 - Clock divisor (24 bit)
        3: begin
          clock_divisor[23:0] <= word_data_received[23:0];
          awaiting_more_words <= 0;
        end
        // 0x04 - Set Microstepping
        4: begin
          // TODO needs to be power of two
          microsteps[2:0] <= word_data_received[2:0];
          awaiting_more_words <= 0;
        end
      endcase
    end else begin
      message_word_count = message_word_count + 1;
      case (message_header)
        1: begin
          // the first non-header word is the move duration
          case (message_word_count)
            1: move_duration[63:0] = word_data_received[63:0];
            2: increment[63:0] = word_data_received[63:0];
            3: begin
                incrementincrement[63:0] = word_data_received[63:0];
                message_word_count = 0;
                awaiting_more_words = 0;
                stepping = ~stepping;
                PIN_22 = ~PIN_22;
            end
          endcase
        end
      endcase
    end
  end

  //
  // Stepper Timing Routine
  //

  // coordinated move execution
  // Latching mechanism for engaging the move. This is currently unbuffered, so TODO
  reg stepping = 1;
  reg steplast = 0;

  reg [63:0] move_duration = 64'h0000000004fffff;
  reg [23:0] clock_divisor = 32;  // should be 32 for 500 khz with bresenham

  reg [63:0] tickaccum = 0;  // move accumulator (clock cycles)
  reg [23:0] clkaccum = 0;  // intra-tick accumulator

  reg signed [63:0] substeps = 64'h8000000000000064; // typemin(Int32) - 100 for buffer
  reg [63:0] steps_taken = 0;
  reg signed [63:0] increment_r = 0;
  reg signed [63:0] increment = 100000000000;
  reg signed [63:0] incrementincrement = 1000000000;

  always @(posedge CLK) begin
    if ((stepping ^ steplast) && tickaccum <= move_duration) begin
        clkaccum = clkaccum + 1;
        if (tickaccum == 0) increment_r = increment;
        if (clkaccum[23:0] >= clock_divisor[23:0]) begin
            clkaccum = 0;
            tickaccum = tickaccum + 1;
            increment_r = increment_r + incrementincrement;
            substeps = substeps + increment_r;
            // TODO need to set residency on the signal
            if (substeps >= 0) begin
                step = 1;
                steps_taken = steps_taken + 1;
                substeps = substeps + 64'h8000000000000000;
            end else begin
                 step = 0;
            end
        end
    end else begin
        tickaccum = 0;
        steplast = stepping;
        steps_taken = 0;
        clkaccum = 0;
    end
  end
endmodule
