

https://github.com/YosysHQ/nextpnr

http://www.clifford.at/icestorm/

Simulation
//yosys sim.ys
yosys ulticore_tb.ys
gtkwave quad_enc.vcd

//nextpnr-ice40 --json blinky.json --pcf blinky.pcf --asc blinky.asc --gui


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

icepll -i 12 -o 60

nextpnr-ice40 --hx8k --json ulticore.json --asc ulticore.asc --gui
