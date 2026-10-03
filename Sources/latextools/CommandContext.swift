import Foundation
import LaTeXToolsCore

struct CommandContext {
  let directory: URL
  let runner: any ProcessRunning
  let output: (String) -> Void
  let errorOutput: (String) -> Void

  init(
    directory: URL = URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
    runner: any ProcessRunning = SystemProcessRunner(),
    output: @escaping (String) -> Void = { print($0) },
    errorOutput: @escaping (String) -> Void = {
      FileHandle.standardError.write(Data(($0 + "\n").utf8))
    }
  ) {
    self.directory = directory
    self.runner = runner
    self.output = output
    self.errorOutput = errorOutput
  }

  func findProject() throws -> Project {
    guard let project = try ProjectStore.find(startingAt: directory) else {
      throw ProjectError.invalid("no project found")
    }
    return project
  }
}
