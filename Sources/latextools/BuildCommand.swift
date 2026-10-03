import ArgumentParser
import Foundation
import LaTeXToolsCore

struct BuildCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "build", abstract: "Build the nearest LaTeX project when its inputs have changed.")

  mutating func run() throws {
    try run(in: CommandContext())
  }

  func run(in context: CommandContext) throws {
    let project = try context.findProject()
    let log = project.artifactURL(extension: "log")
    let priorLogDate =
      try? FileManager.default.attributesOfItem(atPath: log.path)[.modificationDate] as? Date

    do {
      switch try BuildEngine(runner: context.runner).build(project) {
      case .upToDate: context.output("No build needed")
      case .built(let passes):
        context.output("Built \(project.pdfURL.path) in \(passes) LaTeX pass(es)")
      }
    } catch {
      let currentLogDate =
        try? FileManager.default.attributesOfItem(atPath: log.path)[.modificationDate] as? Date

      if currentLogDate != nil, currentLogDate != priorLogDate,
        let contents = try? String(contentsOf: log, encoding: .utf8)
      {
        context.errorOutput(contents)
      }
      throw error
    }
  }
}
