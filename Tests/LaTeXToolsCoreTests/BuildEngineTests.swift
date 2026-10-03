import Foundation
import Testing

@testable import LaTeXToolsCore

struct BuildEngineTests {
  @Test
  func testBuildHelpersConvergenceAndIncrementalSkip() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let config = ProjectConfiguration(
      bin: "build output", entry: "source file.tex", bib: .biber, glossary: true,
      includes: ["chapters"])
    let project = try project(in: root, configuration: config)
    try write("chapter", to: root.appendingPathComponent("chapters/one.tex"))
    let runner = FakeRunner()
    runner.action = { invocation, _ in
      if invocation.executable == "pdflatex" {
        try write("pdf", to: project.pdfURL)
        try write("aux", to: project.artifactURL(extension: "aux"))
        try write("bcf", to: project.artifactURL(extension: "bcf"))
        try write("glo", to: project.artifactURL(extension: "glo"))
      }
    }
    let engine = BuildEngine(runner: runner)
    #expect(try engine.build(project) == .built(latexPasses: 2))
    #expect(runner.calls.map(\.executable) == ["pdflatex", "biber", "makeglossaries", "pdflatex"])
    #expect(runner.calls[0].workingDirectory.path == root.path)
    #expect(runner.calls[0].arguments.last == project.entryURL.path)
    #expect(runner.calls[1].arguments.count == 1)
    let inputDate = Date(timeIntervalSince1970: 1_000_000)
    let inputs = [
      project.configurationURL, project.entryURL, root.appendingPathComponent("chapters/one.tex"),
    ]
    for input in inputs {
      try FileManager.default.setAttributes(
        [.modificationDate: inputDate], ofItemAtPath: input.path)
    }
    try FileManager.default.setAttributes(
      [.modificationDate: inputDate.addingTimeInterval(1)], ofItemAtPath: project.pdfURL.path)
    #expect(try engine.build(project) == .upToDate)
    #expect(runner.calls.count == 4)
  }

  @Test(arguments: BuildHelperScenario.all, BuildPassScenario.all)
  func testHelperScheduling(helper: BuildHelperScenario, scenario: BuildPassScenario) throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try project(in: root, configuration: helper.configuration)
    let runner = FakeRunner()
    var pass = 0
    runner.action = { invocation, _ in
      if invocation.executable == "pdflatex" {
        let contents = scenario.inputContents[pass]
        pass += 1
        try write("pdf", to: project.pdfURL)
        try write(contents, to: project.artifactURL(extension: helper.inputExtension))
      }
    }
    let engine = BuildEngine(runner: runner)
    if let expectedPasses = scenario.expectedPasses {
      #expect(try engine.build(project) == .built(latexPasses: expectedPasses))
    } else {
      let error = #expect(throws: ProjectError.self) { try engine.build(project) }
      #expect(error?.localizedDescription.contains("did not stabilize") == true)
    }
    #expect(pass == scenario.inputContents.count)
    #expect(
      runner.calls.map(\.executable)
        == scenario.expectedInvocations.map {
          $0 == "helper" ? helper.executable : $0
        })
  }

  @Test(arguments: BuildHelperScenario.all)
  func testMissingHelperInputFailsBeforeLaunchingHelper(_ helper: BuildHelperScenario) throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try project(in: root, configuration: helper.configuration)
    let runner = FakeRunner()
    runner.action = { _, _ in try write("pdf", to: project.pdfURL) }
    #expect(throws: (any Error).self) { try BuildEngine(runner: runner).build(project) }
    #expect(runner.calls.map(\.executable) == ["pdflatex"])
  }

  @Test(arguments: BuildHelperScenario.all)
  func testHelperFailureStopsBuild(_ helper: BuildHelperScenario) throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try project(in: root, configuration: helper.configuration)
    let runner = FakeRunner()
    runner.action = { invocation, _ in
      if invocation.executable == helper.executable {
        throw ToolError(executable: helper.executable, exitCode: 2)
      }
      try write("pdf", to: project.pdfURL)
      try write("input", to: project.artifactURL(extension: helper.inputExtension))
    }
    let error = #expect(throws: ToolError.self) { try BuildEngine(runner: runner).build(project) }
    #expect(error?.exitCode == 2)
    #expect(runner.calls.map(\.executable) == ["pdflatex", helper.executable])
  }

  @Test
  func testValidationProcessFailureAndSafeClean() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let invalid = try project(in: root, configuration: .init(includes: ["missing.tex"]))
    let runner = FakeRunner()
    #expect(throws: (any Error).self) {
      try BuildEngine(runner: runner).build(invalid)
    }
    #expect(runner.calls.isEmpty)

    let valid = try project(in: root)
    runner.action = { _, _ in throw ToolError(executable: "pdflatex", exitCode: 2) }
    let error = #expect(throws: ToolError.self) {
      try BuildEngine(runner: runner).build(valid)
    }
    #expect(error?.exitCode == 2)
    try FileManager.default.createDirectory(
      at: valid.outputDirectoryURL, withIntermediateDirectories: true)
    try BuildEngine(runner: runner).clean(valid)
    #expect(!FileManager.default.fileExists(atPath: valid.outputDirectoryURL.path))
    let unsafe = Project(configurationURL: valid.configurationURL, configuration: .init(bin: ".."))
    #expect(throws: (any Error).self) {
      try BuildEngine(runner: runner).clean(unsafe)
    }
    #expect(FileManager.default.fileExists(atPath: root.path))
  }

  @Test
  func testMissingPDFIsAnError() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try project(in: root)
    #expect(throws: ProjectError.self) {
      try BuildEngine(runner: FakeRunner()).build(project)
    }
  }

  @Test
  func testIncludedDirectoryUpdatesTriggerRebuildButOutputDoesNot() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try project(
      in: root, configuration: .init(bin: "assets/output", includes: ["assets"]))
    let included = root.appendingPathComponent("assets/chapter.tex")
    try write("chapter", to: included)
    let runner = FakeRunner()
    runner.action = { invocation, _ in
      if invocation.executable == "pdflatex" {
        try write("pdf", to: project.pdfURL)
      }
    }
    let engine = BuildEngine(runner: runner)
    #expect(try engine.build(project) == .built(latexPasses: 1))

    let inputDate = Date(timeIntervalSince1970: 1_000_000)
    for input in [project.configurationURL, project.entryURL, included] {
      try FileManager.default.setAttributes(
        [.modificationDate: inputDate], ofItemAtPath: input.path)
    }
    try FileManager.default.setAttributes(
      [.modificationDate: inputDate.addingTimeInterval(1)], ofItemAtPath: project.pdfURL.path)
    #expect(try engine.build(project) == .upToDate)

    try write("artifact", to: project.outputDirectoryURL.appendingPathComponent("extra.txt"))
    #expect(try engine.build(project) == .upToDate)

    try write("updated", to: included)
    try FileManager.default.setAttributes(
      [.modificationDate: inputDate.addingTimeInterval(2)], ofItemAtPath: included.path)
    #expect(try engine.build(project) == .built(latexPasses: 1))
  }
}
