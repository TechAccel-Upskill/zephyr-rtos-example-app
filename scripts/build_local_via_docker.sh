#!/usr/bin/env bash
set -euo pipefail

# All-in-One Zephyr RTOS Build Script via Docker
#
# Builds using the same devcontainer image used for local VS Code Dev
# Containers/Codespaces and published by .github/workflows/devcontainer-image.yml
# (built from .devcontainer/Dockerfile), so local and CI builds share
# identical tool versions.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print() { echo -e "${GREEN}$1${NC}"; }
print_step() { echo -e "${YELLOW}→ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed on the host. See https://github.com/zephyrproject-rtos for guidance.${NC}"
    exit 1
fi

# Same image published by devcontainer-image.yml; allow override with env var
IMAGE="${ZEPHYR_BUILD_IMAGE:-ghcr.io/techaccel-upskill/zephyr-rtos-example-app-devcontainer:latest}"

print "Starting Docker build using image: $IMAGE"

# Ensure the image is available locally; pull it, or build it from the
# devcontainer Dockerfile if it hasn't been published yet.
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    print_step "Image $IMAGE not found locally — pulling..."
    if ! docker pull "$IMAGE"; then
        print_step "Pull failed; building image locally from .devcontainer/Dockerfile"
        docker build -t "$IMAGE" -f "$REPO_ROOT/.devcontainer/Dockerfile" "$REPO_ROOT"
    fi
fi

docker run --rm -t \
    -v "$REPO_ROOT:/workspaces/zephyr-rtos-example-app" \
    -w /workspaces/zephyr-rtos-example-app \
    "$IMAGE" bash -lc '
set -euo pipefail

if [ ! -d .west ]; then
    if west topdir &> /dev/null; then
        echo "West workspace already initialized at $(west topdir)"
    else
        west init -l .
    fi
fi

echo "Fetching Zephyr and project dependencies via west update..."
west update
pip install --break-system-packages -q -r "$(west topdir)/zephyr/scripts/requirements.txt"

echo "Building firmware with west twister (app)..."
west twister -T app -v --inline-logs --integration --outdir build
'

# After container run, fix ownership of generated files
print_step "Restoring file ownership to host user"
sudo chown -R "$(id -u):$(id -g)" "$REPO_ROOT" || true

print "Done. Build artifacts (if any) are in build/ in the repository root."
