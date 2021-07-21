============
Register Map
============

RAPcores has the following four types of registers to interface with the device:

- Status - Read
- Configuration - Read/Write
- Telemetry - Read
- Command - Read/Write

Status: Access to system state
Configuration: Parameters for device setup
Telemetry: Synchronized data snapshots
Command: Sets movement segment parameters

For the purposes of controlling RAPcores, the Telemetry and Command registers are used to set and observe the movements of the motors.
In applications that use SPI, these two registers may be accessed concurrently.
The basic operational primitive of RAPcores is a movement segment over some discrete time span. To allow for use in real-time and low-jitter
applications, command registers are at least double buffered. Similarly, the telemetry registers are syncronized to the
buffer switch events to allow for pathplanning correction and controls development. Telemetry registers differ from status registers
in that Telemetry registers provide "snapshots" of stored data on some even, whereas status registers are continuously updated.
Similarly, configuration registers take effect immediately whereas command registers are queued.



---------------
Config Register
---------------




---------------
Status Register
---------------

Note: All values here are read-only.

.. |version| wavedrom::

          {reg:[                        
              {bits: 8,  name: 'Patch'},
              {bits: 8,  name: 'Minor'},
              {bits: 8,  name: 'Major'},
              {bits: 8,  name: 'Devel'} 
          ]} 

.. |channel_info| wavedrom::

          {reg:[                        
              {bits: 8,  name: 'Motor Count'},
              {bits: 8,  name: 'Encoder Count'},
              {bits: 8,  name: 'Encoder Position Bits'},
              {bits: 8,  name: 'Encoder Velocity Bits'}
          ]} 

.. |encoder_fault| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Encoder Fault mask'},
          ]} 


=====   ===============
Entry   Bit Fields
=====   ===============
0x00     |version|
0x01     |channel_info|
0x02     |encoder_fault|
=====   ===============
