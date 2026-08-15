#!/usr/bin/env bash
# Copyright (c) 2024 TechAccel Upskill
# SPDX-License-Identifier: Apache-2.0
#
# build_tfa.sh — Build Trusted Firmware-A (TF-A) BL31 and BL2 for the
#                target platform and place the output FIPs next to the
#                Zephyr binary.
#
# Usage:
#   bash scripts/build_tfa.sh [PLATFORM] [ARCH]
#
# Arguments:
#   PLATFORM  TF-A PLAT value (default: fvp_base_revc_2xaemv8a)
#   ARCH      ARM architecture flavour: aarch64 | aarch32 (default: aarch64)
#
# Environment:
#   TFA_DIR   Path to the TF-A source tree (default: ../tfa relative to
#             the west workspace root, i.e. the directory produced by
#             'west update').
#   CROSS_COMPILE  Cross-compiler prefix (default: aarch64-linux-gnu-)
#
# Output:
#   tfa-build/<PLATFORM>/release/  — BL1/BL2/BL31 ELF and binary artefacts
#   tfa-build/bl31.bin             — copy of BL31 binary for easy reference

set -euo pipefail

PLATFORM="${1:-fvp_base_revc_2xaemv8a}"
ARCH="${2:-aarch64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# West workspaces place modules one level above the application repo.
TFA_DIR="${TFA_DIR:-${REPO_ROOT}/../tfa}"
OUTPUT_DIR="${REPO_ROOT}/tfa-build"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"

if [[ ! -d "${TFA_DIR}" ]]; then
    echo "ERROR: TF-A source tree not found at '${TFA_DIR}'."
    echo "       Run 'west update' first, or set TFA_DIR explicitly."
    exit 1
fi

echo "=== Building TF-A ==="
echo "  Platform      : ${PLATFORM}"
echo "  Architecture  : ${ARCH}"
echo "  TFA source    : ${TFA_DIR}"
echo "  Output        : ${OUTPUT_DIR}/${PLATFORM}/release"
echo "  Cross compiler: ${CROSS_COMPILE}"
echo ""

make -C "${TFA_DIR}" \
    PLAT="${PLATFORM}" \
    ARCH="${ARCH}" \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    DEBUG=0 \
    LOG_LEVEL=20 \
    BL33="${REPO_ROOT}/build/zephyr/zephyr.bin" \
    all fip \
    BUILD_BASE="${OUTPUT_DIR}"

# Stage BL31 binary for easy reference from the Zephyr CMake build
BL31_BIN="${OUTPUT_DIR}/${PLATFORM}/release/bl31.bin"
if [[ -f "${BL31_BIN}" ]]; then
    cp "${BL31_BIN}" "${OUTPUT_DIR}/bl31.bin"
    echo ""
    echo "=== TF-A build complete ==="
    echo "  BL31 binary: ${OUTPUT_DIR}/bl31.bin"
else
    echo "WARNING: bl31.bin not found at expected path '${BL31_BIN}'."
    echo "         Check BUILD_BASE and PLAT settings."
fi
