# M34: The non-Latin-1 recipe names a font TeX Live still maintains

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP3
- **Branch/PR:** `m034-stix-two-recipe`

## Goal

An author copying README's `### Terms outside Latin-1` recipe installs a font
package TeX Live still maintains, and the suite proves the recipe under it.

## Scope

Surface tier: **user-facing** — the recipe block is text an author copies, and
`examples/unicode.qmd` is the fixture README points them at.

**In:** the `stix` → `stix2-otf` swap (STIX Two Text) in README's recipe block,
its font and install prose, and `examples/unicode.qmd`'s front matter;
re-proving the printed set and the four control renders under the new font;
the suite's claims rows, its font guard and the control-derivation assertions
that pin the fixture's `mainfont` block shape; a decision entry recording the
choice and the cost the gate accepted.

**Out:** the seven suite-hardening gaps M33's review left (candidate row stands,
promoted separately). A skip path for a missing font — the gate chose to keep
the run stopping. Any font other than STIX Two Text: no font in a default
TinyTeX covers Cyrillic (probed at the plan gate), so the install step stays
whichever font the recipe names. CJK and RTL stay unsupported → KI6.

## Acceptance criteria

- [ ] AC1: README's `### Terms outside Latin-1` copyable YAML block names
      `pdf-engine: xelatex` and `STIXTwoText` with its four face options, and
      every line of that block appears in `examples/unicode.qmd`'s front
      matter — the direction the suite's block check reads, over the block's
      own lines.
- [ ] AC2: `examples/unicode.qmd`, rendered to PDF under its own front matter
      and captured, prints every term it marks as its own entry line in the
      typeset index — the terms enumerated from the fixture by
      `tests/unicodeprint.py marks`, each one's entry line read out of the
      captured PDF by `tests/unicodeprint.py entries`, locators removed and
      compared in NFC against the expected precomposed list that check states.
- [ ] AC3: under the new font, three of the four controls the suite derives
      from `examples/unicode.qmd` by one edit each reproduce their recorded
      states — (a) `pdf-engine: pdflatex` exits non-zero and its LaTeX log
      says `not set up for use with LaTeX` naming a Greek character the
      fixture marks; (b) `mainfont` left at its default exits 0, its index
      prints the fixture's ASCII term and none of its Greek terms; (c) one
      added CJK term exits 0, the index prints the ASCII term and not the CJK
      term.
- [ ] AC4: README's section names STIX Two Text and the command that installs
      it, a search of README for `tlmgr install` returns only lines naming
      `stix2-otf`, and the section's "no engine set" paragraph states what the
      no-engine control render does under the new font — naming the term that
      does not print as itself where one does not, or saying the index prints
      correctly where none does.
- [ ] AC5: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass,
      at a check count no lower than the merge base's.

## Coverage

- AC1 → T2, T3
- AC2 → T1, T2, T3
- AC3 → T1, T5
- AC4 → T1, T3, T4
- AC5 → T4, T5, T6

## Tasks

- [x] T1: `tlmgr install stix2-otf`; render `examples/unicode.qmd` with the
      STIX Two Text block and read the printed index for every term it marks;
      then run the four controls by hand and record each one's actual
      signature, the no-engine render's printed index included.
- [x] T2: rewrite `examples/unicode.qmd`'s front matter to the STIX Two Text
      block (`examples/unicode.qmd:1`).
- [x] T3: rewrite README's recipe block, its font and install prose, and its
      "no engine set" paragraph against T1's captured renders
      (`README.md:265`).
- [x] T4: update the claims rows (`tests/run-tests.sh:509`) and the font guard
      (`tests/run-tests.sh:1364`) to name `stix2-otf` and
      `STIXTwoText-Regular.otf`; the guard keeps stopping the run.
- [x] T5: update the control-derivation assertions that pin the fixture's
      `mainfont` block shape (`tests/run-tests.sh:4287`) and re-run all four
      controls under the new font.
- [x] T6: run `tests/run-tests.sh --self-test`; compare the check count
      against the merge base.
- [x] T7: append the decision entry; update KI6 and the DESIGN collation
      convention where they name the recipe's font; strike the candidate row.

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan gate criteria audit ran in full mode ([O], fresh context, user-facing tier) and returned 10 findings over 6 drafted criteria, all fixed here — AC1's symmetric line-for-line match narrowed to the direction the check reads, AC2's domain moved from the check's hand-stated term list to the fixture's own marks, AC3's "one YAML edit" corrected and its pins replaced by the signatures themselves, and the drafted AC4/AC5/AC6 dropped as instrument and recording-act promises (the font guard, the claims table, the DESIGN edit), the first two re-entering as tasks T4 and T7 and the third reworded to bind README's own content.
- 2026-08-24: plan gate chose STIX Two Text over keeping the obsolete `stix` package and over naming no font at all, because the successor package the obsolescence notice points at holds the coverage with one install command and no second step for the reader; falsified by evidence that STIX Two Text fails to print a term of the proven set, or that a font inside a default TinyTeX covers Greek, Cyrillic and Latin beyond Latin-1 together.
- 2026-08-24: T1 — `stix2-otf` installed; all four faces resolve by `kpsewhich`. Under STIX Two Text the recipe render and controls (a), (b) and (c) reproduce their M33 signatures exactly, but control (d), the no-engine path, now exits 0 and prints all eight terms correctly where under STIX it dropped `Việt` — README's third failure path and the suite's (d) check both have to change, the branch AC4 anticipated.
- 2026-08-24: T1 — `mainfont: STIX Two Text` with no options block also prints all eight terms, but `pdffonts` shows it embeds macOS's own `STIXTwoText` TrueType while the by-file form embeds the package's `STIXTwoText-Regular` Type 0C; the by-file recipe AC1 names is what loads the installed package. The no-engine render embeds the package face too, so its success is not a fallback.
- 2026-08-24: T2 — `examples/unicode.qmd` front matter swapped to `mainfont: STIXTwoText`; its body's by-file sentence reworded, since "the plain family name is not findable" is false for this font and the operating-system copy is the real reason.
- 2026-08-24: question gate — the recipe keeps `pdf-engine: xelatex` with the section stating that the font alone prints correctly on Quarto 1.10 and the engine line is what holds if Quarto's default changes; README states the by-file reason as the operating-system copy rather than findability.
- 2026-08-24: plan gate chose to keep the suite stopping when the font is absent over skipping the recipe renders, because a skip line reads as a pass to anyone scanning the output and this suite's evidence rests on nothing passing unrun; falsified by evidence that the stop keeps contributors from running the rest of the suite in practice.
- 2026-08-24: T3 — README's recipe block, font and install prose, and "no engine set" paragraph rewritten against T1's renders; the by-file rationale now names the operating-system copy rather than findability, and the third path becomes a build that succeeds with the index correct.
- 2026-08-24: T4 — claims rows renamed the font and the install package, `fail-noengine-silent` replaced by two rows for the new paragraph, and one row added for the by-file reason, marked in the section comment as held verbatim only since no render here executes it; the font guard now probes `STIXTwoText-Regular.otf` and names `tlmgr install stix2-otf`, still stopping the run.
- 2026-08-24: T5 — the control-derivation assertions needed no change: only the `mainfont` value moved, so the block-shape regex still matches and all four controls derive. Control (d)'s check flipped from `absent … Việt` to `entries` over the full term list, and the now-unused `M33_VIET` was removed.
- 2026-08-24: T7 — KI6 marked as re-established under STIX Two Text; the collation convention and IP2 name the README section rather than a font, so neither changed. D-018 was already appended at the plan gate, and the stix/GP3 candidate row was graduated into this milestone then, so neither was outstanding.
- 2026-08-24: the fixture's own render under STIX Two Text emits no `Missing character` line at all, where under `stix` it emitted one for U+1EC7. README's caveat about that line is a general xelatex fact and stands; the suite comment that cited the fixture's own log as the example was corrected.
- 2026-08-24: T6 — branch runs 351 checks plain and 487 with `--self-test`, both green; the merge base (fd47dcc), run in a throwaway worktree under the same toolchain, runs 351 and 487 too, so neither count dropped.
- 2026-08-24: all tasks done, suite green; status to review.

## Decisions

### 2026-08-24: the recipe keeps `pdf-engine: xelatex` though the font alone now prints correctly

**Context:** under STIX Two Text the no-engine control — the fixture with its
`pdf-engine:` line removed — exits 0 on Quarto 1.10's lualatex and prints all
eight terms as their own entry lines, where under `stix` it dropped `Việt`. The
engine line is no longer what makes the index right on this Quarto.
**Decision:** the recipe keeps the engine line. README's "no engine set"
paragraph states that the index prints correctly today and tells the reader to
set the engine anyway, because it pins the behavior to what the recipe states
rather than to whichever engine their Quarto picks; the suite's control (d)
flips from an absence check to the same positive reading the recipe render
gets, over the same term list.
**Consequences:** the section's three paths are now two failures and one that
works. `M33_VIET` leaves the suite, and the claims table loses
`fail-noengine-silent` for two rows that state the new paragraph. A Quarto
whose default engine changes falsifies the paragraph's "prints correctly"
sentence and the control that pins it, and leaves the recipe itself untouched
— which is the reason for keeping the line.

## Review
