@resultBuilder
enum BuildHelperBuilder {
  static func buildExpression(_ helper: BuildHelper) -> [BuildHelper] {
    [helper]
  }

  static func buildBlock(_ components: [BuildHelper]...) -> [BuildHelper] {
    components.flatMap { $0 }
  }

  static func buildOptional(_ component: [BuildHelper]?) -> [BuildHelper] {
    component ?? []
  }
}
