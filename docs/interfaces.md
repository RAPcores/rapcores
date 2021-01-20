# Interfaces

## Interactive SPI using RasPi + Julia

You will need a:
- Raspberry Pi (This is tested in RasPi4)

Step 1:
[Install an operating System](https://www.raspberrypi.org/documentation/installation/installing-images/)

Step 2:
[Enable SPI + SSH](https://www.raspberrypi-spy.co.uk/2014/08/enabling-the-spi-interface-on-the-raspberry-pi/)

Step 3:
Download the Julia ARM binaries:

[https://julialang.org/downloads/](https://julialang.org/downloads/)

The most recent version is recommended (though it may only support ARM64 aka AArch64)

Step 4:
Wire the SPI from the RasPi pinout to the corresponding pins on the target board

Step 5:
Install BaremetalPi

from the Julia prompt (the Julia binary will be in download location ./bin/julia ):

```
julia> using Pkg

julia> Pkg.update()

julia> Pkg.add("BaremetalPi")
```

Step 6:

You should be ready to send commands. The full docs to BaremetalPi are available [here](https://github.com/ronisbr/BaremetalPi.jl).

Some examples:

```
julia> using BaremetalPi # import Pkg

julia> buf = zeros(UInt64, 4) # initializer a buffer
4-element Array{UInt64,1}:
 0x0000000000000000
 0x0000000000000000
 0x0000000000000000
 0x0000000000000000

julia> init_spi("/dev/spidev0.0", max_speed_hz=1_000_000) # initialize the SPI device

julia> spi_transfer!(1, [0x0a00000000000001], buf) # run the enable motor command
8

julia> spi_transfer!(1, [0x0100000000000000, 0x0000000001ffffff, 0x0000010000000000, 0x0000000100000000], buf); println(buf); # execute a transfer and print the buffer
```
