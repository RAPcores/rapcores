// SPDX-License-Identifier: ISC
`default_nettype none

module dda_timer #(parameter dda_bits = 64)
(
  input resetn,
  input [dda_bits-1:0] increment,
  input [dda_bits-1:0] incrementincrement,
  input  loading_move,
  input  executing_move,
  output step,
  input dda_tick,
  input CLK
);

  reg [dda_bits-1:0] substep_accumulator; // typemax(Int64) - 100 for buffer
  reg signed [dda_bits-1:0] increment_r;

  // Step assumulate condition
  wire dda_tick_rising;
  rising_edge_detector dda_rising (.clk(CLK), .in(dda_tick), .out(dda_tick_rising));

  // Step trigger when top bit changes
  wire step_f, step_r;
  rising_edge_detector step_rising (.clk(CLK), .in(substep_accumulator[dda_bits-1]), .out(step_r));
  falling_edge_detector step_falling (.clk(CLK), .in(substep_accumulator[dda_bits-1]), .out(step_f));

  assign step = step_r | step_f;

  always @(posedge CLK) if (!resetn) begin

    substep_accumulator <= {dda_bits{1'b0}}; // typemax(Int64) - 100 for buffer
    increment_r <= {dda_bits{1'b0}};

  end else if (resetn) begin

    // Load up the move duration
    if (loading_move) begin
      increment_r <= increment;
    end

    if(dda_tick_rising) begin

      if (executing_move) begin

        increment_r <= increment_r + incrementincrement;
        substep_accumulator <= substep_accumulator + increment_r;
      end
    end
  end
endmodule
