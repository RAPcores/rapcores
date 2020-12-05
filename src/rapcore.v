`default_nettype none

module rapcore (
    input  CLK,
    `ifdef LED
      output wire [`LED:1] LED,
    `endif
    `ifdef tinyfpgabx
      output USBPU,  // USB pull-up resistor
    `endif
    `ifdef SPI_INTERFACE
      input  SCK,
      input  CS,
      input  COPI,
      output CIPO,
    `endif
    `ifdef DUAL_HBRIDGE
      output wire [`DUAL_HBRIDGE:1] PHASE_A1,  // Phase A
      output wire [`DUAL_HBRIDGE:1] PHASE_A2,  // Phase A
      output wire [`DUAL_HBRIDGE:1] PHASE_B1,  // Phase B
      output wire [`DUAL_HBRIDGE:1] PHASE_B2,  // Phase B
      output wire [`DUAL_HBRIDGE:1] VREF_A,  // VRef
      output wire [`DUAL_HBRIDGE:1] VREF_B,  // VRef
    `endif
    `ifdef ULTIBRIDGE
      output CHARGEPUMP,
      input analog_cmp1,
      output analog_out1,
      input analog_cmp2,
      output analog_out2,
      output wire [`ULTIBRIDGE:1] PHASE_A1,  // Phase A
      output wire [`ULTIBRIDGE:1] PHASE_A2,  // Phase A
      output wire [`ULTIBRIDGE:1] PHASE_B1,  // Phase B
      output wire [`ULTIBRIDGE:1] PHASE_B2,  // Phase B
      output wire [`ULTIBRIDGE:1] PHASE_A1_H,  // Phase A
      output wire [`ULTIBRIDGE:1] PHASE_A2_H,  // Phase A
      output wire [`ULTIBRIDGE:1] PHASE_B1_H,  // Phase B
      output wire [`ULTIBRIDGE:1] PHASE_B2_H,  // Phase B
    `endif
    `ifdef QUAD_ENC
      input [`QUAD_ENC:1] ENC_B,
      input [`QUAD_ENC:1] ENC_A,
    `endif
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

  // Global Reset (TODO: Make input pin)
  //wire reset;
  //assign reset = 1;
  `ifdef tinyfpgabx
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
  `endif

  //Reset
  wire resetn;
  reg [7:0] resetn_counter = 0;
  assign resetn = &resetn_counter;
  always @(posedge CLK) begin
    if (!resetn) resetn_counter <= resetn_counter + 1'b1;
  end
  wire reset = resetn;

  // Stepper Setup
  // TODO: Generate statement?
  // Stepper Config
<<<<<<< HEAD
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
  wire [511:0] cos_table;
=======
  reg [2:0] microsteps = 2;
  reg [7:0] current = 140;
  reg [9:0] config_offtime = 810;
  reg [7:0] config_blanktime = 27;
  reg [9:0] config_fastdecay_threshold = 706;
  reg [7:0] config_minimum_on_time = 54;
  reg [10:0] config_current_threshold = 1024;
  reg [7:0] config_chargepump_period = 91;
  reg config_invert_highside = 0;
  reg config_invert_lowside = 0;
  /*
  reg [511:0] cos_table;
>>>>>>> merget tb_m

  // Stepper control lines
  wire step;
  wire dir;
  reg enable;


  //
  // Stepper Modules
  //

  `ifdef DUAL_HBRIDGE
  DualHBridge s0 (.phase_a1 (PHASE_A1[1]),
                .phase_a2 (PHASE_A2[1]),
                .phase_b1 (PHASE_B1[1]),
                .phase_b2 (PHASE_B2[1]),
                .vref_a (VREF_A[1]),
                .vref_b (VREF_B[1]),
                .step (step),
                .dir (dir),
                .enable (enable),
                .microsteps (microsteps),
                .current (current),
                .microsteps (microsteps));
  `endif

  `ifdef ULTIBRIDGE
    microstepper_top microstepper0(
      .clk(CLK),
      .resetn( resetn),
      .s_l ({PHASE_B2[1], PHASE_B1[1], PHASE_A2[1], PHASE_A1[1]}),
      .s_h ({PHASE_B2_H[1], PHASE_B1_H[1], PHASE_A2_H[1], PHASE_A1_H[1]}),
      .analog_cmp1 (analog_cmp1),
      .analog_out1 (analog_out1),
      .analog_cmp2 (analog_cmp2),
      .analog_out2 (analog_out2),
      .chargepump_pin (CHARGEPUMP),
      .config_offtime (config_offtime),
      .config_blanktime (config_blanktime),
      .config_fastdecay_threshold (config_fastdecay_threshold),
      .config_minimum_on_time (config_minimum_on_time),
      .config_current_threshold (config_current_threshold),
      .config_chargepump_period (config_chargepump_period),
      .config_invert_highside (config_invert_highside),
      .config_invert_lowside (config_invert_lowside),
      //.cos_table (cos_table),
      .step (step),
      .dir (dir),
      .enable(enable),
      );
  `endif


  //
  // Encoder
  //
  reg signed [63:0] encoder_count;
  reg [7:0] encoder_multiplier = 1;
  wire encoder_fault;
  `ifdef QUAD_ENC
    // TODO: For ... generate
    quad_enc #(.encbits(64)) encoder0
    (
      .resetn(reset),
      .clk(CLK),
      .a(ENC_A[1]),
      .b(ENC_B[1]),
      .faultn(encoder_fault),
      .count(encoder_count),
      .multiplier(encoder_multiplier));
  `endif

  //
  // SPI State Machine
  //

  spi_state_machine spifsm (
    .CLK(CLK),

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
    .cos_table(cos_table),

    .encoder_count(encoder_count),

<<<<<<< HEAD
    .step(step),
    .dir(dir),
    .enable(enable),
=======
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
/*
        // Write to Cosine Table
        `CMD_COSINE_CONFIG: begin
          //config_cosine_table[word_data_received[35:32]] <= word_data_received[31:0];
          cos_table[word_data_received[37:32]] <= word_data_received[7:0];
          //cos_table[word_data_received[35:32]+3] <= word_data_received[31:25];
          //cos_table[word_data_received[35:32]+2] <= word_data_received[24:16];
          //cos_table[word_data_received[35:32]+1] <= word_data_received[15:8];
          //cos_table[word_data_received[35:32]] <= word_data_received[7:0];
        end
*/
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
>>>>>>> merget tb_m

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
    `endif
    `ifdef STEPOUTPUT
      .STEPOUTPUT(STEPOUTPUT),
      .DIROUTPUT(DIROUTPUT),
    `endif
  );

endmodule
