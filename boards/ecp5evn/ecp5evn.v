
// Enable SPI Interface
`define SPI_INTERFACE

// Use PLL for higher SPI frequencies
//`define SPIPLL

// Enable Buffer DTR pin
`define BUFFER_DTR

// Enable Move Done Pin
`define MOVE_DONE

// Motor Definitions
//`define DUAL_HBRIDGE 1
//`define ULTIBRIDGE 1

`define MOTOR_COUNT 4

// Encoder Count
`define QUAD_ENC 4

// External Step/DIR Input
//`define STEPINPUT

// Output Step/DIR signals
`define STEPOUTPUT 4

// Change the Move Buffer Size. Should be power of two
//`define MOVE_BUFFER_SIZE 4

// Default Mosfet Active Polarity
//`define DEFAULT_BRIDGE_INVERTING 1


// Enable Logic Analyzer Out
//`define LA_OUT 2

// Enable Logic Analyzer IN
//`define LA_IN 2

// Logic Analyzer IO for rapcore.v can be set here
//`define TOP_LA\
//  assign LA_OUT[1] = dir; \
//  assign LA_OUT[2] = analog_cmp2;
