module bin_to_gray #(
  parameter bits = 4
) (
  input wire [bits-1:0] bin_in,
  output wire [bits-1:0] gray_out
);
    genvar i;
    assign gray_out[bits-1] = bin_in[bits-1];
    for (i=bits-1; i>0; i = i - 1)
        assign gray_out[i-1] = bin_in[i] ^ bin_in[i - 1];
endmodule