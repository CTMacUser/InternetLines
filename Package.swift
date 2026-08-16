// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "InternetLines",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
  ],
  products: [
    // Products define the executables and libraries a package produces,
    // making them visible to other packages.
    .library(
      name: "InternetLines",
      targets: ["InternetLines"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-async-algorithms.git",
      .upToNextMajor(from: "1.1.5")
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package,
    // defining a module or a test suite.
    // Targets can depend on other targets in this package and products from
    // dependencies.
    .target(
      name: "InternetLines"
    ),
    .testTarget(
      name: "InternetLinesTests",
      dependencies: [
        "InternetLines",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
