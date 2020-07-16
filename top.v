module stepper (
    input CLK,    // 16MHz clock
    output phase_a1, // Phase A
    output phase_a2, // Phase A
    output phase_b1, // Phase B
    output phase_b2, // Phase B
    //output pwm_a,
    //output pwm_b,
);

    // keep track of time and location in blink_pattern
    reg [25:0] blink_counter;
    wire phase_a1, phase_a2, phase_b1, phase_b2; //, pwm_a, pwm_b, stby;

    reg [31:0] phase_ct;
    //assign pwm_a = 1; // phase a pwm TODO: microstep
    //assign pwm_b = 1; // phase b pwm

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        blink_counter <= blink_counter + 1;
        if (blink_counter >= 10000000) begin
            blink_counter <= 0;
            phase_ct <= phase_ct + 1;

            case (phase_ct%4)
                0: begin // 1010
                    phase_a1 <= 1'b1;
                    phase_a2 <= 0;
                    phase_b1 <= 1;
                    phase_b2 <= 0;
                end
                1:  begin // 0110
                    phase_a1 <= 0;
                    phase_a2 <= 1;
                    phase_b1 <= 1;
                    phase_b2 <= 0;
                end
                2:  begin //0101
                    phase_a1 <= 0;
                    phase_a2 <= 1;
                    phase_b1 <= 0;
                    phase_b2 <= 1;
                end
                3:  begin //1001
                    phase_a1 <= 1;
                    phase_a2 <= 0;
                    phase_b1 <= 0;
                    phase_b2 <= 1;
                end
            endcase
        end
    end

endmodule

module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    output PIN_8, // Phase A
    output PIN_9, // Phase A
    output PIN_11, // Phase B
    output PIN_12, // Phase B
    output PIN_24,
    output PIN_23,
    output PIN_22,
    output PIN_21,
    //output PIN_7,
    //output PIN_13,
);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    stepper s0 (.CLK (CLK),
                .phase_a1 (PIN_8),
                .phase_a2 (PIN_9),
                .phase_b1 (PIN_11),
                .phase_b2 (PIN_12));
                //.pwm_a (PIN_7),
                //.pwm_b (PIN_13));
    stepper s1 (.CLK (CLK),
                .phase_a1 (PIN_24),
                .phase_a2 (PIN_23),
                .phase_b1 (PIN_22),
                .phase_b2 (PIN_21));
endmodule
