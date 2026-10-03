# LaTeX Tools

`latextools` builds LaTeX projects on macOS, Linux, and Windows. Projects use a
`latexproject.json` file; existing configuration files keep working.

## Install

Install Swift 6.4, then build the executable:

```sh
swift build -c release
```

Place the resulting `latextools` executable on your `PATH`. The core library is
also available as the `LaTeXToolsCore` Swift package product. A LaTeX
distribution and any configured bibliography or glossary tools must be installed
separately.

## Use

```sh
latextools --help                 # list commands
latextools help new               # show options for a command
latextools new                    # create a project in the current folder
latextools new -n my-project      # or --name my-project
cd my-project
latextools build
latextools open
latextools clean
latextools export                 # write a Makefile
latextools generate               # alias for export
```

`new` refuses to replace an existing `latexproject.json` or `index.tex`.
Other commands find the nearest project in the current folder or a parent.
`build` skips work when the PDF is newer than the configuration and all declared
inputs. It runs LaTeX until reference files settle, with a limit of five passes.
`clean` removes the configured output directory only when it is inside the
project root.

The exported Makefile requires GNU Make and forwards `all` and `clean` to
`latextools build` and `latextools clean`.

See [project configuration](docs/Project.md) for all fields.

## Develop

```sh
swift build
swift test
```

The package contains the `LaTeXToolsCore` library and the `latextools` executable.
The CLI lives in `Sources/latextools` and uses
[Swift Argument Parser 1.8.2](https://swiftpackageindex.com/apple/swift-argument-parser/1.8.2/documentation/argumentparser)
for commands, options, help, and argument errors. Core tests live in
`Tests/LaTeXToolsCoreTests`; CLI tests live in `Tests/latextoolsTests`.
GitHub Actions runs build and test jobs on macOS, Linux, and Windows.
