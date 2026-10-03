import ArgumentParser

@main
struct CommandLineApp: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "latextools",
    abstract: "Build LaTeX projects described by latexproject.json.",
    subcommands: [
      NewCommand.self, BuildCommand.self, CleanCommand.self, ExportCommand.self, OpenCommand.self,
    ]
  )
}
