module stepper (
    input CLK,    // 16MHz clock
    output phase_a1, // Phase A
    output phase_a2, // Phase A
    output phase_b1, // Phase B
    output phase_b2 // Phase B
);

    // keep track of time and location in blink_pattern
    reg [25:0] blink_counter;
    reg phase_a1, phase_a2, phase_b1, phase_b2;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        blink_counter <= blink_counter + 1;

        case (blink_counter[25:21]%4)
            0: begin // 1010
                phase_a1 = 1;
                phase_a2 = 0;
                phase_b1 = 1;
                phase_b2 = 0;
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

endmodule

module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    output PIN_24, // Phase A
    output PIN_23, // Phase A
    output PIN_22, // Phase B
    output PIN_21 // Phase B
);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    stepper s0 (.CLK (CLK),
                .phase_a1 (PIN_24),
                .phase_a2 (PIN_23),
                .phase_b1 (PIN_22),
                .phase_b2 (PIN_21));

endmodule
