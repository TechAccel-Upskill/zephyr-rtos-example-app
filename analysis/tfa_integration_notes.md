# TF-A Integration Notes

## Overview

This document describes how Trusted Firmware-A (TF-A) boots and hands off
execution to Zephyr, the PSCI call flow used for CPU hot-plug and power state
control, and the SMC calling convention used to cross the Secure/Non-Secure
boundary at runtime.

---

## 1. Boot Flow: TF-A → Zephyr

```
ROM / BootROM
     │
     ▼
BL1 (First-stage loader — ROM or on-chip SRAM)
  • Sets up minimal CPU state (MMU off, EL3)
  • Loads and authenticates BL2 from storage
     │
     ▼
BL2 (Trusted Boot — Secure EL1)
  • Authenticates and loads BL31, BL32 (optional), and BL33 (Zephyr)
  • Configures security boundaries via TZC-400 / TZC-380
     │
     ▼
BL31 (EL3 Runtime Firmware — runs permanently)
  • Provides PSCI, SMCCC, and platform-specific EL3 services
  • Hands off to BL33 (Zephyr) at EL1/EL2 Non-Secure
     │
     ▼
Zephyr (Non-Secure EL1)
  • Standard Zephyr boot: _start → z_cstart() → main()
  • Issues SMC calls to BL31 for PSCI / platform services
```

### Key Entry Point

BL31 calls `bl31_prepare_next_image_entry()` to configure the SPSR and ELR
registers before the `ERET` that jumps to Zephyr's reset vector. To change
the exception level Zephyr boots at, modify `bl31_plat_get_next_image_ep_info()`
in the platform port.

---

## 2. PSCI Call Flow

PSCI (Power State Coordination Interface) is the standard ARM interface for
CPU on/off/suspend. TF-A implements PSCI in BL31; Zephyr (or the OS driver)
issues `SMC` instructions with the correct function identifiers.

### Common PSCI Functions (SMC64)

| Function           | FunctionID     | Purpose                              |
|--------------------|----------------|--------------------------------------|
| `PSCI_VERSION`     | `0x84000000`   | Query PSCI version                   |
| `CPU_SUSPEND`      | `0xC4000001`   | Suspend a CPU core to a power state  |
| `CPU_OFF`          | `0x84000002`   | Power off calling CPU core           |
| `CPU_ON`           | `0xC4000003`   | Power on a secondary CPU core        |
| `AFFINITY_INFO`    | `0xC4000004`   | Query affinity-level power state     |
| `SYSTEM_SUSPEND`   | `0xC400000E`   | Suspend entire system                |
| `SYSTEM_OFF`       | `0x84000008`   | Power off system                     |
| `SYSTEM_RESET`     | `0x84000009`   | Reset system                         |

### Example: Suspending the System from Zephyr

```c
#include <zephyr/arch/arm64/smccc.h>

/* Issue PSCI SYSTEM_SUSPEND with a platform-specific power-state cookie */
static inline void psci_system_suspend(uintptr_t entry, uintptr_t context_id)
{
    struct arm_smccc_res res;

    arm_smccc_smc(0xC400000EUL, /* SYSTEM_SUSPEND */
                  entry,
                  context_id,
                  0, 0, 0, 0, 0,
                  &res);
}
```

---

## 3. SMC Calling Convention (SMCCC)

All SMC calls from Zephyr follow the ARM SMC Calling Convention
(DEN0028, currently v1.4):

- **x0**: Function identifier (encodes call type, owner, function number).
- **x1–x7**: Input parameters.
- **x0–x3**: Return values (x0 = error code, x1–x3 = results).
- Registers **x8–x17** are not preserved across SMC calls.
- Zephyr's `arm_smccc_smc()` / `arm_smccc_hvc()` wrappers (in
  `arch/arm64/include/zephyr/arch/arm64/smccc.h`) handle the call and
  collect return values into a `struct arm_smccc_res`.

---

## 4. TrustZone Security Boundaries

BL2 programs the TrustZone Controller (TZC-400) to partition DRAM:

| Region         | Address range (example) | Secure access | NS access |
|----------------|------------------------|---------------|-----------|
| Secure heap    | 0x0400_0000–0x04FF_FFFF | RW            | None      |
| Shared buffer  | 0x0500_0000–0x050F_FFFF | RW            | RO        |
| NS DRAM (Zephyr)| 0x0600_0000+           | None          | RW        |

Zephyr must not attempt to access Secure regions; doing so triggers a bus
abort that BL31 catches and logs via the crash reporting framework.

---

## 5. Enabling PSCI in Zephyr

Add the following to the board's DTS or overlay:

```dts
/ {
    cpus {
        enable-method = "psci";
    };

    psci {
        compatible = "arm,psci-1.0";
        method = "smc";
    };
};
```

And in `prj.conf`:

```
CONFIG_ARM_PSCI=y
```

---

## References

- [TF-A Documentation](https://trustedfirmware-a.readthedocs.io/en/latest/)
- [ARM PSCI Specification (DEN0022)](https://developer.arm.com/documentation/den0022/latest)
- [ARM SMCCC Specification (DEN0028)](https://developer.arm.com/documentation/den0028/latest)
- [Zephyr SMCCC API](https://docs.zephyrproject.org/latest/kernel/arch/arm64.html)
