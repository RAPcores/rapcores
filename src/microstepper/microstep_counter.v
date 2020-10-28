module microstep_counter(
input [7:0] pos,
output [5:0] cos_index1,
output [5:0] cos_index2,
output [3:0] sw
);

assign sw[0] = pos[7:0] < 64 || pos[7:0] > 191 ? 1'b1 : 1'b0; //0-63 192-255
assign sw[1] = pos[7:0] < 64 || pos[7:0] > 191 ? 1'b0 : 1'b1; //64-191
assign sw[2] = pos[7:0] < 128 ? 1'b1 : 1'b0; //0-127
assign sw[3] = pos[7:0] < 128 ? 1'b0 : 1'b1; //128-255

assign cos_index1 = pos[6] == 1'b0 ? ~pos[5:0] :  pos[5:0];    //  /\/\
assign cos_index2 = pos[6] == 1'b0 ?  pos[5:0] : ~pos[5:0];    //  \/\/

endmodule
