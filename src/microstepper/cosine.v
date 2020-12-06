`default_nettype none

module cosine (
    input  wire [5:0] cos_index,
    output wire [7:0] cos_value,
    input wire [511:0] cos_table
);

  //reg [31:0] cos_table[0:255];

  //assign cos_value = cos_table[cos_index*8+7:cos_index*8];

  reg [7:0] cos_r;
  assign cos_value = cos_r;

  always @(*)
    case (cos_index)
      1'd0	:	cos_r	<=	cos_table	 [ 	7	 : 	0	];
      1'd1	:	cos_r	<=	cos_table	 [ 	15	 : 	8	];
      2'd2	:	cos_r	<=	cos_table	 [ 	23	 : 	16	];
      2'd3	:	cos_r	<=	cos_table	 [ 	31	 : 	24	];
      3'd4	:	cos_r	<=	cos_table	 [ 	39	 : 	32	];
      3'd5	:	cos_r	<=	cos_table	 [ 	47	 : 	40	];
      3'd6	:	cos_r	<=	cos_table	 [ 	55	 : 	48	];
      3'd7	:	cos_r	<=	cos_table	 [ 	63	 : 	56	];
      4'd8	:	cos_r	<=	cos_table	 [ 	71	 : 	64	];
      4'd9	:	cos_r	<=	cos_table	 [ 	79	 : 	72	];
      4'd10	:	cos_r	<=	cos_table	 [ 	87	 : 	80	];
      4'd11	:	cos_r	<=	cos_table	 [ 	95	 : 	88	];
      4'd12	:	cos_r	<=	cos_table	 [ 	103	 : 	96	];
      4'd13	:	cos_r	<=	cos_table	 [ 	111	 : 	104	];
      4'd14	:	cos_r	<=	cos_table	 [ 	119	 : 	112	];
      4'd15	:	cos_r	<=	cos_table	 [ 	127	 : 	120	];
      5'd16	:	cos_r	<=	cos_table	 [ 	135	 : 	128	];
      5'd17	:	cos_r	<=	cos_table	 [ 	143	 : 	136	];
      5'd18	:	cos_r	<=	cos_table	 [ 	151	 : 	144	];
      5'd19	:	cos_r	<=	cos_table	 [ 	159	 : 	152	];
      5'd20	:	cos_r	<=	cos_table	 [ 	167	 : 	160	];
      5'd21	:	cos_r	<=	cos_table	 [ 	175	 : 	168	];
      5'd22	:	cos_r	<=	cos_table	 [ 	183	 : 	176	];
      5'd23	:	cos_r	<=	cos_table	 [ 	191	 : 	184	];
      5'd24	:	cos_r	<=	cos_table	 [ 	199	 : 	192	];
      5'd25	:	cos_r	<=	cos_table	 [ 	207	 : 	200	];
      5'd26	:	cos_r	<=	cos_table	 [ 	215	 : 	208	];
      5'd27	:	cos_r	<=	cos_table	 [ 	223	 : 	216	];
      5'd28	:	cos_r	<=	cos_table	 [ 	231	 : 	224	];
      5'd29	:	cos_r	<=	cos_table	 [ 	239	 : 	232	];
      5'd30	:	cos_r	<=	cos_table	 [ 	247	 : 	240	];
      5'd31	:	cos_r	<=	cos_table	 [ 	255	 : 	248	];
      6'd32	:	cos_r	<=	cos_table	 [ 	263	 : 	256	];
      6'd33	:	cos_r	<=	cos_table	 [ 	271	 : 	264	];
      6'd34	:	cos_r	<=	cos_table	 [ 	279	 : 	272	];
      6'd35	:	cos_r	<=	cos_table	 [ 	287	 : 	280	];
      6'd36	:	cos_r	<=	cos_table	 [ 	295	 : 	288	];
      6'd37	:	cos_r	<=	cos_table	 [ 	303	 : 	296	];
      6'd38	:	cos_r	<=	cos_table	 [ 	311	 : 	304	];
      6'd39	:	cos_r	<=	cos_table	 [ 	319	 : 	312	];
      6'd40	:	cos_r	<=	cos_table	 [ 	327	 : 	320	];
      6'd41	:	cos_r	<=	cos_table	 [ 	335	 : 	328	];
      6'd42	:	cos_r	<=	cos_table	 [ 	343	 : 	336	];
      6'd43	:	cos_r	<=	cos_table	 [ 	351	 : 	344	];
      6'd44	:	cos_r	<=	cos_table	 [ 	359	 : 	352	];
      6'd45	:	cos_r	<=	cos_table	 [ 	367	 : 	360	];
      6'd46	:	cos_r	<=	cos_table	 [ 	375	 : 	368	];
      6'd47	:	cos_r	<=	cos_table	 [ 	383	 : 	376	];
      6'd48	:	cos_r	<=	cos_table	 [ 	391	 : 	384	];
      6'd49	:	cos_r	<=	cos_table	 [ 	399	 : 	392	];
      6'd50	:	cos_r	<=	cos_table	 [ 	407	 : 	400	];
      6'd51	:	cos_r	<=	cos_table	 [ 	415	 : 	408	];
      6'd52	:	cos_r	<=	cos_table	 [ 	423	 : 	416	];
      6'd53	:	cos_r	<=	cos_table	 [ 	431	 : 	424	];
      6'd54	:	cos_r	<=	cos_table	 [ 	439	 : 	432	];
      6'd55	:	cos_r	<=	cos_table	 [ 	447	 : 	440	];
      6'd56	:	cos_r	<=	cos_table	 [ 	455	 : 	448	];
      6'd57	:	cos_r	<=	cos_table	 [ 	463	 : 	456	];
      6'd58	:	cos_r	<=	cos_table	 [ 	471	 : 	464	];
      6'd59	:	cos_r	<=	cos_table	 [ 	479	 : 	472	];
      6'd60	:	cos_r	<=	cos_table	 [ 	487	 : 	480	];
      6'd61	:	cos_r	<=	cos_table	 [ 	495	 : 	488	];
      6'd62	:	cos_r	<=	cos_table	 [ 	503	 : 	496	];
      default	:	cos_r	<=	cos_table	 [ 	511	 : 	504	];
    endcase

/*
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
  */
endmodule
