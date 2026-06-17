#!/usr/bin/env bash

set -u

print_command_status() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
        printf "OK      %-14s %s\n" \
            "$command_name" \
            "$(command -v "$command_name")"
    else
        printf "MISSING %-14s\n" "$command_name"
    fi
}

echo "USB Touchpad environment check"
echo

echo "System:"
uname -m
sw_vers
echo

echo "Commands:"
print_command_status git
print_command_status code
print_command_status xcodebuild
print_command_status swift
print_command_status java
print_command_status gradle
print_command_status adb
print_command_status sdkmanager
echo

echo "Versions:"

git --version 2>/dev/null || true
code --version 2>/dev/null | head -n 1 || true
xcodebuild -version 2>/dev/null || true
swift --version 2>/dev/null | head -n 1 || true
java -version 2>&1 | head -n 1 || true
gradle --version 2>/dev/null | grep '^Gradle ' | head -n 1 || true
adb version 2>/dev/null | head -n 2 || true
sdkmanager --version 2>/dev/null || true
echo

echo "Environment variables:"
echo "ANDROID_HOME=${ANDROID_HOME:-not set}"
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-not set}"
echo "ADB_LIBUSB=${ADB_LIBUSB:-not set}"
echo

echo "Android SDK packages:"

if command -v sdkmanager >/dev/null 2>&1; then
    sdkmanager \
        --sdk_root="${ANDROID_HOME:-$HOME/Library/Android/sdk}" \
        --list_installed 2>/dev/null || true
else
    echo "sdkmanager is not installed."
fi

echo
echo "Connected Android devices:"

if command -v adb >/dev/null 2>&1; then
    adb start-server >/dev/null 2>&1 || true
    adb devices -l
else
    echo "ADB is not installed."
fi