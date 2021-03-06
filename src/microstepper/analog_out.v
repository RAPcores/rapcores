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

  always @(posedge clk) begin
    if (!resetn) begin
      pwm_counter <= 0;
    end
    else begin
      if (pwm_counter <= current_threshold)
        pwm_counter <= pwm_counter + 1'b1;
      else
        pwm_counter <= 0;
    end
  end
  assign analog_out1 = (resetn) ? pwm_counter <= {3'b0, pwm1} : 0;
  assign analog_out2 = (resetn) ? pwm_counter <= {3'b0, pwm2} : 0;

endmodule
