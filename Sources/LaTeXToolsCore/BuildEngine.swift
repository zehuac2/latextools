import Foundation

public struct BuildEngine {
  public let runner: any ProcessRunning

  public init(runner: any ProcessRunning) { self.runner = runner }

  public func build(_ project: Project) throws -> BuildOutcome {
    let inputs = try collectInputs(project)
    let files = FileManager.default

    if let pdfDate = modificationDate(project.pdfURL),
      inputs.allSatisfy({ (modificationDate($0) ?? .distantFuture) < pdfDate })
    {
      return .upToDate
    }

    try files.createDirectory(at: project.outputDirectoryURL, withIntermediateDirectories: true)
    let plan = BuildPlan(project: project)
    var helperInputs = [URL: Data]()

    for pass in 1...plan.maximumPasses {
      let before = snapshot(plan.referenceURLs)
      try runner.run(plan.latexInvocation)
      let after = snapshot(plan.referenceURLs)
      var helperRan = false

      for helper in plan.helpers {
        let current = try Data(contentsOf: helper.inputURL)
        if pass == 1 || current != helperInputs[helper.inputURL] {
          try runner.run(helper.invocation)
          helperInputs[helper.inputURL] = current
          helperRan = true
        }
      }

      if before == after && !helperRan {
        guard files.fileExists(atPath: plan.requiredPDFURL.path) else {
          throw ProjectError.invalid("build finished without \(plan.requiredPDFURL.path)")
        }
        return .built(latexPasses: pass)
      }
    }

    throw ProjectError.invalid(
      "LaTeX references did not stabilize after \(plan.maximumPasses) passes")
  }

  public func clean(_ project: Project) throws {
    let root = project.rootURL.resolvingSymlinksInPath().standardizedFileURL.path
    let output = project.outputDirectoryURL.resolvingSymlinksInPath().standardizedFileURL.path
    let separator = root.hasSuffix("/") ? "" : "/"

    guard output.hasPrefix(root + separator), output != root else {
      throw ProjectError.invalid("output directory must be inside the project root")
    }

    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(
      atPath: project.outputDirectoryURL.path, isDirectory: &isDirectory)
    {
      guard isDirectory.boolValue else {
        throw ProjectError.invalid(
          "output path is not a directory: \(project.outputDirectoryURL.path)")
      }
      try FileManager.default.removeItem(at: project.outputDirectoryURL)
    }
  }

  public func validate(_ project: Project) throws { _ = try collectInputs(project) }

  private func collectInputs(_ project: Project) throws -> [URL] {
    let files = FileManager.default
    var result = [project.configurationURL]
    var visited = Set<String>()

    for url in [project.entryURL] + project.configuration.includes.map({ project.resolve($0) }) {
      guard files.fileExists(atPath: url.path) else {
        throw ProjectError.invalid("input not found: \(url.path)")
      }
      var isDirectory: ObjCBool = false
      _ = files.fileExists(atPath: url.path, isDirectory: &isDirectory)
      if url == project.entryURL && isDirectory.boolValue {
        throw ProjectError.invalid("entry must be a file: \(url.path)")
      }
      try visit(url, excluding: project.outputDirectoryURL, visited: &visited, result: &result)
    }
    return result
  }

  private func visit(
    _ url: URL, excluding output: URL, visited: inout Set<String>, result: inout [URL]
  ) throws {
    let canonical = url.resolvingSymlinksInPath().standardizedFileURL
    if canonical == output.resolvingSymlinksInPath().standardizedFileURL { return }
    guard visited.insert(canonical.path).inserted else { return }
    let files = FileManager.default
    var isDirectory: ObjCBool = false

    guard files.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      throw ProjectError.invalid("input not found: \(url.path)")
    }

    if isDirectory.boolValue {
      for child in try files.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
        try visit(child, excluding: output, visited: &visited, result: &result)
      }
    } else {
      result.append(url)
    }
  }

  private func snapshot(_ urls: [URL]) -> [URL: Data] {
    var result = [URL: Data]()
    for url in urls {
      result[url] = try? Data(contentsOf: url)
    }
    return result
  }

  private func modificationDate(_ url: URL) -> Date? {
    try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
  }
}
