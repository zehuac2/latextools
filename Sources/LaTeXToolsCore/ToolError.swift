import Foundation

public struct ToolError: Error, LocalizedError {
  public let executable: String
  public let exitCode: Int32

  public var errorDescription: String? { "\(executable) exited with code \(exitCode)" }
}
