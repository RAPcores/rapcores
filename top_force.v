`include "quad.v"
`timescale 1ns/100ps
module top(
  input clk, 
//  input quadA, input quadB,
  output LED0,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output LED5,
  output LED6,
  output LED7
  );

  wire quadA, quadB;
  reg [31:0] count1, count2;
  //reg [15:0] clocks = 0;
  reg resetn;
  //reg count_en;
  wire resetn;
  reg[7:0] resetn_counter = 0;

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end

  quad quad1(.resetn(resetn), .clk(clk), .quadA(quadA), .quadB(quadB), .count(count1));
  quad quad2(.resetn(resetn), .clk(clk), .quadA(quadB), .quadB(quadA), .count(count2));

  initial begin
    quadA <= 0;
    quadB <= 0;
  end

  reg [3:0] quadcntA = 0;
  reg [3:0] quadcntB = 4;

  reg [20:0] cnt = 0;

  always @(posedge clk)
  begin
    if (!resetn)
      cnt = 0;
    cnt <= cnt +1;
    if (cnt >= 20'hFFFF) begin
      quadcntA <= quadcntA + 1;
      quadA <= quadcntA[3];
      quadcntB <= quadcntB - 1;
      quadB <= quadcntB[3];
      cnt <=0;
    end
  end

  assign {LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7} = count1[7:0];

endmodule



