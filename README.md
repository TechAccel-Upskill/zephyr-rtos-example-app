# Zephyr + Trusted Firmware-A Firmware Optimization Demo

> **ARM Staff Developer Interview Showcase**
> Demonstrates firmware optimization skills across CPU, I/O, and power domains
> by integrating Trusted Firmware-A (TF-A) BL31 with a Zephyr RTOS application.

<a href="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/build.yml">
  <img src="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/build.yml/badge.svg">
</a>
<a href="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/tfa_build.yml">
  <img src="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/tfa_build.yml/badge.svg">
</a>

---

## Project Goal

This repository shows how to:

1. **Integrate TF-A BL31** into a Zephyr workspace — TF-A provides the EL3
   runtime (PSCI, SMCCC) while Zephyr runs in Non-Secure EL1.
2. **Demonstrate power-management optimizations** — tickless idle,
   `WFI`/`WFE` usage, and peripheral clock gating.
3. **Report CPU load and interrupt metrics** via a background Zephyr thread
   and an interactive shell command.
4. **Produce a combined FIP image** (TF-A BL31 + Zephyr BL33) in CI that
   can be loaded directly onto an ARM FVP or evaluation board.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      ARM SoC                                │
│                                                             │
│   EL3  ┌──────────────────────────────┐                    │
│        │  BL31 — TF-A Runtime (Secure)│  SMC ◄────────┐   │
│        │  • PSCI CPU on/off/suspend    │               │   │
│        │  • SMCCC dispatcher           │               │   │
│        └──────────────┬───────────────┘               │   │
│                 ERET  │                                │   │
│   EL1  ┌─────────────▼──────────────────────────┐    │   │
│   (NS) │  Zephyr RTOS (Non-Secure)               │    │   │
│        │  • Tickless kernel (WFI idle)            │────┘   │
│        │  • Power-managed peripherals             │        │
│        │  • CPU-load metrics thread               │        │
│        │  • Shell: `metrics` command              │        │
│        └────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

BL2 authenticates and loads both BL31 and Zephyr (BL33). BL31 stays resident
at EL3 and services `SMC` calls from Zephyr for power management and platform
services.

---

## Repository Layout

```
.
├── app/                   Zephyr application (metrics thread, shell cmd)
│   ├── src/main.c         Main + CPU-load reporting thread
│   └── prj.conf           Kconfig: PM, tickless kernel, shell, tracing
├── analysis/
│   ├── cpu_optimization.md        WFI/WFE, big.LITTLE, cache tuning
│   ├── io_optimization.md         DMA vs PIO benchmarks, clock gating
│   └── tfa_integration_notes.md   Boot flow, PSCI call table, SMCCC
├── scripts/
│   └── build_tfa.sh       Build TF-A BL31 and stage output binaries
├── tfa/                   ← populated by `west update` (TF-A source)
├── west.yml               Workspace manifest (Zephyr + TF-A projects)
└── .github/workflows/
    ├── build.yml          Existing Zephyr Twister CI
    └── tfa_build.yml      TF-A BL31 + combined FIP CI pipeline
```

---

## Getting Started

### Prerequisites

- Python 3.12+
- `west` (`pip install west`)
- ARM cross-compiler: `aarch64-linux-gnu-gcc` (for TF-A)
  and `arm-zephyr-eabi-gcc` (for Zephyr Cortex-M targets)
- Zephyr SDK — see the
  [Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/getting_started/index.html)

### Initialize the workspace

```shell
west init -m https://github.com/TechAccel-Upskill/zephyr-rtos-example-app \
    --mr main my-workspace
cd my-workspace
west update   # clones Zephyr modules AND TF-A into tfa/
```

### Build Zephyr

```shell
cd zephyr-rtos-example-app
west build -b $BOARD app
```

where `$BOARD` is your target (e.g. `custom_plank`, `nucleo_f302r8`).

### Build TF-A BL31

```shell
# Default target: FVP platform, AArch64
bash scripts/build_tfa.sh

# Override platform and architecture
bash scripts/build_tfa.sh tc2 aarch64
```

The BL31 binary is placed at `tfa-build/bl31.bin`.

### Build via Docker (all-in-one)

```shell
bash scripts/build_local_via_docker.sh
```

---

## Optimization Highlights

| Area | Technique | Estimated Saving |
|------|-----------|-----------------|
| CPU idle | `CONFIG_TICKLESS_KERNEL` + WFI | ~35 % avg current |
| I/O throughput | DMA for bulk transfers | ~5× faster, CPU free |
| Peripheral power | `pm_device` clock gating | varies by SoC |
| Cache pressure | Aligned DMA buffers, `.fast_text` section | ISR latency −20 % |

Full analysis:
- [`analysis/cpu_optimization.md`](analysis/cpu_optimization.md)
- [`analysis/io_optimization.md`](analysis/io_optimization.md)
- [`analysis/tfa_integration_notes.md`](analysis/tfa_integration_notes.md)

---

## Running the Metrics Shell Command

After flashing, connect a serial terminal (115 200 8N1) and type:

```
uart:~$ metrics
Total execution cycles: 4827392
```

The background `metrics` thread also logs per-thread CPU shares every 2 s via
the Zephyr logging subsystem.

---

## CI Pipeline

The [`tfa_build.yml`](.github/workflows/tfa_build.yml) workflow:

1. Builds the Zephyr app with Twister and uploads `zephyr.bin`.
2. Clones TF-A and builds `bl31.bin` for the FVP platform.
3. Combines both into a FIP image using `fiptool` and uploads `fip.bin`.

---

## Key References

- [Trusted Firmware-A Documentation](https://trustedfirmware-a.readthedocs.io/)
- [ARM PSCI Specification (DEN0022)](https://developer.arm.com/documentation/den0022/latest)
- [Zephyr Power Management](https://docs.zephyrproject.org/latest/services/pm/index.html)
- [Zephyr Example Application](https://github.com/zephyrproject-rtos/example-application)

