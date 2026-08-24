# M33: An index term outside Latin-1 prints in the PDF index

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP2, GP3
- **Branch/PR:** m033-non-latin1-terms

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

- [ ] AC1. `examples/unicode.qmd` — a fixture whose index marks carry terms in
      Greek, in Cyrillic, and in Latin beyond Latin-1, each mark indexing at one
      level — renders to PDF at Quarto exit 0 under the engine and the main font
      README's `### Terms outside Latin-1` names.
- [ ] AC2. For every term in the list `tests/run-tests.sh` states for
      `examples/unicode.qmd`, the text `tests/unicodeprint.py` extracts from
      that term's own entry line in the captured PDF's index, its locators
      removed, equals that term's own characters, each side compared in Unicode
      NFC; a listed term with no entry line fails it.
- [ ] AC3. Three controls fail in the named way: (a) the fixture under
      `pdf-engine: pdflatex` — Quarto exits non-zero and the LaTeX log names
      `not set up for use with LaTeX` for a Greek character the fixture marks;
      (b) the fixture under the recipe's engine with `mainfont` left at its
      default — Quarto exits 0, that render's printed index carries an entry
      line for an ASCII term the fixture also marks, and no entry line in it
      carries any of the fixture's Greek terms; (c) the fixture with one CJK
      term added, under the recipe's engine and font — Quarto exits 0, that
      render's printed index carries an entry line for that same ASCII term, and
      no entry line in it carries the added CJK term.
- [ ] AC4. README's new `### Terms outside Latin-1` section states each of five
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
- [ ] AC5. `cairn/DESIGN.md`'s IP2 carries the engine-and-font condition D-016
      records, and KI6 names Greek, Cyrillic and Latin beyond Latin-1 including
      combining marks as the set proven under the recipe and every other script
      as unproven, naming CJK and RTL, the RTL entry naming the bidi shaping and
      locator placement this milestone's plan gate recorded.
- [ ] AC6. `tests/run-tests.sh` exits 0 on this branch.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3, T4, T6
- AC3 → T4, T5, T6
- AC4 → T7
- AC5 → T8
- AC6 → T3, T4, T5, T6

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

## Decisions

## Review
