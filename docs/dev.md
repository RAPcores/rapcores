# Developer Docs

## Build Prerequisites

RAPCores targets the FOSS synthesis, place and route, and bitstream tools. Namely yosys and
nextpnr. We are open to support other flows and open source tool chain. However do note
that RAPcores does use some SystemVerilog features supported by Yosys.

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


### Verible (Optional)

Verilog Linting and formatting tool from Google.

[https://github.com/google/verible](https://github.com/google/verible)

### Programming Tools

#### ECP5 Devboard

openocd

#### TinyFPGA BX

The TinyFPGA BX uses tinyprog:

`pip3 install --user tinyprog`


## Build Bitstream

`make BOARD=<board>`


## Formal Verification

[https://github.com/YosysHQ/SymbiYosys](https://github.com/YosysHQ/SymbiYosys)

SymbiYosys is used for formal verification of the codebase. It can be run with:

`make formal BOARD=<board>`

This command will create a `symbiyosys` directory in the project that
contains all the logs and data from the verification. If an assert or
cover fails, a `.vcd` file will be generated that will display the states
of registers and wires that induced the failure. GTKWave is a useful
program for viewing the `.vcd` files.

The config for Symbiyosys is `symbiyosys.sby` in the root of the directory.


## Test Benches

`make testbench`

The config for the test bench is `sim.ys` in the root of the directory.

## Formatting

All files should have `none` as the default nettype:

```
`default_nettype none
```

## Linting

`make lint` : Will run Verible to lint the source.

Optionally this VSCode extension is helpful as well:

[https://github.com/mshr-h/vscode-verilog-hdl-support](https://github.com/mshr-h/vscode-verilog-hdl-support)


## Helpful Articles

- https://zipcpu.com/blog/2020/01/13/reuse.html
- https://www.reddit.com/r/yosys/comments/6ulm3m/new_simulation_within_yosys/

## Useful Tools

Google's Verilog formatter and linter:
- https://github.com/google/verible/
