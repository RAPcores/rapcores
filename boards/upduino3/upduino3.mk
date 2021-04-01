PIN_DEF = upduino3.pcf
ARCH = ice40
DEVICE = up5k
PACKAGE = sg48
FREQ = 12
PROGRAMMER = iceprog -d i:0x0403:0x6014
SPIFREQ = 64
PWMFREQ = 140
SYNTH_FLAGS = -abc9 -device u -dff
MANUALPLL = 1