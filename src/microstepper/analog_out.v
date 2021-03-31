// SPDX-License-Identifier: ISC
`default_nettype none

module analog_out (
    input  wire       clk,
    input  wire       resetn,
    input  wire [7:0] pwm1,
    input  wire [7:0] pwm2,
    output wire       analog_out1,
    output wire       analog_out2,
    input wire [10:0] current_threshold
);

  reg [10:0] pwm_counter;
  reg [7:0] pwm1_r;
  reg [7:0] pwm2_r;

  always @(posedge clk) begin
    if (!resetn) begin
      pwm_counter <= 0;
    end
    else begin
      if (pwm_counter <= current_threshold)
        pwm_counter <= pwm_counter + 1'b1;
      else begin
        pwm_counter <= 0;
        pwm1_r <= pwm1;
        pwm2_r <= pwm2;
      end
    end
  end
  assign analog_out1 = (resetn) ? pwm_counter < {3'b0, pwm1_r} : 0;
  assign analog_out2 = (resetn) ? pwm_counter < {3'b0, pwm2_r} : 0;

endmodule
