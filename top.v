// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    output PIN_24, // Phase A
    output PIN_23, // Phase A
    output PIN_22, // Phase B
    output PIN_21, // Phase B
);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // keep track of time and location in blink_pattern
    reg [25:0] blink_counter;

    // pattern that will be flashed over the LED over time
    wire [31:0] blink_pattern = 32'b101010001110111011100010101;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        blink_counter <= blink_counter + 1;

        case (blink_counter[25:21]%4)
            0: begin // 1010
                PIN_24 <= 1;
                PIN_23 <= 0;
                PIN_22 <= 1;
                PIN_21 <= 0;
            end
            1:  begin // 0110
                PIN_24 <= 0;
                PIN_23 <= 1;
                PIN_22 <= 1;
                PIN_21 <= 0;
            end
            2:  begin //0101
                PIN_24 <= 0;
                PIN_23 <= 1;
                PIN_22 <= 0;
                PIN_21 <= 1;
            end
            3:  begin //1001
                PIN_24 <= 1;
                PIN_23 <= 0;
                PIN_22 <= 0;
                PIN_21 <= 1;
            end
        endcase
    end

    // light up the LED according to the pattern
    assign LED = blink_pattern[blink_counter[25:21]];
endmodule
