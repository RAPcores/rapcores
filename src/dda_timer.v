`default_nettype none

module dda_timer(
  input CLK,
  input [7:0] clock_divisor,
  input [63:0] move_duration,
  input [63:0] increment,
  input [63:0] incrementincrement,
  input [`MOVE_BUFFER_SIZE:0] stepready,
  output [`MOVE_BUFFER_SIZE:0] stepfinished,
  output [`MOVE_BUFFER_BITS:0] moveind, // DDA buffer index
  input [`MOVE_BUFFER_BITS:0] writemoveind, // State Machine index
  output step,
  `ifdef HALT
    input halt,
  `endif
  `ifdef MOVE_DONE
    output move_done
  `endif
);

  // Locals
  reg [63:0] tickdowncount;  // move down count (clock cycles)
  reg [7:0] clkaccum = 8'b1;  // intra-tick accumulator

  reg signed [63:0] substep_accumulator = 0; // typemax(Int64) - 100 for buffer
  reg signed [63:0] increment_r;
  reg finishedmove = 1; // flag inidicating a move has been finished, so load next

  // Buffer managment
  reg [`MOVE_BUFFER_BITS:0] moveind = 0; // Move index cursor
  reg [`MOVE_BUFFER_SIZE:0] stepfinished = 0;

  // State managment
  wire processing_move = (stepfinished[moveind] ^ stepready[moveind]);
  wire loading_move = finishedmove & processing_move;
  wire executing_move = !finishedmove & processing_move;

  // Move done signal (alternates)
  `ifdef MOVE_DONE
    reg move_done_r = 0;
    assign move_done = move_done_r;
    reg [1:0] finishedmove_r;
    always @(posedge CLK) begin
      finishedmove_r <= {finishedmove_r[0], finishedmove};
      if (finishedmove_r == 2'b01)
        move_done_r <= ~move_done_r;
    end
  `endif

  // Step Trigger condition
  wire step = (substep_accumulator > 0);

  always @(posedge CLK) begin

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

      // DDA clock divisor
      clkaccum <= clkaccum - 8'b1;
      if (clkaccum == 8'b0) begin

        increment_r <= increment_r + incrementincrement;
        substep_accumulator <= substep_accumulator + increment_r;

        // Increment tick accumulators
        clkaccum <= clock_divisor;
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
