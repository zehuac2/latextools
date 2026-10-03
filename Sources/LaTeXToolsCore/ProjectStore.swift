import Foundation

public enum ProjectStore {
  public static let fileName = "latexproject.json"

  public static func find(startingAt directory: URL) throws -> Project? {
    var current = directory.standardizedFileURL
    while true {
      let candidate = current.appendingPathComponent(fileName)
      if FileManager.default.fileExists(atPath: candidate.path) {
        return try load(at: candidate)
      }
      let parent = current.deletingLastPathComponent().standardizedFileURL
      if parent.path == current.path { return nil }
      current = parent
    }
  }

  public static func load(at configurationURL: URL) throws -> Project {
    let data = try Data(contentsOf: configurationURL)
    let configuration = try JSONDecoder().decode(ProjectConfiguration.self, from: data)
    return Project(configurationURL: configurationURL, configuration: configuration)
  }

  public static func create(in directory: URL, name: String? = nil) throws -> Project {
    var target = directory.standardizedFileURL
    if let name {
      guard !name.isEmpty, name != ".", name != "..",
        !name.contains("/"), !name.contains("\\")
      else {
        throw ProjectError.invalid("project name must be one folder name")
      }
      target.appendPathComponent(name)
    }

    let configurationURL = target.appendingPathComponent(fileName)
    let entryURL = target.appendingPathComponent("index.tex")
    let files = FileManager.default

    guard !files.fileExists(atPath: configurationURL.path),
      !files.fileExists(atPath: entryURL.path)
    else {
      throw ProjectError.invalid("latexproject.json or index.tex already exists in \(target.path)")
    }

    try files.createDirectory(at: target, withIntermediateDirectories: true)

    let configuration = ProjectConfiguration()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(configuration).write(to: configurationURL, options: .atomic)

    let entry = "\\documentclass{article}\n\n\\begin{document}\n  Hello World!\n\\end{document}\n"
    try entry.write(to: entryURL, atomically: true, encoding: .utf8)

    return Project(configurationURL: configurationURL, configuration: configuration)
  }
}
