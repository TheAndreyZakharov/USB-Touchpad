#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MACOS_DIR="$ROOT_DIR/macos-app"

if ! command -v swift >/dev/null 2>&1; then
    echo "Error: Swift is not installed or is not available in PATH."
    exit 1
fi

if [ ! -f "$MACOS_DIR/Package.swift" ]; then
    echo "Error: macos-app/Package.swift was not found."
    exit 1
fi

cd "$MACOS_DIR"

echo "Building Touchpad for macOS..."
swift build

echo
echo "Starting Touchpad..."
swift run Touchpad
