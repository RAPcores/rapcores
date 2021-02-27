`default_nettype none
`include "hbridge_coil.v"
`include "pwm_duty.v"
`timescale 1ns/100ps

module microstepper_tb(
    input           clk,
    output          analog_cmp1,
    output          analog_out1,
    output          analog_cmp2,
    output          analog_out2,
    output          chargepump_pin,
    output          faultn,
);

    reg                 step;
    reg                 dir;
    reg                 enable_in;
    reg         [12:0]  target_current1;
    reg         [12:0]  target_current2;
    reg signed  [12:0]  current1;
    reg signed  [12:0]  current2;
    reg         [9:0]   config_offtime;
    reg         [7:0]   config_blanktime;
    reg         [9:0]   config_fastdecay_threshold;
    reg         [7:0]   config_minimum_on_time;
    reg         [10:0]  config_current_threshold;
    reg         [7:0]   config_chargepump_period;
    reg                 config_invert_highside;
    reg                 config_invert_lowside;

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
    reg     [12:0]  current_abs1;
    reg     [12:0]  current_abs2;
    wire            phase_a1_l;
    wire            phase_a2_l;
    wire            phase_b1_l;
    wire            phase_b2_l;
    wire            phase_a1_h;
    wire            phase_a2_h;
    wire            phase_b1_h;
    wire            phase_b2_h;

    always @(posedge clk) begin
        if (!resetn) begin
            cnt <= 0;
            analog_cmp1 <= 1;
            analog_cmp2 <= 1;
            step <= 1;
            enable_in <= 1;
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
            enable_in <= 1;
            if (current1[12] == 1'b1) begin
                current_abs1 = -current1;
            end
            else begin
                current_abs1 = current1;
            end
            if (current2[12] == 1'b1) begin
                current_abs2 = -current2;
            end
            else begin
                current_abs2 = current2;
            end
            step_clock <= step_clock + 1;
            step <= step_clock[10];
            analog_cmp1 <= (current_abs1[11:0] >= target_current1[11:0]); // compare unsigned
            analog_cmp2 <= (current_abs2[11:0] >= target_current2[11:0]);
            if (cnt <= 20'h4CA9) begin
                dir <= 1;
            end
            else
                dir <= 0;
        end
    end

    microstepper_top stepper(
        .resetn(                        resetn                      ),
        .clk(                           clk                         ),
        .faultn(                        faultn                      ),
        .phase_a1_l(                    phase_a1_l                  ),
        .phase_a2_l(                    phase_a2_l                  ),
        .phase_b1_l(                    phase_b1_l                  ),
        .phase_b2_l(                    phase_b2_l                  ),
        .phase_a1_h(                    phase_a1_h                  ),
        .phase_a2_h(                    phase_a2_h                  ),
        .phase_b1_h(                    phase_b1_h                  ),
        .phase_b2_h(                    phase_b2_h                  ),
        .analog_cmp1(                   analog_cmp1                 ),
        .analog_out1(                   analog_out1                 ),
        .analog_cmp2(                   analog_cmp2                 ),
        .analog_out2(                   analog_out2                 ),
        .chargepump_pin(                chargepump_pin              ),
        .step(                          step                        ),
        .dir(                           dir                         ),
        .enable_in(                     enable_in                   ),
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
    hbridge_coil hbridge_coil1(
        .clk(clk),
        .resetn(resetn),
        .low_1(phase_a1_l),
        .high_1(phase_a1_h),
        .low_2(phase_a2_l),
        .high_2(phase_a2_h),
        .current(current1),
        .polarity_invert_config(1'b0)
    );
    hbridge_coil hbridge_coil2(
        .clk(clk),
        .resetn(resetn),
        .low_1(phase_b1_l),
        .high_1(phase_b1_h),
        .low_2(phase_b2_l),
        .high_2(phase_b2_h),
        .current(current2),
        .polarity_invert_config(1'b0)
    );
endmodule

