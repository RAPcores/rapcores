
// Enable SPI Interface
`define SPI_INTERFACE

// Enable Buffer DTR pin
//`define BUFFER_DTR

// Enable Move Done Pin
//`define MOVE_DONE
// TODO MOVE_DONE BROKEN ON MULTIAXIS

// Enable Halt Input
//`define HALT

// Motor Definitions
`define DUAL_HBRIDGE 2
//`define VREF_AB

`define MOTOR_COUNT 2

// Encoder Count
`define QUAD_ENC 2

// Use a PLL for PWM generation
`define PWMPLL


`define ENCODER_BITS 24

// Change the Move Buffer Size. Should be power of two
//`define MOVE_BUFFER_SIZE 4
