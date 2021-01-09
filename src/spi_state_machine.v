`default_nettype none

module spi_state_machine #(
    parameter motor_count = 1
  )(
  `ifdef LA_IN
    input wire [`LA_IN:1] LA_IN,
  `endif
  `ifdef LA_OUT
    output wire [`LA_OUT:1] LA_OUT,
  `endif

  input resetn,
  // SPI pins
  input SCK,
  input CS,
  input COPI,
  output CIPO,

  // Step IO
  output wire [motor_count:1] step,
  output wire [motor_count:1] dir,
  output wire [motor_count:1] enable,

  // Stepper Config
  output reg [2:0] microsteps,
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
    output BUFFER_DTR,
  `endif
  `ifdef MOVE_DONE
    output MOVE_DONE,
  `endif
  `ifdef HALT
    input HALT,
  `endif
  `ifdef STEPINPUT
    input STEPINPUT,
    input DIRINPUT,
    input ENINPUT,
  `endif
  `ifdef STEPOUTPUT
    output STEPOUTPUT,
    output DIROUTPUT,
    output ENOUTPUT,
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
  wire [`MOVE_BUFFER_BITS:0] moveind; // set via DDA

  // Latching mechanism for engaging the buffered move.
  reg [`MOVE_BUFFER_SIZE:0] stepready;
  wire [`MOVE_BUFFER_SIZE:0] stepfinished; // set via DDA

  reg [`MOVE_BUFFER_SIZE:0] dir_r [motor_count:1];

  reg [63:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0][motor_count:1];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0][motor_count:1];

  // DDA module input wires determined from buffer
  wire [63:0] move_duration_w = move_duration[moveind];

  // Per-axis DDA parameters
  wire [63:0] increment_w [motor_count:1];
  wire [63:0] incrementincrement_w [motor_count:1];

  genvar i;
  for (i=1; i<=motor_count; i=i+1) begin
    assign increment_w[i] = increment[moveind][i];
    assign incrementincrement_w[i] = incrementincrement[moveind][i];
  end

  reg [7:0] clock_divisor;  // should be 40 for 400 khz at 16Mhz Clk

  // Step IO
  wire [motor_count:1] dda_step;
  reg [motor_count:1] enable_r;

  // Implement flow control and event pins if specified
  `ifdef BUFFER_DTR
    assign BUFFER_DTR = ~(~stepfinished == stepready);
  `endif

  `ifndef STEPINPUT
    generate 
      for (i=1; i<=motor_count; i=i+1) begin
        assign dir[i] = dir_r[i][moveind]; // set direction
      end
    endgenerate
    assign step[motor_count:1] = dda_step[motor_count:1];
    assign enable[motor_count:1] = enable_r[motor_count:1];
  `else
    assign dir = dir_r[moveind] ^ DIRINPUT; // set direction
    assign step = dda_step ^ STEPINPUT;
    assign enable = enable_r | ENINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  generate
    for (i=1; i<=motor_count; i=i+1) begin
      if (i == 1) begin
        dda_timer dda0 (
                      .resetn(resetn),
                      .clock_divisor(clock_divisor),
                      .move_duration(move_duration_w),
                      .increment(increment_w[i]),
                      .incrementincrement(incrementincrement_w[i]),
                      .stepready(stepready),
                      .stepfinished(stepfinished), // only need on one mod
                      .moveind(moveind),
                      .writemoveind(writemoveind),
                      .step(dda_step[i]),
                      `ifdef HALT
                        .halt(HALT),
                      `endif
                      `ifdef MOVE_DONE
                        .move_done(MOVE_DONE),
                      `endif
                      .CLK(CLK)
                      );
      end else begin
        // only drive MOVE_DONE and moveind from the first DDA
        dda_timer ddan (
                      .resetn(resetn),
                      .clock_divisor(clock_divisor),
                      .move_duration(move_duration_w),
                      .increment(increment_w[i]),
                      .incrementincrement(incrementincrement_w[i]),
                      .stepready(stepready),
                      .writemoveind(writemoveind),
                      .step(dda_step[i]),
                      `ifdef HALT
                        .halt(HALT),
                      `endif
                      .CLK(CLK)
                      );
      end
    end
  endgenerate

  //
  // State Machine for handling SPI Messages
  //

  reg [7:0] message_word_count;
  reg [7:0] message_header;

  // Encoder
  reg signed [63:0] encoder_store; // Snapshot for SPI comms

  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = (message_header == `CMD_COORDINATED_STEP) |
                             (message_header == `CMD_API_VERSION);
  reg [1:0] word_received_r;

  reg [4:0] nmot;

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

    for (nmot=1; nmot<=motor_count; nmot=nmot+1) begin
      dir_r[nmot] <= {(`MOVE_BUFFER_SIZE+1){1'b0}};
    end

    clock_divisor <= 40;  // should be 40 for 400 khz at 16Mhz Clk
    message_word_count <= 0;
    message_header <= 0;

    word_received_r <= 2'b0;

    // TODO change to for loops for buffer
    move_duration[0] <= 64'b0;
    move_duration[1] <= 64'b0;

    for (nmot=1; nmot<=motor_count; nmot=nmot+1) begin
      increment[0][nmot] <= 64'b0;
      increment[1][nmot] <= 64'b0;
      incrementincrement[0][nmot] <= 64'b0;
      incrementincrement[1][nmot] <= 64'b0;
    end

    encoder_store <= 64'b0;

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
            dir_r[writemoveind] <= word_data_received[motor_count:0];

            // Store encoder values across all axes Now
            encoder_store <= encoder_count;

          end

          // Motor Enable/disable
          `CMD_MOTOR_ENABLE: begin
            enable_r <= word_data_received[motor_count-1:0];
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
            for (nmot=1; nmot<=motor_count; nmot=nmot+1) begin
              // the first non-header word is the move duration
              if (nmot == 1) begin
                if (message_word_count == 1) begin
                  move_duration[writemoveind][63:0] <= word_data_received[63:0];
                  //word_send_data[63:0] <= last_steps_taken[63:0]; // Prep to send steps
                end
              end

              if (message_word_count == nmot*2) begin
                increment[writemoveind][nmot][63:0] <= word_data_received[63:0];
                word_send_data[63:0] <= encoder_store[63:0]; // Prep to send encoder read
              end
              if (message_word_count == nmot*2+1) begin
                incrementincrement[writemoveind][nmot][63:0] <= word_data_received[63:0];

                if (nmot == motor_count) begin
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
