// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Touchpad",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "Touchpad",
      targets: ["USBTouchpadMac"]
    )
  ],
  targets: [
    .executableTarget(
      name: "USBTouchpadMac",
      path: "Sources/USBTouchpadMac",
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "USBTouchpadMacTests",
      dependencies: ["USBTouchpadMac"],
      path: "Tests/USBTouchpadMacTests"
    ),
  ]
)
