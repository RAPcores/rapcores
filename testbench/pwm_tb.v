
module pwm_tb(input  wire clk,
              input  wire resetn,
              output wire pwm);

  pwm #(.bits(8)) va (.clk(clk),
          .resetn (resetn),
          .val(8'd7),
          .pwm(pwm));


endmodule