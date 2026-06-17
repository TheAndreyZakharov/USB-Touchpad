# Architecture

## Overview

USB Touchpad consists of two independent applications connected through a small shared communication protocol.

The Android application captures touch input.

The macOS application receives the input and converts it into cursor, click, drag, and scroll events.

The two applications communicate through a TCP connection transported over USB by Android Debug Bridge.

## Main components

### Android application

The Android application is responsible for:

- displaying a full-screen touch surface;
- reading Android MotionEvent data;
- tracking one or more fingers;
- calculating relative movement;
- recognizing basic gestures;
- starting a TCP server;
- sending touch events to the Mac;
- displaying connection status.

The Android application does not control the Mac directly.

It only sends normalized input events.

### macOS application

The macOS application is responsible for:

- checking whether ADB is available;
- detecting the connected Android tablet;
- configuring ADB port forwarding;
- connecting to the Android TCP server;
- decoding protocol messages;
- moving the macOS cursor;
- generating mouse clicks;
- generating scroll events;
- handling connection loss;
- exposing sensitivity and behavior settings.

The first implementation will generate input through Core Graphics CGEvent.

A custom macOS driver is not required for the initial version.

### Communication protocol

The protocol is shared conceptually by both applications.

The first version uses newline-delimited JSON messages sent over TCP.

Each line represents one complete event.

Example logical events:

    move
    tap
    scroll
    ping
    pong

The exact schema is documented in protocol/protocol.md.

## USB transport

The initial transport uses ADB port forwarding.

The Android application listens on a TCP port on the tablet.

The Mac creates a local forwarding rule:

    Mac localhost port
            ↓
    ADB over USB
            ↓
    Android localhost port

The Mac application then connects to its own localhost address.

This approach provides:

- USB-only communication;
- no dependency on Wi-Fi;
- no Bluetooth pairing;
- simple installation through ADB;
- reliable reconnection;
- low implementation complexity.

## Initial port

The development port is:

    27183

Both applications must use the same port.

## Input processing model

Touch movement is processed as relative movement.

The Android application sends movement deltas rather than absolute screen coordinates.

Example:

    previous position: x 500, y 300
    current position: x 506, y 297
    resulting delta: dx 6, dy -3

The macOS application multiplies the delta by the configured sensitivity and applies it to the current cursor position.

## Gesture ownership

Gesture recognition should primarily happen on Android.

Android has direct access to:

- pointer count;
- touch positions;
- touch duration;
- movement distance;
- pointer down and pointer up events.

The Mac receives high-level events such as:

- move;
- tap;
- scroll;
- drag start;
- drag move;
- drag end.

This keeps the macOS input layer simple.

## Threading

### Android

The user interface thread handles touch input.

Network operations must run on a background thread.

Touch events may be accumulated and sent at a controlled interval to avoid excessive messages.

### macOS

ADB management runs outside the main interface thread.

TCP receiving runs on a dedicated queue.

Decoded input events are passed to the input controller.

User interface state updates return to the main thread.

## Reliability requirements

The applications must tolerate:

- USB disconnection;
- Android application restart;
- macOS application restart;
- incomplete TCP packets;
- multiple messages in one TCP packet;
- malformed protocol messages;
- ADB server restart.

TCP is a byte stream.

The receiver must not assume that one network read equals one protocol message.

Incoming data must be accumulated in a buffer and separated by newline characters.

## Security model

The server listens only on the Android loopback interface when possible.

The Mac connects through ADB forwarding.

No public network port is required.

The protocol does not initially include authentication because the transport is limited to the locally connected ADB device.

## Development stages

### Stage 1

- Android displays touch coordinates.
- Android starts a TCP server.
- Mac connects and prints received messages.

### Stage 2

- one-finger movement;
- short tap;
- macOS cursor movement;
- macOS left click.

### Stage 3

- two-finger scrolling;
- right click;
- drag and drop;
- sensitivity settings.

### Stage 4

- automatic device detection;
- automatic ADB forwarding;
- automatic Android application launch;
- menu bar interface;
- launch at login.

### Stage 5

- smoothing;
- acceleration;
- inertial scrolling;
- additional gestures;
- remote display research.