module microstepper_control (
    input           clk,
    input           resetn,
    output  [3:0]   s_l,
    output  [3:0]   s_h,
    input   [9:0]   config_fastdecay_threshold,
    input           config_invert_highside,
    input           config_invert_lowside,
    input           step,
    input           dir,
    input           enable,
    input           analog_cmp1,
    input           analog_cmp2,
    output          fault,
    input           s1,
    input           s2,
    input           s3,
    input           s4,
    output          offtimer_en0,
    output          offtimer_en1,
    output          a_starting,
    output          b_starting,
    output  [7:0]   phase_ct,
    input   [7:0]   blank_timer0,
    input   [7:0]   blank_timer1,
    input   [9:0]   off_timer0,
    input   [9:0]   off_timer1,
    input   [7:0]   minimum_on_timer0,
    input   [7:0]   minimum_on_timer1,
//    input           off_timer0_done,
//    input           off_timer1_done,
//    output step_b_out,
);
  reg [7:0] phase_ct;
//  reg [1:0] step_b;

//  wire step_edge = (step_b[2] ^ step_b[1]) && step_b[2];
  // step edge rising falling

  reg [2:0] step_b;
  reg [1:0] dir_b;
//  wire step_b_out = step_b[2];
  wire step_rising = (step_b == 2'b01);

  always @(posedge clk) begin
    if (!resetn) begin
      phase_ct <= 0;
    end
    else if (step_rising) begin
        phase_ct <= dir_b[1] ? phase_ct + 1 : phase_ct - 1;
    end
    step_b <= {step_b[1:0], step};
    dir_b <= {dir[0], dir};
  end

  // Switch outputs
  wire s1;
  wire s2;
  wire s3;
  wire s4;

  // Off Timer active flag 
  wire off_timer_active0 = off_timer0 > 0;
  wire off_timer_active1 = off_timer1 > 0; 


  wire fault0 = (minimum_on_timer0 > 0) && off_timer_active0;
  wire fault1 = (minimum_on_timer1 > 0) && off_timer_active1;
  wire fault = fault0 | fault1;

  reg [1:0] s1r, s2r, s3r, s4r; // Switch output history [ previous : now ]
  wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
  wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;

  // Switch output Low
  assign s_l[0] = config_invert_lowside ^ (phase_a1_l | fault);
  assign s_l[1] = config_invert_lowside ^ (phase_a2_l | fault);
  assign s_l[2] = config_invert_lowside ^ (phase_b1_l | fault);
  assign s_l[3] = config_invert_lowside ^ (phase_b2_l | fault);

  // Switch output High
  assign s_h[0] = config_invert_highside ^ (phase_a1_h | fault);
  assign s_h[1] = config_invert_highside ^ (phase_a2_h | fault);
  assign s_h[2] = config_invert_highside ^ (phase_b1_h | fault);
  assign s_h[3] = config_invert_highside ^ (phase_b2_h | fault);

  // Fast decay is first x ticks of off time
  // default fast decay = 706
  wire fastDecay0 = off_timer0 >= config_fastdecay_threshold;
  wire fastDecay1 = off_timer1 >= config_fastdecay_threshold;

  // Slow decay remainder of off time
  wire slowDecay0 = off_timer_active0 && fastDecay0 == 0;
  wire slowDecay1 = off_timer_active1 && fastDecay1 == 0;
  
  // This portion of code sets up output to drive mosfets. Output ON = 0

  // High side output logic
  // If in slow decay = 1
    // OR ( fast decay and commanded to be OFF ) = 1
    // Then OFF
  // Else If Not slow decay (Never in slow decay at same time as fast decay)
    // OR ( not fast decay )
    // Then Follow commanded output
  // Else if fast decay
    // invert commanded polarity
  assign phase_a1_h = slowDecay0 | ( fastDecay0 ? s1 : ~s1 );
  // Low side output logic
  // low side output (invert if configured with XOR)
  // Invert signal if fast decay commands.
  // If slow decay Then the output is low. 
  // Else output = as commanded by microstep counter
  assign phase_a1_l = fastDecay0 ? ~s1 : ( slowDecay0 ? 1'b0 : s1 );
  assign phase_a2_h = slowDecay0 | ( fastDecay0 ? s2 : ~s2 );
  assign phase_a2_l = fastDecay0 ? ~s2 : ( slowDecay0 ? 1'b0 : s2 );
  assign phase_b1_h = slowDecay1 | ( fastDecay1 ? s3 : ~s3 );
  assign phase_b1_l = fastDecay1 ? ~s3 : ( slowDecay1 ? 1'b0 : s3 );
  assign phase_b2_h = slowDecay1 | ( fastDecay1 ? s4 : ~s4 );
  assign phase_b2_l = fastDecay1 ? ~s4 : ( slowDecay1 ? 1'b0 : s4 );

  // NEED DEAD TIME

  // Start Off Time
  // Target peak current detected. Blank timer and Off timer not active
  assign offtimer_en0 = analog_cmp1 & blank_timer0 == 0 & off_timer_active0 == 0;
  assign offtimer_en1 = analog_cmp2 & blank_timer1 == 0 & off_timer_active1 == 0;

`ifdef FORMAL
  always @(*) begin
    assert (!(phase_a1_l == 0 && phase_a1_h == 0));
    assert (!(phase_a2_l == 0 && phase_a2_h == 0));
    assert (!(phase_b1_l == 0 && phase_b1_h == 0));
    assert (!(phase_b2_l == 0 && phase_b2_h == 0));
  end
`endif

endmodule
