`default_nettype none

// Derived from: https://github.com/nandland/spi-slave
// MIT License

// Copyright (c) 2019 russell-merrick

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
//              Creates slave based on input configuration.
//              Receives a byte one bit at a time on MOSI
//              Will also push out byte data one bit at a time on MISO.
//              Any data on input byte will be shipped out on MISO.
//              Supports multiple bytes per transaction when CS_n is kept
//              low during the transaction.
//
// Note:        i_Clk must be at least 4x faster than i_SPI_Clk
//              MISO is tri-stated when not communicating.  Allows for multiple
//              SPI Slaves on the same interface.
//
// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More info: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
///////////////////////////////////////////////////////////////////////////////

// n.b
// The new language for SPI pin labeling recommends the use of SDO/SDI (Serial Data Out/In)
// for single-role hardware, and COPI/CIPO for “Controller Out, Peripheral In” and
// “Controller In, Peripheral Out” for devices that can be either the controller or
// the peripheral. The change also updates the “SS” (Slave Select) pin to use “CS” (Chip Select).

module SPI_Slave
  #(parameter SPI_MODE = 0)
  (
   // Control/Data Signals,
   input            i_Clk,      // FPGA Clock
   output       o_RX_DV,    // Data Valid pulse (1 clock cycle)
   output [7:0] o_RX_Byte,  // Byte received on MOSI
   input            i_TX_DV,    // Data Valid pulse to register i_TX_Byte
   input  [7:0]     i_TX_Byte,  // Byte to serialize to MISO.

   // SPI Interface
   input      i_SPI_Clk,
   output reg o_SPI_MISO,
   input      i_SPI_MOSI,
   input      i_SPI_CS_n // active low
   );


  // SPI Interface (All Runs at SPI Clock Domain)
  wire w_CPOL;     // Clock polarity
  wire w_CPHA;     // Clock phase
  wire w_SPI_Clk;  // Inverted/non-inverted depending on settings
  wire w_SPI_MISO_Mux;

  reg [2:0] r_RX_Bit_Count;
  reg [2:0] r_TX_Bit_Count;
  reg [7:0] r_Temp_RX_Byte;
  reg [7:0] r_RX_Byte;
  reg r_RX_Done;
  reg [7:0] r_TX_Byte;
  reg r_SPI_MISO_Bit, r_Preload_MISO;

  // CPOL: Clock Polarity
  // CPOL=0 means clock idles at 0, leading edge is rising edge.
  // CPOL=1 means clock idles at 1, leading edge is falling edge.
  assign w_CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

  // CPHA: Clock Phase
  // CPHA=0 means the "out" side changes the data on trailing edge of clock
  //              the "in" side captures data on leading edge of clock
  // CPHA=1 means the "out" side changes the data on leading edge of clock
  //              the "in" side captures data on the trailing edge of clock
  assign w_CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);

  assign w_SPI_Clk = w_CPHA ? ~i_SPI_Clk : i_SPI_Clk;

  assign o_RX_Byte = r_RX_Byte;
  assign o_RX_DV = r_RX_Done;

  // Purpose: Recover SPI Byte in SPI Clock Domain
  // Samples line on correct edge of SPI Clock
  always @(posedge w_SPI_Clk or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_RX_Bit_Count <= 0;
      r_RX_Done      <= 1'b0;
    end
    else
    begin
      r_RX_Bit_Count <= r_RX_Bit_Count + 1;

      // Receive in LSB, shift up to MSB
      r_Temp_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};

      if (r_RX_Bit_Count == 3'b111)
      begin
        r_RX_Done <= 1'b1;
        r_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
      end
      else if (r_RX_Bit_Count == 3'b010)
      begin
        r_RX_Done <= 1'b0;
      end

    end // else: !if(i_SPI_CS_n)
  end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)


  // Purpose: Transmits 1 SPI Byte whenever SPI clock is toggling
  // Will transmit read data back to SW over MISO line.
  // Want to put data on the line immediately when CS goes low.
  always @(posedge w_SPI_Clk or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_TX_Bit_Count <= 3'b111;  // Send MSb first
    end
    else
    begin
      r_TX_Bit_Count <= r_TX_Bit_Count - 1;

    end // else: !if(i_SPI_CS_n)
  end // always @ (negedge w_SPI_Clk or posedge i_SPI_CS_n_SW)


  // Purpose: Register TX Byte when DV pulse comes.  Keeps registed byte in
  // this module to get serialized and sent back to master.
  always @(posedge i_Clk) begin
      r_TX_Byte <= i_TX_Byte;
  end // always @ (posedge i_Clk or negedge i_Rst_L)

  // MISO
  assign o_SPI_MISO = r_TX_Byte[r_TX_Bit_Count];

endmodule // SPI_Slave



// 32 bit word SPI wrapper for Little endian 8 bit transfers
//
module SPIWord (
    input         clk,
    input SCK,
    input SSEL,
    input MOSI,
    output MISO,
    input [63:0] word_send_data,
    output       word_received,
    output reg [63:0] word_data_received
);

  // SPI Initialization
  // The standard unit of transfer is 8 bits, MSB
  wire byte_received;  // high when a byte has been received
  wire [7:0] byte_data_received;
  reg [7:0] send_data;
  reg SPI_TX_DV = 1;
  SPI_Slave spi0 (
            .i_Clk(clk),
            .o_RX_DV(byte_received),
            .o_RX_Byte(byte_data_received),
            .i_TX_DV(SPI_TX_DV),
            .i_TX_Byte(send_data),
            .i_SPI_Clk(SCK),
            .o_SPI_MISO(MISO),
            .i_SPI_MOSI(MOSI),
            .i_SPI_CS_n(SSEL));

  reg [4:0] byte_count = 0;

  // TODO Send does not work
  always @(posedge byte_received) begin
    byte_count = (byte_count == 8) ? 1 : byte_count + 1;
    word_data_received = {byte_data_received[7:0], word_data_received[63:8]};
  end

  assign word_received = (byte_count == 8);

  always @(posedge clk) begin
    case (byte_count)
        0: send_data[7:0] = word_send_data[7:0];
        1: send_data[7:0] = word_send_data[15:8];
        2: send_data[7:0] = word_send_data[23:16];
        3: send_data[7:0] = word_send_data[31:24];
        4: send_data[7:0] = word_send_data[39:32];
        5: send_data[7:0] = word_send_data[47:40];
        6: send_data[7:0] = word_send_data[55:48];
        7: send_data[7:0] = word_send_data[63:56];
        8: send_data[7:0] = word_send_data[7:0];
    endcase
  end

endmodule
