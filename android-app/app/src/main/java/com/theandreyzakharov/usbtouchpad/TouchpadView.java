package com.theandreyzakharov.usbtouchpad;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;

public final class TouchpadView extends View {

    public interface Listener {

        void onMove(
                float dx,
                float dy);

        void onTap();

        void onRightTap();

        void onScroll(
                float dx,
                float dy);
    }

    private static final long TAP_TIMEOUT_MILLISECONDS = 250L;

    private Listener listener;

    private float previousX;
    private float previousY;
    private float totalMovement;
    private float touchSlop;

    private long downTime;

    private boolean multiTouchUsed;
    private boolean scrolling;

    public TouchpadView(Context context) {
        super(context);
        initialize(context);
    }

    public TouchpadView(
            Context context,
            AttributeSet attributes) {
        super(
                context,
                attributes);

        initialize(context);
    }

    public TouchpadView(
            Context context,
            AttributeSet attributes,
            int defaultStyle) {
        super(
                context,
                attributes,
                defaultStyle);

        initialize(context);
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    private void initialize(Context context) {
        setFocusable(true);
        setClickable(true);

        touchSlop = ViewConfiguration
                .get(context)
                .getScaledTouchSlop();
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();

        switch (action) {
            case MotionEvent.ACTION_DOWN:
                beginGesture(event);
                return true;

            case MotionEvent.ACTION_POINTER_DOWN:
                beginMultiTouch(event);
                return true;

            case MotionEvent.ACTION_MOVE:
                moveGesture(event);
                return true;

            case MotionEvent.ACTION_POINTER_UP:
                finishPointer(event);
                return true;

            case MotionEvent.ACTION_UP:
                finishGesture(event);
                return true;

            case MotionEvent.ACTION_CANCEL:
                resetGesture();
                return true;

            default:
                return true;
        }
    }

    private void beginGesture(MotionEvent event) {
        previousX = event.getX(0);
        previousY = event.getY(0);

        totalMovement = 0.0f;
        downTime = event.getEventTime();

        multiTouchUsed = false;
        scrolling = false;
    }

    private void beginMultiTouch(MotionEvent event) {
        if (event.getPointerCount() < 2) {
            return;
        }

        multiTouchUsed = true;
        scrolling = true;

        previousX = centroidX(event);
        previousY = centroidY(event);
    }

    private void moveGesture(MotionEvent event) {
        if (event.getPointerCount() >= 2) {
            moveScroll(event);
        } else if (!scrolling) {
            movePointer(event);
        }
    }

    private void movePointer(MotionEvent event) {
        float currentX = event.getX(0);
        float currentY = event.getY(0);

        float dx = currentX - previousX;
        float dy = currentY - previousY;

        previousX = currentX;
        previousY = currentY;

        totalMovement += calculateDistance(
                dx,
                dy);

        if (listener != null
                && (dx != 0.0f || dy != 0.0f)) {
            listener.onMove(
                    dx,
                    dy);
        }
    }

    private void moveScroll(MotionEvent event) {
        float currentX = centroidX(event);
        float currentY = centroidY(event);

        float dx = currentX - previousX;
        float dy = currentY - previousY;

        previousX = currentX;
        previousY = currentY;

        totalMovement += calculateDistance(
                dx,
                dy);

        if (listener != null
                && (dx != 0.0f || dy != 0.0f)) {
            listener.onScroll(
                    dx,
                    dy);
        }
    }

    private void finishPointer(MotionEvent event) {
        multiTouchUsed = true;
        scrolling = false;

        int removedIndex = event.getActionIndex();
        int remainingIndex = removedIndex == 0
                ? 1
                : 0;

        if (remainingIndex < event.getPointerCount()) {
            previousX = event.getX(
                    remainingIndex);

            previousY = event.getY(
                    remainingIndex);
        }
    }

    private void finishGesture(MotionEvent event) {
        long duration = event.getEventTime() - downTime;

        boolean tap = duration <= TAP_TIMEOUT_MILLISECONDS
                && totalMovement <= touchSlop;

        if (tap && listener != null) {
            if (multiTouchUsed) {
                listener.onRightTap();
            } else {
                listener.onTap();
            }

            performClick();
        }

        resetGesture();
    }

    @Override
    public boolean performClick() {
        super.performClick();
        return true;
    }

    private void resetGesture() {
        previousX = 0.0f;
        previousY = 0.0f;
        totalMovement = 0.0f;
        downTime = 0L;
        multiTouchUsed = false;
        scrolling = false;
    }

    private static float centroidX(MotionEvent event) {
        float result = 0.0f;
        int count = event.getPointerCount();

        for (int index = 0; index < count; index++) {
            result += event.getX(index);
        }

        return result / count;
    }

    private static float centroidY(MotionEvent event) {
        float result = 0.0f;
        int count = event.getPointerCount();

        for (int index = 0; index < count; index++) {
            result += event.getY(index);
        }

        return result / count;
    }

    private static float calculateDistance(
            float dx,
            float dy) {
        return (float) Math.sqrt(
                dx * dx + dy * dy);
    }
}
