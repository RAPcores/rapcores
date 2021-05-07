// SPDX-License-Identifier: ISC
`default_nettype none

//
// Space Vector Modulator (one, two and three Phase)
// https://en.wikipedia.org/wiki/Space_vector_modulation
// http://rapcores.org/rapcores/motor_control.html#space-vector-modulation

// We don't handle polarities here, all values are on/off timings.
// polarities and signedness is handled in the bridge controller.

module space_vector_modulator #(
   parameter current_bits = 4,
   parameter microstep_bits = 8,
   parameter phase_ct_bits = 8,
   parameter center_aligned = 1,
   parameter phases = 2,
   parameter microsteps = 64
) (
    input clk,
    input resetn,
    input pwm_clk,
    output [phases-1:0] vref_pwm,
    //output [phases*(current_bits+microstep_bits)-1:0] vref_val,
    input  [current_bits-1:0] current, // also called Phase Vector amplitude
    input [phase_ct_bits-1:0] phase_ct // Represents 0 -> 2pi integer range
);

  // center aligned delay only possible with phases > 1
  localparam can_delay = center_aligned && phases > 1;

  // microsteps commonly means quarter-wave resolution
  // however we store a half wave to get a true zero PWM crossing
  localparam integer phase_table_end = microsteps*2-1;

  // Table of phase agnles (BRAM on FPGA)
  reg [microstep_bits:0] phase_table [0:phase_table_end];

  // Initialize sine table into BRAM
  localparam real pi =  3.1415926535897;
  integer i;

  initial begin
      for (i=0; i <= phase_table_end;  i=i+1) begin
          phase_table[i] <= $sin(pi*i/(phase_table_end+1))*(2.0**microstep_bits-1);
      end
  end

  // sine value based on phase location (retrieved from BRAM)
  reg [microstep_bits-1:0] phase [phases-1:0];

  // sine value scaled by the current
  wire [microstep_bits+current_bits-1:0] pwm [phases-1:0];

  genvar ig;
  generate
    for (ig=0; ig<phases; ig=ig+1) begin
      assign pwm[ig] = phase[ig][microstep_bits-1:0]*current[current_bits-1:0];
    end
  endgenerate

  //assign vref_val = {pwm[0], pwm[1]};

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
  for (ig=0; ig<phases; ig=ig+1) begin
    pwm #(.bits(microstep_bits+current_bits),
          .delayed(can_delay)) mb (.clk(pwm_clk),
            .resetn (resetn),
            .val(pwm[ig]),
            .delay(pwm_delay[ig]),
            .pwm(vref_pwm[ig]));
  end

  localparam idx_end = phase_ct_bits - 2; // 
  wire [idx_end:0] phase_idx = phase_ct[idx_end:0];

  always @(posedge clk) begin
    if (resetn) begin
      // Load sine/cosine from RAM
      if (phases == 1) begin
        phase[1] <= phase_table[phase_idx];
      end if (phases == 2) begin
        phase[0] <= phase_table[phase_idx];
        phase[1] <= phase_table[phase_idx-microsteps];
      end if (phases == 3) begin
        phase[0] <= phase_table[phase_idx+microsteps/3];
        phase[1] <= phase_table[phase_idx+microsteps*2/3];
        phase[3] <= phase_table[phase_idx];
      end
    end
  end

endmodule