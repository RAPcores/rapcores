module mytimer_8 (
    input clk,
    input resetn,
    input start_enable,
    input start_time,
    output timer
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
