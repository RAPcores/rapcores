`default_nettype none

module step_encoder #(parameter width = 32)
(
  input clk,
  input resetn,
  input step,
  input dir,
  output [width-1:0] count
);

  reg signed [width-1:0] count_r;
  assign count = count_r;

  reg [1:0] step_r;

  always @(posedge clk) if (!resetn) begin
    count_r <= 0;
    step_r <= 2'b0;
  end else if (resetn) begin
    step_r <= {step_r[1], step};
    if (step_r == 2'b01) begin
      count_r <= (dir) ? count_r + 1'b1 : count_r - 1'b1;
    end
  end

endmodule