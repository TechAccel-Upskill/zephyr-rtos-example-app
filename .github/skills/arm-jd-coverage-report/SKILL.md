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

## Current Snapshot (2026-08-15)

### 1. Responsibilities (35%)

| JD item | Evidence | Score |
|---|---|---|
| Hands-on design/impl/debug/integration/testing | `app/src/safety_monitor.c`, `app/src/main.c`, `tests/lib/safety_monitor/src/main.c`, `.github/workflows/build.yml` | 90% |
| Core firmware & device drivers for automotive compute subsystems | `drivers/blink/gpio_led.c`, `drivers/sensor/example_sensor/example_sensor.c` — generic GPIO, not automotive-domain (no CAN/LIN, no sensor fusion, no multi-core split) | 50% |
| C / Assembly / Yocto | Strong C; no assembly; no Yocto (west/Zephyr repo, not a Linux BSP) | 20% |
| Analyze/optimize CPU/GPU/I-O/memory usage | Mentioned only as a README exercise bullet; nothing implemented | 10% |
| Plan/prioritize work packages | `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/firmware-exercise.yml`; no roadmap/backlog artifact | 50% |
| Tech leadership & mentoring | `CONTRIBUTING.md`, README interview-practice track; no design-review/ADR/onboarding artifact | 45% |

Bucket average: **≈44%**

### 2. Required Skills and Experience (40%)

| JD item | Evidence | Score |
|---|---|---|
| 10+ yrs bare-metal/kernel-level recent coding (proxy: depth of driver/system work) | Driver + policy separation + devicetree binding show real bare-metal patterns | 70% |
| Strong C and Assembly | C only, no assembly anywhere | 35% |
| Proven driver/system-component contribution | Out-of-tree driver class, custom board (`boards/vendor/custom_plank`), bindings, library | 80% |
| Arm architectures: Cortex-M, Cortex-R, Cortex-A + SoCs | Only Cortex-M boards (nRF52840, STM32F302); no Cortex-R or Cortex-A target | 30% |
| Linux experience (use/deploy/develop) | Almost none — build scripts install Linux packages but no Linux driver/kernel/userspace code | 10% |
| Communication/documentation | README, CONTRIBUTING, Doxygen/Sphinx, `doc/project.rst`, SKILL.md files | 85% |

Bucket average: **≈52%**

### 3. Nice to Have (25%)

| JD item | Evidence | Score |
|---|---|---|
| C++/Rust | None | 0% |
| Python/Bash | Bash scripts exist (`scripts/build_local_via_install.sh`); no Python | 40% |
| Zephyr RTOS | Core of the whole project | 100% |
| TF-A/TF-M/U-Boot/Xen/SOAFEE/ROS/Autoware | Only named in prose; nothing implemented or diagrammed | 10% |
| Automotive safety-domain/standards (ISO 26262, ASIL, MISRA) | Safety-state-machine concept exists; no explicit standards mapping or static-analysis gate | 30% |
| Mentoring experience | Interview practice track + docs; no dedicated artifact | 40% |

Bucket average: **≈37%**

### Overall Score

$$0.35 \times 44\% + 0.40 \times 52\% + 0.25 \times 37\% \approx 45\%$$

**Current alignment: ~45%. Target: 80%. Gap: ~35 points.**

## Root Cause of the Gap

This repo is a pure Zephyr/Cortex-M application. The JD spans a much wider
surface — Cortex-R/A, Linux, Yocto, assembly, TF-A/TF-M, GPU/resource
profiling, and safety standards. A Zephyr-only repo structurally caps out
well below 80% unless cross-cutting artifacts are deliberately added.

## Prioritized Gap-Closers (ranked by score-per-effort)

1. **Resource/CPU/memory analysis** — `CONFIG_THREAD_RUNTIME_STATS` /
   stack-usage reporting + a short profiling doc.
2. **Cortex-R / Cortex-A exposure** — add `qemu_cortex_r5` and
   `qemu_cortex_a53` build targets/overlays alongside existing Cortex-M
   boards.
3. **Assembly snippet** — small inline-asm or naked-function example (e.g.
   critical-section/register access) with a one-line rationale comment.
4. **MISRA-style static analysis gate** — `cppcheck`/`clang-tidy` CI step +
   a short safety-coding-standards note (ISO 26262/MISRA).
5. **Yocto/TF-M architecture note (+ minimal skeleton)** — doc describing the
   companion-core pattern (Cortex-A/Yocto Linux host + Cortex-M/Zephyr
   safety firmware), with an illustrative meta-layer/recipe skeleton.
6. **Python tooling** — small Python log/telemetry parser for CI or
   diagnostics output.
7. **Roadmap + ADRs** — prioritized backlog and 1–2 architecture decision
   records.

Implementing items 1–4 and 7 is expected to reach **~75–80%**; adding 5–6
should comfortably clear 80%.

## How to Use This Skill

- Before adding a new feature, check whether it maps to an unscored or
  low-scoring JD item above and prefer that work first.
- After merging a gap-closer, update the relevant score/evidence row and
  recompute the bucket and overall averages in this file.
- Keep this file and `arm-staff-firmware-jd` in sync — this file scores
  against that one; don't duplicate the JD text here.
