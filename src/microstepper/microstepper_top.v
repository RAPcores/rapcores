`default_nettype none

module microstepper_top (
    input   wire       clk,
    input   wire       resetn,
    output  wire       phase_a1_l,
    output  wire       phase_a2_l,
    output  wire       phase_b1_l,
    output  wire       phase_b2_l,
    output  wire       phase_c1_l,
    output  wire       phase_c2_l,
    output  wire     phase_a1_h,
    output  wire     phase_a2_h,
    output  wire     phase_b1_h,
    output  wire     phase_b2_h,
    output  wire     phase_c1_h,
    output  wire     phase_c2_h,
    input   wire     analog_cmp1,
    output  wire     analog_out1,
    input   wire     analog_cmp2,
    output  wire     analog_out2,
    input   wire     analog_cmp3,
    output  wire     analog_out3,
    output  wire     chargepump_pin,
    input   wire    [9:0]  config_offtime,
    input   wire    [7:0]  config_blanktime,
    //input   wire    [2:0]  config_deadtime,
    input   wire    [9:0]  config_fastdecay_threshold,
    input   wire    [7:0]  config_minimum_on_time,
    input   wire    [10:0] config_current_threshold,
    input   wire    [7:0]  config_chargepump_period,
    input   wire     config_invert_highside,
    input   wire     config_invert_lowside,
    //input [511:0] cos_table,
    input   wire     step,
    input   wire     dir,
    input   wire     enable_in,
    output  wire     faultn
);
  wire s1, s2, s3, s4, s5, s6;
  wire   [7:0]   phase_ct;

  wire   [5:0]   cos_index1,        cos_index2,        cos_index3;
  wire   [7:0]   pwm1,              pwm2,              pwm3;

  wire           a_starting,        b_starting,        c_starting;
  wire   [7:0]   blank_timer0,      blank_timer1,      blank_timer2;
  wire   [7:0]   minimum_on_timer0, minimum_on_timer1, minimum_on_timer2;

  wire           offtimer_en0,      offtimer_en1,      offtimer_en2;
  wire   [9:0]   off_timer0,        off_timer1,        off_timer2;
  wire           off_timer0_done,   off_timer1_done,   off_timer2_done;

  microstepper_control microstepper_control0(
    .clk(clk),
    .resetn(resetn),
    .phase_a1_l_out(phase_a1_l),
    .phase_a2_l_out(phase_a2_l),
    .phase_b1_l_out(phase_b1_l),
    .phase_b2_l_out(phase_b2_l),
    .phase_c1_l_out(phase_c1_l),
    .phase_c2_l_out(phase_c2_l),
    .phase_a1_h_out(phase_a1_h),
    .phase_a2_h_out(phase_a2_h),
    .phase_b1_h_out(phase_b1_h),
    .phase_b2_h_out(phase_b2_h),
    .phase_c1_h_out(phase_c1_h),
    .phase_c2_h_out(phase_c2_h),
    .config_fastdecay_threshold(config_fastdecay_threshold),
    .config_invert_highside(config_invert_highside),
    .config_invert_lowside(config_invert_lowside),
    .step(step),
    .dir(dir),
    .enable_in(enable_in),

    .analog_cmp1(analog_cmp1),
    .analog_cmp2(analog_cmp2),
    .analog_cmp3(analog_cmp3),

    .faultn(faultn),
    .s1(s1),
    .s2(s2),
    .s3(s3),
    .s4(s4),
    .s5(s5),
    .s6(s6),

    .offtimer_en0(offtimer_en0),
    .offtimer_en1(offtimer_en1),
    .offtimer_en2(offtimer_en2),

    .phase_ct (phase_ct),
    .phase_ct_B (phase_ct_B),
    .phase_ct_C (phase_ct_C),

    .blank_timer0(blank_timer0),
    .blank_timer1(blank_timer1),
    .blank_timer2(blank_timer2),

    .off_timer0(off_timer0),
    .off_timer1(off_timer1),
    .off_timer2(off_timer2),

    .minimum_on_timer0(minimum_on_timer0),
    .minimum_on_timer1(minimum_on_timer1),
    .minimum_on_timer2(minimum_on_timer2)
);

  mytimer_10 #(
      .WIDTH(10)
  ) offtimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(offtimer_en0),
      .start_time  (config_offtime),
      .timer       (off_timer0),
      .done         (off_timer0_done)
  );

  mytimer_10 offtimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(offtimer_en1),
      .start_time  (config_offtime),
      .timer       (off_timer1),
      .done         (off_timer1_done)
  );

    mytimer_10 offtimer2 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(offtimer_en2),
      .start_time  (config_offtime),
      .timer       (off_timer2),
      .done         (off_timer2_done)
  );

  mytimer_8 blanktimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer0_done),
      .start_time  (config_blanktime),
      .timer       (blank_timer0)
  );

  mytimer_8 blanktimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer1_done),
      .start_time  (config_blanktime),
      .timer       (blank_timer1)
  );

  mytimer_8 blanktimer2 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer2_done),
      .start_time  (config_blanktime),
      .timer       (blank_timer2)
  );

  mytimer_8 minimumontimer0 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer0_done),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer0)
  );

  mytimer_8 minimumontimer1 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer1_done),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer1)
  );

  mytimer_8 minimumontimer2 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(off_timer2_done),
      .start_time  (config_minimum_on_time),
      .timer       (minimum_on_timer2)
  );

  chargepump chargepump0 (
      .clk           (clk),
      .resetn        (resetn),
      .period        (config_chargepump_period),
      .chargepump_pin(chargepump_pin)
  );

  wire [7:0] phase_ct_B; // = phase_ct + 64;
  wire [7:0] phase_ct_C; // = phase_ct + 128;

  microstep_counter microstep_counter0 (
      .clk (clk), .resetn (resetn),
      .pos (phase_ct),
      .cos_index(cos_index1),
      .sw        ({s1, s2})
  );

  microstep_counter microstep_counter1 (
      .clk (clk), .resetn (resetn),
      .pos (phase_ct_B),
      .cos_index(cos_index2),
      .sw        ({s3, s4})
  );

  microstep_counter microstep_counter2 (
      .clk (clk), .resetn (resetn),
      .pos (phase_ct_C),
      .cos_index(cos_index3),
      .sw        ({s5, s6})
  );

  cosine cosine0 (
      .clk (clk),
      .cos_index(cos_index1),
      .cos_value(pwm1)
      //.cos_table(cos_table)
  );

  cosine cosine1 (
      .clk (clk),
      .cos_index(cos_index2),
      .cos_value(pwm2)
      //.cos_table(cos_table)
  );

  cosine cosine2 (
      .clk (clk),
      .cos_index(cos_index3),
      .cos_value(pwm3)
      //.cos_table(cos_table)
  );

  analog_out analog_out0 (
      .clk        (clk),
      .resetn     (enable_in),
      .pwm1       (pwm1),
      .pwm2       (pwm2),
      .pwm3       (pwm3),
      .analog_out1(analog_out1),
      .analog_out2(analog_out2),
      .analog_out3(analog_out3),
      .current_threshold (config_current_threshold)
  );

endmodule
