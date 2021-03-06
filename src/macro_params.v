// SPDX-License-Identifier: ISC
// !!!
// These are derived parameters. User defines go in <board>.v files.
// !!!

// Version Number specification following SemVer
`define VERSION_MAJOR 0
`define VERSION_MINOR 3
`define VERSION_PATCH 0
`define VERSION_DEVEL 1

// Default move buffer if not specified
`ifndef BUFFER_SIZE
`define BUFFER_SIZE 2
`endif

`ifndef DEFAULT_CLOCK_DIVISOR
`define DEFAULT_CLOCK_DIVISOR 40
`endif

`ifndef DEFAULT_TIMER_WIDTH
`define DEFAULT_TIMER_WIDTH 8
`endif

// Set the unsigned int size of the move duration register
`ifndef MOVE_DURATION_BITS
`define MOVE_DURATION_BITS 32
`endif

// Default Mosfet Active Polarity
`ifndef DEFAULT_BRIDGE_INVERTING
`define DEFAULT_BRIDGE_INVERTING 1
`endif

// Default Encoder accumulator bits
`ifndef ENCODER_BITS
`define ENCODER_BITS 32
`endif

//
// Motor defaults
//

`ifndef MOTOR_COUNT
`define MOTOR_COUNT 0
`endif

`ifndef DEFAULT_MICROSTEPS
`define DEFAULT_MICROSTEPS 8'd1
`endif

`ifndef DEFAULT_CURRENT
`define DEFAULT_CURRENT 8'd150
`endif

`ifndef USE_DDA
`define USE_DDA 1
`endif