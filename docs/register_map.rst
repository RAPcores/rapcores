# Register Map

RAPcores has the following types of registers that may be used to interface with the device:

- Status - Read
- Configuration - Read/Write
- Telemetry - Read
- Command - Read/Write

Status: Realtime data access/system state
Configuration: Parameters for device setup
Telemetry: Time-synced concurrent data snapshots
Command: Sets movement segment parameters

For the purposes of controlling RAPcores, the Telemetry and Command registers are used to set and observe the movements of the motors.
In applications that use SPI, these two registers may be accessed concurrently.
The basic operational primitive of RAPcores is a movement segment over some discrete time span. To allow for use in real-time and low-jitter
applications, command registers are at least double buffered. Similarly, the telemetry registers are syncronized to the
buffer switch events to allow for pathplanning correction and controls development. Telemetry registers differ from status registers
in that Telemetry registers provide "snapshots" of stored data on some even, whereas status registers are continuously updated.
Similarly, configuration registers take effect immediately whereas command registers are queued.


# Config Register

.. wavedrom::

        { "signal": [
                { "name": "clk",  "wave": "P......" },
                { "name": "bus",  "wave": "x.==.=x", "data": ["head", "body", "tail", "data"] },
                { "name": "wire", "wave": "0.1..0." }
        ]}

