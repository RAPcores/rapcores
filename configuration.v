
// Board Selection
`define TINYFPGABX
//`define ECP5DEVBOARD

`define VERSION_MAJOR 0
`define VERSION_MINOR 1
`define VERSION_PATCH 0

`define MOVE_BUFFER_SIZE 2

`define MOVE_BUFFER_BITS $clog2(`MOVE_BUFFER_SIZE) - 1 // number of bits to index given size
