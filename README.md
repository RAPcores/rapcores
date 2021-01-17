# RAPcore

![RAPcore](https://github.com/RAPcores/Ulticores/workflows/RAPCore/badge.svg)

https://rapcores.github.io/rapcores/

The Robotic Application Processing Core.

RAPcore is a project targeting FPGAs and ASIC devices for the next generation of motor and motion
control applications. It is a peripheral that sits between firmwares and motors to free up
processing on the microcontroller and greatly simplify the motor driver.

## Features

- Onboard stepper motor commutator (64x microstepping)
- High precision Fixed Point Step-Timing Algorithm
- High speed Quadrature Encoder Accumulator
- High Speed SPI Bus
- Multi-channel control with protocol support up to 56 motors

## Target Hardware

The following FPGA architectures are supported and tested:

- iCE40
- ECP5

We welcome ports to other architectures.

## Build Requirements

RAPcore uses the free and open source Yosys and nextpnr tool chains.
See the [dev docs](https://rapcores.github.io/rapcores/dev.html) for more information.

## Documentation

https://rapcores.github.io/rapcores/

## License

[ISC License](https://en.wikipedia.org/wiki/ISC_license).
