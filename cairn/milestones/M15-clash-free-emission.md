# M15: A term marked both plainly and with a cross-reference builds

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1, GP2
- **Branch/PR:** `m15-clash-free-emission`

## Goal

A document that marks one term with a locator in one place and a
cross-reference in another builds instead of failing, and its index carries
both.

## Scope

Surface tier: **user-facing** — it changes which documents build and what a
printed index shows (GP1).

**In:** the LaTeX back-end's emission for a *contested key* — an index key
whose marks carry more than one distinct encapsulation. Two shapes, two
repairs, because one repair would change what the other prints:

- A key with at least one plain locator mark: the cross-reference leaves the
  encap channel and is folded into the entry's printed text, identically on
  every plain mark of the key, so the index tool merges them into one entry
  keeping every locator. The cross-reference marks of that key emit nothing of
  their own, so a cross-reference still carries no locator.
- A key with only cross-reference marks: every mark emits one common encap
  over the key's whole target set (M02's `\quartoindexseeboth`). Identical
  encaps are what the tool folds, the page is discarded as it is today, and
  the printed form is unchanged.

Which keys are contested is known only once every mark has been seen, so the
argument each mark emits is decided in a pass that has seen them all. The
clash report is replaced by one describing what the extension did.

**Out:** the HTML back-end, which has no encap channel and already prints a
locator and a cross-reference on one entry — untouched. Whether an
*uncontested* cross-reference mark should carry a locator → the existing
candidate row, unchanged by this milestone. The written-levels/LaTeX-fold
divergence → its candidate row. A suite run on a clean checkout → the existing
candidate row; every criterion here is evidenced in a warmed tree.

## Acceptance criteria

- [ ] AC1 A document marking one term plainly and with a cross-reference
      renders to PDF instead of failing. Evidence: `examples/xref-conflict.qmd`
      rendered to PDF exits 0, and its log carries neither `error generating
      index` nor `Conflicting entries: multiple encaps for the same page under
      same key` — the two strings today's failing render emits, recorded in
      the work log below at plan time.

- [ ] AC2 The compiled index matches an exhaustive hand-derived manifest over
      **every** line it prints, not over a named subset — the contested
      entries, the uncontested controls (`mu`, two identical cross-references
      the tool folds; `nu`, marked plainly twice) and every unrelated entry
      alike, each row stating printed text, level and locator count. The
      manifest states how a wrapped continuation line is derived, since
      `tests/pdfindex.py` returns one as its own entry. A contested term's
      plain marks sit on two pages and its cross-reference mark on a third, so
      a locator count of 2 rather than 3 is what says the cross-reference mark
      contributed none.

- [ ] AC3 Every way two marks can contest one key is exercised, not one
      exemplar standing in for the family: plain against `see=`, plain against
      `see-also=`, `see=` against `see-also=`, `see=` against a *different*
      `see=`, and a both-attributes mark against a plain mark — each at the top
      level, and one of them on a sub-entry key. Evidence: each pairing named
      in the fixture with its own manifest row from AC2, and the count of
      printed entries whose term begins with each contested term asserted to
      be 1.

- [ ] AC4 A cross-reference folded into an entry's printed text is quoted for
      the field it now sits in. Evidence: a contested key whose target carries
      every character README pins as escaped — `! " < >` and the LaTeX
      specials — rendered to PDF, the render exiting 0 and each character
      asserted to typeset in the compiled index, the same bar
      `examples/xref-escaping.qmd` already holds the encap channel to (IP2).

- [ ] AC5 No report tells an author the render can fail from rival
      encapsulations. Evidence: over each `warn()` call's **joined** message —
      the list the distinctness scan already builds, never a single literal,
      which the M13 lesson records a per-literal test cannot see — no message
      carries the phrase `the index tool rejects the pair and the render
      fails`; and the replacement report's full text asserted present, once per
      contested key, over the fixture.

- [ ] AC6 The README and DESIGN claims this milestone falsifies are corrected
      and the new behaviour is pinned. Evidence: the three passages naming the
      old outcome — README's "can fail the build" paragraph, its "The clash
      warning is LaTeX-only" row, and its claim that a cross-reference is
      written through the encapsulation channel — asserted absent, and their
      replacements asserted present, by the suite's existing README-claims
      comparison; DESIGN's LaTeX back-end paragraph updated in the same commit.

## Coverage

- AC1 → T1, T3, T7
- AC2 → T3, T4, T7
- AC3 → T1, T3, T7
- AC4 → T5, T7
- AC5 → T6, T7
- AC6 → T9

## Tasks

- [ ] T1 Extend `examples/xref-conflict.qmd` with AC3's five pairings, one on
      a sub-entry key, and place one contested term's marks across three pages
      so AC2's locator count discriminates. Record the failing PDF render's
      exit status and its two failure strings before changing any code.
- [ ] T2 Split a warn-free index-key derivation out of `index_argument`
      (`index.lua`), which today warns from `clamp_levels` as a side effect, so
      the first Span pass can compute each mark's key and encap without
      emitting a mark's warnings twice.
- [ ] T3 Decide each mark's LaTeX argument in the pass that has seen every
      mark: a contested key with a plain mark folds its cross-references into
      the printed text; a contested key without one emits a common combined
      encap; an uncontested key is untouched.
- [ ] T4 Emit nothing for a cross-reference mark on a contested key that has a
      plain mark, so a cross-reference still carries no locator.
- [ ] T5 Quote the folded printed field for what the index tool reads there —
      `!`, `@`, `|` and `"` are its operators in that field as in the encap
      channel — and probe it with README's escaped-character set.
- [ ] T6 Replace the clash report with one describing what was done; update the
      distinctness count and the three existing clash checks.
- [ ] T7 Suite: AC2's exhaustive manifest, AC3's pairings, AC4's escaping
      assertions, and a guard that no uncontested key's emission changed —
      quantified over every example the suite renders to latex, discovered by
      glob rather than by a list.
- [ ] T8 Prove each new check discriminating: commit the fix, then revert the
      emission change and record which checks fail.
- [ ] T9 Correct DESIGN's LaTeX back-end paragraph and README's three
      falsified passages, pin the replacements, and run
      `tests/run-tests.sh --self-test`.

## Work log

- 2026-08-19: created by /milestone-plan, absorbing the candidate row the user asked on 2026-08-19 be fixed rather than only reported (M02 Decisions lineage).
- 2026-08-19: baseline recorded before any code changed — `quarto render examples/xref-conflict.qmd --to pdf` exits 1 with `ERROR: compilation failed- error generating index` and `Conflicting entries: multiple encaps for the same page under same key.`
- 2026-08-19: plan gate chose folding the cross-reference into the entry's printed text over keeping it a separate page-gobbled item, because the second prints the term twice in adjacent lines; both were verified against makeindex 2.18 to emit zero warnings where today's emission emits the fatal conflict. Falsified by evidence that a reader reads "cats, see Felines, 1, 3" as two entries rather than one.
- 2026-08-19: plan gate chose a common combined encap over folding for a key whose marks are all cross-references, because folding would give such a key a locator it does not have today and the gate ruled that out. Falsified by evidence that two marks carrying one combined encap can still differ.
- 2026-08-19: plan gate chose reading rival encaps as output the extension emitted wrongly over recording a trade against GP2 (D-003). Falsified by a case where the tool rejects output no alternative emission could avoid.
- 2026-08-19: criteria audit (full mode, fresh-context [O] reader) returned 12 findings. Two were fatal and are fixed above: AC5 tested a phrase no single literal carries, so it would have passed against the unmodified filter, and AC3's exhaustive manifest named four of the eight lines the index prints. AC4's two-fixture list was narrowed to a globbed domain, the verify-slot criterion was dropped as instrument-bound and became T9, an escaping criterion was added for the printed field (IP2), and a README/DESIGN criterion was added (GP1). GP2 and the locator question went to the gate.

## Decisions

## Review
