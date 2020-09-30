`default_nettype none

`include "board.v"
`include "buildconfig.v"
`include "configuration.v"
`include "constants.v"
`include "buildconfig.v"
`include "stepper.v"
`include "spi.v"
`include "quad_enc.v"

module top (
    input  CLK,  // 16MHz clock
    output LED,  // User/boot LED next to power LED
    `ifdef tinyfpgabx
      output USBPU,  // USB pull-up resistor
    `endif
    `ifdef SPI_INTERFACE
      input  SCK,
      input  CS,
      input  COPI,
      output CIPO,
    `endif
    output M1_PHASE_A1,  // Phase A
    output M1_PHASE_A2,  // Phase A
    output M1_PHASE_B1,  // Phase B
    output M1_PHASE_B2,  // Phase B
    input ENC1_B,
    input ENC1_A,
);


  // Global Reset (TODO: Make input pin)
  wire reset;
  assign reset = 1;
  `ifdef tinyfpgabx
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
  `endif

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
  reg enable;
  DualHBridge s0 (.phase_a1 (M1_PHASE_A1),
                .phase_a2 (M1_PHASE_A2),
                .phase_b1 (M1_PHASE_B1),
                .phase_b2 (M1_PHASE_B2),
                .step (step),
                .dir (dir),
                .enable (enable),
                .microsteps (microsteps));


  //
  // Encoder
  //
  reg signed [63:0] encoder_count;
  reg signed [63:0] encoder_count_last;
  reg [7:0] encoder_multiplier = 1;
  wire encoder_fault;
  quad_enc encoder0 (
    .resetn(reset),
    .clk(CLK),
    .a(ENC1_A),
    .b(ENC1_B),
    .faultn(encoder_fault),
    .count(encoder_count),
    .multiplier(encoder_multiplier));

  //
  // State Machine for handling SPI Messages
  //

  reg awaiting_more_words = 0;
  reg [7:0] message_word_count = 0;
  reg [7:0] message_header;
  reg [`MOVE_BUFFER_BITS:0] writemoveind = 0;

  always @(posedge word_received) begin
    LED <= !LED;

    // Zero out the next word
    //word_send_data = 0;
    word_send_data[63:0] = encoder_count[63:0]; // Prep to send encoder read

    // Header Processing
    if (!awaiting_more_words) begin

      message_header = word_data_received[63:56]; // Header is 8 MSB

      case (message_header)

        // Coordinated Move
        // Header: 24 bits for direction
        // Word 1: Increment (signed)
        // Word 2: Increment Increment (signed)
        `CMD_COORDINATED_STEP: begin
          // TODO get direction bits here
          awaiting_more_words <= 1;

          dir_r[writemoveind] <= word_data_received[0];

          // Next we send prior ticks
          //word_send_data[63:0] <= tickdowncount_last[63:0]; // Prep to send steps
        end

        // Motor Enable/disable
        `CMD_MOTOR_ENABLE: begin
          enable <= word_data_received[0];
        end

        // Clock divisor (24 bit)
        `CMD_CLK_DIVISOR: begin
          clock_divisor[23:0] <= word_data_received[23:0];
          awaiting_more_words <= 0;
        end

        // Set Microstepping
        `CMD_MICROSTEPS: begin
          // TODO needs to be power of two
          microsteps[2:0] <= word_data_received[2:0];
          awaiting_more_words <= 0;
        end

        // API Version
        `CMD_API_VERSION: begin
          word_send_data[7:0] <= `VERSION_PATCH;
          word_send_data[15:8] <= `VERSION_MINOR;
          word_send_data[23:16] <= `VERSION_MAJOR;
          awaiting_more_words <= 1;
        end
      endcase

    // Addition Word Processing
    end else begin
      message_word_count = message_word_count + 1;
      case (message_header)
        // Move Routine
        `CMD_COORDINATED_STEP: begin
          // the first non-header word is the move duration
          case (message_word_count)
            1: begin
              move_duration[writemoveind][63:0] = word_data_received[63:0];
              //word_send_data[63:0] = last_steps_taken[63:0]; // Prep to send steps
            end
            2: begin
              increment[writemoveind][63:0] = word_data_received[63:0];
              word_send_data[63:0] = encoder_count_last[63:0]; // Prep to send encoder read
            end
            3: begin
                incrementincrement[writemoveind][63:0] = word_data_received[63:0];
                message_word_count = 0;
                awaiting_more_words = 0;
                stepready[writemoveind] = ~stepready[writemoveind];
                writemoveind = writemoveind + 1'b1;
                `ifdef FORMAL
                  assert(writemoveind <= `MOVE_BUFFER_SIZE);
                `endif
            end
          endcase
        end

        // Otherwise we did a single word reply and are now done
        default: awaiting_more_words = 0;

      endcase
    end
  end

  //
  // Stepper Timing Routine
  //

  // coordinated move execution

  reg [`MOVE_BUFFER_BITS:0] moveind = 0; // Move index cursor

  // Latching mechanism for engaging the move. This is currently unbuffered, so TODO
  reg stepready [`MOVE_BUFFER_SIZE:0];
  reg stepfinished [`MOVE_BUFFER_SIZE:0];

  reg [63:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg [23:0] clock_divisor = 40;  // should be 40 for 400 khz at 16Mhz Clk
  reg dir_r [`MOVE_BUFFER_SIZE:0];

  reg [63:0] tickdowncount;  // move down count (clock cycles)
  reg [23:0] clkaccum = 0;  // intra-tick accumulator

  reg signed [63:0] substep_accumulator = 0; // typemax(Int64) - 100 for buffer
  reg signed [63:0] increment_r;
  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0];

  reg finishedmove = 1; // flag inidicating a move has been finished, so load next

  always @(posedge CLK) begin

    // Load up the move duration
    if (finishedmove & (stepfinished[moveind] ^ stepready[moveind])) begin
      tickdowncount = move_duration[moveind];
      finishedmove = 0;
    end

    // check if this move has been done before
    if(!finishedmove & (stepfinished[moveind] ^ stepready[moveind])) begin

      // DDA clock divisor
      clkaccum = clkaccum + 1;
      if (clkaccum[23:0] == clock_divisor[23:0]) begin
        dir = dir_r[moveind]; // set direction
        // TODO For N axes
        increment_r = (tickdowncount == move_duration[moveind]) ? increment[moveind] : increment_r + incrementincrement[moveind];
        substep_accumulator = substep_accumulator + increment_r;
        // TODO need to set residency on the signal
        if (substep_accumulator > 0) begin
          step = 1;
          substep_accumulator = substep_accumulator - 64'h7fffffffffffff9b;
        end else begin
          step = 0;
        end

        // Increment tick accumulators
        clkaccum = 0;
        tickdowncount = tickdowncount - 1'b1;
        encoder_count_last = encoder_count;
        // See if we finished the segment and incrment the buffer
        if(tickdowncount == 0) begin
          stepfinished[moveind] = stepready[moveind];
          moveind = moveind + 1'b1;
          finishedmove = 1;
          `ifdef FORMAL
            assert(moveind <= `MOVE_BUFFER_SIZE);
          `endif
        end
      end
    end
  end
endmodule
