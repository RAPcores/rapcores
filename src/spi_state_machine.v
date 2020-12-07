`default_nettype none


module spi_state_machine(
  input CLK,

  // SPI pins
  input SCK,
  input CS,
  input COPI,
  output CIPO,

  // Step IO
  output step,
  output dir,
  output enable,

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
  //output reg [511:0] cos_table,

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
  `endif
  `ifdef STEPOUTPUT
    output STEPOUTPUT,
    output DIROUTPUT,
  `endif
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
  wire word_received;
  SPIWord word_proc (
                .clk(spi_clock),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received));



  //
  // Stepper Timing Setup
  //

  reg [`MOVE_BUFFER_BITS:0] moveind; // Move index cursor

  // Latching mechanism for engaging the buffered move.
  reg [`MOVE_BUFFER_SIZE:0] stepready;
  reg [`MOVE_BUFFER_SIZE:0] stepfinished;

  reg [63:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg [`MOVE_BUFFER_SIZE:0] dir_r;

  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0];

  reg [7:0] clock_divisor = 40;  // should be 40 for 400 khz at 16Mhz Clk

  // DDA module input wires determined from buffer
  wire [63:0] move_duration_w = move_duration[moveind];
  wire [63:0] increment_w = increment[moveind];
  wire [63:0] incrementincrement_w = incrementincrement[moveind];

  wire dda_step;

  // Implement flow control and event pins if specified
  `ifdef BUFFER_DTR
    assign BUFFER_DTR = ~(~stepfinished == stepready);
  `endif

  `ifndef STEPINPUT
    assign dir = dir_r[moveind]; // set direction
    assign step = dda_step;
  `else
    assign dir = dir_r[moveind] | DIRINPUT; // set direction
    assign step = dda_step | STEPINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
  `endif

  dda_timer dda (.CLK(CLK),
                .clock_divisor(clock_divisor),
                .move_duration(move_duration_w),
                .increment(increment_w),
                .incrementincrement(incrementincrement_w),
                .stepready(stepready),
                .stepfinished(stepfinished),
                .moveind(moveind),
                .writemoveind(writemoveind),
                .step(dda_step),
                `ifdef HALT
                  .halt(HALT),
                `endif
                `ifdef MOVE_DONE
                  .move_done(MOVE_DONE),
                `endif);

  //
  // State Machine for handling SPI Messages
  //

  reg [7:0] message_word_count = 0;
  reg [7:0] message_header;
  reg [`MOVE_BUFFER_BITS:0] writemoveind = 0;

  // Encoder
  reg signed [63:0] encoder_store; // Snapshot for SPI comms

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
        `CMD_COSINE_CONFIG: begin
          //config_cosine_table[word_data_received[35:32]] <= word_data_received[31:0];
          //cos_table[word_data_received[37:32]] <= word_data_received[7:0];
          //cos_table[word_data_received[35:32]+3] <= word_data_received[31:25];
          //cos_table[word_data_received[35:32]+2] <= word_data_received[24:16];
          //cos_table[word_data_received[35:32]+1] <= word_data_received[15:8];
          //cos_table[word_data_received[35:32]] <= word_data_received[7:0];
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



endmodule
