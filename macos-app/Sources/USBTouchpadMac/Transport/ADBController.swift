import Foundation

struct ADBController: Sendable {
  enum ADBError: LocalizedError {
    case executableNotFound
    case commandFailed(
      arguments: [String],
      exitCode: Int32,
      output: String
    )
    case noDevice
    case multipleDevices

    var errorDescription: String? {
      switch self {
      case .executableNotFound:
        return "ADB executable was not found"

      case .commandFailed(
        let arguments,
        let exitCode,
        let output
      ):
        let command = arguments.joined(separator: " ")

        return """
          adb \(command) failed with code \(exitCode): \(output)
          """

      case .noDevice:
        return "No Android device is connected"

      case .multipleDevices:
        return "More than one Android device is connected"
      }
    }
  }

  struct CommandResult: Sendable {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String
  }

  func detectDevice() async throws -> String {
    let result = try await runADB(
      arguments: ["devices", "-l"]
    )

    guard result.exitCode == 0 else {
      throw ADBError.commandFailed(
        arguments: ["devices", "-l"],
        exitCode: result.exitCode,
        output: result.combinedOutput
      )
    }

    let deviceLines = result.standardOutput
      .split(separator: "\n")
      .dropFirst()
      .map(String.init)
      .filter { line in
        let columns = line.split(
          whereSeparator: \.isWhitespace
        )

        return columns.count >= 2
          && columns[1] == "device"
      }

    guard !deviceLines.isEmpty else {
      throw ADBError.noDevice
    }

    guard deviceLines.count == 1 else {
      throw ADBError.multipleDevices
    }

    let line = deviceLines[0]

    if let modelRange = line.range(of: "model:") {
      let modelPart = line[modelRange.upperBound...]

      if let spaceIndex = modelPart.firstIndex(
        where: \.isWhitespace
      ) {
        return String(modelPart[..<spaceIndex])
          .replacingOccurrences(
            of: "_",
            with: " "
          )
      }

      return String(modelPart)
        .replacingOccurrences(
          of: "_",
          with: " "
        )
    }

    return
      line
      .split(whereSeparator: \.isWhitespace)
      .first
      .map(String.init) ?? "Android device"
  }

  func configurePortForwarding(
    localPort: UInt16,
    remotePort: UInt16
  ) async throws {
    let arguments = [
      "forward",
      "tcp:\(localPort)",
      "tcp:\(remotePort)",
    ]

    let result = try await runADB(
      arguments: arguments
    )

    guard result.exitCode == 0 else {
      throw ADBError.commandFailed(
        arguments: arguments,
        exitCode: result.exitCode,
        output: result.combinedOutput
      )
    }
  }

  func removePortForwarding(
    localPort: UInt16
  ) async throws {
    let arguments = [
      "forward",
      "--remove",
      "tcp:\(localPort)",
    ]

    let result = try await runADB(
      arguments: arguments
    )

    guard result.exitCode == 0 else {
      throw ADBError.commandFailed(
        arguments: arguments,
        exitCode: result.exitCode,
        output: result.combinedOutput
      )
    }
  }

  private func runADB(
    arguments: [String]
  ) async throws -> CommandResult {
    try await Task.detached(priority: .utility) {
      guard let executableURL = Self.findADBExecutable() else {
        throw ADBError.executableNotFound
      }

      let process = Process()
      let outputPipe = Pipe()
      let errorPipe = Pipe()

      process.executableURL = executableURL
      process.arguments = arguments
      process.standardOutput = outputPipe
      process.standardError = errorPipe

      var environment = ProcessInfo.processInfo.environment
      environment["ADB_LIBUSB"] = "0"
      process.environment = environment

      try process.run()
      process.waitUntilExit()

      let outputData = outputPipe
        .fileHandleForReading
        .readDataToEndOfFile()

      let errorData = errorPipe
        .fileHandleForReading
        .readDataToEndOfFile()

      return CommandResult(
        exitCode: process.terminationStatus,
        standardOutput: String(
          data: outputData,
          encoding: .utf8
        ) ?? "",
        standardError: String(
          data: errorData,
          encoding: .utf8
        ) ?? ""
      )
    }.value
  }

  private static func findADBExecutable() -> URL? {
    let environment = ProcessInfo.processInfo.environment
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    var candidates: [URL] = []

    if let androidHome = environment["ANDROID_HOME"] {
      candidates.append(
        URL(fileURLWithPath: androidHome)
          .appendingPathComponent("platform-tools/adb")
      )
    }

    candidates.append(
      homeDirectory
        .appendingPathComponent(
          "Library/Android/sdk/platform-tools/adb"
        )
    )

    candidates.append(
      URL(fileURLWithPath: "/opt/homebrew/bin/adb")
    )

    candidates.append(
      URL(fileURLWithPath: "/usr/local/bin/adb")
    )

    return candidates.first { url in
      FileManager.default.isExecutableFile(
        atPath: url.path
      )
    }
  }
}

extension ADBController.CommandResult {
  fileprivate var combinedOutput: String {
    let parts = [
      standardOutput.trimmingCharacters(
        in: .whitespacesAndNewlines
      ),
      standardError.trimmingCharacters(
        in: .whitespacesAndNewlines
      ),
    ]
    .filter { !$0.isEmpty }

    return parts.joined(separator: "\n")
  }
}
