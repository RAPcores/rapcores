`default_nettype none

module dda_timer(
  input resetn,
  input [63:0] move_duration,
  input [63:0] increment,
  input [63:0] incrementincrement,
  input [`MOVE_BUFFER_SIZE:0] stepready,
  output reg [`MOVE_BUFFER_SIZE:0] stepfinished,
  output reg [`MOVE_BUFFER_BITS:0] moveind, // DDA buffer index
  input [`MOVE_BUFFER_BITS:0] writemoveind, // State Machine index
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

  // State managment
  wire processing_move = (stepfinished[moveind] ^ stepready[moveind]);
  wire loading_move = finishedmove & processing_move;
  wire executing_move = !finishedmove & processing_move;

  // Move done signal (alternates)
  `ifdef MOVE_DONE
    reg move_done_r;
    assign move_done = move_done_r;
    reg [1:0] finishedmove_r;
    always @(posedge CLK) if (!resetn) begin
      move_done_r <= 0;
      finishedmove_r <= 2'h0;
    end else if (resetn) begin
      finishedmove_r <= {finishedmove_r[0], finishedmove};
      if (finishedmove_r == 2'b01)
        move_done_r <= ~move_done_r;
    end
  `endif

  // Step Trigger condition
  assign step = (substep_accumulator > 0);

  always @(posedge CLK) if (!resetn) begin
    // Locals
    tickdowncount <= 64'b0;  // move down count (clock cycles)

    substep_accumulator <= 64'b0; // typemax(Int64) - 100 for buffer
    increment_r <= 64'b0;
    finishedmove <= 1; // flag inidicating a move has been finished, so load next

    // Buffer managment
    moveind <= {(`MOVE_BUFFER_BITS+1){1'b0}}; // Move index cursor
    stepfinished <= {(`MOVE_BUFFER_SIZE+1){1'b0}};

  end else if (resetn) begin

    // HALT line (active low) then reset buffer latch and index
    // TODO: Should substep accumulator reset?
    `ifdef HALT
      if (!halt) begin
        moveind <= writemoveind; // match buffer cursor
        stepfinished <= stepready; // reset latch
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

      // Step taken, rollback accumulator
      if (substep_accumulator > 0) begin
        substep_accumulator <= substep_accumulator - 64'h7fffffffffffff9b;
      end

      if (dda_tick) begin

        increment_r <= increment_r + incrementincrement;
        substep_accumulator <= substep_accumulator + increment_r;

        // Increment tick accumulators
        tickdowncount <= tickdowncount - 1'b1;
        // See if we finished the segment and incrment the buffer
        if(tickdowncount == 0) begin
          stepfinished[moveind] <= ~stepfinished[moveind];
          moveind <= moveind + 1'b1;
          finishedmove <= 1;
          `ifdef FORMAL
            assert(moveind <= `MOVE_BUFFER_SIZE);
          `endif
        end
      end
    end
  end
endmodule
