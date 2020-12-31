`default_nettype none
module microstepper_control (
    input           clk,
    input           resetn,
    output          phase_a1_l_out,
    output          phase_a2_l_out,
    output          phase_b1_l_out,
    output          phase_b2_l_out,
    output          phase_c1_l_out,
    output          phase_c2_l_out,

    output          phase_a1_h_out,
    output          phase_a2_h_out,
    output          phase_b1_h_out,
    output          phase_b2_h_out,
    output          phase_c1_h_out,
    output          phase_c2_h_out,

    input   [9:0]   config_fastdecay_threshold,
    input           config_invert_highside,
    input           config_invert_lowside,
    input           step,
    input           dir,
    input           enable_in,
    input           analog_cmp1,
    input           analog_cmp2,
    input           analog_cmp3,
    output reg      faultn,
    input  wire     s1,
    input  wire     s2,
    input  wire     s3,
    input  wire     s4,
    input  wire     s5,
    input  wire     s6,
    output          offtimer_en0,
    output          offtimer_en1,
    output          offtimer_en2,
    output reg [7:0] phase_ct,
    output reg [7:0] phase_ct_B,
    output reg [7:0] phase_ct_C,
    input      [7:0] blank_timer0,
    input      [7:0] blank_timer1,
    input      [7:0] blank_timer2,
    input      [9:0] off_timer0,
    input      [9:0] off_timer1,
    input      [9:0] off_timer2,
    input      [7:0] minimum_on_timer0,
    input      [7:0]   minimum_on_timer1,
    input      [7:0]   minimum_on_timer2
//    input           mixed_decay_enable,
);
  reg [2:0] step_r;
  reg [1:0] dir_r;

  reg       enable;

  always @(posedge clk) begin
    if (!resetn)
      enable <= 0;
    else
      enable <= enable_in;
    step_r <= {step_r[1:0], step};
    dir_r <= {dir_r[0], dir};
  end

  wire step_rising = (step_r == 3'b001);

  always @(posedge clk) begin
    if (!resetn) begin
      phase_ct <= 0;
      phase_ct_B <= 64;
      phase_ct_C <= 128;
    end else if (step_rising)
      if (dir_r[1]) begin
        phase_ct <= phase_ct < 191 ? phase_ct + 1 : 0;
        phase_ct_B <= phase_ct_B < 191 ? phase_ct_B + 1 : 0;
        phase_ct_C <= phase_ct_C < 191 ? phase_ct_C + 1 : 0;
      end else begin
        phase_ct <= phase_ct > 0 ? phase_ct - 1 : 191;
        phase_ct_B <= phase_ct_B > 0 ? phase_ct_B - 1 : 191;
        phase_ct_C <= phase_ct_C > 0 ? phase_ct_C - 1 : 191;
      end
  end

  // Fault (active low) if off timer starts before minimum on timer expires
  wire fault0 = (off_timer0 != 0) & (minimum_on_timer0 != 0);
  wire fault1 = (off_timer1 != 0) & (minimum_on_timer1 != 0);
  wire fault2 = (off_timer2 != 0) & (minimum_on_timer2 != 0);

  // Fault latches until reset
  always @(posedge clk) begin
      if (!resetn) begin
//        fault0 <= 0;
//        fault1 <= 0;
        faultn <= 1;
      end
      else if (faultn) begin
        faultn <= 1; //enable ? !( fault0 | fault1 | fault2 ) : 1'b1;
      end
    end

  wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
  wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;
  wire phase_c1_h, phase_c1_l, phase_c2_h, phase_c2_l;

  // Outputs are active high unless config_invert_**** is set
  // Low side
  assign phase_a1_l_out = config_invert_lowside ^ phase_a1_l_control;
  assign phase_a2_l_out = config_invert_lowside ^ phase_a2_l_control;
  assign phase_b1_l_out = config_invert_lowside ^ phase_b1_l_control;
  assign phase_b2_l_out = config_invert_lowside ^ phase_b2_l_control;
  assign phase_c1_l_out = config_invert_lowside ^ phase_c1_l_control;
  assign phase_c2_l_out = config_invert_lowside ^ phase_c2_l_control;
  // High side
  assign phase_a1_h_out = config_invert_highside ^  phase_a1_h_control;
  assign phase_a2_h_out = config_invert_highside ^  phase_a2_h_control;
  assign phase_b1_h_out = config_invert_highside ^  phase_b1_h_control;
  assign phase_b2_h_out = config_invert_highside ^  phase_b2_h_control;
  assign phase_c1_h_out = config_invert_highside ^  phase_c1_h_control;
  assign phase_c2_h_out = config_invert_highside ^  phase_c2_h_control;


  // Low Side - enable
  wire phase_a1_l_control = phase_a1_l | !enable;
  wire phase_a2_l_control = phase_a2_l | !enable;
  wire phase_b1_l_control = phase_b1_l | !enable;
  wire phase_b2_l_control = phase_b2_l | !enable;
  wire phase_c1_l_control = phase_c1_l | !enable;
  wire phase_c2_l_control = phase_c2_l | !enable;
  // High side - enable, and fault shutdown
  wire phase_a1_h_control = phase_a1_h && faultn && enable;
  wire phase_a2_h_control = phase_a2_h && faultn && enable;
  wire phase_b1_h_control = phase_b1_h && faultn && enable;
  wire phase_b2_h_control = phase_b2_h && faultn && enable;
  wire phase_c1_h_control = phase_c1_h && faultn && enable;
  wire phase_c2_h_control = phase_c2_h && faultn && enable;

  // Fast decay is first x ticks of off time
  // default fast decay = 706
  wire fastDecay0 = off_timer0 >= config_fastdecay_threshold;
  wire fastDecay1 = off_timer1 >= config_fastdecay_threshold;
  wire fastDecay2 = off_timer2 >= config_fastdecay_threshold;

  // Slow decay remainder of off time - Active high
  wire slowDecay0 = (off_timer0 != 0) & (fastDecay0 == 0);
  wire slowDecay1 = (off_timer1 != 0) & (fastDecay1 == 0);
  wire slowDecay2 = (off_timer2 != 0) & (fastDecay2 == 0);

  // Half bridge high side is active
  // WHEN slow decay is NOT active
  // AND
  // ( fast decay active AND would normally be off this phase )
  // OR
  // Should be on to drive this phase / polarity (microstepper_counter)
  assign phase_a1_h = !slowDecay0 && ( fastDecay0 ? !s1 : s1 );
  assign phase_a2_h = !slowDecay0 && ( fastDecay0 ? !s2 : s2 );
  assign phase_b1_h = !slowDecay1 && ( fastDecay1 ? !s3 : s3 );
  assign phase_b2_h = !slowDecay1 && ( fastDecay1 ? !s4 : s4 );
  assign phase_c1_h = !slowDecay2 && ( fastDecay2 ? !s5 : s5 );
  assign phase_c2_h = !slowDecay2 && ( fastDecay2 ? !s6 : s6 );
  // Low side is active
  // WHEN slow decay is active
  // OR
  // ( Fast decay active AND would normally be off this phase )
  assign phase_a1_l = slowDecay0 | ( fastDecay0 ? s1 : !s1 );
  assign phase_a2_l = slowDecay0 | ( fastDecay0 ? s2 : !s2 );
  assign phase_b1_l = slowDecay1 | ( fastDecay1 ? s3 : !s3 );
  assign phase_b2_l = slowDecay1 | ( fastDecay1 ? s4 : !s4 );
  assign phase_c1_l = slowDecay2 | ( fastDecay2 ? s5 : !s5 );
  assign phase_c2_l = slowDecay2 | ( fastDecay2 ? s6 : !s6 );

  // Fixed off time peak current controller off time start
  assign offtimer_en0 = analog_cmp1 & (blank_timer0 == 0) & (off_timer0 == 0);
  assign offtimer_en1 = analog_cmp2 & (blank_timer1 == 0) & (off_timer1 == 0);
  assign offtimer_en2 = analog_cmp3 & (blank_timer2 == 0) & (off_timer2 == 0);

`ifdef FORMAL
  `define ON 1'b1
  always @(*) begin
    assert (!(phase_a1_l_control == `ON && phase_a1_h_control == `ON));
    assert (!(phase_a2_l_control == `ON && phase_a2_h_control == `ON));
    assert (!(phase_b1_l_control == `ON && phase_b1_h_control == `ON));
    assert (!(phase_b2_l_control == `ON && phase_b2_h_control == `ON));
    assert (!(phase_c1_l_control == `ON && phase_c1_h_control == `ON));
    assert (!(phase_c2_l_control == `ON && phase_c2_h_control == `ON));
  end
`endif

endmodule
