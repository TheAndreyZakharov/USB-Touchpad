<div align="center">

<img src="assets/forreadme/app-icon.png" alt="Touchpad logo" width="300"/>

# Touchpad

[![Русский](https://img.shields.io/badge/README_Language-Русский-blue)](https://github.com/TheAndreyZakharov/Touchpad/blob/main/README_RU.md)
[![English](https://img.shields.io/badge/README_Language-English-brightgreen)](https://github.com/TheAndreyZakharov/Touchpad/blob/main/README.md)

</div>

Touchpad turns an old Android tablet into a wireless touchpad for macOS.

The project consists of two applications:

- the Android application captures touch input and recognizes gestures on the tablet;
- the macOS application receives these events over the local network and controls cursor movement, clicks, scrolling, and dragging.

No internet connection is required.

<div align="center">

### Demo

<img src="assets/forreadme/gif.gif" alt="Touchpad demo" width="600"/>

</div>

## How it works

The tablet creates a Wi-Fi hotspot.

The Mac connects to this network and establishes a direct TCP connection with the Android application.

The Android application starts a local server on port `27183` and sends touch events as JSON messages.

The macOS application receives these messages and converts them into system mouse events using Core Graphics.

Communication flow:

    Touch input on the tablet
            ↓
    Android application
            ↓
    TCP server on the local network
            ↓
    macOS application
            ↓
    Cursor movement, clicks, scrolling, and dragging

ADB is not used during normal operation. It is only required by developers to install and debug the Android application.

## Features

### Android application

- one-finger cursor movement;
- left click with a short one-finger tap;
- right click with a two-finger tap;
- scrolling with two-finger movement;
- left-button hold and dragging with a double tap followed by movement;
- automatic screen rotation;
- connection status display;
- gesture instructions;
- compatibility with Android 4.0.4;
- custom application icon.

### macOS application

- menu bar interface;
- direct connection to the tablet over the local network;
- configurable tablet IP address;
- automatic reconnection;
- pointer sensitivity setting;
- scroll sensitivity setting;
- natural scrolling toggle;
- connection status and device information;
- cursor control through macOS system events;
- custom application icon.

## Gestures

    One-finger movement       → move the cursor
    Short one-finger tap      → left click
    Two-finger tap            → right click
    Two-finger movement       → scroll
    Double tap and movement   → hold the left button and drag

## Installation

Download the following files from the latest GitHub Release:

- `Touchpad-Android-<version>.apk`;
- `Touchpad-macOS-<version>.zip`.

### Android

1. Allow installation from unknown sources.
2. Install the APK on the tablet.
3. Open the Touchpad application.
4. Keep the application open while using the touchpad.

The application is designed for Android 4.0.4 and newer compatible Android versions.

### macOS

1. Extract the archive.
2. Move `Touchpad.app` to the `Applications` folder.
3. Launch the application.
4. On the first launch, macOS may display a warning because the application is not notarized. In this case, right-click the application and select `Open`.

## Initial setup

### 1. Grant macOS Accessibility permission

When Touchpad is opened for the first time, it reports that permission is required to control the cursor.

Select the button that opens the macOS settings.

<div align="center">

<img src="assets/forreadme/1.jpeg" alt="Touchpad Accessibility permission request" width="600"/>

</div>

The following section will open:

    System Settings
    → Privacy & Security
    → Accessibility

Enable the switch next to Touchpad. macOS may ask for the user password or Touch ID confirmation.

<div align="center">

<img src="assets/forreadme/2.png" alt="Enabling Touchpad in Accessibility settings" width="600"/>

</div>

Return to Touchpad and select `Request Permission` to refresh the permission status.

When a green icon is displayed next to the Accessibility status, the required permission has been granted.

<div align="center">

<img src="assets/forreadme/3.jpeg" alt="Touchpad Accessibility permission granted" width="400"/>

</div>

### 2. Configure the tablet Wi-Fi hotspot

Open the Android settings and navigate to:

    Settings
    → Wireless & networks
    → Portable hotspot

Enable the checkbox next to `Portable hotspot`.

The `Configure Wi-Fi hotspot` menu can be used to change:

- the network name;
- the password;
- the security type.

<div align="center">

<img src="assets/forreadme/4.png" alt="Android portable hotspot configuration" width="600"/>

</div>

Using a password-protected network is recommended.

### 3. Connect the Mac to the tablet network

Open the Wi-Fi menu on the Mac and connect to the network created by the tablet.

<div align="center">

<img src="assets/forreadme/5.png" alt="Connecting the Mac to the tablet hotspot" width="600"/>

</div>

The network may show that no internet connection is available. This is expected because Touchpad only uses the local connection between the tablet and the Mac.

### 4. Connect the applications

Open Touchpad on the tablet and Touchpad on the Mac.

The macOS application must contain the tablet local IP address. The address depends on the tablet firmware and hotspot configuration. It is usually the local gateway address of the network created by the tablet.

Connection port:

    27183

Select `Reconnect` if the connection is not established automatically.

After a successful connection, the macOS application displays the `Connected` status.

<div align="center">

<img src="assets/forreadme/6.jpeg" alt="Touchpad for macOS connected to the tablet" width="400"/>

</div>

The Android application also displays its current connection state.

Before the Mac is connected:

<div align="center">

<img src="assets/forreadme/7.png" alt="Android application waiting for the Mac connection" width="600"/>

</div>

After the Mac is connected:

<div align="center">

<img src="assets/forreadme/8.png" alt="Android application connected to the Mac" width="600"/>

</div>

After the connected status appears, the tablet can be used as a touchpad.

## Subsequent launches

After the initial setup, the normal startup process is:

1. enable the Wi-Fi hotspot on the tablet;
2. connect the Mac to the tablet network;
3. open Touchpad on the tablet;
4. open Touchpad on the Mac;
5. wait for the `Connected` status.

Internet access is not required. Both devices only need to be connected to the same local network.

## Project structure

    Touchpad/
    ├── android-app/
    │   └── Android application and TCP server
    ├── macos-app/
    │   └── macOS client and cursor controller
    ├── assets/
    │   ├── source application icons
    │   └── documentation images
    ├── protocol/
    │   └── communication protocol specification
    ├── docs/
    │   └── project documentation
    ├── scripts/
    │   └── build, launch, and release scripts
    └── .vscode/
        └── Visual Studio Code configuration

## Building from source

### Android

    cd android-app
    ./gradlew clean assembleDebug

Generated APK:

    android-app/app/build/outputs/apk/debug/app-debug.apk

### macOS

    cd macos-app
    swift build --product Touchpad
    swift test
    swift run Touchpad

The helper script can also be used from the repository root:

    ./scripts/run-macos.sh

## Development and testing environment

- MacBook Air M2 — macOS Tahoe 26.5.
- 3Q Surf RC9716B-DG tablet — Android 4.0.4, 1 GHz processor.
