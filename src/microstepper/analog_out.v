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
  assign analog_out1 = pwm_counter <= pwm1;
  assign analog_out2 = pwm_counter <= pwm2;

endmodule
