module mytimer_10 (
    clk,
    resetn,
    start_enable,
    start_time,
    timer
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
