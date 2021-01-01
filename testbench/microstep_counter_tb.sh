#!/bin/sh
iverilog ./microstep_counter_tb.v ./counter.v ../src/microstepper/cosine.v ../src/microstepper/microstep_counter.v && vvp ./a.out