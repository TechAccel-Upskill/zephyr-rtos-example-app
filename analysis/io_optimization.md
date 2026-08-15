# I/O Optimization Analysis

## Overview

This document covers DMA vs. PIO benchmarking results, peripheral clock
gating strategies, and bus-fabric optimizations observed while running the
Zephyr + TF-A demo on an ARM evaluation platform.

---

## 1. DMA vs. PIO Benchmark

### Setup

- Data transferred: 64 KiB block from SRAM to a simulated peripheral FIFO.
- Timer: Zephyr `timing_counter_get()` before and after each transfer.
- Two configurations compared:
  1. **PIO** — CPU writes 32-bit words in a tight loop.
  2. **DMA** — Single-channel AXI DMA; CPU triggers transfer and waits on
     completion semaphore.

### Results

| Transfer mode | Time (µs) | CPU cycles consumed | CPU idle during xfer |
|---------------|-----------|---------------------|----------------------|
| PIO (loop)    | 512       | ~51 200             | 0 %                  |
| DMA           | 98        | ~480 (setup only)   | > 99 %               |

### Takeaway

DMA frees the CPU for other work and reduces effective execution time by ~5×
for bulk transfers. Use `CONFIG_DMA=y` and the Zephyr DMA API
(`dma_config()`, `dma_start()`).

---

## 2. Peripheral Clock Gating

### Observation

Unused peripherals (e.g., unused UART, SPI controllers) continue to draw
dynamic power if their clocks remain enabled after initialization.

### Technique

1. Enable `CONFIG_PM_DEVICE=y`.
2. Implement `pm_device_action_run(dev, PM_DEVICE_ACTION_SUSPEND)` for
   peripherals that have idle periods longer than the clock-gate latency
   (~50 ns on Cortex-M, ~200 ns on Cortex-A with GIC coordination).
3. For TF-A-managed resources, issue `SMC` calls via the SCMI/SCP firmware
   interface to gate clocks in the Secure World.

### Example

```c
/* Suspend SPI1 when not in use */
const struct device *spi = DEVICE_DT_GET(DT_NODELABEL(spi1));
pm_device_action_run(spi, PM_DEVICE_ACTION_SUSPEND);
/* ... time passes ... */
pm_device_action_run(spi, PM_DEVICE_ACTION_RESUME);
```

---

## 3. AXI Bus Bandwidth Optimization

### Observation

Unaligned memory accesses on AXI4 fabric can generate split transactions,
doubling effective bus cycles for the same payload.

### Fixes Applied

- Aligned DMA source and destination buffers to the AXI data width (128-bit /
  16 bytes) using `__attribute__((aligned(16)))`.
- Set AWBURST/ARBURST to `INCR` rather than `FIXED` for bulk transfers.
- Used write-combining attributes (`MT_DEVICE_nGnRE`) only for MMIO; SRAM
  regions use `MT_NORMAL` with inner-shareable cacheability.

---

## 4. Interrupt Coalescing

For high-frequency I/O events (e.g., Ethernet Rx), configure the interrupt
moderation timer in the peripheral controller to batch IRQs:

- Set `rx_coalesce_usecs = 50` and `rx_max_coalesced_frames = 16` (Linux
  ethtool equivalent) via the driver's device-tree binding or runtime API.
- This reduces interrupt overhead from O(N packets) to O(N/16) at the cost of
  ≤50 µs added latency per burst.

---

## References

- [Zephyr DMA API](https://docs.zephyrproject.org/latest/hardware/peripherals/dma.html)
- [ARM AXI4 Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest)
- [Zephyr Device Power Management](https://docs.zephyrproject.org/latest/services/pm/device.html)
