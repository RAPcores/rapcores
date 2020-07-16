# TinyFPGA-Stepper
WIP and PoC for stepper motor control using TinyFPGA, to merge with Ulticores


## Reproducability

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
