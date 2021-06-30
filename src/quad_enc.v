// SPDX-License-Identifier: ISC
`default_nettype none

module quad_enc #(
    parameter encbits = 64,
    parameter enable_velocity = 1,
    parameter velocity_bits = 32
  )(
  input wire resetn,
  input wire  clk,
  input wire  a,
  input wire  b,
  output reg faultn,
  output reg signed [encbits-1:0] count,
  output reg signed [velocity_bits-1:0] velocity,
  output reg signed [velocity_bits-1:0] velocity_counter
  //input [7:0] multiplier
  );

//  wire faultn;

  reg [2:0] a_stable, b_stable, i_stable;  //Hold sample before compare for stability

  wire step_a = a_stable[1] ^ a_stable[2];  //Step if a changed
  wire step_b = b_stable[1] ^ b_stable[2];  //Step if b changed
  wire step = step_a ^ step_b;  //Step if a xor b stepped
  wire direction = a_stable[1] ^ b_stable[2];  //Direction determined by comparing current sample to last

  always @(posedge clk) begin
    if (!resetn) begin
      count <= 0;  //reset count
      velocity <= 0;
      velocity_counter <= 0;

      faultn <= 1'b1; //reset faultn
      a_stable <= 3'b0;
      b_stable <= 3'b0;
    end
    else begin
      a_stable <= {a_stable[1:0], a};  //Shift new a in. Last 2 samples shift to bits 2 and 1
      b_stable <= {b_stable[1:0], b};  //Shift new b in
      velocity_counter <= velocity_counter + 1'b1;

      if (step_a & step_b)  //We do not know direction if both inputs triggered on single clock
        faultn <= 0;
      if (step) begin
        if (direction) begin
          count <= count + 1'b1;
          velocity <= velocity_counter;
        end
        else begin
          count <= count - 1'b1;
          velocity <= -velocity_counter;
        end
        velocity_counter <= 0;
      end
    end
  end
endmodule
