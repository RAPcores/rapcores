// !!!
// These are derived parameters. User defines go in <board>.v files.
// !!!

// Version Number specification following SemVer
`define VERSION_MAJOR 0
`define VERSION_MINOR 1
`define VERSION_PATCH 0

// Default move buffer if not specified
`ifndef BUFFER_SIZE
`define BUFFER_SIZE 2
`endif

`define MOVE_BUFFER_SIZE `BUFFER_SIZE - 1 //This is the zero-indexed end index

`define MOVE_BUFFER_BITS $clog2(`BUFFER_SIZE)-1 // number of bits to index given size

`define MOTOR_COUNT DUAL_HBRIDGE // + other supported topologies in the future.

`ifndef DEFAULT_TIMER_WIDTH
`define DEFAULT_TIMER_WIDTH 8
`endif

// Default Mosfet Active Polarity
`ifndef DEFAULT_BRIDGE_INVERTING
`define DEFAULT_BRIDGE_INVERTING 1
`endif
