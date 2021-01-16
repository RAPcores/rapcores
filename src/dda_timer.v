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

  always @(posedge CLK) if (!resetn) begin

    substep_accumulator <= 64'b0; // typemax(Int64) - 100 for buffer
    increment_r <= 64'b0;
    step_r <= 0;

  end else if (resetn) begin

    // Load up the move duration
    if (loading_move) begin
      increment_r <= increment;
    end

    // check if this move has been done before
    if(executing_move) begin

      if (dda_tick) begin

        step_r <= 0;

        // Step taken, rollback accumulator
        if (substep_accumulator > 0) begin
          step_r <= 1;
          substep_accumulator <= substep_accumulator - 64'h7fffffffffffff9b;
        end

        increment_r <= increment_r + incrementincrement;
        substep_accumulator <= substep_accumulator + increment_r;
      end
    end
  end
endmodule
