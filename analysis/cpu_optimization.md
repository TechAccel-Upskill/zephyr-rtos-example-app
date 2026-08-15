# CPU Optimization Analysis

## Overview

This document captures observations and applied optimizations for CPU resource
usage in the Zephyr + TF-A firmware demo. The target SoC family is ARM
Cortex-A / Cortex-M, with TF-A providing the Secure World runtime (BL31) and
Zephyr executing in the Non-Secure world.

---

## 1. WFI / WFE Usage and Tickless Idle

### Observation

Polling loops and short `k_sleep()` calls with a fixed tick rate cause the CPU
to wake unnecessarily, increasing average current draw and cache-cold re-entry
costs.

### Optimization Applied

- Enabled `CONFIG_TICKLESS_KERNEL=y` so the scheduler suppresses tick
  interrupts while no runnable thread is pending.
- The idle thread executes `WFI` (Wait For Interrupt) via Zephyr's
  `arch_cpu_idle()`, halting the pipeline until the next interrupt.
- On Cortex-A, `WFE` (Wait For Event) can be preferred in multi-core spinlock
  paths; use `__WFE()` / `__SEV()` intrinsics when a core is spinning on a
  lock to avoid bus-locking overhead.

### Measured Impact

| Configuration          | Avg idle current | Tick wakeup rate |
|------------------------|-----------------|-----------------|
| Tickful (100 Hz)       | baseline        | 100 /s          |
| Tickless + WFI         | −35 % (est.)    | event-driven    |

---

## 2. ARM big.LITTLE Scheduling (Cortex-A)

### Observation

On SoCs with big.LITTLE topology (e.g. Cortex-A72 + Cortex-A53), assigning
latency-sensitive ISRs to big cores and background tasks to little cores
improves both throughput and efficiency.

### Technique

1. Use `sched_setaffinity()` (Linux) or Zephyr's `CONFIG_SCHED_CPU_MASK` to
   pin the metrics reporting thread to the little cluster.
2. Pin time-critical DMA completion handlers to the big cluster.
3. TF-A's PSCI `CPU_ON` / `CPU_OFF` calls can be used to dynamically power
   individual cores; integrate with Zephyr's `pm_device` framework.

---

## 3. Cache Tuning

### Data Cache (D-cache)

- Ensure DMA buffers are placed in non-cacheable memory regions (configured
  via the MPU/MMU table in TF-A and carried through to Zephyr's linker
  script).
- Use `__attribute__((aligned(CACHE_LINE_SIZE)))` on frequently-accessed
  shared structures to avoid false sharing on multi-core targets.

### Instruction Cache (I-cache)

- Hot-path ISRs and the scheduler `_swap()` path benefit from I-cache
  prefetching. Ensure these symbols are in a `.fast_text` section placed in
  SRAM (see linker overlay example in `app/src/linker.ld`).

### Branch Predictor

- Minimize indirect branches inside tight loops; prefer function inlining
  (`__attribute__((always_inline))`) for sub-microsecond ISR paths.

---

## 4. Thread Stack Tuning

- Run `west build -- -DCONFIG_THREAD_ANALYZER=y` and inspect stack high-water
  marks at runtime to right-size stack allocations.
- Over-sized stacks waste SRAM and increase cache-line pressure.

---

## References

- [ARM Cortex-A Series Programmer's Guide — Power Management](https://developer.arm.com/documentation/den0013/latest)
- [Zephyr Power Management](https://docs.zephyrproject.org/latest/services/pm/index.html)
- [TF-A PSCI Implementation Guide](https://trustedfirmware-a.readthedocs.io/en/latest/design/psci-implementation-guide.html)
