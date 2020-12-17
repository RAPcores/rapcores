`default_nettype none

module quad_enc #(
    parameter encbits = 64
  )(
  input wire resetn,
  input wire  clk,
  input wire  a,
  input wire  b,
  output reg faultn,
  output reg signed [encbits-1:0] count,
  input [7:0] multiplier
  );

//  wire faultn;

  reg [2:0] a_stable, b_stable;  //Hold sample before compare for stability

  wire step_a = a_stable[1] ^ a_stable[2];  //Step if a changed
  wire step_b = b_stable[1] ^ b_stable[2];  //Step if b changed
  wire step = step_a ^ step_b;  //Step if a xor b stepped
  wire direction = a_stable[1] ^ b_stable[2];  //Direction determined by comparing current sample to last

  always @(posedge clk) begin
    a_stable <= {a_stable[1:0], a};  //Shift new a in. Last 2 samples shift to bits 2 and 1
    b_stable <= {b_stable[1:0], b};  //Shift new b in

    if (!resetn) begin
      count <= 0;  //reset count
      faultn <= 1; //reset faultn
    end
    else begin
      if (step_a && step_b)  //We do not know direction if both inputs triggered on single clock
        faultn <= 0;
      if (step) begin
        if (direction)
          count <= count + { 56'b0, multiplier};
        else
          count <= count - { 56'b0, multiplier};
      end
    end
  end
endmodule
