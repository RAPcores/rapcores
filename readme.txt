https://www.reddit.com/r/yosys/comments/6ulm3m/new_simulation_within_yosys/


https://github.com/YosysHQ/nextpnr

http://www.clifford.at/icestorm/

Simulation
//yosys sim.ys
yosys quad_sim.ys
gtkwave quad.vcd

Build with make 
make
make prog

Original build instructions
yosys -p 'synth_ice40 -top quad -json quad.json' quad.v
nextpnr-ice40 --hx8k --json quad.json --asc quad.asc
icepack quad.asc quad.bin
iceprog quad.bin

https://www.fpga4fun.com/QuadratureDecoder.html


yosys -p 'synth_ice40 -top quad -json quad.json' quad.v --gui
