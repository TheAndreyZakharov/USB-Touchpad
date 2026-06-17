import Foundation
import Testing

@testable import USBTouchpadMac

struct TouchMessageTests {
  @Test
  func decodesMoveMessage() throws {
    let json = """
      {
        "version": 1,
        "type": "move",
        "sequence": 42,
        "timestamp": 1000,
        "dx": 12.5,
        "dy": -3.25
      }
      """

    let message = try JSONDecoder().decode(
      TouchMessage.self,
      from: Data(json.utf8)
    )

    #expect(message.version == 1)
    #expect(message.type == .move)
    #expect(message.sequence == 42)
    #expect(message.timestamp == 1000)
    #expect(message.dx == 12.5)
    #expect(message.dy == -3.25)
  }

  @Test
  func decodesHelloMessage() throws {
    let json = """
      {
        "version": 1,
        "type": "hello",
        "sequence": 1,
        "timestamp": 500,
        "deviceName": "3Q Surf RC9716B-DG",
        "androidVersion": "4.0.4",
        "screenWidth": 1024,
        "screenHeight": 768
      }
      """

    let message = try JSONDecoder().decode(
      TouchMessage.self,
      from: Data(json.utf8)
    )

    #expect(message.type == .hello)
    #expect(message.deviceName == "3Q Surf RC9716B-DG")
    #expect(message.androidVersion == "4.0.4")
    #expect(message.screenWidth == 1024)
    #expect(message.screenHeight == 768)
  }

  @Test
  func preservesUnknownMessageType() throws {
    let json = """
      {
        "version": 1,
        "type": "futureEvent"
      }
      """

    let message = try JSONDecoder().decode(
      TouchMessage.self,
      from: Data(json.utf8)
    )

    #expect(
      message.type == .unknown("futureEvent")
    )
  }

  @Test
  func encodesReadyMessage() throws {
    let message = TouchMessage(
      type: .ready,
      sequence: 2,
      timestamp: 1500
    )

    let data = try JSONEncoder().encode(message)

    let object = try #require(
      JSONSerialization.jsonObject(
        with: data
      ) as? [String: Any]
    )

    #expect(object["version"] as? Int == 1)
    #expect(object["type"] as? String == "ready")
    #expect(object["sequence"] as? Int == 2)
  }
}
