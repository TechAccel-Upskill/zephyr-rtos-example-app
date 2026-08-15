---
name: arm-jd-coverage-report
description: Track how much of this repository's content matches the Arm Staff Firmware Developer JD (see arm-staff-firmware-jd skill), with a scored gap analysis and a prioritized list of gap-closers targeting 80%+ alignment. Use when planning what to build next, reviewing progress, or re-scoring after changes.
---

# Skill: Arm JD Coverage Report (Matches & Gaps)

This is a **living scorecard** for `zephyr-rtos-example-app` against the
`arm-staff-firmware-jd` skill. Re-run this scoring whenever significant
features are added, and update the tables/score below in place.

## Scoring Method

Each JD bullet is scored 0–100% based on concrete evidence in the repo (file
references, not intentions). Scores are grouped into three buckets weighted
to match the JD's own structure:

- Responsibilities — 35%
- Required Skills and Experience — 40%
- Nice to Have — 25%

Overall score = weighted average of the three bucket averages.

## Current Snapshot (2026-08-15, updated after gap-closing pass)

> **Note:** These scores are re-estimated from source review, not from a
> full `west twister` build (the sandbox used to write this had no
> `west`/`ZEPHYR_BASE`/`bitbake`). Run the CI workflows to confirm before
> treating this as final.

### 1. Responsibilities (35%)

| JD item | Evidence | Score |
|---|---|---|
| Hands-on design/impl/debug/integration/testing | `app/src/safety_monitor.c`, `app/src/can_broadcaster.c`, `app/src/resource_monitor.c`, Ztest suites in `tests/lib/safety_monitor` and `tests/drivers/can_broadcaster`, `.github/workflows/build.yml`, `.github/workflows/static-analysis.yml` | 92% |
| Core firmware & device drivers for automotive compute subsystems | CAN state broadcaster (`app/src/can_broadcaster.c`) using Zephyr's built-in CAN API, tested over a loopback controller (`tests/drivers/can_broadcaster`); `third_party/libcanard` submodule referenced as the higher-layer DroneCAN/Cyphal protocol this transport could carry. Not yet wired into a real board's devicetree (tracked in `ROADMAP.md`) | 80% |
| C / Assembly / Yocto | Strong C; real inline-assembly IRQ-mask reads for Cortex-M (PRIMASK), Cortex-R (CPSR), and Cortex-A (DAIF) in `app/src/resource_monitor.c`; illustrative (not bitbake-verified) Yocto layer at `yocto/meta-safety-monitor/` | 68% |
| Analyze/optimize CPU/GPU/I-O/memory usage | `resource_monitor_start()` periodically runs Zephyr's Thread Analyzer (CPU/stack usage) plus the IRQ-mask read; GPU profiling is out of scope for this MCU-class app (documented, not fabricated) | 78% |
| Plan/prioritize work packages | `ROADMAP.md` with Done/Next/Later, backed by `.github/ISSUE_TEMPLATE/firmware-exercise.yml` and `.github/PULL_REQUEST_TEMPLATE.md` | 85% |
| Tech leadership & mentoring | `doc/adr/0001-safety-monitor-state-machine.md`, `CONTRIBUTING.md`, README interview-practice track | 70% |

Bucket average: **≈79%**

### 2. Required Skills and Experience (40%)

| JD item | Evidence | Score |
|---|---|---|
| 10+ yrs bare-metal/kernel-level recent coding (proxy: depth of driver/system work) | Driver + policy separation + CAN transport + resource profiling + cross-arch test matrix | 85% |
| Strong C and Assembly | Real inline assembly for 3 Arm profiles in `app/src/resource_monitor.c` (verify exact Kconfig guards against your pinned Zephyr revision) | 74% |
| Proven driver/system-component contribution | Out-of-tree GPIO driver, CAN broadcaster, custom board, devicetree bindings, library | 88% |
| Arm architectures: Cortex-M, Cortex-R, Cortex-A + SoCs | `tests/lib/safety_monitor/testcase.yaml` runs the pure-C policy on `qemu_cortex_m3`, `qemu_cortex_r5`, `qemu_cortex_a53`, and `native_sim`; `resource_monitor.c` has real per-profile assembly paths | 83% |
| Linux experience (use/deploy/develop) | `native_sim` tests run as native Linux processes (both Ztest suites); `scripts/parse_test_results.py` is a Linux-CI Python tool; Yocto companion-Linux-image skeleton | 65% |
| Communication/documentation | README, CONTRIBUTING, `ROADMAP.md`, `doc/adr/`, `doc/project.rst`, both SKILL.md files | 92% |

Bucket average: **≈81%**

### 3. Nice to Have (25%)

| JD item | Evidence | Score |
|---|---|---|
| C++/Rust | None | 0% |
| Python/Bash | Bash scripts (`scripts/build_local_via_install.sh`) plus a new Python tool (`scripts/parse_test_results.py`) | 65% |
| Zephyr RTOS | Core of the whole project | 100% |
| TF-A/TF-M/U-Boot/Xen/SOAFEE/ROS/Autoware | `libcanard` submodule (DroneCAN/Cyphal, robotics-adjacent) plus the Yocto companion-image note; TF-A/TF-M/U-Boot/Xen/ROS/Autoware still only named, not implemented | 25% |
| Automotive safety-domain/standards (ISO 26262, ASIL, MISRA) | Safety state machine + `doc/adr/0001...`; cppcheck static-analysis CI gate as a lightweight code-quality control; no explicit ISO 26262/ASIL/MISRA mapping doc yet | 40% |
| Mentoring experience | Interview practice track, ADR, ROADMAP, CONTRIBUTING | 45% |

Bucket average: **≈46%**

### Overall Score

$$0.35 \times 79\% + 0.40 \times 81\% + 0.25 \times 46\% \approx 68\%$$

**Responsibilities ≈79%, Required Skills ≈81% — both at or near the 80%
target set for this pass.** Nice to Have remains the lowest bucket (~46%)
since it spans domains (C++/Rust, TF-A/TF-M/U-Boot/Xen, deep safety-standard
compliance) that are intentionally out of scope for a single Zephyr repo
without further, larger additions.

## Root Cause of Any Remaining Gap

The two buckets the user asked to prioritize (Responsibilities, Required
Skills) are now at/near target through real, reviewable additions: a CAN
automotive-bus driver + test, cross-architecture (Cortex-M/R/A) coverage of
the policy module, real per-profile inline assembly, Thread Analyzer-based
resource reporting, a static-analysis CI gate, and planning/leadership
artifacts (ROADMAP, ADR). What's left to close fully:

- Real board-level CAN devicetree overlay + pin mapping (validated on
  hardware or at least full `west build`), not just native_sim loopback.
- Actual `bitbake` build of the Yocto layer (not possible in this sandbox).
- Deeper mentoring evidence (e.g. a recorded design review or onboarding
  guide) beyond the ADR/ROADMAP/CONTRIBUTING trio.

## Prioritized Gap-Closers (ranked by score-per-effort)

1. **Real board CAN overlay** — port `can_broadcaster` onto `custom_plank` or
   `nucleo_f302r8` with actual pin/controller devicetree nodes.
2. **MISRA/ISO 26262 mapping doc** — a short note tying `safety_monitor`'s
   design to specific MISRA C rules and ASIL concepts.
3. **TF-M exploration** — secure/non-secure partitioning note or PoC on an
   nRF5340-class board (nice-to-have bucket).
4. **C++/Rust port** — reimplement `safety_monitor` in Rust or C++ as a
   comparison exercise (nice-to-have bucket).
5. **Onboarding/mentoring guide** — a short "day-1" doc for a new contributor
   walking through the architecture and review expectations.

## How to Use This Skill

- Before adding a new feature, check whether it maps to an unscored or
  low-scoring JD item above and prefer that work first.
- After merging a gap-closer, update the relevant score/evidence row and
  recompute the bucket and overall averages in this file.
- Keep this file and `arm-staff-firmware-jd` in sync — this file scores
  against that one; don't duplicate the JD text here.
