`default_nettype none

module spi_state_machine #(
    parameter motor_count = 1,
    parameter move_duration_bits = 32
  )(
  `ifdef LA_IN
    input wire [`LA_IN:1] LA_IN,
  `endif
  `ifdef LA_OUT
    output wire [`LA_OUT:1] LA_OUT,
  `endif

  input resetn,
  // SPI pins
  input  wire SCK,
  input  wire CS,
  input  wire COPI,
  output wire CIPO,

  // Step IO
  output wire [motor_count-1:0] step,
  output wire [motor_count-1:0] dir,
  output wire [motor_count-1:0] enable,
  output wire [motor_count-1:0] brake,

  // Stepper Config
  output reg [7:0] microsteps,
  output reg [7:0] current,
  output reg [9:0] config_offtime,
  output reg [7:0] config_blanktime,
  output reg [9:0] config_fastdecay_threshold,
  output reg [7:0] config_minimum_on_time,
  output reg [10:0] config_current_threshold,
  output reg [7:0] config_chargepump_period,
  output reg config_invert_highside,
  output reg config_invert_lowside,
  //output [511:0] cos_table,

  // encoder
  input [63:0] encoder_count,

  // Event IO
  `ifdef BUFFER_DTR
    output wire BUFFER_DTR,
  `endif
  `ifdef MOVE_DONE
    output wire MOVE_DONE,
  `endif
  `ifdef HALT
    input wire HALT,
  `endif
  `ifdef STEPINPUT
    input wire [motor_count-1:0] STEPINPUT,
    input wire [motor_count-1:0] DIRINPUT,
    input wire [motor_count-1:0] ENINPUT,
  `endif
  `ifdef STEPOUTPUT
    output wire [motor_count-1:0] STEPOUTPUT,
    output wire [motor_count-1:0] DIROUTPUT,
    output wire [motor_count-1:0] ENOUTPUT,
  `endif
  input CLK
);

  `ifdef SPIPLL
    // PLL for SPI Bus
    wire spi_clock;
    wire spipll_locked;
    spi_pll spll (.clock_in(CLK),
                  .clock_out(spi_clock),
                  .locked(spipll_locked));
  `else
    wire spi_clock = CLK;
  `endif

  // Word handler
  // The system operates on 64 bit little endian words
  // This should make it easier to send 64 bit chunks from the host controller
  reg [63:0] word_send_data;
  reg [63:0] word_data_received;

  wire [63:0] word_data_received_w;
  always @(posedge spi_clock)
  if(!resetn)
    word_data_received <= 0;
  else
    word_data_received <= word_data_received_w;

  wire word_received;
  SPIWord word_proc (
                .clk(spi_clock),
                .resetn (resetn),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received_w));


  //
  // Stepper Timing and Buffer Setup
  //

  // Move buffer
  reg [`MOVE_BUFFER_BITS:0] writemoveind;
  wire [`MOVE_BUFFER_BITS:0] moveind; // set via DDA FSM

  // Latching mechanism for engaging the buffered move.
  // the DDA side is internal to dda_fsm
  reg [`MOVE_BUFFER_SIZE:0] stepready;

  reg [motor_count:1] dir_r [`MOVE_BUFFER_SIZE:0];

  reg [move_duration_bits-1:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0][motor_count-1:0];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0][motor_count-1:0];

  // DDA module input wires determined from buffer
  wire [move_duration_bits-1:0] move_duration_w = move_duration[moveind];

  // Per-axis DDA parameters
  wire [63:0] increment_w [motor_count-1:0];
  wire [63:0] incrementincrement_w [motor_count-1:0];

  genvar i;
  for (i=0; i<motor_count; i=i+1) begin
    assign increment_w[i] = increment[moveind][i];
    assign incrementincrement_w[i] = incrementincrement[moveind][i];
  end

  wire dda_tick;
  reg [7:0] clock_divisor;  // should be 40 for 400 khz at 16Mhz Clk

  // Step IO
  wire [motor_count-1:0] dda_step;
  reg [motor_count-1:0] enable_r;

  // Motor Brake
  reg [motor_count-1:0] brake_r;
  assign brake[motor_count-1:0] = brake_r;

  `ifndef STEPINPUT
    assign dir[motor_count-1:0] = dir_r[moveind]; // set direction
    assign step[motor_count-1:0] = dda_step;
    assign enable[motor_count-1:0] = enable_r;
  `else
    assign dir[motor_count-1:0] = dir_r[moveind] ^ DIRINPUT; // set direction
    assign step[motor_count-1:0] = dda_step ^ STEPINPUT;
    assign enable[motor_count-1:0] = enable_r | ENINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  wire loading_move;
  wire executing_move;
  wire move_done;
  wire buffer_dtr;

  // Buffer sync events
  `ifdef MOVE_DONE
    assign MOVE_DONE = move_done;
  `endif
  `ifdef BUFFER_DTR
    assign BUFFER_DTR = buffer_dtr;
  `endif

  //
  // DDA Setup
  //

  // Clock divider used to continually make DDA ticks
  clock_divider #(.divider_bits(8)) cd0
  (
    .resetn(resetn),
    .divider(clock_divisor),
    .tick(dda_tick),
    .clk(CLK)
  );

  // DDA FSM for duration and buffer state managment
  dda_fsm #(.buffer_bits(`MOVE_BUFFER_BITS+1),
            .buffer_size(`MOVE_BUFFER_SIZE+1),
            .move_duration_bits(move_duration_bits)) ddam0 (
    .clk(CLK),
    .resetn(resetn),
    .dda_tick(dda_tick),
    .loading_move(loading_move),
    .move_duration(move_duration_w),
    .executing_move(executing_move),
    .move_done(move_done),
    .stepready(stepready),
    .buffer_dtr(buffer_dtr),
    .moveind(moveind)
  );

  // N dda timers per axis
  generate
    for (i=0; i<motor_count; i=i+1) begin
      dda_timer ddan (
                    .resetn(resetn),
                    .dda_tick(dda_tick),
                    .increment(increment_w[i]),
                    .incrementincrement(incrementincrement_w[i]),
                    .loading_move(loading_move),
                    .executing_move(executing_move),
                    .step(dda_step[i]),
                    .CLK(CLK)
                    );
  end
  endgenerate

  //
  // Encoders
  //

  wire [31:0] step_encoder [motor_count-1:0];

  generate
    for (i=0; i<motor_count; i=i+1) begin
      step_encoder #(.width(32)) senc0 (
                    .resetn(resetn),
                    .clk(CLK),
                    .step(step[i]),
                    .dir(dir[i]),
                    .count(step_encoder[i])
                    );
  end
  endgenerate



  //
  // State Machine for handling SPI Messages
  //

  reg [7:0] message_word_count;
  reg [7:0] message_header;

  // Encoder
  reg signed [63:0] encoder_store [motor_count-1:0]; // Snapshot for SPI comms
  reg signed [63:0] step_encoder_store [motor_count-1:0]; // Snapshot for SPI comms

  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = (message_header == `CMD_COORDINATED_STEP) |
                             (message_header == `CMD_API_VERSION);
  reg [1:0] word_received_r;

  reg [7:0] nmot;

  always @(posedge CLK) if (!resetn) begin
    // Stepper Config
    microsteps <= 2;
    current <= 140;
    config_offtime <= 810;
    config_blanktime <= 27;
    config_fastdecay_threshold <= 706;
    config_minimum_on_time <= 54;
    config_current_threshold <= 1024;
    config_chargepump_period <= 91;
    config_invert_highside <= `DEFAULT_BRIDGE_INVERTING;
    config_invert_lowside <= `DEFAULT_BRIDGE_INVERTING;
    enable_r <= {(motor_count){1'b0}};

    word_send_data <= 0;

    writemoveind <= 0;  // Move buffer
    stepready <= 0;  // Latching mechanism for engaging the buffered move.

    // TODO fix this
    dir_r[0] <= {(motor_count){1'b0}};
    dir_r[1] <= {(motor_count){1'b0}};

    brake_r <= 0;

    clock_divisor <= 40;  // should be 40 for 400 khz at 16Mhz Clk
    message_word_count <= 0;
    message_header <= 0;

    word_received_r <= 2'b0;

    // TODO change to for loops for buffer
    move_duration[0] <= 0;
    move_duration[1] <= 0;

    /* verilator lint_off WIDTH */
    for (nmot=0; nmot<motor_count; nmot=nmot+1) begin
      increment[0][nmot] <= 64'b0;
      increment[1][nmot] <= 64'b0;
      incrementincrement[0][nmot] <= 64'b0;
      incrementincrement[1][nmot] <= 64'b0;
  
      // Encoders
      step_encoder_store[nmot] <= 0;
      encoder_store[nmot] <= 0;
    end
    /* verilator lint_off WIDTH */

  end else if (resetn) begin
    word_received_r <= {word_received_r[0], word_received};
    if (word_received_r == 2'b01) begin
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
            dir_r[writemoveind] <= word_data_received[motor_count-1:0];

            // Store encoder values across all axes
            for (nmot=0; nmot<motor_count; nmot=nmot+1) begin
              step_encoder_store[nmot] <= step_encoder[nmot];
            end

          end

          // Motor Enable/disable
          `CMD_MOTOR_ENABLE: begin
            enable_r[motor_count-1:0] <= word_data_received[motor_count-1:0];
          end

          // Motor Brake on Disable
          `CMD_MOTOR_BRAKE: begin
            brake_r[motor_count-1:0] <= word_data_received[motor_count-1:0];
          end

          // Clock divisor (24 bit)
          `CMD_CLK_DIVISOR: begin
            clock_divisor[7:0] <= word_data_received[7:0];
          end

          // Set Microstepping
          `CMD_MOTORCONFIG: begin
            // TODO needs to be power of two
            current[7:0] <= word_data_received[15:8];
            microsteps[2:0] <= word_data_received[2:0];
          end

          // Set Microstepping Parameters
          `CMD_MICROSTEPPER_CONFIG: begin
            config_offtime[9:0] <= word_data_received[39:30];
            config_blanktime[7:0] <= word_data_received[29:22];
            config_fastdecay_threshold[9:0] <= word_data_received[21:12];
            config_minimum_on_time[7:0] <= word_data_received[18:11];
            config_current_threshold[10:0] <= word_data_received[10:0];
          end

          // Set chargepump period
          `CMD_CHARGEPUMP: begin
            config_chargepump_period[7:0] <= word_data_received[7:0];
          end

          // Invert Bridge outputs
          `CMD_BRIDGEINVERT: begin
            config_invert_highside <= word_data_received[1];
            config_invert_lowside <= word_data_received[0];
          end

          // Write to Cosine Table
          // TODO Cosine Net is broken
          //`CMD_COSINE_CONFIG: begin
            //cos_table[word_data_received[35:32]] <= word_data_received[31:0];
            //cos_table[word_data_received[37:32]] <= word_data_received[7:0];
            //cos_table[word_data_received[35:32]+3] <= word_data_received[31:25];
            //cos_table[word_data_received[35:32]+2] <= word_data_received[24:16];
            //cos_table[word_data_received[35:32]+1] <= word_data_received[15:8];
            //cos_table[word_data_received[35:32]] <= word_data_received[7:0];
          //end

          // API Version
          `CMD_API_VERSION: begin
            word_send_data[7:0] <= `VERSION_PATCH;
            word_send_data[15:8] <= `VERSION_MINOR;
            word_send_data[23:16] <= `VERSION_MAJOR;
            word_send_data[31:24] <= `VERSION_DEVEL;
          end

          default: word_send_data <= 64'b0;

        endcase

      // Addition Word Processing
      end else begin

        message_word_count <= message_word_count + 1;

        case (message_header)
          // Move Routine
          `CMD_COORDINATED_STEP: begin
            // Multiaxis
            for (nmot=0; nmot<motor_count; nmot=nmot+1) begin
              // the first non-header word is the move duration
              if (nmot == 0) begin
                if (message_word_count == 1) begin
                  move_duration[writemoveind][move_duration_bits-1:0] <= word_data_received[move_duration_bits-1:0];
                  word_send_data <= step_encoder_store[0]; // Prep to send steps
                end
              end

              if (message_word_count == (nmot+1)*2) begin
                increment[writemoveind][nmot][63:0] <= word_data_received[63:0];
                word_send_data <= encoder_store[nmot]; // Prep to send steps
              end
              if (message_word_count == (nmot+1)*2+1) begin
                incrementincrement[writemoveind][nmot][63:0] <= word_data_received[63:0];
                if (nmot != motor_count-1) word_send_data <= step_encoder_store[nmot+1]; // Prep to send steps

                if (nmot == motor_count-1) begin
                  writemoveind <= writemoveind + 1'b1;
                  stepready[writemoveind] <= ~stepready[writemoveind];
                  message_header <= 8'b0; // Reset Message Header at the end
                  message_word_count <= 0;
                end
                `ifdef FORMAL
                  assert(writemoveind <= `MOVE_BUFFER_SIZE);
                `endif
              end
            end
          end // `CMD_COORDINATED_STEP
          // by default reset the message header if it was a two word transaction
          default: message_header <= 8'b0; // Reset Message Header
        endcase
      end
    end
  end

  // Macro external wiring statements here
  `ifdef STATE_MACHINE_LA
    `STATE_MACHINE_LA
  `endif


endmodule
