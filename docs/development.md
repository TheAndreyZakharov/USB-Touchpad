# Development Guide

## Repository

Clone the repository:

    git clone https://github.com/TheAndreyZakharov/USB-Touchpad.git
    cd USB-Touchpad
    code .

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

Expected shell variables:

    ANDROID_HOME=~/Library/Android/sdk
    ADB_LIBUSB=0

The ADB_LIBUSB setting is required because the old tablet exposes a USB configuration that crashes the newer libusb ADB backend.

## Verify the environment

Run:

    ./scripts/check-environment.sh

The connected tablet should appear with the state:

    device

## Android development

Android source directory:

    android-app/

Primary language:

    Java

Minimum Android version:

    Android 4.x

The project should avoid:

- Jetpack Compose;
- Kotlin-only dependencies;
- modern Android APIs without compatibility checks;
- large external libraries;
- unnecessary animations.

Build the debug APK:

    cd android-app
    ./gradlew assembleDebug

Install the debug APK:

    cd ..
    ./scripts/install-android.sh

## macOS development

macOS source directory:

    macos-app/

Primary language:

    Swift

Build:

    cd macos-app
    swift build

Run:

    swift run USBTouchpadMac

Test:

    swift test

The application will eventually require Accessibility permission to publish mouse and scroll events.

## VS Code

Recommended extensions:

- Swift;
- Extension Pack for Java;
- Gradle Extension Pack.

The repository includes suggested extensions and build tasks under .vscode.

Open the command palette with:

    Command Shift P

Then select:

    Tasks: Run Task

## Git workflow

Before starting work:

    git pull

After completing a logical change:

    git status
    git add .
    git commit -m "Describe the change"
    git push

Use small commits for separate development stages.

Examples:

    Configure Android application
    Implement macOS TCP client
    Add cursor movement
    Add touch event protocol
    Implement Android touch capture

## Development order

The current planned order is:

1. Define shared protocol.
2. Implement macOS application skeleton.
3. Implement macOS TCP client.
4. Implement macOS cursor controller.
5. Configure Android application.
6. Implement Android TCP server.
7. Implement touch capture.
8. Connect both applications.
9. Add gestures and reliability improvements.