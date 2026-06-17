// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "USBTouchpadMac",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "USBTouchpadMac",
      targets: ["USBTouchpadMac"]
    )
  ],
  targets: [
    .executableTarget(
      name: "USBTouchpadMac",
      path: "Sources/USBTouchpadMac"
    ),
    .testTarget(
      name: "USBTouchpadMacTests",
      dependencies: ["USBTouchpadMac"],
      path: "Tests/USBTouchpadMacTests"
    ),
  ]
)
