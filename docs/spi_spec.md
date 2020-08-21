# SPI Specification

## Definitions

- SPI Transfer: An 8 bit, Mode 0 MSB SPI communication
- Words: 64 bits of 8 little endian SPI transfers
- Message: A complete SPI transmission consisting of one or more words
- Forward Channel: SPI communication initiated by firmware to FPGA
- Reverse Channel: Data transmitted by FPGA to firmware during message transfer

## Overview

The SPI bus operated in peripheral mode 0 MSB.The protocol assumes any complete transfer is
a 64 bit word. The word construction is set to little endian for improved compatibility with
SPI controller devices.


| Most Significant Byte | Action                  | Transmission Length (Words) | Default Value |
|-----------------------|-------------------------|-----------------------------|---------------|
| 0x01                  | Coordinated Step Timer  | 2 + 2*N motors              | N/A           |
| 0x02                  | Integration Timer Scale | 1                           | 32            |
| 0x03                  | Set Motor Count         | 1                           | 6             |
| 0x04                  | Set Microstepping       | 1                           | 2             |
