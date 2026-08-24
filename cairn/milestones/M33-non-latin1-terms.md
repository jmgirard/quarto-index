# M33: An index term outside Latin-1 prints in the PDF index

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2, GP3
- **Branch/PR:** —

## Goal

An author indexing terms outside Latin-1 gets them printed in the PDF index by
following one documented engine-and-font recipe, and the repo's stated promise
about non-ASCII terms says what is true.

## Scope

Surface tier: **user-facing** — the deliverable is an author-facing recipe in
README, an example, and the IP2 promise authors read.

**In:** a documented `pdf-engine` + `mainfont` recipe for index terms outside
Latin-1; a fixture and a typeset-print proof covering Greek and Latin beyond
Latin-1 (combining marks included) under a font TeX Live bundles; three controls pinning the failure
signature of each half of the recipe; IP2 amended to carry the recipe as its
condition (D-016); KI6 narrowed to the scripts left unproven.

**Out:**
- RTL scripts (bidi shaping, and the locator comma the plan-gate probe found on
  the wrong side of the entry) → candidate row.
- Cyrillic and CJK as *proven* scripts — both need a covering font the suite
  cannot assume on every machine → named in the narrowed KI6, promoted on a
  bundled font that covers them.
- Collation order beyond what makeindex gives: the DESIGN convention already
  declares it best-effort, and nothing here changes it.
- Any filter-side detection of the engine or the font. D-003 excludes "a
  missing font" by name, and the gate kept that reading.
- The HTML back-end, which already groups a non-ASCII term under Symbols by
  design.

## Acceptance criteria

- [ ] AC1. `examples/unicode.qmd` — a fixture whose index marks carry terms in
      Greek and in Latin beyond Latin-1 — renders to PDF at Quarto exit 0 under
      the engine and the main font README's `### Terms outside Latin-1` names.
- [ ] AC2. `tests/unicodeprint.py` extracts as many index terms from the marks
      in `examples/unicode.qmd` as that fixture carries `.index` marks, and for
      every one of them the text extracted from that term's own entry line in
      the captured PDF's index equals that term's own characters, each side
      compared in Unicode NFC; a term it extracts no entry line for fails it,
      and the recipe render's LaTeX log carries no `Missing character` line.
- [ ] AC3. Three controls fail in the named way: (a) the fixture under
      `pdf-engine: pdflatex` — Quarto exits non-zero and the LaTeX log names
      `not set up for use with LaTeX` for a Greek character the fixture marks;
      (b) the fixture under the recipe's engine with `mainfont` left at its
      default — Quarto exits 0 and the LaTeX log names `Missing character` for
      that same Greek character; (c) the fixture with one Cyrillic term added,
      under the recipe's engine and font — Quarto exits 0 and the LaTeX log
      names `Missing character` for a Cyrillic character.
- [ ] AC4. README's new `### Terms outside Latin-1` section states each of five
      things: the engine the recipe names; the main font it names, and that a
      main font must cover the script being indexed; the three failure
      signatures AC3 names; that `sort=` sets an entry's sort key while ordering
      beyond that is the index processor's and best-effort; and that Cyrillic,
      CJK and RTL are unsupported, RTL additionally unresolved for bidi shaping
      and locator placement.
- [ ] AC5. `cairn/DESIGN.md`'s IP2 carries the engine-and-font condition D-016
      records, and KI6 names exactly three scripts as unsupported by a proven
      recipe — Cyrillic, CJK and RTL — the RTL entry naming the bidi shaping and
      locator placement this milestone's plan gate recorded.
- [ ] AC6. `tests/run-tests.sh` exits 0 on this branch.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3, T4, T6
- AC3 → T5, T6
- AC4 → T7
- AC5 → T8
- AC6 → T3, T4, T5, T6

## Tasks

- [ ] T1. Pin the recipe's font: confirm a TeX Live-bundled font covering Greek
      and Latin-Extended (`texgyrepagella` at the plan gate) and the
      `mainfont` / `mainfontoptions` spelling Quarto needs to load it by file
      name — the plain family name is not findable (probe: fontspec "cannot be
      found").
- [ ] T2. Write `examples/unicode.qmd`: Greek, Polish and Vietnamese terms, one
      written with a combining mark rather than a precomposed character, one
      whose combining sequence has no precomposed form at all, and one carrying
      `sort=`, plus the `.index-here` marker. Give each term a level path no
      other fixture indexes (the M13 registry hazard).
- [ ] T3. Add the recipe render to `tests/run-tests.sh`, capturing the compiled
      PDF into `$WORK` at that render and reading the copy (M24).
- [ ] T4. Write `tests/unicodeprint.py`: extract the fixture's marked terms from
      source, extract each term's own entry line from the captured PDF, and hold
      each to its own characters — the entry's own cell, never a search of the
      index region (M30).
- [ ] T5. Add AC3's three controls as their own renders, each capturing its
      LaTeX log; the Cyrillic control renders a copy of the fixture with one
      Cyrillic term added.
- [ ] T6. Plant a defect per CLAUSE of `tests/unicodeprint.py` and of the three
      controls — not per reader (M32) — one substitution per plant (M29), and
      record the matrix. Include a wrong expected string and a term whose entry
      line is absent.
- [ ] T7. Write README's `### Terms outside Latin-1` after `### Special
      characters`, cross-referenced from it.
- [ ] T8. Amend IP2 in DESIGN.md, narrow KI6 to the three scripts, and append
      D-016. (The RTL candidate row lands with this plan's commit.)

## Work log

- 2026-08-24: created by /milestone-plan; absorbs the 2026-08-16 candidate row "Pick an engine and fonts for non-Latin-1 index terms" (M01 review R7/R9, KI6).
- 2026-08-24: plan gate probed the engine/font matrix under TinyTeX (TeX Live 2026): pdflatex exits 1 on a Greek entry at `\printindex` while makeindex accepts it; xelatex + Latin Modern exits 0 and drops every non-Latin-1 glyph; xelatex + `texgyrepagella` prints Greek, Polish and Vietnamese and drops Cyrillic; RTL prints unshaped with the locator comma misplaced.
- 2026-08-24: criteria audit ran in FULL mode (user-facing tier, ip-touching tripwire) over a fresh-context reader; round 1 returned 12 findings, round 2 over the post-gate wording returned 7. Eleven then seven were fixed at the gate; the AC3/IP2 reachability conflict became this round's IP2 question. The round-2 "no control that the check can fail" finding was disposed as an instrument property (D-118) and lives in T6, not in an AC.
- 2026-08-24: plan gate chose a documented recipe plus a typeset-print proof over filter-side engine detection, because D-003 excludes "a missing font" by name and detection would need a superseding entry; falsified by evidence that an author following the README recipe still gets a broken index.
- 2026-08-24: plan gate chose amending IP2 to carry the engine-and-font condition over reading GP2 as already scoping it, because IP2's words otherwise stay an unconditional promise the probes show is false; falsified by a reading of IP2 under which the pdflatex break is not "because of a marked term".
- 2026-08-24: plan gate chose Greek + Latin-Extended as the proven set over adding Cyrillic, because no TeX Live-bundled font found at the gate covers Cyrillic and assuming one makes the suite machine-dependent; falsified by a bundled font shown to cover both.

- 2026-08-24: remainder ledger caught "combining marks" from the absorbed candidate row absent from the plan; probing it found the PDF text layer renormalizes both ways (decomposed `cafe`+U+0301 extracts precomposed; precomposed Greek `\u03cc` extracts decomposed), which made AC2's byte-equality unsatisfiable for a term already in scope. AC2 now compares in NFC and the fixture carries the combining shapes.
- 2026-08-24: criteria audit re-ran in FULL mode over the changed AC2 and returned 4 findings; 3 were fixed here (a no-precomposed-form fixture term, the extracted-term count floored against the fixture's mark count, and a zero-`Missing character` clause) and the "no control that the check can fail" finding was disposed as an instrument property (D-118) already carried by T6.

## Decisions

## Review
