PROJ = ulticore
TRELLIS=/usr/share/trellis

all: ulticore.bit

%_tb.vvp: %_tb.v %.v quad_enc.v
	iverilog -s testbench -o $@ $^

%_sim: %_tb.vvp
	vvp -N $<

%.json: %.v quad_enc.v
	yosys -p 'synth_ecp5 -json $@' $^

%_out.config: %.json
	nextpnr-ecp5 --um5g-25k --package CABGA256 --json $< --textcfg $@ --no-tmdriv

%.bit: %_out.config
	ecppack --svf ulticore.svf $< $@

%.svf : %.bit

prog: %.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"


clean:
	rm -f ulticore_tb.vvp testbench.vcd %.json %_out.config

.PHONY: %_sim clean prog
.PRECIOUS: %.json %_out.config %.bit

