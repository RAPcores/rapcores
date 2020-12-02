module mytimer_10 (
    input clk,
    input resetn,
    input start_enable,
    input start_time,
    output timer
);

  mytimer #(
      .WIDTH(10)
  ) mytimer10 (
      .clk         (clk),
      .resetn      (resetn),
      .start_enable(start_enable),
      .start_time  (start_time),
      .timer       (timer)
  );

endmodule
