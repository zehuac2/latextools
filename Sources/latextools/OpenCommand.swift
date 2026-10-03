import ArgumentParser
import Foundation
import LaTeXToolsCore

struct OpenCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "open", abstract: "Open the nearest project's PDF in the default viewer.")

  mutating func run() throws {
    try run(in: CommandContext())
  }

  func run(in context: CommandContext) throws {
    let project = try context.findProject()

    guard FileManager.default.fileExists(atPath: project.pdfURL.path) else {
      throw ProjectError.invalid("PDF not found: \(project.pdfURL.path)")
    }

    #if os(macOS)
      let opener = "open"
    #elseif os(Windows)
      let opener = "explorer.exe"
    #else
      let opener = "xdg-open"
    #endif

    try context.runner.run(
      ToolInvocation(
        executable: opener,
        arguments: [project.pdfURL.path],
        workingDirectory: project.rootURL
      ))
  }
}
