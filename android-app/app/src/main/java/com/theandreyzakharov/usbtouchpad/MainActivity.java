package com.theandreyzakharov.usbtouchpad;

import android.app.Activity;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.widget.TextView;

public final class MainActivity
        extends Activity
        implements TouchServer.Listener,
        TouchpadView.Listener {

    private static final String TAG = "USBTouchpadActivity";

    private TouchServer touchServer;

    private TouchpadView touchpadView;
    private TextView statusText;
    private TextView deviceInfoText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getWindow().addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.activity_main);

        touchpadView = (TouchpadView) findViewById(
                R.id.touchpad_view);

        statusText = (TextView) findViewById(
                R.id.status_text);

        deviceInfoText = (TextView) findViewById(
                R.id.device_info_text);

        touchpadView.setListener(this);

        deviceInfoText.setText(
                createDeviceInformation());

        touchServer = new TouchServer(this);

        touchpadView.post(
                new Runnable() {
                    @Override
                    public void run() {
                        startServerIfNeeded();
                        updateServerScreenSize();
                    }
                });

        Log.i(TAG, "Activity created");
    }

    @Override
    protected void onResume() {
        super.onResume();

        Log.i(TAG, "Activity resumed");

        if (touchpadView != null) {
            touchpadView.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            startServerIfNeeded();
                            updateServerScreenSize();
                        }
                    });
        }
    }

    @Override
    public void onConfigurationChanged(
            Configuration newConfiguration) {
        super.onConfigurationChanged(newConfiguration);

        Log.i(TAG, "Screen orientation changed");

        touchpadView.post(
                new Runnable() {
                    @Override
                    public void run() {
                        updateServerScreenSize();
                    }
                });
    }

    @Override
    protected void onDestroy() {
        Log.i(TAG, "Activity destroyed");

        if (touchServer != null) {
            touchServer.stop();
        }

        super.onDestroy();
    }

    @Override
    public void onServerStarted() {
        updateStatus(
                R.string.status_waiting,
                R.color.status_waiting);
    }

    @Override
    public void onClientConnected() {
        updateStatus(
                R.string.status_connected,
                R.color.status_connected);
    }

    @Override
    public void onClientReady() {
        updateStatus(
                R.string.touchpad_ready,
                R.color.status_connected);
    }

    @Override
    public void onClientDisconnected() {
        updateStatus(
                R.string.status_waiting,
                R.color.status_waiting);
    }

    @Override
    public void onServerError(final String message) {
        runOnUiThread(
                new Runnable() {
                    @Override
                    public void run() {
                        statusText.setText(
                                getString(R.string.status_error)
                                        + ": "
                                        + message);

                        statusText.setTextColor(
                                getResources().getColor(
                                        R.color.status_error));
                    }
                });
    }

    @Override
    public void onMove(
            float dx,
            float dy) {
        if (touchServer != null) {
            touchServer.sendMove(dx, dy);
        }
    }

    @Override
    public void onTap() {
        if (touchServer != null) {
            touchServer.sendTap();
        }
    }

    @Override
    public void onRightTap() {
        if (touchServer != null) {
            touchServer.sendRightTap();
        }
    }

    @Override
    public void onScroll(
            float dx,
            float dy) {
        if (touchServer != null) {
            touchServer.sendScroll(dx, dy);
        }
    }

    @Override
    public void onDragStart() {
        if (touchServer != null) {
            touchServer.sendDragStart();
        }
    }

    @Override
    public void onDragMove(
            float dx,
            float dy) {
        if (touchServer != null) {
            touchServer.sendDragMove(dx, dy);
        }
    }

    @Override
    public void onDragEnd() {
        if (touchServer != null) {
            touchServer.sendDragEnd();
        }
    }

    private void startServerIfNeeded() {
        if (touchServer == null || touchServer.isRunning()) {
            return;
        }

        int width = touchpadView.getWidth();
        int height = touchpadView.getHeight();

        if (width <= 0 || height <= 0) {
            return;
        }

        updateStatus(
                R.string.status_starting,
                R.color.status_waiting);

        touchServer.start(width, height);
    }

    private void updateServerScreenSize() {
        if (touchServer == null || touchpadView == null) {
            return;
        }

        int width = touchpadView.getWidth();
        int height = touchpadView.getHeight();

        if (width <= 0 || height <= 0) {
            return;
        }

        touchServer.updateScreenSize(
                width,
                height);

        Log.i(
                TAG,
                "Touch area: "
                        + width
                        + "x"
                        + height);
    }

    private void updateStatus(
            final int textResource,
            final int colorResource) {
        runOnUiThread(
                new Runnable() {
                    @Override
                    public void run() {
                        statusText.setText(textResource);

                        statusText.setTextColor(
                                getResources().getColor(
                                        colorResource));
                    }
                });
    }

    private String createDeviceInformation() {
        return Build.MANUFACTURER
                + " "
                + Build.MODEL
                + " · Android "
                + Build.VERSION.RELEASE
                + " · API "
                + Build.VERSION.SDK_INT;
    }
}
