`default_nettype none

`include "generated/board.v"
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
    `ifdef BUFFER_DTR
      output BUFFER_DTR,
    `endif
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
  wire step;
  wire dir;
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
  reg signed [63:0] encoder_store; // Snapshot for SPI comms
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

  reg [7:0] message_word_count = 0;
  reg [7:0] message_header;
  reg [`MOVE_BUFFER_BITS:0] writemoveind = 0;

  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = (message_header == `CMD_COORDINATED_STEP) |
                             (message_header == `CMD_API_VERSION);

  always @(posedge word_received) begin

    // Zero out send data register
    word_send_data <= 64'b0;

    // Header Processing
    if (!awaiting_more_words) begin

      // Save CMD header incase multi word transaction
      message_header <= word_data_received[63:56]; // Header is 8 MSB

      // First word so message count zero
      message_word_count <= 1;

      case (word_data_received[63:56])

        // Coordinated Move
        `CMD_COORDINATED_STEP: begin

          // Get Direction Bits
          dir_r[writemoveind] <= word_data_received[0];

          // Store encoder values across all axes Now
          encoder_store <= encoder_count;

        end

        // Motor Enable/disable
        `CMD_MOTOR_ENABLE: begin
          enable <= word_data_received[0];
        end

        // Clock divisor (24 bit)
        `CMD_CLK_DIVISOR: begin
          clock_divisor[7:0] <= word_data_received[7:0];
        end

        // Set Microstepping
        `CMD_MICROSTEPS: begin
          // TODO needs to be power of two
          microsteps[2:0] <= word_data_received[2:0];
        end

        // API Version
        `CMD_API_VERSION: begin
          word_send_data[7:0] <= `VERSION_PATCH;
          word_send_data[15:8] <= `VERSION_MINOR;
          word_send_data[23:16] <= `VERSION_MAJOR;
        end
      endcase

    // Addition Word Processing
    end else begin

      message_word_count <= message_word_count + 1;

      case (message_header)
        // Move Routine
        `CMD_COORDINATED_STEP: begin
          // the first non-header word is the move duration
          case (message_word_count)
            1: begin
              move_duration[writemoveind][63:0] <= word_data_received[63:0];
              //word_send_data[63:0] = last_steps_taken[63:0]; // Prep to send steps
            end
            2: begin
              increment[writemoveind][63:0] <= word_data_received[63:0];
              word_send_data[63:0] <= encoder_store[63:0]; // Prep to send encoder read
            end
            3: begin
                incrementincrement[writemoveind][63:0] <= word_data_received[63:0];
                message_word_count <= 0;
                stepready[writemoveind] <= ~stepready[writemoveind];
                writemoveind <= writemoveind + 1'b1;
                message_header <= 8'b0; // Reset Message Header
                `ifdef FORMAL
                  assert(writemoveind <= `MOVE_BUFFER_SIZE);
                `endif
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

  reg [`MOVE_BUFFER_BITS:0] moveind = 0; // Move index cursor

  // Latching mechanism for engaging the move. This is currently unbuffered, so TODO
  reg [`MOVE_BUFFER_SIZE:0] stepready;
  reg [`MOVE_BUFFER_SIZE:0] stepfinished;

  reg [63:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg [7:0] clock_divisor = 40;  // should be 40 for 400 khz at 16Mhz Clk
  reg [`MOVE_BUFFER_SIZE:0] dir_r;

  reg [63:0] tickdowncount;  // move down count (clock cycles)
  reg [7:0] clkaccum = 8'b1;  // intra-tick accumulator

  reg signed [63:0] substep_accumulator = 0; // typemax(Int64) - 100 for buffer
  reg signed [63:0] increment_r;
  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0];

  reg finishedmove = 1; // flag inidicating a move has been finished, so load next
  wire processing_move = (stepfinished[moveind] ^ stepready[moveind]);
  wire loading_move = finishedmove & processing_move;
  wire executing_move = !finishedmove & processing_move;

  `ifdef BUFFER_DTR
    assign BUFFER_DTR = ~(~stepfinished == stepready);
  `endif

  assign dir = dir_r[moveind]; // set direction
  assign step = (substep_accumulator > 0);

  always @(posedge CLK) begin

    // Load up the move duration
    if (loading_move) begin
      tickdowncount <= move_duration[moveind];
      finishedmove <= 0;
      increment_r <= increment[moveind];
    end

    // check if this move has been done before
    if(executing_move) begin

      // Step taken, rollback accumulator
      if (substep_accumulator > 0) begin
        substep_accumulator <= substep_accumulator - 64'h7fffffffffffff9b;
      end

      // DDA clock divisor
      clkaccum <= clkaccum - 8'b1;
      if (clkaccum == 8'b0) begin

        increment_r <= increment_r + incrementincrement[moveind];
        substep_accumulator <= substep_accumulator + increment_r;

        // Increment tick accumulators
        clkaccum <= clock_divisor;
        tickdowncount <= tickdowncount - 1'b1;
        // See if we finished the segment and incrment the buffer
        if(tickdowncount == 0) begin
          stepfinished[moveind] <= ~stepfinished[moveind];
          moveind <= moveind + 1'b1;
          finishedmove <= 1;
          `ifdef FORMAL
            assert(moveind <= `MOVE_BUFFER_SIZE);
          `endif
        end
      end
    end
  end
endmodule
