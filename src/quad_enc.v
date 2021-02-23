`default_nettype none

module quad_enc #(
    parameter encbits = 64
  )(
  input wire resetn,
  input wire  clk,
  input wire  a,
  input wire  b,
  input wire  i,
  output reg faultn,
  output reg signed [encbits-1:0] count,
  output wire step_a,
  output wire step_b,
  output wire step_i
  //input [7:0] multiplier
  );

//  wire faultn;

  reg [2:0] a_stable, b_stable, i_stable;  //Hold sample before compare for stability

  assign step_a = a_stable[1] ^ a_stable[2];  //Step if a changed
  assign step_b = b_stable[1] ^ b_stable[2];  //Step if b changed
  assign step_i = i_stable[1] ^ i_stable[2];  //Step if b changed
  wire step = step_a ^ step_b;  //Step if a xor b stepped
  wire direction = a_stable[1] ^ b_stable[2];  //Direction determined by comparing current sample to last

  always @(posedge clk) begin
    if (!resetn) begin
      count <= 0;  //reset count
      faultn <= 1'b1; //reset faultn
      a_stable <= 3'b0;
      b_stable <= 3'b0;
    end
    else begin
      a_stable <= {a_stable[1:0], a};  //Shift new a in. Last 2 samples shift to bits 2 and 1
      b_stable <= {b_stable[1:0], b};  //Shift new b in
      i_stable <= {i_stable[1:0], i};

      if (step_a && step_b)  //We do not know direction if both inputs triggered on single clock
        faultn <= 0;
      if (step) begin
        if (direction)
          count <= count + 1'b1; //{ 56'b0, multiplier};
        else
          count <= count - 1'b1; //{ 56'b0, multiplier};
      end
    end
  end
endmodule
