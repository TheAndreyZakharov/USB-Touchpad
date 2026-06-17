import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
final class MouseController {
  var sensitivity: Double = 1.5
  var scrollSensitivity: Double = 1.0
  var naturalScrolling = true

  private var isDragging = false

  func move(
    dx: Double,
    dy: Double,
    dragging: Bool
  ) {
    guard AXIsProcessTrusted() else {
      return
    }

    guard let currentLocation = CGEvent(source: nil)?.location else {
      return
    }

    let newLocation = CGPoint(
      x: currentLocation.x + CGFloat(dx * sensitivity),
      y: currentLocation.y + CGFloat(dy * sensitivity)
    )

    let eventType: CGEventType

    if dragging || isDragging {
      eventType = .leftMouseDragged
    } else {
      eventType = .mouseMoved
    }

    guard
      let event = CGEvent(
        mouseEventSource: nil,
        mouseType: eventType,
        mouseCursorPosition: newLocation,
        mouseButton: .left
      )
    else {
      return
    }

    event.post(tap: .cghidEventTap)
  }

  func leftClick() {
    guard AXIsProcessTrusted() else {
      return
    }

    postClick(
      button: .left,
      downType: .leftMouseDown,
      upType: .leftMouseUp
    )
  }

  func rightClick() {
    guard AXIsProcessTrusted() else {
      return
    }

    postClick(
      button: .right,
      downType: .rightMouseDown,
      upType: .rightMouseUp
    )
  }

  func beginDrag() {
    guard AXIsProcessTrusted() else {
      return
    }

    guard !isDragging else {
      return
    }

    guard let location = CGEvent(source: nil)?.location else {
      return
    }

    guard
      let event = CGEvent(
        mouseEventSource: nil,
        mouseType: .leftMouseDown,
        mouseCursorPosition: location,
        mouseButton: .left
      )
    else {
      return
    }

    isDragging = true
    event.post(tap: .cghidEventTap)
  }

  func endDrag() {
    guard isDragging else {
      return
    }

    guard let location = CGEvent(source: nil)?.location else {
      isDragging = false
      return
    }

    let event = CGEvent(
      mouseEventSource: nil,
      mouseType: .leftMouseUp,
      mouseCursorPosition: location,
      mouseButton: .left
    )

    event?.post(tap: .cghidEventTap)
    isDragging = false
  }

  func releaseAllButtons() {
    endDrag()
  }

  func scroll(
    dx: Double,
    dy: Double
  ) {
    guard AXIsProcessTrusted() else {
      return
    }

    let direction: Double = naturalScrolling ? -1 : 1

    let horizontalValue = Int32(
      (dx * scrollSensitivity * direction)
        .rounded()
        .clamped(
          to: Double(Int32.min)...Double(Int32.max)
        )
    )

    let verticalValue = Int32(
      (dy * scrollSensitivity * direction)
        .rounded()
        .clamped(
          to: Double(Int32.min)...Double(Int32.max)
        )
    )

    guard horizontalValue != 0 || verticalValue != 0 else {
      return
    }

    let event = CGEvent(
      scrollWheelEvent2Source: nil,
      units: .pixel,
      wheelCount: 2,
      wheel1: verticalValue,
      wheel2: horizontalValue,
      wheel3: 0
    )

    event?.post(tap: .cghidEventTap)
  }

  private func postClick(
    button: CGMouseButton,
    downType: CGEventType,
    upType: CGEventType
  ) {
    guard let location = CGEvent(source: nil)?.location else {
      return
    }

    let downEvent = CGEvent(
      mouseEventSource: nil,
      mouseType: downType,
      mouseCursorPosition: location,
      mouseButton: button
    )

    let upEvent = CGEvent(
      mouseEventSource: nil,
      mouseType: upType,
      mouseCursorPosition: location,
      mouseButton: button
    )

    downEvent?.post(tap: .cghidEventTap)
    upEvent?.post(tap: .cghidEventTap)
  }
}

extension Comparable {
  fileprivate func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}
