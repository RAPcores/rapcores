// SPDX-License-Identifier: ISC
`default_nettype none

module dda_timer #(parameter dda_bits = 64,
  parameter phase_angle_bits = 10,
  parameter step_encoder_bits = 24
  )
(
  input resetn,
  input signed [dda_bits-1:0] increment,
  input signed [dda_bits-1:0] incrementincrement,
  input  loading_move,
  input  executing_move,
  output signed [phase_angle_bits-1:0] phase_angle,
  output signed [step_encoder_bits-1:0] step_encoder,
  output wire [dda_bits-2:0] substep_accumulator, // this is the fractional part of our fixed-point
  input dda_tick,
  input CLK
);

  // This implements a fixed point scheme suitable for carry chain optimizations and
  // allows for both implicit and explicit timing modes.
  // We use one less bit than the dda_bits (fractional) element since increments are
  // signed and we use the bottom bits of the integral portion for commutation and location
  // encoding
  reg signed [step_encoder_bits+dda_bits-2:0] accumulator;

  assign substep_accumulator = accumulator[dda_bits-2:0];
  assign phase_angle = accumulator[dda_bits+phase_angle_bits-2:dda_bits-1];
  assign step_encoder = accumulator[step_encoder_bits+dda_bits-2:dda_bits-1];


  reg signed [dda_bits-1:0] increment_r;

  // Step Trigger condition
  wire dda_tick_rising;

  rising_edge_detector dda_rising (.clk(CLK), .in(dda_tick), .out(dda_tick_rising));

  always @(posedge CLK) if (!resetn) begin

    accumulator <= 0;
    increment_r <= {dda_bits{1'b0}};

  end else if (resetn) begin

    // Load up the move duration
    if (loading_move) begin
      increment_r <= increment;
    end

    if(dda_tick_rising && executing_move) begin
      increment_r <= increment_r + incrementincrement;
      accumulator <= accumulator + increment_r;
    end
  end
endmodule
