# SPI Specification

## Definitions

- SPI Transfer: An 8 bit, Mode 0 MSB SPI communication
- Words: 64 bits of 8 little endian SPI transfers
- Message: A complete SPI transmission consisting of one or more words
- Forward Channel: SPI communication initiated by firmware to FPGA
- Reverse Channel: Data transmitted by FPGA to firmware during message transfer

## Versioning

RAPCores follows [Semantic Versioning](https://semver.org/). This is still a pre-1.0
project so breaking changes are likely to happen with the SPI protocol. This document
serves as the "as-built" reference for the RAPcore, and may deviate from documents outside
this repository.

## Overview

The SPI bus operated in peripheral mode 0 MSB.The protocol assumes any complete transfer is
a 64 bit word. The word construction is set to little endian for improved compatibility with
SPI controller devices.


| Header                | Action                  | Transmission Length (Words) | Default Value |
|-----------------------|-------------------------|-----------------------------|---------------|
| 0x01                  | Coordinated Step Timer  | 1 + 2*N motors              | N/A           |
| 0x02                  | Integration Timer Scale | 1                           | 32            |
| 0x04                  | Set Microstepping       | 1                           | 2             |
| 0xfe                  | Get Version             | 2                           | 0x...MMmmpp   |


## Coordinated Step Timer - 64 bit coordinated segment command
This message type specifies a move segment to be clocked out of the core. It uses 64bit words to specify the DDA values, and returns 32bit precision encoder readings.

<table>
<tr>
<th rowspan="2">I/O</th>
<th colspan="8">Word 1 (Control / Status)</th>
<th colspan="8">Words 2,4,6,etc.</th>
<th colspan="8">Words 3,5,7,etc.</th>
</tr>
<tr>
<th>B1</th> <th>B2</th> <th>B3</th> <th>B4</th> <th>B5</th> <th>B6</th> <th>B7</th> <th>B8</th>
<th>B1</th> <th>B2</th> <th>B3</th> <th>B4</th> <th>B5</th> <th>B6</th> <th>B7</th> <th>B8</th>
<th>B1</th> <th>B2</th> <th>B3</th> <th>B4</th> <th>B5</th> <th>B6</th> <th>B7</th> <th>B8</th>
</tr>

<!-- left header-->
<tr><th>CO</th>

<!-- word 1-->
<td><code>0x01</code></td>
<td><code>RESERVED</code></td>
<td><code>0bPONM_LKJI</code></td>
<td><code>0bHGFE_DCBA</code></td>
<td colspan="4"><code>dda_ticks</code></td>

<!-- word 2-->
<td colspan="8"><code>substep_increment_<i>N</i></code></td>

<!-- word 3-->
<td colspan="8"><code>substep_increment_increment_<i>N</i></code></td>
</tr>

<tr>
<!-- left header-->
<th>CI</th>

<!-- word 1-->
<td colspan="8">Status word is TBD</td>

<!-- word 2-->
<td colspan="4"></td>
<td colspan="4"><code>shaft_encoder_<i>N</i></code></td>

<!-- word 3-->
<td colspan="4"></td>
<td colspan="4"><code>effector_encoder_<i>N</i></code></td>

</tr>
</table>

### Notes
- CO is the forward SPI channel from the controller to the peripheral (core). CI is the reverse channel.
- Word1 is the 64bit message header, consisting of 8 bytes, MSbyte = B1, LSbyte = B8
- Word1 from CO is the `control word`. Word1 back from the CI is the `status word`
- __N_ is the number of motor channels configured - making the message length 2xN+1 64bit words
- CO Word1, Byte1 is the message number in the control word
- CO direction bitfield: bit `A` is direction for motor 0; bit `P` is direction for motor 15;
  - Direction is arbitrary - 0 is considered Normal, 1 is Reverse
- CO `dda_ticks` is the segment length in DDA ticks. For example, a value of 16000 at a 16 MHz DDA clock sets a 1 mS segment
- CI `shaft_encoder_N` is the signed 32-bit absolute, unscaled encoder count for the shaft encoder. If no encoder is present it's absolute step count.
- CI `effector_encoder_N` is the signed 32-bit absolute, unscaled encoder count for the effector encoder; or zero if no encoder present
