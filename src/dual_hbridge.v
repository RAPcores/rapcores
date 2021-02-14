`default_nettype none

module dual_hbridge #(
   parameter current_bits = 4,
   parameter microstep_bits = 8,
   parameter vref_off_brake = 1
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
    input  [7:0] current
);

  // TODO: if phase_ct is initialized BRAM does not infer
  // TODO: phase_ct must be initialized on enable does not enable before step
  reg [7:0] phase_ct; // needs to be the size of microsteps, for LUT
  wire signed [2:0] phase_inc; // Phase increment per step
  wire [2:0] abs_increment;

  // Table of phases
  reg [7:0] phase_table [0:255]; // Larger to trigger BRAM inference

  initial $readmemb("lut/cos_lut.bit", phase_table);

  wire [11:0] pwm_a;
  wire [11:0] pwm_b;

  assign pwm_a = phase_table[phase_ct+8'd64][7:(8-microstep_bits)]*current[7:(8-current_bits)];
  assign pwm_b = phase_table[phase_ct][7:(8-microstep_bits)]*current[7:(8-current_bits)];

  // Microstep -> vector angle
  pwm #(.bits(microstep_bits+current_bits)) ma (.clk(pwm_clk),
          .resetn (resetn),
          .val(pwm_a),
          .pwm(vref_a));
  pwm #(.bits(microstep_bits+current_bits)) mb (.clk(pwm_clk),
          .resetn (resetn),
          .val(pwm_b),
          .pwm(vref_b));


  // Set braking when PWM off
  wire brake_a, brake_b;
  if (vref_off_brake) begin
    assign brake_a = ((!enable & brake) | !vref_a);
    assign brake_b = ((!enable & brake) | !vref_b);
  end else begin
    assign brake_a = brake;
    assign brake_b = brake;
  end

  // determine phase polarity from quadrant
  wire [3:0] phase_polarity;
  assign phase_polarity = (phase_ct < 64) ? 4'b1010 : (phase_ct < 128) ? 4'b0110 : (phase_ct < 192) ? 4'b0101 : 4'b1001;

  assign phase_a1 = (enable & vref_a) ? phase_polarity[0] : brake_a;
  assign phase_a2 = (enable & vref_a) ? phase_polarity[1] : brake_a;
  assign phase_b1 = (enable & vref_b) ? phase_polarity[2] : brake_b;
  assign phase_b2 = (enable & vref_b) ? phase_polarity[3] : brake_b;

  assign abs_increment = 1'b1;
  assign phase_inc = dir ? abs_increment : -abs_increment; // Generate increment, multiple of microsteps\

  reg [1:0] step_r;

  always @(posedge clk) begin
    if (!resetn) begin
      step_r <= 2'b0;
    end else if (resetn) begin
      step_r <= {step_r[0], step};
      
      // TODO: Need to add safety SPI or here
      //`ifdef FORMAL
      //  assert( (microsteps == 3'b010 && phase_inc == 3'b001) ||
      //          (microsteps == 3'b001 && phase_inc == 3'b010) );
      //`endif

      // Traverse the table based on direction, rolls over
      if (step_r == 2'b01) begin // rising edge
        phase_ct <= phase_ct + phase_inc;
      end
    end
  end

endmodule
