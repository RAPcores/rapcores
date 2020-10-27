`include "microstep_counter.v"
`include "cosine.v"
`include "analog_out.v"
`include "chargepump.v"

module microstepper_top(
input clk,
input resetn,
//input wire [7:0] position,
output [3:0] s_l,
output [3:0] s_h,
input analog_cmp1,
output analog_out1,
input analog_cmp2,
output analog_out2,
output chargepump_pin,
input step,
input dir,
input enable
);

reg [7:0] phase_ct;

always @(posedge step) begin
  phase_ct <= phase_ct + (dir ? 1 : -1);
end

//wire [17:0] position;
wire [5:0] cos_index1; 
wire [5:0] cos_index2;
wire s1; 
wire s2; 
wire s3; 
wire s4;
wire [7:0] pwm1; 
wire [7:0] pwm2;

reg [7:0] blank_timer0;
reg [7:0] blank_timer1;

wire overCurrent0 = off_timer0 > 0;
wire overCurrent1 = off_timer1 > 0;

wire fastDecay0 = off_timer0 >= 506;
wire fastDecay1 = off_timer1 >= 506;

reg [1:0] s1r, s2r, s3r, s4r;
wire phase_a1_h, phase_a1_l, phase_a2_h, phase_a2_l;
wire phase_b1_h, phase_b1_l, phase_b2_h, phase_b2_l;

assign s_h[0] = phase_a1_h;
assign s_l[0] = phase_a1_l;
assign s_h[1] = phase_a2_h;
assign s_l[1] = phase_a2_l;

assign s_h[2] = phase_b1_h;
assign s_l[2] = phase_b1_l;
assign s_h[3] = phase_b2_h;
assign s_l[3] = phase_b2_l;


assign phase_a1_h = fastDecay0 ?  s1r[1] : ~s1r[1];
assign phase_a1_l = fastDecay0 ? ~s1r[1] :  s1r[1];
assign phase_a2_h = fastDecay0 ?  s2r[1] : ~s2r[1];
assign phase_a2_l = fastDecay0 ? ~s2r[1] :  s2r[1];

assign phase_b1_h = fastDecay1 ?  s3r[1] : ~s3r[1];
assign phase_b1_l = fastDecay1 ? ~s3r[1] :  s3r[1];
assign phase_b2_h = fastDecay1 ?  s4r[1] : ~s4r[1];
assign phase_b2_l = fastDecay1 ? ~s4r[1] :  s4r[1];

//off timer0
reg [9:0] off_timer0;
always @(posedge clk) begin
  if (!resetn) 
    off_timer0 <= 0;
  else if( analog_cmp1 & blank_timer0==0 )
    off_timer0 <= 810;
  else if( off_timer0 > 0 )
    off_timer0 <= off_timer0 - 1'b1;
end

//off timer1
reg [9:0] off_timer1;
always @(posedge clk) begin
  if (!resetn) 
    off_timer1 <= 0;
  else if( analog_cmp2 & blank_timer1==0 )
    off_timer1 <= 810;
  else if( off_timer1 > 0 )
    off_timer1 <= off_timer1 - 1'b1;
end

//blank timer0
always @(posedge clk) begin
  if (!resetn) 
    blank_timer0 <= 0;
  else if ( blank_timer0 > 0 )
    blank_timer0 <= blank_timer0 - 1'b1;
end

//blank timer1
always @(posedge clk) begin
  if (!resetn) 
    blank_timer1 <= 0;
  else if ( blank_timer1 > 0 )
    blank_timer1 <= blank_timer1 - 1'b1;
end

always @(posedge clk) begin
	s1r <= { s1r[0], s1 };
	s2r <= { s2r[0], s2 };
	s3r <= { s3r[0], s3 };
	s4r <= { s4r[0], s4 };
end

chargepump cp0 (
  .clk (clk),
  .resetn (resetn), 
  .chargepump_pin (chargepump_pin)
  );

microstep_counter mc0(
  .pos (phase_ct),
  .cos_index1 (cos_index1),
  .cos_index2 (cos_index2), 
  .sw ({s1, s2, s3, s4})
  );

cosine cosine0(
  .cos_index(cos_index1),
  .cos_value(pwm1)
  );

cosine cosine1(
  .cos_index(cos_index2),
  .cos_value(pwm2)
  );

analog_out ao0(
  .clk(clk), 
  .resetn(resetn), 
  .pwm1(pwm1), 
  .pwm2(pwm2), 
  .analog_out1(analog_out1),
  .analog_out2(analog_out2)
  );

endmodule