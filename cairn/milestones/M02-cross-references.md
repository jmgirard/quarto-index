# M02: Cross-references (see / see also)

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M01
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP1, GP5, GP6
- **Branch/PR:** m02-cross-references

## Goal

Add cross-reference index entries — see and see also — to the marking syntax,
realized by the LaTeX back-end with format-neutral target semantics.

## Scope

Surface tier: **user-facing** — new documented syntax the community consumes.

**In:** `see=` and `see-also=` span attributes on any mark form; target values
are structured level data (`!` separates, `!!` literal), never raw back-end
code (D-001/IP1). Source entry = `entry=` if present, else the visible term; a
cross-reference replaces the locator (indexing convention). Both attributes on
one mark: warn, emit both. LaTeX realization settled by an empirical spike
(hyperref rewrites `\index` arguments at the first `|` — the encap channel).
Misuse warnings, escaping probes, docs.

**Out:** HTML realization of cross-references → candidate row (HTML index
generation). Sort keys, page-range/styling, multiple indexes → existing
candidate rows. No new exclusions.

Known holes carried over (noted, not criteria): bare unquoted attribute
values escape the source pins (existing ROADMAP row); AC1's pin regex matches
quoted values only.

## Acceptance criteria

- [ ] AC1: `tests/run-tests.sh` renders `examples/demo.qmd` to LaTeX and
      every `\index{}` argument matches the hand-derived entry manifest,
      extended with one row per cross-reference (a mark carrying both
      attributes contributes two) — each row's exact argument hand-derived
      from the emission form T1 records in the milestone's Decisions section,
      including rows probing `!`-level parsing and `!!` literals inside
      see-targets. A completeness pin counts `see=`/`see-also=` occurrences
      in `examples/demo.qmd` and fails unless the cross-reference manifest
      row count matches. Manifest rows are never copied from filter output.
- [ ] AC2: `examples/demo.qmd` compiles to PDF through Quarto's own engine;
      the `pdftotext` extraction of the index section shows, for each
      cross-reference manifest row of AC1, the source entry followed by its
      cross-reference text, per a hand-derived expected list whose
      multi-level join form and see-also label derive from T1's recorded
      decision (GP6).
- [ ] AC3: A cross-reference escaping probe fixture (extending
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
- [ ] AC4: Rendering `examples/demo.qmd` to HTML and to beamer succeeds; the
      visible text of every cross-reference mark is preserved; no
      `see=`/`see-also=` value leaks into rendered text, per the suite's
      no-leak mechanism with its source pin extended to the two new
      attributes; and a cross-reference mark on content with no derivable
      text (in `examples/content.qmd`) indexes nothing and deletes nothing,
      in HTML and LaTeX.
- [ ] AC5: Each defined misuse case — (a) a cross-reference mark with no
      source entry (no `entry=`, no visible text), (b) a mark carrying both
      `see=` and `see-also=`, exercised in `examples/demo.qmd` so AC1's
      manifest and AC2's PDF list cover its output — emits its own named
      warning, distinct from each other and from every existing warning,
      identified in the render log by distinctive message text, with the
      render still exiting successfully; the defined output for each case is
      asserted (case a: nothing emitted; case b: both cross-references
      emitted); and the `--self-test` proves each warning check discriminates
      (the check fails on a run or fixture lacking its warning).
- [ ] AC6: The README documents the cross-reference forms — the syntax, the
      format-neutral semantics of the target value (structured `!` levels,
      `!!` literal), the see-replaces-locator semantics, and current
      per-format behavior. The suite's normative supported-forms list is
      restructured as label/exemplar pairs, includes the new forms, and
      fails if any syntax exemplar does not appear verbatim in the README.
- [ ] AC7: `tests/run-tests.sh --self-test` (the profile's verify command)
      exits clean.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T3, T4
- AC3 → T3, T5
- AC4 → T2, T4
- AC5 → T2, T4
- AC6 → T6
- AC7 → T4, T5, T6

## Tasks

- [ ] T1: Spike: empirically probe cross-reference emission under Quarto's
      PDF pipeline — hyperref's first-`|` rewrite, `\see`/`\seealso`
      availability under imakeidx, multi-level target join, any characters
      unrealizable in encap context — and record the chosen emission form,
      join form, and label source as a milestone Decisions entry.
- [ ] T2: Parse and validate `see=`/`see-also=` in
      `_extensions/index/index.lua`, format-neutral layer: structured
      levels, source resolution (`entry=` else visible term), misuse
      warnings (a)/(b) with their defined outputs.
- [ ] T3: LaTeX realization per T1's decision, including encap-context
      escaping (second table or recorded equivalent).
- [ ] T4: Extend `examples/demo.qmd`, `examples/content.qmd`, and
      `tests/run-tests.sh`: cross-reference manifest rows + completeness
      pin, PDF expected list, no-leak pin extension, misuse checks,
      self-test discrimination coverage.
- [ ] T5: Author the cross-reference escaping probe fixture and its suite
      checks: compile, `.ilg` acceptance, exact-text typeset assertions,
      union-table pin, graceful-degradation assertions for any T1-excluded
      character.
- [ ] T6: README cross-reference documentation; normative supported-forms
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

## Decisions

## Review
