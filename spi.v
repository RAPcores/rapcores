`default_nettype none

// TODO license unknown, replace with MIT version in soft_spi.v
module SPI (
    input            clk,
    input            SCK,
    input            SSEL,
    input            MOSI,
    output reg       MISO,
    input      [7:0] send_data,
    output           byte_received,
    output reg    [7:0] byte_data_received
);
  parameter txwidth = 8;
  parameter rxwidth = 8;

  // sync SCK to the FPGA clock using a 3-bits shift register
  reg [2:0] SCKr;
  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};

  wire SCK_risingedge = (SCKr[2:1] == 2'b01);  // now we can detect SCK rising edges
  wire SCK_fallingedge = (SCKr[2:1] == 2'b10);  // and falling edges

  // same thing for SSEL
  reg [2:0] SSELr;
  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};

  wire SSEL_active = ~SSELr[1];  // SSEL is active low
  wire SSEL_startmessage = (SSELr[2:1] == 2'b10);  // message starts at falling edge
  wire SSEL_endmessage = (SSELr[2:1] == 2'b01);  // message stops at rising edge

  // and for MOSI
  reg [1:0] MOSIr;
  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  wire MOSI_data = MOSIr[1];

  // we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
  reg [2:0] bitcnt;

  reg [rxwidth-1:0] rx_data;

  always @(posedge clk) begin
    if (~SSEL_active) bitcnt <= 3'b000;
    else if (SCK_risingedge) begin
      bitcnt <= bitcnt + 3'b001;

      // implement a shift-left register (since we receive the data MSB first)
      byte_data_received <= {byte_data_received[rxwidth - 2:0], MOSI_data};
    end
  end

  always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt[2:0] == 3'b111);

  reg [7:0] byte_data_sent;

  reg [7:0] cnt;
  always @(posedge clk) if (SSEL_startmessage) cnt <= cnt + 8'h1;  // count the messages

  always @(posedge clk)
    if (SSEL_active) begin
      if (SSEL_startmessage) byte_data_sent <= send_data;
      else if (SCK_fallingedge) byte_data_sent <= {byte_data_sent[6:0], 1'b0};
    end


  assign MISO = byte_data_sent[7];  // send MSB first
  // we assume that there is only one slave on the SPI bus
  // so we don't bother with a tri-state buffer for MISO
  // otherwise we would need to tri-state MISO when SSEL is inactive

endmodule


// 32 bit word SPI wrapper for Little endian 8 bit transfers
//
module SPIWord (
    input         clk,
    input SCK,
    input SSEL,
    input MOSI,
    output MISO,
    input [31:0] word_send_data,
    output reg       word_received,
    output [31:0] word_data_received
);

  // SPI Initialization
  // The standard unit of transfer is 8 bits, MSB
  wire byte_received;  // high when a byte has been received
  reg [7:0] byte_data_received;
  reg [7:0] send_data;
  SPI spi0 (.clk(clk),
            .SCK(SCK),
            .SSEL(SSEL),
            .MOSI(MOSI),
            .MISO(MISO),
            .send_data(send_data),
            .byte_received(byte_received),
            .byte_data_received(byte_data_received) );


  reg [2:0] byte_count = 0;

  // TODO Send does not work
  always @(posedge byte_received) begin
    byte_count = (byte_count == 4) ? 1 : byte_count + 1;
    word_data_received = {byte_data_received[7:0], word_data_received[31:8]};
  end

  always @(posedge clk) begin
    word_received <= (byte_count[2:0] == 3'b100);
    if (byte_count == 4) send_data[7:0] <= word_send_data[7:0];
    if (byte_count == 1) send_data[7:0] <= word_send_data[15:8];
    if (byte_count == 2) send_data[7:0] <= word_send_data[23:16];
    if (byte_count == 3) send_data[7:0] <= word_send_data[31:24];
  end
endmodule
