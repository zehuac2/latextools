import Foundation

/// A helper runs on the first pass and whenever its input contents change.
struct BuildHelper: Sendable {
  // The input URL also identifies the helper's last successfully consumed input.
  let inputURL: URL
  let invocation: ToolInvocation
}
