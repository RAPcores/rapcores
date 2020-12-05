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

  wire s1;
  wire s2;
  wire s3;
  wire s4;

  // Off Timer active flag 
  wire off_timer_active0 = off_timer0 > 0;
  wire off_timer_active1 = off_timer1 > 0; 

  wire fastDecay0 = off_timer0 >= config_fastdecay_threshold;
  wire fastDecay1 = off_timer1 >= config_fastdecay_threshold;

  wire slowDecay0 = off_timer_active0 && fastDecay0 == 0;
  wire slowDecay1 = off_timer_active1 && fastDecay1 == 0;

  wire fault0 = (minimum_on_timer0 > 0) && off_timer_active0;
  wire fault1 = (minimum_on_timer1 > 0) && off_timer_active1;
  wire fault = fault0 | fault1;

  reg [1:0] s1r, s2r, s3r, s4r;
  wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
  wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;

  // Switch output Low
  assign s_l[0] = !(phase_a1_l | fault);
  assign s_l[1] = !(phase_a2_l | fault);
  assign s_l[2] = !(phase_b1_l | fault);
  assign s_l[3] = !(phase_b2_l | fault);

  // Switch output High
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
 
  // Start on time per half bridge
  // todo concatanate config inverting for active high or low
  wire s1_starting = s1r == 2'b10;
  wire s2_starting = s2r == 2'b10;
  wire s3_starting = s3r == 2'b10;
  wire s4_starting = s4r == 2'b10;

  // Bridge On Time start
  // Blank timer and minimum on timer enable
  //assign a_starting = s1_starting | s2_starting;
  //assign b_starting = s3_starting | s4_starting;

  // start Off Time
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

  // Shift register buffer switch output
  // Triger start on time
  always @(posedge clk) begin
    s1r <= {s1r[0], s1};
    s2r <= {s2r[0], s2};
    s3r <= {s3r[0], s3};
    s4r <= {s4r[0], s4};
  end
//
//  wire  [1:0]   off_time_b;
//  reg           a_starting;
//  reg           b_starting;

//  always @(posedge clk) begin
    //start on time
//    if 
//    a_starting <= ~off_timer0;
//    b_starting <= ~off_timer1;
    
//  end

endmodule
