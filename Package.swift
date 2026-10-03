// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "LaTeXTools",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "LaTeXToolsCore", targets: ["LaTeXToolsCore"]),
    .executable(name: "latextools", targets: ["latextools"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.8.2")
  ],
  targets: [
    .target(name: "LaTeXToolsCore"),
    .executableTarget(
      name: "latextools",
      dependencies: [
        "LaTeXToolsCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "LaTeXToolsCoreTests",
      dependencies: ["LaTeXToolsCore"],
      path: "Tests/LaTeXToolsCoreTests"
    ),
    .testTarget(name: "latextoolsTests", dependencies: ["latextools"]),
  ]
)
