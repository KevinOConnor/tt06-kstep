This document provides information on testing "kstep" on the
standard Tiny Tapeout demo board.

# Kstep MicroPython test tool

The "kstep" project uses SPI for communication.  A `test_kstep` python
class can be found in the [test_kstep.py](test_kstep.py) file.  This
code provides some basic communication tools for communicating with
the "kstep" circuit.

One can cut-and-paste the contents of the
[test_kstep.py](test_kstep.py) into the standard Tiny Tapeout
MicroPython command session.

Alternatively, one can copy [test_kstep.py](test_kstep.py) to the
rp2040 flash and then import it into the main command session with:
`from test_kstep import test_kstep`

# Basic communication tests

Start by enabling the kstep design by running:
```python
kstep = test_kstep()
kstep.enable()
```

After running the above commands, all the segments of the lcd digit
display on the Tiny Tapeout board demo board should turn off.

A good test of communication is to write to the 0x10 "pin polarity"
register.  Try running:
```python
kstep.write_reg(0x10, 0b11111111)
```
That command should turn on all segments of the lcd digit display.
Try running the above command with different bits set - it is possible
to enable and disable the corresponding segments of the lcd digit
display.

Another good test is to verify clock timing by reading the 0x70
"clock" register.  Try running the following command:
```python
import time
t1=kstep.read_reg(0x70); time.sleep(1.0); t2=kstep.read_reg(0x70); print(t2-t1)
```
It should print out a value around 50000000 (as the kstep project
defaults to a 50Mhz clock).

One can also test writing to the clock:
```python
import time
t1=0; kstep.write_reg(0x70, t1); time.sleep(1.0); t2=kstep.read_reg(0x70); print(t2-t1)
```
It should also print out a value around 50000000.

# Basic step scheduling tests

It is possible to use lcd digit display to verify basic step
scheduling.  The step scheduler is designed to command a stepper motor
driver, but for testing purposes it can also behave as a simple Pulse
Width Modulator (PWM).  That is, it can dim the top segment of the lcd
digit display.

Try the following code:
```python
def pulse_as_pwm(ks):
    # init
    ks.write_reg(0x10, 0b00000000) # Clear all polarity
    ks.set_pin_shutdown(0)
    ks.write_reg(0x11, 0) # Clear shutdown (just in case)
    ks.set_pulse_time(0.00125)
    # Start queuing
    ks.write_reg(0x70, 0x80000000) # Dummy clock to avoid misstart
    ks.write_reg(0x30, 0) # Clear last step clock
    # Queue pulses
    ks.set_next_step_dir(0)
    ks.queue_steps_time(1000, 0.005)
    ks.set_next_step_dir(1)
    ks.queue_steps_time(500, 0.010)
    ks.set_next_step_dir(0)
    ks.write_reg(0x70, 0xfffffff8) # Begin timing after 2 entries queued
    ks.queue_steps_time(5000, 0.002)
    ks.queue_steps_time(1000, 0.003)

kstep = test_kstep()
kstep.enable()
pulse_as_pwm(kstep)
```
The above should run for a few seconds and show various brightness
levels on the top segment of the lcd display (which corresponds with
the "step" pin).  The top right segment will also turn on and off
during the test (as it corresponds with the "direction" pin).

# Testing with a stepper motor driver

It is possible to wire kstep to an actual stepper motor driver and
stepper motor.  This is a more elaborate test.  The description here
involves wiring a
[reprap style a4988 stepstick](https://reprap.org/wiki/StepStick) to
the Tiny Tapeout development board.  One will need a stepstick, a
stepper motor, a separate 12V power supply (or similar), and
sufficient wires.

The stepper motor driver works with 12V (or higher) voltages.  Caution
should be taken when wiring these boards as an incorrect wiring may
permanently damage the Tiny Tapeout board and components.

The test here assumes the `out0` pin has been wired to the stepstick
`step` pin, `out1` wired to `dir`, and `out2` wired to `enable`.  It
is assumed that `sleep` will be wired to `reset` on the stepstick.  It
is also assumed that `ms1`, `ms2`, and `ms3` will all be wired to 3.3V
`vdd` (for 16 microstep mode).

In this mode, the `out2` pin controls the enable mode of the driver,
which is active low.  So, it is recommended to initialize the "kstep"
in driver disabled mode *prior* to applying 12V power to the stepper
motor driver.
```python
kstep = test_kstep()
kstep.enable()
kstep.write_reg(0x10, 0b00000100)
```

Once everything is wired and initialized, one may apply 12V power to
the stepper motor driver and run a step movement test.  The following
commands can be used to queue a series of movements that involve an
acceleration and deceleration sequence.
```python
movement = [
    (1,),
    (1, 1118034, 0),
    (1, 409229, 0),
    (1, 281754, 0),
    (2, 228238, -29426),
    (3, 176218, -13922),
    (4, 139794, -7194),
    (5, 113897, -3844),
    (9, 95121, -2115),
    (9, 77511, -1266),
    (15, 66436, -747),
    (18, 55772, -463),
    (23, 47820, -293),
    (31, 41310, -188),
    (36, 35743, -126),
    (44, 31410, -86),
    (403, 27953, 0),
    (46, 28247, 85),
    (34, 32366, 124),
    (28, 36820, 186),
    (22, 42308, 287),
    (18, 48857, 459),
    (14, 57440, 753),
    (10, 68664, 1261),
    (7, 82248, 2184),
    (6, 98202, 3989),
    (3, 125310, 7270),
    (3, 148718, 13578),
    (2, 198375, 31426),
    (1, 281755, 0),
    (1, 409229, 0),
]

def send_movements(ks, cmds):
    # init
    ks.write_reg(0x10, 0b00000000)
    ks.set_pin_shutdown(0)
    ks.write_reg(0x11, 0) # Clear shutdown (just in case)
    ks.set_pulse_time(0.000002)
    # Start queing
    ks.write_reg(0x70, 0x80000000) # Dummy clock to avoid misstart
    ks.write_reg(0x30, 0) # Clear last step clock
    # Queue pulses
    numqueue = 0
    for cmd in cmds:
        if len(cmd) == 1:
            ks.set_next_step_dir(cmd[0])
            continue
        count, interval, add = cmd
        if numqueue == 2:
            # Start clock
            ks.write_reg(0x70, 0xfffffff8)
        ks.queue_steps(count, interval, add)
        numqueue += 1
    # Turn off stepper
    ks.write_reg(0x10, 0b00000100)

send_movements(kstep, movement)
```

Unfortunately, the "kstep" design only has a single queue entry and
the MicroPython code running on the rp2040 is often too slow to keep
that queue populated.  If the rp2040 running MicroPython is unable to
issue the next command fast enough, the process may become stuck (the
"kstep" design may end up waiting for an entire 32-bit clock counter
rollover before processing the next queue entry).  If this occurs, one
can hit `cntl-c` and then reset "kstep" by running `kstep.enable()`
and `kstep.write_reg(0x10, 0b00000100)`.

# Errata

When queuing multiple entries, the time spent on each entry is
`interval*(count+1) + add*(count+1)*count//2` while the original
intent was `interval*count + add*count*(count-1)//2`.  That is,
`count` steps are sent as intended, but effectively `count+1` time is
used.  This does not impact basic testing, but it is different from
the original intent.
