`default_nettype none

module rapcore #(
  parameter motor_count = `MOTOR_COUNT,
  parameter move_duration_bits = `MOVE_DURATION_BITS
  )(
    `ifdef LED
      output wire [`LED:1] LED,
    `endif
    `ifdef tinyfpgabx
      output USBPU,  // USB pull-up resistor
    `endif
    `ifdef SPI_INTERFACE
      input  wire SCK,
      input  wire CS,
      input  wire COPI,
      output wire CIPO,
    `endif
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
      output wire [motor_count-1:0] ENOUTPUT,
      output wire [motor_count-1:0] DIROUTPUT,
    `endif
    `ifdef LA_IN
      input wire [`LA_IN:1] LA_IN,
    `endif
    `ifdef LA_OUT
      output wire [`LA_OUT:1] LA_OUT,
    `endif
    `ifdef RESETN
      input resetn_in,
    `endif
    input CLK
);

  `ifdef tinyfpgabx
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
  `endif

  //Reset
  wire resetn;
  assign resetn = &resetn_counter;
  `ifdef RESETN
    reg [7:0] resetn_counter;
    always @(posedge CLK)
    if(!resetn_in)
      resetn_counter <= 0;
    else
      if (!resetn) resetn_counter <= resetn_counter + 1'b1;
  `endif
  `ifndef RESETN
    reg [7:0] resetn_counter = 0; // FPGA ONLY
    always @(posedge CLK) begin
      if (!resetn) resetn_counter <= resetn_counter + 1'b1;
    end
  `endif
  wire reset = resetn;

  // Stepper Setup
  // TODO: Generate statement?
  // Stepper Config
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

  // Stepper control lines
  wire [motor_count-1:0] step;
  wire [motor_count-1:0] dir;
  wire [motor_count-1:0] enable;
  wire [motor_count-1:0] brake;

  // Stepper status outputs
  wire [motor_count-1:0] faultn;


  //
  // Stepper Modules
  //

  `ifdef DUAL_HBRIDGE
    genvar i;
    generate
      for (i=0; i<motor_count; i=i+1) begin
        dual_hbridge s0 (.phase_a1 (PHASE_A1[i]),
                      .phase_a2 (PHASE_A2[i]),
                      .phase_b1 (PHASE_B1[i]),
                      .phase_b2 (PHASE_B2[i]),
                      .vref_a (VREF_A[i]),
                      .vref_b (VREF_B[i]),
                      .step (step[i]),
                      .dir (dir[i]),
                      .enable (enable[i]),
                      .brake  (brake[i]),
                      .microsteps (microsteps),
                      .current (current));
      end
    endgenerate
  `endif

  `ifdef ULTIBRIDGE
    genvar i;
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
          .config_offtime (config_offtime),
          .config_blanktime (config_blanktime),
          .config_fastdecay_threshold (config_fastdecay_threshold),
          .config_minimum_on_time (config_minimum_on_time),
          .config_current_threshold (config_current_threshold),
          .config_chargepump_period (config_chargepump_period),
          .config_invert_highside (config_invert_highside),
          .config_invert_lowside (config_invert_lowside),
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
  `endif

  //
  // SPI State Machine
  //

  spi_state_machine #(.motor_count(motor_count),
                      .move_duration_bits(move_duration_bits)) spifsm
  (
    `ifdef LA_IN
      .LA_IN(LA_IN),
    `endif
    `ifdef LA_OUT
      .LA_OUT(LA_OUT),
    `endif
    .CLK(CLK),
    .resetn(resetn),

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

    .encoder_count(encoder_count),

    .step(step),
    .dir(dir),
    .enable(enable),
    .brake(brake),

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
      .ENINPUT(ENINPUT),
    `endif
    `ifdef STEPOUTPUT
      .STEPOUTPUT(STEPOUTPUT),
      .DIROUTPUT(DIROUTPUT),
      .ENOUTPUT(ENOUTPUT)
    `endif
  );


  // Macro external wiring statements here
  `ifdef TOP_LA
    `TOP_LA
  `endif

endmodule
