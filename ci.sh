#!/usr/bin/env bash
set -euo pipefail

# Determine repository root (directory of this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Allow overrides via env vars
BUILD_DIR="${BUILD_DIR:-build}"
CONFIG="${CONFIG:-Release}"

printf "[ci] Build directory: %s\n" "$BUILD_DIR"
printf "[ci] Configuration:   %s\n" "$CONFIG"

# 1) Create build directory
mkdir -p "$BUILD_DIR"

# 2) Change into build directory
cd "$BUILD_DIR"

# 3) Configure project with CMake
cmake -DCMAKE_BUILD_TYPE="$CONFIG" ..

# 4) Build the project
# Try to parallelize based on available CPU cores
CORES=4
if command -v nproc >/dev/null 2>&1; then
  CORES="$(nproc)"
elif command -v getconf >/dev/null 2>&1; then
  CORES="$(getconf _NPROCESSORS_ONLN)"
elif command -v sysctl >/dev/null 2>&1; then
  CORES="$(sysctl -n hw.ncpu)"
fi

cmake --build . --config "$CONFIG" -- -j"$CORES"

printf "[ci] Build completed successfully.\n"