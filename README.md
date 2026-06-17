# USB Touchpad

USB Touchpad turns an old Android tablet into a wired touchpad for macOS.

The project consists of two applications stored in one repository:

- an Android application that captures touch input;
- a macOS application that receives touch events and controls the cursor.

The Android tablet connects to the Mac through USB. Android Debug Bridge provides the transport channel, so Wi-Fi and Bluetooth are not required.

## Target devices

Development environment:

- MacBook Air with Apple Silicon;
- macOS;
- 3Q Surf RC9716B-DG tablet;
- Android 4.x;
- USB debugging enabled.

## Repository structure

    USB-Touchpad/
    ├── android-app/
    │   └── Android touch input application
    ├── macos-app/
    │   └── macOS cursor control application
    ├── protocol/
    │   └── Communication protocol specification
    ├── docs/
    │   └── Architecture and development documentation
    ├── scripts/
    │   └── Build, installation, and environment scripts
    └── .vscode/
        └── VS Code workspace configuration

## Planned features

Initial version:

1. Move the cursor with one finger.
2. Perform a left click with a short tap.
3. Scroll vertically with two fingers.
4. Connect through USB using ADB port forwarding.
5. Automatically reconnect after the tablet is disconnected.
6. Adjust pointer sensitivity on the Mac.

Possible future features:

- right click with a two-finger tap;
- double click;
- drag and drop;
- horizontal scrolling;
- inertial scrolling;
- three-finger gestures;
- automatic Android application launch;
- macOS menu bar application;
- remote display mode.

## Communication flow

    Android touch events
            ↓
    Android TCP server
            ↓
    ADB USB port forwarding
            ↓
    macOS TCP client
            ↓
    macOS Core Graphics events
            ↓
    Cursor, clicks, and scrolling

## Development tools

Android application:

- Java;
- Android SDK;
- Gradle;
- minimum Android API compatible with the tablet.

macOS application:

- Swift;
- Swift Package Manager;
- SwiftUI or AppKit;
- Core Graphics;
- Network framework.

Common tools:

- Visual Studio Code;
- Git;
- ADB;
- Xcode toolchain.

## Environment check

From the repository root, run:

    ./scripts/check-environment.sh

The script checks the required development tools and lists connected Android devices.

## Build Android application

From the repository root:

    cd android-app
    ./gradlew assembleDebug

The generated APK will be located under:

    android-app/app/build/outputs/apk/debug/

## Install Android application

Connect the tablet through USB and run:

    ./scripts/install-android.sh

## Build and run macOS application

From the repository root:

    ./scripts/run-macos.sh

The macOS application will require Accessibility permission before it can control the cursor.

The permission is located in:

    System Settings
    Privacy & Security
    Accessibility

## Current development status

- repository initialized;
- Android SDK installed;
- Gradle wrapper configured;
- ADB connection with the tablet verified;
- Swift toolchain installed;
- Xcode installed;
- VS Code extensions installed;
- application source structure created.

The next development stage is implementing the macOS application.