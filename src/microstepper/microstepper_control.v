module microstepper_control (
    input           clk,
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
);
  reg [7:0] phase_ct;

  always @(posedge step) begin
    phase_ct <= phase_ct + (dir ? 1 : -1);
  end

  wire s1;
  wire s2;
  wire s3;
  wire s4;

  wire overCurrent0 = off_timer0 > 0;
  wire overCurrent1 = off_timer1 > 0;

  wire fastDecay0 = off_timer0 >= config_fastdecay_threshold;
  wire fastDecay1 = off_timer1 >= config_fastdecay_threshold;

  wire slowDecay0 = overCurrent0 && fastDecay0 == 0;
  wire slowDecay1 = overCurrent1 && fastDecay1 == 0;

  wire fault0 = (minimum_on_timer0 > 0) && overCurrent0;
  wire fault1 = (minimum_on_timer1 > 0) && overCurrent1;
  wire fault = fault0 | fault1;

  reg [1:0] s1r, s2r, s3r, s4r;
  wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
  wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;

  assign s_l[0] = !(phase_a1_l | fault);
  assign s_l[1] = !(phase_a2_l | fault);
  assign s_l[2] = !(phase_b1_l | fault);
  assign s_l[3] = !(phase_b2_l | fault);

  assign s_h[0] = !(phase_a1_h | fault);
  assign s_h[1] = !(phase_a2_h | fault);
  assign s_h[2] = !(phase_b1_h | fault);
  assign s_h[3] = !(phase_b2_h | fault);

  assign phase_a1_h = config_invert_highside ^ (slowDecay0 | (fastDecay0 ? s1r[1] : ~s1r[1]));
  assign phase_a1_l = config_invert_lowside ^ (fastDecay0 ? ~s1r[1] : (slowDecay0 ? 1'b0 : s1r[1]));
  assign phase_a2_h = config_invert_highside ^ (slowDecay0 | (fastDecay0 ? s2r[1] : ~s2r[1]));
  assign phase_a2_l = config_invert_lowside ^ (fastDecay0 ? ~s2r[1] : (slowDecay0 ? 1'b0 : s2r[1]));

  assign phase_b1_h = config_invert_highside ^ (slowDecay1 | (fastDecay1 ? s3r[1] : ~s3r[1]));
  assign phase_b1_l = config_invert_lowside ^ (fastDecay1 ? ~s3r[1] : (slowDecay1 ? 1'b0 : s3r[1]));
  assign phase_b2_h = config_invert_highside ^ (slowDecay1 | (fastDecay1 ? s4r[1] : ~s4r[1]));
  assign phase_b2_l = config_invert_lowside ^ (fastDecay1 ? ~s4r[1] : (slowDecay1 ? 1'b0 : s4r[1]));
 

  wire s1_starting = s1r == 2'b10;
  wire s2_starting = s2r == 2'b10;
  wire s3_starting = s3r == 2'b10;
  wire s4_starting = s4r == 2'b10;

  assign offtimer_en0 = analog_cmp1 & blank_timer0 == 0 & overCurrent0 == 0;
  assign offtimer_en1 = analog_cmp2 & blank_timer1 == 0 & overCurrent1 == 0;
  assign a_starting = s1_starting | s2_starting;
  assign b_starting = s3_starting | s4_starting;

`ifdef FORMAL
  always @(*) begin
    assert (!(phase_a1_l == 0 && phase_a1_h == 0));
    assert (!(phase_a2_l == 0 && phase_a2_h == 0));
    assert (!(phase_b1_l == 0 && phase_b1_h == 0));
    assert (!(phase_b2_l == 0 && phase_b2_h == 0));
  end
`endif

  always @(posedge clk) begin
    s1r <= {s1r[0], s1};
    s2r <= {s2r[0], s2};
    s3r <= {s3r[0], s3};
    s4r <= {s4r[0], s4};
  end

endmodule
