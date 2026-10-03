import Foundation
import Testing

@testable import LaTeXToolsCore

struct BuildPlanTests {
  @Test(arguments: [false, true], [false, true])
  func testPlanDeclaresConfiguredTools(bibliography: Bool, glossary: Bool) throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = Project(
      configurationURL: root.appendingPathComponent("latexproject.json"),
      configuration: .init(
        latex: "custom latex", bin: "build output", entry: "chapters/source file.tex",
        bib: bibliography ? .biber : .none, glossary: glossary
      )
    )
    let plan = BuildPlan(project: project)
    #expect(plan.latexInvocation.executable == "custom latex")
    #expect(
      plan.latexInvocation.arguments == [
        "-output-directory=\(project.outputDirectoryURL.path)", "-interaction=batchmode",
        project.entryURL.path,
      ])
    #expect(plan.latexInvocation.workingDirectory == project.rootURL)
    #expect(
      plan.helpers.map(\.invocation.executable) == (bibliography ? ["biber"] : [])
        + (glossary ? ["makeglossaries"] : []))
    for helper in plan.helpers {
      #expect(helper.invocation.workingDirectory == project.rootURL)
      if helper.invocation.executable == "biber" {
        #expect(helper.inputURL == project.artifactURL(extension: "bcf"))
        #expect(
          helper.invocation.arguments == [
            project.outputDirectoryURL.appendingPathComponent("source file").path
          ])
      } else {
        #expect(helper.inputURL == project.artifactURL(extension: "glo"))
        #expect(
          helper.invocation.arguments == ["-d", project.outputDirectoryURL.path, "source file"])
      }
    }
    #expect(plan.maximumPasses == 5)
    #expect(plan.requiredPDFURL == project.pdfURL)
    #expect(
      plan.referenceURLs.map(\.pathExtension) == ["aux", "toc", "out", "bcf", "glo", "glsdefs"])
    #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
  }
}
