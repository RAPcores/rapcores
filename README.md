# RAPcore

![RAPCore](https://github.com/RAPcores/Ulticores/workflows/RAPCore/badge.svg)

The Robotic Application Processing Core.

RAPCore is a project targeting FPGAs and ASIC devices for the next generation of motor and motion
control applications.

## Features

- Onboard stepper motor commutator/driver
- Fixed Point Step-Timing Algorithm
- High-speed Quadrature Encoder Accumulator
- High-Speed SPI Bus

## Target Hardware

The following FPGA architectures are supported and tested:

- iCE40
- ECP5

We welcome ports to other architectures.

## Build Requirements

RAPCores uses the free and open source Yosys and nextpnr toolchains.
See the [dev docs](./docs/dev.md) for more information.

## Documentation

- [Dev](./docs/dev.md)
- [SPI Protocol](./docs/spi_spec.md)
- [Board Parameters](./docs/boards.md)

## License

[ISC License](https://en.wikipedia.org/wiki/ISC_license).
