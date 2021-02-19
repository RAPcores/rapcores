// Dummy PLL module for sim

module pwm_pll(
	input  wire clock_in,
	output wire clock_out,
	output wire locked
	);

  assign clock_out = clock_in;

endmodule
