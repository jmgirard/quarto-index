<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M067: The editor-metadata checks read what they claim to read

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** —

## Goal

The four M50 editor-metadata readers that misread their input — a quoted
value, a construct's term, an unreadable page, a page's own stated count —
read what their messages already claim they read.

## Scope

Surface tier: **internal** — the deliverable is the acceptance suite's own
readers over repo-internal artifacts (the shipped schema and snippets, the
tracked site pages, a captured page); no external consumer of this repo
relies on them. Each repair leaves what its check promises unchanged, which
is the disposition D-011 records for M24's own read-repair.

**In:** four read-repairs across two files that already share a module —
`tests/editorfixture.py` imports `editormeta`'s `parse_attrs`, `constructs`,
`ATTR_BLOCK` and `MARK_CLASS`, so the KI124 repair reaches the KI125 site.

- KI124: `parse_attrs`'s quoted-value scan (`tests/editormeta.py:113-119`)
  has no escape handling, so a value ends at the first `"` even where Pandoc
  escaped it; the scan then resumes mid-value and manufactures attribute
  names nobody wrote. The function's own docstring advertises exactly the
  robustness it lacks.
- KI125: `attribute_sites` (`tests/editorfixture.py:176-179`) advances its
  ordinal for every mark-class construct while `marked_terms` skips any
  `.index` construct that is not a span, so one skip shifts every later term.
- KI122: `check_docs` (`tests/editormeta.py:426-427`) partitions its
  arguments by `os.path.isfile` alone, so a page that is missing silently
  becomes a needle searched for in the surviving pages — a run that reddens
  naming `README.md` for a fault in the M24 capture.
- KI121: `table_values` requires the form table to carry `SYNTAX_FORMS = 10`
  rows and its message says "that page states exactly 10 supported forms",
  while the constant is a literal (`tests/editormeta.py:72`) and nothing
  reads the sentence at `site/syntax.qmd:7`.

Both KI124 and KI125 are **latent**: every snippet in
`_extensions/index/_snippets.json` writes its mark as a span, and the two
`::: {.qi-index-here}` div snippets carry a class both functions skip. Each
repair's evidence is therefore a planted construct, not a shipped one, on the
`m50_planted` per-clause model already at `tests/run-tests.sh:19878`.

**Out:**
- KI123 (`check_schema` requires a description only under `attributes:`,
  never over `classes:`, while `README.md:44-46` and `site/index.qmd:37-40`
  promise one apiece) — repairing it *widens* what the checker asserts rather
  than repairing what it reads, which is the checker-regress shape. Routed at
  the plan gate → the promise-changing suite row in `## Candidates`.
- The recovery-route checks → M066.
- KI117, KI119(c), KI120 → the outstanding reads-repairs candidate row.

## Acceptance criteria

- [ ] AC1. `parse_attrs` (`tests/editormeta.py:89-132`) reads a
      backslash-escaped quote inside a quoted attribute value as part of that
      value, ending the value at the next unescaped quote.
- [ ] AC2. `attribute_sites` (`tests/editorfixture.py:161-191`) pairs each
      mark-class construct with the term of that same construct, so a snippet
      whose `.index` construct is not a span shifts no later construct's
      pairing.
- [ ] AC3. `check_docs` (`tests/editormeta.py:419-441`) fails naming a
      documentation page it cannot read, rather than reclassifying that
      argument into a name to search for in the remaining pages.
- [ ] AC4. The row count `table_values` requires of `site/syntax.qmd`'s form
      table is read from that page's own stated sentence rather than from a
      literal in `tests/editormeta.py`.
- [ ] AC5. `tests/run-tests.sh` and `tests/run-tests.sh --self-test` each
      exit 0.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6

## Tasks

- [ ] T1. Give `parse_attrs`'s quoted-value scan escape handling: a
      backslash-escaped quote belongs to the value, and the value ends at the
      next unescaped quote. Keep it a scan, not a pattern — the docstring's
      stated reason (`entry="a=b"` is one attribute) still holds.
- [ ] T2. Plant a snippet body carrying an escaped quote in a value and show
      the pre-repair scan manufacturing a spurious attribute name, then the
      repaired scan reading one value. The plant is required because no
      shipped snippet carries the shape.
- [ ] T3. Pair terms with constructs by identity rather than by ordinal in
      `attribute_sites` — have `marked_terms` return the term against the
      construct it came from (or `None` where it skipped), so a skip cannot
      shift a later pairing. Plant a non-span `.index` construct ahead of two
      ordinary marks and show the mis-pairing before and its absence after.
- [ ] T4. Classify `check_docs`'s arguments by something other than
      existence — position or an explicit separator — and fail naming a page
      it cannot read. Extend the `m50_planted` block with the case an absent
      page produces, which today reddens naming the wrong file.
- [ ] T5. Read the form count from `site/syntax.qmd`'s own sentence and hold
      the table against it, so editing the sentence alone or adding a row
      alone each fail. Dispose of `table_values`'s narrowing rationale in the
      same pass: its docstring's ground (an `enum:` offering the empty string
      would be a demonstration read as syntax) is untrue of the swept domain,
      which carries no `mention=""` or `range=""` construct at all — correct
      the docstring to the ground that holds, or drop the narrowing.
- [ ] T6. Run `tests/run-tests.sh` and `tests/run-tests.sh --self-test`
      sequentially (PROFILE: never two invocations at once) and record both
      check counts and exit codes.

## Work log

- 2026-08-31: created by /milestone-plan.
- 2026-08-31: plan gate chose pairing by identity in `attribute_sites` (T3) over teaching `marked_terms` to return a term for every mark-class construct, because a non-span construct has no bracketed term to return and inventing one would put a value in the fixture no page wrote; falsified by a construct kind that does carry a term this pairing cannot reach.
- 2026-08-31: plan gate chose keeping `parse_attrs` a hand-written scan (T1) over replacing it with Pandoc's own parse of the block, because reading the attribute through a render would make an internal-tier check depend on a process boundary and a Pandoc version; falsified by the scan and Pandoc disagreeing on a shape the snippets come to carry.
- 2026-08-31: plan gate routed KI123 out rather than repairing it here, because its repair widens what `check_schema` asserts where the other four repair what a reader reads; falsified by a decision that `check_schema` should hold the docs' description promise after all.
- 2026-08-31: criteria audit ran in REDUCED mode (internal tier, no RB-tripwire tag) over the five drafted criteria in a fresh-context [O] reader. One finding, fixed before writing: AC1 promised agreement with Pandoc's own parse on a rendered fixture, which crosses a process and environment boundary and binds a plant rather than the reader — restated as the reader's own behavior. Two cited ranges were corrected in passing (`parse_attrs` 89-132, `check_docs` 419-441).

## Decisions

## Review
