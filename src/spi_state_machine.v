`default_nettype none

module spi_state_machine #(
    parameter motor_count = 1,
    parameter move_duration_bits = 32,
    parameter default_microsteps = 64,
    parameter default_current = 140
  )(
  `ifdef LA_IN
    input wire [`LA_IN:1] LA_IN,
  `endif
  `ifdef LA_OUT
    output wire [`LA_OUT:1] LA_OUT,
  `endif

  input resetn,

  // Bus Interface
  input wire [63:0] word_data_received,
  output reg [63:0] word_send_data,
  input wire word_received,

  `ifdef DUAL_HBRIDGE
    output wire [`DUAL_HBRIDGE-1:0] PHASE_A1,  // Phase A
    output wire [`DUAL_HBRIDGE-1:0] PHASE_A2,  // Phase A
    output wire [`DUAL_HBRIDGE-1:0] PHASE_B1,  // Phase B
    output wire [`DUAL_HBRIDGE-1:0] PHASE_B2,  // Phase B
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
    input wire [`QUAD_ENC-1:0] ENC_B,
    input wire [`QUAD_ENC-1:0] ENC_A,
  `endif

  // Event IO
  output wire buffer_dtr,
  output wire move_done,
  input  wire halt,

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
  input CLK,
  input pwm_clock
);

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
  wire [motor_count-1:0] brake = brake_r;

  `ifndef STEPINPUT
    wire [motor_count-1:0] dir = dir_r[moveind]; // set direction
    wire [motor_count-1:0] step = dda_step;
    wire [motor_count-1:0] enable = enable_r;
  `else
    wire [motor_count-1:0] dir = dir_r[moveind] ^ DIRINPUT; // set direction
    wire [motor_count-1:0] step = dda_step ^ STEPINPUT;
    wire [motor_count-1:0] enable = enable_r | ENINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  wire [motor_count-1:0] faultn; // stepper fault

  wire [31:0] step_encoder [motor_count-1:0]; // step encoder

  //
  // Stepper Configs
  //

  reg [15:0] config_memory [0:motor_count-1]; // [15:8] -> microsteps [7:0] current

  reg [9:0] config_offtime [0:motor_count-1];
  reg [7:0] config_blanktime [0:motor_count-1];
  reg [9:0] config_fastdecay_threshold [0:motor_count-1];
  reg [7:0] config_minimum_on_time [0:motor_count-1];
  reg [10:0] config_current_threshold [0:motor_count-1];
  reg config_invert_highside [0:motor_count-1];
  reg config_invert_lowside [0:motor_count-1];
  reg [7:0] config_chargepump_period; // one chargepump for all

  //
  // Stepper Modules
  //

  `ifdef DUAL_HBRIDGE
    genvar i;
    generate
      for (i=0; i<motor_count; i=i+1) begin
        dual_hbridge s0 (
                      .clk (CLK),
                      .resetn(resetn),
                      .pwm_clk(pwm_clock),
                      .phase_a1 (PHASE_A1[i]),
                      .phase_a2 (PHASE_A2[i]),
                      .phase_b1 (PHASE_B1[i]),
                      .phase_b2 (PHASE_B2[i]),
                      .vref_a (VREF_A[i]),
                      .vref_b (VREF_B[i]),
                      .step (step[i]),
                      .dir (dir[i]),
                      .enable (enable[i]),
                      .brake  (brake[i]),
                      .microsteps (config_memory[i][`MEM_MICROSTEPS]),
                      .current (config_memory[i][`MEM_CURRENT]),
                      .step_count(step_encoder[i]));
      end
    endgenerate
  `endif

  `ifdef ULTIBRIDGE
    generate
      for (i=0; i<motor_count; i=i+1) begin
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
          .faultn(faultn[i])
          );
      end
    endgenerate
  `endif


  //
  // Encoder
  //
  wire signed [63:0] encoder_count;
  wire encoder_fault;
  `ifdef QUAD_ENC
    /* verilator lint_off PINMISSING */
    // TODO: For ... generate
    quad_enc #(.encbits(64)) encoder0
    (
      .resetn(resetn),
      .clk(CLK),
      .a(ENC_A[0]),
      .b(ENC_B[0]),
      .faultn(encoder_fault),
      .count(encoder_count)
      //.multiplier(encoder_multiplier)
      );
      /* verilator lint_off PINMISSING */
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

    config_chargepump_period <= 91;

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

      // Stepper Config
      config_memory[nmot][`MEM_MICROSTEPS] <= default_microsteps;
      config_memory[nmot][`MEM_CURRENT] <= default_current;

      // Microstepper config
      config_offtime[nmot] <= 810;
      config_blanktime[nmot] <= 27;
      config_fastdecay_threshold[nmot] <= 706;
      config_minimum_on_time[nmot] <= 54;
      config_current_threshold[nmot] <= 1024;
      config_invert_highside[nmot] <= `DEFAULT_BRIDGE_INVERTING;
      config_invert_lowside[nmot] <= `DEFAULT_BRIDGE_INVERTING;
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
            config_memory[word_data_received[55:48]] <= word_data_received[15:0];
          end

          // Set Microstepping Parameters
          `CMD_MICROSTEPPER_CONFIG: begin
            config_offtime[word_data_received[55:48]][9:0] <= word_data_received[39:30];
            config_blanktime[word_data_received[55:48]][7:0] <= word_data_received[29:22];
            config_fastdecay_threshold[word_data_received[55:48]][9:0] <= word_data_received[21:12];
            config_minimum_on_time[word_data_received[55:48]][7:0] <= word_data_received[18:11];
            config_current_threshold[word_data_received[55:48]][10:0] <= word_data_received[10:0];
          end

          // Set chargepump period
          `CMD_CHARGEPUMP: begin
            config_chargepump_period[7:0] <= word_data_received[7:0];
          end

          // Invert Bridge outputs
          `CMD_BRIDGEINVERT: begin
            config_invert_highside[word_data_received[55:48]] <= word_data_received[1];
            config_invert_lowside[word_data_received[55:48]] <= word_data_received[0];
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
