yosys -import

set 

read_verilog -sv testbench/microstepper_tb.v src/microstepper/*.v
prep -top testbench
show m_control_0
sim -n 40000 -clock clk -vcd testbench/microstepper.vcd
