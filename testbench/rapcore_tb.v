

// Your config here
//`include "../boards/mpw_one_defines.v"
`include "../boards/tinyfpgabx/tinyfpgabx.v"

`include "rapcore_harness_tb.v"
`include "pwm_duty.v"
`include "hbridge_coil.v"
`timescale 1ns/100ps

module rapcore_tb #(
  parameter motor_count = `MOTOR_COUNT
  )(
    `ifdef DUAL_HBRIDGE
      output wire [`DUAL_HBRIDGE-1:0] PHASE_A1,  // Phase A
      output wire [`DUAL_HBRIDGE-1:0] PHASE_A2,  // Phase A
      output wire [`DUAL_HBRIDGE-1:0] PHASE_B1,  // Phase B
      output wire [`DUAL_HBRIDGE-1:0] PHASE_B2,  // Phase B
    `endif
    input             CLK,
    output CIPO
  );

  `ifdef SPI_INTERFACE
    wire SCK;
    wire CS;
    wire COPI;
    wire CIPO;
  `endif
  `ifdef DUAL_HBRIDGE
    wire [`DUAL_HBRIDGE-1:0] PHASE_A1;  // Phase A
    wire [`DUAL_HBRIDGE-1:0] PHASE_A2;  // Phase A
    wire [`DUAL_HBRIDGE-1:0] PHASE_B1;  // Phase B
    wire [`DUAL_HBRIDGE-1:0] PHASE_B2;  // Phase B
    wire [`DUAL_HBRIDGE-1:0] VREF_A;  // VRef
    wire [`DUAL_HBRIDGE-1:0] VREF_B;  // VRef
  `endif
  `ifdef ULTIBRIDGE
    wire CHARGEPUMP;
    wire analog_cmp1;
    wire analog_out1;
    wire analog_cmp2;
    wire analog_out2;
    wire PHASE_A1;  // Phase A
    wire PHASE_A2;  // Phase A
    wire PHASE_B1;  // Phase B
    wire PHASE_B2;  // Phase B
    wire PHASE_A1_H;  // Phase A
    wire PHASE_A2_H;  // Phase A
    wire PHASE_B1_H;  // Phase B
    wire PHASE_B2_H;  // Phase B
  `endif
  `ifdef QUAD_ENC
    wire ENC_B;
    wire ENC_A;
  `endif
  `ifdef BUFFER_DTR
    wire BUFFER_DTR;
  `endif
  `ifdef MOVE_DONE
    wire MOVE_DONE;
  `endif
  `ifdef HALT
    wire HALT;
  `endif
  `ifdef STEPINPUT
    wire STEPINPUT;
    wire DIRINPUT;
    wire ENINPUT;
  `endif
  `ifdef STEPOUTPUT
    wire STEPOUTPUT;
    wire ENOUTPUT;
    wire DIROUTPUT;
  `endif
  `ifdef LA_IN
    wire LA_IN;
  `endif
  `ifdef LA_OUT
    wire LA_OUT;
  `endif
  `ifdef RESETN
    wire resetn_in;
  `endif
  wire CLK;

  rapcore_harness harness0 (
      `ifdef LED
        .LED(LED),
      `endif
      `ifdef tinyfpgabx
        .USBPU(USBPU),  // USB pull-up resistor
      `endif
      `ifdef SPI_INTERFACE
        .SCK(SCK),
        .CS(CS),
        .COPI(COPI),
        .CIPO(CIPO),
        .BOOT_DONE_IN(1'b1),
      `endif
      `ifdef ULTIBRIDGE
        .CHARGEPUMP(CHARGEPUMP),
        .analog_cmp1(analog_cmp1),
        .analog_out1(analog_out1),
        .analog_cmp2(analog_cmp2),
        .analog_out2(analog_out2),
        .PHASE_A1(PHASE_A1),  // Phase A
        .PHASE_A2(PHASE_A2),  // Phase A
        .PHASE_B1(PHASE_B1),  // Phase B
        .PHASE_B2(PHASE_B2),  // Phase B
        .PHASE_A1_H(PHASE_A1_H),  // Phase A
        .PHASE_A2_H(PHASE_A2_H),  // Phase A
        .PHASE_B1_H(PHASE_B1_H),  // Phase B
        .PHASE_B2_H(PHASE_B2_H),  // Phase B
      `endif
      `ifdef QUAD_ENC
        .ENC_B(ENC_B),
        .ENC_A(ENC_A),
      `endif
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
        .ENOUTPUT(ENOUTPUT),
        .DIROUTPUT(DIROUTPUT),
      `endif
      `ifdef LA_IN
        .LA_IN(LA_IN),
      `endif
      `ifdef LA_OUT
        .LA_OUT(LA_OUT),
      `endif
      `ifdef RESETN
        .resetn_in(resetn_in),
      `endif
      .CLK(CLK)
  );


  rapcore rapcore0 (
      `ifdef LED
        .LED(LED),
      `endif
      `ifdef tinyfpgabx
        .USBPU(USBPU),  // USB pull-up resistor
      `endif
      `ifdef SPI_INTERFACE
        .SCK(SCK),
        .CS(CS),
        .COPI(COPI),
        .CIPO(CIPO),
      `endif
      `ifdef DUAL_HBRIDGE
        .PHASE_A1(PHASE_A1),  // Phase A
        .PHASE_A2(PHASE_A2),  // Phase A
        .PHASE_B1(PHASE_B1),  // Phase B
        .PHASE_B2(PHASE_B2),  // Phase B
      `endif
      `ifdef VREF_AB
        .VREF_A(VREF_A),  // VRef
        .VREF_B(VREF_B),  // VRef
      `endif
      `ifdef ULTIBRIDGE
        .CHARGEPUMP(CHARGEPUMP),
        .analog_cmp1(analog_cmp1),
        .analog_out1(analog_out1),
        .analog_cmp2(analog_cmp2),
        .analog_out2(analog_out2),
        .PHASE_A1(PHASE_A1),  // Phase A
        .PHASE_A2(PHASE_A2),  // Phase A
        .PHASE_B1(PHASE_B1),  // Phase B
        .PHASE_B2(PHASE_B2),  // Phase B
        .PHASE_A1_H(PHASE_A1_H),  // Phase A
        .PHASE_A2_H(PHASE_A2_H),  // Phase A
        .PHASE_B1_H(PHASE_B1_H),  // Phase B
        .PHASE_B2_H(PHASE_B2_H),  // Phase B
      `endif
      `ifdef QUAD_ENC
        .ENC_B(ENC_B),
        .ENC_A(ENC_A),
      `endif
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
        .ENOUTPUT(ENOUTPUT),
        .DIROUTPUT(DIROUTPUT),
      `endif
      `ifdef LA_IN
        .LA_IN(LA_IN),
      `endif
      `ifdef LA_OUT
        .LA_OUT(LA_OUT),
      `endif
      `ifdef RESETN
        .resetn_in(resetn_in),
      `endif
      .CLK(CLK)
  );



endmodule
