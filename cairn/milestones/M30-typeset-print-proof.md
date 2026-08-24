<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M30: A character in an index entry is proved to print, not merely to compile

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m030-typeset-print-proof`

## Goal

Every printable ASCII character `examples/escaping.qmd` indexes is proved to
reach the compiled PDF's index as its own entry, not merely to compile and be
accepted by makeindex.

## Scope

Surface tier: **user-facing** — the promise is about what a reader sees in a
compiled index.

**In:** the escaping probe's typeset assertion in `tests/run-tests.sh`
(the PDF block at ~4113–4147) currently searches the index region for the 16
escape-domain characters `PROBE_CHARS` names. The fixture indexes all 94
printable ASCII characters and the suite proves all 94 compile and are accepted
by makeindex; nothing says the other 78 print. This widens the assertion to the
whole domain and asserts each character's own entry shape rather than its bare
presence anywhere in the region, since presence passes trivially for
punctuation the index prints regardless. The gap is recorded as KI86. Any
character whose printed form the PDF text layer cannot return as itself is
named in `cairn/DESIGN.md` with what extraction yields instead.

**Out:**
- Adding any character to `LATEX_LITERAL` → nothing; D-015 settles the one
  standing request, for `[` and `]`.
- The same widening for the cross-reference probe (`examples/xref-escaping.qmd`,
  M02-AC3) and the sort-key probe (`examples/sort-escaping.qmd`, M06-AC3) →
  ROADMAP candidate row.
- Non-Latin-1 terms → the existing engine-and-font candidate row (KI6).

## Acceptance criteria

- [ ] AC1: In the index region of the PDF Quarto renders from
      `examples/escaping.qmd`, each of the 94 printable ASCII characters
      U+0021–U+007E is found as its own index entry: the cell `pdftotext
      -layout` is expected to yield for that character — by default the
      character itself, then `, `, then a page number, and otherwise the cell
      the AC2 table states for it. A table row states a cell to find, never an
      exemption from finding one. The check enumerates that domain as the
      codepoint range itself and carries no per-character skip list.
- [ ] AC2: Every character whose expected extracted form is not the character
      itself is carried in one named table beside the check, each row stating
      the typesetting fact it rests on rather than a value read back from the
      artifact under test.
- [ ] AC3: `tests/run-tests.sh --self-test` completes clean.

## Coverage

- AC1 → T2, T3
- AC2 → T1, T2
- AC3 → T5

## Tasks

- [x] T1: Re-derive the extraction against the shipping pipeline: render
      `examples/escaping.qmd` to PDF through Quarto, capture, extract with
      `pdftotext -layout`, and record what the text layer yields for each of the
      94 characters. A hand-built `article` + `[T1]{fontenc}` + hyperref +
      imakeidx probe on 2026-08-24 returned 93 of 94 as themselves, with `'`
      returned as U+2019; the shipping preamble is not that preamble, so this is
      measured, not inherited.
- [x] T2: Write the expected-extraction table into `tests/run-tests.sh` beside
      the widened check — one row per character whose extracted form differs,
      each naming the typesetting fact behind it (T1 encoding's quote shapes,
      and whatever else T1 finds).
- [x] T3: Widen the assertion to `range(0x21, 0x7F)`, asserting the
      `<expected>, <page>` entry shape and reporting every character that fails
      by name. Read the captured PDF, never the working tree.
- [x] T4: Prove the widened check able to fail: on a copy of the fixture, remove
      one character's index mark with a single substitution, require the check
      red and naming that character, and require the unplanted run green.
- [x] T5: Run `tests/run-tests.sh --self-test`; strike KI86; file a
      Known-issues entry for any character the text layer cannot distinguish,
      and a candidate row for the two probes left un-widened.

## Work log

- 2026-08-24: created by /milestone-plan.
- 2026-08-24: plan chose asserting the `<char>, <page>` entry shape over searching the index region for the bare character because bare presence passes trivially for punctuation the index prints anyway; falsified by a page-number format that makes the shape unmatchable.
- 2026-08-24: plan chose a stated-fact expected-extraction table over deriving expected forms from the render under test because an oracle derived from its own artifact is blind where it derives (M20); falsified by extraction proving to vary with engine or font version, which would make hand-stated rows stale.
- 2026-08-24: plan chose three milestones (M30, M31, M32) over one clustered milestone because the goal sentence needed "and" and the three ship independently; falsified by the three proving to share a fixture or a check.
- 2026-08-24: criteria audit ran in **full** mode (user-facing tier), inline rather than in a fresh-context [O] reader — this session is under a standing instruction not to spawn subagents. It returned three findings, all fixed before the criteria were written: a draft criterion promising every character "appears in the index region" was unsatisfiable as a bare-presence test and became the entry-shape assertion; a draft criterion binding the D-entry and the Known-issues strike bound records rather than the deliverable and moved out of the milestone entirely (landed in the plan commit); a draft criterion requiring the widened check to go red on a planted defect bound the checker, not the deliverable (M25), and moved to T4.

- 2026-08-24: implement gate chose the expected-extraction table as a named dict inside the check's heredoc, and the planted-defect proof as a permanent `--self-test` entry.
- 2026-08-24: T1 measured the shipping pipeline (Quarto PDF render of `examples/escaping.qmd`, `pdftotext -layout`): 91 of 94 characters extract as themselves in an `X, <page>` cell; `'` yields `’`, `` ` `` yields `‘`, and `,` yields `„<page>` because the `.ind` line is `\item ,, \hyperpage{1}` and `,,` is the T1 ligature for the double-low-9 quote.
- 2026-08-24: amendment (substantive, user-selected at a mini gate): AC1 now asks for the cell `pdftotext -layout` is expected to yield — the character, `, `, a page number by default, otherwise the cell the AC2 table states — because the comma's entry has no `, ` separator to match. No criterion added; the criteria set is not widened. Inline criteria audit (full mode, user-facing tier, no subagent per this session's standing instruction) returned two findings on the draft, both fixed before writing: an unnamed extraction instrument, and a table clause readable as a skip list.

- 2026-08-24: T2, T3 and T4 landed in one checkpoint — they are one edit to `tests/run-tests.sh` plus its self-test half. T2/T3: the typeset assertion is now `esc_typeset_check`, a single reader carrying the named `EXPECTED_CELL` table (three rows: `'`, `` ` ``, `,`) and sweeping `range(0x21, 0x7F)` against the cells `pdftotext -layout` yields from the captured PDF, naming every character it cannot find. T4: the same reader is called again in `--self-test` against a copy of the fixture with the apostrophe's two marks removed; it exits 1 reporting `U+0027 "'": no printed index entry matching '’, {page}'`, and passes on the same fixture unplanted.

- 2026-08-24: T5: `tests/run-tests.sh --self-test` exits 0 with 431 checks, including the widened `M30-AC1` check and the M30 self-test entry. KI86 struck as closed; KI87 filed for the comma entry printing as one double-low-9 quote and for the apostrophe and grave printing as curly quotes; the suite-hardening candidate row absorbed the two probes left un-widened, and one row added for making a comma entry print as a comma.

## Decisions

## Review
