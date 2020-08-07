`default_nettype none

module stepper (
    output phase_a1,  // Phase A
    output phase_a2,  // Phase A
    output phase_b1,  // Phase B
    output phase_b2,  // Phase B
    output pwm_a,
    output pwm_b,
    input step,
    input dir,
    input [2:0] microsteps
);

  reg [31:0] phase_ct;
  assign pwm_a = 1;  // phase a pwm TODO: microstep
  assign pwm_b = 1;  // phase b pwm

  // increment the move_ticks every clock
  always @(posedge step) begin
    phase_ct <= phase_ct + 1;

    if (microsteps == 0 || microsteps == 1) begin
      // TODO: Test sync vs async (on scope)
      // TODO: Function?
      // 1010
      // 0110
      // 0101
      // 1001
      case (phase_ct % 4)
        0: begin  // 1010
          phase_a1 <= 1'b1;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b1;
          phase_b2 <= 1'b0;
        end
        1: begin  // 0110
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b1;
          phase_b1 <= 1'b1;
          phase_b2 <= 1'b0;
        end
        2: begin  //0101
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b1;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b1;
        end
        3: begin  //1001
          phase_a1 <= 1'b1;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b1;
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
          phase_a1 <= 1'b1;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b1;
          phase_b2 <= 1'b0;
        end
        1: begin  // 0010
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b1;
          phase_b2 <= 1'b0;
        end
        2: begin  // 0110
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b1;
          phase_b1 <= 1'b1;
          phase_b2 <= 1'b0;
        end
        3: begin  // 0100
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b1;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b0;
        end
        4: begin  // 0101
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b1;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b1;
        end
        5: begin  // 0001
          phase_a1 <= 1'b0;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b1;
        end
        6: begin  // 1001
          phase_a1 <= 1'b1;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b1;
        end
        7: begin  // 1000
          phase_a1 <= 1'b1;
          phase_a2 <= 1'b0;
          phase_b1 <= 1'b0;
          phase_b2 <= 1'b0;
        end
      endcase
    end
  end

endmodule
