
// Enable SPI Interface
`define SPI_INTERFACE

// Enable Buffer DTR pin
//`define BUFFER_DTR

// Enable Move Done Pin
//`define MOVE_DONE

// Enable Halt Input
//`define HALT

// Motor Definitions
`define DUAL_HBRIDGE 4
//`define VREF_AB

`define MOTOR_COUNT 4

// Encoder Count
//`define QUAD_ENC 0

// Use a PLL for PWM generation
`define PWMPLL

`define BUFFERED_PLL

`define STEPINPUT

`define ENCODER_BITS 24

`define USE_DDA 0

// Change the Move Buffer Size. Should be power of two
//`define MOVE_BUFFER_SIZE 4
