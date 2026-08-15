# Roadmap / Work Packages

Prioritized backlog mapped to the Arm Staff Firmware Developer JD (see
[.github/skills/arm-staff-firmware-jd/SKILL.md](.github/skills/arm-staff-firmware-jd/SKILL.md)
and
[.github/skills/arm-jd-coverage-report/SKILL.md](.github/skills/arm-jd-coverage-report/SKILL.md)).

## Done

- [x] Safety monitor state machine + Ztest coverage
- [x] GPIO sensor/blink drivers with explicit error propagation
- [x] Periodic CPU/stack resource reporting (Thread Analyzer + PRIMASK read)
- [x] CAN automotive-bus state broadcaster + native_sim loopback test
- [x] Cross-architecture pure-C test matrix (Cortex-M/R/A via QEMU, native_sim)
- [x] Static analysis CI gate (cppcheck)
- [x] Yocto companion-image layer skeleton (illustrative)

## Next

- [ ] Real board CAN devicetree overlay (custom_plank / nucleo_f302r8)
- [ ] Second sensor + voting/disagreement detection
- [ ] Watchdog supervision of the monitor thread
- [ ] TF-M secure/non-secure partition exploration on an nRF5340-class board
- [ ] Yocto companion-image build validation (bitbake, outside this sandbox)

## Later / Stretch

- [ ] Rust or C++ policy module port for comparison
- [ ] ROS 2 bridge for the safety state topic
