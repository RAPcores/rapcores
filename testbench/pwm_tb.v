
module pwm_tb(input  wire clk,
              input  wire resetn,
              output wire pwm,
              output wire pwm_delayed);

  pwm #(.bits(8)) va (.clk(clk),
          .resetn (resetn),
          .val(8'd7),
          .pwm(pwm));

  pwm_delayed #(.bits(8)) vd (.clk(clk),
          .resetn (resetn),
          .delay(8'd7),
          .val(8'd7),
          .pwm(pwm_delayed));

endmodule