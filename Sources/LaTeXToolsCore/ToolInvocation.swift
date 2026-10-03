import Foundation

public struct ToolInvocation: Sendable {
  public let executable: String
  public let arguments: [String]
  public let workingDirectory: URL

  public init(executable: String, arguments: [String], workingDirectory: URL) {
    self.executable = executable
    self.arguments = arguments
    self.workingDirectory = workingDirectory
  }
}
