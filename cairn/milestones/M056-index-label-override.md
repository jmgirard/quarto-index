# M056: An author sets the words the index back-end picks itself

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP4, GP5
- **Branch/PR:** m056-index-label-override — https://github.com/jmgirard/quarto-index/pull/56

## Goal

An author can set the three English words the HTML and EPUB index back-end
emits on its own — `Symbols`, `see` and `see also` — for a whole document or
for one index.

## Scope

Surface tier: **user-facing** — the deliverable is a metadata surface authors
write and words a reader sees in a published index.

**In:** an `index-labels:` map holding `symbols`, `see` and `see-also`, read at
the document's top level and inside one `indexes:` entry, the nearer setting
winning key by key and English the fallback (D-036, key name amended by D-039);
the three words resolved through it in `html.lua` and `core.lua`; reports for an
`index-labels:` that is not a map, an unknown key in one, and a key whose value
is empty, each falling back rather than half-installing; the editor snippets;
fixtures, suite rows and documentation.

**Out:** the shipped translation table and any reading of `lang:` → M057, which
depends on this. The editor schema, whose vocabulary has no place for a
top-level metadata key at all (its own comment says so). The untitled heading's default → M057 (D-037); `title:`
already overrides it and is untouched here. Locator punctuation as a fourth
label → candidate row. The LaTeX back-end, which localizes through babel
already and gains nothing here.

## Acceptance criteria

- [x] AC1. A document writing a top-level `index-labels:` with all three keys
      renders to HTML with the non-letter group heading and the two
      cross-reference labels printing exactly those three strings. Evidence:
      the suite's exhaustive HTML index manifest for the fixture, which
      enumerates every group heading and every entry line of the section,
      states the three declared strings in the positions those words print,
      and a sweep of the rendered sections finding no group heading reading
      `Symbols` and no cross-reference word reading `see` or `see also`.
- [x] AC2. A per-index `index-labels:` overrides the document-level one key by
      key, not map by map: in a fixture declaring two indexes where the
      document sets all three keys and one index resets only `see`, that index
      prints its own `see` word with the document's other two, and the second
      index prints all three of the document's. Evidence: the same manifest
      over both sections.
- [x] AC3. The same fixture rendered to EPUB prints the same words in the same
      places. Evidence: `tests/epubcheck.py sections --labels`, which reads the
      built EPUB through `tests/epubindex.py`, against a hand-derived manifest
      stating the word each cross-reference prints.
- [x] AC4. The keys stay optional, English stays the default, and Quarto's own
      `labels:` metadata is not read: a twin fixture carrying the same marks
      and no `index-labels:` anywhere prints `Symbols`, `see` and `see also`
      and draws no message about a label word, though Quarto injects a
      `labels:` map into it; and `examples/letter-groups.qmd` and
      `examples/resolving-xref.qmd` render the same index output they render
      today. Evidence: the twin's manifest and its render log;
      `examples/letter-groups.qmd`'s existing manifest passing with no row
      edited; and, for `examples/resolving-xref.qmd`, which the suite holds no
      index manifest for, a manifest derived by hand from the `.qmd` under the
      suite's ORACLE RULE rather than read off the render.
- [x] AC5. Each unusable shape draws one message and leaves the words falling
      back to the next level and then to English. The misuse fixture writes
      four: at the document level, one map carrying both an unknown key and a
      key whose value is empty; and at the per-index level, an `index-labels:`
      that is not a map in each of its two forms, a scalar and a sequence. The
      two per-key messages name their key and the document level, and the two
      not-a-map messages each name the index it was written in. Evidence: the
      misuse fixture's log, each of the four messages asserted whole rather
      than by substring, this extension's total message count over that render
      being exactly four, and the fixture's manifest showing `Symbols`, `see`
      and `see also`.
- [x] AC6. No `index-labels:` declaration reaches the LaTeX back-end: the
      complete `diff` of the labels fixture's `.tex` against the `.tex` of a
      twin that is the same file with only its two `index-labels:` blocks
      removed is empty. Evidence: the diff itself, which enumerates every
      difference exhaustively rather than sampling emission sites, and the
      derivation check of T4 proving the twin is that file; a non-empty diff
      fails the criterion whatever the differing lines say.
- [x] AC7. `site/letter-groups.qmd`, `site/cross-references.qmd` and
      `site/back-end-differences.qmd` each state the `index-labels:` map, its
      three keys, the two levels it is written at, and that it reaches HTML and
      EPUB only; and at least one of them states that the map is named
      `index-labels:` rather than `labels:` because a top-level `labels:` is
      Quarto's own. Evidence: a read of the three pages against that list.
- [ ] AC8. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both exit
      0.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T1, T2, T3, T4
- AC3 → T2, T3, T4
- AC4 → T3, T4
- AC5 → T1, T3, T4
- AC6 → T3, T4
- AC7 → T6
- AC8 → T4

## Tasks

- [x] T1. Read and validate `index-labels:` in `_extensions/index/modules/indexes.lua`
      at both levels, following `read_declaration`'s existing report-and-fall-
      back discipline (lines 80–116); export a resolver taking an index name
      and a key and returning the nearer declared string or the English
      default.
- [x] T2. Point `html.lua:45`'s group heading and `core.lua:24-27`'s two
      `XREF_KINDS` labels at that resolver, leaving `latex.lua`'s use of the
      same rows untouched.
- [x] T3. Fixtures: a two-index document declaring `index-labels:` at both
      levels, a twin declaring none, and a misuse document carrying the four
      unusable writings AC5 enumerates. Give each new mark a term no other mark
      in its file indexes.
- [x] T4. Suite: HTML manifest rows for both new fixtures, the EPUB read, the
      LaTeX twin comparison, the message-whole warning assertions, and a
      planted defect proving each new check can go red. Include a derivation
      check that fails when the twin is not the labels fixture with its
      `index-labels:` blocks deleted, on the model of M04-AC4's
      (`tests/run-tests.sh:3810-3831`) — without it AC6's empty diff can fail
      for drift unrelated to `labels:`.
- [x] T5. Add an `index-labels:` snippet and its three keys to
      `_extensions/index/_snippets.json`, and correct the now-stale sentence in
      `_extensions/index/_schema.yml` naming `indexes:` as this extension's one
      metadata key.
- [x] T6. Documentation: the three site pages named in AC7, plus a
      `CHANGELOG.md` entry naming the new metadata surface.

## Work log

- 2026-08-28: created by /milestone-plan, after RB02/RR02 settled the approach.
- 2026-08-28: criteria audit ran in FULL mode (declared tier user-facing), one fresh-context [O] reader over both files' criteria; it returned six findings across the two, all fixed at the gate — instrument-bound promises in this file's AC4 and in M057's AC5, an unsatisfiable message wording in this file's AC5, unbounded universals in this file's AC6 and M057's AC7, and a set-level gap in M057 where no criterion bound the shipped words' correctness. Its seventh point, that the suite-green AC is instrument-bound, was left standing as a template-mandated criterion. A re-audit of the changed wording was commissioned and had not returned when this was committed.
- 2026-08-28: the re-audit returned; this file's AC4, AC5 and AC6 were clean, and its one finding here — that AC6's twin was never required to be the labels fixture minus its `labels:` blocks, so an empty diff could fail for unrelated drift — is fixed in AC6 and T4.
- 2026-08-28: plan gate chose a nested `labels:` map over three flat fields beside `title:` because a flat `see:` collides with the mark attribute `see=`, where the same word names a target rather than a label (D-036); falsified by an author needing a per-index word these three keys cannot express.
- 2026-08-28: plan gate chose two declaration levels over per-index only because an undeclared document cannot override without inventing an index name, which moves the section id and breaks inbound links; falsified by the two levels proving indistinguishable in practice.
- 2026-08-28: plan gate chose splitting the override surface from the shipped table over one milestone because the surface is a permanent naming decision and the table is a data asset, each reviewable alone; falsified by the split forcing a rework of the resolver when M057 wires `lang:` beneath it.
- 2026-08-28: implement question gate, four choices, every recommendation taken. (1) The printed cross-reference word reaches the manifest through a new `labels` flag on `htmlindex.row()`, off for every existing manifest so all 36 existing xref rows stay byte-identical, on for this milestone's fixtures — the field the class alone decides today (`see-link Aardvark`) becomes `see-link cf. Aardvark`. (2) AC4 names a `resolving-xref` manifest the suite does not have, so one is hand-derived in the label-aware form rather than AC4 being amended; no row of it is edited because it has none. (3) The author's symbols word is what the heading PRINTS and not the group's identity: `group_label`/`group_rank` keep the internal sentinel, so a word that is a single ASCII letter cannot merge with that letter's group and a word sorting after `A` cannot re-rank the group. (4) The English fallbacks stay where they are — `Symbols` at `html.lua`, the two words in `core.lua`'s `XREF_KINDS` — and the resolver takes the fallback from its call site, so no word gets a second copy.

- 2026-08-28: BLOCKING DISCOVERY, and the substantive amendment it forced. The first render of the labels fixture showed `labels:` is Quarto's own top-level key: it injects a nine-key title-block map into every document, so the new unknown-key report fired nine times on the twin, which declares nothing. The map is renamed `index-labels:` at both levels at the user's selection, over nesting `labels:` inside a new `index:` map and over staying inside Quarto's; D-039 records it and amends D-036, whose every other clause stands.
- 2026-08-28: the amended acceptance-criterion wording went to a fresh-context [O] criteria audit in FULL mode (declared tier user-facing) before it was written; the reader authored none of it. Nine findings, all disposed at the mini gate. Six are folded into the criteria: AC1's "carries none of `Symbols`, `see`, `see also`" was unsatisfiable, because the manifest's own xref token contains `see`, and now binds the positions those words print plus a sweep of the rendered sections; AC3 named `tests/epubindex.py`, a hand tool that cannot report a printed word, and now names `tests/epubcheck.py sections --labels`; AC4 split its two fixtures' evidence, since only one of them has a manifest today, and grew the promise that binds the motivating defect — Quarto's injected `labels:` is not read, evidenced by the twin's log; AC5 pins both not-a-map forms and both level phrases across four writings; AC7 gained the rename's discoverability clause. Three were disposed without changing a criterion: the per-index override exercising only `see` stands, because the key axis is covered at the document level by AC1 and the resolver's lookup is key-agnostic; T5's schema half is descoped, the schema vocabulary having no place for a top-level metadata key by its own comment; and the record repairs are D-039 and this pass's rename through Scope and the tasks.

- 2026-08-28: T1/T2 — `index-labels:` is read and validated in `indexes.lua` at both levels, and `html.lua` resolves the group heading and the two cross-reference words through `qi_indexes.label(index, key, fallback)`. `core.lua`'s `XREF_KINDS` rows gained a `label_key` field spelled out rather than reused from `attr`, so a later rename of either cannot move the other; `latex.lua` reads the same rows and is untouched.
- 2026-08-28: T3 — three fixtures, and `examples/index-labels-twin.qmd` is generated from `examples/index-labels.qmd` by the same deletion the suite's derivation check asserts. Both fixtures' prose is written to read truthfully in either file, since the twin carries it verbatim.
- 2026-08-28: T4 — the suite gained the M56 block, `htmlindex.row()` a `labels` flag (off by default, so all 36 existing cross-reference rows stay byte-identical), `check_html_index_manifest`/`check_index_sections` a fifth argument passing it, and `epubcheck.py sections` a `--labels` option. Three suite-wide readers needed the new tuple field: seven 4-tuple unpacks of a record's `xrefs` in `run-tests.sh` and one in `editorfixture.py`, each widened by a name; `tests/scans/warn-distinct.py`'s exact warn-message count went 71 → 74. The new fixtures were registered in `site/gallery.yml` (not-shown) and in M14's dangling-target corpus, each with the count derived from its own marks.
- 2026-08-28: T5/T6 — the `index-labels` snippet, the schema comment corrected to name two top-level metadata keys and say the vocabulary has no place for either, the three site pages, and a CHANGELOG entry under Marking syntax naming the collision by name.
- 2026-08-28: verify ran twice green after the work was complete, sequentially as PROFILE requires: `tests/run-tests.sh` 441 checks and `tests/run-tests.sh --self-test` 863 checks, both exit 0. Three earlier runs failed for reasons the work list did not hold and were fixed as found — the warn-count pin, the `xrefs` tuple width, and the fixtures being untracked, which the gallery's `git ls-files` enumeration reads. One run died on a Quarto segfault rendering `examples/content.qmd`, an unrelated fixture the next run rendered fine.
- 2026-08-28: the `--self-test` run surfaced a defect that is not this milestone's: M40's self-test summary writes backtick-quoted tokens inside a double-quoted `pass` message, so the shell runs one as a command substitution and the run log carries `line 13996: ..: command not found`. Recorded as KI172; M56's own summary is single-quoted for the same reason, after the first run showed it eating the word it quoted.

- 2026-08-28: review — PR #56 opened as a draft, CI green. Default branch had not moved. cairn_validate exit 0 (two advisory sizing WARNs only); no IP/GP change, so cairn_impact skipped; the generic profile names no toolchain checks. The eight criterion boxes arrived ticked with an empty Review section, so all eight were reset and are being re-ticked against fresh evidence: AC1-AC7 verified and recorded. AC8 awaits the in-flight `--self-test` run; the three fresh-context reviewers are still out. Checkpoint, not a finished review.

- 2026-08-28: review — three fresh-context lenses ran; blame-history and prior-PR-comments returned no findings, the [O] diff-bug lens returned 15. Three items fixed at the gate (two false babel/`symbols` claims in the site pages, the stale manifest-1e row-format definition, and four code comments still naming the map `labels:` after D-039), eleven deferred as KI173-KI183, two rejected. No finding demonstrates a criterion failing, so status stays in review. Both suites re-running over the fixed tree for AC8; checkpoint, not a finished review.

## Decisions

- **What falls back is the key, not the map.** A map whose `see:` is empty
  still sets its `symbols:`, exactly as an index declaration whose `title:` is
  empty still declares its `name:`. The alternative — one unusable key voiding
  the whole map — would make a typo change words the author wrote correctly,
  which is the half-install the scope forbids. Only a value that is no map at
  all sets nothing, because there is nothing in it to read key by key.

## Review

Evidence gathered 2026-08-28 on branch `m056-index-label-override` at the
pre-gate checkpoint, against PR #56. The default branch had not moved since the
branch was cut (`git rev-list --left-right --count origin/main...HEAD` → `0 2`),
so no merge was needed. Suite evidence is from one sequential
`tests/run-tests.sh` run and one `tests/run-tests.sh --self-test` run.

### Acceptance criteria

- **AC1 — pass.** The labels fixture's exhaustive HTML manifest matched all 18
  rows over both generated sections, in order; a further check asserted the
  three declared words print in the positions the extension words itself; and
  the sweep check reported none of the three English words printed in any of
  the 12 positions the extension words. Link integrity held in both sections
  (4 links each, every id unique).
- **AC2 — pass.** The same manifest run covered both sections of the two-index
  fixture, and the paired check reported the second index printing its own
  `see` word beside the document's other two, the first printing all three of
  the document's.
- **AC3 — pass.** `tests/epubcheck.py sections … --labels`
  (`tests/run-tests.sh:18177`) read the built EPUB and matched all 16 rows of
  the hand-derived label-aware manifest over both generated sections
  (`qi-index-main`, `qi-index-authors`); all 8 links inside those sections
  resolved.
- **AC4 — pass.** The twin fixture matched all 18 manifest rows and the check
  reported it printing `Symbols`, `see` and `see also` and drawing no message
  at all, though Quarto writes a `labels:` map into its metadata.
  `examples/letter-groups.qmd`'s existing manifest passed at 14 rows with no
  row edited by this branch (`git diff main...HEAD -- tests/run-tests.sh`
  touches no manifest row of it, only an added comment). The hand-derived
  `examples/resolving-xref.qmd` manifest matched all 16 rows in order.
- **AC5 — pass.** The misuse fixture's manifest matched all 18 rows, and the
  message check reported each of the four unusable writings drawing exactly its
  own whole message and none of the others, those four being the whole of what
  the render reports, and every word falling back to English.
- **AC6 — pass.** The labels fixture and its twin rendered byte-for-byte
  identical `.tex`, so the complete diff is empty; the T4 derivation check
  separately confirmed the twin is `examples/index-labels.qmd` with its two
  `index-labels:` blocks deleted and nothing else.
- **AC7 — pass.** Read of the three site pages against the list.
  `site/letter-groups.qmd`, `site/cross-references.qmd` and
  `site/back-end-differences.qmd` each state the `index-labels:` map, its three
  keys (`symbols`, `see`, `see-also`), both levels with the nearer setting
  winning key by key, and that it reaches HTML and EPUB only. Two of them —
  `letter-groups.qmd` and `cross-references.qmd` — state the rename clause, that
  the map is `index-labels:` rather than `labels:` because a top-level `labels:`
  is Quarto's own.

### Consistency gate

`cairn_validate.py` exit 0 — every check PASS, two advisory sizing WARNs
(M056 and M057 each carry 8 acceptance criteria, over the 7 tripwire), which
are advisories and not gate failures. No `DESIGN.md` principle changed — the
diff adds a Known-issues entry only — so `cairn_impact.py` was not run. The
active profile is `generic`, whose `consistency-gate` slot names no toolchain
checks, so that half is a clean no-op.

### Independent fresh-context review

Declared tier is user-facing and the diff touches executable surface, so the
full three-lens fan-out ran, each lens fresh-context and none having authored
the implementation.

- **[S] blame-history** — no findings. It confirmed `group_label`/`group_rank`
  are untouched by the diff, the LaTeX/babel path is left alone as `core.lua`'s
  standing comment intends, D-037/D-038 are not contradicted, and every
  `xrefs` unpack was widened.
- **[S] prior-PR-comments** — no findings. The GitHub existence probe found no
  inline review comments on this repo at all, so that surface was skipped; the
  archived `## Review` sections for M52, M38, M39, M25 and M50 were read
  against the touched files and no prior review point is regressed.
- **[O] diff-bug** — 15 findings, ranked. Dispositions below; the maintainer
  sees the full ranked text at the gate.

Findings and dispositions, in the reviewer's own severity order:

- **F1. A usable `index-labels:` is silently ignored in LaTeX, with no report.**
  *Rejected — the intentional scope decision this milestone's plan called for.*
  Scope Out names the LaTeX back-end, which localizes through babel; IP1 makes
  a format that does not realize a feature degrade gracefully rather than
  report, and all three site pages state the HTML/EPUB-only reach.
- **F2. Two site pages state something false about babel and the `symbols`
  word.** *Fixed now.* babel supplies `\seename` and `\alsoname` only, and a
  LaTeX index has no letter groups at all, so there is no third word for
  `symbols:` to override there. Both sentences rewritten; verified against
  `latex.lua`, which emits no letter-group heading.
- **F3. A whitespace-only word is accepted as a printed word.** *Follow-up —
  KI173.*
- **F4. The `read`-ordering the comment exists for is untested.** *Follow-up —
  KI177.*
- **F5. The labeled manifest field folds word and target into one ambiguous
  string.** *Follow-up — KI178.* Verified at `tests/htmlindex.py:541`.
- **F6. The canonical row-format definition was not updated for the new
  shape.** *Fixed now* — manifest 1e's definition now states the label form and
  that the eight manifests referring back to it mean the plain form.
- **F7. M26's cell inventory is stale and the two new cells are unbound by any
  reset probe.** *Follow-up — KI179.* The stale count was not corrected here:
  the comment's "seventeen" does not reproduce from a read of the four `reset`
  bodies, so a guessed number would be a fresh derived-figure defect.
- **F8. A per-index map on a refused entry vanishes with no message.**
  *Follow-up — KI176.*
- **F9. The `.tex` planted defect re-implements the check.** *Follow-up —
  KI180.*
- **F10. The labels fixture's own render logs are never held to a warning
  count.** *Follow-up — KI181.*
- **F11. A nested map under a label key stringifies to a word.** *Follow-up —
  KI175.*
- **F12. `m56_derive` ends a block at a blank line.** *Follow-up — KI182.*
- **F13. A single-ASCII-letter `symbols:` word prints two identically headed
  groups.** *Follow-up — KI174.*
- **F14. The two per-key messages are only exercised at the document level.**
  *Follow-up — KI183.*
- **F15. Two dead exports (`LABELS_KEY`, `LABEL_KEYS`, `SYMBOLS_KEY`).**
  *Rejected — a style point no behavior rests on, and the out-of-scope
  taxonomy's linter-or-nitpick member.*

One further finding came from the review session itself, not from a lens:

- **M1. Four code comments still named the map `labels:` after D-039 renamed it
  to `index-labels:`** (`core.lua:24`, `indexes.lua:62`, `:117`, `:218`).
  *Fixed now.* The one remaining `labels:` mention, `indexes.lua:40`, is the
  deliberate explanation of why the name is not that.

**Return floor.** No actioned finding demonstrates an acceptance criterion
failing, and none is a load-bearing defect in what the extension does for its
users: the three fixed items are two prose corrections and a stale-comment
sweep, and the eleven deferred ones are edges and check weaknesses, each
recorded as a Known-issues entry with a candidate row to promote from. Status
stays in review.

