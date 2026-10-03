import Foundation
import LaTeXToolsCore

func temporaryDirectory() throws -> URL {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

func write(_ value: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try value.write(to: url, atomically: true, encoding: .utf8)
}

func project(in root: URL, configuration: ProjectConfiguration = .init()) throws
  -> Project
{
  let configURL = root.appendingPathComponent("latexproject.json")
  try JSONEncoder().encode(configuration).write(to: configURL)
  try write("entry", to: root.appendingPathComponent(configuration.entry))
  return Project(configurationURL: configURL, configuration: configuration)
}
