#!/usr/bin/env bash
set -euo pipefail

# All-in-One Zephyr RTOS Build Script via Docker
# This mirrors the steps in build_local_via_install.sh but performs
# all installs inside a disposable Docker container every run.
# See https://github.com/zephyrproject-rtos for Docker/Zephyr docs.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print() { echo -e "${GREEN}$1${NC}"; }
print_step() { echo -e "${YELLOW}→ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed on the host. See https://github.com/zephyrproject-rtos for guidance.${NC}"
    exit 1
fi

# Use Zephyr-provided build image by default; allow override with env var
IMAGE="${ZEPHYR_BUILD_IMAGE:-zephyrprojectrtos/zephyr:latest}"

print "Starting Docker build/run using image: $IMAGE"

# Run container and perform full install each time. Mount workspace so artifacts
# and source are available. We keep caches like .zephyr-sdks in the host HOME
# directory so SDK downloads are reused if present.

# Ensure the image is available locally; try to pull if missing
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    print_step "Docker image $IMAGE not found locally — pulling..."
    if ! docker pull "$IMAGE"; then
        echo -e "${YELLOW}Failed to pull Docker image: $IMAGE${NC}"
        print_step "Falling back to ubuntu:24.04 and performing installs inside container"
        IMAGE="ubuntu:24.04"
        # ensure fallback image exists
        if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
            if ! docker pull "$IMAGE"; then
                echo -e "${RED}Failed to pull fallback Docker image: $IMAGE${NC}"
                exit 1
            fi
        fi
        DO_FULL_INSTALL=1
    else
        print_step "Pulled Docker image: $IMAGE"
    fi
fi

docker run --rm -t \
    -v "$REPO_ROOT:/workspaces/app" \
    -v "$HOME/.zephyr-sdks:$HOME/.zephyr-sdks" \
    -v "$HOME/.cache:$HOME/.cache" \
    -w /workspaces/app \
    -e IMAGE="$IMAGE" \
    -e DO_FULL_INSTALL="${DO_FULL_INSTALL:-}" \
    "$IMAGE" bash -lc '
set -euo pipefail

echo "Using prebuilt Zephyr image: $IMAGE"

if [ "${DO_FULL_INSTALL:-}" = "1" ]; then
    echo "Running full package install inside container (fallback image)."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git curl wget ca-certificates \
        python3.12 python3.12-venv python3.12-dev python3-pip python3-full \
        gcc-arm-none-eabi libnewlib-arm-none-eabi \
        device-tree-compiler gperf tar xz-utils bzip2
fi

# Ensure west exists; install via pip --user to avoid venv and PEP 668 issues
if ! command -v west &> /dev/null; then
    echo "west not found; installing via pip3.12 --user..."
    if command -v pip3.12 &> /dev/null; then
        echo "Installing west to user home directory..."
        pip3.12 install --user --upgrade pip setuptools wheel 2>&1 | tail -1 || true
        pip3.12 install --user -q west || {
            echo "Failed; retrying with --break-system-packages..."
            pip3.12 install --user --break-system-packages -q west || true
        }
        # Ensure ~/.local/bin is in PATH
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "Error: pip3.12 not found"
        exit 1
    fi
fi

if [ ! -d .west ]; then
    if west topdir &> /dev/null; then
        echo "West workspace already initialized at $(west topdir)"
    else
        west init -l
    fi
fi

# Only update and clone if using fallback image; official Zephyr image has it pre-installed
if [ "${DO_FULL_INSTALL:-}" = "1" ]; then
    echo "Fetching Zephyr and project dependencies via west update..."
    west update || true
fi

# Determine ZEPHYR_BASE. Prefer pre-installed Zephyr in official image, then mounted, then local, then clone
if [ -d "/opt/zephyr" ]; then
    export ZEPHYR_BASE="/opt/zephyr"
    echo "Using ZEPHYR_BASE from official image: /opt/zephyr"
elif [ -d "/workspaces/zephyr" ]; then
    export ZEPHYR_BASE="/workspaces/zephyr"
    echo "Using ZEPHYR_BASE from mounted volume: /workspaces/zephyr"
elif [ -d "zephyr" ]; then
    export ZEPHYR_BASE="$(pwd)/zephyr"
    echo "Using ZEPHYR_BASE from local: $(pwd)/zephyr"
else
    echo "Zephyr source not found; cloning from GitHub into /workspaces/zephyr"
    git clone --depth=1 https://github.com/zephyrproject-rtos/zephyr.git /workspaces/zephyr || true
    export ZEPHYR_BASE="/workspaces/zephyr"
fi
export PYTHONPATH="${ZEPHYR_BASE}/scripts:${PYTHONPATH:-}"

if [ -f "$ZEPHYR_BASE/scripts/requirements.txt" ]; then
    if command -v python3 &> /dev/null; then
        pip3.12 install -q -r "$ZEPHYR_BASE/scripts/requirements.txt" || true
    fi
fi

echo "Building firmware with west twister (app)..."
west twister -T app -v --inline-logs --integration || true

echo "Docker container build finished"
'

# After container run, fix ownership of generated files
print_step "Restoring file ownership to host user"
sudo chown -R "$(id -u):$(id -g)" "$REPO_ROOT" || true

print "Done. Build artifacts (if any) are in twister-out/ in the repository root."
