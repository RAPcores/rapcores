
// Build opts
`include "configuration.v"

// Motor Enumerations for board configs
`define DUAL_H_BRIDGE 1

// Board includes
`ifdef TINYFPGABX
  `include "./boards/tinyfpgabx/tinyfpgabx.v"
`endif
