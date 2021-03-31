#!/bin/sh
iverilog ../src/microstepper/*.v ./iverilog_microstepper_tb.v ../src/generated/board.v ../src/macro_params.v ../src/microstepper/*.v ../src/pwm.v && vvp ./a.out
