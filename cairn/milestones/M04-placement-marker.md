# M04: Index placement marker

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP4, GP5
- **Branch/PR:** m04-placement-marker / https://github.com/jmgirard/quarto-index/pull/4

## Goal

Ship a format-neutral placement marker — an empty div with class
`qi-index-here` — that puts the index where the author wrote it, in every
back-end, with today's auto-append preserved when no marker is present.

## Scope

Surface tier: **user-facing** — new documented authoring syntax for the
extension's community audience.

**In:** marker recognition (top-level blocks only); HTML back-end emits the
index section at the marker's site; LaTeX back-end emits `\printindex` at the
marker's site; append suppression when a marker placed; misuse handling
(duplicate, nested, no-marks) warned in every format; pass-through residue
sweeps; docs. Marker token is `qi-index-here`, deliberately distinct from the
generated section id `qi-index` (ROADMAP F11 row records that collision
class).

**Out:** book projects (marker-as-aggregation-site) → M05. Nested-marker
placement support → widen later compatibly if demanded (candidate behavior:
top-level only, stated in README). Letter groups, sort keys → existing
candidate rows.

## Acceptance criteria

- [x] AC1: In a single-document HTML render whose source carries one marker
      between two body sections, the index section appears at the marker's
      position — after the first section's content and before the second's —
      and nowhere else on the page (structural position check over the
      rendered page), and the page's index content matches its hand-derived
      manifest.
- [x] AC2: In that same document rendered to LaTeX, exactly one `\printindex`
      is emitted, at the marker's position between the two sections' text
      (asserted on the emitted `.tex`), and the document renders to PDF whose
      index slice — bounded from the Index heading to the following section
      heading's text, not end-of-file — contains each fixture term.
- [x] AC3: Every existing LaTeX fixture's `.tex` output is byte-identical to
      the merge base, per the byte-diff procedure extended to loop over all
      existing LaTeX fixtures; the full suite passes with a printed check
      count not lower than at the merge base.
- [x] AC4: Misuse renders safely in every output format, warnings emitted
      before the back-end branch (warning-split check extended): a second
      marker warns identifying it by position and leaves no element residue;
      a nested (non-top-level) marker warns, places nothing, leaves no
      residue; a marker in a document with no index marks leaves no residue
      and emits no index section or `\printindex` in either back-end —
      residue asserted structurally (no empty div/group), not by token grep.
- [x] AC5: The marker fixture rendered to gfm contains no residue of the
      marker (no marker element, no empty div, no token), and the marker
      fixture added to the existing beamer render compiles clean with no
      residue (IP2).
- [x] AC6: The README documents the marker with an exemplar row in the
      suite's `SUPPORTED_FORMS` roster, and the now-false sentence
      "Placement is automatic; there is no option to put the index elsewhere
      yet" is captured in `README_STALE` so it cannot survive verbatim.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T3, T4
- AC3 → T4
- AC4 → T1, T2, T3, T4
- AC5 → T4
- AC6 → T5

## Tasks

- [x] T1: Marker recognition (top-level `doc.blocks` walk; class
      `qi-index-here`), format-neutral misuse warnings (duplicate by
      position, nested, no-marks); fixture `examples/marker.qmd` (marker
      between two sections; duplicate + nested + no-marks variants) with
      hand-derived manifests.
- [x] T2: HTML back-end: emit section at the marker site, suppress append
      when a marker placed (index.lua `append_html_index`, Pandoc pass).
- [x] T3: LaTeX back-end: `\printindex` at the marker site, suppress
      append; shared marker resolution with T2 so the two back-ends cannot
      drift.
- [x] T4: Suite: document-order position primitive in `tests/htmlindex.py`;
      bounded PDF index slice; byte-diff loop over all existing LaTeX
      fixtures; warning-split check extension; gfm + beamer marker-fixture
      renders with structural residue checks; merge-base check-count pin.
- [x] T5: Docs: README marker section (+ `SUPPORTED_FORMS` and
      `README_STALE` rows), DESIGN.md architecture lines updated ("one
      `\printindex` appended" / "index section appended" become
      marker-aware).

## Work log

- 2026-08-17: created by /milestone-plan.
- 2026-08-17: criteria audit ran in full mode, two rounds ([O] fresh reader; second round after the gate widened the marker to all back-ends): round 1 — AC positives unpinned, missing location axes, undecidable book warning, instrument-bound suite clause; round 2 — unsound end-of-file PDF slice, byte-diff covering only demo.qmd, unenumerable "no assertion weakened" clause, vacuous pass-through sweep, marker/section-id name collision, missing docs criterion. All fixed in the wording above or moved to tasks; none left open.
- 2026-08-17: plan gate chose one marker honored by all back-ends over a book-HTML-only marker because one syntax must not carry per-format meaning (IP1) and it absorbs the placement candidate row; falsified by a back-end where site-placement is impossible to realize.
- 2026-08-17: plan chose top-level-only marker recognition (nested warns, places nothing) over recognize-anywhere because `\printindex` inside a group/environment is an IP2-class render risk; falsified by evidence that nested placement is safe in both back-ends or by author demand.
- 2026-08-17: plan chose marker token `qi-index-here` over reusing `qi-index` because the generated section already owns that id and one string with two meanings is the F11 collision class; falsified by nothing cheaper than a rename before first release (IP3).
- 2026-08-17: implementation gate settled three open choices (non-empty marker content, nested-marker fallback, duplicate-marker precedence); see Decisions.
- 2026-08-17: T1 — marker recognition (`qi-index-here`), format-neutral misuse warnings (nested, duplicate-by-position, no-marks, non-empty), fixtures `marker.qmd`, `marker-misuse.qmd`, `marker-nomarks.qmd`.
- 2026-08-17: T2+T3 — one `place_index` both back-ends call (HTML section and `\printindex` at the marker site, append when no marker, marker removed either way), so the two cannot drift; the LaTeX per-branch `marks_emitted` counter became one format-neutral `marks_seen`, which the marker's no-marks warning needs.
- 2026-08-17: T4 — suite: document-order primitive (`position`, `position_of_id`, `empty_divs`) in `tests/htmlindex.py`; M04 checks for marker placement (HTML position, `.tex` ordering, bounded PDF slice), misuse (nested/duplicate/non-empty/no-marks, each warned once in HTML+LaTeX+gfm, discrimination-tested), structural residue incl. a byte-identical twin-render pin, gfm + beamer residue; `tests/byte-diff.sh` for the merge-base LaTeX loop; the run now prints its own check count (68 with --self-test).
- 2026-08-17: T4 found a defect the plan did not know: a mid-document `\printindex` closes imakeidx's `.idx` stream, so every mark written after the marker went to the log and vanished from the index (verified on `marker.qmd`: `gamma`'s `\indexentry` in `marker.log`, absent from `marker.idx`). Fixed by loading imakeidx with `noautomatic` in marker documents only; `gamma` in the PDF index slice is the regression pin.
- 2026-08-17: T5 — README gains a "Placing the index" section (marker syntax, the four rules, why a marker document loads imakeidx with `noautomatic`), the LaTeX/HTML emission paragraphs and the examples list are marker-aware, the stale automatic-placement sentence is gone and pinned in `README_STALE`, the marker exemplar is a `SUPPORTED_FORMS` row, and DESIGN.md's Pandoc-pass and back-end lines record marker resolution and shared placement.
- 2026-08-17: all tasks done; suite green at 68 checks (--self-test) against 62 at the merge base, and `tests/byte-diff.sh` reports all 8 merge-base fixtures byte-identical. Status -> review.
- 2026-08-17: review corrects the 2026-08-17 completion line above: its "62 at the merge base" was this branch's own count without --self-test, not a merge-base figure. Measured at review from a separate clone at `main`: the merge base prints 44 `ok` lines with --self-test, against this branch's 68.
- 2026-08-17: review verified three of the [O] findings by hand before triage: F1 reproduced (a planted failure inside the wrapper still printed "All checks passed", exit 0); F2 confirmed in the emitted preamble (`\@ifpackageloaded{imakeidx}{}{...}` skips the option for a document that already loads imakeidx); F3 confirmed by render (an id written on the marker div is dropped, no warning). The verification run itself carried zero FAIL lines, so the AC evidence above stands as recorded.

## Decisions

- 2026-08-17: A marker div carrying content keeps that content, printed where
  the marker was written, and warns — deleting what an author wrote inside a
  marker is the silent corruption IP2 forbids. Chosen at the implementation
  gate over dropping the content or refusing to read a non-empty div as a
  marker.
- 2026-08-17: A marker below the top level warns, places nothing, and leaves
  the index in its automatic end-of-document position rather than suppressing
  it — a misplaced marker must not cost an author their index (GP4).
- 2026-08-17: With more than one top-level marker the index goes at the first;
  every later one warns naming its ordinal and its top-level block position,
  and is removed. Chosen over last-wins, which is harder to predict in a
  document read top to bottom.

## Review

Evidence from a fresh `tests/run-tests.sh --self-test` run and
`tests/byte-diff.sh` on 2026-08-17 at commit fd65748 (68 checks, exit 0).

- AC1 (met): `examples/marker.html` — the generated section matches all 4
  hand-derived manifest rows in order; document-order check puts the section
  after the mark written before the marker and before the mark written after
  it (position 30), nested in neither body section; no index entry renders
  outside the one section; every id unique and all 4 index links resolve.
- AC2 (met): `examples/marker.tex` — exactly one `\printindex`, between
  `\section{Before the marker}` and `\section{After the marker}`; the 3-row
  `\index{}` manifest matches (4 commands). PDF: the index slice bounded from
  the `Index` heading to the following section's heading text lists all 4
  derived terms, `gamma` (marked *after* the marker) included.
- AC3 (met): `tests/byte-diff.sh` renders all 8 fixtures the merge base
  carries, once with each filter, and reports every `.tex` byte-identical.
  Check count: the branch's suite prints 68 checks (`--self-test`, exit 0);
  the merge base's suite, run from a separate clone at `main`, printed 44 `ok`
  lines (exit 0) — measured, not recalled. Not lower.
- AC4 (met): the nested, duplicate-by-position and non-empty warnings each
  fire exactly once in HTML, LaTeX and gfm, and the no-marks warning once in
  each format (zero in the marker-free twin); the duplicate and no-marks
  checks also pass the planted-defect discrimination harness. One
  `\printindex` at the first marker in a document carrying three; content
  written inside a marker survives in all three formats; no marker element
  and no empty div in any marker fixture's HTML; with no index to place, all
  three renders are byte-identical to the same document with the marker
  deleted by hand (the twin is pinned to be exactly that document).
- AC5 (met): `examples/marker.md` (gfm) carries no marker element, no div,
  no index section and none of the tokens `qi-index-here` / `qi-index` /
  `printindex`, with visible term text kept; the marker fixture added to the
  beamer render compiles clean with no index token and no marker residue.
- Independent review, three fresh-context lenses. [S] blame-history: no
  findings (every rename/restructure traced to recorded intent). [S]
  prior-review record: no findings; notes M03's F11 collision class is
  addressed rather than reintroduced. [O] diff-bug: 13 findings, verified and
  triaged below.
- AC6 (met): the marker exemplar `::: {.qi-index-here}` is a
  `SUPPORTED_FORMS` row and appears verbatim in README.md (7 exemplars
  checked); "Placement is automatic; there is no option to put the index
  elsewhere yet" is a `README_STALE` row and is absent from README.md (4
  stale sentences checked).
