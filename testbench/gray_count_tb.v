
module gray_count_tb(input  wire clk,
              input  wire resetn,
              output wire [5:0] gray_count,
              output wire [5:0] bin_count);

  gray_count #(.bits(6)) gc0 (.clk(clk),
          //.resetn (resetn),
          .gray_count(gray_count));

  gray_to_bin #(.bits(6)
  ) gb0 (
  .gray_in(gray_count),
  .bin_out(bin_count)
);

endmodule