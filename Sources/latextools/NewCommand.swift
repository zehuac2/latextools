import ArgumentParser
import LaTeXToolsCore

struct NewCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "new",
    abstract: "Create a LaTeX project in the current folder or a named subfolder.")

  @Option(name: .shortAndLong, help: "Create the project in a subfolder with this name.")
  var name: String?

  mutating func run() throws {
    try run(in: CommandContext())
  }

  func run(in context: CommandContext) throws {
    let project = try ProjectStore.create(in: context.directory, name: name)
    context.output("Created \(project.rootURL.path)")
  }
}
