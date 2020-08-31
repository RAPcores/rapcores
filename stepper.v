`default_nettype none

module DualHBridge (
    output       phase_a1,  // Phase A
    output       phase_a2,  // Phase A
    output       phase_b1,  // Phase B
    output       phase_b2,  // Phase B
    input        step,
    input        dir,
    input  [2:0] microsteps
);

  reg [7:0] phase_ct; // needs to be the size of microsteps, for LUT

  reg pa1 = 1'b0;
  reg pa2 = 1'b0;
  reg pb1 = 1'b0;
  reg pb2 = 1'b0;

  assign phase_a1 = pa1;
  assign phase_a2 = pa2;
  assign phase_b1 = pb1;
  assign phase_b2 = pb2;

  // increment the move_ticks every clock
  always @(posedge step) begin
    phase_ct <= (dir) ? phase_ct - 1'b1 : phase_ct + 1'b1;

    if (microsteps == 0 || microsteps == 1) begin
      // TODO: Function?
      // 1010
      // 0110
      // 0101
      // 1001
      case (phase_ct % 4)
        0: begin  // 1010
          pa1 <= 1'b1;
          pa2 <= 1'b0;
          pb1 <= 1'b1;
          pb2 <= 1'b0;
        end
        1: begin  // 0110
          pa1 <= 1'b0;
          pa2 <= 1'b1;
          pb1 <= 1'b1;
          pb2 <= 1'b0;
        end
        2: begin  //0101
          pa1 <= 1'b0;
          pa2 <= 1'b1;
          pb1 <= 1'b0;
          pb2 <= 1'b1;
        end
        3: begin  //1001
          pa1 <= 1'b1;
          pa2 <= 1'b0;
          pb1 <= 1'b0;
          pb2 <= 1'b1;
        end
      endcase
    end else if (microsteps == 2) begin
      // 1010
      // 0010
      // 0110
      // 0100
      // 0101
      // 0001
      // 1001
      // 1000
      case (phase_ct % 8)
        0: begin  // 1010
          pa1 <= 1'b1;
          pa2 <= 1'b0;
          pb1 <= 1'b1;
          pb2 <= 1'b0;
        end
        1: begin  // 0010
          pa1 <= 1'b0;
          pa2 <= 1'b0;
          pb1 <= 1'b1;
          pb2 <= 1'b0;
        end
        2: begin  // 0110
          pa1 <= 1'b0;
          pa2 <= 1'b1;
          pb1 <= 1'b1;
          pb2 <= 1'b0;
        end
        3: begin  // 0100
          pa1 <= 1'b0;
          pa2 <= 1'b1;
          pb1 <= 1'b0;
          pb2 <= 1'b0;
        end
        4: begin  // 0101
          pa1 <= 1'b0;
          pa2 <= 1'b1;
          pb1 <= 1'b0;
          pb2 <= 1'b1;
        end
        5: begin  // 0001
          pa1 <= 1'b0;
          pa2 <= 1'b0;
          pb1 <= 1'b0;
          pb2 <= 1'b1;
        end
        6: begin  // 1001
          pa1 <= 1'b1;
          pa2 <= 1'b0;
          pb1 <= 1'b0;
          pb2 <= 1'b1;
        end
        7: begin  // 1000
          pa1 <= 1'b1;
          pa2 <= 1'b0;
          pb1 <= 1'b0;
          pb2 <= 1'b0;
        end
      endcase
    end
  end

endmodule
