# Developer Docs

## Prerequisites

```
Yosys 0.9+2406 (git sha1 3209c076, gcc 9.3.0-10ubuntu2 -fPIC -Os)
nextpnr-ice40 -- Next Generation Place and Route (Version 44007eab)

Name: tinyprog
Version: 1.0.21
```

TinyFPGA program utility:
```
pip install --user tinyprog
```


Program the TinyFPGA B-series board with the bitstream:
```shell
make prog
```

## Build


## Format Spec

All files should have `none` as the default nettype:

```
`default_nettype none
```

## Verification

sby -f symbiyosys.sby

## Helpful Articles

- https://zipcpu.com/blog/2020/01/13/reuse.html

## Useful Tools

Google's Verilog formatter and linter:
- https://github.com/google/verible/
