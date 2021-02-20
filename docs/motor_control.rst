=============
Motor Control
=============

This section describes the principles of motor control at a low level.

Definitions
===========

- Integrated Driver - A IC taking step/direction signals with onboard logic for commutation and microstepping
- Commutation - The process of controlling an electrical bridge for
- Full Bridge - A center-tapped transistor circuit allowing for either high or low (ground) voltage
- H-Bridge - Two full bridges allowing for bidirectional current flow

Electrical Commutation
======================

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
the approach in RAPcores is to provide higher level APIs tailored for the application or
action. Some examples:

* "S"-curve stepping algorithms
* Sensorless homing
* Torque control

Commutation Tables
==================

Bipolar Stepper
---------------

== ==
A  B 
== ==
\+ \- 
\- \- 
\- \+ 
\+ \+ 
== ==

Three Phase (BLDC, Induction)
-----------------------------

 == == ==
 A  B  C 
 == == ==
 \+ \- \  
 \+ \  \- 
 \  \+ \- 
 \- \+ \  
 \- \  \+ 
 \  \- \+ 
 == == ==

Five Phase Stepper
------------------

 == == == == ==
 A  B  C  D  E 
 == == == == ==
 \+ \  \- \- \  
 \+ \+ \  \- \  
 \  \+ \  \- \- 
 \  \+ \+ \  \- 
 \- \  \+ \  \- 
 \- \  \+ \+ \  
 \- \- \  \+ \  
 \  \- \  \+ \+ 
 \  \- \- \  \+ 
 \+ \  \- \  \+ 
 == == == == ==

Space Vector Modulation
=======================

The key to smooth and efficient motor control is current regulation.
Through current regulation in a motor, one can accomplish a few valuable things:

* Microstepping (subdividing the commutation table)
* Current regulation (limiting power output for efficiency)

With closed loop current regulation, e.g. through a current sense resistor, additional
capabilities are also achieved:

* Fault detection
* Phase shift and skip detection


Vector Concepts
---------------

Here we will present the mathematical ideas of how to model the target current in a bipolar stepper
motor as a vector. This is known as `Space Vector Modulation <https://en.wikipedia.org/wiki/Space_vector_modulation>`_.
To start we must understand some basic concepts from vector algebra and trigonometry.

Recall that sine and cosine are derived from the components of a vector rotating around the origin:

.. image:: https://upload.wikimedia.org/wikipedia/commons/b/bd/Sine_and_cosine_animation.gif

And recall the identity where:

.. math::
  cos(\theta)^2+sin(\theta)^2=1

Or alternatively:

.. math::
  A \cdot cos(\theta)^2+A \cdot sin(\theta)^2=A

The above equation is essential in our understanding of constructing the vector. Recall the phase table for the bipolar stepper:

== ==
A  B 
== ==
\+ \- 
\- \- 
\- \+ 
\+ \+ 
== ==

If we visualize each phase as a 2D plot we can see these commutation steps form the corners of a square as shown below:

.. image:: ./img/bipolar-svm.svg

Microstepping is possible in this space (a square), however it yields undesirable effects since the total current in the motor
varies due to a change of vector length as shown in the red arrow above. This can yield resonance and torque ripples. The objective
is to create smooth motion as we traverse between the phases. Therefore we need to move our vector along a circle, such as the arrows in blue above. The trade-off is
that we do not achieve the peak torque attainable in the corners of the square, but instead the motion is smooth and controllable.

PWM Concepts
------------

Below is a simple PWM module in verilog:

.. code-block:: verilog
  :linenos:

    /*
    Simple PWM module
    */
    module pwm #(
        parameter bits = 8
    ) (
        input  clk,
        input  resetn,
        input  [bits-1:0] val,
        output pwm
    );

      reg [bits-1:0] accum;
      assign pwm = (accum < val);

      always @(posedge clk)
      if(!resetn)
        accum <= 0;
      else if(resetn)
        accum <= accum + 1'b1;

    endmodule

We can see that the PWM output frequency is a function of the base clock frequency (`clk`) and the number of bits used for the accumulator. E.g.:

.. math::

  F_{PMW} = \frac{F_{clk}}{2^{bits}}


For quiet operation and fast updates we want the PWM frequency to be superaudible, so a value greater than 30khz. Assume we use a PLL to achieve
a higher operational frequency for `PWM` module at 150mhz. The bit resolution of the PWM can be calculated thus:

.. math::

  bits = \log_2({F_{PMW}/F_{clk}})

In our example of a 30khz output with a 150mhz accumulator clock we get ~12.3 bit resolution. For simplicity we will use 12 bits going forward.

Now the challenge is how to compute the value to the PWM such that we bring both the current and the microstep/phase angle into a single value.
In the next section we will see this is a relatively straight forward process that falls out of the vector model.


Applied Space Vector Modulation
-------------------------------

Recall that a vector (:math:`\vec{A}`) may be element-wise scaled by a given factor such that the length (:math:`\left\lVert\vec{A}\right\rVert`) is scaled by the same factor.
Our vector is formed from a given angle (or microstep position) :math:`\theta` as: :math:`(cos(\theta), sin(\theta))`. Then scaling the current is simply multiplication of this vector
by a factor `C`: :math:`(C \cdot cos(\theta), C \cdot sin(\theta))`. Then using the above identify we known that the length of this vector is:

.. math::
  \left\lVert(C \cdot cos(\theta), C \cdot sin(\theta))\right\rVert = C

Then the matter of partitioning the 12 bit space of the PWM become quite simple. For example we may use 8 bits for the trigonometric functions (implemented as lookup tables in practice), and 4 bits for current.
Which gives sufficient precision for 64 microsteps and 16 discrete current values.

So now we can do space vector modulation. But where do we put it? The answer is as a voltage reference or gate PWM input. For example we may use this output to
create a reference for a 1-bit ADC by adding a RC filter to the output in a `chopper drive <https://en.wikipedia.org/wiki/Chopper_(electronics)>`_. 
Or for a dead-reckoned approach this PWM can be used to quickly turn the gate drivers on and off. An example of this can be found in the RAPcores Dual H Bridge module.


SVM in Three Phase
------------------

For the mathematically inclined, you may notice that the bipolar stepper is nice as the phases form an orthonormal basis in 2D space. In three phase this is not the case.
We have yet to implement three phase in RAPcores, but in the interim `the wikipedia page <https://en.wikipedia.org/wiki/Space_vector_modulation>`_ has some
information on handling this case.