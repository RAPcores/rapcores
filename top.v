`include "stepper.v"
`include "spi.v"

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
    output PIN_13,
    input PIN_14,
    input PIN_15,
    input PIN_16,
    input PIN_17);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire byte_received;  // high when a byte has been received
    wire [7:0] byte_data_received;
    wire [7:0] packet_received;

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
            .SCK(PIN_14),
            .SSEL(PIN_15),
            .MOSI(PIN_16),
            .MISO(PIN_17),
            .send_data(spi_send_data),
            .byte_received(byte_received),
            .rx_data( {byte_data_received, packet_received} ) );


    always @(posedge byte_received) begin
        PIN_23 <= ~PIN_23;
        case (byte_data_received)
            //led_pwm_value = byte_data_received;
            1: PIN_24 <= 1;

            2: PIN_24 <= 0;
        endcase
    end

endmodule
