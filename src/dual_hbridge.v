// SPDX-License-Identifier: ISC
`default_nettype none

module dual_hbridge #(
   parameter current_bits = 4,
   parameter microstep_bits = 8, // should not be greater than 8
   parameter vref_off_brake = 1,
   parameter microstep_count = 64,
   parameter step_count_bits = 32,
   parameter encoder_bits = 32
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
    input        step,
    input        dir,
    input        enable,
    input        brake,
    input  [7:0] microsteps,
    input  [7:0] current,
    output wire [step_count_bits-1:0] step_count,
    input signed [encoder_bits-1:0] encoder_count,
    output wire faultn
);

  //-------------------------------
  // Phase Vector Angle and Internal Step Counts
  //-------------------------------

  reg signed [step_count_bits-1:0] count_r;
  assign step_count = count_r;
  reg [7:0] phase_ct;
  // Set the increment sign based on direction
  wire signed [7:0] phase_inc = dir ? abs_increment : -abs_increment;
  reg signed [encoder_bits-1:0] encoder_prev;

  // This is the integer value of the encoded SVM pulse
  // N Phases are packed here, to be unpacked elsewhere
  wire [2*(current_bits+microstep_bits)-1:0] vref_val_packed;

  // Set the increment across the phase table from the specified microsteps
  wire [7:0] abs_increment = microsteps;

  //-------------------------------
  // Space Vector Modulation
  //-------------------------------

  space_vector_modulator #(
    .current_bits(current_bits)
  )
    svm0 (.clk(clk),
          .pwm_clk(pwm_clk),
          .resetn(resetn),
          .vref_pwm({vref_b,vref_a}),
          //.vref_val(vref_val_packed),
          .current(current[7:(8-current_bits)]),
          .phase_ct(phase_ct));


  //-------------------------------
  // Coil Polarities
  //-------------------------------

  // determine phase polarity from quadrant
  wire [3:0] phase_polarity;
  assign phase_polarity = (phase_ct < microstep_count  ) ? 4'b1010 :
                          (phase_ct < microstep_count*2) ? 4'b0110 :
                          (phase_ct < microstep_count*3) ? 4'b0101 :
                                                           4'b1001 ;

  // Set the bridge directions
  assign phase_a1 = (enable & vref_a) ? phase_polarity[0] : brake_a;
  assign phase_a2 = (enable & vref_a) ? phase_polarity[1] : brake_a;
  assign phase_b1 = (enable & vref_b) ? phase_polarity[2] : brake_b;
  assign phase_b2 = (enable & vref_b) ? phase_polarity[3] : brake_b;


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


  wire step_rising;
  rising_edge_detector step_r (.clk(clk), .in(step), .out(step_rising));

  always @(posedge clk) begin
    if (!resetn) begin
      phase_ct <= 8'b0;
    end else if (resetn) begin
      // Traverse the table based on direction, rolls over
      if (step_rising) begin // rising edge
        phase_ct <= dir ? phase_ct + abs_increment : phase_ct - abs_increment;
        count_r <= dir ? count_r + abs_increment : count_r - abs_increment;
      end

    end
  end

endmodule
