import LaTeXToolsCore

final class FakeRunner: ProcessRunning {
  var calls: [ToolInvocation] = []
  var action: ((ToolInvocation, Int) throws -> Void)?

  func run(_ invocation: ToolInvocation) throws {
    calls.append(invocation)
    try action?(invocation, calls.count)
  }
}
