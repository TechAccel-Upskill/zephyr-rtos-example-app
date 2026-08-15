---
name: arm-staff-firmware-jd
description: Reference the Arm Staff Firmware Developer job description to align this repository's Zephyr practice project (features, exercises, docs) with the role's responsibilities and required/nice-to-have skills. Use when planning, extending, or reviewing this project for interview preparation for that role.
---

# Skill: Arm Staff Firmware Developer — Job Description Reference

This repository (`zephyr-rtos-example-app`) is being evolved into an interview
preparation project for the **Staff Firmware Developer** role at **Arm**. Use
this file as the source of truth for what the role requires when deciding
what to build, test, or document next.

## About the Job

Arm is looking for a Staff Firmware Developer to help build and test the
software stack for next-generation compute subsystems in physical AI
(software-defined vehicles and robots). The role is hands-on: designing,
writing, debugging, reviewing and testing production-quality code, with deep,
recent engagement in low-level (OS kernel / bare-metal) development spanning
compute, vision, AI, and safety/security subsystems.

## Responsibilities

- Hands-on design, implementation, debugging, integration and testing of the
  software stack, with a strong focus on validating high-quality,
  production-grade code.
- Engineer core firmware and device drivers for automotive compute
  subsystems.
- Write, review and test robust, maintainable and efficient C/assembly/Yocto
  code across firmware and low-level system components.
- Analyze and optimize CPU, GPU, I/O, and memory usage across system
  components.
- Help plan and prioritize engineering work packages with project management
  and tech leadership.
- Provide technical leadership and mentoring to other team members.
- Contribute to a collaborative, inclusive, and productive team environment.

## Required Skills and Experience

- Bachelor's or Master's degree (or equivalent experience) in Computer
  Science, Electrical Engineering, or a related field.
- 10+ years hands-on embedded software experience, with recent, regular
  coding at OS kernel or bare-metal level.
- Strong C and Assembly skills with deep expertise in low-level compute
  infrastructure.
- Proven track record designing and contributing code (core features,
  drivers, or system components) in recent roles.
- Knowledge of Arm architectures (Cortex-M, Cortex-R, Cortex-A) and Arm SoCs.
- Experience using, deploying, and developing for Linux.
- Strong interpersonal/communication skills; clear written and spoken
  English; ability to write coherent documentation, influence, and build
  consensus.

## Nice to Have

- Additional systems languages: C++ and/or Rust.
- Scripting: Python and/or Bash.
- Zephyr RTOS development.
- Familiarity with TF-A, TF-M, U-Boot, Xen, SOAFEE, ROS, Autoware.
- Automotive/industrial/robotics standards, protocols, safety domain
  knowledge.
- Mentoring experience.

## How to Use This Skill in This Repository

When proposing or implementing changes to this project, map the work back to
the JD:

- **Drivers / firmware**: prefer changes in `drivers/`, `include/app/`, and
  `app/src/` that mirror real driver/state-machine design (see
  `safety_monitor.c/.h`, `example_sensor.c`, `gpio_led.c`).
- **Low-level correctness**: favor explicit error propagation, fault states,
  and Kconfig-driven tunables over hidden assumptions.
- **Resource analysis**: prefer exercises that touch CPU/memory/stack usage
  (e.g. Zephyr thread stats, `CONFIG_THREAD_MONITOR`, footprint tools) since
  the JD calls out CPU/GPU/I-O/memory optimization.
- **Testing**: extend Ztest/Twister coverage (`tests/`) for new behavior
  rather than only manual verification, to demonstrate "validating
  high-quality, production-grade code."
- **Documentation/leadership**: keep `README.md`, `CONTRIBUTING.md`, and
  `doc/project.rst` current — the JD explicitly values coherent
  documentation and mentoring/consensus-building.
- **Stretch goals** (nice-to-have alignment): note follow-up ideas involving
  Rust/C++, Python/Bash tooling, or exposure to TF-A/TF-M/U-Boot/Xen/SOAFEE
  concepts, even if not implemented in Zephyr directly.

Keep this file in sync if the JD changes; treat it as the acceptance
criteria backdrop for interview-prep exercises added to this repo.
