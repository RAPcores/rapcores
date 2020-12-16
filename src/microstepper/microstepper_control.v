`default_nettype none
module microstepper_control (
    input           clk,
    input           resetn,
    output          phase_a1_l_out,
    output          phase_a2_l_out,
    output          phase_b1_l_out,
    output          phase_b2_l_out,
    output          phase_a1_h_out,
    output          phase_a2_h_out,
    output          phase_b1_h_out,
    output          phase_b2_h_out,
    input   [9:0]   config_fastdecay_threshold,
    input           config_invert_highside,
    input           config_invert_lowside,
    input           step,
    input           dir,
    input           enable_in,
    input           analog_cmp1,
    input           analog_cmp2,
    output          faultn,
    input           s1,
    input           s2,
    input           s3,
    input           s4,
    output          offtimer_en0,
    output          offtimer_en1,
    output  [7:0]   phase_ct,
    input   [7:0]   blank_timer0,
    input   [7:0]   blank_timer1,
    input   [9:0]   off_timer0,
    input   [9:0]   off_timer1,
    input   [7:0]   minimum_on_timer0,
    input   [7:0]   minimum_on_timer1
//    input           mixed_decay_enable,
);
  reg [7:0] phase_ct;
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

  wire step_rising = (step_r == 2'b01);

  always @(posedge clk) begin
    if (!resetn) begin
      phase_ct <= 0;
    end
    else if (step_rising)
        phase_ct <= dir_r[1] ? phase_ct + 1 : phase_ct - 1;
  end

  // Phase polarity control signal from microstep counter
  wire s1;
  wire s2;
  wire s3;
  wire s4;

  // Fault (active low) if off timer starts before minimum on timer expires
  wire fault0 = off_timer0 && minimum_on_timer0 && enable;
  wire fault1 = off_timer1 && minimum_on_timer1 && enable;
  reg faultn;
  // Fault latches until reset
  always @(posedge clk) begin
      if (!resetn) begin
//        fault0 <= 0;
//        fault1 <= 0;
        faultn <= 1;
      end
      else if (faultn) begin
        faultn <= ( fault0 | fault1 ) && enable;
      end
    end

  wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
  wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;

  // Low side output polarity, enable, and fault shutdown
  // Outputs are active high unless config_invert_**** is set
  assign phase_a1_l_out = config_invert_lowside ^ ( phase_a1_l | !enable );
  assign phase_a2_l_out = config_invert_lowside ^ ( phase_a2_l | !enable );
  assign phase_b1_l_out = config_invert_lowside ^ ( phase_b1_l | !enable );
  assign phase_b2_l_out = config_invert_lowside ^ ( phase_b2_l | !enable );

  // High side
  assign phase_a1_h_out = config_invert_highside ^  ( phase_a1_h && !faultn && enable );
  assign phase_a2_h_out = config_invert_highside ^  ( phase_a2_h && !faultn && enable );
  assign phase_b1_h_out = config_invert_highside ^  ( phase_b1_h && !faultn && enable );
  assign phase_b2_h_out = config_invert_highside ^  ( phase_b2_h && !faultn && enable );

  // Fast decay is first x ticks of off time
  // default fast decay = 706
  wire fastDecay0 = off_timer0 >= config_fastdecay_threshold;
  wire fastDecay1 = off_timer1 >= config_fastdecay_threshold;

  // Slow decay remainder of off time - Active high
  wire slowDecay0 = off_timer0 && !fastDecay0;
  wire slowDecay1 = off_timer1 && !fastDecay1;

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
  // Low side is active
  // WHEN slow decay is active
  // OR
  // ( Fast decay active AND would normally be off this phase )
  assign phase_a1_l = slowDecay0 | ( fastDecay0 ? s1 : !s1 );
  assign phase_a2_l = slowDecay0 | ( fastDecay0 ? s2 : !s2 );
  assign phase_b1_l = slowDecay1 | ( fastDecay1 ? s3 : !s3 );
  assign phase_b2_l = slowDecay1 | ( fastDecay1 ? s4 : !s4 );

  // Fixed off time peak current controller off time start
  assign offtimer_en0 = analog_cmp1 & !blank_timer0 & !off_timer0;
  assign offtimer_en1 = analog_cmp2 & !blank_timer1 & !off_timer1;

`ifdef FORMAL
  always @(*) begin
    assert (!(phase_a1_l == 0 && phase_a1_h == 0));
    assert (!(phase_a2_l == 0 && phase_a2_h == 0));
    assert (!(phase_b1_l == 0 && phase_b1_h == 0));
    assert (!(phase_b2_l == 0 && phase_b2_h == 0));
  end
`endif

endmodule
