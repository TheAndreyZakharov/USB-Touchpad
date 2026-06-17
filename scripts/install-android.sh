#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android-app"

if ! command -v adb >/dev/null 2>&1; then
    echo "Error: adb is not installed or is not available in PATH."
    exit 1
fi

if [ ! -x "$ANDROID_DIR/gradlew" ]; then
    echo "Error: Gradle wrapper was not found."
    exit 1
fi

DEVICE_COUNT="$(
    adb devices |
    awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }'
)"

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: no authorized Android device is connected."
    echo
    adb devices -l
    exit 1
fi

if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo "Error: more than one Android device is connected."
    echo "Set ANDROID_SERIAL before running this script."
    echo
    adb devices -l
    exit 1
fi

echo "Building and installing Android application..."

cd "$ANDROID_DIR"
./gradlew installDebug

echo
echo "Android application installed successfully."