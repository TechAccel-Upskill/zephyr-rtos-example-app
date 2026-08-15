# Shared toolchain image for local development (VS Code Dev Containers /
# GitHub Codespaces) and GitHub Actions CI, so both environments build with
# identical tool versions. See ../README.md for usage.
FROM ubuntu:24.04

ARG ZEPHYR_SDK_VERSION=0.17.4
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk \
    PATH="/root/.local/bin:${PATH}"

# Core build tools, Zephyr build deps, static-analysis and docs toolchain —
# these cover everything used by build.yml, static-analysis.yml and docs.yml.
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git curl wget ca-certificates xz-utils \
        python3.12 python3.12-venv python3.12-dev python3-pip \
        device-tree-compiler gperf ccache \
        cppcheck doxygen \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

RUN pip3 install --break-system-packages --no-cache-dir --upgrade pip setuptools wheel \
    && pip3 install --break-system-packages --no-cache-dir west Sphinx

# Minimal Zephyr SDK with only the arm-zephyr-eabi toolchain, matching the
# "toolchains: arm-zephyr-eabi" used by the CI build workflow.
RUN arch="$(uname -m)" \
    && case "$arch" in \
         x86_64) sdk_arch=x86_64 ;; \
         aarch64) sdk_arch=aarch64 ;; \
         *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL -o /tmp/zephyr-sdk-minimal.tar.xz \
        "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${sdk_arch}_minimal.tar.xz" \
    && mkdir -p "${ZEPHYR_SDK_INSTALL_DIR}" \
    && tar -xf /tmp/zephyr-sdk-minimal.tar.xz -C "${ZEPHYR_SDK_INSTALL_DIR}" --strip-components=1 \
    && rm -f /tmp/zephyr-sdk-minimal.tar.xz \
    && "${ZEPHYR_SDK_INSTALL_DIR}/setup.sh" -t arm-zephyr-eabi -h -c

WORKDIR /workspaces/zephyr-rtos-example-app
