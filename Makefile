# Makefile borrowed from https://github.com/cliffordwolf/icestorm/blob/master/examples/icestick/Makefile
#
# The following license is from the icestorm project and specifically applies to this file only:
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

ifdef BOARD
	include ./boards/${BOARD}/${BOARD}.mk
endif

PROJ = top
TOP = ./src/top.v
GENERATEDDIR = ./src/generated/
SRCDIR = ./src/
BUILDDIR = ./build/
BUILD = $(BUILDDIR)$(BOARD)

all: $(BUILD).bit

$(BUILD).bit:
# set board define for Verilog and include the board specific verilog file
	echo '`define $(BOARD)\n`include "./boards/$(BOARD)/$(BOARD).v"' > $(GENERATEDDIR)board.v
ifeq ($(ARCH), ice40)
	icepll -i $(FREQ) -o $(SPIFREQ) -m -n spi_pll -f $(GENERATEDDIR)spi_pll.v
	yosys -ql ./logs/$(BOARD)_yosys.log -p 'synth_ice40 -top $(PROJ) -abc9 -dsp -blif $(BUILD).blif -json $(BUILD).json' $(TOP)
	nextpnr-ice40 -ql ./logs/$(BOARD)_nextpnr.log --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --json $(BUILD).json --asc $(BUILD).asc --pcf ./boards/$(BOARD)/$(PIN_DEF)
	icetime -d $(DEVICE) -c $(FREQ) -mtr $(BUILD).rpt $(BUILD).asc
	icepack $(BUILD).asc $(BUILD).bit
endif
ifeq ($(ARCH), ecp5)
	ecppll -i $(FREQ) -o $(SPIFREQ) -n spi_pll -f spi_pll.v
	yosys -ql $(BOARD)_yosys.log -p 'synth_ecp5 -top $(PROJ) -json top.json' $(PROJ).v
	nextpnr-ecp5 -ql $(BOARD)_nextpnr.log --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --json $(PROJ).json --lpf ./boards/$(BOARD)/$(PIN_DEF)
	ecppack --svf $(PROJ).svf $(BOARD).bit
endif

prog: $(BUILD).bit
	$(PROGRAMMER) $<

clean:
	rm -f $(BUILD).blif $(BUILD).asc $(BUILD).rpt  $(BUILD).json $(BUILD).bin $(BUILD).bit ./src/generated/*.v

formal:
	echo '`define $(BOARD)\n`include "./boards/$(BOARD)/$(BOARD).v"' > $(GENERATEDDIR)board.v
	sby -f symbiyosys.sby

lint:
	verible-verilog-lint src/*.v

testbench:
	yosys sim.ys

.SECONDARY:
.PHONY: all prog clean testbench formal
