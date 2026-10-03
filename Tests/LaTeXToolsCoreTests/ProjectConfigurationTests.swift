import Foundation
import Testing

@testable import LaTeXToolsCore

struct ProjectConfigurationTests {
  @Test(arguments: [
    "{}",
    #"{"latex":null,"bin":null,"entry":null,"bib":null,"glossary":null,"includes":null}"#,
  ])
  func testJSONDefaults(_ json: String) throws {
    let configuration = try JSONDecoder().decode(ProjectConfiguration.self, from: Data(json.utf8))
    #expect(configuration.latex == "pdflatex")
    #expect(configuration.bin == "bin")
    #expect(configuration.entry == "index.tex")
    #expect(configuration.bib == .none)
    #expect(!configuration.glossary)
    #expect(configuration.includes == [])
  }

  @Test
  func testExplicitConfigurationRoundTrips() throws {
    let original = ProjectConfiguration(
      latex: "xelatex", bin: "build output", entry: "main.tex", bib: .biber,
      glossary: true, includes: ["chapters"])
    let decoded = try JSONDecoder().decode(
      ProjectConfiguration.self, from: JSONEncoder().encode(original))
    #expect(decoded.latex == original.latex)
    #expect(decoded.bin == original.bin)
    #expect(decoded.entry == original.entry)
    #expect(decoded.bib == original.bib)
    #expect(decoded.glossary == original.glossary)
    #expect(decoded.includes == original.includes)
  }
}
