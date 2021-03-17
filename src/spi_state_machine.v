// SPDX-License-Identifier: ISC
`default_nettype none

module spi_state_machine #(
    parameter num_motors = 1,
    parameter num_encoders = 0,
    parameter word_bits = 64,
    parameter dda_bits = 64,
    parameter move_duration_bits = 32,
    parameter encoder_bits = 32,
    parameter default_microsteps = 64,
    parameter default_current = 140,
    parameter BUFFER_SIZE = 2,
    parameter default_clock_divisor = 32
  )(
  `ifdef LA_IN
    input wire [`LA_IN:1] LA_IN,
  `endif
  `ifdef LA_OUT
    output wire [`LA_OUT:1] LA_OUT,
  `endif

  input resetn,

  // Bus Interface
  input wire [word_bits-1:0] word_data_received,
  output reg [word_bits-1:0] word_send_data,
  input wire word_received,

  `ifdef DUAL_HBRIDGE
    output wire [`DUAL_HBRIDGE-1:0] PHASE_A1,  // Phase A
    output wire [`DUAL_HBRIDGE-1:0] PHASE_A2,  // Phase A
    output wire [`DUAL_HBRIDGE-1:0] PHASE_B1,  // Phase B
    output wire [`DUAL_HBRIDGE-1:0] PHASE_B2,  // Phase B
  `endif
  `ifdef VREF_AB
    output wire [`DUAL_HBRIDGE-1:0] VREF_A,  // VRef
    output wire [`DUAL_HBRIDGE-1:0] VREF_B,  // VRef
  `endif
  `ifdef ULTIBRIDGE
    output wire CHARGEPUMP,
    input  wire [`ULTIBRIDGE-1:0] analog_cmp1,
    output wire [`ULTIBRIDGE-1:0] analog_out1,
    input  wire [`ULTIBRIDGE-1:0] analog_cmp2,
    output wire [`ULTIBRIDGE-1:0] analog_out2,
    output wire [`ULTIBRIDGE-1:0] PHASE_A1,  // Phase A
    output wire [`ULTIBRIDGE-1:0] PHASE_A2,  // Phase A
    output wire [`ULTIBRIDGE-1:0] PHASE_B1,  // Phase B
    output wire [`ULTIBRIDGE-1:0] PHASE_B2,  // Phase B
    output wire [`ULTIBRIDGE-1:0] PHASE_A1_H,  // Phase A
    output wire [`ULTIBRIDGE-1:0] PHASE_A2_H,  // Phase A
    output wire [`ULTIBRIDGE-1:0] PHASE_B1_H,  // Phase B
    output wire [`ULTIBRIDGE-1:0] PHASE_B2_H,  // Phase B
  `endif
  `ifdef QUAD_ENC
    input wire [num_encoders-1:0] ENC_B,
    input wire [num_encoders-1:0] ENC_A,
  `endif

  // Event IO
  output wire buffer_dtr,
  output wire move_done,
  input  wire halt,

  `ifdef STEPINPUT
    input wire [num_motors-1:0] STEPINPUT,
    input wire [num_motors-1:0] DIRINPUT,
    input wire [num_motors-1:0] ENINPUT,
  `endif
  `ifdef STEPOUTPUT
    output wire [num_motors-1:0] STEPOUTPUT,
    output wire [num_motors-1:0] DIROUTPUT,
    output wire [num_motors-1:0] ENOUTPUT,
  `endif
  input CLK,
  input pwm_clock
);

  localparam CMD_COORDINATED_STEP    = 8'h01;
  localparam CMD_MOTOR_ENABLE        = 8'h0a;
  localparam CMD_MOTOR_BRAKE         = 8'h0b;
  localparam CMD_MOTORCONFIG         = 8'h10;
  localparam CMD_CLK_DIVISOR         = 8'h20;
  localparam CMD_MICROSTEPPER_CONFIG = 8'h30;
  localparam CMD_COSINE_CONFIG       = 8'h40;
  localparam CMD_API_VERSION         = 8'hfe;
  localparam CMD_CHARGEPUMP          = 8'h31;
  localparam CMD_BRIDGEINVERT        = 8'h32;
  localparam CMD_STEPPERFAULT        = 8'h50;
  localparam CMD_ENCODERFAULT        = 8'h51;

  localparam MOVE_BUFFER_SIZE = BUFFER_SIZE - 1; //This is the zero-indexed end index
  localparam MOVE_BUFFER_BITS = $clog2(BUFFER_SIZE) - 1; // number of bits to index given size


  //
  // Stepper Timing and Buffer Setup
  //

  // Move buffer
  reg [MOVE_BUFFER_BITS:0] writemoveind;
  wire [MOVE_BUFFER_BITS:0] moveind; // set via DDA FSM

  // Latching mechanism for engaging the buffered move.
  // the DDA side is internal to dda_fsm
  reg [MOVE_BUFFER_SIZE:0] stepready;

  reg [num_motors:1] dir_r [MOVE_BUFFER_SIZE:0];

  reg [move_duration_bits-1:0] move_duration [MOVE_BUFFER_SIZE:0];
  reg signed [dda_bits-1:0] increment [MOVE_BUFFER_SIZE:0][num_motors-1:0];
  reg signed [dda_bits-1:0] incrementincrement [MOVE_BUFFER_SIZE:0][num_motors-1:0];

  // DDA module input wires determined from buffer
  wire [move_duration_bits-1:0] move_duration_w = move_duration[moveind];

  // Per-axis DDA parameters
  wire [dda_bits-1:0] increment_w [num_motors-1:0];
  wire [dda_bits-1:0] incrementincrement_w [num_motors-1:0];

  genvar i;
  for (i=0; i<num_motors; i=i+1) begin
    assign increment_w[i] = increment[moveind][i];
    assign incrementincrement_w[i] = incrementincrement[moveind][i];
  end

  wire dda_tick;
  reg [7:0] clock_divisor;  // should be 40 for 400 khz at 16Mhz Clk

  // Step IO
  wire [num_motors-1:0] dda_step;
  reg [num_motors-1:0] enable_r;

  // Motor Brake
  reg [num_motors-1:0] brake_r;
  wire [num_motors-1:0] brake = brake_r;

  `ifndef STEPINPUT
    wire [num_motors-1:0] dir = dir_r[moveind]; // set direction
    wire [num_motors-1:0] step = dda_step;
    wire [num_motors-1:0] enable = enable_r;
  `else
    wire [num_motors-1:0] dir = dir_r[moveind] ^ DIRINPUT; // set direction
    wire [num_motors-1:0] step = dda_step ^ STEPINPUT;
    wire [num_motors-1:0] enable = enable_r | ENINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  wire [num_motors-1:0] stepper_faultn; // stepper fault

  wire [encoder_bits-1:0] step_encoder [num_motors-1:0]; // step encoder

  //
  // Stepper Configs
  //

  reg [7:0] microsteps [0:num_motors-1];
  reg [7:0] current [0:num_motors-1];
  reg [9:0] config_offtime [0:num_motors-1];
  reg [7:0] config_blanktime [0:num_motors-1];
  reg [9:0] config_fastdecay_threshold [0:num_motors-1];
  reg [7:0] config_minimum_on_time [0:num_motors-1];
  reg [10:0] config_current_threshold [0:num_motors-1];
  reg config_invert_highside [0:num_motors-1];
  reg config_invert_lowside [0:num_motors-1];
  reg [7:0] config_chargepump_period; // one chargepump for all

  //
  // Stepper Modules
  //

  `ifdef DUAL_HBRIDGE
    genvar i;
    generate
      for (i=0; i<num_motors; i=i+1) begin
        dual_hbridge #(.step_count_bits(encoder_bits))
                    s0 (
                      .clk (CLK),
                      .resetn(resetn),
                      .pwm_clk(pwm_clock),
                      .phase_a1 (PHASE_A1[i]),
                      .phase_a2 (PHASE_A2[i]),
                      .phase_b1 (PHASE_B1[i]),
                      .phase_b2 (PHASE_B2[i]),
                      `ifdef VREF_AB
                        .vref_a (VREF_A[i]),
                        .vref_b (VREF_B[i]),
                      `endif
                      .step (step[i]),
                      .dir (dir[i]),
                      .enable (enable[i]),
                      .brake  (brake[i]),
                      .microsteps (microsteps[i]),
                      .current (current[i]),
                      .step_count(step_encoder[i]),
                      .encoder_count(encoder_count[i]),
                      .faultn(stepper_faultn[i]));
      end
    endgenerate
  `endif

  `ifdef ULTIBRIDGE
    generate
      for (i=0; i<num_motors; i=i+1) begin
        microstepper_top microstepper0(
          `ifdef LA_IN
            .LA_IN(LA_IN),
          `endif
          `ifdef LA_OUT
            .LA_OUT(LA_OUT),
          `endif
          .clk(CLK),
          .resetn( resetn),
          .phase_a1_l(PHASE_A1[i]),
          .phase_a2_l(PHASE_A2[i]),
          .phase_b1_l(PHASE_B1[i]),
          .phase_b2_l(PHASE_B2[i]),
          .phase_a1_h(PHASE_A1_H[i]),
          .phase_a2_h(PHASE_A2_H[i]),
          .phase_b1_h(PHASE_B1_H[i]),
          .phase_b2_h(PHASE_B2_H[i]),
          .analog_cmp1 (analog_cmp1[i]),
          .analog_out1 (analog_out1[i]),
          .analog_cmp2 (analog_cmp2[i]),
          .analog_out2 (analog_out2[i]),
          .chargepump_pin (CHARGEPUMP),
          .config_offtime (config_offtime[i]),
          .config_blanktime (config_blanktime[i]),
          .config_fastdecay_threshold (config_fastdecay_threshold[i]),
          .config_minimum_on_time (config_minimum_on_time[i]),
          .config_current_threshold (config_current_threshold[i]),
          .config_chargepump_period (config_chargepump_period),
          .config_invert_highside (config_invert_highside[i]),
          .config_invert_lowside (config_invert_lowside[i]),
          //.cos_table (cos_table),
          .step (step[i]),
          .dir (dir[i]),
          .enable_in(enable[i]),
          .faultn(stepper_faultn[i])
          );
      end
    endgenerate
  `endif


  //
  // Encoders
  //

  wire signed [encoder_bits-1:0] encoder_count [num_encoders-1:0];
  wire [num_encoders-1:0] encoder_fault;

  if(num_encoders > 0) begin
    for (i=0; i<num_encoders; i=i+1) begin
      quad_enc #(.encbits(encoder_bits)) encoder0
      (
        .resetn(resetn),
        .clk(CLK),
        .a(ENC_A[i]),
        .b(ENC_B[i]),
        .faultn(encoder_fault[i]),
        .count(encoder_count[i])
        //.multiplier(encoder_multiplier)
        );
    end
  end


  wire loading_move;
  wire executing_move;

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
  dda_fsm #(.buffer_bits(MOVE_BUFFER_BITS+1),
            .buffer_size(BUFFER_SIZE),
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
    for (i=0; i<num_motors; i=i+1) begin
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
  // State Machine for handling SPI Messages
  //

  reg [7:0] message_word_count;
  reg [7:0] message_header;

  // Encoder
  reg signed [encoder_bits-1:0] encoder_store [num_motors-1:0]; // Snapshot for SPI comms
  reg signed [encoder_bits-1:0] step_encoder_store [num_motors-1:0]; // Snapshot for SPI comms

  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = (message_header == CMD_COORDINATED_STEP) |
                             (message_header == CMD_API_VERSION) |
                             (message_header == CMD_STEPPERFAULT) |
                             (message_header == CMD_ENCODERFAULT);

  wire [$clog2(num_motors-1):0] header_motor_channel = word_data_received[(48+$clog2(num_motors)):48];


  wire word_received_rising;
  rising_edge_detector word_recieved_edge_rising (.clk(CLK), .in(word_received), .out(word_received_rising));

  reg [$clog2(num_motors):0] nmot;

  always @(posedge CLK) if (!resetn) begin

    config_chargepump_period <= 91;

    enable_r <= {(num_motors){1'b0}};

    word_send_data <= 0;

    writemoveind <= 0;  // Move buffer
    stepready <= 0;  // Latching mechanism for engaging the buffered move.

    // TODO fix this
    dir_r[0] <= {(num_motors){1'b0}};
    dir_r[1] <= {(num_motors){1'b0}};

    brake_r <= 0;

    clock_divisor <= default_clock_divisor;  // should be 40 for 400 khz at 16Mhz Clk
    message_word_count <= 0;
    message_header <= 0;

    // TODO change to for loops for buffer
    move_duration[0] <= 0;
    move_duration[1] <= 0;

    for (nmot=0; nmot<num_motors; nmot=nmot+1) begin
      increment[0][nmot] <= {dda_bits{1'b0}};
      increment[1][nmot] <= {dda_bits{1'b0}};
      incrementincrement[0][nmot] <= {dda_bits{1'b0}};
      incrementincrement[1][nmot] <= {dda_bits{1'b0}};
  
      // Encoders
      step_encoder_store[nmot] <= 0;
      encoder_store[nmot] <= 0;

      // Stepper Config
      microsteps[nmot] <= default_microsteps;
      current[nmot] <= default_current;
      config_offtime[nmot] <= 810;
      config_blanktime[nmot] <= 27;
      config_fastdecay_threshold[nmot] <= 706;
      config_minimum_on_time[nmot] <= 54;
      config_current_threshold[nmot] <= 1024;
      config_invert_highside[nmot] <= `DEFAULT_BRIDGE_INVERTING;
      config_invert_lowside[nmot] <= `DEFAULT_BRIDGE_INVERTING;
    end

  end else if (resetn) begin

    if (word_received_rising) begin
      // Header Processing
      //if (!awaiting_more_words) begin

        // Save CMD header incase multi word transaction
        //message_header <= word_data_received[word_bits-1:word_bits-8]; // Header is 8 MSB

        // First word so message count zero
      if (!awaiting_more_words) begin
        message_word_count <= 1;
        message_header <= word_data_received[word_bits-1:word_bits-8]; // Header is 8 MSB
      end else begin
        message_word_count <= message_word_count + 1;
      end

      case (message_header)

        // Coordinated Move
        CMD_COORDINATED_STEP: begin

          if (message_word_count == 0) begin
            // Get Direction Bits
            dir_r[writemoveind] <= word_data_received[num_motors-1:0];

            // Store encoder values across all axes
            for (nmot=0; nmot<num_motors; nmot=nmot+1) begin
              step_encoder_store[nmot] <= step_encoder[nmot];
              encoder_store[nmot] <= encoder_count[nmot];
            end
          end

          // Multiaxis
          for (nmot=0; nmot<num_motors; nmot=nmot+1) begin
            // the first non-header word is the move duration
            if (nmot == 0) begin
              if (message_word_count == 1) begin
                move_duration[writemoveind][move_duration_bits-1:0] <= word_data_received[move_duration_bits-1:0];
                word_send_data[encoder_bits-1:0] <= step_encoder_store[0]; // Prep to send steps
              end
            end
            /* verilator lint_off WIDTH */
            if (message_word_count == (nmot+1)*2) begin
            /* verilator lint_on WIDTH */
              increment[writemoveind][nmot] <= word_data_received;
              word_send_data[encoder_bits-1:0] <= encoder_store[nmot]; // Prep to send steps
            end
            /* verilator lint_off WIDTH */
            if (message_word_count == (nmot+1)*2+1) begin
            /* verilator lint_on WIDTH */
              incrementincrement[writemoveind][nmot] <= word_data_received;
              if (nmot != num_motors-1) word_send_data[encoder_bits-1:0] <= step_encoder_store[nmot+1]; // Prep to send steps

              if (nmot == num_motors-1) begin
                writemoveind <= writemoveind + 1'b1;
                stepready[writemoveind] <= ~stepready[writemoveind];
                message_header <= 8'b0; // Reset Message Header at the end
                message_word_count <= 0;
              end
              `ifdef FORMAL
                assert(writemoveind <= MOVE_BUFFER_SIZE);
              `endif
            end
          end
        end // CMD_COORDINATED_STEP

        // Motor Enable/disable
        CMD_MOTOR_ENABLE: begin
          enable_r[num_motors-1:0] <= word_data_received[num_motors-1:0];
        end

        // Motor Brake on Disable
        CMD_MOTOR_BRAKE: begin
          brake_r[num_motors-1:0] <= word_data_received[num_motors-1:0];
        end

        // Clock divisor (24 bit)
        CMD_CLK_DIVISOR: begin
          clock_divisor[7:0] <= word_data_received[7:0];
        end

        // Set Microstepping
        CMD_MOTORCONFIG: begin
          // TODO needs to be power of two
          current[header_motor_channel][7:0] <= word_data_received[15:8];
          microsteps[header_motor_channel][2:0] <= word_data_received[2:0];
          `ifdef FORMAL
            assert(header_motor_channel == word_data_received[(48+$clog2(num_motors)):48]);
          `endif
        end

        // Set Microstepping Parameters
        CMD_MICROSTEPPER_CONFIG: begin
          config_offtime[header_motor_channel][9:0] <= word_data_received[39:30];
          config_blanktime[header_motor_channel][7:0] <= word_data_received[29:22];
          config_fastdecay_threshold[header_motor_channel][9:0] <= word_data_received[21:12];
          config_minimum_on_time[header_motor_channel][7:0] <= word_data_received[18:11];
          config_current_threshold[header_motor_channel][10:0] <= word_data_received[10:0];
        end

        // Set chargepump period
        CMD_CHARGEPUMP: begin
          config_chargepump_period[7:0] <= word_data_received[7:0];
        end

        // Invert Bridge outputs
        CMD_BRIDGEINVERT: begin
          config_invert_highside[header_motor_channel] <= word_data_received[1];
          config_invert_lowside[header_motor_channel] <= word_data_received[0];
        end

        // Read Stepper fault register
        CMD_STEPPERFAULT: begin
          word_send_data[num_motors-1:0] <= stepper_faultn;
        end

        // Read Stepper fault register
        // TODO
        //CMD_ENCODERFAULT: begin
        //  word_send_data[num_motors-1:0] <= stepper_faultn;
        //end


        // Write to Cosine Table
        // TODO Cosine Net is broken
        //CMD_COSINE_CONFIG: begin
          //cos_table[word_data_received[35:32]] <= word_data_received[31:0];
          //cos_table[word_data_received[37:32]] <= word_data_received[7:0];
          //cos_table[word_data_received[35:32]+3] <= word_data_received[31:25];
          //cos_table[word_data_received[35:32]+2] <= word_data_received[24:16];
          //cos_table[word_data_received[35:32]+1] <= word_data_received[15:8];
          //cos_table[word_data_received[35:32]] <= word_data_received[7:0];
        //end

        // API Version
        CMD_API_VERSION: begin
          word_send_data[7:0] <= `VERSION_PATCH;
          word_send_data[15:8] <= `VERSION_MINOR;
          word_send_data[23:16] <= `VERSION_MAJOR;
          word_send_data[31:24] <= `VERSION_DEVEL;
        end

        default: word_send_data <= 64'b0;

      endcase

    end
  end

  // Macro external wiring statements here
  `ifdef STATE_MACHINE_LA
    `STATE_MACHINE_LA
  `endif


endmodule
