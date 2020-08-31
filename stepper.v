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
  reg [3:0] phase_inc; // Phase increment per step

  // Table of phases
  reg [3:0] phase_table [7:0];

  reg pa1 = 1'b0;
  reg pa2 = 1'b0;
  reg pb1 = 1'b0;
  reg pb2 = 1'b0;

  assign phase_a1 = pa1;
  assign phase_a2 = pa2;
  assign phase_b1 = pb1;
  assign phase_b2 = pb2;

  always @(posedge step) begin

    // TODO try with bit shifts
    case(microsteps)
      1: begin
        phase_inc = 4'h2;
      end
      2: begin
        phase_inc = 4'h1;
      end
    endcase

    phase_ct = (dir) ? phase_ct - phase_inc : phase_ct + phase_inc;

    // TODO these should be initialized in a resetable block
    // Yosys memory support is influx, so track issues.
    phase_table[0] <= 4'b1010;
    phase_table[1] <= 4'b0010;
    phase_table[2] <= 4'b0110;
    phase_table[3] <= 4'b0100;
    phase_table[4] <= 4'b0101;
    phase_table[5] <= 4'b0001;
    phase_table[6] <= 4'b1001;
    phase_table[7] <= 4'b1000;

    pa1 = phase_table[phase_ct % 8][0];
    pa2 = phase_table[phase_ct % 8][1];
    pb1 = phase_table[phase_ct % 8][2];
    pb2 = phase_table[phase_ct % 8][3];
  end

endmodule
