
module microstepper_top (
    input        clk,
    input        resetn,
    output [3:0] s_l,
    output [3:0] s_h,
    input        analog_cmp1,
    output       analog_out1,
    input        analog_cmp2,
    output       analog_out2,
    output       chargepump_pin,
    input [9:0]  config_offtime,
    input [7:0]  config_blanktime,
    input [9:0]  config_fastdecay_threshold,
    input [7:0]  config_minimum_on_time,
    input [10:0] config_current_threshold,
    input [7:0]  config_chargepump_period,
    input        config_invert_highside,
    input        config_invert_lowside,
    //input [511:0] cos_table,
    input        step,
    input        dir,
    input        enable
);

  reg [7:0] phase_ct;

  always @(posedge step) begin
  phase_ct <= phase_ct + (dir ? 1 : -1);
end

  wire                                               [5:0] cos_index1;
  wire                                               [5:0] cos_index2;
  wire                                                     s1;
  wire                                                     s2;
  wire                                                     s3;
  wire                                                     s4;
  wire                                               [7:0] pwm1;
  wire                                               [7:0] pwm2;

  reg                                                [7:0] blank_timer0;
  reg                                                [7:0] blank_timer1;
  reg                                                [9:0] off_timer0;
  reg                                                [9:0] off_timer1;
  reg                                                [7:0] minimum_on_timer0;
  reg                                                [7:0] minimum_on_timer1;

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

  mytimer_10 #(
      .WIDTH(10)
  ) offtimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(analog_cmp1 & blank_timer0 == 0 & overCurrent0 == 0),
      .start_time  (config_offtime),
      .timer       (off_timer0)
  );

  mytimer_10 #(
      .WIDTH(10)
  ) offtimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(analog_cmp2 & blank_timer1 == 0 & overCurrent1 == 0),
      .start_time  (config_offtime),
      .timer       (off_timer1)
  );

  mytimer_8 #(
      .WIDTH(8)
  ) blanktimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(s1_starting | s2_starting),
      .start_time  (config_blanktime),
      .timer       (blank_timer0)
  );

  mytimer_8 #(
      .WIDTH(8)
  ) blanktimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(s3_starting | s4_starting),
      .start_time  (config_blanktime),
      .timer       (blank_timer1)
  );

  mytimer_8 #(
      .WIDTH(8)
  ) minimumontimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(s1_starting | s2_starting),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer0)
  );

  mytimer_8 #(
      .WIDTH(8)
  ) minimumontimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(s3_starting | s4_starting),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer1)
  );

  chargepump cp0 (
      .clk           (clk),
      .resetn        (resetn),
      .period        (config_chargepump_period),
      .chargepump_pin(chargepump_pin)
  );

  microstep_counter mc0 (
      .pos       (phase_ct),
      .cos_index1(cos_index1),
      .cos_index2(cos_index2),
      .sw        ({s1, s2, s3, s4})
  );

  cosine cosine0 (
      .cos_index(cos_index1),
      .cos_value(pwm1),
      //.cos_table(cos_table)
  );

  cosine cosine1 (
      .cos_index(cos_index2),
      .cos_value(pwm2),
      //.cos_table(cos_table)
  );

  analog_out ao0 (
      .clk        (clk),
      .resetn     (resetn),
      .pwm1       (pwm1),
      .pwm2       (pwm2),
      .analog_out1(analog_out1),
      .analog_out2(analog_out2),
      .current_threshold (config_current_threshold)
  );

endmodule
