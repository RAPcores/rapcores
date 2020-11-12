module chargepump (
    input  clk,
    input  resetn,
    output chargepump_pin
);

  reg [7:0] cp_counter;
  reg       chargepump;
  assign chargepump_pin = chargepump;
  always @(posedge clk) begin
    if (!resetn) begin
      cp_counter <= 0;
      chargepump <= 0;
    end else begin
      cp_counter <= cp_counter + 1'b1;

      if (cp_counter == 215) begin
        cp_counter <= 0;
        chargepump <= ~chargepump;
      end
    end
  end

endmodule
