`default_nettype none

/*
Manage move buffers and DDA timing length
*/
module dda_fsm #(parameter buffer_bits = 2,
                 parameter buffer_size = 1,
                 parameter move_duration_bits = 32)
(
  input clk,
  input resetn,
  input dda_tick,
  input [move_duration_bits-1:0] move_duration,
  output loading_move,
  output executing_move,
  output move_done,
  output [buffer_bits-1:0] moveind,
  input [buffer_size-1:0] stepready,
  output buffer_dtr
);


  // Buffer latching
  reg [buffer_size-1:0] stepfinished;

  assign moveind = moveind_r;
  reg [buffer_bits-1:0] moveind_r;

  // State managment
  wire finishedmove = finishedmove_r;
  wire processing_move = (stepfinished[moveind] ^ stepready[moveind]);
  assign loading_move = finishedmove & processing_move;
  assign executing_move = !finishedmove & processing_move;

  reg [move_duration_bits-1:0] tickdowncount;
  reg move_done_r;
  reg finishedmove_r;
  reg [1:0] dda_tick_r;

  always @(posedge clk) if (!resetn) begin
    move_done_r <= 0;
    finishedmove_r <= 1; // set 1 init so we are in 'loading_move'
    stepfinished <= 0;
    moveind_r <= 0;
  end else if (resetn) begin

    if (loading_move) begin
      tickdowncount <= move_duration;
      finishedmove_r <= 0;
    end

    // catch rising edge on DDA tick and downcount
    dda_tick_r <= {dda_tick_r[0], dda_tick};
    if (dda_tick_r == 2'b01 && executing_move) begin
      tickdowncount <= tickdowncount - 1'b1;
    end

    // Trigger move finished
    if (tickdowncount == 0 && executing_move) begin
      finishedmove_r <= 1;
      move_done_r <= ~move_done_r;
      moveind_r <= moveind_r + 1'b1;
      stepfinished[moveind] <= ~stepfinished[moveind]; // flip latch to done
    end
  end

  // Buffer flow control outputs
  assign move_done = move_done_r;
  assign buffer_dtr = ~(~stepfinished == stepready);


endmodule