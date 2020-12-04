
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
    input        enable,
    output       fault,
);
  wire [5:0] cos_index1;
  wire [5:0] cos_index2;
  wire [7:0] pwm1;
  wire [7:0] pwm2;

  wire s1, s2, s3, s4;
  wire offtimer_en0, offtimer_en1;

  wire a_starting, b_starting;
  wire   [7:0]   phase_ct;
  wire   [7:0]   blank_timer0;
  wire   [7:0]   blank_timer1;
  wire   [9:0]   off_timer0;
  wire   [9:0]   off_timer1;
  wire   [7:0]   minimum_on_timer0;
  wire   [7:0]   minimum_on_timer1;
  
  microstepper_control microstepper_control0(
    .clk(clk),
    .resetn(resetn),
    .s_l(s_l),
    .s_h(s_h),
    .config_fastdecay_threshold(config_fastdecay_threshold),
    .config_invert_highside(config_invert_highside),
    .config_invert_lowside(config_invert_lowside),
    .step(step),
    .dir(dir),
    .enable(enable),
    .analog_cmp1(analog_cmp1),
    .analog_cmp2(analog_cmp2),
    .fault(fault),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .s4(s4),
    .offtimer_en0(offtimer_en0),
    .offtimer_en1(offtimer_en1),
    .a_starting(a_starting),
    .b_starting(b_starting),
    .phase_ct(phase_ct),
    .blank_timer0(blank_timer0),
    .blank_timer1(blank_timer1),
    .off_timer0(off_timer0),
    .off_timer1(off_timer1),
    .minimum_on_timer0(minimum_on_timer0),
    .minimum_on_timer1(minimum_on_timer1),
);

  mytimer_10 offtimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(offtimer_en0),
      .start_time  (config_offtime),
      .timer       (off_timer0)
  );

  mytimer_10 offtimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(offtimer_en1),
      .start_time  (config_offtime),
      .timer       (off_timer1)
  );

  mytimer_8 blanktimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(a_starting),
      .start_time  (config_blanktime),
      .timer       (blank_timer0)
  );

  mytimer_8 blanktimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(b_starting),
      .start_time  (config_blanktime),
      .timer       (blank_timer1)
  );

  mytimer_8 minimumontimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(a_starting),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer0)
  );

  mytimer_8 minimumontimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(b_starting),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer1)
  );

  chargepump chargepump0 (
      .clk           (clk),
      .resetn        (resetn),
      .period        (config_chargepump_period),
      .chargepump_pin(chargepump_pin)
  );

  microstep_counter microstep_counter0 (
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

  analog_out analog_out0 (
      .clk        (clk),
      .resetn     (resetn),
      .pwm1       (pwm1),
      .pwm2       (pwm2),
      .analog_out1(analog_out1),
      .analog_out2(analog_out2),
      .current_threshold (config_current_threshold)
  );

endmodule
