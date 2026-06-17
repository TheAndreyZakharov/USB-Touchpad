# USB Touchpad

USB Touchpad turns an old Android tablet into a touchpad for macOS.

The project contains two applications:

- an Android application that captures touch gestures and sends input events;
- a macOS menu bar application that receives those events and controls the cursor.

The applications communicate directly over a local Wi-Fi network. Internet access is not required.

## How it works

The Android tablet creates a Wi-Fi hotspot.

The Mac connects to that hotspot and establishes a direct TCP connection to the Android application.

The Android application starts a TCP server on port `27183`. The macOS application connects to the tablet using its local network address.

Communication flow:

    Touch input on Android
            ↓
    Gesture processing
            ↓
    TCP server on the tablet
            ↓
    Local Wi-Fi connection
            ↓
    TCP client on macOS
            ↓
    Core Graphics input events
            ↓
    Cursor movement, clicks, and scrolling

ADB is not used for the active touchpad connection. It is only used during development to install updated APK files on the tablet.

## Features

### Android application

- one-finger cursor movement;
- single tap for left click;
- two-finger tap for right click;
- two-finger scrolling;
- automatic screen rotation;
- connection status display;
- TCP server for sending touch events;
- compatibility with Android 4.0.4;
- custom application icon.

### macOS application

- menu bar interface;
- direct TCP connection to the tablet;
- configurable tablet address;
- automatic reconnection;
- cursor movement;
- left and right clicks;
- scrolling;
- pointer sensitivity setting;
- scroll sensitivity setting;
- natural scrolling option;
- connection and device information;
- Accessibility permission handling;
- custom application icon.

## Network connection

On the Android tablet:

1. Enable the Wi-Fi hotspot.
2. Open the USB Touchpad application.
3. Leave the application running.

On the Mac:

1. Connect to the hotspot created by the tablet.
2. Determine the local address of the tablet.
3. Enter that address in the macOS application.
4. Connect to TCP port `27183`.

The tablet address depends on the Android firmware and hotspot configuration. It is commonly the network gateway assigned to the Mac.

Internet access is not required. The Mac and tablet only need to be connected to the same local network.

## Gestures

    One-finger movement  → Move cursor
    One-finger tap       → Left click
    Two-finger tap       → Right click
    Two-finger movement  → Scroll

## Communication protocol

Messages are sent as UTF-8 JSON objects separated by newline characters.

Supported message types include:

- `hello`;
- `ready`;
- `move`;
- `tap`;
- `rightTap`;
- `scroll`;
- `dragStart`;
- `dragMove`;
- `dragEnd`;
- `ping`;
- `pong`;
- `error`.

Example movement message:

    {
      "version": 1,
      "type": "move",
      "sequence": 12,
      "timestamp": 15420,
      "dx": 7.5,
      "dy": -2.0
    }

The complete protocol description is stored in:

    protocol/protocol.md

## Repository structure

    USB-Touchpad/
    ├── android-app/
    │   └── Android touch input application and TCP server
    ├── macos-app/
    │   └── macOS menu bar client and cursor controller
    ├── assets/
    │   └── Shared application artwork
    ├── protocol/
    │   └── Communication protocol specification
    ├── docs/
    │   └── Architecture and development documentation
    ├── scripts/
    │   └── Development and build scripts
    └── .vscode/
        └── VS Code workspace configuration

## Android application

The Android application is written in Java.

It uses:

- Android `MotionEvent` for touch input;
- a custom `View` as the touch surface;
- `ServerSocket` for network communication;
- JSON messages for input events;
- Android API 14 as the minimum supported API level.

The project avoids AndroidX, Jetpack Compose and modern Android-only APIs to remain compatible with Android 4.0.4.

## macOS application

The macOS application is written in Swift.

It uses:

- SwiftUI for the menu bar interface;
- Network framework for the TCP connection;
- Core Graphics `CGEvent` for cursor and mouse events;
- Swift Package Manager for building and testing;
- `UserDefaults` for storing settings.

The application requires Accessibility permission to control the cursor.

The permission can be enabled in:

    System Settings
    Privacy & Security
    Accessibility

## Development requirements

Required tools:

- Visual Studio Code;
- Git;
- Xcode;
- Swift;
- Java 17;
- Android SDK;
- Android SDK Platform Tools;
- Gradle;
- ADB.

Check the development environment:

    ./scripts/check-environment.sh

## Build the Android application

From the repository root:

    cd android-app
    ./gradlew clean assembleDebug

The generated APK is located at:

    android-app/app/build/outputs/apk/debug/app-debug.apk

## Install the Android application

Connect the tablet through USB and enable USB debugging.

Check the connection:

    ADB_LIBUSB=0 adb devices -l

Install or update the APK:

    ADB_LIBUSB=0 adb install -r app/build/outputs/apk/debug/app-debug.apk

ADB is only needed for installation and debugging. The running application communicates with the Mac over Wi-Fi.

## Build the macOS application

From the repository root:

    cd macos-app
    swift build

Run tests:

    swift test

Run the application:

    swift run USBTouchpadMac

The helper script can also be used from the repository root:

    ./scripts/run-macos.sh

## Application icons

The shared source image is stored at:

    assets/app-icon.png

Android uses density-specific launcher icons generated from the shared source image.

The macOS application includes the image as a Swift Package resource.
