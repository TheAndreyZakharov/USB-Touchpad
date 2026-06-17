import Foundation
import Network

final class TouchConnection: @unchecked Sendable {
  enum ConnectionState: Sendable {
    case setup
    case waiting(String)
    case ready
    case failed(String)
    case cancelled
  }

  private let host: NWEndpoint.Host
  private let port: NWEndpoint.Port

  private let queue = DispatchQueue(
    label: "com.theandreyzakharov.usbtouchpad.connection",
    qos: .userInteractive
  )

  private let onStateChange: @Sendable (ConnectionState) -> Void

  private let onMessage: @Sendable (TouchMessage) -> Void

  private var connection: NWConnection?
  private var receiveBuffer = Data()
  private var didReportDisconnection = false
  private var outgoingSequence = 1

  init(
    host: String,
    port: UInt16,
    onStateChange:
      @escaping @Sendable (ConnectionState) -> Void,
    onMessage:
      @escaping @Sendable (TouchMessage) -> Void
  ) {
    self.host = NWEndpoint.Host(host)
    self.port = NWEndpoint.Port(rawValue: port)!
    self.onStateChange = onStateChange
    self.onMessage = onMessage
  }

  func start() {
    queue.async { [weak self] in
      self?.startOnQueue()
    }
  }

  func stop() {
    queue.async { [weak self] in
      guard let self else {
        return
      }

      self.connection?.cancel()
      self.connection = nil
      self.receiveBuffer.removeAll(
        keepingCapacity: false
      )

      self.reportDisconnectionIfNeeded()
    }
  }

  func sendReady() {
    send(
      TouchMessage(
        type: .ready,
        sequence: nextSequence(),
        timestamp: monotonicMilliseconds()
      )
    )
  }

  func sendPong(sequence: Int?) {
    send(
      TouchMessage(
        type: .pong,
        sequence: sequence ?? nextSequence(),
        timestamp: monotonicMilliseconds()
      )
    )
  }

  private func startOnQueue() {
    didReportDisconnection = false
    receiveBuffer.removeAll(keepingCapacity: true)

    let newConnection = NWConnection(
      host: host,
      port: port,
      using: .tcp
    )

    connection = newConnection

    newConnection.stateUpdateHandler = {
      [weak self] state in

      guard let self else {
        return
      }

      self.queue.async {
        self.handleNetworkState(state)
      }
    }

    onStateChange(.setup)

    newConnection.start(queue: queue)
    receiveNextChunk()
  }

  private func handleNetworkState(
    _ state: NWConnection.State
  ) {
    switch state {
    case .setup:
      onStateChange(.setup)

    case .preparing:
      onStateChange(.setup)

    case .waiting(let error):
      onStateChange(
        .waiting(error.localizedDescription)
      )

    case .ready:
      didReportDisconnection = false
      onStateChange(.ready)

    case .failed(let error):
      onStateChange(
        .failed(error.localizedDescription)
      )

      connection?.cancel()
      connection = nil
      reportDisconnectionIfNeeded()

    case .cancelled:
      connection = nil
      reportDisconnectionIfNeeded()

    @unknown default:
      onStateChange(
        .failed("Unknown network state")
      )

      connection?.cancel()
      connection = nil
      reportDisconnectionIfNeeded()
    }
  }

  private func receiveNextChunk() {
    guard let connection else {
      return
    }

    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: 65_536
    ) { [weak self] data, _, isComplete, error in
      guard let self else {
        return
      }

      self.queue.async {
        if let data, !data.isEmpty {
          self.receiveBuffer.append(data)
          self.processReceiveBuffer()
        }

        if let error {
          self.onStateChange(
            .failed(error.localizedDescription)
          )

          self.connection?.cancel()
          self.connection = nil
          self.reportDisconnectionIfNeeded()
          return
        }

        if isComplete {
          self.connection?.cancel()
          self.connection = nil
          self.reportDisconnectionIfNeeded()
          return
        }

        self.receiveNextChunk()
      }
    }
  }

  private func processReceiveBuffer() {
    let newlineByte = UInt8(ascii: "\n")

    while let newlineIndex = receiveBuffer.firstIndex(
      of: newlineByte
    ) {
      let lineData = receiveBuffer[
        receiveBuffer.startIndex..<newlineIndex
      ]

      let nextIndex = receiveBuffer.index(
        after: newlineIndex
      )

      receiveBuffer.removeSubrange(
        receiveBuffer.startIndex..<nextIndex
      )

      guard !lineData.isEmpty else {
        continue
      }

      decodeLine(Data(lineData))
    }
  }

  private func decodeLine(_ data: Data) {
    do {
      let message = try JSONDecoder().decode(
        TouchMessage.self,
        from: data
      )

      guard message.version == 1 else {
        sendProtocolError(
          code: "unsupported_version",
          message: "Unsupported protocol version \(message.version)"
        )

        return
      }

      onMessage(message)
    } catch {
      sendProtocolError(
        code: "invalid_message",
        message: error.localizedDescription
      )
    }
  }

  private func sendProtocolError(
    code: String,
    message: String
  ) {
    send(
      TouchMessage(
        type: .error,
        sequence: nextSequence(),
        timestamp: monotonicMilliseconds(),
        code: code,
        message: message
      )
    )
  }

  private func send(_ message: TouchMessage) {
    queue.async { [weak self] in
      guard let self,
        let connection = self.connection
      else {
        return
      }

      do {
        var data = try JSONEncoder().encode(message)
        data.append(UInt8(ascii: "\n"))

        connection.send(
          content: data,
          completion: .contentProcessed {
            [weak self] error in

            guard let self,
              let error
            else {
              return
            }

            self.queue.async {
              self.onStateChange(
                .failed(error.localizedDescription)
              )

              self.connection?.cancel()
              self.connection = nil
              self.reportDisconnectionIfNeeded()
            }
          }
        )
      } catch {
        self.onStateChange(
          .failed(error.localizedDescription)
        )
      }
    }
  }

  private func nextSequence() -> Int {
    let sequence = outgoingSequence
    outgoingSequence += 1
    return sequence
  }

  private func monotonicMilliseconds() -> Int64 {
    Int64(
      ProcessInfo.processInfo.systemUptime * 1_000
    )
  }

  private func reportDisconnectionIfNeeded() {
    guard !didReportDisconnection else {
      return
    }

    didReportDisconnection = true
    onStateChange(.cancelled)
  }
}
