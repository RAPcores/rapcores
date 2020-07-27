`include "stepper.v"

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
    output PIN_7,
    output PIN_13);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    stepper s0 (.CLK (CLK),
                .phase_a1 (PIN_8),
                .phase_a2 (PIN_9),
                .phase_b1 (PIN_11),
                .phase_b2 (PIN_12),
                .pwm_a (PIN_7),
                .pwm_b (PIN_13));
    stepper s1 (.CLK (CLK),
                 .phase_a1 (PIN_24),
                 .phase_a2 (PIN_23),
                 .phase_b1 (PIN_22),
                 .phase_b2 (PIN_21),
                 .pwm_a (),
                 .pwm_b ());
endmodule
