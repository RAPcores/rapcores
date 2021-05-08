# RAPcores

![RAPcore](https://github.com/RAPcores/Ulticores/workflows/RAPCore/badge.svg)

http://rapcores.org/rapcores/

Robotic Application Processing Cores.

RAPcores is a motor and motion control toolkit for FPGAs and ASIC devices.
It creates a peripheral that sits between kinematics engines and motors to free up
processing power, enrich dynamical models, and greatly simplify the motor driver.

## Features

- Onboard stepper motor commutator (at least 256x microsteps)
- High precision 64-bit fixed-point second order motion interpolator
- High speed second order quadrature encoder
- High speed SPI bus
- Multi-channel control with protocol support up to 56 motors

## Target Hardware

The following FPGA architectures are supported and tested:

- iCE40
- ECP5
- Gowin (Experimental)
- nexus (Experimental)

We welcome ports to other architectures.

An early pathfinder has been hardened on ASIC for the Skywater Open MPW run using OpenLANE:

- [MPW-one ASIC](https://github.com/RAPcores/caravel_rapcores)

## Build Requirements

RAPcores uses the free and open source Yosys and nextpnr tool chains.
See the [dev docs](https://rapcores.github.io/rapcores/dev.html) for more information.

## Documentation

https://rapcores.github.io/rapcores/

## License

[ISC License](https://en.wikipedia.org/wiki/ISC_license).
