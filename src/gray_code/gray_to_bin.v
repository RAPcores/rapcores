module gray_to_bin #(
  parameter   bits = 4
) (
  input  wire  [bits-1:0]   gray_in,
  output wire  [bits-1:0]   bin_out
);
 
  genvar i;


  assign bin_out[bits-1] = gray_in[bits-1];

  generate
  for (i=bits-2; i >= 0; i=i-1) begin
    assign bin_out[i] = ^gray_in[bits-1:i];
  end
  endgenerate
      
endmodule