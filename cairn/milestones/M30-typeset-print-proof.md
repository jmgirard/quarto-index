<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M30: A character in an index entry is proved to print, not merely to compile

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Branch/PR:** `m030-typeset-print-proof` — https://github.com/jmgirard/quarto-index/pull/30

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

- [x] AC1: In the index region of the PDF Quarto renders from
      `examples/escaping.qmd`, each of the 94 printable ASCII characters
      U+0021–U+007E is found as its own index entry: the cell `pdftotext
      -layout` is expected to yield for that character — by default the
      character itself, then `, `, then a page number, and otherwise the cell
      the AC2 table states for it. A table row states a cell to find, never an
      exemption from finding one. The check enumerates that domain as the
      codepoint range itself and carries no per-character skip list.
- [x] AC2: Every character whose expected extracted form is not the character
      itself is carried in one named table beside the check, each row stating
      the typesetting fact it rests on rather than a value read back from the
      artifact under test.
- [x] AC3: `tests/run-tests.sh --self-test` completes clean.

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

Fresh evidence, 2026-08-24, on `m030-typeset-print-proof` at commit `5e9d191`,
PR #30. `origin/main` had not moved since the branch was cut (`133f4c8` on both
local and remote), so no merge was needed. The `verify` slot was run whole
(`tests/run-tests.sh --self-test`, exit 0, 431 checks); every figure below was
read back out of that run's own captured artifacts by command, not from its
pass lines.

- **AC1** — the run's `M30-AC1` check passes: "escaping probe compiles, all
  entries accepted, and each of the 94 printable ASCII characters prints as its
  own entry in the typeset index". Read back independently from the same
  captured PDF (`tests/.work/cap/esc-pdf/escaping.pdf`, `pdftotext -layout`):
  the index region splits into 96 cells, 94 of them one-character entries plus
  the two page-footer folios `2` and `3`. Every codepoint in `range(0x21,0x7F)`
  matches a cell — 91 as `<char>, 1`, and `'` as `’, 1`, `` ` `` as `‘, 1`, `,`
  as `„1`, the three cells `EXPECTED_CELL` states. The check enumerates the
  domain as `range(0x21, 0x7F)` and carries no skip list; `EXPECTED_CELL` holds
  three cells to find, no exemptions. A non-empty-cells guard fails the check
  before the sweep, so a reader that found nothing could not report nothing
  missing.
- **AC2** — the three characters whose expected cell is not the character
  itself are carried in one named table, `EXPECTED_CELL`, in the heredoc of
  `esc_typeset_check` in `tests/run-tests.sh`, immediately above the sweep that
  reads it. The comment block above it gives one row per character, each
  stating a typesetting fact and not a value read back from the PDF under test:
  `'` and `` ` `` because a T1 text font puts the right and left single
  quotation marks at those two ASCII positions, and `,` because makeindex
  writes the entry as `\item ,, \hyperpage{N}` and `,,` is the T1 ligature for
  the double low-9 quotation mark, merging the entry's own comma with the index
  style's delimiter into one glyph with no separator and no space before the
  page number. No other character has a row.
- **AC3** — `tests/run-tests.sh --self-test` exits 0 with "All checks passed
  (431 checks)", including the widened `M30-AC1` check — which now reports
  through the counted `pass` helper rather than printing its own line — and the
  M30 planted-defect entry.

Discrimination: the `--self-test` M30 entry renders a copy of
`examples/escaping.qmd` with the apostrophe's visible mark and its `entry=`
level removed — the plant asserts it removed exactly one of each — captures it,
and calls the same `esc_typeset_check`. It exits non-zero naming `U+0027`. Read
back independently from that planted capture
(`tests/.work/cap/m30-plant/escaping.pdf`), the sweep reports exactly one
missing character, `U+0027`. The run's own green call on the unplanted fixture
is the control.

Consistency gate: `cairn_validate` — all 16 checks PASS, 7 advisories OK. No
`DESIGN.md` principle definition changed (the diff touches only the Known
issues list), so `cairn_impact` is skipped. The `generic` profile names no
toolchain `consistency-gate` checks, so that half is a clean no-op. No Driving
RR, so the projection-vs-outcome record no-ops.

Returns: no defect returns and no amendment returns this milestone; the thrash
rule does not fire.

## Findings

Three lenses, run inline in this session rather than in fresh-context
subagents, per the standing instruction this session carries against spawning
subagents — logged as an override, as the plan and implement phases logged the
same one. The [S] prior-review lens found no regression against any recorded
finding on the touched files: `gh api` returns 0 inline PR review comments
across the repo, and the archived `## Review` sections on `tests/run-tests.sh`
carry two live constraints this diff honours — M24's "every check reads the
copy captured at its own render" (both call sites read `$CAPTURE_ROOT`, and the
run's own M24-AC1/AC3 checks pass over 27 sources and 88 render commands), and
M15's send-to-candidates note on the suite's two independent joined-`warn()`
readers, which this diff answers by giving the widened check one shared
function rather than a third copy. The [S] blame-history lens read the modified
region's history (`M01`, `M02`, `M24`): the widening replaces M01's 16-character
search, which is what KI86 recorded as a gap and what this milestone's Scope
names; nothing M02 or M24 added is undone. The [O] diff-bug lens returned three
ranked findings.

- **F1 (diff-bug, med)** — the planted-defect self-test proves the reader goes
  red and names `U+0027`, but does not pin that the redness is *scoped* to the
  planted character. A reader that reported all 94 characters missing would
  satisfy both assertions identically, which is the blindness the block's own
  comment says it guards against; the unplanted green control rules out an
  always-red reader, not an all-missing one. The reader already prints
  `<N> of 94` in its failure header, and the planted run's real N is 1
  (measured at this review off `tests/.work/cap/m30-plant/escaping.pdf`), so
  the proof is one added `grep -qF '1 of 94'` away.
- **F2 (diff-bug, low)** — `esc_typeset_check` returns non-zero for four
  distinct causes — `pdftotext` failing, no `Index` heading, a region holding no
  cells, and characters missing — and each prints its own message on stderr, but
  the call site's `fail` text names only the last: "a printable ASCII character
  the probe indexes does not print as its own entry". The suite's own rule is
  that an observed failure backs a claim only as the failure it is verified to
  be. The reader's specific line does reach the console above it, so this is a
  summary line overreaching, not a lost diagnosis.
- **F3 (diff-bug, low)** — `cairn/DESIGN.md`'s KI87 says a reader sees `„1`
  "where `, 1` is meant". The shape the check's own default would predict for
  this entry is `,, 1` — the entry's comma plus the index style's delimiter —
  so `, 1` is what a reader would want rather than what the pipeline otherwise
  emits, and the sentence reads as the latter.

Rejected, with reason:

- **PROBE_CHARS on the coverage probe** — the `PROBE_CHARS="$PROBE_CHARS"`
  prefix on the fixture-coverage probe above the widened check passes an
  environment variable its Python never reads (it imports `os` and `string`
  unused too). Pre-existing on `main`, on lines this diff does not modify: the
  out-of-scope taxonomy's pre-existing-issue and unmodified-line members.
- **KI87's position in the Known-issues list** — it was written into the slot
  KI86 vacated, so it sits between KI71 and KI72. The list is not kept in
  numeric order (KI86 sat there too), so this is a cosmetic nitpick.

Triage at the gate, 2026-08-24: the maintainer chose to fix all three on the
branch. F1 — the self-test now also requires the reader's own header to read
`M30-AC1: 1 of 94`, matched with that fixed prefix attached so the count cannot
match inside a larger one; the pass line says "naming U+0027 and no other
character". F2 — the call site's summary now names the check and points at the
reader's own message for which of its four causes fired. F3 — KI87 now reads
"where every other entry's shape would give `,, 1` and a reader would want
`, 1`". `tests/run-tests.sh --self-test` re-run after the three fixes: exit 0,
431 checks, both M30 checks green. `cairn_validate` re-run: clean.
