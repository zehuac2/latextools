public protocol ProcessRunning {
  func run(_ invocation: ToolInvocation) throws
}
