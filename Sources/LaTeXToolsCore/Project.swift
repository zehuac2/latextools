import Foundation

public struct Project: Sendable {
  public let configurationURL: URL
  public let configuration: ProjectConfiguration

  public init(configurationURL: URL, configuration: ProjectConfiguration) {
    self.configurationURL = configurationURL.standardizedFileURL
    self.configuration = configuration
  }

  public var rootURL: URL { configurationURL.deletingLastPathComponent() }
  public var entryURL: URL { resolve(configuration.entry) }
  public var outputDirectoryURL: URL { resolve(configuration.bin) }
  public var pdfURL: URL { artifactURL(extension: "pdf") }

  public func artifactURL(extension suffix: String) -> URL {
    let stem = entryURL.deletingPathExtension().lastPathComponent
    return outputDirectoryURL.appendingPathComponent("\(stem).\(suffix)")
  }

  public func resolve(_ path: String) -> URL {
    if (path as NSString).isAbsolutePath {
      return URL(fileURLWithPath: path).standardizedFileURL
    }
    return URL(fileURLWithPath: path, relativeTo: rootURL).standardizedFileURL
  }
}
