/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        12.000 MHz
 * Requested output frequency:  140.000 MHz
 * Achieved output frequency:   141.000 MHz
 */

module pwm_pll(
	input  clock_in,
	output clock_out,
  output wire clock_out_buffered,
	output locked
	);

SB_PLL40_2_PAD #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),		// DIVR =  0
		.DIVF(7'b0101110),	// DIVF = 46
		.DIVQ(3'b010),		// DIVQ =  2
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.PACKAGEPIN(clock_in),
		.PLLOUTGLOBALA(clock_out),
    .PLLOUTGLOBALB(clock_out_buffered)
		);

endmodule
