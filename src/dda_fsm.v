// SPDX-License-Identifier: ISC
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
  output reg move_done,
  output reg finishedmove,
  output reg [buffer_bits-1:0] moveind,
  input [buffer_size-1:0] stepready,
  output buffer_dtr
);


  // Buffer latching
  (* onehot *) reg [buffer_size-1:0] stepfinished;

  // State managment
  wire processing_move = (stepfinished[moveind] ^ stepready[moveind]);
  assign loading_move = finishedmove & processing_move;
  assign executing_move = !finishedmove & processing_move;

  reg [move_duration_bits-1:0] tickdowncount;
  reg [1:0] dda_tick_r;

  always @(posedge clk) if (!resetn) begin
    move_done <= 0;
    finishedmove <= 1; // set 1 init so we are in 'loading_move'
    stepfinished <= 0;
    moveind <= 0;
  end else if (resetn) begin

    if (loading_move) begin
      tickdowncount <= move_duration;
      finishedmove <= 0;
    end

    // catch rising edge on DDA tick and downcount
    dda_tick_r <= {dda_tick_r[0], dda_tick};
    if (dda_tick_r == 2'b01 && executing_move) begin
      tickdowncount <= tickdowncount - 1'b1;
    end

    // Trigger move finished
    if (tickdowncount == 0 && executing_move) begin
      finishedmove <= 1;
      move_done <= ~move_done;
      moveind <= moveind + 1'b1;
      stepfinished[moveind] <= ~stepfinished[moveind]; // flip latch to done
    end
  end

  assign buffer_dtr = ~(~stepfinished == stepready);


endmodule