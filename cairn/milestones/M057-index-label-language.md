# M057: A non-English document gets a non-English index

- **Status:** review
- **Priority:** normal
- **Depends on:** M056
- **Driving RR:** —
- **Principles touched:** IP2, IP3, GP3, GP4
- **Branch/PR:** `m057-index-label-language`

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
`DEFAULT_TITLE` an undeclared document uses and nothing else (D-038), which is
why no table row can reach the LaTeX back-end at all. The `labels:` override surface → M056, which this
depends on. Locator punctuation as a fourth label → candidate row. A language
whose words could not be confidently checked, which is omitted and falls back
to English rather than guessed.

## Acceptance criteria

- [ ] AC1. A document declaring `lang: es` and no `labels:` renders to HTML
      with the non-letter group heading, the two cross-reference labels and
      the index heading printing the four Spanish strings the shipped table
      holds. Evidence: the suite's exhaustive HTML index manifest for that
      fixture.
- [ ] AC2. Resolution falls back by tag across the three outcomes below an
      exact hit: a `lang:` the table holds only at its primary subtag —
      `fr-CA` — prints that subtag's row; a `lang:` the table holds at neither,
      and a malformed `lang:` value, each print the four English defaults and
      draw no extension message at all. Evidence: the three fixtures'
      manifests, and a warning count of zero over the second and third
      fixtures' logs.
- [ ] AC3. A language the table covers in part prints the covered words and
      English for the rest, in one index, with no message. Evidence: that
      fixture's manifest.
- [ ] AC4. An author's `labels:` beats the table key by key: a `lang: es`
      document also writing `see:` at document level prints its own word for
      `see` and the table's Spanish words for the other three. Evidence: that
      fixture's manifest.
- [ ] AC5. Every word the shipped table holds matches what at least two
      references of different kinds give — one lexical, one a typographic or
      editorial authority for that language, each reference's kind recorded
      beside it — and a word those references disagree on is not shipped, a
      language reaching fewer than two kinds being omitted entirely. Evidence:
      the table's own literal enumerates the rows and the words each ships, and
      T1's synthesis note carries every shipped word's quoted extract from both
      references with each reference's kind named.
- [ ] AC6. `CHANGELOG.md` records the heading's changed default and says that
      writing `title: Index` restores the old word, and
      `site/back-end-differences.qmd` states the three residual divergences:
      the back-ends share `lang:` and nothing else, the author override reaches
      HTML and EPUB only, and the covered languages differ. Evidence: a read of
      the two files.
- [ ] AC7. No word this milestone resolves reaches the LaTeX back-end, across
      every outcome of the tag resolver T2 defines and which T2 enumerates —
      exact-tag hit, primary-subtag hit, miss, and a malformed or absent value:
      each of the four fixtures exercising those outcomes, rendered to LaTeX
      against a twin that is the same file with only its `lang:` line removed,
      produces a complete `.tex` `diff` whose every differing line is one
      Quarto emits for the document language and none this filter writes.
      Evidence: the four diffs, each differing line classified in a ledger
      committed with the suite, and the derivation check of T6 proving each
      twin is its fixture minus that one line.
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

- [x] T1. Choose at least two independent reference sources per language,
      ingest each as a `cairn/references/` source note with its `INDEX.md`
      line, and write one synthesis note holding each language's four words
      with both references' quoted extracts and each reference's kind beside
      each. The two kinds are one lexical reference and one typographic or
      editorial authority for that language, which is what makes them
      independent rather than two restatements of one source. A word the two
      disagree on is not shipped; a language reaching fewer than two kinds is
      left out.
- [x] T2. The table module and its resolver: exact tag, then primary subtag,
      then English, reading `lang:` from the document metadata; a malformed or
      absent value misses silently, since an author writing `lang:` for Quarto
      did not address this filter (IP2).
- [x] T3. Wire the resolver beneath M056's override so the order is per-index
      `labels:`, then document `labels:`, then the table, then English —
      resolved per key, never per map.
- [x] T4. Resolve the untitled index heading through the same table in
      `indexes.lua`'s `title`, replacing the `DEFAULT_TITLE` fallback only: a
      declared index with no `title:` keeps falling back to its own `name`, so
      the `\makeindex[title={...}]` LaTeX path (`index.lua:419-430`) stays
      unreached. A declared `title:` wins outright.
- [x] T5. Fixtures, one per resolver outcome plus the two coverage cases:
      `lang: es` (exact hit), `lang: fr-CA` (subtag), a language the table
      lacks (miss), a malformed `lang:` value, a partly covered language, and a
      `lang: es` document that also writes `labels:`. Each of the four resolver
      fixtures gets a twin that is itself with only the `lang:` line removed.
- [x] T6. Suite rows for each fixture, the four LaTeX twin comparisons with a
      derivation check per pair on the model of M04-AC4's
      (`tests/run-tests.sh:3810-3831`), and a planted defect proving each new
      check can go red.
- [x] T7. `CHANGELOG.md` and `site/back-end-differences.qmd` per AC6, plus the
      covered-language list wherever the site names what an author can expect.

## Work log

- 2026-08-28: created by /milestone-plan, after RB02/RR02 settled the approach.
- 2026-08-28: criteria audit ran in FULL mode (declared tier user-facing), one fresh-context [O] reader over both files' criteria; it returned six findings across the two, all fixed at the gate — instrument-bound promises in this file's AC4 and in M057's AC5, an unsatisfiable message wording in this file's AC5, unbounded universals in this file's AC6 and M057's AC7, and a set-level gap in M057 where no criterion bound the shipped words' correctness. Its seventh point, that the suite-green AC is instrument-bound, was left standing as a template-mandated criterion. A re-audit of the changed wording was commissioned and had not returned when this was committed.
- 2026-08-28: the re-audit returned and found four more, all fixed here: the twin fixtures AC6 and AC7 diff against were never required to be derived from their originals, AC7's four-outcome list mixed the tag resolver's axis with per-key coverage and omitted the malformed-`lang:` outcome, AC5's "independent" admitted no failing state, and AC5's "four words" contradicted AC3's partly-covered row. It also found the plan freezing a narrower heading set than D-037's sentence promised, which D-038 now narrows the entry to.
- 2026-08-28: plan gate chose a table authored in this repo over pandoc's shipped translation files because those are GPL-2-or-later data in an MIT repo and give one word for both cross-reference kinds in Japanese (D-035); falsified by a reachable, licensable per-language source with better authority appearing.
- 2026-08-28: plan gate chose a shipped table over reading the files at render time through `pandoc.pipe` because Quarto's pandoc need not be on PATH, so two machines would render one document with different words; falsified by a render-time lookup shown to give one answer on every supported install.
- 2026-08-28: plan gate chose localizing the untitled heading in this release over holding it one release behind the labels because that halfway state is the worst of the three (D-037); falsified by an author reporting a link or cross-reference that depended on the English heading text.

- 2026-08-29: implement gate chose four languages (es, fr, de, it) over two or six, babel's per-language locale data as the typographic reference the words are checked against, and leaving a word English wherever no authority backs it.
- 2026-08-29: T1 — six `cairn/references/` pages: babel's installed `.ini` locale data and Unicode CLDR's character labels as the typographic and editorial references, Duden, Treccani, the TLFi via the CNRTL and Wiktionary as the lexical ones, and one synthesis note holding the 16-row per-word ledger. The RAE refuses automated requests, so the Spanish lexical leg is Wikcionario alone, recorded on the page rather than glossed over.
- 2026-08-29: T2, T3, T4 — `modules/languages.lua` holds the table and the resolver; `indexes.lua` consults it beneath both author levels and above the English word, and installs its heading only where the document declared no index.
- 2026-08-29: T5, T6 — six fixtures and four twins, six hand-derived manifests, an EPUB comparison, the four `.tex` twin comparisons with a derivation check per pair and an eight-entry ledger classifying every differing line, and eleven planted defects.
- 2026-08-29: T7 — the changelog entry for the changed heading, a tenth row on the back-end-differences page, and the covered-language list on the letter-groups, cross-references and HTML pages.
- 2026-08-29: checkpoint — all seven tasks are written and the suite is mid-run at 376 checks with no failure; the plain and `--self-test` runs the completion gate needs have not both returned, so this commit is honest work-in-progress and the status stays `in-progress`.
- 2026-08-29: the first full run failed on one check only — `site/gallery.yml` requires every `examples/*.qmd` be declared `shown:` or `not-shown:`, and the ten new fixtures were neither; declared under `not-shown:`, and `site/examples.qmd` now names them and the M56 label fixtures it had also never described.
- 2026-08-29: tasks complete, suite green twice over the final tree: 465 checks plain and 899 with `--self-test`, both exit 0. All eleven planted defects go red and report themselves as what they are. Status to `review`.

## Decisions

- 2026-08-29: **A word two references do not spell the same way is not shipped, and German's Symbols heading is the one that falls.** The rule AC5 states is applied as a string comparison, not a judgement: Unicode's locale data heads that category `Zeichen` in German while a German dictionary's word for a symbol is `Symbol`, plural `Symbole`. Those are two different strings, and this repo has no standing to pick between them in a language its maintainer does not read, so the German row ships three words and a German document prints the English `Symbols`. Spanish, French and Italian pass the same test because their locale label is the plural of the same dictionary headword. Recorded because the rule, not the German language, is what produced the gap — a later language will be judged the same way. Falsified by a German reader reporting `Symbols` as the wrong heading where `Zeichen` would have been right.

- 2026-08-29: **`es_ES` resolves as `es-ES`; a value with a space in it does not resolve at all.** Rendering `lang: es_ES` to LaTeX put `spanish` in the `\documentclass` options and `Tabla de contenidos` in the preamble, so Quarto reads the underscore spelling as Spanish and localizes the whole document from it. Refusing it here would have left the index the one part of that document still in English, which is the split this table exists to close, so `_` is read as a separator. The boundary stays sharp everywhere else: the primary subtag is two to eight letters and every subtag after it one to eight letters or digits, and anything else — `lang: "es ES"`, the fixture this milestone uses — resolves to nothing and prints English silently. Falsified by a spelling Quarto localizes from that this resolver still refuses.

## Review
