# Project configuration

`latexproject.json` lives at the project root. Every field is optional; the
following values are the defaults:

```json
{
  "latex": "pdflatex",
  "bin": "bin",
  "entry": "index.tex",
  "bib": "none",
  "glossary": false,
  "includes": []
}
```

| Key | Meaning |
| --- | --- |
| `latex` | LaTeX executable name or path. |
| `bin` | Directory for the PDF and build artifacts. |
| `entry` | Main `.tex` file. |
| `bib` | `none` or `biber`. |
| `glossary` | Run `makeglossaries` when true. |
| `includes` | Additional input files or directories, scanned recursively. |

Relative paths resolve from the folder containing `latexproject.json`, even
when a command runs in a child folder. Absolute paths are accepted for inputs
and output. The output directory is excluded when scanning included folders.
For safety, `clean` rejects an output directory that resolves outside the
project root or to the root itself.

The PDF and build artifacts use the entry file's name without `.tex`. For
example, `entry: "chapters/report.tex"` and `bin: "build"` produce
`build/report.pdf`.
