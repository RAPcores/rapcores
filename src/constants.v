

//
// SPI Command Header Constants
//

`define CMD_COORDINATED_STEP 8'h01
`define CMD_MOTOR_ENABLE 8'h0a
`define CMD_MOTOR_BRAKE 8'h0b
`define CMD_MOTORCONFIG 8'h10
`define CMD_CLK_DIVISOR 8'h20
`define CMD_MICROSTEPPER_CONFIG 8'h30
`define CMD_COSINE_CONFIG 8'h40
`define CMD_API_VERSION 8'hfe
`define CMD_CHARGEPUMP 8'h31
`define CMD_BRIDGEINVERT 8'h32


//
// Bit packed memory offsets for configs
//

`define MEM_MICROSTEPS 15:8
`define MEM_CURRENT 7:0