# M33: An index term outside Latin-1 prints in the PDF index

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2, GP3
- **Branch/PR:** m033-non-latin1-terms · https://github.com/jmgirard/quarto-index/pull/33

## Goal

An author indexing terms outside Latin-1 gets them printed in the PDF index by
following one documented engine-and-font recipe, and the repo's stated promise
about non-ASCII terms says what is true.

## Scope

Surface tier: **user-facing** — the deliverable is an author-facing recipe in
README, an example, and the IP2 promise authors read.

**In:** a documented `pdf-engine` + `mainfont` recipe for index terms outside
Latin-1; a fixture and a typeset-print proof covering Greek, Cyrillic and Latin
beyond Latin-1 (combining marks included) under a font TeX Live bundles; three
controls pinning the failure signature of each half of the recipe and of a
script the recipe's font does not cover; IP2 amended to carry the recipe as its
condition (D-016); KI6 narrowed to name the proven set and the unproven
remainder.

**Out:**
- RTL scripts (bidi shaping, and the locator comma the plan-gate probe found on
  the wrong side of the entry) → candidate row.
- CJK as a *proven* script — it needs a covering font the suite cannot assume
  on every machine → named in the narrowed KI6, promoted on a bundled font that
  covers it.
- Collation order beyond what makeindex gives: the DESIGN convention already
  declares it best-effort, and nothing here changes it.
- Any filter-side detection of the engine or the font. D-003 excludes "a
  missing font" by name, and the gate kept that reading.
- The HTML back-end, which already groups a non-ASCII term under Symbols by
  design.

## Acceptance criteria

- [x] AC1. `examples/unicode.qmd` — a fixture whose index marks carry terms in
      Greek, in Cyrillic, and in Latin beyond Latin-1, each mark indexing at one
      level — renders to PDF at Quarto exit 0 under the engine and the main font
      README's `### Terms outside Latin-1` names.
- [x] AC2. For every term in the list `tests/run-tests.sh` states for
      `examples/unicode.qmd`, the text `tests/unicodeprint.py` extracts from
      that term's own entry line in the captured PDF's index, its locators
      removed, equals that term's own characters, each side compared in Unicode
      NFC; a listed term with no entry line fails it.
- [x] AC3. Three controls fail in the named way: (a) the fixture under
      `pdf-engine: pdflatex` — Quarto exits non-zero and the LaTeX log names
      `not set up for use with LaTeX` for a Greek character the fixture marks;
      (b) the fixture under the recipe's engine with `mainfont` left at its
      default — Quarto exits 0, that render's printed index carries an entry
      line for an ASCII term the fixture also marks, and no entry line in it
      carries any of the fixture's Greek terms; (c) the fixture with one CJK
      term added, under the recipe's engine and font — Quarto exits 0, that
      render's printed index carries an entry line for that same ASCII term, and
      no entry line in it carries the added CJK term.
- [x] AC4. README's new `### Terms outside Latin-1` section states each of five
      things: the engine the recipe names; the main font it names, and that a
      main font must cover the script being indexed; the two failure signatures
      — pdflatex ending the render with `not set up for use with LaTeX`, and a
      main font not covering the script leaving the term absent from the printed
      index at a render that otherwise succeeds — together with the fact that a
      `Missing character` line in the LaTeX log does not by itself mean a glyph
      was dropped, since xelatex prints many such characters from their
      decomposition; that `sort=` sets an entry's sort key while ordering beyond
      that is the index processor's and best-effort; and that the recipe is
      proven for Greek, Cyrillic and Latin beyond Latin-1 including combining
      marks, with any other script unproven — CJK and RTL named, RTL
      additionally unresolved for bidi shaping and locator placement.
- [x] AC5. `cairn/DESIGN.md`'s IP2 carries the engine-and-font condition D-016
      records, and KI6 names Greek, Cyrillic and Latin beyond Latin-1 including
      combining marks as the set proven under the recipe and every other script
      as unproven, naming CJK and RTL, the RTL entry naming the bidi shaping and
      locator placement this milestone's plan gate recorded.
- [x] AC6. `tests/run-tests.sh` exits 0 on this branch.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3, T4, T6
- AC3 → T4, T5, T6
- AC4 → T7, T9
- AC5 → T8
- AC6 → T3, T4, T5, T6, T9

## Tasks

- [x] T1. Pin the recipe's font: confirm a TeX Live-bundled font covering
      Greek, Cyrillic and Latin-Extended (`STIX` at the amendment gate) and the
      `mainfont` / `mainfontoptions` spelling Quarto needs to load it by file
      name — the plain family name is not findable (probe: fontspec "cannot be
      found").
- [x] T2. Write `examples/unicode.qmd`: Greek, Cyrillic, Polish and Vietnamese
      terms, one written with a combining mark rather than a precomposed
      character, one whose combining sequence has no precomposed form at all,
      one carrying `sort=`, and one ASCII term the controls read as their
      positive signal, plus the `.index-here` marker. Every mark indexes at one
      level, and each term takes a level path no other fixture indexes (the M13
      registry hazard).
- [x] T3. Add the recipe render to `tests/run-tests.sh`, capturing the compiled
      PDF into `$WORK` at that render and reading the copy (M24).
- [x] T4. Write `tests/unicodeprint.py`: read each listed term's own entry line
      from the captured PDF and hold it, its locators removed, to that term's
      own characters in NFC — the entry's own cell, never a search of the index
      region (M30). It also holds the term list `tests/run-tests.sh` states
      against the fixture's own marks, one term per mark, so the list cannot
      drift from what the fixture indexes.
- [x] T5. Add AC3's three controls as their own renders, each capturing its PDF
      and its LaTeX log; the third renders a copy of the fixture with one CJK
      term added. Controls (b) and (c) each read their own printed index for the
      ASCII term's entry line and for the absence of the foreign-script term's.
- [x] T6. Plant a defect per CLAUSE of `tests/unicodeprint.py` and of the three
      controls — not per reader (M32) — one substitution per plant (M29), and
      record the matrix. Include a wrong expected string, a term whose entry
      line is absent, and a stated term list drifted from the fixture's marks.
- [x] T7. Write README's `### Terms outside Latin-1` after `### Special
      characters`, cross-referenced from it.
- [x] T8. Amend IP2 in DESIGN.md, narrow KI6 to the proven set and the unproven
      remainder, and append D-016. (The RTL candidate row lands with this plan's commit.)
- [x] T9. Repair the six findings the review gate returned to implement:
      README's default-engine framing and its STIX-install claim, its
      fixture-list miscount and its suite-prerequisites sentence;
      `tests/unicodeprint.py`'s missing empty-term-list guard and its relative
      import; a fourth control render pinning the no-engine path README now
      documents, and a plant for the new guard's clause.

## Work log

- 2026-08-24: created by /milestone-plan; absorbs the 2026-08-16 candidate row "Pick an engine and fonts for non-Latin-1 index terms" (M01 review R7/R9, KI6).
- 2026-08-24: plan gate probed the engine/font matrix under TinyTeX (TeX Live 2026): pdflatex exits 1 on a Greek entry at `\printindex` while makeindex accepts it; xelatex + Latin Modern exits 0 and drops every non-Latin-1 glyph; xelatex + `texgyrepagella` prints Greek, Polish and Vietnamese and drops Cyrillic; RTL prints unshaped with the locator comma misplaced.
- 2026-08-24: criteria audit ran in FULL mode (user-facing tier, ip-touching tripwire) over a fresh-context reader; round 1 returned 12 findings, round 2 over the post-gate wording returned 7. Eleven then seven were fixed at the gate; the AC3/IP2 reachability conflict became this round's IP2 question. The round-2 "no control that the check can fail" finding was disposed as an instrument property (D-118) and lives in T6, not in an AC.
- 2026-08-24: plan gate chose a documented recipe plus a typeset-print proof over filter-side engine detection, because D-003 excludes "a missing font" by name and detection would need a superseding entry; falsified by evidence that an author following the README recipe still gets a broken index.
- 2026-08-24: plan gate chose amending IP2 to carry the engine-and-font condition over reading GP2 as already scoping it, because IP2's words otherwise stay an unconditional promise the probes show is false; falsified by a reading of IP2 under which the pdflatex break is not "because of a marked term".
- 2026-08-24: plan gate chose Greek + Latin-Extended as the proven set over adding Cyrillic, because no TeX Live-bundled font found at the gate covers Cyrillic and assuming one makes the suite machine-dependent; falsified by a bundled font shown to cover both.

- 2026-08-24: remainder ledger caught "combining marks" from the absorbed candidate row absent from the plan; probing it found the PDF text layer renormalizes both ways (decomposed `cafe`+U+0301 extracts precomposed; precomposed Greek `\u03cc` extracts decomposed), which made AC2's byte-equality unsatisfiable for a term already in scope. AC2 now compares in NFC and the fixture carries the combining shapes.
- 2026-08-24: criteria audit re-ran in FULL mode over the changed AC2 and returned 4 findings; 3 were fixed here (a no-precomposed-form fixture term, the extracted-term count floored against the fixture's mark count, and a zero-`Missing character` clause) and the "no control that the check can fail" finding was disposed as an instrument property (D-118) already carried by T6.
- 2026-08-24: implement gate probed the font matrix: `texgyrepagella` drops Cyrillic, but xelatex prints a precomposed character the font lacks from that character's decomposition, so a `Missing character` log line fires on correctly-printing Greek as well as on dropped Cyrillic; TinyTeX also bundles `STIX`, which printed and extracted Greek, Cyrillic, Polish, Vietnamese, a decomposed `café` and `Nux̌alk` correctly and drops CJK at Quarto exit 0.
- 2026-08-24: amendment at the implement gate, both halves user-selected: the recipe names `STIX` and the proven set gains Cyrillic (the plan gate's own falsifier, "a bundled font shown to cover both", fired), and AC2 loses its zero-`Missing character` clause. Scope In/Out, AC1-AC5, Coverage and T1/T2/T4/T5/T6/T8 amended.
- 2026-08-24: criteria audit ran twice in FULL mode over the amended wording, each over a fresh-context reader that did not author it; round 1 returned 7 findings, all disposed by narrowing (positively-stated proven set, one-level marks, a stated term list as AC2's domain, printed-index evidence replacing the log line in the controls); round 2 over the repaired wording returned 6 on the same criteria and went to the user under the once-more rule, who accepted the repair. AC5 and AC6 came back clean.
- 2026-08-24: T1 — `STIX` is the recipe font: the plain family name `STIX` fails the render with fontspec's "The font \"STIX\" cannot be found", so the recipe names it by file (`Extension=.otf`, `UprightFont=*-Regular` and the three siblings). T2 — `examples/unicode.qmd` marks eight one-level terms: Greek, Greek with `sort=`, Cyrillic, Polish, Vietnamese, a decomposed `café`, `Nux̌alk` (`x` + U+030C, no precomposed form) and an ASCII term the controls read as their positive signal.
- 2026-08-24: T3/T4 — the recipe render and `tests/unicodeprint.py` are in the suite; all eight terms print as their own entry line in the captured PDF, compared in NFC, and the stated term list is held against the fixture's own marks one per mark. Suite 339 checks, up from 336.
- 2026-08-24: T5 — the three controls are in the suite, each derived from the fixture by one YAML edit (the CJK control also adds one mark): pdflatex exits non-zero with `not set up for use with LaTeX` naming U+03B8; the default main font exits 0 with the Greek entry lines gone; the full recipe exits 0 with the added CJK entry line gone. Both silent-drop controls first prove their own index printed, by finding the fixture's ASCII entry line. Suite 346 checks.
- 2026-08-24: T6 — ten plants over the reader's ten reachable clauses, one substitution each, matrix recorded in the self-test's own comment beside them; each plant states the message fragment it expects, so a reader going red for another reason is not counted. The pdflatex control's log reading moved out of a shell heredoc into a fourth reader mode (`stopped`) so its two clauses could be planted. One clause is guarded and not planted: an index heading present with no entry lines is unreachable through this extension — probed, a document with no marks gets no heading at all. Self-test 482 checks.
- 2026-08-24: T7 — README's `### Terms outside Latin-1` lands after `### Special characters`, cross-referenced from it and from the Examples list; eleven claim rows are held verbatim and the copyable YAML block is held line for line against `examples/unicode.qmd` (the M32 recipe-block pattern). Suite 349 checks.
- 2026-08-24: T8 — IP2 amended in place and marked, the collation convention corrected to match, KI6 narrowed to the proven set and the unproven remainder, D-016 appended. Pre-review check `tests/run-tests.sh --self-test` clean at 485 checks.
- 2026-08-24: minor — the tool guard now fails loudly when `kpsewhich` cannot find `STIX-Regular.otf`, so a machine without TeX Live's `stix` package reports the missing package rather than four renders failing inside a LaTeX log.
- 2026-08-24: all tasks complete; status to review. `tests/run-tests.sh --self-test` clean at 485 checks (336 on the merge base).
- 2026-08-24: review returned M33 to in-progress (defect return #1): the README recipe states two things review probed false — that Quarto's default engine is pdflatex, when 1.10.18 defaults to lualatex and the fixture minus its `pdf-engine:` line exits 0 with only the Vietnamese term corrupted, and that STIX needs no installing, when it ships in collection-fontsextra. Six findings to fix, five to follow-up rows, three rejected; all fourteen and their dispositions are in the Review section.

- 2026-08-24: implement gate re-probed both returned defects before touching anything. Quarto 1.10.18 renders through LuaHBTeX, not pdflatex; the fixture with only its `pdf-engine:` line removed exits 0 with `Việt` printing as `Vi<?>t` and its other seven terms correct, and with both recipe lines removed it exits 0 with Greek and Cyrillic printing as empty boxes. `tlmgr info stix` reports `collection: collection-fontsextra`, which TinyTeX does not install by default.
- 2026-08-24: implement gate chose, user-selected, to document the no-engine path in README and pin it with a fourth control render, over stating less and adding no check, and over naming the control in an acceptance criterion. AC3 keeps the three controls it names and AC4 keeps its five things — no criterion changed. Minor amendment: T9 added for the return's six fixes, and mapped under AC4 and AC6 in Coverage; no criterion text changed.
- 2026-08-24: T9 — R9 and R7 fixed in `tests/unicodeprint.py` (import resolved from `__file__`; `entries` refuses an empty term list, a clause now planted, eleven plants over eleven reachable clauses). R1: README's "one of two failures" replaced by three, the third naming lualatex as Quarto's default engine and the silent half-set build, with control (d) rendering the fixture minus its `pdf-engine:` line and holding it to exit 0, the ASCII entry line present and the Vietnamese term not printing as itself; two claim rows added. R2, R10, R13: the STIX install fact, the suite-prerequisites sentence and the fixture-list count corrected, the install fact added as a claim row. D-017 appended, correcting D-016's default-engine context and leaving its decision standing. Suite `--self-test` clean at 487 checks.
- 2026-08-24: defect return #1 repaired; status back to review. `tests/run-tests.sh --self-test` clean at 487 checks (485 before the return, 336 on the merge base).

## Decisions

## Review

### Acceptance criteria — fresh evidence

Evidence from `tests/run-tests.sh --self-test` on b61091b (exit 0, 485 checks),
run at review 2026-08-24.

- AC1 — the suite's `M33-AC1/AC2` check renders `examples/unicode.qmd` under
  README's engine and main font at Quarto exit 0, capturing the PDF at that
  render; green.
- AC2 — the same check reads all 8 stated terms out of their own entry lines in
  the captured PDF and compares each, locators removed, to that term's own
  characters in NFC; a companion check holds the stated term list against the
  fixture's own marks (8 terms, one per mark), so a listed term with no entry
  line fails. Both green.
- AC3 — three control checks, each green: `M33-AC3a` (pdflatex render exits
  non-zero, its log stopping on U+03B8, a Greek character the fixture marks,
  with `not set up for use with LaTeX`); `M33-AC3b` (default `mainfont`, exit 0,
  the ASCII term's entry line present and neither of the 2 Greek terms
  printing); `M33-AC3c` (recipe engine and font with one CJK term added, exit 0,
  the ASCII entry line present and the CJK term absent). A fourth check holds
  each control to deriving from the fixture by one YAML edit.
- AC4 — read at review, README's `### Terms outside Latin-1` states all five:
  the engine (`xelatex`); the font (`STIX`, named by file) and the rule that a
  main font must cover the script; both failure signatures plus the
  `Missing character` caveat; what `sort=` does against best-effort ordering;
  and the proven set with CJK and RTL named unsupported, RTL additionally
  unshaped with the locator comma misplaced. Two suite checks hold this
  mechanically — 11 claim rows verbatim, and the copyable YAML block line for
  line against `examples/unicode.qmd`; both green.
- AC5 — read at review: `cairn/DESIGN.md` IP2 carries the engine-and-font
  condition and cites the README section (marked `amended M33; D-016`), and KI6
  names Greek, Cyrillic and Latin beyond Latin-1 including combining marks as
  the proven set, every other script unproven, CJK unsupported, and RTL both
  unsupported and unresolved for shaping and locator placement.
- AC6 — `tests/run-tests.sh --self-test` exits 0 on b61091b at 485 checks.

### Consistency gate

- `cairn_validate.py` — exit 0, all checks passed, no advisory fired.
- `cairn_impact.py --changed` reported no changed principles: IP2's amendment
  sits on lines that do not themselves spell the id, so the mechanical
  detection misses it. Reconciled by hand via `cairn_impact.py IP2` (24
  references): `DESIGN.md:66` was corrected in T8; `DESIGN.md:318/392/532` and
  KI11 cite IP2's never-break-the-document half, which the amendment leaves
  untouched; DECISIONS.md hits are D-016 itself; archive and work-log hits are
  history (IP4).
- Profile `generic` — its `consistency-gate` slot names no toolchain checks, so
  that half is a clean no-op. The suite ran anyway as AC6's evidence.

### Independent review — findings

Three fresh-context lenses (user-facing tier, executable surface). The
blame-history lens and the prior-review lens each reported no findings; the
prior-review probe found no inline review comments anywhere in the repo, so its
evidence was the archived `## Review` sections and LESSONS, against which the
diff was found compliant (M30's oracle rule, M16's empty-region rule, M32's
recipe-block and per-clause-plant patterns, M29's one-substitution rule, M24's
capture rule, M13's registry hazard). The diff-bug lens returned 14, ranked
below with the review's recommended disposition; the maintainer triages at the
gate.

- R1. README:268-269 ("the default engine and font cannot" draw the characters)
  and D-016 ("under Quarto's default `pdflatex`") state a false fact: Quarto
  1.10.18 defaults to **lualatex**, not pdflatex. Re-probed at review — a bare
  document renders under `lualatex`, and the fixture with only its
  `pdf-engine:` line removed exits 0 and prints an index in which Greek,
  Cyrillic, Polish, the combining-mark terms and the ASCII term are all
  correct while the Vietnamese term prints corrupted (`Vi<?>t`). So omitting
  the engine half gives a *third*, silent, partial failure — not the loud
  pdflatex stop README documents. The pdflatex control pins a signature only an
  author who opts *into* pdflatex can reach. **Recommended: fix now** — the
  silent-corruption path is the IP2 class, and README currently tells an author
  the opposite of what happens.
- R2. README:284-285 ("STIX ships with TeX Live and TinyTeX, so there is
  nothing to install") is contradicted by the guard this same diff adds at
  `tests/run-tests.sh` (which tells the operator to run `tlmgr install stix`).
  Confirmed at review: `tlmgr info stix` reports `collection:
  collection-fontsextra`, which is not in TinyTeX's default install. The claim
  is also not one of the 11 rows `README_UNICODE_CLAIMS` holds.
  **Recommended: fix now** — it is the one sentence telling a reader the recipe
  needs no setup.
- R3. `tlmgr info stix`: "As of April 2018 this package is considered
  obsolete. See `stix2-otf` and `stix2-type1` instead." GP3 asks LaTeX-side
  needs to stay within mainstream-bundled packages; an obsolete fontsextra-only
  package meets that weakly, and README, KI6 and D-016 all now name it as the
  recipe font. **Recommended: follow-up** — re-probing `stix2-otf` is its own
  render matrix.
- R4. `tests/unicodeprint.py` `cmd_entries` compares `nfc(term)` against every
  entry's term at every level and never reads `Entry.level`, so a term printed
  as a sub-entry would pass, though AC1 and the fixture both require one-level
  marks. **Recommended: follow-up.**
- R5. The AC3(a) control flips only the engine, and the fixture's Greek appears
  in body prose as well as in marks, so the control shows "pdflatex refuses
  Greek", not "a marked term breaks the document". **Recommended: reject** —
  the milestone's plan gate recorded this reachability conflict and disposed of
  it; the control is the change the plan called for.
- R6. `cmd_stopped` searches the log for the stop signature and for a named
  character independently, so a log whose fatal error named some other
  character while a Greek character appeared elsewhere would pass; AC3(a) asks
  for the stronger relation. **Recommended: follow-up.**
- R7. `cmd_entries` accepts an empty term list and passes vacuously; `stopped`
  and `absent` both guard against it. Mitigated in the suite by the paired
  `marks` check, which pins the list against the fixture's marks.
  **Recommended: fix now** — a two-line guard.
- R8. The copyable-block check is one-directional (README's block ⊆ fixture),
  so it cannot catch a README block that drops `pdf-engine:` or a
  `mainfontoptions` line, and it does not notice that the fixture carries
  `from: markdown-smart` while README's block does not.
  **Recommended: follow-up.**
- R9. `tests/unicodeprint.py` uses a relative `sys.path.insert(0, 'tests')`
  where every other helper resolves from `__file__`. **Recommended: fix now** —
  one line, and it matches convention.
- R10. README's suite-prerequisites sentence still names only TinyTeX,
  `makeindex` and `pdftotext`; this diff adds `kpsewhich` and the `stix`
  package as hard requirements. **Recommended: fix now.**
- R11. README's general "Any other script is unproven" disclaimer is not among
  the claim rows held verbatim. **Recommended: reject** — a general disclaimer
  is not the kind of claim a verbatim row can fence without pinning wording.
- R12. The `stopped` "no rejection" plant feeds a Quarto stdout log to a reader
  that in production reads a LaTeX log; it goes red for the right reason but
  not against the artifact family it guards. **Recommended: follow-up.**
- R13. README's fixture-list entry says the fixture "marks eight terms" and
  then lists six categories, omitting the second Greek term carrying `sort=`
  and the ASCII term the controls depend on. **Recommended: fix now.**
- R14. Task T2 names `.index-here`; the class the fixture correctly uses is
  `.qi-index-here`. Task text only, no code effect. **Recommended: reject** —
  the work log is history and the task is done.

### Gate disposition (2026-08-24)

The maintainer judged R1 and R2 load-bearing defects in the README recipe, the
milestone's user-facing deliverable, and returned M33 to `in-progress` rather
than repairing them at the gate: R1's repair is new documentation of the
default-engine failure plus, on the review's reading, a fourth control, which
is implementation work. Defect return #1 for this milestone.

Dispositions carried into that return: **fix** — R1, R2, R7, R9, R10, R13;
**follow-up** — R3, R4, R6, R8, R12 (candidate rows, search-first, at the
milestone that closes); **reject** — R5 (the plan gate recorded and disposed
of this reachability conflict; the control is the change the plan called for),
R11 (a general disclaimer is not fenceable by a verbatim claim row), R14 (task
text, no code effect, and the work log is history). Every criterion's evidence
above stands and was gathered on b61091b; the ticks are unchanged by this
return, and re-review re-gathers them on the repaired branch.
