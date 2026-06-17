# Development Guide

## Repository

Clone the repository:

    git clone https://github.com/TheAndreyZakharov/Touchpad.git
    cd Touchpad
    code .

## Project structure

    Touchpad/
    ├── android-app/
    │   └── Android touch input application and TCP server
    ├── macos-app/
    │   └── macOS menu bar application and cursor controller
    ├── assets/
    │   └── shared application artwork
    ├── protocol/
    │   └── communication protocol specification
    ├── docs/
    │   └── project documentation
    ├── scripts/
    │   └── build, installation, launch, and release scripts
    └── .vscode/
        └── Visual Studio Code configuration

## Required tools

The development environment requires:

- Git;
- Visual Studio Code;
- Xcode;
- Swift;
- Java 17;
- Gradle;
- Android SDK;
- Android SDK Platform Tools;
- ADB.

## Android SDK environment

Expected Android SDK location:

    ~/Library/Android/sdk

Recommended shell variables:

    ANDROID_HOME=~/Library/Android/sdk
    ADB_LIBUSB=0

`ADB_LIBUSB=0` is used because the old Android tablet exposes a USB configuration that is unstable with the newer libusb ADB backend.

ADB is only required for installation and debugging.

The running applications communicate over the local Wi-Fi network.

## Verify the environment

From the repository root:

    ./scripts/check-environment.sh

When the tablet is connected through USB with debugging enabled, it should appear in:

    ADB_LIBUSB=0 adb devices -l

Expected state:

    device

## Android development

Android source directory:

    android-app/

Primary language:

    Java

Minimum supported API:

    API 14

Target test device:

    Android 4.0.4

The Android project intentionally avoids:

- Jetpack Compose;
- AndroidX;
- Kotlin-only dependencies;
- modern Android-only APIs;
- unnecessary external libraries;
- resource-heavy animations.

### Build the debug APK

From the repository root:

    cd android-app
    ./gradlew clean assembleDebug

Generated APK:

    android-app/app/build/outputs/apk/debug/app-debug.apk

### Install the debug APK

Connect the tablet through USB and enable USB debugging.

From the `android-app` directory:

    ADB_LIBUSB=0 adb devices -l
    ADB_LIBUSB=0 adb install -r app/build/outputs/apk/debug/app-debug.apk

For a clean reinstall:

    ADB_LIBUSB=0 adb uninstall com.theandreyzakharov.usbtouchpad.debug
    ADB_LIBUSB=0 adb install app/build/outputs/apk/debug/app-debug.apk

### Start the Android application with ADB

    ADB_LIBUSB=0 adb shell am start -n com.theandreyzakharov.usbtouchpad.debug/com.theandreyzakharov.usbtouchpad.MainActivity

On the target tablet, launching an application may temporarily reset the ADB connection.

This does not affect the normal Wi-Fi touchpad connection.

### Android logs

Clear logs:

    ADB_LIBUSB=0 adb logcat -c

Read Touchpad logs:

    ADB_LIBUSB=0 adb logcat -d -s USBTouchpadActivity USBTouchpadServer

### Test the Android TCP server

Connect the Mac to the tablet hotspot.

Determine the tablet local address and test the server:

    nc -v TABLET_ADDRESS 27183

A successful connection should return a JSON `hello` message.

## macOS development

macOS source directory:

    macos-app/

Primary language:

    Swift

Frameworks and technologies:

- SwiftUI;
- AppKit;
- Network framework;
- Core Graphics;
- Swift Package Manager.

### Format the source code

    cd macos-app
    swift format --in-place --recursive Sources Tests Package.swift

### Build

    swift build --product Touchpad

### Run tests

    swift test

### Run

    swift run Touchpad

The helper script can also be used from the repository root:

    ./scripts/run-macos.sh

### Accessibility permission

The macOS application requires Accessibility permission to generate cursor, click, scroll, and drag events.

The permission is located in:

    System Settings
    Privacy & Security
    Accessibility

When running through Terminal or Visual Studio Code during development, macOS may grant permission to the launching application rather than directly to the Swift executable.

## Local network testing

The recommended test configuration is:

1. Enable the Wi-Fi hotspot on the Android tablet.
2. Connect the Mac to the tablet hotspot.
3. Start the Android Touchpad application.
4. Start the macOS Touchpad application.
5. Enter the tablet local address in the macOS application.
6. Confirm that both applications show a connected state.

Runtime port:

    27183

Internet access is not required.

## Supported gestures

    One-finger movement      → cursor movement
    One-finger tap           → left click
    Two-finger tap           → right click
    Two-finger movement      → scrolling
    Double tap and movement  → left-button drag

Gesture recognition is implemented in:

    android-app/app/src/main/java/com/theandreyzakharov/usbtouchpad/TouchpadView.java

Protocol messages are created in:

    android-app/app/src/main/java/com/theandreyzakharov/usbtouchpad/TouchMessage.java

The Android TCP server is implemented in:

    android-app/app/src/main/java/com/theandreyzakharov/usbtouchpad/TouchServer.java

## VS Code

Recommended extensions:

- Swift;
- Extension Pack for Java;
- Gradle Extension Pack.

The repository contains VS Code configuration under:

    .vscode/

Open the command palette with:

    Command Shift P

Then select:

    Tasks: Run Task

## Release builds

Create Android and macOS release artifacts from the repository root:

    ./scripts/build-release.sh 1.0.0

Generated files:

    release/Touchpad-Android-1.0.0.apk
    release/Touchpad-macOS-1.0.0.zip

The release directory is ignored by Git.

Attach the generated APK and ZIP files to a GitHub Release.

## macOS release packaging

The release script:

- builds the Swift product in release mode;
- creates `Touchpad.app`;
- copies Swift Package resources;
- generates the macOS `.icns` icon;
- creates `Info.plist`;
- applies ad-hoc code signing;
- archives the application as ZIP.

The ad-hoc signature is sufficient for local testing.

On another Mac, Gatekeeper may require the user to open the application through the context menu because the application is not signed with an Apple Developer ID certificate and is not notarized.

## Android release packaging

The current release script packages the debug APK.

This is suitable for direct installation and project testing.

A production Android release should use:

- a release build type;
- a private signing keystore;
- a stable version code;
- a stable version name.

## Git workflow

Before starting work:

    git pull

After completing a logical change:

    git status
    git add .
    git commit -m "Describe the change"
    git push

Keep generated build directories and release files out of Git.

Commit source code, documentation, configuration, and build scripts.

## Internal names

The visible project and product name is:

    Touchpad

Some internal source and package identifiers remain unchanged:

    USBTouchpadMac
    USBTouchpadMacTests
    com.theandreyzakharov.usbtouchpad

These names are kept for compatibility and do not affect the visible application name.
