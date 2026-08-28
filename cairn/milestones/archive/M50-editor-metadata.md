# M50: Editors complete and document the marking syntax

**Status:** done (2026-08-27, PR #49 https://github.com/jmgirard/quarto-index/pull/49)

**Goal:** Ship the two editor-metadata files the Quarto extension listing asks
for, `_schema.yml` and `_snippets.json`, so an editor completes and documents
this extension's marking syntax.

**Outcome:** `_schema.yml` declares the `index` and `qi-index-here` classes and
the seven and one attributes each carries, `mention` and `range` enumerating
their values; `_snippets.json` carries 11 VS Code-format snippets.
`tests/editormeta.py` holds both against the syntax the 20 tracked `site/*.qmd`
pages document; `tests/editorfixture.py` builds a document from every snippet
and a bare-mark control from the same, reading each attribute as the difference
between the two rendered indexes; an install probe archives what git tracks and
installs it with `quarto add`. Suite 397, self-test 760.

**Decisions:** D-030 — the suite reads YAML with PyYAML and names the package
when the import raises. KI90 records that no check holds the schema against
the attribute set the filter accepts (the plan gate's choice over a Lua scan).

**Review:** one round, no returns. Blame-history and prior-review found nothing;
diff-bug reported thirteen — three fixed at the gate (a reader that raised
instead of reporting, PyYAML absent from the tool guard, a docs sentence
claiming editor behavior no check holds), nine filed, one rejected.
