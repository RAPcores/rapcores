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

# Do not use make's built-in rules
# (this improves performance and avoids hard-to-debug behaviour);
MAKEFLAGS += -r

# default board is rapbo
BOARD ?= rapbo

ifdef BOARD
	include ./boards/${BOARD}/${BOARD}.mk
endif

# Default parameters for PLL, since they are always generated, even if not used
SPIFREQ ?= 64
PWMFREQ ?= 150

# Default flags
SYNTH_FLAGS ?= -abc9
PNR_FLAGS ?=
YOSYS_FLAGS ?= -DBOARD=$(BOARD)
YOSYS_READ_VERILOG ?= read_verilog -sv -noassert -noassume -norestrict # -defer may be needed for parametrics

PROJ = rapcore
TOP = ./src/rapcore.v
GENERATEDDIR = ./src/generated/
SRCDIR = ./src/
BUILDDIR = ./build/
BUILD = $(BUILDDIR)$(BOARD)
RAPCOREFILES := boards/$(BOARD)/$(BOARD).v \
								$(addprefix src/, clock_divider.v \
														edge_detector.v \
													  macro_params.v \
														register_input.v \
														space_vector_modulator.v \
														spi_state_machine.v \
														pwm.v \
														quad_enc.v \
														spi.v \
														dda_fsm.v \
														dual_hbridge.v \
														dda_timer.v \
														rapcore.v) \
								$(wildcard src/microstepper/*.v)

# Some architectures or clock specs cannot have auto generated PLL.
# Define MANUALPLL=1 and instantiate PLL for include with a module like:
#     module spi_pll(
#   		input  clock_in,
#   		output clock_out,
#   		output locked
#   	);
ifndef MANUALPLL
	PLLFILES := src/generated/spi_pll_$(ARCH)_$(SPIFREQ).v src/generated/pwm_pll_$(ARCH)_$(PWMFREQ).v
endif
ifdef MANUALPLL
	PLLFILES := boards/$(BOARD)/spi_pll.v boards/$(BOARD)/pwm_pll.v 
endif

SYNTHFILES  = $(RAPCOREFILES)
SYNTHFILES += $(PLLFILES)

SIMFILES = $(RAPCOREFILES)
SIMFILES += ./src/sim/pwm_pll.v

all: $(BUILD).bit

$(BUILD).json: logs build $(SYNTHFILES)
	yosys -ql ./logs/$(BOARD)_yosys.log $(YOSYS_FLAGS) -p '$(YOSYS_READ_VERILOG) $(SYNTHFILES); synth_$(ARCH) -top $(PROJ) $(SYNTH_FLAGS) -json $(BUILD).json'

$(BUILD).bit: $(BUILD).json ./boards/$(BOARD)/$(PIN_DEF)
ifeq ($(ARCH), ice40)
	nextpnr-ice40 -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --json $(BUILD).json --asc $(BUILD).asc --pcf ./boards/$(BOARD)/$(PIN_DEF)
	icetime -d $(DEVICE) -c $(FREQ) -mtr $(BUILD).rpt $(BUILD).asc
	icepack $(BUILD).asc $(BUILD).bit
endif
ifeq ($(ARCH), ecp5)
	nextpnr-ecp5 -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --textcfg $(BUILD)_out.config --json $(BUILD).json  --lpf ./boards/$(BOARD)/$(PIN_DEF)
	ecppack --svf $(BUILD).svf $(BUILD)_out.config $(BUILD).bit
endif
ifeq ($(ARCH), nexus)
	nextpnr-nexus -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --device $(DEVICE) --freq $(FREQ) --json $(BUILD).json --fasm $(BUILD).fasm --pdc ./boards/$(BOARD)/$(PIN_DEF)
	prjoxide pack $(BUILD).fasm $(BUILD).bit
endif
ifeq ($(ARCH), gowin)
	nextpnr-gowin -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --device $(DEVICE) --freq $(FREQ) --json $(BUILD).json --cst ./boards/$(BOARD)/$(PIN_DEF)
	gowin_pack $(PACK_FLAGS) -o $(BUILD).bit $(BUILD).json
endif

$(PLLFILES):
ifndef MANUALPLL
ifeq ($(ARCH), ice40)
	icepll -i $(FREQ) -o $(SPIFREQ) -m -n spi_pll -f src/generated/spi_pll_$(ARCH)_$(SPIFREQ).v
	icepll -i $(FREQ) -o $(PWMFREQ) -m -n pwm_pll -f src/generated/pwm_pll_$(ARCH)_$(PWMFREQ).v
endif
ifeq ($(ARCH), ecp5)
	ecppll -i $(FREQ) -o $(SPIFREQ) --clkin_name clock_in --clkout0_name clock_out -n spi_pll -f src/generated/spi_pll_$(ARCH)_$(SPIFREQ).v
	ecppll -i $(FREQ) -o $(PWMFREQ) --clkin_name clock_in --clkout0_name clock_out -n pwm_pll -f src/generated/pwm_pll_$(ARCH)_$(PWMFREQ).v
endif
endif

build-full: build logs formal iverilog-parse $(BUILD).bit

logs:
	mkdir -p logs

build:
	mkdir -p build

build/clocks_$(BOARD).py:
	printf "ctx."

prog: $(BUILD).bit
	$(PROGRAMMER) $<

clean:
	rm -f $(BUILD).blif $(BUILD).asc $(BUILD).rpt  $(BUILD).json $(BUILD).bin $(BUILD).bit ./src/generated/*.v

cleanall:
	rm -rf build logs ./src/generated/*.v

formal:
	cat symbiyosys/symbiyosys.sby boards/$(BOARD)/$(BOARD).v > symbiyosys/symbiyosys_$(BOARD).sby
	sby -f symbiyosys/symbiyosys_$(BOARD).sby

iverilog-parse: $(SIMFILES)
	iverilog -tnull -g2012 -E -Wall $(SIMFILES)

yosys-parse: $(SIMFILES)
	yosys -qp 'read -sv $(SIMFILES)'

verilator-cdc: $(SIMFILES)
	verilator --top-module rapcore --clk CLK --cdc $(SIMFILES)

triple-check: yosys-parse iverilog-parse verilator-cdc

svlint: $(SIMFILES)
	svlint $(SIMFILES)

vvp: $(SIMFILES)
	iverilog -tvvp -g2012 $(SIMFILES)

testbench/vcd:
	mkdir -p testbench/vcd

yosys-%: testbench/vcd $(SIMFILES)
	yosys -s testbench/yosys/$*.ys $(SIMFILES)
	gtkwave testbench/vcd/$*.vcd

cxxrtl-%: testbench/vcd
	yosys testbench/cxxrtl/$*.ys
	clang++ -g -O3 -std=c++14 -I `yosys-config --datdir`/include testbench/cxxrtl/$*.cpp -o testbench/cxxrtl/$*.bin
	./testbench/cxxrtl/$*.bin
	gtkwave testbench/vcd/$*_cxxrtl.vcd

stat:
	yosys -s yosys/stats.ys $(SIMFILES) $(GENERATEDFILES)

ice40:
	yosys -s yosys/ice40.ys $(SIMFILES) $(GENERATEDFILES)


#
# RAPcore-cli and librapcore recipes
#


CFLAGS += -O2 -Wall -g -D_GNU_SOURCE -I$(OUTPUT)include

rapcore-cli: librapcore/rapcore-cli.c librapcore/librapcore.h
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o $@


#
# Misc.
#

.SECONDARY:
.PHONY: all prog clean formal build-full