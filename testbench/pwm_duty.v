// Calculate PWM Duty - cycle by cycle
module pwm_duty(
    input           clk,
    input           pwm,
    input           resetn,
    output  [12:0]  duty,
    );
    reg [1:0] edge_b;
    reg [11:0] cnt_h;
    reg [11:0] cnt_l;
    wire s_edge = edge_b[1] ^ edge_b[0];
    wire pwm;

    reg   [12:0]   duty;

    always @(posedge clk) begin
        if (!resetn) begin
            cnt_h <= 0;
            cnt_l <= 0;
            duty <= 0;
        end
        else begin
            if (s_edge && edge_b[0]) begin // Rising edge
                duty <=  8191 * cnt_h / (cnt_h + cnt_l) ;
                cnt_h <= 0;
                cnt_l <= 0;
            end
            else begin
                if (edge_b[1]) begin
                    cnt_h <= cnt_h + 1;
                end
                else if (!edge_b[1]) begin
                    cnt_l <= cnt_l + 1;
                end
            end
        end
        edge_b = {edge_b[0], pwm};
    end

endmodule
