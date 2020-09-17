# Developer Docs

## Build Prerequisites

RAPCores targets the FOSS synthesis, place and route, and bitstream tools.
Linux is recommended for development. These tools rapidly improve, so it is recommended
the tools are built from source and kept up to date.

Please check each repo for detailed build instruction.
If something breaks use `git reflog` to rollback to the prior commit.

### Yosys (Required)

[https://github.com/YosysHQ/yosys](https://github.com/YosysHQ/yosys)

### Nextpnr (Required)

[https://github.com/YosysHQ/nextpnr](https://github.com/YosysHQ/nextpnr)

Note: Icestorm and/or Prjtrellis should be installed before nextpnr.

### Icestorm (Ice40 Architectures)

[https://github.com/YosysHQ/icestorm](https://github.com/YosysHQ/icestorm)

### prjtrellis (ECP5 Architectures)

[https://github.com/YosysHQ/prjtrellis](https://github.com/YosysHQ/prjtrellis)

### Programming Tools

#### ECP5 Devboard

openocd

#### TinyFPGA BX

The TinyFPGA BX uses tinyprog:

`pip3 install --user tinyprog`


## Formatting

All files should have `none` as the default nettype:

```
`default_nettype none
```

## Formal Verification

[https://github.com/YosysHQ/SymbiYosys](https://github.com/YosysHQ/SymbiYosys)

sby -f symbiyosys.sby

## Helpful Articles

- https://zipcpu.com/blog/2020/01/13/reuse.html

## Useful Tools

Google's Verilog formatter and linter:
- https://github.com/google/verible/
