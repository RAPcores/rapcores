`default_nettype none

module microstep_counter (
    input clk,
    input resetn,
    input  [7:0] pos,
    output reg [5:0] cos_index,
    //output [5:0] cos_index2,
    //output [5:0] cos_index3,
    output [1:0] sw
);

  assign sw[0] = pos[7:0] < 48 || 143 < pos[7:0] ? 1'b1 : 1'b0;  //0-47 144-191
  assign sw[1] = 144 > pos[7:0] > 47 ? 1'b0 : 1'b1;  //48-143

  //assign sw[0] = pos[7:0] < 48 || 143 < pos[7:0] < 240 ? 1'b1 : 1'b0;  //0-47 144-191
  //assign sw[1] = 144 > pos[7:0] > 47 || pos[7:0] > 239 ? 1'b0 : 1'b1;  //48-143

  //assign sw[2] = pos[7:0] > 79 || pos[7:0] < 176 ? 1'b1 : 1'b0;  //80-175
  //assign sw[3] = pos[7:0] < 80 || pos[7:0] > 175 ? 1'b0 : 1'b1;  //0-79 176-191

  //assign sw[4] = pos[7:0] > 15 || pos[7:0] < 112 ? 1'b1 : 1'b0;  //16-111
  //assign sw[5] = pos[7:0] < 16 || pos[7:0] > 111 ? 1'b0 : 1'b1;  //0-15 112-191

  always @(posedge clk) begin
    if(pos < 48)
      cos_index <= pos [5:0];
    else if(pos < 96)
      cos_index <= 96 - pos;
    else if(pos < 144)
      cos_index  <= pos - 96;
    else 
      cos_index  <= 192 - pos;
    /*
    if(pos < 192)
      cos_index  <= 192 - pos;
    else if(pos < 241)
      cos_index <=  pos - 192;
    else
      cos_index <= 288 - pos;
      */  
  end


  //assign cos_index1 = pos[6] == 1'b0 ? ~pos[5:0] : pos[5:0];
  //assign cos_index2 = pos[6] == 1'b0 ? pos[5:0] : ~pos[5:0];

endmodule
