`default_nettype none

module microstep_counter (
    input clk,
    input resetn,
    input  [7:0] pos,
    output reg [5:0] cos_index,
    output [1:0] sw
);

  assign sw[0] = pos[7:0] < 48 || 143 < pos[7:0] ? 1'b1 : 1'b0;  // 0-47      144-191
  assign sw[1] = pos[7:0] < 48 || 143 < pos[7:0] ? 1'b0 : 1'b1;  //     48-143

  always @(posedge clk) begin  // Result Min-Max  // Phase Count
    if(pos < 48)                                  // 0-47
      cos_index <= pos [5:0];  // 0-47
    else if(pos < 96)                             // 48 - 95
      cos_index <= 95 - pos;   // 47-0
    else if(pos < 144)                            // 96 - 143
      cos_index  <= pos - 96;  // 0-47
    else                                          // 144 - 191+
      cos_index  <= 191 - pos; // 47-0
  end

endmodule
