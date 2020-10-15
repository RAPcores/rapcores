`define VERSION_MAJOR 0
`define VERSION_MINOR 1
`define VERSION_PATCH 0

`ifndef MOVE_BUFFER_SIZE
`define MOVE_BUFFER_SIZE 2
`endif

`define MOVE_BUFFER_BITS $clog2(`MOVE_BUFFER_SIZE) - 1 // number of bits to index given size
