`default_nettype none

module dda_timer(
  input resetn,
  input [63:0] increment,
  input [63:0] incrementincrement,
  input  loading_move,
  input  executing_move,
  output step,
  input dda_tick,
  input CLK
);

  reg signed [63:0] substep_accumulator; // typemax(Int64) - 100 for buffer
  reg signed [63:0] increment_r;

  // Step Trigger condition
  reg step_r;
  assign step = step_r;

  reg [1:0] tick_r;

  always @(posedge CLK) if (!resetn) begin

    substep_accumulator <= 64'b0; // typemax(Int64) - 100 for buffer
    increment_r <= 64'b0;
    step_r <= 0;

  end else if (resetn) begin

    // Load up the move duration
    if (loading_move) begin
      increment_r <= increment;
    end

    // catch tick rising edge
    tick_r <= {tick_r[1], dda_tick};

    if(tick_r == 2'b01) begin

      // Step taken, rollback accumulator
      if (substep_accumulator > 0) begin
        step_r <= 1;
        substep_accumulator <= substep_accumulator - 64'h7fffffffffffff9b;
      end else begin
        step_r <= 0;
      end

      if (executing_move) begin
        increment_r <= increment_r + incrementincrement;
        substep_accumulator <= substep_accumulator + increment_r;
      end
    end
  end
endmodule
