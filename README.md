# Zephyr Example Application

<a href="https://github.com/zephyrproject-rtos/example-application/actions/workflows/build.yml?query=branch%3Amain">
  <img src="https://github.com/zephyrproject-rtos/example-application/actions/workflows/build.yml/badge.svg?event=push">
</a>
<a href="https://github.com/zephyrproject-rtos/example-application/actions/workflows/docs.yml?query=branch%3Amain">
  <img src="https://github.com/zephyrproject-rtos/example-application/actions/workflows/docs.yml/badge.svg?event=push">
</a>
<a href="https://zephyrproject-rtos.github.io/example-application">
  <img alt="Documentation" src="https://img.shields.io/badge/documentation-3D578C?logo=sphinx&logoColor=white">
</a>
<a href="https://zephyrproject-rtos.github.io/example-application/doxygen">
  <img alt="API Documentation" src="https://img.shields.io/badge/API-documentation-3D578C?logo=c&logoColor=white">
</a>

This repository contains a Zephyr example application. The main purpose of this
repository is to serve as a reference on how to structure Zephyr-based
applications. Some of the features demonstrated in this example are:

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

If you prefer to run the full build environment in a container, a helper
script is provided at `scripts/build_local_via_docker.sh`. The script uses a
Zephyr-provided Docker image by default and will perform the workspace
initialization, `west update`, and a `west twister -T app` build inside the
container.

- **Requirements:** Docker installed on the host. See the Zephyr project for
  guidance: https://github.com/zephyrproject-rtos
- **Default image:** `zephyrprojectrtos/zephyr:latest`. Override with the
  `ZEPHYR_BUILD_IMAGE` environment variable.

Run with:

```shell
bash scripts/build_local_via_docker.sh
```

To use a specific image tag or branch:

```shell
ZEPHYR_BUILD_IMAGE=zephyrprojectrtos/zephyr:main bash scripts/build_local_via_docker.sh
```

The script mounts the repository into the container and also mounts
`$HOME/.zephyr-sdks` and `$HOME/.cache` so downloaded SDKs and caches are
reused between runs.

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
