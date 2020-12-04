// Linear current ramp
module coil (
    input           clk,
    input           resetn,
    input           s_l1,
    input           s_h1,
    input           s_l2,
    input           s_h2,
    output  [12:0]   current,
);
    reg     [12:0]   current;
    reg     [7:0]   cnt;

    wire on = (s_l1 && s_h2) | (s_l1 && s_h2);

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