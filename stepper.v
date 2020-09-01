`default_nettype none

module DualHBridge (
    output       phase_a1,  // Phase A
    output       phase_a2,  // Phase A
    output       phase_b1,  // Phase B
    output       phase_b2,  // Phase B
    input        step,
    input        dir,
    input  [2:0] microsteps
);

  reg [2:0] phase_ct; // needs to be the size of microsteps, for LUT
  reg [2:0] phase_inc; // Phase increment per step

  // Table of phases
  reg [3:0] phase_table [7:0];

  reg [3:0] phase_reg; // this will be 4xN bits PWM

  assign phase_a1 = phase_reg[0];
  assign phase_a2 = phase_reg[1];
  assign phase_b1 = phase_reg[2];
  assign phase_b2 = phase_reg[3];

  always @(posedge step) begin

    phase_inc = 3'b100 >> microsteps; // Generate increment, multiple of microsteps

    // Traverse the table based on direction, rolls over
    phase_ct = (dir) ? phase_ct - phase_inc : phase_ct + phase_inc;

    // TODO PWM these should be initialized in a resetable block for user calibration
    // Yosys memory support is influx, so track issues.
    phase_table[0] <= 4'b1010;
    phase_table[1] <= 4'b0010;
    phase_table[2] <= 4'b0110;
    phase_table[3] <= 4'b0100;
    phase_table[4] <= 4'b0101;
    phase_table[5] <= 4'b0001;
    phase_table[6] <= 4'b1001;
    phase_table[7] <= 4'b1000;

    // Write the phase wires
    phase_reg = phase_table[phase_ct % 8];

  end

endmodule
