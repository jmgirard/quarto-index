# M057: A non-English document gets a non-English index

- **Status:** planned
- **Priority:** normal
- **Depends on:** M056
- **Driving RR:** —
- **Principles touched:** IP2, IP3, GP3, GP4
- **Branch/PR:** —

## Goal

The four reader-facing words the HTML and EPUB index back-end emits follow the
document's declared `lang:`, against a table this repo authors, with the
author's own `labels:` still winning.

## Scope

Surface tier: **user-facing** — the deliverable changes words a reader sees in
a published index, and changes one of them by default.

**In:** a shipped table of `symbols`, `see`, `see-also` and the untitled index
heading, per language, each row carrying the reference it was checked against;
resolution from `lang:` by exact BCP-47 tag, then primary subtag, then English;
the untitled heading resolved through it while `title:` still wins absolutely
(D-037); `cairn/references/` pages for the sources the table relies on; the
changelog entry for the changed default; the documentation of what the two
back-ends do and do not share.

**Out:** any file copied from pandoc or another GPL source, and any render-time
call out to a `pandoc` binary — both refused in D-035, neither to be revisited
without superseding it. The heading a *declared* index with no `title:` falls
back to, which is that index's own `name` and reaches LaTeX through
`\makeindex[title={...}]` (`index.lua:419-430`): the localization replaces the
`DEFAULT_TITLE` an undeclared document uses and nothing else, which is why no
table row can reach the LaTeX back-end at all. The `labels:` override surface → M056, which this
depends on. Locator punctuation as a fourth label → candidate row. A language
whose words could not be confidently checked, which is omitted and falls back
to English rather than guessed.

## Acceptance criteria

- [ ] AC1. A document declaring `lang: es` and no `labels:` renders to HTML
      with the non-letter group heading, the two cross-reference labels and
      the index heading printing the four Spanish strings the shipped table
      holds. Evidence: the suite's exhaustive HTML index manifest for that
      fixture.
- [ ] AC2. Resolution falls back by tag: a `lang:` the table holds only at its
      primary subtag — `fr-CA` — prints that subtag's row, and a `lang:` the
      table holds at neither prints the four English defaults and draws no
      extension message at all. Evidence: the two fixtures' manifests, and a
      warning count of zero over the second fixture's log.
- [ ] AC3. A language the table covers in part prints the covered words and
      English for the rest, in one index, with no message. Evidence: that
      fixture's manifest.
- [ ] AC4. An author's `labels:` beats the table key by key: a `lang: es`
      document also writing `see:` at document level prints its own word for
      `see` and the table's Spanish words for the other three. Evidence: that
      fixture's manifest.
- [ ] AC5. Every row of the shipped table names at least two independent
      references that agree on each of its four words, and each word matches
      what those references give; a word its references disagree on is not
      shipped, and a language with fewer than two checkable references is
      omitted. Evidence: the table's own literal enumerates the rows, and the
      synthesis note of T1 carries each word's quoted extract from both
      references.
- [ ] AC6. `CHANGELOG.md` records the heading's changed default and says that
      writing `title: Index` restores the old word, and
      `site/back-end-differences.qmd` states the three residual divergences:
      the back-ends share `lang:` and nothing else, the author override reaches
      HTML and EPUB only, and the covered languages differ. Evidence: a read of
      the two files.
- [ ] AC7. No word this milestone resolves reaches the LaTeX back-end, for any
      of the four resolution outcomes: each of the `lang: es`, `fr-CA`,
      partly-covered and uncovered fixtures, rendered to LaTeX against an
      otherwise identical twin declaring no `lang:`, produces a complete `.tex`
      `diff` whose every differing line is one Quarto emits for the document
      language, and none this filter writes. Evidence: the four diffs, each
      differing line classified in a ledger committed with the suite.
- [ ] AC8. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
      0.

## Coverage

- AC1 → T1, T2, T3, T5, T6
- AC2 → T2, T5, T6
- AC3 → T1, T2, T5, T6
- AC4 → T3, T5, T6
- AC5 → T1, T2
- AC6 → T7
- AC7 → T5, T6
- AC8 → T6

## Tasks

- [ ] T1. Choose at least two independent reference sources per language,
      ingest each as a `cairn/references/` source note with its `INDEX.md`
      line, and write one synthesis note holding each language's four words
      with both references' quoted extracts beside each. A word the two
      disagree on is not shipped; a language reaching fewer than two
      references is left out.
- [ ] T2. The table module and its resolver: exact tag, then primary subtag,
      then English, reading `lang:` from the document metadata; a malformed or
      absent value misses silently, since an author writing `lang:` for Quarto
      did not address this filter (IP2).
- [ ] T3. Wire the resolver beneath M056's override so the order is per-index
      `labels:`, then document `labels:`, then the table, then English —
      resolved per key, never per map.
- [ ] T4. Resolve the untitled index heading through the same table in
      `indexes.lua`'s `title`, replacing the `DEFAULT_TITLE` fallback only: a
      declared index with no `title:` keeps falling back to its own `name`, so
      the `\makeindex[title={...}]` LaTeX path (`index.lua:419-430`) stays
      unreached. A declared `title:` wins outright.
- [ ] T5. Fixtures: `lang: es`, `lang: fr-CA`, a partly covered language, a
      language the table lacks, and an `lang: es` document that also writes
      `labels:`.
- [ ] T6. Suite rows for each fixture, the LaTeX twin comparison, and a planted
      defect proving each new check can go red.
- [ ] T7. `CHANGELOG.md` and `site/back-end-differences.qmd` per AC6, plus the
      covered-language list wherever the site names what an author can expect.

## Work log

- 2026-08-28: created by /milestone-plan, after RB02/RR02 settled the approach.
- 2026-08-28: criteria audit ran in FULL mode (declared tier user-facing), one fresh-context [O] reader over both files' criteria; it returned six findings across the two, all fixed at the gate — instrument-bound promises in this file's AC4 and in M057's AC5, an unsatisfiable message wording in this file's AC5, unbounded universals in this file's AC6 and M057's AC7, and a set-level gap in M057 where no criterion bound the shipped words' correctness. Its seventh point, that the suite-green AC is instrument-bound, was left standing as a template-mandated criterion. A re-audit of the changed wording was commissioned and had not returned when this was committed.
- 2026-08-28: plan gate chose a table authored in this repo over pandoc's shipped translation files because those are GPL-2-or-later data in an MIT repo and give one word for both cross-reference kinds in Japanese (D-035); falsified by a reachable, licensable per-language source with better authority appearing.
- 2026-08-28: plan gate chose a shipped table over reading the files at render time through `pandoc.pipe` because Quarto's pandoc need not be on PATH, so two machines would render one document with different words; falsified by a render-time lookup shown to give one answer on every supported install.
- 2026-08-28: plan gate chose localizing the untitled heading in this release over holding it one release behind the labels because that halfway state is the worst of the three (D-037); falsified by an author reporting a link or cross-reference that depended on the English heading text.

## Decisions

## Review
