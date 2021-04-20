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
	GENERATEDFILES := src/generated/spi_pll.v src/generated/pwm_pll.v
endif
ifdef MANUALPLL
	GENERATEDFILES := boards/$(BOARD)/spi_pll.v boards/$(BOARD)/pwm_pll.v 
endif

RAPCOREFILES += $(GENERATEDFILES)

all: $(BUILD).bit

$(BUILD).bit: logs pll build $(RAPCOREFILES)
ifeq ($(ARCH), ice40)
	yosys -ql ./logs/$(BOARD)_yosys.log $(YOSYS_FLAGS) -p 'synth_ice40 -top $(PROJ) $(SYNTH_FLAGS) -json $(BUILD).json' $(RAPCOREFILES)
	nextpnr-ice40 -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --json $(BUILD).json --asc $(BUILD).asc --pcf ./boards/$(BOARD)/$(PIN_DEF)
	icetime -d $(DEVICE) -c $(FREQ) -mtr $(BUILD).rpt $(BUILD).asc
	icepack $(BUILD).asc $(BUILD).bit
endif
ifeq ($(ARCH), ecp5)
	yosys -ql ./logs/$(BOARD)_yosys.log $(YOSYS_FLAGS) -p 'synth_ecp5 -top $(PROJ) $(SYNTH_FLAGS) -json $(BUILD).json' $(RAPCOREFILES)
	nextpnr-ecp5 -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --$(DEVICE) --freq $(FREQ) --package $(PACKAGE) --textcfg $(BUILD)_out.config --json $(BUILD).json  --lpf ./boards/$(BOARD)/$(PIN_DEF)
	ecppack --svf $(BUILD).svf $(BUILD)_out.config $(BUILD).bit
endif
ifeq ($(ARCH), nexus)
	yosys -ql ./logs/$(BOARD)_yosys.log $(YOSYS_FLAGS) -p 'synth_nexus -top $(PROJ) $(SYNTH_FLAGS) -json $(BUILD).json' $(RAPCOREFILES)
	nextpnr-nexus -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --device $(DEVICE) --freq $(FREQ) --json $(BUILD).json --fasm $(BUILD).fasm --pdc ./boards/$(BOARD)/$(PIN_DEF)
	prjoxide pack $(BUILD).fasm $(BUILD).bit
endif
ifeq ($(ARCH), gowin)
	yosys -ql ./logs/$(BOARD)_yosys.log $(YOSYS_FLAGS) -p 'synth_gowin -top $(PROJ) $(SYNTH_FLAGS) -json $(BUILD).json' $(RAPCOREFILES)
	nextpnr-gowin -ql ./logs/$(BOARD)_nextpnr.log $(PNR_FLAGS) --device $(DEVICE) --freq $(FREQ) --json $(BUILD).json --cst ./boards/$(BOARD)/$(PIN_DEF)
	gowin_pack $(PACK_FLAGS) -o $(BUILD).bit $(BUILD).json
endif

pll:
ifndef MANUALPLL
ifeq ($(ARCH), ice40)
	icepll -i $(FREQ) -o $(SPIFREQ) -m -n spi_pll -f $(GENERATEDDIR)spi_pll.v
	icepll -i $(FREQ) -o $(PWMFREQ) -m -n pwm_pll -f $(GENERATEDDIR)pwm_pll.v
endif
ifeq ($(ARCH), ecp5)
	ecppll -i $(FREQ) -o $(SPIFREQ) --clkin_name clock_in --clkout0_name clock_out -n spi_pll -f $(GENERATEDDIR)spi_pll.v
	ecppll -i $(FREQ) -o $(PWMFREQ) --clkin_name clock_in --clkout0_name clock_out -n pwm_pll -f $(GENERATEDDIR)pwm_pll.v
endif
endif

build-full: build logs iverilog-parse formal $(BUILD).bit

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

iverilog-parse: $(RAPCOREFILES)
	iverilog -tnull $(RAPCOREFILES)

yosys-parse: $(RAPCOREFILES)
	yosys -qp 'read -sv $(RAPCOREFILES)'

verilator-cdc: $(RAPCOREFILES)
	verilator --top-module rapcore --clk CLK --cdc $(RAPCOREFILES)

triple-check: yosys-parse iverilog-parse verilator-cdc

svlint: $(RAPCOREFILES)
	svlint $(RAPCOREFILES)

vvp: $(RAPCOREFILES)
	iverilog -tvvp $(RAPCOREFILES)

testbench/vcd:
	mkdir -p testbench/vcd

yosys-%: testbench/vcd $(RAPCOREFILES)
	yosys -s testbench/yosys/$*.ys src/sim/pwm_pll.v $(RAPCOREFILES)
	gtkwave testbench/vcd/$*.vcd

cxxrtl-%: testbench/vcd
	yosys testbench/cxxrtl/$*.ys
	clang++ -g -O3 -std=c++14 -I `yosys-config --datdir`/include testbench/cxxrtl/$*.cpp -o testbench/cxxrtl/$*.bin
	./testbench/cxxrtl/$*.bin
	gtkwave testbench/vcd/$*_cxxrtl.vcd

stat:
	yosys -s yosys/stats.ys $(RAPCOREFILES) $(GENERATEDFILES)

ice40:
	yosys -s yosys/ice40.ys $(RAPCOREFILES) $(GENERATEDFILES)

.SECONDARY:
.PHONY: all prog clean formal
