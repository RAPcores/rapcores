module gray_count #(
    parameter bits = 4
  ) (
    input clk,
    output wire [bits-1:0] gray_count
  );

  reg [bits-1:0] cnt_gray = 0;
  assign gray_count = cnt_gray;

  wire [bits-1:0] cnt_cc = {cnt_cc[bits-2:1] & ~cnt_gray[bits-3:0], ^cnt_gray, 1'b1};  // carry-chain type logic
  always @(posedge clk) begin
    cnt_gray <= cnt_gray ^ cnt_cc ^ cnt_cc[bits-1:1];
  end
endmodule
