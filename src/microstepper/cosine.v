module cosine (
    input  wire [5:0] cos_index,
    output wire [7:0] cos_value
);

  reg [31:0] cos_table[0:255];

  assign cos_value = cos_table[cos_index];

  initial begin
    cos_table[0] = 8'd255;
    cos_table[1] = 8'd255;
    cos_table[2] = 8'd255;
    cos_table[3] = 8'd254;
    cos_table[4] = 8'd254;
    cos_table[5] = 8'd253;
    cos_table[6] = 8'd252;
    cos_table[7] = 8'd251;
    cos_table[8] = 8'd250;
    cos_table[9] = 8'd249;
    cos_table[10] = 8'd247;
    cos_table[11] = 8'd246;
    cos_table[12] = 8'd244;
    cos_table[13] = 8'd242;
    cos_table[14] = 8'd240;
    cos_table[15] = 8'd238;
    cos_table[16] = 8'd236;
    cos_table[17] = 8'd233;
    cos_table[18] = 8'd231;
    cos_table[19] = 8'd228;
    cos_table[20] = 8'd225;
    cos_table[21] = 8'd222;
    cos_table[22] = 8'd219;
    cos_table[23] = 8'd215;
    cos_table[24] = 8'd212;
    cos_table[25] = 8'd208;
    cos_table[26] = 8'd205;
    cos_table[27] = 8'd201;
    cos_table[28] = 8'd197;
    cos_table[29] = 8'd193;
    cos_table[30] = 8'd189;
    cos_table[31] = 8'd185;
    cos_table[32] = 8'd180;
    cos_table[33] = 8'd176;
    cos_table[34] = 8'd171;
    cos_table[35] = 8'd167;
    cos_table[36] = 8'd162;
    cos_table[37] = 8'd157;
    cos_table[38] = 8'd152;
    cos_table[39] = 8'd147;
    cos_table[40] = 8'd142;
    cos_table[41] = 8'd136;
    cos_table[42] = 8'd131;
    cos_table[43] = 8'd126;
    cos_table[44] = 8'd120;
    cos_table[45] = 8'd115;
    cos_table[46] = 8'd109;
    cos_table[47] = 8'd103;
    cos_table[48] = 8'd98;
    cos_table[49] = 8'd92;
    cos_table[50] = 8'd86;
    cos_table[51] = 8'd80;
    cos_table[52] = 8'd74;
    cos_table[53] = 8'd68;
    cos_table[54] = 8'd62;
    cos_table[55] = 8'd56;
    cos_table[56] = 8'd50;
    cos_table[57] = 8'd44;
    cos_table[58] = 8'd37;
    cos_table[59] = 8'd31;
    cos_table[60] = 8'd25;
    cos_table[61] = 8'd19;
    cos_table[62] = 8'd13;
    cos_table[63] = 8'd6;
  end
endmodule
