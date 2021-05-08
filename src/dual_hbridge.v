// SPDX-License-Identifier: ISC
`default_nettype none

module dual_hbridge #(
   parameter current_bits = 4, // bit precision of current
   parameter microstep_bits = 8, // bit precision of microsteps
   parameter vref_off_brake = 1, // "decay mode"
   parameter microstep_count = 256, // quarter-cycle divisions
   parameter step_count_bits = 32, // internal encoder counter precision
   parameter encoder_bits = 32 // external input encoder precision
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

  // Compute the lower bits to determine phase count
  // Recall that microsteps is quarter wave and we want a counter for 0 -> 2pi
  localparam phase_ct_end = $clog2(microstep_count*4) - 1; 

  // Set the increment sign based on direction
  wire signed [7:0] phase_inc = dir ? abs_increment : -abs_increment;

  // This is the integer value of the encoded SVM pulse
  // N Phases are packed here, to be unpacked elsewhere
  wire [2*(current_bits+microstep_bits)-1:0] vref_val_packed;

  // Set the increment across the phase table from the specified microsteps
  wire [7:0] abs_increment = microsteps;

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
          .current(current[7:(8-current_bits)]),
          .phase_ct(count_r[phase_ct_end:0]));


  //-------------------------------
  // Coil Polarities
  //-------------------------------

  // determine phase polarity from quadrant
  wire [1:0] phase_polarity;
  //hmm gray codes
  assign phase_polarity = (count_r[phase_ct_end:phase_ct_end-1] == 2'b00 ) ? 2'b11 :
                          (count_r[phase_ct_end:phase_ct_end-1] == 2'b01 ) ? 2'b01 :
                          (count_r[phase_ct_end:phase_ct_end-1] == 2'b10 ) ? 2'b00 :
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


  wire step_rising;
  rising_edge_detector step_r (.clk(clk), .in(step), .out(step_rising));

  always @(posedge clk) begin
    if (!resetn) begin
      count_r <= 0;
    end else if (resetn) begin
      // Traverse the table based on direction, rolls over
      if (step_rising) begin // rising edge
        count_r <= count_r + phase_inc;
      end

    end
  end

endmodule
