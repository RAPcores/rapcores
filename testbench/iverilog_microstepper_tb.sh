#!/bin/sh
iverilog ./iverilog_microstepper_tb.v ../src/generated/board.v ../src/macro_params.v ../src/microstepper/*.v ../src/pwm.v && vvp ./a.out
