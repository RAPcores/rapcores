PIN_DEF = ecp5evn.lpf
ARCH = ecp5
DEVICE = um5g-85k
PACKAGE = CABGA381
FREQ = 12
PROGRAMMER = openocd -f boards/ecp5evn/ecp5evn.cfg -c "transport select jtag; init; svf build/ecp5evn.svf; exit"
SPIFREQ = 64
