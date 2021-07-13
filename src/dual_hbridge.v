// SPDX-License-Identifier: ISC
`default_nettype none

module dual_hbridge #(
   parameter current_bits = 4, // bit precision of current
   parameter microstep_bits = 8, // bit precision of microsteps
   parameter vref_off_brake = 1, // "decay mode"
   parameter microstep_count = 256 // quarter-cycle divisions
) (
    input clk,
    input resetn,
    input pwm_clk, // Clock for PWM
    output       phase_a1,  // Phase A
    output       phase_a2,  // Phase A
    output       phase_b1,  // Phase B
    output       phase_b2,  // Phase B
    output       vref_a,  // vref - Phase A
    output       vref_b,  // vref - Phase B
    input        enable,
    input        brake,
    input  [current_bits-1:0] current,
    input  [phase_ct_end:0] phase_angle, // represents location in 0 -> 2pi electrical cycle
    output wire faultn
);

  // Compute the lower bits need from the step_count for the 0 -> 2pi phase count.
  // Microsteps is quarter wave but we want a full electrical cycle
  localparam phase_ct_end = $clog2(microstep_count*4) - 1; 

  // This is the integer value of the encoded SVM pulse
  // N Phases are packed here, to be unpacked elsewhere
  // wire [2*(current_bits+microstep_bits)-1:0] vref_val_packed;

  //-------------------------------
  // Space Vector Modulation
  //-------------------------------

  space_vector_modulator #(
    .current_bits(current_bits),
    .phase_ct_bits(phase_ct_end+1),
    .microsteps(microstep_count)
  )
    svm0 (.clk(clk),
          .pwm_clk(pwm_clk),
          .resetn(resetn),
          .vref_pwm({vref_b,vref_a}),
          //.vref_val(vref_val_packed),
          .current(current),
          .phase_ct(phase_angle));


  // TODO Coil Polarities and Decay modes could go into a "driver" layer once the SVM handles polarities well.
  //-------------------------------
  // Coil Polarities
  //-------------------------------

  // determine phase polarity from quadrant
  wire [1:0] phase_polarity;
  //hmm gray codes
  assign phase_polarity = (phase_angle[phase_ct_end:phase_ct_end-1] == 2'b00 ) ? 2'b11 :
                          (phase_angle[phase_ct_end:phase_ct_end-1] == 2'b01 ) ? 2'b01 :
                          (phase_angle[phase_ct_end:phase_ct_end-1] == 2'b10 ) ? 2'b00 :
                                                                                 2'b10 ;

  // Set the bridge directions
  assign phase_a1 = (enable & vref_a) ?  phase_polarity[0] : brake_a;
  assign phase_a2 = (enable & vref_a) ? ~phase_polarity[0] : brake_a;
  assign phase_b1 = (enable & vref_b) ?  phase_polarity[1] : brake_b;
  assign phase_b2 = (enable & vref_b) ? ~phase_polarity[1] : brake_b;


  //-------------------------------
  // Decay Modes
  //-------------------------------

  // Set braking when PWM off (type of decay for integrated bridges without current chop)
  wire brake_a, brake_b;
  if (vref_off_brake) begin
    assign brake_a = ((!enable & brake) | !vref_a);
    assign brake_b = ((!enable & brake) | !vref_b);
  end else begin
    assign brake_a = brake;
    assign brake_b = brake;
  end

endmodule
