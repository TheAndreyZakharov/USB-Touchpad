import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var statusText = "Stopped"
  @Published private(set) var isRunning = false
  @Published private(set) var isConnected = false
  @Published private(set) var accessibilityGranted = false
  @Published private(set) var lastEventText = "No events"
  @Published private(set) var deviceName = "Unknown device"

  @Published var tabletHost: String {
    didSet {
      UserDefaults.standard.set(
        tabletHost,
        forKey: "tabletHost"
      )
    }
  }

  @Published var sensitivity: Double = 1.5 {
    didSet {
      mouseController.sensitivity = sensitivity
    }
  }

  @Published var scrollSensitivity: Double = 1.0 {
    didSet {
      mouseController.scrollSensitivity = scrollSensitivity
    }
  }

  @Published var naturalScrolling = true {
    didSet {
      mouseController.naturalScrolling = naturalScrolling
    }
  }

  private let mouseController = MouseController()

  private var touchConnection: TouchConnection?
  private var connectionTask: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?

  init() {
    tabletHost =
      UserDefaults.standard.string(
        forKey: "tabletHost"
      ) ?? "192.168.43.1"

    mouseController.sensitivity = sensitivity
    mouseController.scrollSensitivity = scrollSensitivity
    mouseController.naturalScrolling = naturalScrolling

    refreshAccessibilityStatus()
  }

  func start() {
    guard !isRunning else {
      return
    }

    isRunning = true
    statusText = "Starting"

    refreshAccessibilityStatus(
      promptIfNeeded: true
    )

    connect()
  }

  func stop() {
    isRunning = false
    isConnected = false
    statusText = "Stopped"

    connectionTask?.cancel()
    connectionTask = nil

    reconnectTask?.cancel()
    reconnectTask = nil

    touchConnection?.stop()
    touchConnection = nil

    mouseController.releaseAllButtons()
  }

  func reconnect() {
    guard isRunning else {
      start()
      return
    }

    isConnected = false
    statusText = "Reconnecting"

    touchConnection?.stop()
    touchConnection = nil

    connectionTask?.cancel()
    reconnectTask?.cancel()

    connect()
  }

  func requestAccessibilityPermission() {
    refreshAccessibilityStatus(
      promptIfNeeded: true
    )
  }

  func refreshAccessibilityStatus(
    promptIfNeeded: Bool = false
  ) {
    if promptIfNeeded {
      let options =
        [
          "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary

      accessibilityGranted =
        AXIsProcessTrustedWithOptions(options)
    } else {
      accessibilityGranted =
        AXIsProcessTrusted()
    }
  }

  private func connect() {
    connectionTask?.cancel()

    connectionTask = Task { [weak self] in
      guard let self else {
        return
      }

      await self.performConnectionAttempt()
    }
  }

  private func performConnectionAttempt() async {
    guard isRunning else {
      return
    }

    let host = tabletHost.trimmingCharacters(
      in: .whitespacesAndNewlines
    )

    guard !host.isEmpty else {
      isConnected = false
      statusText = "Tablet IP is empty"
      return
    }

    statusText = "Connecting to \(host)"

    touchConnection?.stop()

    let connection = TouchConnection(
      host: host,
      port: 27183,
      onStateChange: { [weak self] state in
        Task { @MainActor in
          self?.handleConnectionState(state)
        }
      },
      onMessage: { [weak self] message in
        Task { @MainActor in
          self?.handleMessage(message)
        }
      }
    )

    touchConnection = connection
    connection.start()
  }

  private func handleConnectionState(
    _ state: TouchConnection.ConnectionState
  ) {
    guard isRunning else {
      return
    }

    switch state {
    case .setup:
      statusText = "Preparing connection"

    case .waiting(let message):
      isConnected = false
      statusText = "Waiting: \(message)"

    case .ready:
      isConnected = true
      statusText = "Connected"

    case .failed(let message):
      isConnected = false
      statusText = "Connection failed: \(message)"

      mouseController.releaseAllButtons()
      scheduleReconnect()

    case .cancelled:
      isConnected = false

      if isRunning {
        statusText = "Disconnected"

        mouseController.releaseAllButtons()
        scheduleReconnect()
      }
    }
  }

  private func scheduleReconnect() {
    guard isRunning else {
      return
    }

    reconnectTask?.cancel()

    reconnectTask = Task { [weak self] in
      do {
        try await Task.sleep(
          for: .seconds(2)
        )
      } catch {
        return
      }

      guard let self else {
        return
      }

      await self.performConnectionAttempt()
    }
  }

  private func handleMessage(
    _ message: TouchMessage
  ) {
    lastEventText = message.debugDescription

    switch message.type {
    case .hello:
      if let receivedDeviceName = message.deviceName,
        !receivedDeviceName.isEmpty
      {
        deviceName = receivedDeviceName
      }

      touchConnection?.sendReady()

    case .move:
      mouseController.move(
        dx: message.dx ?? 0,
        dy: message.dy ?? 0,
        dragging: false
      )

    case .tap:
      mouseController.leftClick()

    case .rightTap:
      mouseController.rightClick()

    case .scroll:
      mouseController.scroll(
        dx: message.dx ?? 0,
        dy: message.dy ?? 0
      )

    case .dragStart:
      mouseController.beginDrag()

    case .dragMove:
      mouseController.move(
        dx: message.dx ?? 0,
        dy: message.dy ?? 0,
        dragging: true
      )

    case .dragEnd:
      mouseController.endDrag()

    case .ping:
      touchConnection?.sendPong(
        sequence: message.sequence
      )

    case .pong:
      break

    case .ready:
      break

    case .error:
      statusText =
        message.message
        ?? "Android application error"

    case .unknown:
      break
    }
  }
}
