// SPDX-License-Identifier: ISC
`default_nettype none


//
// Space Vector Modulator (Two Phase)
// https://en.wikipedia.org/wiki/Space_vector_modulation
// http://rapcores.org/rapcores/motor_control.html#space-vector-modulation


module space_vector_modulator #(
   parameter current_bits = 4,
   parameter microstep_bits = 8, // should not be greater than 8
   parameter phase_ct_bits = 8,
   parameter center_aligned = 1
) (
    input clk,
    input resetn,
    input pwm_clk, // Clock for PWM
    output       vref_a,  // vref - Phase A
    output       vref_b,  // vref - Phase B
    input  [7:0] current, // also called Phase Vector amplitude
    input [phase_ct_bits-1:0] phase_ct // Represents 0 -> 2pi integer range
);


  // Table of phase agnles (BRAM on FPGA)
  reg [7:0] phase_table [0:255];

  // Load sine table into BRAM
  initial $readmemb("lut/cos_lut.bit", phase_table);

  // unscaled sine value based on phase location (retrieved from BRAM)
  reg [microstep_bits-1:0] phase_a;
  reg [microstep_bits-1:0] phase_b;

  // sine value scaled by the current
  wire [microstep_bits+current_bits-1:0] pwm_a = phase_a[7:(8-microstep_bits)]*current[7:(8-current_bits)];
  wire [microstep_bits+current_bits-1:0] pwm_b = phase_b[7:(8-microstep_bits)]*current[7:(8-current_bits)];

  // PWM Types:
  //
  // Center Aligned
  // A: ___|-------|____
  // B: ______|-|_______
  //
  // Normal
  // A: ___|-------|____
  // B: ___|-|__________

  if (center_aligned) begin
    // Determine delay for center aligned PWM
    wire [microstep_bits+current_bits-2:0] pwm_delay_a = (pwm_a >= pwm_b) ? 0 : (pwm_b-pwm_a)>>1;
    wire [microstep_bits+current_bits-2:0] pwm_delay_b = (pwm_b >= pwm_a) ? 0 : (pwm_a-pwm_b)>>1;

    // Microstep*current -> vector angle voltage reference
    // Center aligned for better response characteristics
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
  end else begin
    // Microstep*current -> vector angle voltage reference
    pwm #(.bits(microstep_bits+current_bits)) ma (.clk(pwm_clk),
            .resetn (resetn),
            .val(pwm_a),
            .pwm(vref_a));
    pwm #(.bits(microstep_bits+current_bits)) mb (.clk(pwm_clk),
            .resetn (resetn),
            .val(pwm_b),
            .pwm(vref_b));
  end

  always @(posedge clk) begin
    if (resetn) begin
      // Load sine/cosine from RAM
      phase_a <= phase_table[phase_ct+8'd64];
      phase_b <= phase_table[phase_ct];
    end
  end

endmodule