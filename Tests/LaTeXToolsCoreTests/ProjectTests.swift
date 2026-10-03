import Foundation
import Testing

@testable import LaTeXToolsCore

struct ProjectTests {
  @Test
  func testPathsWithSpaces() throws {
    let temporaryRoot = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }
    let root = temporaryRoot.appendingPathComponent("a project")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let config = ProjectConfiguration(bin: "build output", entry: "source file.tex")
    let original = try project(in: root, configuration: config)
    #expect(
      original.pdfURL.path == root.appendingPathComponent("build output/source file.pdf").path)
    #expect(original.artifactURL(extension: "aux").lastPathComponent == "source file.aux")
  }
}
