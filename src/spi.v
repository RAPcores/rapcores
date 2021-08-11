// SPDX-License-Identifier: ISC
`default_nettype none


// SPI Bus implementation (Mode 0 only)
// Parameters:
//  - word_bits: Number of bits in a word
//
// Note: It is assumed the base transaction is an 8 bit byte,
// and multi-byte transfers are little endian. This module
// will wait until the requested number of bits have been
// received, before signaling the transaction is complete.
module SPI #(
  parameter word_bits = 64
)(
    input            clk,    // System clock
    input            resetn, // Reset active low
    input            SCK,    // SPI clock
    input            CS,     // Chip select
    input            COPI,   // Controller out Peripheral in
    output           CIPO,   // Controller in Peripheral out
    input [word_bits-1:0]  tx_byte, // Transmit data
    output [word_bits-1:0] rx_byte, // Receive data
    output           rx_byte_ready // Receive data ready
);

  localparam counter_bits = $clog2(word_bits);
  localparam byte_count = word_bits/8;

  // Registers to sync IO with FPGA clock
  reg COPIr;
  reg CSr;
  reg [1:0] SCKr;

  // shift register for recieved bits, endian correction is pipelined
  reg [word_bits-1:0] rx_shreg;

  // Output Byte and ready flag
  reg rx_byte_ready_r;
  assign rx_byte_ready = rx_byte_ready_r;

  // count the number of RX and TX bits RX incrments on rising, TX on falling SCK edge
  reg [counter_bits-1:0] rxbitcnt; // counts up
  reg [counter_bits-1:0] txbitcnt; // counts down

  // CIPO pin (tristated per convention)
  assign CIPO = (~CSr) ? tx_byte[txbitcnt] : 1'bZ;

  // TODO generate this
  // Endianness correction
  // We do this here to avoid having to do it in the shift register
  if (word_bits == 64) begin
    assign rx_byte = {rx_shreg[0:7],
                      rx_shreg[8:15],
                      rx_shreg[16:23],
                      rx_shreg[24:31],
                      rx_shreg[32:39],
                      rx_shreg[40:47],
                      rx_shreg[48:55],
                      rx_shreg[56:63]};
  end else if (word_bits == 32) begin
    assign rx_byte = {rx_shreg[0:7],
                      rx_shreg[8:15],
                      rx_shreg[16:23],
                      rx_shreg[24:31]};
  end else if (word_bits == 16) begin
    assign rx_byte = {rx_shreg[0:7],
                      rx_shreg[8:15]};
  end else if (word_bits == 8) begin
    assign rx_byte = rx_shreg[0:7];
  end else begin
    $error("SPI: Unsupported word width");
  end

  always @(posedge clk) begin
    if (!resetn) begin
      // Registers to sync IO with FPGA clock
      COPIr <= 1'b0;

      // Output Byte and ready flag
      rx_byte_ready_r <= 0;
      rx_shreg <= {word_bits{1'b0}};

      // count the number of RX and TX bits RX incrments on rising, TX on falling SCK edge
      rxbitcnt <= {counter_bits{1'b0}}; // counts up
      txbitcnt <= {counter_bits{1'b1}}; // counts down
    end else if (resetn) begin
      COPIr <= COPI;
      CSr <= CS;
      SCKr <= {SCKr[0],SCK};

      if (~CSr) begin
        // Recieve increment on rising edge
        if (SCKr == 2'b01) begin
          rxbitcnt <= rxbitcnt + 1'b1;
          // Shift in Recieved bits ( we pipeline endianness above)
          rx_shreg <= {rx_shreg[word_bits-2:0], COPIr};
        end else if (SCKr == 2'b10) begin
          txbitcnt <= txbitcnt - 1'b1; // rolls over
          // Trigger Byte recieved
          rx_byte_ready_r <= (txbitcnt == {counter_bits{1'b0}});
        end

        //`ifdef FORMAL
        //  assert(rx_byte_ready && rxbitcnt == 3'b111);
        //`endif
      end else begin // !CS_active
        // Reset counts if a txfer is interrupted for some reason
        rxbitcnt <= {counter_bits{1'b0}};
        txbitcnt <= {counter_bits{1'b1}};
      end
    end
  end

endmodule
