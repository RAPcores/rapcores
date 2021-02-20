// !!!
// These are derived parameters. User defines go in <board>.v files.
// !!!

// Version Number specification following SemVer
`define VERSION_MAJOR 0
`define VERSION_MINOR 2
`define VERSION_PATCH 0
`define VERSION_DEVEL 1

// Default move buffer if not specified
`ifndef BUFFER_SIZE
`define BUFFER_SIZE 2
`endif

`define MOVE_BUFFER_SIZE `BUFFER_SIZE - 1 //This is the zero-indexed end index

`define MOVE_BUFFER_BITS $clog2(`BUFFER_SIZE)-1 // number of bits to index given size

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

//
// Motor defaults
//

`ifndef DEFAULT_MICROSTEPS
`define DEFAULT_MICROSTEPS 8'd64
`endif

`ifndef DEFAULT_CURRENT
`define DEFAULT_CURRENT 8'd150
`endif