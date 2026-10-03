import Foundation

public struct ProjectConfiguration: Codable, Sendable {
  public var latex: String
  public var bin: String
  public var entry: String
  public var bib: Bibliography
  public var glossary: Bool
  public var includes: [String]

  public init(
    latex: String = "pdflatex",
    bin: String = "bin",
    entry: String = "index.tex",
    bib: Bibliography = .none,
    glossary: Bool = false,
    includes: [String] = []
  ) {
    self.latex = latex
    self.bin = bin
    self.entry = entry
    self.bib = bib
    self.glossary = glossary
    self.includes = includes
  }

  public init(from decoder: any Decoder) throws {
    let defaults = ProjectConfiguration()
    let values = try decoder.container(keyedBy: CodingKeys.self)

    latex = try values.decodeIfPresent(String.self, forKey: .latex) ?? defaults.latex
    bin = try values.decodeIfPresent(String.self, forKey: .bin) ?? defaults.bin
    entry = try values.decodeIfPresent(String.self, forKey: .entry) ?? defaults.entry
    bib = try values.decodeIfPresent(Bibliography.self, forKey: .bib) ?? defaults.bib
    glossary = try values.decodeIfPresent(Bool.self, forKey: .glossary) ?? defaults.glossary
    includes = try values.decodeIfPresent([String].self, forKey: .includes) ?? defaults.includes
  }
}
