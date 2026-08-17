# M02: Cross-references (see / see also)

- **Status:** review
- **Priority:** normal
- **Depends on:** M01
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP5, GP6
- **Branch/PR:** m02-cross-references / https://github.com/jmgirard/quarto-index/pull/2

## Goal

Add cross-reference index entries — see and see also — to the marking syntax,
realized by the LaTeX back-end with format-neutral target semantics.

## Scope

Surface tier: **user-facing** — new documented syntax the community consumes.

**In:** `see=` and `see-also=` span attributes on any mark form; target values
are structured level data (`!` separates, `!!` literal), never raw back-end
code (D-001/IP1). Source entry = `entry=` if present, else the visible term; a
cross-reference replaces the locator (indexing convention). Both attributes on
one mark: warn, emit both targets in one command. LaTeX realization settled by an empirical spike
(hyperref rewrites `\index` arguments at the first `|` — the encap channel).
Misuse warnings, escaping probes, docs.

**Out:** HTML realization of cross-references → candidate row (HTML index
generation). Sort keys, page-range/styling, multiple indexes → existing
candidate rows. No new exclusions.

Known holes carried over (noted, not criteria): bare unquoted attribute
values escape the source pins (existing ROADMAP row); AC1's pin regex matches
quoted values only.

## Acceptance criteria

- [x] AC1: `tests/run-tests.sh` renders `examples/demo.qmd` to LaTeX and
      every `\index{}` argument matches the hand-derived entry manifest,
      extended with one row per cross-reference mark (a mark carrying both
      attributes contributes one row, whose single command carries both
      targets) — each row's exact argument hand-derived from the emission
      forms the milestone's Decisions section records, including rows
      probing `!`-level parsing and `!!` literals inside see-targets. A
      completeness pin counts occurrences of `see="` and of `see-also="` in
      `examples/demo.qmd` and fails unless that total equals the summed
      counts of the single-target cross-reference rows plus twice the summed
      counts of the dual-target rows, rows classified by whether the row's
      argument carries the dual-target command the Decisions section names;
      `examples/demo.qmd` carries no mark whose cross-reference target is
      unusable and none with no source entry, so every occurrence belongs to
      a row. Manifest rows are never copied from filter output.
- [x] AC2: `examples/demo.qmd` compiles to PDF through Quarto's own engine;
      the `pdftotext` extraction of the index section shows, for each
      cross-reference manifest row of AC1, the source entry followed by that
      row's full cross-reference text — for a dual row, both targets with
      their labels in the order the Decisions section's emission form fixes
      (see-target first, see-also second) — per a hand-derived expected list
      whose multi-level join form, label source and dual-target separators
      derive from the decisions recorded in that section, and whose
      source-entry-to-cross-reference delimiter is makeindex's default, with
      whitespace normalized as the existing PDF check normalizes it (GP6).
- [x] AC3: A cross-reference escaping probe fixture (extending
      `examples/escaping.qmd` or a sibling) places every printable ASCII
      character (space excluded) as its own see-target level — except any
      character T1 records in the milestone's Decisions section as
      unrealizable in encap context; each excluded character is instead
      asserted to degrade gracefully (warned, no corrupted entry, documented
      in the README). Union coverage (not the cross-product) across
      leading/medial/trailing positions in multi-level targets and across
      `see=` vs `see-also=`, each probed character under both attributes at
      least once. The render compiles through Quarto's PDF engine and
      makeindex accepts every probe entry (asserted in the `.ilg`). Each
      character of the special-handling set — which the suite pins to equal
      the union of the filter's escape tables, so a table the filter adds
      can never go unprobed — additionally typesets: its probe's
      cross-reference text in the `pdftotext` index region equals a
      hand-derived exact expected string.
- [x] AC4: Rendering `examples/demo.qmd` to HTML and to beamer succeeds; the
      visible text of every cross-reference mark is preserved; no
      `see=`/`see-also=` value leaks into rendered text, per the suite's
      no-leak mechanism with its source pin extended to the two new
      attributes; and a cross-reference mark on content with no derivable
      text (in `examples/content.qmd`) indexes nothing and deletes nothing,
      in HTML and LaTeX.
- [x] AC5: Each defined misuse case — (a) a cross-reference mark with no
      source entry (no `entry=`, no visible text), exercised in
      `examples/content.qmd`, and (b) a mark carrying both `see=` and
      `see-also=`, exercised in `examples/demo.qmd` so AC1's manifest and
      AC2's PDF list cover its output — emits its own named warning,
      distinct from each other and from every existing warning, identified
      in the render log by distinctive message text, with the render still
      exiting successfully; the defined output for each case is asserted
      (case a: no `\index` command emitted and no content deleted, in HTML
      and LaTeX, the shape AC4 covers; case b: exactly one `\index` command
      carrying both targets, and the compiled PDF's `pdftotext` index region
      shows the source entry followed by both cross-reference texts in the
      order the Decisions section's emission form fixes); and the
      `--self-test` proves each of the two warning checks this criterion
      names discriminates on both axes — over a captured render log, the
      check fails on a fixture with its warning line removed and on one with
      that line duplicated, so each check asserts an exact occurrence count
      rather than mere presence.
- [x] AC6: The README documents the cross-reference forms — the syntax, the
      format-neutral semantics of the target value (structured `!` levels,
      `!!` literal), the see-replaces-locator semantics, and current
      per-format behavior. The suite's normative supported-forms list is
      restructured as label/exemplar pairs, includes the new forms, and
      fails if any syntax exemplar does not appear verbatim in the README.
- [x] AC7: `tests/run-tests.sh --self-test` (the profile's verify command)
      exits clean.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T3, T4
- AC3 → T3, T5
- AC4 → T2, T4
- AC5 → T2, T3, T4
- AC6 → T6
- AC7 → T4, T5, T6

## Tasks

- [x] T1: Spike: empirically probe cross-reference emission under Quarto's
      PDF pipeline — hyperref's first-`|` rewrite, `\see`/`\seealso`
      availability under imakeidx, multi-level target join, any characters
      unrealizable in encap context — and record the chosen emission form,
      join form, and label source as a milestone Decisions entry.
- [x] T2: Parse and validate `see=`/`see-also=` in
      `_extensions/index/index.lua`, format-neutral layer: structured
      levels, source resolution (`entry=` else visible term), misuse
      warnings (a)/(b) with their defined outputs.
- [x] T3: LaTeX realization per the emission decisions recorded in the
      Decisions section, including encap-context escaping (second table or
      recorded equivalent), and the document-level report of a term marked
      both plainly and with a cross-reference.
- [x] T4: Extend `examples/demo.qmd`, `examples/content.qmd`, and
      `tests/run-tests.sh`: cross-reference manifest rows + completeness
      pin, PDF expected list, no-leak pin extension, misuse checks,
      self-test discrimination coverage.
- [x] T5: Author the cross-reference escaping probe fixture and its suite
      checks: compile, `.ilg` acceptance, exact-text typeset assertions,
      union-table pin, graceful-degradation assertions for any T1-excluded
      character.
- [x] T6: README cross-reference documentation; normative supported-forms
      list as label/exemplar pairs with the verbatim README pin.

## Work log

- 2026-08-16: created by /milestone-plan.
- 2026-08-16: criteria audit ran in full mode ([O] fresh-context reader): 12 findings — 10 repaired into the wording, 2 disposed at the gate (verbatim README pin adopted; warn-and-emit-both confirmed); amended wording re-audited: 4 further wording-level findings, all repaired.
- 2026-08-16: plan gate chose `see=`/`see-also=` attributes over a single `xref=` micro-syntax because two plain kebab-case attributes match Pandoc style and avoid a value-internal syntax; falsified by a third cross-reference kind forcing attribute proliferation.
- 2026-08-16: plan gate chose any-form marks with see-replacing-locator over invisible-only marks because it matches indexing convention and natural usage; falsified by author demand for locator+see on one mark.
- 2026-08-16: plan gate chose warn-and-emit-both for a mark carrying both attributes over silent-allow or drop-one because IP2 forbids silent loss and the combination is a probable author error; falsified by legitimate dual-use patterns emerging.
- 2026-08-16: plan gate chose the verbatim README content pin over dropping the docs check because a content pin is strictly stronger than a count at no more machinery (audit finding 11); falsified by README format churn making the pin brittle.
- 2026-08-16: plan chose the full printable-ASCII see-target probe (with a T1 exclusion hatch) over the 16-character set because the repo's lesson says only compiling settles survival; falsified by probe runtime becoming prohibitive.
- 2026-08-16: implement started; branch m02-cross-references cut from main at 68c06ba.
- 2026-08-16: question gate — cross-reference character probe goes in a new sibling fixture (keeps M01's probe count intact); see-also label fallback policy chosen (T1 then found imakeidx already provides it); new suite checks labelled `M02-AC<N>` to avoid colliding with M01's labels.
- 2026-08-16: T1 done — four spike renders through Quarto's PDF engine settled the emission form, the `: ` multi-level join, and that no character is unrealizable in encap context; four Decisions entries recorded.
- 2026-08-16: T2 done — `see=`/`see-also=` parsed into levels in the format-neutral layer (so misuse is diagnosed in every format), source resolution unchanged, and two new named warnings for the misuse cases plus two for an unusable target; verify slot clean, existing behavior unchanged.
- 2026-08-16: T3 done — cross-references emitted through makeindex's encap channel; the both-attributes case forced a design change (one command via a back-end-defined `\quartoindexseeboth`) after it proved to fail Quarto's render, superseding a mis-derived T1 note. T3's task wording updated to cite the Decisions section rather than T1 alone. Verify slot clean.
- 2026-08-16: substantive amendment (gated) — AC1, AC2, AC5 amended for the one-command dual-target form, plus Scope's "emit both" clause and Coverage's AC5 row (now T2, T3, T4); a narrowing, since the old two-command promise was jointly unsatisfiable with IP2. Amended wording audited in full mode by a fresh-context [O] reader (9 findings, all repaired), then re-audited once by a second fresh [O] reader (11 findings, all disposed: pin arithmetic moved to summed row counts, row classification named, case (a) relocated to `examples/content.qmd`, the discrimination axis given a concrete artifact, tautological "emitted order" replaced, makeindex's own delimiter named, and the "each warning check" over-reach restricted to this criterion's two warnings).
- 2026-08-16: discovered sub-task added to T3 at a mini gate — the same makeindex conflict is reachable across two marks on one term, so the document pass now warns once per affected key (LaTeX only); README note and a ROADMAP candidate row for prevention. Scope unchanged: no new acceptance criterion, covered by suite checks.
- 2026-08-16: T4 done — seven cross-reference marks in `examples/demo.qmd` (six single-target, one dual) and two source-less marks in `examples/content.qmd`; suite gains the cross-reference manifest, the completeness pin with its arithmetic, a pin tying the manifest to the filter's dual-target command name, exact-count warning checks for both misuse cases, the babel-label pin, the no-leak source pin extended to both new attributes, the PDF cross-reference text list, and self-test discrimination on the missing/duplicated axes. Every hand-derived row matched the render first time.
- 2026-08-16: T5 done — `examples/xref-escaping.qmd` puts all 94 printable ASCII characters through cross-reference targets under both attributes, across all three level positions, plus the special set as single-target, dual-target and both; 238 entries derived by construction, 238 accepted by makeindex, 0 rejected, and all 48 exact typeset strings found. Also pins that the single and dual forms render a target identically, and covers the two unusable-target warnings.
- 2026-08-16: T6 done — README gains a cross-reference section (syntax, target level semantics, see-replaces-locator, the both-attributes behavior, the two-marks-on-one-term hazard, per-format behavior) and the forms table grows to six; the normative forms list is now label/exemplar pairs pinned verbatim to README.md, and the pin was proved discriminating by drifting one exemplar and watching it fail.
- 2026-08-16: all tasks done, `tests/run-tests.sh --self-test` clean (23 checks + 3 self-test checks); status review.
- 2026-08-16: review found 19 findings across three lenses; 15 fixed on the branch (including a README claim that was simply false and a clash case the new detector missed), 2 to ROADMAP rows, 1 no action, plus a no-regression report. Re-verified: 28 checks, exit 0.

## Decisions

- 2026-08-16 (T1 spike): Cross-reference emission form. A cross-reference is
  emitted as `\index{<source levels>|see{<target>}}` (and `|seealso{…}`) —
  makeindex's encap channel. hyperref rewrites it to
  `|hyperxindexformat{\see{…}}` before makeindex runs, which is harmless:
  `\see`/`\seealso` take the page as their second argument and discard it, so
  the cross-reference replaces the locator with no extra work. `\see`,
  `\seealso`, `\seename` and `\alsoname` are `\providecommand`'d by imakeidx,
  which the extension already loads, so no label definition is injected and a
  document loading babel first keeps babel's translated wording. The gate's
  fallback policy therefore costs no code.

- 2026-08-16 (T1 spike): Multi-level see-targets join with `: `. A raw `!`
  inside the encap argument is rejected by makeindex ("Extra `!' at position
  36 of first argument") and Quarto turns that rejection into a failed render
  — harder than the M01 depth case, which only lost an entry while the build
  stayed clean. Quoted `"!` is accepted but typesets as a literal `!`, leaking
  the extension's own level syntax into printed prose. `, ` is ambiguous when
  a level itself contains a comma ("see Smith, John, early work"); `: ` is not
  ("see Smith, John: early work"). Both were typeset in the spike PDF before
  choosing.

- 2026-08-16 (T1 spike): No character is unrealizable in encap context, so
  AC3's exclusion hatch stays unused and the back-end needs no second escape
  table. The existing `LATEX_LITERAL` table applied to see-target levels put
  every printable ASCII character (space excluded) through Quarto's own PDF
  engine — each as its own single-level see-target, and each again as the
  medial level of a three-level see-also target — for 190 entries accepted and
  0 rejected, with all sixteen special-handling characters typesetting
  correctly under both attributes. The `.ind` file is re-read as ordinary
  LaTeX, so the `\text…` commands and makeindex's `"` quoting work in a
  see-target exactly as they do in a source level.

- 2026-08-16 (T1 spike): A term carrying both a plain mark and a
  cross-reference mark is legal but noisy. makeindex warns "Conflicting
  entries: multiple encaps for the same page under same key", still builds,
  and prints the entry with both its locator and its cross-reference. Not an
  error and not a case the extension generates on its own, so it is documented
  in the README rather than warned about.

- 2026-08-16 (T3; supersedes the T1 entry immediately above): that entry
  called makeindex's conflicting-encaps warning harmless. It is not, and the
  claim was mis-derived — spike 1 failed on a rejected entry in the same run,
  and the warning was read off that failure instead of being tested on its
  own. Tested on its own: a mark carrying both `see=` and `see-also=` emits
  two `\index` commands under one key on one page, makeindex warns
  "Conflicting entries: multiple encaps for the same page under same key",
  and Quarto turns that warning into a failed render — deleting only that
  mark makes the same render succeed with 0 warnings. Emitting both would
  therefore break the document, which IP2 forbids, so a mark carrying both
  now emits one `\index` whose encap is
  `\quartoindexseeboth{<see>}{<see-also>}`. The back-end `\providecommand`s
  that command in its own preamble, and only in a document that uses one; it
  discards its third argument (the page) exactly as `\see` does, and takes
  its labels from `\seename`/`\alsoname` rather than literal words, so a
  document loading babel keeps babel's wording. Each target is rendered by
  the same code path as a single-target mark, so the two forms cannot drift
  apart in how they escape a character. Verified: 0 makeindex warnings, and
  the compiled index printing `theta, see A % b; see also B!c`.

- 2026-08-16 (gated addition after T3): two separate marks on one term — one
  plain, one a cross-reference — hit the same makeindex conflict as the
  both-attributes case. Verified: a document marking `kappa` plainly and again
  with `see=` failed the render on "Conflicting entries: multiple encaps for
  the same page under same key". It bites only when the two land on one
  printed page, and page numbers do not exist when the filter runs, so this
  cannot be prevented at this layer. The back-end reports it instead: the
  document pass warns once per affected key, naming the key, which beats an
  index-tool error naming neither the term nor this extension. The check is
  LaTeX-only, unlike the misuse warnings, because the failure is a property of
  the LaTeX index tool rather than of the mark syntax — warning in a format
  with no index back-end would be noise about a problem that format cannot
  have. Prevention (locator suppression, or deferring emission until page
  numbers are known) is a ROADMAP candidate, not this milestone's scope.

## Review

Fresh evidence, 2026-08-16, on branch m02-cross-references at the pre-gate
checkpoint. Every line below is from a command run in this session, never
from the implementing session's recollection.

- AC1: verified. Fresh `tests/run-tests.sh`: 30 manifest rows against 32
  `\index` commands in `examples/demo.tex`, all matching, with no unexpected
  entry. The seven cross-reference rows were hand-derived from the emission
  forms the Decisions section records and matched the render without
  adjustment. The completeness pin reports 6 single-target and 1 dual-target
  rows accounting for all 8 `see=`/`see-also=` occurrences in the source, and
  it fails if the manifest's dual-target command name and the filter's own
  constant disagree.

- AC2: verified. `examples/demo.qmd` compiled to PDF through Quarto's own
  engine, and all 7 hand-derived cross-reference strings were found in the
  `pdftotext` index region under the same whitespace normalization the
  existing PDF check uses. Read directly out of the compiled index:
  `cats, see Felines`; `dogs, see also Pets`; `owls, see Birds: Owls`;
  `bang, see Wow!Hey`; `Canids` with sub-item `Foxes, see Vulpes`;
  `Ghosts, see also Spirits`; and the dual row `both, see Aye; see also Bee`,
  see-target first and see-also second.

- AC3: verified. `examples/xref-escaping.qmd` compiled through Quarto's own
  PDF engine and, separately, through pdflatex plus makeindex: 238 entries
  accepted, 0 rejected, against 238 derived by construction from the
  fixture's own shape rather than read back from the run. The coverage check
  confirms all 94 printable ASCII characters (space excluded) appear as their
  own target level under both `see=` and `see-also=`, with leading, medial
  and trailing level positions all exercised. All 48 hand-derived exact
  strings for the special-handling set were found in the probe's typeset
  index, and the single-target and dual-target forms were shown to render
  each target byte-identically, so the character evidence covers both. No
  character proved unrealizable in encap context, so the criterion's
  exclusion hatch is unused and its graceful-degradation clause is vacuous.

- AC4: verified. `examples/demo.qmd` rendered to HTML and to beamer without
  error; the beamer `.tex` carries no index token and keeps its visible term
  text. 28 distinct visible terms across 30 marks matched by exact rendered
  span text, the six new cross-reference terms among them. No `entry=`,
  `see=` or `see-also=` value reaches rendered text, and the source pin that
  fences the no-leak list against the `.qmd` now covers all three attributes,
  so a new attribute value cannot escape the sweep by going unlisted.
  `examples/content.qmd` renders in HTML and LaTeX with exactly one `\index`
  command and all three marked images intact, the cross-reference mark on
  textless content among them.

- AC5: verified. Case (a) warned exactly twice in each of the HTML and LaTeX
  renders of `examples/content.qmd` — once per source-less mark — adding no
  `\index` command and deleting no content. Case (b) warned exactly once in
  the demo LaTeX render and produced exactly one command carrying both
  targets, which AC1's manifest fences as a single row and AC2 read out of
  the compiled PDF as `both, see Aye; see also Bee`. All 10 of the filter's
  warning literals are mutually distinct and none is a prefix of another, so
  each is separable by its message text. Under `--self-test`, each of the two
  checks failed on a captured render log with its warning line removed, failed
  again on one with that line duplicated, and passed on the log as rendered —
  the passing control shown to pass for the claim's reason.

- AC6: verified. README.md documents the cross-reference forms: the two
  attributes with worked examples, the target's `!`/`!!` level semantics and
  why levels join with `: ` rather than `!`, see-replaces-locator, the
  both-attributes behavior, the two-marks-on-one-term build hazard, and
  per-format behavior including what the LaTeX back-end adds to the preamble.
  The forms table grew from four rows to six. The suite's normative list is
  now label/exemplar pairs and all 6 exemplars were found verbatim in
  README.md. The pin was proved discriminating, not merely green: drifting
  one exemplar in the README to `seealso=` made the check fail naming that
  exemplar, and the README was restored.

- AC7: verified. `tests/run-tests.sh --self-test`, the profile's verify
  command, exits 0 on a wiped work directory: 23 acceptance checks and 3
  self-test checks, all passing.

### Consistency gate

- `cairn_validate`: exit 0, all checks passed — 16 PASS and 7 advisory OK,
  including coverage completeness, weight caps and the binding-criteria check.
- No `DESIGN.md` principle changed in this milestone, so the impact report
  does not apply.
- Toolchain checks: the active profile is `generic`, whose `consistency-gate`
  slot names none, so this half is a clean no-op. The profile's `verify`
  command was run in full under AC7.

### Independent review

Three fresh-context reviewers, none of which had seen the implementation.
Findings and dispositions; every finding reported is listed.

- [S] blame-history: no regressions. Every M01 fix it traced — the beamer
  guard, the depth-fold warning, the escape table, the content-preservation
  branches — intact or strengthened; it read the tightened image count and the
  extended manifests as strengthenings. Noted that `describe()` treats
  `entry=""` as absent where M01's inline expression did not, a latent-bug
  fix. No action.
- [S] prior-review record: no GitHub review-thread evidence exists (probe
  returned empty), so the archive was the surface. One finding — the new
  `include_text` call site inherits the unguarded gap M01 review N14 raised.
  FIXED: the guard now requires `quarto.doc.include_text` too, closing N14 for
  both call sites. Its second finding (bare unquoted values in the new pins)
  was already disclosed in Scope and on the ROADMAP; the row is widened to
  name the two new attributes and the false-pass direction.
- [O] diff-bug: 17 findings. Two were re-verified against the toolchain
  before acting. FIXED (14): the README claimed `see-also=` yields a page
  number and prescribed a build-breaking workaround (both false — `\seealso`
  discards the page exactly as `\see` does); the clash detector missed the
  see-vs-see-also case, which fails identically (verified: two differing
  encaps on one key and page fail the render); that detector had no test at
  all; the dual/single render pin was vacuous on target count; the
  both-attributes warning could claim an emission that did not happen; the
  `\providecommand`'s absence from documents that do not need it was
  untested; no cross-reference source key carried a special character; two
  warning messages stated outcomes untrue in some formats; non-ASCII targets
  were unprobed while the README promised more; `check_warning_count` counted
  lines rather than occurrences; the image count was pinned to a substring
  that collides with boilerplate; an injection-order comment gave a wrong
  reason; and `demo.qmd` still said "four supported span forms". FOLLOW-UP
  (2): the `: ` join is less ambiguous than `, ` rather than unambiguous, now
  stated in the README; the PDF cross-reference checks assert presence rather
  than counts (ROADMAP row). NO ACTION (1): the `.ilg` count is hand
  arithmetic, which the reviewer confirms is the right property — it is
  derived from the fixture's construction, not read back from the run, so it
  fails loudly rather than drifting.

No finding demonstrated an acceptance criterion failing inside the domain of
a procedure that criterion names, so none met the return floor. The two
severe ones were nonetheless defects in what users receive and were fixed on
the branch before the merge gate.

### Post-fix re-verification

`tests/run-tests.sh --self-test` exits 0 with 28 checks, up from 26. The
cross-reference probe now carries 256 entries derived by construction, all
256 accepted by makeindex and 0 rejected, and all 66 exact typeset strings
found — including the 16 special characters inside a cross-reference source
key and the two non-ASCII targets. The clash report is fenced in both
directions by a new fixture: it names each of the two differing-encap keys
once, stays silent on the two keys whose marks agree, stays silent in HTML,
and is proved discriminating on the missing and duplicated axes.

