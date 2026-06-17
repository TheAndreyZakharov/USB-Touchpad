package com.theandreyzakharov.usbtouchpad;

import android.os.SystemClock;

import org.json.JSONException;
import org.json.JSONObject;

public final class TouchMessage {

    public static final int PROTOCOL_VERSION = 1;

    private TouchMessage() {
    }

    public static String hello(
            long sequence,
            String deviceName,
            String androidVersion,
            int screenWidth,
            int screenHeight) {
        JSONObject object = createBaseMessage(
                "hello",
                sequence);

        try {
            object.put("deviceName", deviceName);
            object.put("androidVersion", androidVersion);
            object.put("screenWidth", screenWidth);
            object.put("screenHeight", screenHeight);
        } catch (JSONException exception) {
            throw new IllegalStateException(
                    "Cannot create hello message",
                    exception);
        }

        return object.toString();
    }

    public static String move(
            long sequence,
            float dx,
            float dy) {
        return createMovementMessage(
                "move",
                sequence,
                dx,
                dy);
    }

    public static String scroll(
            long sequence,
            float dx,
            float dy) {
        return createMovementMessage(
                "scroll",
                sequence,
                dx,
                dy);
    }

    public static String dragMove(
            long sequence,
            float dx,
            float dy) {
        return createMovementMessage(
                "dragMove",
                sequence,
                dx,
                dy);
    }

    public static String tap(long sequence) {
        return createBaseMessage(
                "tap",
                sequence).toString();
    }

    public static String rightTap(long sequence) {
        return createBaseMessage(
                "rightTap",
                sequence).toString();
    }

    public static String dragStart(long sequence) {
        return createBaseMessage(
                "dragStart",
                sequence).toString();
    }

    public static String dragEnd(long sequence) {
        return createBaseMessage(
                "dragEnd",
                sequence).toString();
    }

    public static String pong(long sequence) {
        return createBaseMessage(
                "pong",
                sequence).toString();
    }

    public static String error(
            long sequence,
            String code,
            String message) {
        JSONObject object = createBaseMessage(
                "error",
                sequence);

        try {
            object.put("code", code);
            object.put("message", message);
        } catch (JSONException exception) {
            throw new IllegalStateException(
                    "Cannot create error message",
                    exception);
        }

        return object.toString();
    }

    private static String createMovementMessage(
            String type,
            long sequence,
            float dx,
            float dy) {
        JSONObject object = createBaseMessage(
                type,
                sequence);

        try {
            object.put("dx", dx);
            object.put("dy", dy);
        } catch (JSONException exception) {
            throw new IllegalStateException(
                    "Cannot create movement message",
                    exception);
        }

        return object.toString();
    }

    private static JSONObject createBaseMessage(
            String type,
            long sequence) {
        JSONObject object = new JSONObject();

        try {
            object.put(
                    "version",
                    PROTOCOL_VERSION);

            object.put(
                    "type",
                    type);

            object.put(
                    "sequence",
                    sequence);

            object.put(
                    "timestamp",
                    SystemClock.elapsedRealtime());
        } catch (JSONException exception) {
            throw new IllegalStateException(
                    "Cannot create protocol message",
                    exception);
        }

        return object;
    }
}
