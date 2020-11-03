module mytimer (
    input        clk,
    input        resetn,
    input        start_enable,
    input  [9:0] start_time,
    output [9:0] timer
);

  reg [9:0] counter;

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
