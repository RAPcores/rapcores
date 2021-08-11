// SPDX-License-Identifier: ISC
`default_nettype none

module spi_state_machine #(
    parameter num_motors = 1,
    parameter num_encoders = 0,
    parameter word_bits = 64,
    parameter dda_bits = 64,
    parameter use_dda = 1,
    parameter move_duration_bits = 32,
    parameter encoder_bits = 32,
    parameter encoder_velocity_bits = 32,
    parameter default_microsteps = 1,
    parameter default_current = 140,
    parameter BUFFER_SIZE = 2,
    parameter default_clock_divisor = 32,
    parameter current_bits = 4,
    parameter reserved_motor_channels = 32, // Represents the motor channel length to reserve, ill advised to change
    parameter reserved_encoder_channels = 64 // Represents the encoder channel length to reserve, ill advised to change
  )(

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

  // Static Parameter checks
  if(encoder_bits > word_bits) $error("parameter: encoder_bits is greater than word_bits");
  if(move_duration_bits > word_bits) $error("parameter: move_duration_bits is greater than word_bits");
  if(word_bits < 32) $error("parameter: word_bits must be at least 32 bits");
  if(BUFFER_SIZE%2 != 0) $error("parameter: BUFFER_SIZE must be a power of two");


  localparam CMD_COORDINATED_STEP    = 8'h01;
  localparam CMD_STATUS_REG          = 8'hf1;
  localparam CMD_CONFIG_REG          = 8'hf2;

  localparam MOVE_BUFFER_SIZE = BUFFER_SIZE - 1; //This is the zero-indexed end index
  localparam MOVE_BUFFER_BITS = $clog2(BUFFER_SIZE) - 1; // number of bits to index given size

  // Iteration consts
  integer j;
  genvar g;

  // ---
  // Status Register
  // ---

  // Status register offset aliases,
  // These may be used in instantiated modules via dot access, e.g. rapcores.status_version
  // for procedural interface generation
  localparam status_version = 0;
  localparam status_channel_info = 1;
  localparam status_encoder_fault = 2;
  localparam status_stepper_fault = 3;
  localparam status_encoder_position_start = 4;
  localparam status_encoder_position_end = status_encoder_position_start + reserved_encoder_channels - 1;
  localparam status_encoder_velocity_start = status_stepper_fault + 1;
  localparam status_encoder_velocity_end = status_encoder_velocity_start + reserved_encoder_channels - 1;
  localparam status_phase_angle_start = status_encoder_velocity_end + 1;
  localparam status_phase_angle_end = status_phase_angle_start + reserved_motor_channels - 1;
  localparam status_reg_end = status_phase_angle_end;

  // Status Register (read-only)
  wire [word_bits-1:0] status_reg_ro    [status_reg_end:0];

  wire [num_motors-1:0] stepper_faultn;
  wire [num_encoders-1:0] encoder_faultn;
  wire signed [encoder_bits-1:0] encoder_count [num_encoders-1:0];
  wire signed [encoder_velocity_bits-1:0] encoder_velocity [num_encoders-1:0];
  wire signed [encoder_velocity_bits-1:0] encoder_velocity_counter [num_encoders-1:0];
  wire [9:0] phase_angle [0:num_motors-1];

  // Set Status Registers, these are reset by their respective module,
  // or set as constants here
  assign status_reg_ro[status_version][7:0]               = `VERSION_PATCH;        // constant
  assign status_reg_ro[status_version][15:8]              = `VERSION_MINOR;        // constant
  assign status_reg_ro[status_version][23:16]             = `VERSION_MAJOR;        // constant
  assign status_reg_ro[status_version][31:24]             = `VERSION_DEVEL;        // constant
  assign status_reg_ro[status_channel_info][7:0]          = num_motors;            // constant
  assign status_reg_ro[status_channel_info][15:8]         = num_encoders;          // constant
  assign status_reg_ro[status_channel_info][23:16]        = encoder_bits;          // constant
  assign status_reg_ro[status_channel_info][31:24]        = encoder_velocity_bits; // constant
  assign status_reg_ro[status_encoder_fault]              = encoder_faultn;
  assign status_reg_ro[status_stepper_fault]              = stepper_faultn;
  for(g=0; g<num_encoders; g=g+1) begin
    assign status_reg_ro[status_encoder_velocity_start+g] = encoder_velocity[g];
    assign status_reg_ro[status_encoder_position_start+g] = encoder_count[g];
  end
  for(g=0; g<num_motors; g=g+1) begin
    assign status_reg_ro[status_phase_angle_start+g] = phase_angle[g];
  end

  // ---
  // Config Register
  // ---

  // Config Register offset aliases
  localparam config_enable = 0;
  localparam config_brake = 1;
  localparam config_clocks = 2;
  localparam config_reg_end = config_clocks;

  (* mem2reg *) reg  [word_bits-1:0] config_reg_rw    [config_reg_end:0];

  // Config Register - Set mappings for internal wiring
  wire [num_motors-1:0] enable_r = config_reg_rw[config_enable][num_motors-1:0]; 
  wire [num_motors-1:0] brake_r = config_reg_rw[config_brake][num_motors-1:0]; 
  wire [7:0] clock_divisor = config_reg_rw[config_clocks][7:0];
  reg [7:0] microsteps [0:num_motors-1];
  reg [current_bits-1:0] current [0:num_motors-1];
  reg [9:0] config_offtime [0:num_motors-1];
  reg [7:0] config_blanktime [0:num_motors-1];
  reg [9:0] config_fastdecay_threshold [0:num_motors-1];
  reg [7:0] config_minimum_on_time [0:num_motors-1];
  reg [10:0] config_current_threshold [0:num_motors-1];
  reg config_invert_highside [0:num_motors-1];
  reg config_invert_lowside [0:num_motors-1];
  reg [7:0] config_chargepump_period; // one chargepump for all

  // ---
  // Telemetry Register
  // ---

  // Telemetry Register
  localparam telemetry_reg_end = num_encoders*2 - 1;

  (* mem2reg *) reg  [word_bits-1:0] telemetry_reg_ro [telemetry_reg_end:0];

  always @(posedge CLK) begin
    if (capture_telemetry) begin
      for (j=0; j < num_encoders; j=j+1) begin
        telemetry_reg_ro[j*2]   <= encoder_count[j]; 
        telemetry_reg_ro[j*2+1] <= encoder_velocity[j];
      end
    end
  end

  // ---
  // Command Register
  // ---

  // Command Register
  localparam command_reg_end = (2 + num_motors * 2);

  // TODO what is the column vs row major trap in FPGA? Does it exist?
  (* mem2reg *) reg  [word_bits-1:0] command_reg_rw   [BUFFER_SIZE:0][command_reg_end:0];

  reg [num_motors:1] dir_r [MOVE_BUFFER_SIZE:0];

  // Per-axis DDA parameters
  wire signed [dda_bits-1:0] increment_w [num_motors-1:0];
  wire signed [dda_bits-1:0] incrementincrement_w [num_motors-1:0];

  // Command Buffer selection
  genvar i;
  for (i=0; i<num_motors; i=i+1) begin
    assign increment_w[i] = command_reg_rw[moveind][2+i*2];
    assign incrementincrement_w[i] = command_reg_rw[moveind][2+i*2];
  end
  // DDA module input wires determined from buffer
  wire [move_duration_bits-1:0] move_duration_w = command_reg_rw[moveind][1][move_duration_bits-1:0];


  // Any register/wire below this point is outside user space
  wire capture_telemetry;

  // Move buffer
  reg [MOVE_BUFFER_BITS:0] writemoveind;
  wire [MOVE_BUFFER_BITS:0] moveind; // set via DDA FSM

  // Latching mechanism for engaging the buffered move.
  // the DDA side is internal to dda_fsm
  (* onehot *)reg [MOVE_BUFFER_SIZE:0] stepready;

  wire dda_tick;

  // Step IO
  wire [num_motors-1:0] dda_step;

  // handle External Step/Direction/Enable signals
  // when acting as a traditional motor driver
  `ifndef STEPINPUT
    wire [num_motors-1:0] dir = dir_r[moveind];
    wire [num_motors-1:0] step = dda_step;
    wire [num_motors-1:0] enable = enable_r;
  `else
    wire [num_motors-1:0] step_input_r, dir_input_r, en_input_r;

    register_input #(.width(num_motors)) stepin_m (.clk(CLK),.in(STEPINPUT), .out(step_input_r));
    register_input #(.width(num_motors)) dirin_m  (.clk(CLK),.in(DIRINPUT), .out(dir_input_r));
    register_input #(.width(num_motors)) enin_m   (.clk(CLK),.in(ENINPUT), .out(en_input_r));

    wire [num_motors-1:0] dir = dir_r[moveind] ^ dir_input_r;
    wire [num_motors-1:0] step = dda_step ^ step_input_r;
    wire [num_motors-1:0] enable = enable_r | en_input_r;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  wire signed [encoder_bits-1:0] step_encoder [num_motors-1:0]; // step encoder


  //
  // Stepper Modules
  //

  `ifdef DUAL_HBRIDGE
    generate
      for (i=0; i<num_motors; i=i+1) begin
        dual_hbridge #(.current_bits(current_bits))
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
                      .phase_angle (phase_angle[i]),
                      .enable (enable[i]),
                      .brake  (brake_r[i]),
                      .current (current[i]),
                      .faultn(stepper_faultn[i]));
      end
    endgenerate
  `endif

  `ifdef ULTIBRIDGE
    generate
      for (i=0; i<num_motors; i=i+1) begin
        microstepper_top microstepper0(
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
  `ifdef QUAD_ENC
    for (i=0; i<num_encoders; i=i+1) begin
      quad_enc #(.encbits(encoder_bits),
                 .velocity_bits(encoder_velocity_bits)) encoder0
      (
        .resetn(resetn),
        .clk(CLK),
        .a(ENC_A[i]),
        .b(ENC_B[i]),
        .faultn(encoder_faultn[i]),
        .count(encoder_count[i]),
        .velocity(encoder_velocity[i]),
        .velocity_counter(encoder_velocity_counter[i])
        //.multiplier(encoder_multiplier)
        );
    end
  `endif


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

  if (use_dda) begin
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
      .finishedmove(capture_telemetry),
      .move_done(move_done),
      .stepready(stepready),
      .buffer_dtr(buffer_dtr),
      .moveind(moveind)
    );

    // N dda timers per axis
    for (i=0; i<num_motors; i=i+1) begin
      dda_timer #(.phase_angle_bits(10),
                  .step_encoder_bits(encoder_bits))
        ddan (
                    .resetn(resetn),
                    .dda_tick(dda_tick),
                    .increment(increment_w[i]),
                    .incrementincrement(incrementincrement_w[i]),
                    .loading_move(loading_move),
                    .executing_move(executing_move),
                    .step_encoder(step_encoder[i]),
                    .phase_angle(phase_angle[i]),
                    .CLK(CLK)
                    );
    end
  end // use_dda


  //
  // State Machine for handling SPI Messages
  //

  reg [$clog2(command_reg_end)-1:0] message_word_count;
  reg [7:0] message_header;


  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = message_header != 0;

  wire word_received_rising;
  rising_edge_detector word_recieved_edge_rising (.clk(CLK), .in(word_received), .out(word_received_rising));

  reg [$clog2(num_motors):0] nmot;

  reg [7:0] dma_addr;

  always @(posedge CLK) if (!resetn) begin

    word_send_data <= 0;

    writemoveind <= 0;  // Move buffer
    stepready <= 0;  // Latching mechanism for engaging the buffered move.

    message_word_count <= 0;
    message_header <= 0;

    config_reg_rw[config_enable] <= 0;
    config_reg_rw[config_brake]  <= 0;
    config_reg_rw[config_clocks] <= default_clock_divisor;

    for (nmot=0; nmot<num_motors; nmot=nmot+1) begin

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
      // Zero out send data register
      word_send_data <= 64'b0;

      // Header Processing
      if (!awaiting_more_words) begin

        // Save CMD header incase multi word transaction
        message_header <= word_data_received[word_bits-1:word_bits-8]; // Header is 8 MSB

        message_word_count <= 1;

        case (word_data_received[word_bits-1:word_bits-8])

          // Coordinated Move
          CMD_COORDINATED_STEP: begin

            // Get Direction Bits
            dir_r[writemoveind] <= word_data_received[num_motors-1:0];
          end

          CMD_STATUS_REG: begin
            dma_addr <= word_data_received[7:0];
            word_send_data <= status_reg_ro[word_data_received[32:0]];
          end

          CMD_CONFIG_REG: begin
            dma_addr <= word_data_received[7:0];
            word_send_data <= config_reg_rw[word_data_received[32:0]];
          end

          default: word_send_data <= 64'b0;

        endcase

      // Addition Word Processing
      end else begin

        message_word_count <= message_word_count + 1'b1;

        case (message_header)

          // Move Routine
          CMD_COORDINATED_STEP: begin
            word_send_data <= telemetry_reg_ro[message_word_count-1]; // Prep to send steps
            command_reg_rw[writemoveind][message_word_count] <= word_data_received;
            if (message_word_count == num_motors*2 + 1) begin
              message_header <= 8'b0; // Reset Message Header at the end
              message_word_count <= 0;
              writemoveind <= writemoveind + 1'b1;
              stepready[writemoveind] <= ~stepready[writemoveind];
            end
          end // `CMD_COORDINATED_STEP

          CMD_CONFIG_REG: begin
            config_reg_rw[dma_addr] <= word_data_received[31:0];
            message_header <= 8'b0;
          end

          // by default reset the message header if it was a two word transaction
          default: message_header <= 8'b0; // Reset Message Header

        endcase
      end
    end
  end

endmodule
