// Built to work in one polarity
module hbridge_coil (
    input                   clk,
    input                   resetn,
    input                   low_1,
    input                   high_1,
    input                   low_2,
    input                   high_2,
    output signed   [12:0]  current,
    output                  current_sum_polarity,
    input                   polarity_invert_config,
);
    reg signed      [12:0]  current;
    reg                     polarity; // arbitrary polarity
    reg                     on;
    reg             [8:0]   cnt;
    reg                     alive;
    reg                     slow_decay;
    reg signed              current_ramp_cnt; // rates are delay counter sizes
    reg signed      [3:0]   slow_decay_cnt;
    reg signed      [1:0]   fast_decay_cnt;
    reg                     open; // coils not connected. Should never occur?
    wire                    current_sum_polarity;

    assign  current_sum_polarity = (current >= 0);
    // For each coil of motor
    // Each coil is driven by 2 half bridges. _1 and _2
    // Each half bridge is driven by two drivers. high_ and low_
    // Current goes in one direction when low_0 is on and high_1 is on.
    // Current goes the opposite direction when high_0 is on and low_1 is on.
    // set state of on for next tick
//    wire phase_negative = low_1 && high_0;
    always @(posedge clk) begin
        if (!resetn) begin
            current <= 0;
            on <= 0;
            polarity <= 0;
            cnt <= 0;
            current_ramp_cnt <= 0;
            slow_decay_cnt <= 0;
            fast_decay_cnt <= 0;
        end
        else begin
            cnt <= cnt + 1;
            current_ramp_cnt <= current_ramp_cnt + 1;
            slow_decay_cnt <= slow_decay_cnt + 1;
            fast_decay_cnt <= fast_decay_cnt + 1;
            on <= ( low_1 && high_2 ) | ( low_2 && high_1 );
            if ( polarity_invert_config )
                polarity <= high_2 && low_1;
            else
                polarity <= low_2 && high_1;
            slow_decay <= ( low_1 && low_2 ) | ( high_1 && high_2 );
            if ( on ) begin
                if ( polarity )
                    current <= current  + !current_ramp_cnt;
                else
                    current <= current - !current_ramp_cnt; // fast decay
            end
            else if ( slow_decay && current !== 0 && !slow_decay_cnt ) begin
                if (current >= 0) // current is positive
                    current <= current - 1; // slow decay every 4th tick
                else
                    current <= current + 1;
            end
        end
    end
endmodule
//(cnt[2]== 1)