
// Enable SPI Interface
`define SPI_INTERFACE

// Use PLL for higher SPI frequencies
//`define SPIPLL

// Enable Buffer DTR pin
`define BUFFER_DTR

// Enable Move Done Pin
`define MOVE_DONE

// Enable Halt Input
`define HALT

// Motor Definitions
//`define DUAL_HBRIDGE 1
`define ULTIBRIDGE 1

// Encoder Count
`define QUAD_ENC 1

// External Step/DIR Input
`define STEPINPUT

// Output Step/DIR signals
`define STEPOUTPUT

// Enable RESETN
`define RESETN

// Change the Move Buffer Size. Should be power of two
//`define MOVE_BUFFER_SIZE 4
