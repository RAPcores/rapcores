// SPDX-License-Identifier: ISC
`default_nettype none

module mytimer (
    input               clk,
    input               resetn,
    input               start_enable,
    input  [WIDTH-1:0]  start_time,
    output [WIDTH-1:0]  timer,
    output        reg   done // single cycle timer done event
);
  parameter WIDTH = `DEFAULT_TIMER_WIDTH;

  reg run;
  reg [WIDTH-1:0] counter;
  assign timer = counter;

  always @(posedge clk) begin
  if (!resetn) begin
    counter <= 0;
    run <= 0;
    done <= 0;
  end
  else if( start_enable ) begin
    counter <= start_time;
    run <= 1;
  end
  else if( counter > 0 )
    counter <= counter - 1'b1;
  else if (run)
    done <= 1;
  if (done) begin
    run <= 0;
    done <= 0;
  end
end

endmodule
