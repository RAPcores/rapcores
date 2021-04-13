// SPDX-License-Identifier: ISC
`default_nettype none

// Mode 0 8Bit transfer SPI Peripheral implementation
module SPI (
    input            clk,
    input            resetn,
    input            SCK,
    input            CS,
    input            COPI,
    output           CIPO,
    input      [7:0] tx_byte,
    output reg [7:0] rx_byte,
    output           rx_byte_ready
);

  // Registers to sync IO with FPGA clock
  reg [1:0] COPIr;
  reg [1:0] CSr;

  // Output Byte and ready flag
  reg rx_byte_ready_r;
  assign rx_byte_ready = rx_byte_ready_r;

  // count the number of RX and TX bits RX incrments on rising, TX on falling SCK edge
  reg [2:0] rxbitcnt; // counts up
  reg [2:0] txbitcnt; // counts down

  // Assign wires for SPI events, registers assigned in block below
  wire SCK_risingedge;
  wire SCK_fallingedge;
  edge_detector #(.buffered(1), .mode("rising")) sck_rising (.clk(clk), .in(SCK), .out(SCK_risingedge));
  edge_detector #(.buffered(1), .mode("falling"))  sck_falling (.clk(clk), .in(SCK), .out(SCK_fallingedge));

  wire CS_active = ~CSr[1];  // active low
  wire COPI_data = COPIr[1];
  // CIPO pin (tristated per convention)
  assign CIPO = (CS_active) ? tx_byte[txbitcnt] : 1'bZ;


  always @(posedge clk) begin
    if (!resetn) begin
      // Registers to sync IO with FPGA clock
      COPIr <= 2'b0;

      // Output Byte and ready flag
      rx_byte_ready_r <= 0;
      rx_byte <= 8'b0;

      // count the number of RX and TX bits RX incrments on rising, TX on falling SCK edge
      rxbitcnt <= 3'b000; // counts up
      txbitcnt <= 3'b111; // counts down
    end else if (resetn) begin

      // Use a 2 bit shift register to sync COPI with FPGA clock
      COPIr <= {COPIr[0], COPI};
      CSr <= {CSr[0], CS};

      if (CS_active) begin
        // Recieve increment on rising edge
        if (SCK_risingedge) begin
          rxbitcnt <= rxbitcnt + 1'b1;
          // Shift in Recieved bits
          rx_byte <= {rx_byte[6:0], COPI_data};
        end else if (SCK_fallingedge) begin
          txbitcnt <= txbitcnt - 1'b1; // rolls over
          // Trigger Byte recieved
          rx_byte_ready_r <= (txbitcnt == 3'b0);
        end

        //`ifdef FORMAL
        //  assert(rx_byte_ready && rxbitcnt == 3'b111);
        //`endif
      end else begin // !CS_active
        // Reset counts if a txfer is interrupted for some reason
        rxbitcnt <= 3'b000;
        txbitcnt <= 3'b111;
      end
    end
  end

endmodule



// 32 bit word SPI wrapper for Little endian 8 bit transfers
//
module SPIWord #(parameter bits = 64) (
    input wire        clk,
    input wire        resetn,
    input wire        SCK,
    input wire        CS,
    input wire        COPI,
    output wire       CIPO,
    input wire [bits-1:0] word_send_data,
    output wire       word_received,
    output reg [bits-1:0] word_data_received
);

  // SPI Initialization
  // The standard unit of transfer is 8 bits, MSB
  wire rx_byte_ready;  // high when a byte has been received
  wire [7:0] rx_byte;
  wire [7:0] tx_byte;

  SPI spi0 (.clk(clk),
            .resetn (resetn),
            .CS(CS),
            .SCK(SCK),
            .CIPO(CIPO),
            .COPI(COPI),
            .tx_byte(tx_byte),
            .rx_byte(rx_byte),
            .rx_byte_ready(rx_byte_ready));

  reg [((bits == 64) ? 2 : 1):0] byte_count;
  wire [7:0] word_slice [7:0]; // slice the register into 8 bits
  wire rx_byte_ready_rising;
  reg word_received_r;

  edge_detector #(.buffered(0)) ready_rising (.clk(clk), .in(rx_byte_ready), .out(rx_byte_ready_rising));

  // Recieve Shift Register
  always @(posedge clk) if (!resetn) begin
    word_data_received <= {bits{1'b0}};
    byte_count <= 0;
    word_received_r <= 0;
  end else if (resetn) begin
    if (rx_byte_ready_rising) begin
      byte_count <= byte_count + 1'b1;
      word_data_received <= {rx_byte[7:0], word_data_received[bits-1:8]};
      if (bits == 64) begin
        if (byte_count[2:0] == 3'b111) word_received_r <= 1'b1;
        else word_received_r <= 1'b0;
      end
      if (bits == 32) begin
        if (byte_count[1:0] == 2'b11) word_received_r <= 1'b1;
        else word_received_r <= 1'b0;
      end
    end
  end

  assign word_received = word_received_r;

  if (bits >= 32) begin
    assign word_slice[0] = word_send_data[7:0]; // This should only hit at initialization
    assign word_slice[1] = word_send_data[15:8];
    assign word_slice[2] = word_send_data[23:16];
    assign word_slice[3] = word_send_data[31:24];
  end
  if (bits >= 64) begin
    assign word_slice[4] = word_send_data[39:32];
    assign word_slice[5] = word_send_data[47:40];
    assign word_slice[6] = word_send_data[55:48];
    assign word_slice[7] = word_send_data[63:56];
  end

  assign tx_byte[7:0] = word_slice[byte_count];

endmodule
