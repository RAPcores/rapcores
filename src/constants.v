

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
// Buffer Memory Offsets
//

`define MOVE_BUF_DIRECTION 0
`define MOVE_BUF_DURATION 1
// Axes follow increment=2, incrementincrement=3 ...