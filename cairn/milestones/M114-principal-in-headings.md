<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M114: A principal mention in a LaTeX heading or caption builds

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** IP2, GP6   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — it changes the PDF that a document with a principal mention in a heading or caption gets   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m114-principal-in-headings   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

A PDF built through LaTeX no longer fails to render because a heading or a
figure or table caption carries a principal mention, and its index emphasizes
that mention's page alone.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Probes on 2026-10-19 (Quarto 1.10.18, lualatex) found that any
`mention="principal"` mark in a heading or a figure or table caption stops
the PDF build, with or without a contents list: `! Illegal parameter number in
definition of \^^@.` for a heading, `! Argument of \caption@ydblarg has an
extra }.` for a figure caption, `! Argument of \caption@listentry@ has an
extra }.` for a table caption. The cause is the three commands a principal mark or
a principal range's ends emit (`\quartoindexregister`,
`\quartoindexrangefrom`, `\quartoindexrangeend`, defined at
`_extensions/index/modules/core.lua:213`, `:297`, `:300`). They are fragile,
and LaTeX expands them when it copies a heading or caption elsewhere. LaTeX
removes `\index` from those copies itself, so ordinary marks build (probed
under scrartcl, scrbook, book and article). This milestone makes the three
commands safe in LaTeX's copies of a heading or caption: a copy neither breaks
the build nor registers its own page as a principal page. It adds a fixture
and suite checks, a changelog entry and a docs sentence, and strikes KI2.

**Out:**
- Typst: a mark in a figure caption files the page of the caption's copy in a
  list of figures (KI290). It gets the candidate row this plan adds.
- Typst and HTML: a principal mention in a heading already prints right there
  (probed 2026-10-19). This milestone adds no check and no docs claim for them.
- A Quarto PDF book: its chapters are one LaTeX document with the same
  commands, so no book fixture is added.
- The CI version matrix's fixture list stays as it is. A whole-suite run on the
  floor Quarto stays with the `Floor-Quarto CI suite job` candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [x] AC1: `quarto render examples/principal-headings.qmd --to pdf` exits 0
      in the suite. The fixture uses Quarto's default document class with
      `toc: true`, `lof: true`, `lot: true` and `pagestyle: headings`. It
      carries a principal mention in a heading at each of levels 1, 2 and 4;
      a principal range opened in one heading and closed in a later one; a
      principal mention in a figure caption; a principal range opened in a
      figure caption and closed in body text on a later page; a principal
      mention in a table caption; and one ordinary mark in a heading.
- [x] AC2: In the fixture's printed index, each principal mention's page and
      each principal range's span is emphasized, and no other locator of the
      fixture's terms is. The suite checks this by reading the index with
      `tests/pdfindex.py` through the fixture's `\quartoindexprincipal`
      redefinition and matching every entry's term, level, locators and the
      emphasis on each locator against a manifest derived by hand from the
      fixture source.
- [x] AC3: `tests/run-tests.sh --self-test` exits 0.
- [x] AC4: `CHANGELOG.md`'s Unreleased Output section says that a principal
      mention in a heading, a figure caption or a table caption no longer
      stops a PDF build through LaTeX, and `site/principal-mention.qmd` says
      that a principal mention can sit there in a PDF built through LaTeX.
      Both say the case was tested under Quarto's default document class with
      a contents list, lists of figures and tables, and running heads.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1, T2
- AC2 → T1, T2, T3
- AC3 → T4
- AC4 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: Write `examples/principal-headings.qmd` (AC1's marks) and its
      hand-derived manifest, with a derivation comment that names the page of
      each mark. Give each term an ordinary mark on a page that prints a copy
      of its heading or caption, one for each kind of copy (contents line,
      list line, running head) where the layout allows, off its principal
      page and range, so a copy that registered its page would show as an
      emphasized locator. Add the
      render, its capture and the AC2 index check to `tests/run-tests.sh`.
      Show at the base commit that a heading-only, a figure-caption-only and a
      table-caption-only variant each fail with the error the Scope quotes for
      it, and commit the red check.
- [x] T2: Change the three command definitions in `core.lua` so LaTeX's copies
      of a heading or caption neither expand nor run them, keeping each one
      beside its `\index` so both still ship on one page (D-007). Probe each
      copy site alone (contents line, list-of-figures and list-of-tables
      lines, running head, PDF bookmarks, the caption package's processing)
      and the scrbook class by hand, and log the results. Update the
      subsystem comment in `core.lua`. AC1 and AC2 green.
- [x] T3: Show AC2's check able to fail with one plant per copy site and per
      command that reaches it in the fixture, a range end's copy corrupting a
      span among them. Each plant registers a copy's page and turns the check
      red, naming the entry. The self-test's planted-defect cases cover the
      new manifest.
- [x] T4: Write the changelog entry and the `site/principal-mention.qmd`
      sentence. Strike KI2 in `cairn/DESIGN.md` and correct any Architecture
      text about the three commands. Run `tests/run-tests.sh --self-test`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete.
     A milestone of a feature series also carries the plan's
     `feature series: M<a> -> M<b>[ -> …]` line (tracking-rules "Feature series"). -->

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to work on — marks in LaTeX headings (KI2); take the Typst caption case (KI290) too — no, one only, KI290 gets a candidate row; simplify or harden the PDF check follow-ups — answered "Simplify", which does not apply to this work.
- 2026-10-19: collision sweep: no open issue or outside PR (inbox empty); no candidate row names KI2; D-007 and D-008 stand and bind T2 (the role stays on the `.aux` channel beside its `\index`); M101 shipped caption marks and never probed a principal one in LaTeX.
- 2026-10-19: probes (Quarto 1.10.18, scratchpad): plain, range, sub-entry, see and named-index marks in a heading build and file the heading's page under scrartcl, scrbook, book and article with a contents list and running heads; a principal mark in a heading, figure caption or table caption fails the build; Typst and HTML print a principal mention in a heading right.
- 2026-10-19: scope widened from headings to headings and figure and table captions, because the same three commands fail there and T2's fix is one change; nothing the user asked for is dropped.
- 2026-10-19: plan gate chose to make the three LaTeX commands safe in LaTeX's copies over moving them out of the heading or caption in the filter, as `latex.move_alt_commands` does for alt text, because a write between a heading and its paragraph can allow a page break after the heading and splits the registration from its `\index` (D-007's same-page agreement); falsified by a copy site where the changed commands still break the build or register the copy's page.
- 2026-10-19: RB tripwire not tagged: the work restores IP2 and changes no principle.
- 2026-10-19: criteria audit (full mode, fresh Opus reader) returned 9 findings. Fixed: 1 (`pagestyle: headings`; the caption range's close placed), 2 (PDF bookmarks probed; one failing variant per error), 3 and 5 (AC2 states the index property, then what the check compares), 4 (AC2 states the copy-page locators, each on a page apart from the mention's), 7 (T3 plants per copy site and per command), 8 (AC4 names the tested configuration), 9 (table captions probed, fail the same way, added to scope). Answered: 6 (AC3 is the profile's verify gate the template requires; T3's plants are review evidence for AC2, and AC3 now maps to T4 alone).
- 2026-10-19: implement started; branch m114-principal-in-headings cut from main at 55edcd9; tree clean.
- 2026-10-19: T1 red at base (Quarto 1.10.18, lualatex, base extension): a heading-only variant fails with `Illegal parameter number in definition of \^^@`, a figure-caption-only one with `Argument of \caption@ydblarg has an extra }`, a table-caption-only one with `Argument of \caption@listentry@ has an extra }`; the fixture itself, under `pagestyle: headings`, fails first at the running head with `Illegal parameter number in definition of \g__mark_tmp_tl` (a fourth copy site the Scope did not name).
- 2026-10-19: T1 added `examples/principal-headings.qmd`, `tests/principal-headings-pdf.tsv`, the M114-AC1/AC2 section of `tests/run-tests.sh`, and `pdfindex.read`'s `from_page` (default 1, unchanged behavior), because page 1's contents line `Index` is a line exactly equal to the heading and the read would start there.
- 2026-10-19: T2 design: each command became `\qi@guard`, which runs a `\protected` worker when `\protect` is `\@typeset@protect` and, in a copy, keeps the command unexpanded only while `\index` means what it meant at `\begin{document}`; two tries failed first in scratch: a guard testing `\index` against `\@gobble`/`\relax` built but let every contents-list copy register page 1 (the TeX Live 2026 contents line removes `\index` with `\@gobble@som`, and an earlier `\protected@edef` with `\index` live had already expanded the command).
- 2026-10-19: T2 probes, each copy site alone (scratchpad, Quarto 1.10.18): a heading with no list, with `toc: true`, and with `pagestyle: headings`; a figure caption with and without `lof: true`; a table caption with and without `lot: true`; and scrbook with a contents list and running heads all build, print the principal page emphasized, and print the copy pages plain; no `Token not allowed in a PDF string` warning, so the PDF bookmarks take the heading's plain text; the fixture also matches the manifest under pdflatex and xelatex.
- 2026-10-19: T3 found AC2's copy clause unsatisfiable as written: a running head also prints on its own heading's page, and a mark on every running-head page folds consecutive pages into one range; the fixture moved dahlia's closing heading to page 7 so page 6 prints the opening heading's running head inside the range (a page a span-corrupting plant can reach); manifest and derivation comment updated, 13 page breaks, index on page 14; render matches.
- 2026-10-19: re-audit: AC2 (full) — 4 findings: "the mention's own page" reads two ways for holly, which has no principal mark; the three copy kinds read as examples; "a principal range" could be any term's; T3 should plant a span corruption at page 6.
- 2026-10-19: re-audit: AC2 (full) — 4 findings on the fixed wording: read per heading, dahlia's opening heading can never be met; "each of three kinds" reads as all three required; "The suite checks this" overclaims, since the manifest match does not check that the copy pages print their copies; T3 should show plants at pages 6 and 8 red. Second re-audit on AC2: stopped for the user (repeated review-failure stop).
- 2026-10-19: substantive amendment: AC2 narrowed at the user's choice at the stop to its index promise and its check ("each principal mention's page and each principal range's span is emphasized, and no other locator of the fixture's terms is"); the copy-page clause moved to T1 as test design (minor task edit). The kept-copy-clause option with a new copy-page check was declined. No further reader for AC2: two re-audit lines are on record.
- 2026-10-19: T3 plants tried in scratch before the suite: taking the guard off the registration is red on aster (`[P:1]`, `[P:4]`) and off a range opening red on dahlia (`[P:1]`, span plain); off a range closing stays green, because a closing mark's copies print only where its range's slot is empty (before the opening, after the closing); raw-LaTeX registrations on a contents line, list-of-figures line, list-of-tables line, running-head page and a running-head page inside the range are each red naming the term. All eight are in the suite's `--self-test` block, plus three manifest plants (a row removed, altered, added).
- 2026-10-19: T4 wrote the changelog entry and the `site/principal-mention.qmd` paragraph, deleted KI2 from `cairn/DESIGN.md` (closed entries are deleted, as M113 did) and added an Architecture sentence on the guard. The simple-english lint hook counts 207 hits in older CHANGELOG.md text; only the new entry was rewritten to its rules.
- 2026-10-19: claim audit: 105 claims read, 6 corrected — core.lua (running heads set `\index` to `\relax`, not removed), CHANGELOG.md and site/principal-mention.qmd (narrowed to contents-list, list and running-head copies; a `\nameref` copy registers, now KI317), examples/principal-headings.qmd (contents list leaves clover out; `\paragraph` is set on its own line, not run in), tests/run-tests.sh (clover derivation line; AC1 pass message; plant expectations now grep the first-difference line, not the whole got/want dump).
- 2026-10-19: first full suite run stopped at about 524 checks with no failure, so the corrections could be run once; the corrections were made with Edit and one literal-replacement script over tests/run-tests.sh.
- 2026-10-19: second full run red at M20-AC3/AC4 (`tests/m20probes.py`'s registration regex read the new zero-argument definition `\providecommand*\quartoindexregister{\qi@guard…}` as a registration, after 614 checks); the three commands keep their `[1]` argument form and pass it to the guard, the shape the M20/M21/M31 definition checks read, and the T3 splice follows it; no probe changed.
- 2026-10-19: third full run red at M41-AC1 after 962 checks: every fixture must be declared in `site/gallery.yml`; `examples/principal-headings.qmd` added under `not-shown:`, since a shown fixture needs an HTML index manifest and this one has a PDF one.
- 2026-10-19: fourth full run `tests/run-tests.sh --self-test` green at 5d30241: 1789 checks, the M114 section 53s, all eleven M114 plants red or green as stated (Python 3.9 at /usr/bin/python3 for PyYAML). T3 and T4 ticked; status review.
- 2026-10-19: review: four-lens pass, 23 findings (9 fixed in 4dabfa0, 3 to candidate rows, 11 rejected); final `--self-test` run green at 4dabfa0, 1788 checks.
- 2026-10-19: step-7 approval: m114-principal-in-headings approved for merge

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->

- 2026-10-19 sync: branch level with origin/main (0 behind); no PR yet; Copilot round off (no `# Copilot review:` line in PROFILE.md).
- AC1 evidence (2026-10-19, ae78813 tree, scratch copy of extension + fixture): `quarto render principal-headings.qmd --to pdf` exit 0, 0 WARN lines; the fixture sets `toc`, `lof`, `lot: true`, `pagestyle: headings`, no `documentclass` (Quarto's default), and carries principal mentions in headings at levels 1/2/4 (aster, basil, clover), a principal range across two level-one headings (dahlia), principal mentions in a figure caption (elm) and a table caption (ginkgo), a principal range opened in a figure caption and closed in body text (fern), and an ordinary heading mark (holly); 13 page breaks. The suite's own M114-AC1 line was green in the 5d30241 run.
- AC2 evidence (2026-10-19, same render): `m114_pdf_check` (pdfindex.read from page 2, level + NFC text per line) exit 0, the 8 lines of tests/principal-headings-pdf.tsv: aster 1, [P:2], 4; basil 1, [P:2]; clover 1, [P:3]; dahlia 1, [P:5–7], 9; elm 1, [P:10]; fern 1, [P:11–12]; ginkgo 1, [P:13]; holly 1, 10 — each principal page or span emphasized, every other locator plain. Discrimination: the 5d30241 `--self-test` run showed the check red on all ten plants meant to be red (two command leaks, five copy-site plants, three manifest plants), each on its first-difference line, and green on the range-closing leak.
- AC3 evidence (2026-10-19, 4dabfa0, after every fix-now commit): `tests/run-tests.sh --self-test` exit 0, "All checks passed (1788 checks)", 15 M114 `ok` lines, each of the eleven M114 plants red on its first-difference line (leak-rangeend now among them); python3 with PyYAML put first on PATH per the verify slot.
- AC4 evidence (2026-10-19, 4dabfa0): CHANGELOG.md's `## Unreleased` → `### Output` entry says a principal mention in a heading, a figure caption or a table caption "no longer stops a PDF build through LaTeX" and that the suite tests this "under Quarto's default document class with a table of contents, lists of figures and tables, and running heads"; site/principal-mention.qmd's paragraph "A heading or a caption can hold the principal mention." says "In a PDF built through LaTeX, a principal mention can sit in a heading, a figure caption or a table caption" and names the same tested configuration.
- consistency gate (2026-10-19): `cairn_validate.py` all checks passed; no principle text changed, so no `cairn_impact` run; the generic profile names no toolchain checks.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the range-closing leak plant cannot go red on this fixture; a second principal range of a key under the closing heading's running head makes the guard load-bearing (reviewer rendered `dahlia, [P:1–2], [P:4–6]` against `4–6` plain) — fix now, fixed 4dabfa0: fixture gains a second dahlia range on pages 9–11, manifest re-derived (16 pages), leak-rangeend now red on `dahlia, 1, [P:5–7], 9–11`, other plant expectations moved to the new pages.
- diff-bug #2: changelog "Before this change, each copy broke the build" implies a heading without lists built — fix now, fixed 4dabfa0: "Before this change, the build stopped."
- diff-bug #3: `\qi@copy` leaves `\noexpand#1`, one protection layer, so a shipout `\write` run with `\protect` as `\relax` would write the worker — follow-up: row "Principal marks through nameref" (no such package found or rendered).
- diff-bug #4: `from_page` counts PDF pages, not printed numbers, unstated — fix now, fixed 4dabfa0: docstring says so.
- diff-bug #5: nothing checks that the lists and running heads print their copies — reject, planned change: AC2 was narrowed to its index promise at the user's choice.
- diff-bug #6: a later begin-document hook redefining `\index` drops every copy — reject, false as a defect: the reviewer verified the typeset path is unaffected, so the only effect is fewer copy registrations.
- blame-history #1: a stale `.toc`/`.lof`/`.lot`/`.out` could name the three inline commands the stand-ins do not define — follow-up: row "Principal marks through nameref"; contents and list lines gobble the copy (`\@gobble@som` observed) and the diff-bug lens built a stale-`.aux` case with a `\nameref` cleanly.
- blame-history #2: the `\index` snapshot depends on begin-document hook order (memoir's `\hideindexmarks`) — reject, false as a defect: a mismatch only drops copies (diff-bug #6 verified the typeset path; the diff-bug lens built memoir clean).
- blame-history #3: the running-head premise (`\index` is `\relax` while a mark is built) is asserted, not checked — reject, false: the claim audit read `\@kernel@before@insertmark` and the mark log showing `\index` kept and the registration dropped.
- prior-review #1: the guard comment and DESIGN sentence say a copy never registers its page, which KI317 contradicts — fix now, fixed 4dabfa0 for DESIGN.md (narrowed to contents line, list line, running head, naming KI317); the core.lua comment ("registers only where its `\index` would also index") holds for `\nameref`, whose `\index` also files there — reject for core.lua, false.
- prior-review #2: deleting KI2 drops a record of the moving-argument concern KI317 shows is live — reject, false: KI317 now holds the live remainder and KI2's "unprobed" is probed.
- prior-review #3: the AC1 render does not delete a stale `examples/principal-headings.aux`/`.ind` first (M20 F10) — reject, false: the fixture keeps Quarto's default `latex-clean`, and the printed index comes from this render's own later pass, which rewrites the `.aux` first.
- prior-review #4: the fixture's `\newcommand*\quartoindexprincipal` hard-errors if the filter's definition lands first (KI61) — reject, planned change: the same documented pattern as principal-cases.qmd and figure-marks.qmd, whose order M20 F13 measured.
- prior-review #5: the docs sentence "Only the mention's own page is emphasized" is false for a range span — fix now, fixed 4dabfa0: "The mention's own page, or a principal range's whole span, is emphasized".
- prior-review #6: the M114 read has no `stop` — reject, false: the index is the document's last section, and any later line would enter the comparison and turn it red, not pass.
- ripple #1: KI74 says no acceptance criterion binds a registered page printing emphasized — fix now, fixed 4dabfa0: KI74 deleted (M114-AC2 binds it), its label dropped from the Locator-control follow-ups row.
- ripple #2: core.lua:126 says REGISTER_COMMAND writes through `\protected@write` directly — fix now, fixed 4dabfa0: "where it is typeset (its guard is below)".
- ripple #3: core.lua:335 says the `.aux` carries the three emitted commands — reject, false: it says the commands they write.
- ripple #4: pdfindex.py docstring's LookupError sentence ignores `from_page` — fix now, fixed 4dabfa0.
- ripple #5: DESIGN.md:528 describes the write one level off — reject, false: the mechanism stated is right, and the added sentence below it states the guard.
- ripple #6: "Four `\providecommand` commands are injected" — reject, false: the count still holds.
- ripple #7: latex.lua:207 says three gobbling stand-ins, the block holds four — follow-up: row "Stand-in count comment" (a pre-existing line the diff did not touch).
- ripple (inside the diff): the docs sentence "Only the mention's own page" contradicts KI317 — fix now, fixed 4dabfa0, with prior-review #5.
