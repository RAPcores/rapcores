module stepper (
    input  CLK,  // 16MHz clock
    output phase_a1,  // Phase A
    output phase_a2,  // Phase A
    output phase_b1,  // Phase B
    output phase_b2,  // Phase B
    output pwm_a,
    output pwm_b,
    input [23:0] duration,
    input start,
    output LED
);

  // keep track of time and location in blink_pattern
  reg [23:0] move_ticks = 0;
  reg [23:0] last_step_tick = 0;
  wire phase_a1, phase_a2, phase_b1, phase_b2;  //, pwm_a, pwm_b, stby;

  reg [2:0] microsteps;
  assign microsteps = 2;

  reg [31:0] phase_ct;
  assign pwm_a = 1;  // phase a pwm TODO: microstep
  assign pwm_b = 1;  // phase b pwm

  // increment the move_ticks every clock
  always @(posedge CLK) begin
    move_ticks <= move_ticks + 1;
    LED <= (move_ticks < duration);
    if (((move_ticks - last_step_tick) >= (50000 / microsteps)) && start) begin
      last_step_ticks <= move_ticks;
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
    end else begin
      start <= 0;
      last_step_tick <= 0;
      move_ticks <= 0;
    end
  end

endmodule
