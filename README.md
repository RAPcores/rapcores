# RAPcores

![RAPcore](https://github.com/RAPcores/Ulticores/workflows/RAPCore/badge.svg)

http://rapcores.org/rapcores/

Robotic Application Processing Cores.

RAPcores is a motor and motion control toolkit for FPGAs and ASIC devices.
It creates a peripheral that sits between kinematics engines and motors to free up
processing power, enrich dynamical models, and greatly simplify the motor driver.

## Docs

- [Build](http://rapcores.org/rapcores/dev.html)
- [Configuration](http://rapcores.org/rapcores/configuration.html)
- [Releases](http://rapcores.org/rapcores/releases.html)
- [Motor Control Guide](http://rapcores.org/rapcores/motor_control.html)
- [ASIC Deployments](http://rapcores.org/rapcores/asic.html)
- [SPI Interface](http://rapcores.org/rapcores/spi_spec.html)
- [Support Software](http://rapcores.org/rapcores/interfaces.html)
- [C API](http://rapcores.org/rapcores/librapcore.html)

## FPGA Support

The following FPGA architectures are supported and tested on our build configuration system:

- iCE40
- ECP5
- Gowin (Experimental)
- nexus (Experimental)

We welcome ports to other architectures.

An early pathfinder has been hardened on ASIC for the Skywater Open MPW run using OpenLANE:

- [MPW-one ASIC](https://github.com/RAPcores/caravel_rapcores)

RAPcores RTL is written in Verilog and tested with Yosys and IVerilog.

## License

[ISC License](https://en.wikipedia.org/wiki/ISC_license)
