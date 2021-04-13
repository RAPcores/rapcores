// Source: https://github.com/tinyfpga/TinyFPGA-Bootloader
// Apache 2.0


/*
Parameteric Edge detector

  parameters:
    mode: either "rising" or "falling"
    buffered: if true, use a tribuffer to sync with clock, detection delay one cycle
*/
module edge_detector #(
  parameter mode = "rising",
  parameter buffered = 1)
  (
  input clk,
  input in,
  output out
);

  if (buffered) reg [2:0] in_q;
  else reg in_q;

  always @(posedge clk) begin
    if (buffered) in_q <= {in_q[1:0], in};
    else in_q <= in;
  end

  if (buffered) begin
    if (mode == "rising") assign out = (in_q[2:1] == 2'b01);
    else assign out = (in_q[2:1] == 2'b10);
  end else begin
    if (mode == "rising") assign out = !in_q && in;
    else assign out = in_q && !in;
  end
endmodule
