// Linear current ramp
module coil (
    input           clk,
    input           resetn,
    input           s_l0,
    input           s_h0,
    input           s_l1,
    input           s_h1,
    output  [12:0]   current,
    output positive,
    output negative,
);
    reg     [12:0]   current;

    // For each coil of motor
    // Each coil is driven by s_x1 and s_x2
    // One side s_x1 or s_x2 must be high when the other is low to be on
//    wire phase_a_positive = !s_l0 && !s_h1;
//    wire phase_a_negative = !s_l1 && !s_h0;
//    wire off = s_l0;
    wire on = (!s_l0 && !s_h1) | (!s_l1 && !s_h0);
    wire positive = (!s_l0 && !s_h1);
    wire negative = (!s_l1 && !s_h0);

    always @(posedge clk) begin
        if (!resetn) begin
            current <= 0;
        end
        else begin
            if ( on ) begin  
                current <= current + 1;
            end
            else begin
                current <= 0;
            end
        end
    end
endmodule
//(cnt[2]== 1)