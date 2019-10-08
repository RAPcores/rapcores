PROJ = ulticore
PIN_DEF = hx8kboard.pcf
DEVICE = hx8k

all: $(PROJ).rpt $(PROJ).bin

%.json: %.v quad_enc.v spi.v
	yosys -p 'synth_ice40 -top soc -json $@' $^

%.asc: %.json $(PIN_DEF)
	nextpnr-ice40 --$(DEVICE) --json $< --pcf $(word 2,$^) --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
