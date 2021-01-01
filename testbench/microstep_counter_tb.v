`default_nettype none

module microstep_counter_tb;

initial begin
   $dumpfile("microstep_counter_tb.vcd");
   $dumpvars(0, microstep_counter_tb);

   resetn = 0;
   # 5 resetn = 1;

   #7650 $finish;
end

initial $monitor("pos = %0d, idx = %0d, pwm = %0d", pos, cos_index, pwm );

reg resetn;
reg clk = 0;
always #5 clk = !clk;

reg [7:0] pos = 0;
always #40 pos = pos + 1;

wire [5:0] cos_index;
wire [7:0] cos_value;
wire s1, s2;

wire [8:0] inv_pwm = ~cos_value + 1;
wire [8:0] pwm = s1 ? cos_value : inv_pwm;

microstep_counter microstep_counter0 (
    .clk       (clk),
    .resetn    (resetn),
    .pos       (pos),
    .cos_index (cos_index),
    .sw        ({s2, s1})
);

cosine cosine0 (
   .clk       (clk),
   .cos_index (cos_index),
   .cos_value (cos_value)
);

endmodule
