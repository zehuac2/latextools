@testable import LaTeXToolsCore

struct BuildHelperScenario: Sendable {
  let configuration: ProjectConfiguration
  let inputExtension: String
  let executable: String

  static let all: [BuildHelperScenario] = [
    .init(configuration: .init(bib: .biber), inputExtension: "bcf", executable: "biber"),
    .init(
      configuration: .init(glossary: true), inputExtension: "glo", executable: "makeglossaries"),
  ]
}
