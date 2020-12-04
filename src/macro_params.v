// !!!
// These are derived parameters. User defines go in <board>.v files.
// !!!

// Version Number specification following SemVer
`define VERSION_MAJOR 0
`define VERSION_MINOR 1
`define VERSION_PATCH 0

// Default move buffer if not specified
`ifndef MOVE_BUFFER_SIZE
`define MOVE_BUFFER_SIZE 2
`endif

`define MOVE_BUFFER_BITS $clog2(`MOVE_BUFFER_SIZE) - 1 // number of bits to index given size

`define MOTOR_COUNT DUAL_HBRIDGE // + other supported topologies in the future.

`ifndef DEFAULT_TIMER_WIDTH
`define DEFAULT_TIMER_WIDTH 8
`endif
