============
Register Map
============

RAPcores has the following four types of registers/memories:

- Status - Read
- Configuration - Read/Write
- Telemetry - Read
- Command - Read/Write

Status: Access to system state
Configuration: Parameters for device setup
Telemetry: Synchronized data snapshots tied to command events
Command: Initiates a move or control pattern

The basic operational primitive of RAPcores is a movement segment over some discrete time span. To allow for use in real-time and low-jitter
applications, command registers are at least double buffered. Similarly, the telemetry registers are syncronized to the
buffer swap events to allow for pathplanning correction and controls development. Telemetry registers differ from status registers
in that Telemetry registers provide "snapshots" of stored data on some event, whereas status registers are continuously updated.
In practice, telemetry also may be a RAM resource whereas status is a hardware register.
Similarly, configuration registers take effect immediately whereas command registers are queued.

By default, RAPcores reserves memory and register sections for up to 32 motor channels and 64 encoder channels. This ensures
hardware devices below this limit are API compatible. The word size is selectable to 64 or 32 bits.

----------------------------
Configuration Register - Read/Write
----------------------------

.. |cfg_motor_enable| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Motor Enable Mask'},
          ]} 

.. |cfg_motor_brake| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Motor Brake-on-Disable Mask'},
          ]} 

.. |cfg_clocks| wavedrom::

          {reg:[                        
              {bits: 8,  name: 'DDA Clock Divider'},
          ]} 

=====   ===============
Entry   Bit Fields
=====   ===============
0x00     |cfg_motor_enable|
0x01     |cfg_motor_brake|
0x02     |cfg_clocks|
=====   ===============


---------------------------
Status Register - Read Only
---------------------------

.. |stat_version| wavedrom::

          {reg:[                        
              {bits: 8,  name: 'Patch'},
              {bits: 8,  name: 'Minor'},
              {bits: 8,  name: 'Major'},
              {bits: 8,  name: 'Devel'} 
          ]} 

.. |stat_channel_info| wavedrom::

          {reg:[                        
              {bits: 8,  name: 'Motor Count'},
              {bits: 8,  name: 'Encoder Count'},
              {bits: 8,  name: 'Encoder Position Bits'},
              {bits: 8,  name: 'Encoder Velocity Bits'}
          ]} 

.. |stat_encoder_fault| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Encoder Fault mask'},
          ]} 

.. |stat_motor_fault| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Motor Fault mask'},
          ]} 

.. |stat_encoder_position_start| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Encoder Position', attr: 'channel 0'},
          ]} 

.. |stat_encoder_position_end| wavedrom::

          {reg:[                        
              {bits: 32,  name: 'Encoder Position', attr: 'channel 31'},
          ]} 

=====   ===============
Entry   Bit Fields
=====   ===============
0x00     |stat_version|
0x01     |stat_channel_info|
0x02     |stat_encoder_fault|
0x03     |stat_motor_fault|
0x04     |stat_encoder_position_start|
...      ...
0x24     |stat_encoder_position_end|

=====   ===============
