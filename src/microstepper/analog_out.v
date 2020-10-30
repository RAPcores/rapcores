module analog_out (
    input  wire       clk,
    input  wire       resetn,
    input  wire [7:0] pwm1,
    input  wire [7:0] pwm2,
    output wire       analog_out1,
    output wire       analog_out2
);

  reg [9:0] pwm_counter;

  always @(posedge clk) if (resetn) pwm_counter <= pwm_counter + 1'b1;

  assign analog_out1 = pwm_counter <= pwm1;
  assign analog_out2 = pwm_counter <= pwm2;

endmodule
