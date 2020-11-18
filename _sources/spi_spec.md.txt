# SPI Specification

## Definitions

- SPI Transfer: An 8 bit, Mode 0 MSB SPI communication
- Words: 64 bits of 8 little endian SPI transfers
- Message: A complete SPI transmission consisting of one or more words
- Forward Channel: SPI communication initiated by firmware to FPGA
- Reverse Channel: Data transmitted by FPGA to firmware during message transfer
- Motor Channel:

## Versioning

RAPCores follows [Semantic Versioning](https://semver.org/). This is still a pre-1.0
project so breaking changes are likely to happen with the SPI protocol. This document
serves as the "as-built" reference for the RAPcore, and may deviate from documents outside
this repository.

## Overview

The SPI bus operated in peripheral mode 0 MSB.The protocol assumes any complete transfer is
a 64 bit word. The word construction is set to little endian for improved compatibility with
SPI controller devices.


| Most Significant Byte | Action                  | Transmission Length (Words) | Default Value |
|-----------------------|-------------------------|-----------------------------|---------------|
| 0x01                  | Coordinated Step Timer  | 2 + 2*N motors              | N/A           |
| 0x02                  | Integration Timer Scale | 1                           | 32            |
| 0x03                  | Set Motor Count         | 1                           | 6             |
| 0x10                  | Set Motor Config        | 1                           | See Below     |
| 0xfe                  | Get Version             | 2                           | 0x...MMmmpp   |


### Set Motor Config - 0x10

| Byte 1 | Byte 2         | Byte 3   | Byte 4   | Byte 5   | Byte 6   | Byte 7  | Byte 8     |
|--------|----------------|----------|----------|----------|----------|---------|------------|
| 0x10   | Motor Channel  | Reserved | Reserved | Reserved | Reserved | Current | Microsteps |

### Get API Version - 0xfe

|  | Word 1 |  |  |  |  |  |  |  | Word 2 |  |  |  |  |     |     |     |
|--|--------|--|--|--|--|--|--|--|--------|--|--|--|--|-----|-----|-----|
|  | Byte 1 |B2|B3|B4|B5|B6|B7|B8| B1     |B2|B3|B4|B5|B6   |B7   |B8   |
|TX| 0xfe   |  |  |  |  |  |  |  |        |  |  |  |  |     |     |     |
|RX| STATUS |  |  |  |  |  |  |  |        |  |  |  |  |MAJOR|MINOR|PATCH|

### Enable/Disable Motors - 0x0a

|  | Word 1 |  |  |  |  |  |  |          |
|--|--------|--|--|--|--|--|--|----------|
|  | Byte 1 |B2|B3|B4|B5|B6|B7|B8        |
|TX| 0xfe   |  |  |  |  |  |  |0b11111111|
|RX| STATUS |  |  |  |  |  |  |          |

Starting from 0x01 of B8, enable or disable (1/0 respectively) a motor channel.
This will power up the motors. For example:

|Byte 8||||||||
|-|-|-|-|-|-|-|-|
|Bit 8| Bit 7 | Bit 6|Bit 5| Bit 4| Bit 3| Bit 2| Bit 1|
|Mot 8| Mot 7 | Mot 6|Mot 5| Mot 4| Mot 3| Mot 2| Mot 1|
| Dis. | Dis.  | Dis.| Dis.| En.  | En.  | En.  | En.  |
| 0    |  0    | 0   | 0   | 1    | 1    | 1    | 1    |
