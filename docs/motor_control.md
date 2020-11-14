# Motor Control

This section describes the principles of motor control at a low level.

## Definitions

- Integrated Driver - A IC taking step/direction signals with onboard logic for commutation and microstepping
- Commutation - The process of controlling an electrical bridge for
- Full Bridge - A center-tapped transistor circuit allowing for either high or low (ground) voltage
- H-Bridge - Two full bridges allowing for bidirectional current flow

## Electrical Commutation

Electrical commutation is the process of timing and controlling electrical current in the
windings of a motor. In years past you might use a brushed DC or induction motor, plug it
into you power supply or wall mains outlet and that would be it. The reason the hookup
for brushed DC is simple is due to electrical contacts called commutators. With induction
motors your mains AC voltage will generate a rotating potential in the motor making it spin,
which is also a form of commutation.

However, modern brushless motors require much more logic and control to perform their best.
First, since brushless motors (e.g. Steppers, BLDC) do not have electro-mechanical commutation
(hence the name "brush-less"), we need to digitally switch the motor coils on and off.
This is accomplished with arrays of transistors called "bridges" that allow for bidirectional
current flow. By controlling these bridges we can generate alternative voltages that make
the motor spin.

In contrast to integrated drivers e.g. that take PWM for BLDC, or step/direction for steppers,
the approach in RAPcore is to provide higher level APIs tailored for the application or
action. Some examples:

- "S"-curve stepping algorithms
- Sensorless homing
- Torque control

### Commutation Tables

#### Bipolar Stepper

|A|B|
|-|-|
|+|-|
|-|-|
|-|+|
|+|+|

#### Three Phase (BLDC, Induction)

|A|B|C|
|-|-|-|
|+|-| |
|+| |-|
| |+|-|
|-|+| |
|-| |+|
| |-|+|

#### Five Phase Stepper

|A|B|C|D|E|
|-|-|-|-|-|
|+| |-|-| |
|+|+| |-| |
| |+| |-|-|
| |+|+| |-|
|-| |+| |-|
|-| |+|+| |
|-|-| |+| |
| |-| |+|+|
| |-|-| |+|
|+| |-| |+|
