# Board Configuration

Each board should have the following three files in the name equal to the `BOARD`
parameter sent to make:

- [.mk] FPGA Architecture parameters
- [.v] Verilog configuration parameters
- [.pcf/.lpf] Pin out and pin name information

## Makefile (.mk) Parameters

The following parameters are passed to place and route (nextpnr) and timing analysis
tools to generate the bitstream of the RAPcores for FPGAs. These are required for bistream generation.

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


## SPI Interface

```
`define SPI_INTERFACE
```
Enables the SPI Interface.

### Pin Names

- `SCK` - SPI Clock
- `CS` - SPI Chip Select
- `COPI` - SPI Controller Out Peripheral In (RAPcores is the Peripheral)
- `CIPO` - SPI Controller In Peripheral Out

## PWM

For high resolution PWM signals a PLL is required. This acts as a clock multiplier, and for example
given a 16mhz clock, a 200mhz signal can be used for things like accumulators and timing.

To enable declare the following in the ".v" configuration file:

```
`define PWMPLL
```

Then inside of the ".mk" aguements we will need to declare the frequency (in mhz):

```
PWMFREQ = 275
```

This will allow PWM signals to use this clock for accumulators giving higher precision and
less audible noise in the case of motor drives.

## Motors

In addition to device-specific counts, a motor count must be defines as so:

```
`define MOTOR_COUNT <N>
```

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

### Pin Names - Dual H Bridge

- `PHASE_A1[N]`
- `PHASE_A2[N]`
- `PHASE_B1[N]`
- `PHASE_B2[N]`
- `VREF_A[N]`
- `VREF_B[N]`

### Pin Names ULTIBRIDGE

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


### Defaults

```
`define DEFAULT_MICROSTEPS <N>
```

Set the default microsteps for all motor channels.

```
`define DEFAULT_CURRENT <N>
```

Set the default current for all motor channels.

## Encoders

```
`define QUAD_ENC <N>
```
Enables quadrature encoder . Where `<N>` encoders are specified.

### Pin Names

- `ENC_A[N]`
- `ENC_B[N]`


## Flow Control and Events

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


### Pin Names

- `BUFFER_DTR` - Output active High when move buffer has slots.
- `MOVE_DONE` - Output toggles when a move in the buffer has finished.
- `HALT` - Input immediately stops step timing and clears the buffer.


## Move Buffer Size

```
`define MOVE_BUFFER_SIZE 2
```
Default: 2

Changes the default move buffer size. Must be a power of two.

## DDA

```
`define DEFAULT_CLOCK_DIVISOR 32
```
Default: 32

Sets the default clock divisor for the DDA.

## Internal Register Sizes

```
`define MOVE_DURATION_BITS 32
```
Default: 32

Sets the move_duration register size used in step timing routines.

```
`define DEFAULT_TIMER_WIDTH 8
```
Default: 8

Sets the width for internal clock dividers.

## LED

```
`define LED <N>
```

Type: Output

Default: none/0

Enables LED output. Currently unused, but useful for low-frequency visual debugging.


## Logic Analyzer

The Logic Analyzer interface allows for observation and injection of signals
within the top-level RAPcores project without patching the core project.

```
`define LA_OUT <N>
```

Type: Output

Default: none/0

```
`define LA_IN <N>
```

Type: Input

Default: none/0



Assignments can be done at the `BOARD.v` level
by making a `LOGICANALYZER_MACRO` like so:

```
`define LOGICANALYZER_MACRO\
  assign LA_OUT[1] = dir; \
  assign LA_OUT[2] = analog_cmp2;
```
