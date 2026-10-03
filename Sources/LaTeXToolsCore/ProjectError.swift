import Foundation

public enum ProjectError: Error, LocalizedError {
  case invalid(String)

  public var errorDescription: String? {
    switch self {
    case .invalid(let message): message
    }
  }
}
