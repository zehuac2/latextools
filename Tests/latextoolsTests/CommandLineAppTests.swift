import ArgumentParser
import Foundation
import Testing

@testable import LaTeXToolsCore
@testable import latextools

struct CommandLineAppTests {
  @Test(arguments: ["-n", "--name"])
  func testNewNameOption(_ option: String) throws {
    let command = try #require(
      try CommandLineApp.parseAsRoot(["new", option, "project with spaces"]) as? NewCommand)
    #expect(command.name == "project with spaces")
  }

  @Test
  func testNewDefaultsToCurrentDirectory() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let command = try #require(try CommandLineApp.parseAsRoot(["new"]) as? NewCommand)
    #expect(command.name == nil)
    try command.run(in: CommandContext(directory: root, output: { _ in }))
    #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("index.tex").path))
  }

  @Test(arguments: [
    ["unknown"], ["new", "-n"], ["new", "--name"], ["new", "unexpected"],
    ["build", "unexpected"], ["clean", "--unknown"], ["export", "unexpected"],
    ["generate", "unexpected"], ["open", "unexpected"],
  ])
  func testInvalidArguments(_ arguments: [String]) throws {
    let caught = #expect(throws: (any Error).self) {
      try CommandLineApp.parseAsRoot(arguments)
    }
    let error = try #require(caught)
    #expect(CommandLineApp.exitCode(for: error) == .validationFailure)
    #expect(CommandLineApp.fullMessage(for: error).contains("Usage:"))
  }

  @Test(arguments: [
    ["--help"], ["-h"], ["help"], ["new", "--help"], ["build", "--help"],
    ["clean", "--help"], ["export", "--help"], ["generate", "--help"],
    ["open", "--help"], ["help", "new"],
  ])
  func testHelpExitsSuccessfully(_ arguments: [String]) throws {
    var command = try CommandLineApp.parseAsRoot(arguments)
    let caught = #expect(throws: (any Error).self) {
      try command.run()
    }
    let error = try #require(caught)
    #expect(CommandLineApp.exitCode(for: error) == .success)
    #expect(CommandLineApp.fullMessage(for: error).contains("USAGE: latextools"))
  }

  @Test
  func testRootDisplaysHelpWithoutRunningAProjectCommand() throws {
    var command = try CommandLineApp.parseAsRoot([])
    #expect(command is CommandLineApp)
    let caught = #expect(throws: (any Error).self) { try command.run() }
    let error = try #require(caught)
    #expect(CommandLineApp.exitCode(for: error) == .success)
    let help = CommandLineApp.fullMessage(for: error)
    #expect(help.contains("SUBCOMMANDS:"))
    #expect(help.contains("export, generate"))
  }

  @Test(arguments: ["export", "generate"])
  func testExportFromChildDirectory(_ name: String) throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let new = try #require(
      try CommandLineApp.parseAsRoot(["new", "--name", "named project"]) as? NewCommand)
    try new.run(in: CommandContext(directory: root, output: { _ in }))
    let named = root.appendingPathComponent("named project")
    let child = named.appendingPathComponent("child")
    try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
    let command = try #require(try CommandLineApp.parseAsRoot([name]) as? ExportCommand)
    var output: [String] = []
    try command.run(in: CommandContext(directory: child, output: { output.append($0) }))
    let makefileURL = named.appendingPathComponent("Makefile")
    let makefile = try String(contentsOf: makefileURL, encoding: .utf8)
    #expect(makefile.contains("\tlatextools build"))
    #expect(makefile.contains("\tlatextools clean"))
    #expect(output == ["Wrote \(makefileURL.path)"])
  }

  @Test
  func testBuildFailurePrintsFreshLogAndReportsError() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try ProjectStore.create(in: root)
    var errors: [String] = []
    let runner = FakeRunner()
    runner.action = { _, _ in
      try write("TeX log details", to: project.artifactURL(extension: "log"))
      throw ToolError(executable: "pdflatex", exitCode: 7)
    }
    let command = try #require(try CommandLineApp.parseAsRoot(["build"]) as? BuildCommand)
    let caught = #expect(throws: ToolError.self) {
      try command.run(
        in: CommandContext(
          directory: root, runner: runner, output: { _ in }, errorOutput: { errors.append($0) }))
    }
    let error = try #require(caught)
    #expect(errors == ["TeX log details"])
    #expect(CommandLineApp.exitCode(for: error) == .failure)
    #expect(CommandLineApp.fullMessage(for: error).contains("pdflatex exited with code 7"))
  }

  @Test
  func testBuildSuccessAndIncrementalOutput() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try ProjectStore.create(in: root)
    let runner = FakeRunner()
    runner.action = { _, _ in try write("PDF", to: project.pdfURL) }
    var output: [String] = []
    let context = CommandContext(directory: root, runner: runner, output: { output.append($0) })
    let command = try #require(try CommandLineApp.parseAsRoot(["build"]) as? BuildCommand)
    try command.run(in: context)
    #expect(output == ["Built \(project.pdfURL.path) in 1 LaTeX pass(es)"])

    try FileManager.default.setAttributes(
      [.modificationDate: Date(timeIntervalSince1970: 1_000_000_000)],
      ofItemAtPath: project.configurationURL.path)
    try FileManager.default.setAttributes(
      [.modificationDate: Date(timeIntervalSince1970: 1_000_000_000)],
      ofItemAtPath: project.entryURL.path)
    try FileManager.default.setAttributes(
      [.modificationDate: Date(timeIntervalSince1970: 1_000_000_100)],
      ofItemAtPath: project.pdfURL.path)

    try command.run(in: context)
    #expect(output.last == "No build needed")
    #expect(runner.calls.count == 1)
  }

  @Test
  func testClean() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try ProjectStore.create(in: root)
    try write("PDF", to: project.pdfURL)
    let command = try #require(try CommandLineApp.parseAsRoot(["clean"]) as? CleanCommand)
    var output: [String] = []
    try command.run(in: CommandContext(directory: root, output: { output.append($0) }))
    #expect(!FileManager.default.fileExists(atPath: project.outputDirectoryURL.path))
    #expect(output == ["Cleaned \(project.outputDirectoryURL.path)"])
    #expect(FileManager.default.fileExists(atPath: project.entryURL.path))
  }

  @Test
  func testOpenUsesPlatformViewerAndPreservesSpaces() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try ProjectStore.create(in: root, name: "project with spaces")
    let runner = FakeRunner()
    let command = try #require(try CommandLineApp.parseAsRoot(["open"]) as? OpenCommand)
    let context = CommandContext(directory: project.rootURL, runner: runner)
    #expect(throws: ProjectError.self) { try command.run(in: context) }
    #expect(runner.calls.isEmpty)
    try write("PDF", to: project.pdfURL)
    try command.run(in: context)
    let invocation = try #require(runner.calls.first)
    #if os(macOS)
      #expect(invocation.executable == "open")
    #elseif os(Windows)
      #expect(invocation.executable == "explorer.exe")
    #else
      #expect(invocation.executable == "xdg-open")
    #endif
    #expect(invocation.arguments == [project.pdfURL.path])
    #expect(invocation.workingDirectory == project.rootURL)
  }

  @Test
  func testMissingProjectReportsFailure() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let command = try #require(try CommandLineApp.parseAsRoot(["build"]) as? BuildCommand)
    let caught = #expect(throws: ProjectError.self) {
      try command.run(in: CommandContext(directory: root))
    }
    let error = try #require(caught)
    #expect(CommandLineApp.exitCode(for: error) == .failure)
    #expect(CommandLineApp.fullMessage(for: error).contains("no project found"))
  }
}
