`default_nettype none

module mytimer (
    clk,
    resetn,
    start_enable,
    start_time,
    timer
);
  parameter WIDTH = 10;

  input clk;
  input resetn;
  input start_enable;
  input [WIDTH-1:0] start_time;
  output [WIDTH-1:0] timer;

  reg [WIDTH-1:0] counter;

  assign timer = counter;

  always @(posedge clk) begin
  if (!resetn)
    counter <= 0;
  else if( start_enable )
    counter <= start_time;
  else if( counter > 0 )
    counter <= counter - 1'b1;
end

endmodule
