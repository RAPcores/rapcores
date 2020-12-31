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
      1'd1	:	cos_r	<=	254	;
      2'd2	:	cos_r	<=	254	;
      2'd3	:	cos_r	<=	253	;
      3'd4	:	cos_r	<=	252	;
      3'd5	:	cos_r	<=	250	;
      3'd6	:	cos_r	<=	248	;
      3'd7	:	cos_r	<=	246	;
      4'd8	:	cos_r	<=	244	;
      4'd9	:	cos_r	<=	241	;
      4'd10	:	cos_r	<=	239	;
      4'd11	:	cos_r	<=	236	;
      4'd12	:	cos_r	<=	232	;
      4'd13	:	cos_r	<=	229	;
      4'd14	:	cos_r	<=	225	;
      4'd15	:	cos_r	<=	221	;
      5'd16	:	cos_r	<=	217	;
      5'd17	:	cos_r	<=	212	;
      5'd18	:	cos_r	<=	207	;
      5'd19	:	cos_r	<=	202	;
      5'd20	:	cos_r	<=	197	;
      5'd21	:	cos_r	<=	192	;
      5'd22	:	cos_r	<=	186	;
      5'd23	:	cos_r	<=	180	;
      5'd24	:	cos_r	<=	174	;
      5'd25	:	cos_r	<=	168	;
      5'd26	:	cos_r	<=	162	;
      5'd27	:	cos_r	<=	155	;
      5'd28	:	cos_r	<=	149	;
      5'd29	:	cos_r	<=	142	;
      5'd30	:	cos_r	<=	135	;
      5'd31	:	cos_r	<=	128	;
      6'd32	:	cos_r	<=	120	;
      6'd33	:	cos_r	<=	113	;
      6'd34	:	cos_r	<=	105	;
      6'd35	:	cos_r	<=	98	;
      6'd36	:	cos_r	<=	90	;
      6'd37	:	cos_r	<=	82	;
      6'd38	:	cos_r	<=	74	;
      6'd39	:	cos_r	<=	66	;
      6'd40	:	cos_r	<=	58	;
      6'd41	:	cos_r	<=	50	;
      6'd42	:	cos_r	<=	42	;
      6'd43	:	cos_r	<=	33	;
      6'd44	:	cos_r	<=	25	;
      6'd45	:	cos_r	<=	17	;
      6'd46	:	cos_r	<=	8	;
      default: cos_r <= 0 ;
    endcase
endmodule
