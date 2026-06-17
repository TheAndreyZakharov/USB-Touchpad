import Foundation

struct TouchMessage: Codable, Sendable {
  enum MessageType: Sendable, Equatable {
    case hello
    case ready
    case move
    case tap
    case rightTap
    case scroll
    case dragStart
    case dragMove
    case dragEnd
    case ping
    case pong
    case error
    case unknown(String)

    init(rawValue: String) {
      switch rawValue {
      case "hello":
        self = .hello

      case "ready":
        self = .ready

      case "move":
        self = .move

      case "tap":
        self = .tap

      case "rightTap":
        self = .rightTap

      case "scroll":
        self = .scroll

      case "dragStart":
        self = .dragStart

      case "dragMove":
        self = .dragMove

      case "dragEnd":
        self = .dragEnd

      case "ping":
        self = .ping

      case "pong":
        self = .pong

      case "error":
        self = .error

      default:
        self = .unknown(rawValue)
      }
    }

    var rawValue: String {
      switch self {
      case .hello:
        return "hello"

      case .ready:
        return "ready"

      case .move:
        return "move"

      case .tap:
        return "tap"

      case .rightTap:
        return "rightTap"

      case .scroll:
        return "scroll"

      case .dragStart:
        return "dragStart"

      case .dragMove:
        return "dragMove"

      case .dragEnd:
        return "dragEnd"

      case .ping:
        return "ping"

      case .pong:
        return "pong"

      case .error:
        return "error"

      case .unknown(let value):
        return value
      }
    }
  }

  let version: Int
  let type: MessageType
  let sequence: Int?
  let timestamp: Int64?

  let dx: Double?
  let dy: Double?

  let deviceName: String?
  let androidVersion: String?
  let screenWidth: Int?
  let screenHeight: Int?

  let code: String?
  let message: String?

  enum CodingKeys: String, CodingKey {
    case version
    case type
    case sequence
    case timestamp
    case dx
    case dy
    case deviceName
    case androidVersion
    case screenWidth
    case screenHeight
    case code
    case message
  }

  init(
    version: Int = 1,
    type: MessageType,
    sequence: Int? = nil,
    timestamp: Int64? = nil,
    dx: Double? = nil,
    dy: Double? = nil,
    deviceName: String? = nil,
    androidVersion: String? = nil,
    screenWidth: Int? = nil,
    screenHeight: Int? = nil,
    code: String? = nil,
    message: String? = nil
  ) {
    self.version = version
    self.type = type
    self.sequence = sequence
    self.timestamp = timestamp
    self.dx = dx
    self.dy = dy
    self.deviceName = deviceName
    self.androidVersion = androidVersion
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.code = code
    self.message = message
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(
      keyedBy: CodingKeys.self
    )

    version =
      try container.decodeIfPresent(
        Int.self,
        forKey: .version
      ) ?? 1

    let rawType = try container.decode(
      String.self,
      forKey: .type
    )

    type = MessageType(rawValue: rawType)

    sequence = try container.decodeIfPresent(
      Int.self,
      forKey: .sequence
    )

    timestamp = try container.decodeIfPresent(
      Int64.self,
      forKey: .timestamp
    )

    dx = try container.decodeIfPresent(
      Double.self,
      forKey: .dx
    )

    dy = try container.decodeIfPresent(
      Double.self,
      forKey: .dy
    )

    deviceName = try container.decodeIfPresent(
      String.self,
      forKey: .deviceName
    )

    androidVersion = try container.decodeIfPresent(
      String.self,
      forKey: .androidVersion
    )

    screenWidth = try container.decodeIfPresent(
      Int.self,
      forKey: .screenWidth
    )

    screenHeight = try container.decodeIfPresent(
      Int.self,
      forKey: .screenHeight
    )

    code = try container.decodeIfPresent(
      String.self,
      forKey: .code
    )

    message = try container.decodeIfPresent(
      String.self,
      forKey: .message
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(
      keyedBy: CodingKeys.self
    )

    try container.encode(
      version,
      forKey: .version
    )

    try container.encode(
      type.rawValue,
      forKey: .type
    )

    try container.encodeIfPresent(
      sequence,
      forKey: .sequence
    )

    try container.encodeIfPresent(
      timestamp,
      forKey: .timestamp
    )

    try container.encodeIfPresent(
      dx,
      forKey: .dx
    )

    try container.encodeIfPresent(
      dy,
      forKey: .dy
    )

    try container.encodeIfPresent(
      deviceName,
      forKey: .deviceName
    )

    try container.encodeIfPresent(
      androidVersion,
      forKey: .androidVersion
    )

    try container.encodeIfPresent(
      screenWidth,
      forKey: .screenWidth
    )

    try container.encodeIfPresent(
      screenHeight,
      forKey: .screenHeight
    )

    try container.encodeIfPresent(
      code,
      forKey: .code
    )

    try container.encodeIfPresent(
      message,
      forKey: .message
    )
  }

  var debugDescription: String {
    switch type {
    case .move, .dragMove, .scroll:
      return "\(type.rawValue): dx=\(dx ?? 0), dy=\(dy ?? 0)"

    case .hello:
      return "hello: \(deviceName ?? "unknown device")"

    case .error:
      return "error: \(message ?? "unknown error")"

    default:
      return type.rawValue
    }
  }
}
