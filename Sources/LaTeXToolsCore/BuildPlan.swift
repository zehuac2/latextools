import Foundation

/// Describes a build without reading files or launching processes.
struct BuildPlan: Sendable {
  let latexInvocation: ToolInvocation
  let helpers: [BuildHelper]
  let referenceURLs: [URL]
  let maximumPasses: Int
  let requiredPDFURL: URL

  init(project: Project) {
    latexInvocation = ToolInvocation(
      executable: project.configuration.latex,
      arguments: [
        "-output-directory=\(project.outputDirectoryURL.path)", "-interaction=batchmode",
        project.entryURL.path,
      ],
      workingDirectory: project.rootURL
    )

    helpers = Self.helpers(for: project)

    referenceURLs = ["aux", "toc", "out", "bcf", "glo", "glsdefs"].map {
      project.artifactURL(extension: $0)
    }

    maximumPasses = 5
    requiredPDFURL = project.pdfURL
  }

  @BuildHelperBuilder
  private static func helpers(for project: Project) -> [BuildHelper] {
    if project.configuration.bib == .biber {
      BuildHelper(
        inputURL: project.artifactURL(extension: "bcf"),
        invocation: ToolInvocation(
          executable: "biber",
          arguments: [
            project.outputDirectoryURL.appendingPathComponent(
              project.entryURL.deletingPathExtension().lastPathComponent
            ).path
          ],
          workingDirectory: project.rootURL
        )
      )
    }
    if project.configuration.glossary {
      BuildHelper(
        inputURL: project.artifactURL(extension: "glo"),
        invocation: ToolInvocation(
          executable: "makeglossaries",
          arguments: [
            "-d", project.outputDirectoryURL.path,
            project.entryURL.deletingPathExtension().lastPathComponent,
          ],
          workingDirectory: project.rootURL
        )
      )
    }
  }
}
