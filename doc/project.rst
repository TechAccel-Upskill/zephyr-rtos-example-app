Safety Monitor Project
======================

Purpose
-------

The application is a small embedded safety monitor. It samples a GPIO-backed
proximity sensor, applies a deterministic policy, and controls a status LED.
The policy is independent of Zephyr so it can be tested without hardware.

Failure policy
--------------

The monitor requires consecutive valid hazard samples before escalating. It
enters ``FAULT`` after consecutive invalid samples and returns to ``NORMAL``
after a valid clear sample. The LED blink period communicates the current state.
Thresholds are configured in Kconfig and are intentionally visible in the
application logs.

Practice extensions
-------------------

Useful next exercises include watchdog supervision, a second-sensor voting
scheme, an I2C sensor implementation, shell diagnostics, and resource
measurements using Zephyr's thread and runtime statistics.