import Foundation
import Testing

@testable import LaTeXToolsCore

struct ProjectStoreTests {
  @Test
  func testCreation() throws {
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    try write("{}", to: root.appendingPathComponent("latexproject.json"))
    let created = try ProjectStore.create(in: root, name: "a project")
    let json = try #require(
      try JSONSerialization.jsonObject(with: Data(contentsOf: created.configurationURL))
        as? [String: Any])
    #expect(Set(json.keys) == Set(["latex", "bin", "entry", "bib", "glossary", "includes"]))
    #expect(throws: (any Error).self) {
      try ProjectStore.create(in: root, name: "a project")
    }
    #expect(throws: (any Error).self) {
      try ProjectStore.create(in: root, name: "../escape")
    }
    #expect(throws: (any Error).self) {
      try ProjectStore.create(in: root)
    }
  }

  @Test
  func testParentDiscovery() throws {
    let temporaryRoot = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }
    let root = temporaryRoot.appendingPathComponent("a project")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let config = ProjectConfiguration(bin: "build output", entry: "source file.tex")
    let original = try project(in: root, configuration: config)
    let child = root.appendingPathComponent("nested/deep")
    try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
    let found = try #require(try ProjectStore.find(startingAt: child))
    #expect(found.configurationURL == original.configurationURL)
  }
}
