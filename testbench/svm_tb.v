
module svm_tb(input  wire clk,
              input  wire resetn,
              output wire pwm,
              output wire pwm_delayed,
              output wire vref_a,
              output wire vref_b,
              output wire [11:0] vref_val_a,
              output wire [11:0] vref_val_b,
);


    localparam current_bits = 4;
    localparam microstep_bits = 8;

    wire pwm_clk = clk;
    reg [current_bits-1:0] current = 1;
    reg [7:0] phase_ct = 0;
    wire [2*(current_bits+microstep_bits)-1:0] vref_val_packed;
    assign vref_val_a = vref_val_packed[11:0];
    assign vref_val_b = vref_val_packed[23:12];

    space_vector_modulator #(
    .current_bits(current_bits),
    .microstep_bits(microstep_bits)
    )
    svm0 (.clk(clk),
            .pwm_clk(pwm_clk),
            .resetn(resetn),
            .vref_pwm({vref_b,vref_a}),
            .vref_val(vref_val_packed),
            .current(current),
            .phase_ct(phase_ct));


    always @(posedge clk) begin
        phase_ct <= phase_ct + 1'b1;
    end

endmodule