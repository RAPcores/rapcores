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