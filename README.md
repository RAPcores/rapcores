# RAPcores

![RAPcore](https://github.com/RAPcores/Ulticores/workflows/RAPCore/badge.svg)

https://rapcores.org/rapcores/

Robotic Application Processing Cores.

RAPcores is a motor and motion control toolkit for FPGAs and ASIC devices.
It creates a peripheral that sits between kinematics engines and motors to free up
processing power, enrich dynamical models, and greatly simplify the motor driver.

## Docs

- [Build](https://rapcores.org/rapcores/dev.html)
- [Configuration](https://rapcores.org/rapcores/configuration.html)
- [Releases](https://rapcores.org/rapcores/releases.html)
- [Motor Control Guide](https://rapcores.org/rapcores/motor_control.html)
- [ASIC Deployments](https://rapcores.org/rapcores/asic.html)
- [SPI Interface](https://rapcores.org/rapcores/spi_spec.html)
- [Register Map](https://rapcores.org/rapcores/register_map.html)
- [Support Software](https://rapcores.org/rapcores/interfaces.html)
- [C API](https://rapcores.org/rapcores/librapcore.html)

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
