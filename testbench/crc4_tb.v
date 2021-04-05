
module crc4_tb(input  wire clk,
              input  wire resetn,
              //output reg [63:0] data_in,
              output wire [4:0]crc_out);

        
    reg [63:0] data_in = 0;
    reg crc_en = 1;

    crc4 c (.data_in(data_in),
    .crc_en(1),
    .crc_out(crc_out),
    .rst(resetn),
    .clk(clk));

    always @(posedge clk) begin
        data_in <= data_in + 1'b1;
    end

endmodule