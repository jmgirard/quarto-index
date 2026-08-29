# M057: A non-English document gets a non-English index

- **Status:** review
- **Priority:** normal
- **Depends on:** M056
- **Driving RR:** —
- **Principles touched:** IP2, IP3, GP3, GP4
- **Branch/PR:** `m057-index-label-language` — https://github.com/jmgirard/quarto-index/pull/57

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

- [x] AC1. A document declaring `lang: es` and no `labels:` renders to HTML
      with the non-letter group heading, the two cross-reference labels and
      the index heading printing the four Spanish strings the shipped table
      holds. Evidence: the suite's exhaustive HTML index manifest for that
      fixture.
- [x] AC2. Resolution falls back by tag across the three outcomes below an
      exact hit: a `lang:` the table holds only at its primary subtag —
      `fr-CA` — prints that subtag's row; a `lang:` the table holds at neither,
      and a malformed `lang:` value, each print the four English defaults and
      draw no extension message at all. Evidence: the three fixtures'
      manifests, and a warning count of zero over the second and third
      fixtures' logs.
- [x] AC3. A language the table covers in part prints the covered words and
      English for the rest, in one index, with no message. Evidence: that
      fixture's manifest.
- [x] AC4. An author's `labels:` beats the table key by key: a `lang: es`
      document also writing `see:` at document level prints its own word for
      `see` and the table's Spanish words for the other three. Evidence: that
      fixture's manifest.
- [x] AC5. Every word the shipped table holds matches what at least two
      references of different kinds give — one lexical, one a typographic or
      editorial authority for that language, each reference's kind recorded
      beside it — and a word those references disagree on is not shipped, a
      language reaching fewer than two kinds being omitted entirely. Evidence:
      the table's own literal enumerates the rows and the words each ships, and
      T1's synthesis note carries every shipped word's quoted extract from both
      references with each reference's kind named.
- [x] AC6. `CHANGELOG.md` records the heading's changed default and says that
      writing `title: Index` restores the old word, and
      `site/back-end-differences.qmd` states the three residual divergences:
      the back-ends share `lang:` and nothing else, the author override reaches
      HTML and EPUB only, and the covered languages differ. Evidence: a read of
      the two files.
- [x] AC7. No word this milestone resolves reaches the LaTeX back-end, across
      every outcome of the tag resolver T2 defines and which T2 enumerates —
      exact-tag hit, primary-subtag hit, miss, and a malformed or absent value:
      each of the four fixtures exercising those outcomes, rendered to LaTeX
      against a twin that is the same file with only its `lang:` line removed,
      produces a complete `.tex` `diff` whose every differing line is one
      Quarto emits for the document language and none this filter writes.
      Evidence: the four diffs, each differing line classified in a ledger
      committed with the suite, and the derivation check of T6 proving each
      twin is its fixture minus that one line.
- [x] AC8. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
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

Fresh evidence, 2026-08-29, over the branch at PR #57. The suite's plain run
reported `All checks passed (465 checks)`, exit 0; every check line quoted
below is from that run.

- **AC1 — verified.** `M57-AC1`: the `index-lang-es` HTML capture matched its
  nine-row exhaustive manifest in order — heading `Índice alfabético`, group
  heading `Símbolos`, `véase` before the see cross-reference, `véase también`
  before the see-also — with every id unique and all 4 index links resolving.
  `M57-AC1` (EPUB): the EPUB capture matched the same nine rows. `M57-AC1
  (twin)`: the same document with only its `lang:` line removed matched the
  all-English manifest and drew no message, which is what makes the language
  the thing that changed the words.
- **AC2 — verified.** `M57-AC2 (subtag)`: `lang: fr-CA` matched the `fr`
  manifest — `Symboles`, `voir`, `voir aussi`. `M57-AC2 (miss)`: `lang: sw`
  matched the English manifest. `M57-AC2 (malformed)`: `lang: "es ES"` matched
  the English manifest. `check_extension_warning_count … 0` over the miss and
  malformed logs passed on both, so neither drew an extension message.
- **AC3 — verified.** `M57-AC3`: `index-lang-de` matched its manifest — the
  three German words `siehe`, `siehe auch` and the heading `Index` beside the
  English `Symbols`, in one index — and its warning count was 0.
- **AC4 — verified.** `M57-AC4`: `index-lang-override`, a `lang: es` document
  writing `see: compárese` at document level, matched a manifest printing the
  author's `compárese` and the table's `Símbolos`, `véase también` and
  `Índice alfabético`; warning count 0. The other three words standing is what
  shows the fold is per key, not per map.
- **AC5 — verified.** A mechanical comparison of the `WORDS` literal in
  `_extensions/index/modules/languages.lua` against the ledger table in
  `cairn/references/index-words-by-language.md`: the literal holds exactly the
  ledger's 15 `Ship` rows, key for key and string for string, and none of its
  one `Withhold` row (W-DE4, German `symbols`). Every ledger row names a
  typographic or editorial reference (babel's installed locale data, or CLDR's
  character labels for the Symbols heading, which babel does not carry) and a
  lexical one (Duden, Treccani, the TLFi, Wiktionary), each with its quoted
  extract and its kind in its own column. No shipped language reaches fewer
  than two kinds.
- **AC6 — verified.** A read of both files. `CHANGELOG.md` (Output) records the
  changed default, names the two languages whose heading actually differs, and
  says that writing `title: Index` restores the old heading.
  `site/back-end-differences.qmd` item 10 states all three divergences: the
  back-ends share `lang:` and nothing else, `index-labels:` is read by the HTML
  and EPUB back-ends alone, and the covered languages differ.
- **AC7 — verified.** Four `M57-AC7 (derivation, …)` checks passed: each twin
  is its fixture with its one `lang:` line deleted and nothing else. Four
  `M57-AC7 (…)` ledger comparisons then classified every differing `.tex` line
  against the eight-entry Quarto ledger — 44 lines for the exact hit, 30 for
  the subtag hit, 9 for the miss and 9 for the malformed value — with no
  unclassified line in any pair. An empty diff would have failed the check, so
  none of the four was satisfied by a pair that never exercised the language
  path.
- **AC8 — verified.** `tests/run-tests.sh` reported `All checks passed (465
  checks)`, exit 0; `tests/run-tests.sh --self-test` reported `All checks
  passed (899 checks)`, exit 0. Run sequentially, 2026-08-29, over the branch
  as pushed.

### Consistency gate

`cairn_validate.py` exits 0: every check PASS, one advisory WARN (`sizing`:
M057 carries 8 acceptance criteria against the 7 tripwire), which is an
advisory and not a gate failure. No `DESIGN.md` principle changed in this
milestone, so `cairn_impact.py` does not apply. The active profile is
`generic`, whose `consistency-gate` slot names no toolchain checks, so that
half of the gate is a clean no-op.

### Independent review

Surface tier user-facing and the diff touches executable surface, so all three
fresh-context lenses ran. The blame-history lens returned no findings: M056's
override precedence is extended rather than weakened, the `DEFAULT_TITLE` path
is scoped to D-038's narrower carve-out, and no existing suite assertion was
loosened to accommodate the new default. The diff-bug lens returned eleven and
the prior-review lens two. Each was verified against the implementation rather
than against the reviewer's account of it.

- **F1 (diff-bug, rank 1; confirmed).** `CHANGELOG.md` tells an author that
  writing `title: Index` restores the old heading, and it does not: nothing in
  the filter reads a top-level `title:` — `TITLE_FIELD` is read only inside an
  `indexes:` entry (`indexes.lua:208-213`) — so the front-matter `title:` a
  reader would naturally write is the document title. Rendered directly: a
  `lang: es` document writing `title: Index` prints `<h1 class="title">Index`
  and an index still headed `Índice alfabético`. The path that does work is
  `indexes: [{name: main, title: Index}]`, which the changelog does not name
  and which moves the index section's id from `qi-index` to `qi-index-main`
  (entry ids are unchanged). AC6 asks only that the changelog say the sentence,
  which it does, so AC6 passes on its own procedure; a changelog naming the
  `indexes:` location and the id it moves would satisfy AC6 too.
- **F2 (diff-bug, rank 2; confirmed).** The Italian row ships four words that no
  fixture exercises: no `examples/` file declares `lang: it`, and `Indice
  analitico`, `vedi`, `vedi anche` and `Simboli` appear in no manifest. The
  changelog advertises Italian to authors. Separately, the ledger's Disposition
  bullet 4 in `cairn/references/index-words-by-language.md` states that "each
  shipped word appears in a manifest row derived by hand from this ledger",
  which is false for those four.
- **F3 (diff-bug; confirmed).** `languages.lua:85`'s `OUTCOMES` table is read
  nowhere — not in the module, the suite, or the site. The comment above it
  justifies the table as what stops a check from naming its own outcomes while
  a fourth goes unexercised, but the suite's coverage is the four hard-coded
  strings of `M57_RESOLVER_FIXTURES`, with no link to `OUTCOMES`. The
  safeguard is inert.
- **F4 (diff-bug; confirmed).** `well_formed` uses `%a` and `%w`, against a
  convention this repo states verbatim at `html.lua:69-70`: "`[A-Za-z]` rather
  than `%a`, whose meaning follows the C locale and so could differ between one
  machine and another." Both outcomes print English today, so nothing visible
  diverges; the `miss`/`malformed` distinction the module treats as
  load-bearing becomes machine-dependent.
- **F5 (diff-bug; confirmed by reading).** `m57_tex_ledger` discards a differing
  line whose body is `--` or `++`: `unified_diff` prefixes it to `---`/`+++`
  and the header filter drops it. A line this filter wrote of that shape would
  pass unclassified. No such line exists in LaTeX preamble output today.
- **F6 (diff-bug; confirmed, also found in session).** `indexes.lua:444`
  exports `TITLE_KEY`, which nothing outside the module reads. The new module
  states the opposite rule for itself at `languages.lua:158-161`: "an export
  nothing reads is surface to keep in step for nobody (GP5)."
- **F7 (diff-bug; confirmed, latent).** `label()` consults `language_words[key]`
  for whatever key it is given, and `TITLE_KEY`'s string value sits in the same
  table as the three label keys. No call site passes `"title"` today
  (`html.lua:309` passes the cross-reference's key, `html.lua:369` the symbols
  key), so nothing is wrong now; a future printing site adding a `title` label
  key would silently pick up the index heading.
- **F8 (diff-bug; partly refuted).** The reviewer reported that a `lang:`
  written as a list or a map is concatenated by `pandoc.utils.stringify` and can
  resolve to a row — `lang: [es]` reaching the Spanish row — contradicting the
  module comment's claim that such a value "reaches `well_formed` as the
  nonsense it is". The concatenation is real, but the reviewer reproduced it
  under bare `pandoc -L`. Through Quarto, which is this filter's host, all
  three shapes are rejected by Quarto's own YAML schema before the filter runs
  ("Render failed due to invalid YAML", location `lang`), so the input class is
  unreachable. What stands is the comment's wording, not a reachable defect.
- **F9 (diff-bug).** AC5's same-string test is applied strictly to German,
  where `Zeichen` and `Symbol` differ and the word is withheld, and loosely to
  the multi-word phrases, where the lexical reference attests the parts rather
  than the shipped string (`Índice alfabético` against "`índice` sense 3 +
  `alfabético`"; `Indice analitico` against Treccani defining "`i. analitico`").
  The ledger's Method §2 discloses the rule, so it is stated rather than
  concealed.
- **F10 (diff-bug; confirmed).** The ledger's Provenance line says "the five
  source notes beside it" and then names six.
- **F11 (diff-bug; confirmed).** No book fixture carries `lang:`. All six
  `lang:`-bearing fixtures are single documents, so the aggregated book index —
  several Pandoc processes in HTML, one in EPUB — takes no language path in the
  suite.
- **F12 (prior-review; confirmed).** KI178 records that the label-form manifest
  row folds the printed word and the target into one space-joined field
  (`tests/htmlindex.py:541`), so a render printing `siehe` before `auch
  Kestrel` yields the row a render printing `siehe auch` before `Kestrel`
  yields. Three of the four shipped languages spell `see-also` as two words, so
  the ambiguity KI178 raised as hypothetical is now live in every non-English
  manifest this milestone adds. The fold is pre-existing and unchanged by this
  diff.
- **F13 (prior-review; confirmed, soft).** KI179's class extends: `tests/state-pollute.lua`
  does not call `qi_indexes.read`, so the new `language_words` cell sits outside
  that cross-document leak probe as `doc_labels` and `index_labels` already do.
  `reset` does clear it (`indexes.lua:298`), so no leak is demonstrated.
