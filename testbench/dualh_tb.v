
module dualh_tb(input  wire clk,
              input  wire resetn,
              output wire A1,
              output wire A2,
              output wire B1,
              output wire B2,
              output wire VREF_A,
              output wire VREF_B);


        reg dir = 1;
        wire step;
        reg enable = 1;
        reg brake = 1;
        reg [7:0] current = 8'd80;
        reg [1:0] microsteps = 8'd1;

        dual_hbridge s0 (.clk (clk),
                        .resetn(resetn),
                        .phase_a1 (A1),
                        .phase_a2 (A2),
                        .phase_b1 (B1),
                        .phase_b2 (B2),
                        .vref_a (VREF_A),
                        .vref_b (VREF_B),
                        .step (step),
                        .dir (dir),
                        .enable (enable),
                        .brake  (brake),
                        .microsteps (microsteps),
                        .current (current));

endmodule