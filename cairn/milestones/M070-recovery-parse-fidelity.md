<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M070: A recovered chapter is read as the file it is, and everywhere its own render reads it

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M069
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Branch/PR:** m070-recovery-parse-fidelity

## Goal

The recovery parse is given only a chapter source Pandoc's markdown reader is
the right reader for, and reads a mark wherever that chapter's own render reads
one, so a recovered chapter's terms are neither silently refiled into the wrong
index nor silently left out of every index.

## Scope

Surface tier: **user-facing** — the deliverable is which of an author's terms
reach the book index and what the render tells them when some cannot.

**In:**

- An extension test in `recover_record` (`book.lua:783`) before
  `pandoc.read(text, "markdown")`: a chapter source whose extension is not one
  of the markdown ones Quarto books take is not parsed at all, and its chapter
  is reported rather than refiled. KI219 records what happens today — a
  one-cell `.ipynb` chapter's raw JSON is accepted, its span's `index`
  attribute arrives seven characters long with the JSON escaping inside it,
  `mark_index` matches no declared index of that name, and the term is filed
  into the book's first index with nothing said, because recovery resolves the
  name before `fold_undeclared` would draw the refiling report.
- The report for such a chapter: a wording naming the file and saying its
  source was not read, beside the wordings `book.lua:887-891` and M069 draw.
- `recovered_marks` (`book.lua:693`) and `recovered_markers` (`book.lua:762`)
  reach a mark a chapter writes in its YAML front matter, which the ordinary
  render already indexes: probed 2026-09-02 under pandoc 3.11, a filter table
  carrying a `Span` function visits a span in `abstract:` exactly as it visits
  one in the body, while the recovery walk is over `parsed.blocks` alone.
- Acceptance-suite fixtures for both edges, and `--self-test` plants over each
  axis they are free in.
- `site/books.qmd`, `CHANGELOG.md` and `cairn/DESIGN.md` with KI219 retired and
  KI11 corrected where recovery bears on it.

**Out:**

- Narrowing the ordinary render so that a front-matter mark is not indexed at
  all. The plan gate chose to make recovery match the render rather than the
  render match recovery; the alternative and its falsifier are in the work log.
- A chapter whose front matter carries a placement marker rather than a mark.
  KI11 records it as filter residue of its own class; nothing here changes it.
- Refiling a recovered mark whose index name the book does not declare, which
  is silent for a reason of its own (KI218). Stays the reads-repair candidate
  row.
- Minting a fragment for a recovered locator. Stays the recovery-follow-ups
  candidate row.

## Acceptance criteria

- [ ] AC1. A book chapter whose source file's extension is not one the recovery
      parse accepts, and whose record is neither opened-and-usable nor read for
      any other reason, has none of its terms in any index section of the
      rendered book, and its reading chapter draws a report naming that
      chapter's file and saying its source was not read — asserted
      message-whole, on both entry paths: a record that is unopenable and
      listed, and a record no render has written.
- [ ] AC2. The extensions the parse accepts are `.qmd`, `.md`, `.markdown` and
      `.Rmd`; a fixture carrying one recovered chapter per accepted extension
      has each of those chapters' terms in the book's index, held row by row in
      href form against a hand-derived manifest.
- [ ] AC3. A mark written in a chapter's YAML front matter reaches the book's
      index by the recovery route under the same printed entry and in the same
      declared index as it reaches it when that chapter's record is read, its
      locator a link to that chapter's page with no fragment; the record-route
      half is asserted on its own render of the same fixture as the control.
- [ ] AC4. `site/books.qmd` and `CHANGELOG.md` each state which chapter source
      files the recovery route reads and which it refuses, and that a recovered
      chapter's front-matter marks reach the index with its body's.
- [ ] AC5. `tests/run-tests.sh` exits 0 both plain and with `--self-test`.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T1, T4
- AC3 → T3, T5
- AC4 → T6
- AC5 → T4, T5, T6

## Tasks

- [ ] T1. The extension test in `recover_record` (`book.lua:783`), before the
      read: the accepted set as a named table, the comparison on the chapter
      path's own extension lowercased, and a refusal that returns the file
      rather than nil so the caller can name it. A chapter whose name carries
      no extension at all is refused with the rest.
- [ ] T2. The refusal wording beside `book.lua:887-891` and M069's, drawn once
      per reading chapter for the refused chapter; `tests/scans/warn-distinct.py`'s
      EXPECTED count moves with it.
- [ ] T3. `recovered_marks` and `recovered_markers` over the chapter's metadata
      as well as its blocks, with `drop_conditional` applied to neither — front
      matter carries no conditional element — and document order settled so a
      front-matter mark's declared sort key cannot beat a body mark's by an
      order the ordinary render does not use.
- [ ] T4. The AC1/AC2 fixture: a copy of `examples/book` gaining a one-cell
      `.ipynb` chapter that marks a term, and one chapter per accepted
      extension; the refusal asserted message-whole on both entry paths, and
      the accepted chapters' terms held against the href-form manifest.
- [ ] T5. The AC3 fixture and its control: a chapter marking a term in
      `abstract:` and nowhere else, rendered once with its record readable and
      once with it recovered, the two asserted to file the same entry in the
      same index and to differ only in the locator's fragment.
- [ ] T6. `--self-test` plants over each axis, each shown red against the check
      that fences it: the extension test removed; the test inverted; the
      accepted set narrowed by one member; the metadata walk removed; and the
      metadata walk applied to the ordinary render's own pass, which must
      change nothing. Then `site/books.qmd`, `CHANGELOG.md` and
      `cairn/DESIGN.md` with KI219 retired.

## Work log

- 2026-09-02: created by /milestone-plan.
- 2026-09-02: plan gate chose to make recovery reach a front-matter mark over narrowing the ordinary render so neither reaches one, because the render's behavior is what a single-document author already gets and changing it would drop terms from documents that are not books at all; falsified by an author reporting a term in their front matter reaching the index as a defect rather than as what they asked for.
- 2026-09-02: plan gate chose an extension whitelist over sniffing the file's content, because Quarto names the chapter files and the set it accepts is small and enumerable, where a content sniff would be a second reader guessing at a format Quarto already knows; falsified by a Quarto release taking a book chapter whose extension is outside the set and whose source Pandoc's markdown reader reads correctly.
- 2026-09-02: criteria audit ran in FULL mode ([O], fresh context) and returned findings on all three drafted criteria — AC1 unbounded over "not markdown" with no enumerable set and its antecedent covering only one of two entry paths, AC2 unsatisfiable as written because a recovered locator carries no fragment by decision and its record-route baseline was unpinned, AC3 wholly instrument-bound and its single plant standing in for a family. All fixed before this file was written.
- 2026-09-02: probe run 2026-09-02 under pandoc 3.11 — a filter table carrying a `Span` function visits a span in `abstract:` as well as one in the body, confirming the asymmetry AC3 rests on before this milestone was written rather than leaving it for implementation.

## Decisions

## Review
