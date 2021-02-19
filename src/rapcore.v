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

  // Wire declarations
  // These are declared here so that we may just leave disconnected without
  // ifdef in the modules for easier reuse
  `ifndef BUFFER_DTR
    wire BUFFER_DTR;
  `endif
  `ifndef MOVE_DONE
    wire MOVE_DONE;
  `endif
  `ifndef HALT
    wire HALT;
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

  // High frequency PLL for PWM or anything else
  `ifdef PWMPLL
    // PLL for SPI Bus
    wire pwm_clock;
    wire pwmpll_locked;
    pwm_pll ppll (.clock_in(CLK),
                  .clock_out(pwm_clock),
                  .locked(pwmpll_locked));
  `else
    wire pwm_clock = CLK;
  `endif

  // SPI PLL
  `ifdef SPIPLL
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
    .pwm_clock(pwm_clock),
    .resetn(resetn),

    .word_data_received(word_data_received_w),
    .word_send_data(word_send_data),
    .word_received(word_received),

    .buffer_dtr(BUFFER_DTR),
    .move_done(MOVE_DONE),
    .halt(HALT),

  `ifdef DUAL_HBRIDGE
    .PHASE_A1(PHASE_A1),  // Phase A
    .PHASE_A2(PHASE_A2),  // Phase A
    .PHASE_B1(PHASE_B1),  // Phase B
    .PHASE_B2(PHASE_B2),  // Phase B
    .VREF_A(VREF_A),       // VRef
    .VREF_B(VREF_B),       // VRef
  `endif
  `ifdef ULTIBRIDGE
    .CHARGEPUMP (CHARGEPUMP ),
    .analog_cmp1(analog_cmp1),
    .analog_out1(analog_out1),
    .analog_cmp2(analog_cmp2),
    .analog_out2(analog_out2),
    .PHASE_A1(PHASE_A1), // Phase A
    .PHASE_A2(PHASE_A2), // Phase A
    .PHASE_B1(PHASE_B1), // Phase B
    .PHASE_B2(PHASE_B2), // Phase B
    .PHASE_A1_H(PHASE_A1_H), // Phase A
    .PHASE_A2_H(PHASE_A2_H), // Phase A
    .PHASE_B1_H(PHASE_B1_H), // Phase B
    .PHASE_B2_H(PHASE_B2_H), // Phase B
  `endif
  `ifdef QUAD_ENC
    .ENC_B(ENC_B),
    .ENC_A(ENC_A),
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
