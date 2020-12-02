`default_nettype none
module mytimer_10 (
    input               clk,
    input               resetn,
    input               start_enable,
    input  [WIDTH-1:0]  start_time,
    output [WIDTH-1:0]  timer,
    output              done // single cycle timer done event
);

  mytimer #(
      .WIDTH(8)
  ) mytimer8 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(start_enable),
      .start_time  (start_time),
      .timer       (timer)
  );

endmodule
