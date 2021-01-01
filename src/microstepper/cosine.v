`default_nettype none

module cosine (
    input wire clk,
    input  wire [5:0] cos_index,
    output wire [7:0] cos_value
);
  reg [7:0] cos_r;
  assign cos_value = cos_r;
  always @(posedge clk)
    case (cos_index)
      1'd0	:	cos_r	<=	255	;
      1'd1	:	cos_r	<=	255	;
      2'd2	:	cos_r	<=	254	;
      2'd3	:	cos_r	<=	253	;
      3'd4	:	cos_r	<=	252	;
      3'd5	:	cos_r	<=	251	;
      3'd6	:	cos_r	<=	249	;
      3'd7	:	cos_r	<=	247	;
      4'd8	:	cos_r	<=	245	;
      4'd9	:	cos_r	<=	243	;
      4'd10	:	cos_r	<=	240	;
      4'd11	:	cos_r	<=	237	;
      4'd12	:	cos_r	<=	234	;
      4'd13	:	cos_r	<=	231	;
      4'd14	:	cos_r	<=	227	;
      4'd15	:	cos_r	<=	223	;
      5'd16	:	cos_r	<=	219	;
      5'd17	:	cos_r	<=	214	;
      5'd18	:	cos_r	<=	210	;
      5'd19	:	cos_r	<=	205	;
      5'd20	:	cos_r	<=	200	;
      5'd21	:	cos_r	<=	194	;
      5'd22	:	cos_r	<=	189	;
      5'd23	:	cos_r	<=	183	;
      5'd24	:	cos_r	<=	177	;
      5'd25	:	cos_r	<=	171	;
      5'd26	:	cos_r	<=	165	;
      5'd27	:	cos_r	<=	159	;
      5'd28	:	cos_r	<=	152	;
      5'd29	:	cos_r	<=	145	;
      5'd30	:	cos_r	<=	138	;
      5'd31	:	cos_r	<=	131	;
      6'd32	:	cos_r	<=	124	;
      6'd33	:	cos_r	<=	117	;
      6'd34	:	cos_r	<=	109	;
      6'd35	:	cos_r	<=	101	;
      6'd36	:	cos_r	<=	94	;
      6'd37	:	cos_r	<=	86	;
      6'd38	:	cos_r	<=	78	;
      6'd39	:	cos_r	<=	70	;
      6'd40	:	cos_r	<=	62	;
      6'd41	:	cos_r	<=	54	;
      6'd42	:	cos_r	<=	46	;
      6'd43	:	cos_r	<=	37	;
      6'd44	:	cos_r	<=	29	;
      6'd45	:	cos_r	<=	21	;
      6'd46	:	cos_r	<=	13	;
      default: cos_r <= 4 ;
    endcase
endmodule
