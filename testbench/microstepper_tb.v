`include "../src/microstepper/microstepper_top.v"
`include "coil.v"
`include "pwm_duty.v"
`timescale 1ns/100ps

module testbench(
    input           clk,
    output  [3:0]   s_l,
    output  [3:0]   s_h,
    output          analog_cmp1,
    output          analog_out1,
    output          analog_cmp2,
    output          analog_out2,
    output          chargepump_pin,
    output          fault,
    output [12:0]   target_current1,
);

    reg             step;
    reg             dir;
    reg             enable;
    reg     [12:0]  target_current1;
    reg     [12:0]  target_current2;
    reg     [12:0]  current1;
    reg     [12:0]  current2;
    reg     [9:0]   config_offtime;
    reg     [7:0]   config_blanktime;
    reg     [9:0]   config_fastdecay_threshold;
    reg     [7:0]   config_minimum_on_time;
    reg     [10:0]  config_current_threshold;
    reg     [7:0]   config_chargepump_period;
    reg             config_invert_highside;
    reg             config_invert_lowside;

    wire resetn;
    reg [7:0] resetn_counter = 0;
    
    assign resetn = &resetn_counter;
    always @(posedge clk) begin
        if (!resetn) resetn_counter <= resetn_counter +1;
    end

    reg             analog_cmp1;
    reg             analog_cmp2;
    reg     [40:0]  step_clock;
    reg     [20:0]  cnt;
    always @(posedge clk) begin
        if (!resetn) begin
            cnt <= 0;
            analog_cmp1 <= 0;
            analog_cmp2 <= 0;
            step <= 1;
            enable <= 1;
            config_offtime = 810;
            config_blanktime = 27;
            config_fastdecay_threshold = 706;
            config_minimum_on_time = 54;
            config_current_threshold = 1024;
            config_chargepump_period = 91;
            config_invert_highside = 0;
            config_invert_lowside = 0;
            step_clock = 0;
        end
        else begin
            cnt <= cnt + 1;
            step_clock <= step_clock + 1;
            step <= step_clock[11];
            if (current1 > target_current1) analog_cmp1 <= 1;
            else analog_cmp1 <= 0;
            if (current2 > target_current2) analog_cmp2 <= 1;
            else analog_cmp2 <= 0;
            if (cnt <= 20'hAEC) begin
                dir <= 1;
            end
            else if (cnt <= 20'hEBE) begin
                dir <= 0;
            end
        end
    end

    microstepper_top stepper(
        .resetn(                        resetn                      ),
        .clk(                           clk                         ),
        .fault(                           fault                         ),
        .s_l(                           s_l                         ),
        .s_h(                           s_h                         ),
        .analog_cmp1(                   analog_cmp1                 ),
        .analog_out1(                   analog_out1                 ),
        .analog_cmp2(                   analog_cmp2                 ),
        .analog_out2(                   analog_out2                 ),
        .chargepump_pin(                chargepump_pin              ),
        .step(                          step                        ),
        .dir(                           dir                         ),
        .enable(                        enable                      ),
        .config_offtime(                config_offtime              ),
        .config_blanktime(              config_blanktime            ),
        .config_fastdecay_threshold(    config_fastdecay_threshold  ),
        .config_minimum_on_time(        config_minimum_on_time      ),
        .config_current_threshold(      config_current_threshold    ),
        .config_chargepump_period(      config_chargepump_period    ),
        .config_invert_highside(        config_invert_highside      ),
        .config_invert_lowside(         config_invert_lowside       ),
    );
    pwm_duty duty1(
        .clk(clk),
        .resetn(resetn),
        .pwm(analog_out1),
        .duty(target_current1)
    );
    pwm_duty duty2(
        .clk(clk),
        .resetn(resetn),
        .pwm(analog_out2),
        .duty(target_current2)
    );
    coil coil1(
        .clk(clk),
        .resetn(resetn),
        .s_l0(s_l[0]),
        .s_l1(s_l[1]),
        .s_h0(s_h[0]),
        .s_h1(s_h[1]),
        .current(current1)
    );
    coil coil2(
        .clk(clk),
        .resetn(resetn),
        .s_l0(s_l[2]),
        .s_l1(s_l[3]),
        .s_h0(s_h[2]),
        .s_h1(s_h[3]),
        .current(current2)
    );
endmodule

