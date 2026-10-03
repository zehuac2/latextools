# Repository guidance

## Project and layout

LaTeXTools is a Swift package that builds LaTeX projects described by
`latexproject.json`. It provides the `latextools` executable and the
`LaTeXToolsCore` library for macOS, Linux, and Windows.

- `Package.swift`: Swift 6.4 package manifest; macOS deployment target is 13.
- `Sources/LaTeXToolsCore/Project.swift`: project paths and artifact locations.
- `Sources/LaTeXToolsCore/ProjectConfiguration.swift`: configuration and defaults;
  `ProjectConfiguration+CodingKeys.swift` contains its coding keys.
- `Sources/LaTeXToolsCore/ProjectStore.swift`: project discovery and creation.
- `Sources/LaTeXToolsCore/BuildEngine.swift`: input validation, incremental
  builds, reference convergence, and safe cleanup.
- `Sources/LaTeXToolsCore/SystemProcessRunner.swift`: process execution and
  executable lookup, using `ProcessRunning` and `ToolInvocation`.
- `Sources/latextools/CommandLineApp.swift`: Swift Argument Parser entry point
  and subcommand registration. Command types in this folder handle CLI output,
  Makefile export, and opening PDFs, using an injectable `CommandContext`.
  Keep project and build logic in the core library.
- `Tests/LaTeXToolsCoreTests/`: Swift Testing suites grouped by core type,
  with shared helpers in `TestSupport.swift` and `FakeRunner.swift`.
- `Tests/latextoolsTests/`: Swift Testing cases for CLI parsing and execution.
- `README.md`: installation, commands, and development instructions.
- `docs/Project.md`: configuration fields, defaults, and path semantics.
- `.github/workflows/test.yml`: build and test jobs on all three platforms.

## Development and validation

Run commands from the repository root:

```sh
swift build
swift test
swift build -c release
```

Use `swift build` and `swift test` for Swift changes. Use the release build when
changing packaging or installation behavior. For documentation-only changes,
check referenced paths and commands; a full build is unnecessary.
Run `git diff --check` before finishing and report any checks you could not run.

The existing unit tests use a fake process runner and do not require a LaTeX
distribution. Real document builds require the configured LaTeX executable and,
when enabled, `biber` and `makeglossaries` on `PATH`.

## Implementation conventions

- Match the existing Swift style: two-space indentation, UpperCamelCase types,
  lowerCamelCase members, and explicit `any` for protocol existential types.
- Keep each enum, struct, and class in its own file, including nested types
  declared in extensions. Name files after the type they contain.
- Use Foundation `URL` APIs for filesystem paths and preserve paths with spaces.
- Pass executables and argument arrays through `ToolInvocation` and
  `ProcessRunning`; avoid shell command strings. Keep runners injectable.
- Keep platform-specific behavior behind `#if os(...)` branches. Consider
  Windows path handling and executable lookup as well as macOS and Linux.
- Use descriptive errors through the existing error types. The CLI reports
  failures to stderr and returns a nonzero exit status.
- Preserve the core library's public API unless the task calls for a change.
  Keep dependencies minimal; Swift Argument Parser 1.8.2 is pinned for the
  executable target. The core library has no external dependencies.

## Behavior to preserve

- Keep existing `latexproject.json` files compatible. All six fields are
  optional: `latex`, `bin`, `entry`, `bib`, `glossary`, and `includes`.
  Defaults are documented in `docs/Project.md`.
- Discover the nearest configuration by searching the current directory and
  then its parents. Resolve relative paths from the configuration's directory.
- Refuse to overwrite an existing configuration or entry file when creating a
  project. Named projects must use a single folder name.
- Incremental builds track the configuration, entry file, and declared includes.
  Scan included directories recursively, exclude the output directory, and
  handle symlink cycles.
- Bound LaTeX reference convergence to five passes. Run bibliography and
  glossary helpers when their inputs require it, and require a resulting PDF.
- Keep cleanup restricted to an output directory strictly inside the project
  root, checking resolved symlinks before deletion.
- Preserve `generate` as an alias for `export`. Exported Makefiles forward build
  and clean operations to `latextools`.

## Tests and documentation

For behavior changes, add or update focused Swift Testing cases using `@Test`
and `#expect`. Use temporary directories with deferred cleanup and fake
`ProcessRunning` implementations to verify invocations without launching tools
or opening desktop apps. Set timestamps explicitly when testing incremental
builds rather than relying on sleeps.

Update `README.md` when commands or installation change, and `docs/Project.md`
when configuration or path behavior changes. Do not edit generated `.build/`
or `.swiftpm/` contents. Inspect the working tree before editing and preserve
unrelated work already present.
