RAPcore Documentation
=====================

RAPcore stands for Robotic Application Processing Core, and
seeks to develop high-performance hardware to enable the next generation
of robotics application. The project was started by Ultimachine and Synthetos,
two companies that have innovated technologies such as the RAMPS board, RAMBo, and
jerk controlled kinematics in low-cost additive and subtractive systems.

Objective
---------

3D printers as one of the first ubiquitous robots, but there is far more value in automation
and digital manufacturing technologies that has yet to be unlocked to the average person.
RAPcore leverages recent advancements in technology to help accomplish this:

* Open Source FPGA synthesis
* Open Source formal verification
* Open Source RISC-V CPUs
* Advanced motor control and kinematic algorithms

To start, the project is focused on FPGA hardware for high performance closed-loop motor
control. These early iterations will prove-out the hardware and RAPcore gateware. Similarly,
we will greatly reduce the computational overhead on microcontrollers by coordinating
step sequences and commutation. This will lead to a suitable middle ground of price
and performance based upon our analysis. By fusing the step timing and commutation logic
into a single element (the FPGA) we allow for smaller and more efficient micro controllers,
and on the drive side we allow for greater flexibility and power output of motor driver
circuitry.

Feature Overview
----------------

The basic features of RAPcores is as follows:

* Onboard stepper motor commutator
* Fixed Point Step-Timing Algorithm
* High-speed Quadrature Encoder Accumulator
* High-Speed SPI Bus

Contents
--------

.. toctree::
   :maxdepth: 2

   releases
   spi_spec
   boards
   dev
   motor_control
   interfaces
   asic