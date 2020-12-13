`default_nettype none

// Mode 0 8Bit transfer SPI Peripheral implementation
module SPI (
    input            clk,
    input            SCK,
    input            CS,
    input            COPI,
    output           CIPO,
    input      [7:0] tx_byte,
    output reg [7:0] rx_byte,
    output reg       rx_byte_ready
);

  // Tegisters to sync IO with FPGA clock
  reg [2:0] SCKr;
  reg [2:0] CSr;
  reg [1:0] COPIr;

  // count the number of RX and TX bits RX incrments on rising, TX on falling SCK edge
  reg [2:0] rxbitcnt = 3'b000; // counts up
  reg [2:0] txbitcnt = 3'b111; // counts down

  // Assign wires for SPI events, registers assigned in block below
  wire SCK_risingedge = (SCKr[2:1] == 2'b01);
  wire SCK_fallingedge = (SCKr[2:1] == 2'b10);
  wire CS_active = ~CSr[1];  // active low
  wire COPI_data = COPIr[1];
  // CIPO pin (tristated per convention)
  assign CIPO = (CS_active) ? tx_byte[txbitcnt] : 1'bZ;

  always @(posedge clk) begin

    // Use a 3 bit shift register to sync CS, COPI, CIPO, with FPGA clock
    SCKr <= {SCKr[1:0], SCK};
    CSr <= {CSr[1:0], CS};
    COPIr <= {COPIr[0], COPI};

    if (CS_active) begin
      // Recieve increment on rising edge
      if (SCK_risingedge) begin
        rxbitcnt <= rxbitcnt + 3'b001;
        // Shift in Recieved bits
        rx_byte <= {rx_byte[6:0], COPI_data};

        // Trigger Byte recieved
        rx_byte_ready <= (rxbitcnt[2:0] == 3'b111);
      end

      // Transmit increment
      if (SCK_fallingedge) begin
        txbitcnt <= txbitcnt - 3'b001; // rolls over
      end

      //`ifdef FORMAL
      //  assert(rx_byte_ready && rxbitcnt == 3'b111);
      //`endif
    end else begin
      // Reset counts if a txfer is interrupted for some reason
      rxbitcnt <= 3'b000;
      txbitcnt <= 3'b111;
    end
  end

endmodule



// 32 bit word SPI wrapper for Little endian 8 bit transfers
//
module SPIWord (
    input             clk,
    input             SCK,
    input             CS,
    input             COPI,
    output            CIPO,
    input [63:0]      word_send_data,
    output            word_received,
    output reg [63:0] word_data_received
);

  // SPI Initialization
  // The standard unit of transfer is 8 bits, MSB
  wire rx_byte_ready;  // high when a byte has been received
  wire [7:0] rx_byte;
  wire [7:0] tx_byte;
  SPI spi0 (.clk(clk),
            .CS(CS),
            .SCK(SCK),
            .CIPO(CIPO),
            .COPI(COPI),
            .tx_byte(tx_byte),
            .rx_byte(rx_byte),
            .rx_byte_ready(rx_byte_ready));

  reg [3:0] byte_count = 0;
  wire [7:0] word_slice [8:0]; // slice the register into 8 bits

  // Recieve Shift Register
  always @(posedge rx_byte_ready) begin
    byte_count <= (byte_count == 8) ? 1 : byte_count + 1;
    word_data_received <= {rx_byte[7:0], word_data_received[63:8]};
  end

  assign word_received = (byte_count == 8);

  //TODO: Use generate
  assign word_slice[0] = word_send_data[7:0]; // This should only hit at initialization
  assign word_slice[1] = word_send_data[15:8];
  assign word_slice[2] = word_send_data[23:16];
  assign word_slice[3] = word_send_data[31:24];
  assign word_slice[4] = word_send_data[39:32];
  assign word_slice[5] = word_send_data[47:40];
  assign word_slice[6] = word_send_data[55:48];
  assign word_slice[7] = word_send_data[63:56];
  assign word_slice[8] = word_send_data[7:0];

  assign tx_byte[7:0] = word_slice[byte_count];

endmodule
