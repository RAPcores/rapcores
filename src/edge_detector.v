// Source: https://github.com/tinyfpga/TinyFPGA-Bootloader
// Apache 2.0

module rising_edge_detector ( 
  input clk,
  input in,
  output out
);
  reg in_q;

  always @(posedge clk) begin
    in_q <= in;
  end

  assign out = !in_q && in;
endmodule

module falling_edge_detector ( 
  input clk,
  input in,
  output out
);
  reg in_q;

  always @(posedge clk) begin
    in_q <= in;
  end

  assign out = in_q && !in;
endmodule



module rising_edge_detector_tribuf ( 
  input clk,
  input in,
  output out
);
  reg [2:0] in_q;

  always @(posedge clk) begin
    in_q <= {in_q[1:0], in};
  end

  assign out = (in_q == 3'b001);
endmodule

module falling_edge_detector_tribuf ( 
  input clk,
  input in,
  output out
);
  reg [2:0] in_q;

  always @(posedge clk) begin
    in_q <= {in_q[1:0], in};
  end

  assign out = (in_q == 3'b100);
endmodule