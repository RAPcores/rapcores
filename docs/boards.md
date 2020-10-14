# Board Definition Structure and Porting Guide

Each board should have the following three files in the name equal to the `BOARD`
parameter sent to make:

- [.mk] FPGA Architecture parameters
- [.v] Verilog configuration parameters
- [.pcf/.lpf] Pin out and pin name information

## (.mk) Parameters


## (.v) Parameters

### SPI Interface

```
`define SPI_INTERFACE
```
Enables the SPI Interface.

## (.pcf/.lpf) Parameters

### SPI Pin Names

- `SCK` - SPI Clock
- `CS` - SPI Chip Select
- `COPI` - SPI Controller Out Peripheral In (RAPCore is the Peripheral)
- `CIPO` - SPI Controller In Peripheral Out
