// SPDX-License-Identifier: ISC
`default_nettype none
module mytimer_8 (
    input               clk,
    input               resetn,
    input               start_enable,
    input  [WIDTH-1:0]  start_time,
    output [WIDTH-1:0]  timer
);
  parameter WIDTH = 8;

  reg [WIDTH-1:0] counter;
  assign timer = counter;

  always @(posedge clk) begin
  if (!resetn) begin
    counter <= 0;
  end
  else if( start_enable ) begin
    counter <= start_time;
  end
  else if( counter > 0 )
    counter <= counter - 1'b1;
end

endmodule
