// SPDX-License-Identifier: ISC
`default_nettype none

//
// Space Vector Modulator (one, two and three Phase)
// https://en.wikipedia.org/wiki/Space_vector_modulation
// http://rapcores.org/rapcores/motor_control.html#space-vector-modulation

module space_vector_modulator #(
   parameter current_bits = 4,
   parameter microstep_bits = 8, // should not be greater than 8
   parameter phase_ct_bits = 8,
   parameter center_aligned = 1,
   parameter phases = 2,
   parameter cosine_lut = "lut/cos_lut.bit"
) (
    input clk,
    input resetn,
    input pwm_clk,
    output [phases-1:0] vref_pwm,
    output [phases*(current_bits+microstep_bits)-1:0] vref_val,
    input  [7:0] current, // also called Phase Vector amplitude
    input [phase_ct_bits-1:0] phase_ct // Represents 0 -> 2pi integer range
);

  // center aligned delay only possible with phases > 1
  localparam can_delay = center_aligned && phases > 1;

  // Table of phase agnles (BRAM on FPGA)
  reg [7:0] phase_table [0:255];

  // Load sine table into BRAM
  initial $readmemb(cosine_lut, phase_table);

  // unscaled sine value based on phase location (retrieved from BRAM)
  reg [microstep_bits-1:0] phase [phases-1:0];

  // sine value scaled by the current
  wire [microstep_bits+current_bits-1:0] pwm [phases-1:0];

  genvar i;
  generate
    for (i=0; i<phases; i=i+1) begin
      assign pwm[i] = phase[i][7:(8-microstep_bits)]*current[7:(8-current_bits)];
    end
  endgenerate

  // PWM Types:
  //
  // Center Aligned
  // A: ___|-------|____
  // B: ______|-|_______
  //
  // Normal
  // A: ___|-------|____
  // B: ___|-|__________
  wire [microstep_bits+current_bits-2:0] pwm_delay [phases-1:0];


  if (can_delay) begin
    // Determine delay for center aligned PWM

    // Center Aligned
    // A: |-------|____
    // B: ___|-|_______
    // C: _|-----|_____
    // For the above:
    // Delay A: 0
    // Delay B: (A-B)/2
    // Delay C: (A-C)/2
    // Where A == Max(A,B,C)

    if (phases == 2) begin
      assign pwm_delay[0] = (pwm[0] >= pwm[1]) ? 0 : (pwm[1]-pwm[0])>>1;
      assign pwm_delay[1] = (pwm[1] >= pwm[0]) ? 0 : (pwm[0]-pwm[1])>>1;
    end if (phases == 3) begin
      // TODO
      assign pwm_delay[0] = (pwm[0] >= pwm[1]) ? 0 : (pwm[1]-pwm[0])>>1;
      assign pwm_delay[1] = (pwm[1] >= pwm[0]) ? 0 : (pwm[0]-pwm[1])>>1;
    end
  end

  // Microstep*current -> vector angle voltage reference
  // Center aligned for better response characteristics if available/selected
  for (i=0; i<phases; i=i+1) begin
    pwm #(.bits(microstep_bits+current_bits),
          .delayed(can_delay)) mb (.clk(pwm_clk),
            .resetn (resetn),
            .val(pwm[i]),
            .delay(pwm_delay[i]),
            .pwm(vref_pwm[i]));
  end


  always @(posedge clk) begin
    if (resetn) begin
      // Load sine/cosine from RAM
      if (phases == 1) begin
        phase[1] <= phase_table[phase_ct];
      end if (phases == 2) begin
        phase[0]<= phase_table[phase_ct+8'd64];
        phase[1] <= phase_table[phase_ct];
      end if (phases == 3) begin
        phase[0]<= phase_table[phase_ct+8'd86];
        phase[0]<= phase_table[phase_ct+8'd43];
        phase[1] <= phase_table[phase_ct];
      end
    end
  end

endmodule