# Architecture

## Overview

Touchpad consists of two independent applications connected through a small shared communication protocol:

- an Android application that captures touch input and recognizes gestures;
- a macOS application that receives input events and converts them into cursor movement, clicks, scrolling, and dragging.

The applications communicate directly over a local Wi-Fi network.

The Android tablet can create its own Wi-Fi hotspot, and the Mac connects to that network. Internet access is not required.

## Communication flow

    Touch input on Android
            ↓
    Gesture recognition
            ↓
    Android TCP server
            ↓
    Local Wi-Fi network
            ↓
    macOS TCP client
            ↓
    Core Graphics input events
            ↓
    Cursor movement, clicks, scrolling, and dragging

ADB is not used as the runtime transport.

ADB is only used during development to install APK files, inspect logs, and debug the Android application.

## Main components

### Android application

The Android application is responsible for:

- displaying the touch surface;
- receiving Android `MotionEvent` data;
- tracking one or more fingers;
- calculating relative movement;
- recognizing touch gestures;
- starting a TCP server;
- serializing input events as JSON;
- sending events to the Mac;
- displaying connection status and gesture instructions;
- supporting screen rotation;
- remaining compatible with Android 4.0.4.

The Android application does not control the Mac directly.

It converts raw touch input into high-level protocol events.

Supported gestures include:

- one-finger movement;
- one-finger tap;
- two-finger tap;
- two-finger scrolling;
- double tap followed by movement for dragging.

### macOS application

The macOS application is responsible for:

- connecting directly to the Android TCP server;
- storing the tablet network address;
- decoding protocol messages;
- moving the macOS cursor;
- generating left clicks;
- generating right clicks;
- generating scroll events;
- holding and releasing the left mouse button during dragging;
- reconnecting after connection loss;
- exposing pointer and scrolling settings;
- displaying connection and device information;
- requesting Accessibility permission.

The macOS application runs as a menu bar application.

Input events are generated through Core Graphics `CGEvent`.

A custom macOS driver is not required.

## Network transport

The Android application listens on TCP port:

    27183

The server binds to the available network interfaces so that it can be reached through the tablet hotspot or another shared local network.

The macOS application connects to:

    tablet-local-address:27183

The tablet address depends on the hotspot firmware and network configuration.

In the common hotspot setup, the tablet is the local gateway and the Mac receives another address from the same subnet.

No internet connection is required.

## Communication protocol

The protocol uses newline-delimited JSON messages sent over TCP.

Each line contains one complete JSON object.

Example message types:

    hello
    ready
    move
    tap
    rightTap
    scroll
    dragStart
    dragMove
    dragEnd
    ping
    pong
    error

The complete schema is documented in:

    protocol/protocol.md

## Message framing

TCP is a byte stream.

The receiver must not assume that one network read contains exactly one protocol message.

Incoming data is accumulated in a buffer and split using newline characters.

The implementation must correctly handle:

- partial messages;
- multiple messages in one read;
- malformed JSON;
- connection closure;
- reconnect attempts.

## Input processing model

Pointer movement is processed as relative movement.

The Android application sends movement deltas instead of absolute screen coordinates.

Example:

    previous position: x 500, y 300
    current position: x 506, y 297
    resulting delta: dx 6, dy -3

The macOS application multiplies the received values by the configured sensitivity and applies the result to the current cursor position.

This allows the Android touch surface to work independently of the Mac display size.

## Gesture ownership

Gesture recognition happens primarily on Android.

Android has direct access to:

- pointer count;
- pointer coordinates;
- touch duration;
- movement distance;
- pointer down events;
- pointer up events;
- gesture cancellation.

The Mac receives high-level events rather than raw touch points.

This keeps the macOS input layer simple and allows gesture behavior to remain consistent regardless of the Mac display configuration.

## Gesture mapping

    One-finger movement      → move
    One-finger tap           → tap
    Two-finger tap           → rightTap
    Two-finger movement      → scroll
    Double tap and movement  → dragStart, dragMove, dragEnd

For dragging:

1. The first tap is recognized normally.
2. A second nearby tap within the double-tap timeout becomes a drag candidate.
3. Movement beyond the touch threshold sends `dragStart`.
4. Continued movement sends `dragMove`.
5. Releasing the finger sends `dragEnd`.

## Threading

### Android

The Android user interface thread handles touch input and view updates.

The TCP server runs on a background thread.

The server accepts one Mac client connection at a time.

Touch events are serialized and written to the active connection.

UI updates from server callbacks are forwarded to the main thread.

### macOS

The application state is managed on the main actor.

The Network framework handles TCP connection events and incoming data asynchronously.

Decoded protocol messages are passed to the mouse controller.

User interface changes are performed on the main actor.

## Connection lifecycle

The Android application:

1. starts the TCP server;
2. waits for a Mac connection;
3. accepts the connection;
4. sends a `hello` message;
5. waits for the Mac to send `ready`;
6. begins sending gesture events;
7. returns to the waiting state after disconnection.

The macOS application:

1. loads the stored tablet address;
2. connects to the configured TCP port;
3. receives the `hello` message;
4. stores the device information;
5. sends `ready`;
6. processes incoming input events;
7. retries after connection failure.

## Screen rotation

The Android activity handles orientation and screen-size configuration changes without restarting the TCP server.

After rotation, the touch surface dimensions are recalculated and stored by the server.

Relative pointer movement does not depend on orientation, so the same gesture protocol works in portrait and landscape modes.

## Reliability requirements

The applications must tolerate:

- temporary Wi-Fi connection loss;
- Android application restart;
- macOS application restart;
- malformed protocol messages;
- incomplete TCP data;
- multiple messages in one TCP packet;
- screen rotation;
- client reconnection;
- the Mac joining the tablet hotspot after the Android application is already running.

The macOS application automatically retries the connection.

The Android server returns to its listening state when the Mac disconnects.

## Security model

The TCP server is available inside the current local network.

The protocol does not currently include authentication or encryption.

The intended configuration is a private hotspot created by the tablet and protected with a Wi-Fi password.

Users should not expose the server port to an untrusted or public network.

## Application identifiers

The visible project and application name is:

    Touchpad

Some internal identifiers still contain the original development name for compatibility:

    USBTouchpadMac
    USBTouchpadMacTests
    com.theandreyzakharov.usbtouchpad

These identifiers are not shown to users.

Keeping them unchanged avoids unnecessary package migration and allows existing Android installations to be updated.
