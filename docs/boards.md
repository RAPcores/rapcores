# Board Definition Structure and Porting Guide

Each board should have the following three files in the name equal to the `BOARD`
parameter sent to make:

- [.mk] FPGA Architecture parameters
- [.v] Verilog configuration parameters
- [.pcf/.lpf] Pin out and pin name information

## (.mk) Parameters

The following parameters are passed to place and route (nextpnr) and timing analysis
tools to generate the bitstream of the RAPCore for FPGAs.

### ARCH
```
ARCH = ice40
```

### DEVICE
```
DEVICE = lp8k
```

### PACKAGE
```
PACKAGE = cm81
```

### FREQ
```
FREQ = 16
```

### PROGRAMMER (Optional)
```
PROGRAMMER = tinyprog -p
```
The programming command for the device used with the `make prog` target.


## (.v) Parameters

The following Verilog Macro Definitions may be used to enable or disable certain
features:

### SPI Interface

```
`define SPI_INTERFACE
```
Enables the SPI Interface.

### Buffer DTR

```
`define BUFFER_DTR
```
Active High when move buffer has slots available for send.

### Move Buffer

```
`define MOVE_BUFFER_SIZE 2
```
Changes the default move buffer size. Must be a power of two.

## (.pcf/.lpf) Parameters

The following are pin naming conventions for the RAPCore "top" module:

### SPI Pin Names

- `SCK` - SPI Clock
- `CS` - SPI Chip Select
- `COPI` - SPI Controller Out Peripheral In (RAPCore is the Peripheral)
- `CIPO` - SPI Controller In Peripheral Out

### Buffer DTR

- `BUFFER_DTR` - Active High when move buffer has slots
