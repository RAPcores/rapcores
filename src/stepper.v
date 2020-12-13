`default_nettype none

module DualHBridge (
    input clk,
    output       phase_a1,  // Phase A
    output       phase_a2,  // Phase A
    output       phase_b1,  // Phase B
    output       phase_b2,  // Phase B
    output       vref_a,  // vref - Phase A
    output       vref_b,  // vref - Phase B
    input        step,
    input        dir,
    input        enable,
    input  [2:0] microsteps,
    input  [7:0] current
);

  // TODO: if phase_ct is initialized BRAM does not infer
  // TODO: phase_ct must be initialized on enable does not enable before step
  reg [2:0] phase_ct; // needs to be the size of microsteps, for LUT
  wire signed [2:0] phase_inc; // Phase increment per step
  wire [2:0] abs_increment;

  // Table of phases
  reg [31:0] phase_table [0:255]; // Larger to trigger BRAM inference

  // Vref - A
  PWM va (.clk(clk),
          .val(current),
          .pwm(vref_a));
  // Vref - B
  PWM vb (.clk(clk),
          .val(current),
          .pwm(vref_b));

  assign phase_a1 = (enable) ? phase_table[phase_ct][0] : 0;
  assign phase_a2 = (enable) ? phase_table[phase_ct][1] : 0;
  assign phase_b1 = (enable) ? phase_table[phase_ct][2] : 0;
  assign phase_b2 = (enable) ? phase_table[phase_ct][3] : 0;

  assign abs_increment = 3'b100 >> microsteps;
  assign phase_inc = dir ? abs_increment : -abs_increment; // Generate increment, multiple of microsteps\

  reg [1:0] step_r;

  initial begin
    phase_table[0] = 4'b1010;
    phase_table[1] = 4'b0010;
    phase_table[2] = 4'b0110;
    phase_table[3] = 4'b0100;
    phase_table[4] = 4'b0101;
    phase_table[5] = 4'b0001;
    phase_table[6] = 4'b1001;
    phase_table[7] = 4'b1000;
  end

  always @(posedge clk) begin
    step_r <= {step_r[0], step};
    if (step_r == 2'b01) begin
      // TODO: Need to add safety SPI or here
      //`ifdef FORMAL
      //  assert( (microsteps == 3'b010 && phase_inc == 3'b001) ||
      //          (microsteps == 3'b001 && phase_inc == 3'b010) );
      //`endif

      // Traverse the table based on direction, rolls over
      phase_ct <= phase_ct + phase_inc;
    end
  end

endmodule
