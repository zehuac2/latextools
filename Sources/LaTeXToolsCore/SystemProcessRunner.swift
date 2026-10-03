import Foundation

public struct SystemProcessRunner: ProcessRunning {
  public init() {}

  public func run(_ invocation: ToolInvocation) throws {
    let process = Process()
    process.executableURL = try Self.resolve(
      invocation.executable, from: invocation.workingDirectory)
    process.arguments = invocation.arguments
    process.currentDirectoryURL = invocation.workingDirectory
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw ToolError(executable: invocation.executable, exitCode: process.terminationStatus)
    }
  }

  private static func resolve(_ name: String, from directory: URL) throws -> URL {
    let files = FileManager.default

    if name.contains("/") || name.contains("\\") {
      let url =
        (name as NSString).isAbsolutePath
        ? URL(fileURLWithPath: name)
        : URL(fileURLWithPath: name, relativeTo: directory)
      guard files.isExecutableFile(atPath: url.path) else {
        throw ProjectError.invalid("tool not executable: \(name)")
      }
      return url.standardizedFileURL
    }
    let environment = ProcessInfo.processInfo.environment
    #if os(Windows)
      let separator = ";"
      let extensions =
        [""]
        + (environment["PATHEXT"] ?? ".COM;.EXE;.BAT;.CMD")
        .split(separator: ";").map(String.init)
    #else
      let separator = ":"
      let extensions = [""]
    #endif

    for component in (environment["PATH"] ?? "").components(separatedBy: separator) {
      let folder = component.isEmpty ? directory : URL(fileURLWithPath: component)
      for suffix in extensions {
        let candidate = folder.appendingPathComponent(name + suffix)
        if files.isExecutableFile(atPath: candidate.path) { return candidate }
      }
    }

    throw ProjectError.invalid("tool not found in PATH: \(name)")
  }
}
