# ADR 0001: Deterministic Safety State Machine

## Status

Accepted

## Context

The application needs a testable, hardware-independent policy for escalating
proximity hazards without coupling escalation logic to sensor or GPIO APIs.

## Decision

Implement `safety_monitor` as pure C (no Zephyr headers) with an explicit
config struct (`warning_samples`, `emergency_samples`, `fault_samples`) and a
single `safety_monitor_update()` entry point. Sensor/driver errors are
propagated as an explicit `sample_valid` boolean rather than folded into the
hazard boolean, so fault handling and hazard detection cannot be conflated.

## Consequences

- The policy can be unit tested on the host and on every QEMU target
  (Cortex-M/R/A) without any board-specific devicetree.
- Adding a new input (e.g. CAN) or a new output (e.g. a different actuator)
  only requires new glue code in `app/src/main.c`, not changes to the policy.
- Thresholds are Kconfig-driven so tuning does not require code changes.
