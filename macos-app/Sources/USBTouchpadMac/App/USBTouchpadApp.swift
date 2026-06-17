import AppKit
import SwiftUI

@main
struct USBTouchpadApp: App {
  @StateObject private var appState = AppState()

  init() {
    configureApplicationIcon()
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarView()
        .environmentObject(appState)
    } label: {
      Image(
        systemName: appState.isConnected
          ? "rectangle.connected.to.line.below"
          : "rectangle.dashed"
      )
      .accessibilityLabel("USB Touchpad")
    }
    .menuBarExtraStyle(.window)
  }

  private func configureApplicationIcon() {
    guard
      let iconURL = Bundle.module.url(
        forResource: "app-icon",
        withExtension: "png"
      )
    else {
      return
    }

    guard
      let iconImage = NSImage(
        contentsOf: iconURL
      )
    else {
      return
    }

    NSApplication.shared.applicationIconImage = iconImage
  }
}
