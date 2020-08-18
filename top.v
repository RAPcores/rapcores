`default_nettype none

`include "stepper.v"
`include "spi.v"

module top (
    input  CLK,  // 16MHz clock
    output LED,  // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    input  SCK,
    input  SSEL,
    input  MOSI,
    output MISO,
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

  // Word handler
  // The system operates on 32 bit little endian words
  // This should make it easier to send 32 bit chunks from the host controller
  reg [31:0] word_send_data;
  reg [31:0] word_data_received;
  wire word_received;
  SPIWord word_proc (
                .clk(CLK),
                .SCK(SCK),
                .SSEL(SSEL),
                .MOSI(MOSI),
                .MISO(MISO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received));

  // Stepper Setup
  // TODO: Generate statement?
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

  //
  // State Machine for handling SPI Messages
  //

  reg awaiting_more_words = 0;
  reg [7:0] message_word_count = 0;
  reg [7:0] message_header;
  always @(posedge word_received) begin
    LED <= !LED;
    word_send_data[31:0] <= word_data_received[31:0]; // Debug Echo
    if (!awaiting_more_words) begin
      message_header = word_data_received[31:24];
      case (message_header)
        // 0x01 - Coordinated Move
        // Header: 24 bits for direction
        // Word 1: Increment (signed)
        // Word 2: Increment Increment (signed)
        1: begin
          // TODO get direction bits here
          awaiting_more_words <= 1;
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
            1: move_duration[31:0] = word_data_received[31:0];
            2: increment[31:0] = word_data_received[31:0];
            3: begin
                incrementincrement[31:0] = word_data_received[31:0];
                message_word_count = 0;
                awaiting_more_words = 0;
                move_cmd_ready = ~move_cmd_ready;
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
  reg move_cmd_ready = 1;
  reg stepping = 1;
  wire execute_step_timer;
  assign execute_step_timer = move_cmd_ready ^ stepping;

  reg [31:0] move_duration = 32'h04fffff;
  reg [23:0] clock_divisor = 32;  // should be 32 for 500 khz with bresenham

  reg [31:0] clkaccum = 0;  // move accumulator (clock cycles)
  reg [23:0] clkfreq = 0;  // intra-tick accumulator rename clock tick

  reg signed [63:0] stepaccum = 64'h8000000000000064; // typemin(Int32) - 100 for buffer
  reg [31:0] steps_taken = 0;
  reg signed [31:0] increment = 400000000; // always positive
  reg signed [31:0] incrementincrement = 1000000;
  reg signed [31:0] increment_r = 0;


  assign PIN_21 = step;
 assign PIN_24 = move_cmd_ready;
//  assign PIN_23 = steplast;

  always @(posedge CLK) begin
    // step pin residency would go here

    if (move_cmd_ready && clkaccum <= move_duration) begin
        clkfreq = clkfreq + 1;
        if (clkaccum == 0) begin
          increment_r = increment;
        end
        if (clkfreq[23:0] >= clock_divisor[23:0]) begin
            // step -> 0
            clkfreq = 0;
            clkaccum = clkaccum + 1;
            increment_r = increment_r + incrementincrement;
            stepaccum = stepaccum + increment_r;
            // TODO need to set residency on the signal
            if (stepaccum >= 0) begin
                step = 1;
                steps_taken = steps_taken + 1;
                stepaccum = stepaccum + 64'h8000000000000000;
            end else begin
                 step = 0;
            end
            //increment <= increment + incrementincrement;
        end //TODO set DTR for next move, and load from buffer if complete
        // need to keep the residue between moves
        // need to handle direction -> complement. line 527 stepper.cpp
    end else begin
        clkaccum = 0;
        stepping = 0;
        steps_taken = 0;
        clkfreq = 0;
    end
  end
endmodule
