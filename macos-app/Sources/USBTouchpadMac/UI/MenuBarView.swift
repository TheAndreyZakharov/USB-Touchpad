import AppKit
import SwiftUI

struct MenuBarView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 14
    ) {
      header

      Divider()

      connectionSection

      Divider()

      settingsSection

      Divider()

      accessibilitySection

      Divider()

      footer
    }
    .padding(16)
    .frame(width: 360)
    .task {
      appState.start()
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      Image(
        systemName: appState.isConnected
          ? "wifi"
          : "wifi.slash"
      )
      .font(.title2)
      .foregroundStyle(
        appState.isConnected
          ? Color.green
          : Color.secondary
      )

      VStack(
        alignment: .leading,
        spacing: 2
      ) {
        Text("Touchpad")
          .font(.headline)

        Text(appState.statusText)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer()
    }
  }

  private var connectionSection: some View {
    VStack(
      alignment: .leading,
      spacing: 10
    ) {
      Text("Tablet connection")
        .font(.subheadline)
        .fontWeight(.semibold)

      HStack {
        Text("IP address")

        TextField(
          "192.168.43.1",
          text: $appState.tabletHost
        )
        .textFieldStyle(.roundedBorder)
        .frame(width: 160)
        .onSubmit {
          appState.reconnect()
        }
      }

      row(
        title: "Port",
        value: "27183"
      )

      row(
        title: "Device",
        value: appState.deviceName
      )

      row(
        title: "Connection",
        value: appState.isConnected
          ? "Connected"
          : "Disconnected"
      )

      row(
        title: "Last event",
        value: appState.lastEventText
      )

      HStack {
        if appState.isRunning {
          Button("Reconnect") {
            appState.reconnect()
          }

          Button("Stop") {
            appState.stop()
          }
        } else {
          Button("Start") {
            appState.start()
          }
        }

        Spacer()
      }
    }
  }

  private var settingsSection: some View {
    VStack(
      alignment: .leading,
      spacing: 12
    ) {
      Text("Pointer")
        .font(.subheadline)
        .fontWeight(.semibold)

      VStack(
        alignment: .leading,
        spacing: 4
      ) {
        HStack {
          Text("Sensitivity")

          Spacer()

          Text(
            appState.sensitivity,
            format: .number.precision(
              .fractionLength(1)
            )
          )
          .monospacedDigit()
          .foregroundStyle(.secondary)
        }

        Slider(
          value: $appState.sensitivity,
          in: 0.3...4.0,
          step: 0.1
        )
      }

      VStack(
        alignment: .leading,
        spacing: 4
      ) {
        HStack {
          Text("Scroll sensitivity")

          Spacer()

          Text(
            appState.scrollSensitivity,
            format: .number.precision(
              .fractionLength(1)
            )
          )
          .monospacedDigit()
          .foregroundStyle(.secondary)
        }

        Slider(
          value: $appState.scrollSensitivity,
          in: 0.2...3.0,
          step: 0.1
        )
      }

      Toggle(
        "Natural scrolling",
        isOn: $appState.naturalScrolling
      )
    }
  }

  private var accessibilitySection: some View {
    VStack(
      alignment: .leading,
      spacing: 8
    ) {
      HStack {
        Image(
          systemName:
            appState.accessibilityGranted
            ? "checkmark.shield.fill"
            : "exclamationmark.triangle.fill"
        )
        .foregroundStyle(
          appState.accessibilityGranted
            ? Color.green
            : Color.orange
        )

        Text(
          appState.accessibilityGranted
            ? "Accessibility permission granted"
            : "Accessibility permission required"
        )
        .font(.caption)
      }

      if !appState.accessibilityGranted {
        Text(
          "Permission is required to move the cursor and generate clicks."
        )
        .font(.caption)
        .foregroundStyle(.secondary)

        HStack {
          Button("Request permission") {
            appState.requestAccessibilityPermission()
          }

          Button("Open Settings") {
            openAccessibilitySettings()
          }
        }
      } else {
        Button("Refresh permission") {
          appState.refreshAccessibilityStatus()
        }
      }
    }
  }

  private var footer: some View {
    HStack {
      Button("Reconnect") {
        appState.reconnect()
      }

      Spacer()

      Button("Quit") {
        appState.stop()
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q")
    }
  }

  private func row(
    title: String,
    value: String
  ) -> some View {
    HStack(
      alignment: .firstTextBaseline
    ) {
      Text(title)
        .foregroundStyle(.secondary)

      Spacer()

      Text(value)
        .multilineTextAlignment(.trailing)
        .lineLimit(2)
        .textSelection(.enabled)
    }
    .font(.caption)
  }

  private func openAccessibilitySettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    else {
      return
    }

    NSWorkspace.shared.open(url)
  }
}
