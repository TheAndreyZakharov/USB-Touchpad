import SwiftUI

@main
struct USBTouchpadApp: App {
  @StateObject private var appState = AppState()

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
}
