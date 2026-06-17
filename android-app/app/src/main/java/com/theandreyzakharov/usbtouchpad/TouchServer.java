package com.theandreyzakharov.usbtouchpad;

import android.os.Build;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;

public final class TouchServer {

    public interface Listener {

        void onServerStarted();

        void onClientConnected();

        void onClientReady();

        void onClientDisconnected();

        void onServerError(String message);
    }

    private static final String TAG = "USBTouchpadServer";
    private static final int PORT = 27183;

    private final Object connectionLock = new Object();
    private final Listener listener;

    private volatile boolean running;

    private Thread serverThread;
    private ServerSocket serverSocket;
    private Socket clientSocket;
    private BufferedWriter writer;

    private long sequence = 1L;

    private volatile int screenWidth;
    private volatile int screenHeight;

    public TouchServer(Listener listener) {
        this.listener = listener;
    }

    public synchronized void start(
            int width,
            int height) {
        if (running) {
            Log.d(TAG, "Server is already running");
            return;
        }

        updateScreenSize(width, height);

        running = true;

        serverThread = new Thread(
                new Runnable() {
                    @Override
                    public void run() {
                        runServer();
                    }
                },
                "USBTouchpadServer");

        serverThread.start();
    }

    public void updateScreenSize(
            int width,
            int height) {
        if (width <= 0 || height <= 0) {
            return;
        }

        screenWidth = width;
        screenHeight = height;

        Log.i(
                TAG,
                "Screen size updated: "
                        + width
                        + "x"
                        + height);
    }

    public synchronized void stop() {
        Log.d(TAG, "Stopping server");

        running = false;

        closeClient();

        if (serverSocket != null) {
            try {
                serverSocket.close();
            } catch (IOException ignored) {
            }

            serverSocket = null;
        }

        if (serverThread != null) {
            serverThread.interrupt();
            serverThread = null;
        }
    }

    public boolean isRunning() {
        return running;
    }

    public void sendMove(
            float dx,
            float dy) {
        sendLine(
                TouchMessage.move(
                        nextSequence(),
                        dx,
                        dy));
    }

    public void sendTap() {
        sendLine(
                TouchMessage.tap(
                        nextSequence()));
    }

    public void sendRightTap() {
        sendLine(
                TouchMessage.rightTap(
                        nextSequence()));
    }

    public void sendScroll(
            float dx,
            float dy) {
        sendLine(
                TouchMessage.scroll(
                        nextSequence(),
                        dx,
                        dy));
    }

    private void runServer() {
        try {
            ServerSocket socket = new ServerSocket();

            socket.setReuseAddress(true);

            socket.bind(
                    new InetSocketAddress(PORT));

            serverSocket = socket;

            Log.i(
                    TAG,
                    "Server listening on port " + PORT);

            notifyServerStarted();

            while (running) {
                try {
                    Socket acceptedSocket = socket.accept();

                    if (!running) {
                        closeQuietly(acceptedSocket);
                        break;
                    }

                    handleClient(acceptedSocket);
                } catch (SocketException exception) {
                    if (running) {
                        reportError(
                                "Accept failed: "
                                        + exception.getMessage());
                    }
                }
            }
        } catch (IOException exception) {
            if (running) {
                reportError(
                        "Server start failed: "
                                + exception.getMessage());
            }
        } finally {
            running = false;
            closeClient();

            if (serverSocket != null) {
                try {
                    serverSocket.close();
                } catch (IOException ignored) {
                }

                serverSocket = null;
            }

            Log.i(TAG, "Server thread finished");
        }
    }

    private void handleClient(Socket socket) {
        Log.i(TAG, "Mac client connected");

        closeClient();

        BufferedReader reader = null;

        try {
            socket.setTcpNoDelay(true);
            socket.setKeepAlive(true);

            BufferedWriter newWriter = new BufferedWriter(
                    new OutputStreamWriter(
                            socket.getOutputStream(),
                            "UTF-8"));

            reader = new BufferedReader(
                    new InputStreamReader(
                            socket.getInputStream(),
                            "UTF-8"));

            synchronized (connectionLock) {
                clientSocket = socket;
                writer = newWriter;
            }

            notifyClientConnected();
            sendHello();

            String line;

            while (running
                    && !socket.isClosed()
                    && (line = reader.readLine()) != null) {
                processIncomingMessage(line);
            }
        } catch (IOException exception) {
            if (running) {
                Log.w(
                        TAG,
                        "Client connection ended: "
                                + exception.getMessage());
            }
        } finally {
            closeQuietly(reader);
            closeClient();

            Log.i(TAG, "Mac client disconnected");

            notifyClientDisconnected();
        }
    }

    private void sendHello() {
        String manufacturer = Build.MANUFACTURER == null
                ? "Unknown"
                : Build.MANUFACTURER;

        String model = Build.MODEL == null
                ? "Android tablet"
                : Build.MODEL;

        String version = Build.VERSION.RELEASE == null
                ? "Unknown"
                : Build.VERSION.RELEASE;

        sendLine(
                TouchMessage.hello(
                        nextSequence(),
                        manufacturer + " " + model,
                        version,
                        screenWidth,
                        screenHeight));
    }

    private void processIncomingMessage(String line) {
        try {
            JSONObject object = new JSONObject(line);

            String type = object.optString(
                    "type",
                    "");

            if ("ready".equals(type)) {
                Log.i(TAG, "Mac client is ready");
                notifyClientReady();
                return;
            }

            if ("ping".equals(type)) {
                long receivedSequence = object.optLong(
                        "sequence",
                        nextSequence());

                sendLine(
                        TouchMessage.pong(
                                receivedSequence));
            }
        } catch (JSONException exception) {
            sendLine(
                    TouchMessage.error(
                            nextSequence(),
                            "invalid_message",
                            exception.getMessage()));
        }
    }

    private void sendLine(String line) {
        synchronized (connectionLock) {
            if (writer == null) {
                return;
            }

            try {
                writer.write(line);
                writer.write('\n');
                writer.flush();
            } catch (IOException exception) {
                Log.w(
                        TAG,
                        "Write failed: "
                                + exception.getMessage());

                closeClient();
            }
        }
    }

    private synchronized long nextSequence() {
        long current = sequence;

        sequence++;

        if (sequence <= 0L) {
            sequence = 1L;
        }

        return current;
    }

    private void closeClient() {
        synchronized (connectionLock) {
            if (writer != null) {
                try {
                    writer.close();
                } catch (IOException ignored) {
                }

                writer = null;
            }

            if (clientSocket != null) {
                try {
                    clientSocket.close();
                } catch (IOException ignored) {
                }

                clientSocket = null;
            }
        }
    }

    private void reportError(String message) {
        Log.e(TAG, message);

        if (listener != null) {
            listener.onServerError(message);
        }
    }

    private void notifyServerStarted() {
        if (listener != null) {
            listener.onServerStarted();
        }
    }

    private void notifyClientConnected() {
        if (listener != null) {
            listener.onClientConnected();
        }
    }

    private void notifyClientReady() {
        if (listener != null) {
            listener.onClientReady();
        }
    }

    private void notifyClientDisconnected() {
        if (listener != null) {
            listener.onClientDisconnected();
        }
    }

    private static void closeQuietly(
            Closeable closeable) {
        if (closeable == null) {
            return;
        }

        try {
            closeable.close();
        } catch (IOException ignored) {
        }
    }

    private static void closeQuietly(
            Socket socket) {
        if (socket == null) {
            return;
        }

        try {
            socket.close();
        } catch (IOException ignored) {
        }
    }
}
