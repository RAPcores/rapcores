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
Values: ice40, ecp5

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
Device external clock frequency. Used to validate timings.

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

### Motors

```
`define DUAL_HBRIDGE <N>
```
Enables control of Dual H Bridge motor drivers used for stepper control. Where `<N>`
dual H Bridges are specified.

See: "Dual H Bridge" in Pinouts for name specification.

```
`define ULTIBRIDGE <N>
```
Enables control of the Ultibridge. Where `<N>` Ultibridges are specified.

See: "Ultibridge" in Pinouts for name specification.

### Encoders

```
`define QUAD_ENC <N>
```
Enables quadrature encoder . Where `<N>` encoders are specified.

### Flow Control and Events

The following Input/Output tied to certain events can be enabled:

```
`define BUFFER_DTR
```
Type: Output

Active High when move buffer has slots available for send.

```
`define MOVE_DONE
```
Type:Output

Toggles when a move in the buffer has completed.

```
`define HALT
```
Type: Input

Immediately stops step timing and clears the buffer.

### Move Buffer

```
`define MOVE_BUFFER_SIZE 2
```
Default: 2

Changes the default move buffer size. Must be a power of two.

### LED

```
`define LED <N>
```

Type: Output

Default: none/0

Enables LED output. Currently unused, but useful for low-frequency visual debugging.

## (.pcf/.lpf) Pin Names

The following are pin naming conventions for the RAPCore "top" module:

### SPI Pin Names

Enabled by `SPI_INTERFACE` in the Verilog config.

- `SCK` - SPI Clock
- `CS` - SPI Chip Select
- `COPI` - SPI Controller Out Peripheral In (RAPCore is the Peripheral)
- `CIPO` - SPI Controller In Peripheral Out

### Flow Control and Events


- `BUFFER_DTR` - Output active High when move buffer has slots.
- `MOVE_DONE` - Output toggles when a move in the buffer has finished.
- `HALT` - Input immediately stops step timing and clears the buffer.

### Motors


#### Dual H Bridge

- `PHASE_A1[N]`
- `PHASE_A2[N]`
- `PHASE_B1[N]`
- `PHASE_B2[N]`
- `VREF_A[N]`
- `VREF_B[N]`

#### ULTIBRIDGE

- `CHARGEPUMP`
- `analog_cmp1`
- `analog_out1`
- `analog_cmp2`
- `analog_out2`
- `PHASE_A1[N]`
- `PHASE_A2[N]`
- `PHASE_B1[N]`
- `PHASE_B2[N]`
- `PHASE_A1_H[N]`
- `PHASE_A2_H[N]`
- `PHASE_B1_H[N]`
- `PHASE_B2_H[N]`

### Quadrature Encoders

- `ENC_A[N]`
- `ENC_B[N]`
