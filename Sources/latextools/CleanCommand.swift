import ArgumentParser
import LaTeXToolsCore

struct CleanCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "clean", abstract: "Remove the nearest project's output directory.")

  mutating func run() throws {
    try run(in: CommandContext())
  }

  func run(in context: CommandContext) throws {
    let project = try context.findProject()
    try BuildEngine(runner: context.runner).clean(project)
    context.output("Cleaned \(project.outputDirectoryURL.path)")
  }
}
