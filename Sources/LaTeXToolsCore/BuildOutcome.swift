public enum BuildOutcome: Equatable {
  case upToDate
  case built(latexPasses: Int)
}
