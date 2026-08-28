# quarto-index

A Quarto extension for book-quality subject indexing. Mark index entries with
a format-neutral span syntax; the extension emits the right thing per output
format. Two back-ends ship: LaTeX/PDF and HTML.

## Install

```bash
quarto add jmgirard/quarto-index
```

Then enable the filter in your document (or `_quarto.yml`):

```yaml
---
title: "My book"
filters:
  - index
---
```

Requires Quarto 1.4 or later. GitHub Actions renders the example fixtures on
Quarto 1.4.549 — the oldest release of that line — as well as on the version
the documentation site is built with, and compares the HTML index each one
emits. Weekly and on demand rather than on every push, the same run also
typesets two of the fixtures to PDF on each of those versions and checks that
an index printed; no PDF is compared across versions, because two Quarto
versions typeset through different TeX engines. No other runtime
dependencies: on the LaTeX side it uses `imakeidx`, which ships with
mainstream TeX distributions.

## Documentation

The full documentation is published at
<https://jmgirard.github.io/quarto-index/>: the supported marking forms, what
each output format gets, where the two back-ends differ, and how a Quarto book
gets one index. Its source is the Quarto website in
[`site/`](site/index.qmd), which GitHub Actions renders and publishes on every
push to the default branch.

## Editor support

Two files ship inside the extension for editors to read. `_schema.yml` is its
Quarto Wizard schema, declaring the two classes the filter reads and every
attribute each one carries, with a description apiece. `_snippets.json` is
VS Code-format snippets, one per marking form. Editors supporting those
formats read them for completion and hover text; nothing in a render reads
either file. The [Syntax](site/syntax.qmd) page has the forms themselves.

## Examples

`examples/` is the fixture corpus the acceptance suite renders — a
four-chapter book, every supported form, the escaping probes, the placement
marker and its misuse cases, the cross-reference pairs, the named-index
fixtures and the non-Latin-1 recipe. The [Examples](site/examples.qmd) page
lists what each one exercises, and the site's Gallery gives a page to each
fixture it shows, with that fixture's source, the index its render produced,
and its PDF.

```bash
quarto render examples/demo.qmd --to pdf
quarto render examples/demo.qmd --to html
```

## Tests

```bash
tests/run-tests.sh --self-test
```

The [Tests](site/tests.qmd) page says what the suite renders, what it compares
the output against, and what it needs installed.

## License

MIT — see [LICENSE](LICENSE).
