module mytimer_10 (
    clk,
    resetn,
    start_enable,
    start_time,
    timer
);
  localparam WIDTH = 10;

  input clk;
  input resetn;
  input start_enable;
  input [WIDTH-1:0] start_time;
  output [WIDTH-1:0] timer;

  mytimer #(
      .WIDTH(WIDTH)
  ) mytimer10 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(start_enable),
      .start_time  (start_time),
      .timer       (timer)
  );

endmodule
