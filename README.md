# Zephyr Safety Monitor Node

<a href="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/build.yml?query=branch%3Amain">
  <img src="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/build.yml/badge.svg?event=push">
</a>
<a href="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/docs.yml?query=branch%3Amain">
  <img src="https://github.com/TechAccel-Upskill/zephyr-rtos-example-app/actions/workflows/docs.yml/badge.svg?event=push">
</a>
<a href="https://techaccel-upskill.github.io/zephyr-rtos-example-app">
  <img alt="Documentation" src="https://img.shields.io/badge/documentation-3D578C?logo=sphinx&logoColor=white">
</a>
<a href="https://techaccel-upskill.github.io/zephyr-rtos-example-app/doxygen">
  <img alt="API Documentation" src="https://img.shields.io/badge/API-documentation-3D578C?logo=c&logoColor=white">
</a>

This repository is a hands-on firmware project for preparing for senior and
staff-level embedded systems interviews. It models a small safety monitor for
an autonomous vehicle or robot: a GPIO-backed proximity input is sampled,
classified by a deterministic safety state machine, and exposed through a
status LED.

The project deliberately keeps policy separate from hardware. That makes the
decision logic testable on a host while the Zephyr application exercises
devicetree, Kconfig, a custom driver class, logging, and board integration.

## What This Project Demonstrates

- Safety-oriented state transitions: NORMAL, WARNING, EMERGENCY, and FAULT
- Consecutive-sample filtering and explicit sensor fault handling
- A pure C policy module covered by a native Ztest suite
- A GPIO sensor driver with error propagation and channel validation
- An out-of-tree blink driver class with a device API
- Devicetree bindings and a custom board
- Kconfig-controlled timing and fault thresholds
- Twister build/test integration for application and unit-test targets
- GitHub Actions build, documentation, and static-analysis (cppcheck) workflows
- Periodic CPU/stack resource reporting (Zephyr Thread Analyzer) plus a real
  Cortex-M/R/A inline-assembly IRQ-mask read
- A CAN automotive-bus state broadcaster with a native_sim loopback Ztest
- A pure-C policy test matrix across Cortex-M, Cortex-R, and Cortex-A (QEMU)
  and native Linux (native_sim)
- A `libcanard` git submodule (DroneCAN/Cyphal) as a reference higher-layer
  automotive/robotics protocol stack for the CAN transport
- A Yocto companion-image layer skeleton illustrating a Cortex-A/Linux host
  paired with this Cortex-M/R Zephyr safety core
- `ROADMAP.md` and `doc/adr/` for work-package planning and design records

The original repository structure is retained as a learning reference for:

- Basic [Zephyr application][app_dev] skeleton
- [Zephyr workspace applications][workspace_app]
- [Zephyr modules][modules]
- [West T2 topology][west_t2]
- [Custom boards][board_porting]
- Custom [devicetree bindings][bindings]
- Out-of-tree [drivers][drivers]
- Out-of-tree libraries
- Example CI configuration (using GitHub Actions)
- Custom [west extension][west_ext]
- Custom [Zephyr runner][runner_ext]
- Doxygen and Sphinx documentation boilerplate

## Architecture

```text
GPIO proximity input
  |
  v
example_sensor driver ---> sensor_sample_fetch/channel_get
  |
  v
safety_monitor (pure C policy) ---> state transition + fault decision
  |
  v
blink driver class ---> GPIO status indicator
```

The monitor enters WARNING after `CONFIG_APP_WARNING_SAMPLES` consecutive
hazard samples, EMERGENCY after `CONFIG_APP_EMERGENCY_SAMPLES`, and FAULT after
`CONFIG_APP_FAULT_SAMPLES` invalid samples. A valid clear sample returns the
system to NORMAL. These are intentionally simple interview-sized policies that
can later be extended with timestamps, watchdog supervision, CAN input, or a
multi-sensor voting strategy.

`app/src/resource_monitor.c` periodically logs per-thread CPU/stack usage via
Zephyr's Thread Analyzer and reads the current IRQ-mask state using inline
assembly (Cortex-M PRIMASK, with real Cortex-R CPSR and Cortex-A DAIF paths
guarded by Kconfig). `app/src/can_broadcaster.c` sends the safety state as a
CAN frame using Zephyr's built-in CAN API; it is exercised on `native_sim`
over a CAN loopback controller in `tests/drivers/can_broadcaster` rather than
wired into the default board build, since the current boards have no CAN
devicetree node yet (tracked in `ROADMAP.md`).

### Cloning with Submodules

This repository references `libcanard` (a DroneCAN/Cyphal reference
implementation) as a git submodule under `third_party/libcanard`. Clone with:

```shell
git clone --recurse-submodules <repo-url>
# or, if already cloned:
git submodule update --init --recursive
```

## Interview Practice Track

1. Explain the device initialization order and the devicetree-to-driver path.
2. Add hysteresis or a time-based debounce without blocking the sensor thread.
3. Add a watchdog and define the behavior when the monitor thread stalls.
4. Replace the GPIO sensor with an I2C sensor while preserving the policy API.
5. Add a second sensor and implement disagreement detection and degraded mode.
6. Measure stack, CPU, and memory usage; document the result and tradeoffs.
7. Review the code for concurrency, integer overflow, initialization failures,
   and fail-safe output behavior.
8. Port the application to another Arm Cortex-M board and add its overlay.
9. Write a design note covering safety assumptions, diagnostics, and recovery.

These exercises map to the Arm role's driver development, low-level debugging,
resource analysis, testing, documentation, and technical leadership themes.

This repository is versioned together with the [Zephyr main tree][zephyr]. This
means that every time that Zephyr is tagged, this repository is tagged as well
with the same version number, and the [manifest](west.yml) entry for `zephyr`
will point to the corresponding Zephyr tag. For example, the `example-application`
v2.6.0 will point to Zephyr v2.6.0. Note that the `main` branch always
points to the development branch of Zephyr, also `main`.

[app_dev]: https://docs.zephyrproject.org/latest/develop/application/index.html
[workspace_app]: https://docs.zephyrproject.org/latest/develop/application/index.html#zephyr-workspace-app
[modules]: https://docs.zephyrproject.org/latest/develop/modules.html
[west_t2]: https://docs.zephyrproject.org/latest/develop/west/workspaces.html#west-t2
[board_porting]: https://docs.zephyrproject.org/latest/guides/porting/board_porting.html
[bindings]: https://docs.zephyrproject.org/latest/guides/dts/bindings.html
[drivers]: https://docs.zephyrproject.org/latest/reference/drivers/index.html
[zephyr]: https://github.com/zephyrproject-rtos/zephyr
[west_ext]: https://docs.zephyrproject.org/latest/develop/west/extensions.html
[runner_ext]: https://docs.zephyrproject.org/latest/develop/modules.html#external-runners

## Getting Started

Before getting started, make sure you have a proper Zephyr development
environment. Follow the official
[Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/getting_started/index.html).

### Initialization

The first step is to initialize the workspace folder (``my-workspace``) where
the ``example-application`` and all Zephyr modules will be cloned. Run the following
command:

```shell
# initialize my-workspace for the example-application (main branch)
west init -m https://github.com/zephyrproject-rtos/example-application --mr main my-workspace
# update Zephyr modules
cd my-workspace
west update
```

### Building and running

To build the application, run the following command:

```shell
cd example-application
west build -b $BOARD app
```

where `$BOARD` is the target board.

You can use the `custom_plank` board found in this
repository. Note that Zephyr sample boards may be used if an
appropriate overlay is provided (see `app/boards`).

A sample debug configuration is also provided. To apply it, run the following
command:

```shell
west build -b $BOARD app -- -DEXTRA_CONF_FILE=debug.conf
```

Once you have built the application, run the following command to flash it:

```shell
west flash
```

### Building with Docker

A [Dev Container](.devcontainer/) defines the toolchain (build tools, west,
Zephyr SDK arm-zephyr-eabi toolchain, cppcheck, doxygen, Sphinx) used both for
local development (VS Code Dev Containers / GitHub Codespaces) and for
GitHub Actions CI. The image is built from `.devcontainer/Dockerfile` and
published by `.github/workflows/devcontainer-image.yml`, so `build.yml`,
`static-analysis.yml` and `docs.yml` all run inside the exact same image.

To open this repository in the dev container, use VS Code's "Reopen in
Container" command (requires Docker/the Dev Containers extension).

If you prefer a one-shot script instead of opening the dev container, a
helper is provided at `scripts/build_local_via_docker.sh`. It pulls the same
published image (building it locally from `.devcontainer/Dockerfile` as a
fallback), then runs `west update` and `west twister -T app` inside it.

- **Requirements:** Docker installed on the host.
- **Default image:** `ghcr.io/techaccel-upskill/zephyr-rtos-example-app-devcontainer:latest`.
  Override with the `ZEPHYR_BUILD_IMAGE` environment variable.

Run with:

```shell
bash scripts/build_local_via_docker.sh
```

To use a locally built image instead:

```shell
ZEPHYR_BUILD_IMAGE=my-local-tag bash scripts/build_local_via_docker.sh
```

The script mounts the repository into the container so build artifacts are
available on the host afterwards.

### Building via local install script

If you want the helper script to install the toolchain and dependencies
directly on the host (recommended for development when you control the
machine), use `scripts/build_local_via_install.sh`. The script performs the
following actions:

- Installs system packages (build-essential, CMake, Ninja, ARM toolchain,
  device-tree-compiler, etc.) via `apt`.
- Ensures Python 3.12 is available and creates a `venv` in the repository.
- Installs `west`, initializes a local west workspace, and runs `west update`.
- Installs Zephyr Python requirements and the Zephyr SDK (default v0.17.4)
  under `$HOME/.zephyr-sdk-0.17.4`.
- Runs `west twister -T app` to build the application and places artifacts in
  `twister-out/`.

Run with:

```shell
bash scripts/build_local_via_install.sh
```

After the script finishes:

- Activate the created virtualenv: `source venv/bin/activate`.
- The script exports `ZEPHYR_BASE` into the virtualenv activation script so
  the environment is ready when you `source` it.

Notes:

- The script requires `sudo` to install system packages on Debian/Ubuntu.
- The script is idempotent and skips re-installing components that are
  already present.

### Testing

To execute Twister integration tests, run the following command:

```shell
west twister -T tests --integration
```

### Documentation

A minimal documentation setup is provided for Doxygen and Sphinx. To build the
documentation first change to the ``doc`` folder:

```shell
cd doc
```

Before continuing, check if you have Doxygen installed. It is recommended to
use the same Doxygen version used in [CI](.github/workflows/docs.yml). To
install Sphinx, make sure you have a Python installation in place and run:

```shell
pip install -r requirements.txt
```

API documentation (Doxygen) can be built using the following command:

```shell
doxygen
```

The output will be stored in the ``_build_doxygen`` folder. Similarly, the
Sphinx documentation (HTML) can be built using the following command:

```shell
make html
```

The output will be stored in the ``_build_sphinx`` folder. You may check for
other output formats other than HTML by running ``make help``.
