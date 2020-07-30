`include "stepper.v"
`include "spi.v"

module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    input PIN_1,
    input PIN_2,
    input PIN_3,
    input PIN_4,
    output PIN_8, // Phase A
    output PIN_9, // Phase A
    output PIN_11, // Phase B
    output PIN_12, // Phase B
    output PIN_24,
    output PIN_23,
    output PIN_22,
    output PIN_21,
    output PIN_20,
    output PIN_7,
    output PIN_13,
    input PIN_14,
    input PIN_15,
    input PIN_16,
    input PIN_17);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire byte_received;  // high when a byte has been received
    reg [7:0] byte_data_received;

    reg [7:0] spi_send_data;

    stepper s0 (.CLK (CLK),
                .phase_a1 (PIN_8),
                .phase_a2 (PIN_9),
                .phase_b1 (PIN_11),
                .phase_b2 (PIN_12),
                .pwm_a (PIN_7),
                .pwm_b (PIN_13));
    // LED Stepper
    // stepper s1 (.CLK (CLK),
    //              .phase_a1 (PIN_24),
    //              .phase_a2 (PIN_23),
    //              .phase_b1 (PIN_22),
    //              .phase_b2 (PIN_21),
    //              .pwm_a (),
    //              .pwm_b ());

    spi spi0(.clk(CLK),
            .SCK(PIN_1),
            .SSEL(PIN_2),
            .MOSI(PIN_3),
            .MISO(PIN_4),
            .send_data(spi_send_data),
            .byte_received(byte_received),
            .byte_data_received(byte_data_received) );


    always @(posedge byte_received) begin
        PIN_20 <= ~PIN_20;
        PIN_24 = byte_data_received[0];
        PIN_23 = byte_data_received[1];
        PIN_22 = byte_data_received[2];
        spi_send_data <= byte_data_received;
    end

endmodule
