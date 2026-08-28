# Changelog

## Unreleased

### Project

- The extension ships editor metadata beside its manifest:
  `_extensions/index/_schema.yml`, a Quarto Wizard schema declaring the
  `index` and `qi-index-here` classes and the attributes each carries, and
  `_extensions/index/_snippets.json`, VS Code-format snippets for every
  marking form. Editors supporting those formats read them for completion and
  hover text; a render reads neither.

## 0.1.0 (2026-08-26)

First tagged release. Earlier development is in the git history.

### Marking syntax

- Ten supported span forms, listed on the [Syntax](site/syntax.qmd) page: a
  bare mark, `entry=` for an entry other than the visible text, `!`-separated
  sub-entry levels, an empty span that indexes without writing anything,
  `see=` and `see-also=` cross-references, `mention="principal"` for the
  locator an entry emphasizes, `range="open"` / `range="close"` for one
  locator spanning a discussion, and `index=` for which named index a mark
  belongs to.
- A `sort=` attribute files an entry under a key other than its own text,
  including a key per sub-entry level.
- A `::: {.qi-index-here}` div says where the index prints. It is honoured at
  the top level of a document, the first marker wins, and a second one is
  reported by its position.
- The visible text of a mark is left exactly as written in every format.

### Output

- A LaTeX/PDF back-end built on `imakeidx`.
- An HTML back-end that prints the entry tree with letter groups and links
  each locator to the marked passage.
- A Quarto book gets one index for the whole book, built from a sidecar store
  the chapter renders share; the extension names any chapter whose entries
  came from an earlier render rather than the current one.
- In beamer and any other format with no back-end, marks pass through: the
  text is preserved and no index markup is emitted.
- Warnings about a mark itself — an empty level, a cross-reference with no
  usable target, a mark with nothing to index — are raised whatever the
  output format.

### Project

- Requires Quarto 1.4 or later. `imakeidx` is the only other runtime
  dependency, on the LaTeX side.
- Released under the MIT license.
- Documentation site at <https://jmgirard.github.io/quarto-index/>.
