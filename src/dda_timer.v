`default_nettype none

module dda_timer(
  input resetn,
  input [63:0] move_duration,
  input [63:0] increment,
  input [63:0] incrementincrement,
  input processing_move,
  input loading_move,
  input executing_move,
  output finishedmove,
  output step,
  `ifdef HALT
    input halt,
  `endif
  `ifdef MOVE_DONE
    output move_done,
  `endif
  input dda_tick,
  input CLK
);

  // Locals
  reg [63:0] tickdowncount;  // move down count (clock cycles)
  reg [7:0] clkaccum;  // intra-tick accumulator

  reg signed [63:0] substep_accumulator; // typemax(Int64) - 100 for buffer
  reg signed [63:0] increment_r;
  reg finishedmove; // flag inidicating a move has been finished, so load next

  // Step Trigger condition
  reg step_r;
  assign step = step_r;

  always @(posedge CLK) if (!resetn) begin
    // Locals
    tickdowncount <= 64'b0;  // move down count (clock cycles)

    substep_accumulator <= 64'b0; // typemax(Int64) - 100 for buffer
    increment_r <= 64'b0;
    finishedmove <= 1; // flag inidicating a move has been finished, so load next
    step_r <= 0;

  end else if (resetn) begin

    // HALT line (active low) then reset buffer latch and index
    // TODO: Should substep accumulator reset?
    `ifdef HALT
      if (!halt) begin
        //moveind <= writemoveind; // match buffer cursor
        //stepfinished <= stepready; // reset latch
        finishedmove <= 1; // Puts us back in loading_move
      end
    `endif

    // Load up the move duration
    if (loading_move) begin
      tickdowncount <= move_duration;
      finishedmove <= 0;
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

        // Increment tick accumulators
        tickdowncount <= tickdowncount - 1'b1;
        // See if we finished the segment and incrment the buffer
        if(tickdowncount == 0) begin
          finishedmove <= 1;
        end
      end
    end
  end
endmodule
