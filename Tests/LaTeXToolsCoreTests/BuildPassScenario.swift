struct BuildPassScenario: Sendable {
  let inputContents: [String]
  let expectedPasses: Int?
  let expectedInvocations: [String]

  static let all: [BuildPassScenario] = [
    .init(
      inputContents: ["stable", "stable"], expectedPasses: 2,
      expectedInvocations: ["pdflatex", "helper", "pdflatex"]
    ),
    .init(
      inputContents: ["initial", "changed", "changed"], expectedPasses: 3,
      expectedInvocations: ["pdflatex", "helper", "pdflatex", "helper", "pdflatex"]
    ),
    .init(
      inputContents: ["1", "2", "3", "4", "5"], expectedPasses: nil,
      expectedInvocations: [
        "pdflatex", "helper", "pdflatex", "helper", "pdflatex", "helper",
        "pdflatex", "helper", "pdflatex", "helper",
      ]
    ),
  ]
}
