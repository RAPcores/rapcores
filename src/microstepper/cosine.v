module cosine(
input wire [5:0] cos_index,
output wire [7:0] cos_value
);
reg [7:0] cos_r;
assign cos_value = cos_r;
always @(*)
case(cos_index)
1'd0	:	cos_r	<=	255	;
1'd1	:	cos_r	<=	255	;
2'd2	:	cos_r	<=	255	;
2'd3	:	cos_r	<=	254	;
3'd4	:	cos_r	<=	254	;
3'd5	:	cos_r	<=	253	;
3'd6	:	cos_r	<=	252	;
3'd7	:	cos_r	<=	251	;
4'd8	:	cos_r	<=	250	;
4'd9	:	cos_r	<=	249	;
4'd10	:	cos_r	<=	247	;
4'd11	:	cos_r	<=	246	;
4'd12	:	cos_r	<=	244	;
4'd13	:	cos_r	<=	242	;
4'd14	:	cos_r	<=	240	;
4'd15	:	cos_r	<=	238	;
5'd16	:	cos_r	<=	236	;
5'd17	:	cos_r	<=	233	;
5'd18	:	cos_r	<=	231	;
5'd19	:	cos_r	<=	228	;
5'd20	:	cos_r	<=	225	;
5'd21	:	cos_r	<=	222	;
5'd22	:	cos_r	<=	219	;
5'd23	:	cos_r	<=	215	;
5'd24	:	cos_r	<=	212	;
5'd25	:	cos_r	<=	208	;
5'd26	:	cos_r	<=	205	;
5'd27	:	cos_r	<=	201	;
5'd28	:	cos_r	<=	197	;
5'd29	:	cos_r	<=	193	;
5'd30	:	cos_r	<=	189	;
5'd31	:	cos_r	<=	185	;
6'd32	:	cos_r	<=	180	;
6'd33	:	cos_r	<=	176	;
6'd34	:	cos_r	<=	171	;
6'd35	:	cos_r	<=	167	;
6'd36	:	cos_r	<=	162	;
6'd37	:	cos_r	<=	157	;
6'd38	:	cos_r	<=	152	;
6'd39	:	cos_r	<=	147	;
6'd40	:	cos_r	<=	142	;
6'd41	:	cos_r	<=	136	;
6'd42	:	cos_r	<=	131	;
6'd43	:	cos_r	<=	126	;
6'd44	:	cos_r	<=	120	;
6'd45	:	cos_r	<=	115	;
6'd46	:	cos_r	<=	109	;
6'd47	:	cos_r	<=	103	;
6'd48	:	cos_r	<=	98	;
6'd49	:	cos_r	<=	92	;
6'd50	:	cos_r	<=	86	;
6'd51	:	cos_r	<=	80	;
6'd52	:	cos_r	<=	74	;
6'd53	:	cos_r	<=	68	;
6'd54	:	cos_r	<=	62	;
6'd55	:	cos_r	<=	56	;
6'd56	:	cos_r	<=	50	;
6'd57	:	cos_r	<=	44	;
6'd58	:	cos_r	<=	37	;
6'd59	:	cos_r	<=	31	;
6'd60	:	cos_r	<=	25	;
6'd61	:	cos_r	<=	19	;
6'd62	:	cos_r	<=	13	;
default	:	cos_r	<=	6	;
endcase
endmodule
