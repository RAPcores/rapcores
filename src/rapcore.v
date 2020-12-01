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

  // Stepper control lines
  wire step;
  wire dir;
  wire enable;

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

    .step(step),
    .dir(dir),
    .enable(enable),

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
