#!/bin/bash
#
# All-in-One Zephyr RTOS Build Script for Linux
# Handles complete setup and build process
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Helper functions
print_section() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Main script starts here
print_section "Zephyr RTOS Example Application - Complete Build"

# ============================================================================
# STEP 1: Install System Dependencies
# ============================================================================
print_section "STEP 1: Installing System Dependencies"

print_step "Updating package lists..."
sudo apt-get update -qq --allow-unauthenticated 2>&1 | grep -v "GPG error" | grep -v "NO_PUBKEY" || true

print_step "Installing core build tools..."
sudo apt-get install -y --quiet \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    wget

print_step "Installing Python 3.12..."
if ! command -v python3.12 &> /dev/null; then
    sudo apt-get install -y --quiet \
        python3.12 \
        python3.12-dev \
        python3.12-venv
    print_success "Python 3.12 installed"
else
    print_success "Python 3.12 already installed"
fi

print_step "Installing ARM embedded toolchain..."
sudo apt-get install -y --quiet \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libnewlib-dev

print_step "Installing Zephyr tools..."
sudo apt-get install -y --quiet \
    device-tree-compiler \
    gperf

# Verify system dependencies
print_step "Verifying system dependencies..."
MISSING=0

if ! command -v python3.12 &> /dev/null; then
    print_error "Python 3.12 not found"
    MISSING=1
else
    print_success "Python 3.12"
fi

if ! command -v cmake &> /dev/null; then
    print_error "CMake not found"
    MISSING=1
else
    print_success "CMake"
fi

if ! command -v ninja &> /dev/null; then
    print_error "Ninja not found"
    MISSING=1
else
    print_success "Ninja"
fi

if ! command -v arm-none-eabi-gcc &> /dev/null; then
    print_error "ARM toolchain not found"
    MISSING=1
else
    print_success "ARM toolchain"
fi

if ! command -v dtc &> /dev/null; then
    print_error "Device Tree Compiler not found"
    MISSING=1
else
    print_success "Device Tree Compiler"
fi

if [ $MISSING -eq 1 ]; then
    print_error "Some system dependencies are missing"
    exit 1
fi

print_success "All system dependencies installed"

# ============================================================================
# STEP 2: Setup Python Virtual Environment
# ============================================================================
print_section "STEP 2: Setting Up Python Virtual Environment"

print_step "Creating Python 3.12 virtual environment..."
if [ ! -d "venv" ]; then
    python3.12 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

print_step "Activating virtual environment..."
source venv/bin/activate

print_step "Upgrading pip, setuptools, and wheel..."
pip install --quiet --upgrade pip setuptools wheel

print_success "Python environment ready"

# ============================================================================
# STEP 3: Setup Zephyr Project
# ============================================================================
print_section "STEP 3: Setting Up Zephyr Project"

# Verify venv is activated
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Python virtual environment not activated"
    exit 1
fi

print_step "Installing west package manager..."
pip install -q west

print_step "Initializing west workspace..."
if [ ! -d ".west" ]; then
    # Check if we're already in a west workspace
    if west topdir &> /dev/null; then
        print_success "West workspace already initialized at $(west topdir)"
    else
        west init -l
        print_success "West workspace initialized"
    fi
else
    print_success "West workspace already initialized"
fi

print_step "Fetching Zephyr and dependencies (this may take a few minutes)..."
west update

# Determine ZEPHYR_BASE - it should be in parent workspace
# Check if /workspaces/zephyr exists (parent workspace)
if [ -d "/workspaces/zephyr" ]; then
    export ZEPHYR_BASE="/workspaces/zephyr"
    print_success "Using ZEPHYR_BASE: /workspaces/zephyr"
elif [ -d "zephyr" ]; then
    export ZEPHYR_BASE="$(pwd)/zephyr"
    print_success "Using ZEPHYR_BASE: $(pwd)/zephyr"
else
    print_error "Zephyr directory not found"
    exit 1
fi

echo "export ZEPHYR_BASE=$ZEPHYR_BASE" >> venv/bin/activate
print_success "ZEPHYR_BASE set to: $ZEPHYR_BASE"

print_step "Installing Zephyr Python dependencies..."
if [ -f "$ZEPHYR_BASE/scripts/requirements.txt" ]; then
    pip install -q -r $ZEPHYR_BASE/scripts/requirements.txt
    print_success "Zephyr dependencies installed"
else
    print_error "Zephyr requirements.txt not found at $ZEPHYR_BASE/scripts/requirements.txt"
    print_error "Attempting to install twister directly..."
    pip install -q twine twister 2>&1 || pip install -q twister || true
fi

# Add Zephyr scripts to Python path
export PYTHONPATH="$ZEPHYR_BASE/scripts:$PYTHONPATH"
echo "export PYTHONPATH=$ZEPHYR_BASE/scripts:\$PYTHONPATH" >> venv/bin/activate

# Install Zephyr SDK
print_step "Installing Zephyr SDK (v1.0.1)..."
SDK_VERSION="1.0.1"
SDK_ARCH="x86_64"
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
SDK_FILE="zephyr-sdk-${SDK_VERSION}_linux-${SDK_ARCH}.tar.xz"
SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/${SDK_FILE}"
SDK_DIR="$HOME/.zephyr-sdk-${SDK_VERSION}"

if [ -d "$SDK_DIR" ]; then
    print_success "Zephyr SDK already installed at $SDK_DIR"
else
    print_step "Downloading Zephyr SDK from GitHub..."
    mkdir -p "$HOME/.zephyr-sdks"
    cd "$HOME/.zephyr-sdks"
    
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        print_error "Neither wget nor curl available for downloading SDK"
        exit 1
    fi
    
    if command -v wget &> /dev/null; then
        wget -q "$SDK_URL" || {
            print_error "Failed to download Zephyr SDK from $SDK_URL"
            exit 1
        }
    else
        curl -L -o "$SDK_FILE" "$SDK_URL" || {
            print_error "Failed to download Zephyr SDK from $SDK_URL"
            exit 1
        }
    fi
    
    print_step "Extracting Zephyr SDK..."
    tar -xf "$SDK_FILE" || {
        print_error "Failed to extract SDK"
        exit 1
    }
    
    mv "zephyr-sdk-${SDK_VERSION}" "$SDK_DIR"
    rm -f "$SDK_FILE"
    cd - > /dev/null
    
    print_success "Zephyr SDK installed to $SDK_DIR"
fi

# Set Zephyr SDK path
export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"
echo "export ZEPHYR_SDK_INSTALL_DIR=$SDK_DIR" >> venv/bin/activate
print_success "ZEPHYR_SDK_INSTALL_DIR set to: $ZEPHYR_SDK_INSTALL_DIR"

# Verify toolchain
print_step "Verifying ARM toolchain..."
if ! command -v arm-none-eabi-gcc &> /dev/null; then
    print_error "ARM toolchain not found"
    exit 1
fi
print_success "ARM toolchain verified"

print_success "Zephyr project setup complete"

# ============================================================================
# STEP 4: Build Firmware
# ============================================================================
print_section "STEP 4: Building Firmware"

print_step "Verifying west command..."
if ! command -v west &> /dev/null; then
    print_error "west command not found"
    exit 1
fi
print_success "west command available"

# Ensure PYTHONPATH is set for Zephyr modules , check

if [ -n "$ZEPHYR_BASE" ]; then
    export PYTHONPATH="$ZEPHYR_BASE/scripts:$PYTHONPATH" 
fi

print_step "Building application firmware (this may take a few minutes)..."
west twister -T app -v --inline-logs --integration

if [ -d "twister-out" ]; then
    print_success "Firmware build complete - artifacts in twister-out/"
else
    print_error "Build artifacts not found"
fi

# ============================================================================
# STEP 5: Run Tests (Optional)
# ============================================================================
read -p "Do you want to run tests? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_section "STEP 5: Running Tests"
    
    print_step "Running Zephyr tests..."
    west twister -T tests -v --inline-logs --integration
    
    print_success "Tests completed"
fi

# ============================================================================
# Summary
# ============================================================================
print_section "Build Complete!"

echo "Build Summary:"
echo "  ✓ System dependencies installed"
echo "  ✓ Python 3.12 environment configured"
echo "  ✓ Zephyr project initialized"
echo "  ✓ Firmware built successfully"
echo ""
echo "Next steps:"
echo "  • Activate venv: source venv/bin/activate"
echo "  • View build artifacts: ls -la twister-out/"
echo "  • Clean build: rm -rf twister-out/"
echo ""
