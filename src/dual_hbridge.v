// SPDX-License-Identifier: ISC
`default_nettype none

module dual_hbridge #(
   parameter current_bits = 4,
   parameter microstep_bits = 8, // should not be greater than 8
   parameter vref_off_brake = 1,
   parameter microstep_count = 64,
   parameter step_count_bits = 32,
   parameter encoder_bits = 24
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
    input signed wire [encoder_bits-1:0] encoder_count,
    output wire faultn
);

  reg signed [step_count_bits-1:0] count_r;
  assign step_count = count_r;

  // Table of phases (BRAM on FPGA)
  reg [7:0] phase_table [0:255];

  // Load sine table into BRAM
  initial $readmemb("lut/cos_lut.bit", phase_table);

  // unscaled sine value based on phase location (retrieved from BRAM)
  reg [microstep_bits-1:0] phase_a;
  reg [microstep_bits-1:0] phase_b;

  // sine value scaled by the current
  wire [microstep_bits+current_bits-1:0] pwm_a = phase_a[7:(8-microstep_bits)]*current[7:(8-current_bits)];
  wire [microstep_bits+current_bits-1:0] pwm_b = phase_b[7:(8-microstep_bits)]*current[7:(8-current_bits)];

  // Determine delay for center aligned PWM
  wire [microstep_bits+current_bits-1:0] pwm_max = (pwm_a >= pwm_b) ? pwm_a : pwm_b;
  wire [microstep_bits+current_bits-1:0] pwm_delay_a = (pwm_max == pwm_a) ? 0 : (pwm_max-pwm_a)>>1;
  wire [microstep_bits+current_bits-1:0] pwm_delay_b = (pwm_max == pwm_b) ? 0 : (pwm_max-pwm_b)>>1;

  // Microstep*current -> vector angle voltage reference
  pwm_delayed #(.bits(microstep_bits+current_bits)) ma (.clk(pwm_clk),
          .resetn (resetn),
          .val(pwm_a),
          .delay(pwm_delay_a),
          .pwm(vref_a));
  pwm_delayed #(.bits(microstep_bits+current_bits)) mb (.clk(pwm_clk),
          .resetn (resetn),
          .val(pwm_b),
          .delay(pwm_delay_b),
          .pwm(vref_b));

  // Set braking when PWM off (type of decay for integrated bridges without current chop)
  wire brake_a, brake_b;
  if (vref_off_brake) begin
    assign brake_a = ((!enable & brake) | !vref_a);
    assign brake_b = ((!enable & brake) | !vref_b);
  end else begin
    assign brake_a = brake;
    assign brake_b = brake;
  end

  // determine phase polarity from quadrant
  // TODO double check
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

  // Set the increment across the phase table from the specified microsteps
  wire [7:0] abs_increment = (microsteps == 8'd0 ) ? 8'd64 :
                             (microsteps <= 8'd2 ) ? 8'd32 :
                             (microsteps <= 8'd4 ) ? 8'd16 :
                             (microsteps <= 8'd8 ) ? 8'd8  :
                             (microsteps <= 8'd16) ? 8'd4  :
                             (microsteps <= 8'd32) ? 8'd2  :
                                                     8'd1  ;

  // Set the increment sign based on direction
  wire signed [7:0] phase_inc = dir ? abs_increment : -abs_increment;

  reg [7:0] phase_ct;

  wire step_rising;
  rising_edge_detector step_r (.clk(clk), .in(step), .out(step_rising));
  reg signed [encoder_bits-1:0] encoder_prev;

  always @(posedge clk) begin
    if (!resetn) begin
      phase_ct <= 8'b0;
    end else if (resetn) begin
      // Traverse the table based on direction, rolls over
      if (step_rising) begin // rising edge
        phase_ct <= phase_ct + phase_inc;
        count_r <= count_r + phase_inc;
      end

      // Load sine/cosine from RAM
      phase_a <= phase_table[phase_ct+8'd64];
      phase_b <= phase_table[phase_ct];
    end
  end

endmodule
