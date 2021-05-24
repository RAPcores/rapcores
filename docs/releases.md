# Release Notes


RAPcores follows [Semantic Versioning](https://semver.org/). 
Note: RAPcores in pre-v1.0 so API breakages should be expected.
Stabilized releases live in "release-M.m" branches.


## 0.3.0 - (Current Development)

Branch: main
Milestone: [GitHub](https://github.com/RAPcores/rapcores/milestone/3)


## 0.2.0 - "Pathfinder2"

Branch: release-0.2
Milestone: [GitHub](https://github.com/RAPcores/rapcores/milestone/2)

Continued development and pathfinding. Notable developments:
- Improved board and architecture support
- Add support for multiple motor channels
- Improved microstepping support
- Numerous bug fixes

The base SPI protocol semantics in v0.2 are compatible with v0.1. 

## 0.1.0 - "Pathfinder"

Branch: release-0.1
Milestone: [GitHub](https://github.com/RAPcores/rapcores/milestone/1)

Initial development pathfinder combining 64x microstep stepper control with custom
design motor inverter, SPI bus, and step timing algorithm derived from G2 firmware.
ASIC hardened design on the Google sponsored Skywater 130nm ASIC MPW shuttle.
