`default_nettype none

module cosine (
    input  wire [5:0] cos_index,
    output wire [7:0] cos_value
);
  reg [7:0] cos_r;
  assign cos_value = cos_r;
  always @(*)
    case (cos_index)
      6'd0: cos_r    <= 8'd255;
      6'd1: cos_r    <= 8'd255;
      6'd2: cos_r    <= 8'd255;
      6'd3: cos_r    <= 8'd254;
      6'd4: cos_r    <= 8'd254;
      6'd5: cos_r    <= 8'd253;
      6'd6: cos_r    <= 8'd252;
      6'd7: cos_r    <= 8'd251;
      6'd8: cos_r    <= 8'd250;
      6'd9: cos_r    <= 8'd249;
      6'd10: cos_r   <= 8'd247;
      6'd11: cos_r   <= 8'd246;
      6'd12: cos_r   <= 8'd244;
      6'd13: cos_r   <= 8'd242;
      6'd14: cos_r   <= 8'd240;
      6'd15: cos_r   <= 8'd238;
      6'd16: cos_r   <= 8'd236;
      6'd17: cos_r   <= 8'd233;
      6'd18: cos_r   <= 8'd231;
      6'd19: cos_r   <= 8'd228;
      6'd20: cos_r   <= 8'd225;
      6'd21: cos_r   <= 8'd222;
      6'd22: cos_r   <= 8'd219;
      6'd23: cos_r   <= 8'd215;
      6'd24: cos_r   <= 8'd212;
      6'd25: cos_r   <= 8'd208;
      6'd26: cos_r   <= 8'd205;
      6'd27: cos_r   <= 8'd201;
      6'd28: cos_r   <= 8'd197;
      6'd29: cos_r   <= 8'd193;
      6'd30: cos_r   <= 8'd189;
      6'd31: cos_r   <= 8'd185;
      6'd32: cos_r   <= 8'd180;
      6'd33: cos_r   <= 8'd176;
      6'd34: cos_r   <= 8'd171;
      6'd35: cos_r   <= 8'd167;
      6'd36: cos_r   <= 8'd162;
      6'd37: cos_r   <= 8'd157;
      6'd38: cos_r   <= 8'd152;
      6'd39: cos_r   <= 8'd147;
      6'd40: cos_r   <= 8'd142;
      6'd41: cos_r   <= 8'd136;
      6'd42: cos_r   <= 8'd131;
      6'd43: cos_r   <= 8'd126;
      6'd44: cos_r   <= 8'd120;
      6'd45: cos_r   <= 8'd115;
      6'd46: cos_r   <= 8'd109;
      6'd47: cos_r   <= 8'd103;
      6'd48: cos_r   <= 8'd98;
      6'd49: cos_r   <= 8'd92;
      6'd50: cos_r   <= 8'd86;
      6'd51: cos_r   <= 8'd80;
      6'd52: cos_r   <= 8'd74;
      6'd53: cos_r   <= 8'd68;
      6'd54: cos_r   <= 8'd62;
      6'd55: cos_r   <= 8'd56;
      6'd56: cos_r   <= 8'd50;
      6'd57: cos_r   <= 8'd44;
      6'd58: cos_r   <= 8'd37;
      6'd59: cos_r   <= 8'd31;
      6'd60: cos_r   <= 8'd25;
      6'd61: cos_r   <= 8'd19;
      6'd62: cos_r   <= 8'd13;
      default: cos_r <= 8'd6;
    endcase
endmodule
