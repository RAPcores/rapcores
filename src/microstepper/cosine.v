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
      6'd0: cos_r    <= 8'd255;
      6'd1: cos_r    <= 8'd255;
      6'd2: cos_r    <= 8'd255;
      6'd3: cos_r    <= 8'd254;
      6'd4: cos_r    <= 8'd253;
      6'd5: cos_r    <= 8'd253;
      6'd6: cos_r    <= 8'd252;
      6'd7: cos_r    <= 8'd251;
      6'd8: cos_r    <= 8'd249;
      6'd9: cos_r    <= 8'd248;
      6'd10: cos_r   <= 8'd247;
      6'd11: cos_r   <= 8'd245;
      6'd12: cos_r   <= 8'd243;
      6'd13: cos_r   <= 8'd241;
      6'd14: cos_r   <= 8'd239;
      6'd15: cos_r   <= 8'd237;
      6'd16: cos_r   <= 8'd234;
      6'd17: cos_r   <= 8'd232;
      6'd18: cos_r   <= 8'd229;
      6'd19: cos_r   <= 8'd226;
      6'd20: cos_r   <= 8'd223;
      6'd21: cos_r   <= 8'd220;
      6'd22: cos_r   <= 8'd217;
      6'd23: cos_r   <= 8'd214;
      6'd24: cos_r   <= 8'd210;
      6'd25: cos_r   <= 8'd207;
      6'd26: cos_r   <= 8'd203;
      6'd27: cos_r   <= 8'd199;
      6'd28: cos_r   <= 8'd195;
      6'd29: cos_r   <= 8'd191;
      6'd30: cos_r   <= 8'd187;
      6'd31: cos_r   <= 8'd183;
      6'd32: cos_r   <= 8'd178;
      6'd33: cos_r   <= 8'd174;
      6'd34: cos_r   <= 8'd169;
      6'd35: cos_r   <= 8'd164;
      6'd36: cos_r   <= 8'd159;
      6'd37: cos_r   <= 8'd154;
      6'd38: cos_r   <= 8'd149;
      6'd39: cos_r   <= 8'd144;
      6'd40: cos_r   <= 8'd139;
      6'd41: cos_r   <= 8'd134;
      6'd42: cos_r   <= 8'd128;
      6'd43: cos_r   <= 8'd123;
      6'd44: cos_r   <= 8'd117;
      6'd45: cos_r   <= 8'd112;
      6'd46: cos_r   <= 8'd106;
      6'd47: cos_r   <= 8'd100;
      6'd48: cos_r   <= 8'd95;
      6'd49: cos_r   <= 8'd89;
      6'd50: cos_r   <= 8'd83;
      6'd51: cos_r   <= 8'd77;
      6'd52: cos_r   <= 8'd71;
      6'd53: cos_r   <= 8'd65;
      6'd54: cos_r   <= 8'd59;
      6'd55: cos_r   <= 8'd53;
      6'd56: cos_r   <= 8'd47;
      6'd57: cos_r   <= 8'd41;
      6'd58: cos_r   <= 8'd34;
      6'd59: cos_r   <= 8'd28;
      6'd60: cos_r   <= 8'd22;
      6'd61: cos_r   <= 8'd16;
      6'd62: cos_r   <= 8'd9;
      default: cos_r <= 8'd3;
    endcase
endmodule
