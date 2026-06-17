# USB Touchpad Communication Protocol

## Version

Protocol version:

    1

## Transport

The protocol is transported over TCP.

Default port:

    27183

Each message is encoded as one JSON object followed by a newline character.

Encoding:

    UTF-8

Message separator:

    LF

Each protocol message must fit on one logical line.

## General message structure

Every message contains:

- version;
- type;
- sequence number;
- timestamp.

Common conceptual structure:

    version: protocol version
    type: event type
    sequence: increasing event identifier
    timestamp: sender monotonic time in milliseconds

## Event types

### Hello

Sent by Android immediately after the Mac connects.

Fields:

- version;
- type;
- deviceName;
- androidVersion;
- screenWidth;
- screenHeight.

Type value:

    hello

### Ready

Sent by the Mac after accepting the protocol version.

Type value:

    ready

### Move

Represents relative one-finger movement.

Fields:

- dx;
- dy.

Type value:

    move

Positive dx moves the cursor to the right.

Negative dx moves the cursor to the left.

Positive dy moves the cursor down.

Negative dy moves the cursor up.

### Tap

Represents a short one-finger tap.

Type value:

    tap

The Mac interprets this as a left click.

### Right tap

Represents a short two-finger tap.

Type value:

    rightTap

The Mac interprets this as a right click.

### Scroll

Represents relative two-finger scrolling.

Fields:

- dx;
- dy.

Type value:

    scroll

The Mac may invert scroll direction according to user settings.

### Drag start

Begins a left-button drag operation.

Type value:

    dragStart

### Drag move

Moves the pointer while the left mouse button remains pressed.

Fields:

- dx;
- dy.

Type value:

    dragMove

### Drag end

Finishes a drag operation.

Type value:

    dragEnd

### Ping

Used to verify that the connection remains active.

Type value:

    ping

### Pong

Response to a ping message.

Type value:

    pong

### Error

Reports a protocol or application error.

Fields:

- code;
- message.

Type value:

    error

## Sequence numbers

The Android application increments the sequence number for every outgoing event.

The first sequence number after connection should be:

    1

The Mac may use sequence numbers to detect missing or reordered application messages.

TCP already preserves byte order, so sequence numbers are primarily useful for debugging.

## Timestamps

Timestamps should use a monotonic clock rather than wall-clock time.

The value represents elapsed milliseconds from an arbitrary system reference point.

The timestamp is used for:

- debugging latency;
- gesture timing;
- identifying delayed events.

## Connection lifecycle

Expected connection sequence:

    Android starts TCP server
    Mac configures ADB forwarding
    Mac connects to localhost port 27183
    Android sends hello
    Mac validates protocol version
    Mac sends ready
    Android begins sending input events

## Reconnection

When the connection is lost:

- Android keeps the server running;
- Android stops sending events until a new client connects;
- Mac retries the connection;
- a new hello and ready handshake is required;
- sequence numbering may restart from 1.

## Invalid messages

The receiver must ignore malformed messages without terminating the application.

The receiver should log:

- invalid JSON;
- unsupported version;
- missing event type;
- invalid numeric fields;
- unexpected event type.

Repeated protocol errors may cause the connection to be closed and recreated.

## Initial implementation scope

The first working version only requires:

- hello;
- ready;
- move;
- tap;
- scroll;
- ping;
- pong.

The remaining events may be added after basic cursor control works.