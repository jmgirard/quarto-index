<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M067: The editor-metadata checks read what they claim to read

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Branch/PR:** m067-editor-metadata-readers · https://github.com/jmgirard/quarto-index/pull/67

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

- [x] AC1. `parse_attrs` (`tests/editormeta.py:89-132`) reads a
      backslash-escaped quote inside a quoted attribute value as part of that
      value, ending the value at the next unescaped quote.
- [x] AC2. `attribute_sites` (`tests/editorfixture.py:161-191`) pairs each
      mark-class construct with the term of that same construct, so a snippet
      whose `.index` construct is not a span shifts no later construct's
      pairing.
- [x] AC3. `check_docs` (`tests/editormeta.py:419-441`) fails naming a
      documentation page it cannot read, rather than reclassifying that
      argument into a name to search for in the remaining pages.
- [x] AC4. The row count `table_values` requires of `site/syntax.qmd`'s form
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

- [x] T1. Give `parse_attrs`'s quoted-value scan escape handling: a
      backslash-escaped quote belongs to the value, and the value ends at the
      next unescaped quote. Keep it a scan, not a pattern — the docstring's
      stated reason (`entry="a=b"` is one attribute) still holds.
- [x] T2. Plant a snippet body carrying an escaped quote in a value and show
      the pre-repair scan manufacturing a spurious attribute name, then the
      repaired scan reading one value. The plant is required because no
      shipped snippet carries the shape.
- [x] T3. Pair terms with constructs by identity rather than by ordinal in
      `attribute_sites` — have `marked_terms` return the term against the
      construct it came from (or `None` where it skipped), so a skip cannot
      shift a later pairing. Plant a non-span `.index` construct ahead of two
      ordinary marks and show the mis-pairing before and its absence after.
- [x] T4. Classify `check_docs`'s arguments by something other than
      existence — position or an explicit separator — and fail naming a page
      it cannot read. Extend the `m50_planted` block with the case an absent
      page produces, which today reddens naming the wrong file.
- [x] T5. Read the form count from `site/syntax.qmd`'s own sentence and hold
      the table against it, so editing the sentence alone or adding a row
      alone each fail. Dispose of `table_values`'s narrowing rationale in the
      same pass: its docstring's ground (an `enum:` offering the empty string
      would be a demonstration read as syntax) is untrue of the swept domain,
      which carries no `mention=""` or `range=""` construct at all — correct
      the docstring to the ground that holds, or drop the narrowing.
- [x] T6. Run `tests/run-tests.sh` and `tests/run-tests.sh --self-test`
      sequentially (PROFILE: never two invocations at once) and record both
      check counts and exit codes.

## Work log

- 2026-08-31: created by /milestone-plan.
- 2026-08-31: plan gate chose pairing by identity in `attribute_sites` (T3) over teaching `marked_terms` to return a term for every mark-class construct, because a non-span construct has no bracketed term to return and inventing one would put a value in the fixture no page wrote; falsified by a construct kind that does carry a term this pairing cannot reach.
- 2026-08-31: plan gate chose keeping `parse_attrs` a hand-written scan (T1) over replacing it with Pandoc's own parse of the block, because reading the attribute through a render would make an internal-tier check depend on a process boundary and a Pandoc version; falsified by the scan and Pandoc disagreeing on a shape the snippets come to carry.
- 2026-08-31: plan gate routed KI123 out rather than repairing it here, because its repair widens what `check_schema` asserts where the other four repair what a reader reads; falsified by a decision that `check_schema` should hold the docs' description promise after all.
- 2026-08-31: criteria audit ran in REDUCED mode (internal tier, no RB-tripwire tag) over the five drafted criteria in a fresh-context [O] reader. One finding, fixed before writing: AC1 promised agreement with Pandoc's own parse on a rendered fixture, which crosses a process and environment boundary and binds a plant rather than the reader — restated as the reader's own behavior. Two cited ranges were corrected in passing (`parse_attrs` 89-132, `check_docs` 419-441).
- 2026-09-01: implementation gate chose `--` to separate `docs` mode's pages from its filenames (T4), a word table plus digits for the form-count sentence (T5), and the escaped quote read without its backslash, as pandoc 3.11 was observed to read it (T1).
- 2026-09-01: T1 — `parse_attrs` treats a backslash before the closing quote or before another backslash as an escape, the character after it joining the value; `ESCAPE` is a module constant so a self-test can splice it out.
- 2026-09-01: T2 — `escaped.json` plants `sort="The \"key=Hague\" city"`; the bodies check passes on it, and the same check under a copy of the reader with `ESCAPE` spliced out names `key=` as an undocumented attribute. The splice is `spliced_copy`, extracted from `m061_mutant` with the same per-substitution counts, which now calls it.
- 2026-09-01: T3 — `constructs` records each block's offset; `load` reads each `.index` construct's own term off the span it closes (`marked_term`, None for a div) and `attribute_sites` pairs by that. `divmark.json` plants a `.index` div ahead of a sort= mark and a bare mark; the probe reads sort= paired with `The Hague`, and with the ordinal pairing spliced back in, with `Den Haag`.
- 2026-09-01: T4 — `check_docs` splits its arguments at `--`; a page it cannot read fails through `read`'s own message naming the path. The four suite call sites moved to the new shape; plants added for an absent page and for a call with no `--`.
- 2026-09-01: T5 — `stated_forms` reads "There are exactly <count> supported forms" off the page (digits or one to twenty in words, exactly one such sentence) and `form_table` holds the row count to it; `SYNTAX_FORMS` is gone. Plants: the sentence edited to eleven, a row added, the sentence removed, a non-number word. The narrowing's docstring now states the ground a same-session read of the site supports: the empty-value demonstrations are backticked prose, which the sweep never reads as a construct. `int()` is guarded by `isascii()` per the M36 lesson.
- 2026-09-01: T6 — plain run over d7c555c: 578 checks, exit 0. The module docstring's `schema` paragraph still stated the empty-value ground T5 corrected; fixed after that run (docstring only), the self-test run below is over the corrected tree.
- 2026-09-01: T6 — self-test run over e7f9a55: 1085 checks, exit 0 (1071 on M066; the 14 added are the M067 plants and probes). Status → review.
- 2026-09-01: T1–T5 landed in one checkpoint rather than five: their suite evidence is one contiguous self-test block, and the block was run extracted on its own before the full suite (T6).

## Decisions

## Review

- 2026-09-01: reviewed over 67738c8 (branch even with `origin/main`, nothing to merge in); draft PR #67.
- AC1 — direct probe of `parse_attrs` from a scratch script over 67738c8: `entry="a \"b=c\" d" sort="k"` reads as two attributes, `entry` holding `a "b=c" d`; `entry="p \\"` reads as `p \`; the single-quoted form reads the same way. Verified.
- AC2 — direct probe: a `.index` div ahead of a `sort=` mark and a bare mark; `constructs` carries `term` None for the div, `The Hague` and `Den Haag` for the spans, and `attribute_sites` pairs `sort=` with `The Hague`. Verified.
- AC3 — `docs <absent.html> README.md -- _schema.yml _snippets.json` fails naming the absent path through `read`'s own message, exit 1; a call with no `--` fails saying so, exit 1. Verified.
- AC4 — `SYNTAX_FORMS` is absent from `tests/`, `site/` and `README.md`; `stated_forms` reads 10 off `site/syntax.qmd`'s sentence and `form_table` counts 10 rows. Verified.
