# M38: Marks name which index they belong to, and the HTML back-end prints each

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP4, GP5
- **Branch/PR:** m038-named-indexes-html · https://github.com/jmgirard/quarto-index/pull/38

## Goal

An author can send index marks to more than one named index, which the HTML
back-end prints as one section each.

## Scope

Surface tier: **user-facing** — the deliverable is new author-written syntax
and new rendered output, which the general Quarto community reads.

**In:** an `indexes:` metadata list declaring each index's name and printed
title in order, the first declared being the one an unnamed mark files in;
an `index=` attribute on a mark and on a placement marker; per-index keying
of the format-neutral accumulators, so a cross-reference target, a sort key
and a range pair are all settled within one index; an HTML back-end that
builds one entry tree per declared index and emits one section each, in
declared order, with its own title, section id and entry ids; a PDF render
and a book chapter that index every named-index mark in the document's one
index and report that they did; README and the DESIGN convention line.

**Out:** more than one index in a PDF — Quarto's PDF loop builds only the
main `.idx`, so the design fork (imakeidx's own shell-escape run against a
documented one-index limit) is unsettled → `candidate` row, promoted on that
fork being settled. More than one index across a book's chapters, which
needs the sidecar store's record format and version → `candidate` row,
promoted once this milestone lands. Per-index index styles, headers or
collation rules — nothing here changes how one index is ordered or
printed. Proof that every clause of every check this
milestone adds is shown red by the defect that clause states — AC7 bound
that proof and failed twice, each time by a different mechanism, while the
checks themselves ship and run → `candidate` row, promoted with the readers
it binds in hand.

## Acceptance criteria

- [x] AC1: An HTML render of `examples/named-indexes.qmd`, whose metadata
      declares two indexes, prints one section per declared index in declared
      order. `tests/htmlindex.py` reads the captured page and asserts, for
      each declared index, the section heading's tag and text, the section
      id, and the exact set of top-level entry texts listed under it, against
      a manifest derived from that fixture's marks.
- [x] AC2: A cross-reference target resolves only within its own index. In
      that fixture a `see=` on a mark of the second index whose target names
      a term marked only in the first draws the dangling-target report, and a
      `see=` on a mark of the first index naming that same term draws none;
      both readings come from the captured render log, greped by the report's
      own key.
- [x] AC3: The sort-key registry and range pairing are keyed within one
      index. In that fixture a term carrying `sort=` in the first index sits
      in the letter group its key selects while the same term with no sort
      key in the second index sits in the letter group its own text selects;
      and a `range="open"` in the first index with a `range="close"` on the
      same term in the second leaves the never-closed report for the opening
      and the never-opened report for the closing in the captured log, each
      of the two marks printing an ordinary locator in the captured HTML.
- [x] AC4: A placement marker names the index it places, and the
      first-marker rule applies per index. In a fixture writing three markers
      — one per declared index, plus a second for the first index — the
      captured HTML carries each index's section at its own marker's
      position, asserted by the id of the element preceding the section, and
      the captured log carries exactly one duplicate-marker report, naming
      the repeated index.
- [x] AC5: A named index outside HTML degrades without loss. A PDF render of
      the same fixture leaves in the captured `.tex` an `\index{}` command
      for every mark the fixture's manifest lists, each carrying the argument
      the default index gives it, exactly one `\printindex`, and no marker
      residue; the captured log carries one report per named-index mark and
      one per named-index marker, each naming the index and saying the mark
      was indexed in the document's one index instead. The same two
      properties hold for a chapter of `examples/book/` rendered to HTML.
- [x] AC6: README's new section states the metadata declaration form, the
      `index=` attribute on a mark and on a placement marker, the rule that
      an unnamed mark files in the first declared index, and that a PDF
      render and a book index everything in one index for now; every fixture
      path and command that section names exists in the repo and runs clean.

## Coverage

- AC1 → T1, T2, T5, T7, T8
- AC2 → T3, T7, T8
- AC3 → T3, T7, T8
- AC4 → T4, T7, T8
- AC5 → T6, T7, T8
- AC6 → T10

## Tasks

<!-- T1-T17 are done and each one's outcome is the work-log line naming it, so
     the text here is compressed to what the task was. T11-T17 were added at
     the first review gate, T18-T24 at the second. -->

- [x] T1: Read `indexes:` into an ordered name->title table, first name the default.
- [x] T2: Read `index=` on a mark and on a placement marker, reporting an undeclared value.
- [x] T3: Key the format-neutral accumulators per index, `reset` still emptying each in place.
- [x] T4: Make `resolve_markers` and `place_index` per index, one surviving marker per name.
- [x] T5: `html.lua`: one entry tree and one section per index, ids from the shared `taken` set.
- [x] T6: Fold every named-index mark into the default index in LaTeX and in books, reporting each.
- [x] T7: `examples/named-indexes.qmd` and its manifest, plus the single-index twin.
- [x] T8: The AC1-AC5 checks in `tests/run-tests.sh` and `tests/htmlindex.py`, each over a capture.
- [x] T9: Self-test entries planting one defect per clause of each reader T8 adds.
- [x] T10: README's `### Named indexes` section, the DESIGN convention line, the ROADMAP rows.
- [x] T11: Validate a declared index name as an HTML id fragment, refusing one that is not (R1).
- [x] T12: Settle a folded marker's placement slot so it cannot take the built index's (R2).
- [x] T13: Head a folded union index neutrally, and correct KI10's inventory (R3, R13).
- [x] T14: Report a second marker naming the same non-default index under fold (R4).
- [x] T15: Give the declared-order rule a fixture that marker order cannot satisfy (R5).
- [x] T16: Read AC6's "runs clean" off a ledger of what ran, and pin the declaration block (R6).
- [x] T17: Plant a section heading at the wrong level, for the tag comparison's own clause (R7).
- [x] T18: Plant a defect for every clause `check_folded_site`,
      `check_folded_second`, `check_folded_heading` and `check_readme_indexes`
      state and no plant reaches, and correct the block's two under-counting
      comments and its closing `pass` line to what the readers state (AC7).
- [x] T19: Make `check_folded_second` report a missing `\printindex` as a
      finding rather than raise, and make `check_no_invalid_id`'s control a
      control its reader can actually fail (AC7, F9).
- [x] T20: Narrow `NAME_SHAPE` so a declared name cannot mint a section id no
      `#id` selector addresses, refused with its own report as an empty or
      repeated name is, and widen the id sweep to the character it admits (F1).
- [x] T21: Make `check_html_index_links` report a wrong or missing section id
      as a finding rather than a traceback (F8).
- [x] T22: `DESIGN.md`: add `indexes.lua` to the module list, correct
      `passes.Reset`'s "the three" to the four it calls, and add `data-index`
      to the pass-through residue enumeration, each marked `corrected M38`
      (F5, F6).
- [x] T23: Correct `examples/book/last.qmd`'s prose about its third marker to
      the report the shipped filter draws (F7).
- [x] T24: Correct README's "The last two" for the tenth form (F10).
- [x] T25: Narrow the criteria set to AC1-AC6 at the amendment gate, the
      per-clause proof work going to the hardening candidate row.
- [x] T26: README states the shape a declared index name may take, pinned as
      an AC6 claim (G5).
- [x] T27: Correct the self-test block's two claims about the folded-heading
      reader to what that reader is shown to do (G3).

## Work log

- 2026-08-25: created by /milestone-plan; absorbs the "Multiple named indexes" candidate row added 2026-08-16.
- 2026-08-25: criteria audit ran in REDUCED-scope in-context mode, not the fresh-context reader — the session carries a standing directive against spawning subagents unless asked, reported at the gate. It returned one finding: AC6 as drafted promised "each documented claim is asserted by a check in tests/run-tests.sh", which binds the test harness rather than the deliverable; fixed before the gate by narrowing AC6 to README's own text plus the requirement that every path and command it names exists and runs, with the per-claim check moved to T10.
- 2026-08-25: plan gate probed Quarto 1.10.18 with a two-index imakeidx document: with `noautomatic` the loop built only `probe.idx`, leaving `authors.idx` unprocessed and the second index empty at exit 0; without it, imakeidx ran makeindex itself under restricted shell escape and the second index printed.
- 2026-08-25: plan gate chose YAML metadata declaration over declaring on the placement marker because a book needs one chapter-wide channel and an unmarkered document needs a stated print order; falsified by evidence that authors keep the declaration and the markers out of sync often enough to cost more than the missing order does.
- 2026-08-25: plan gate chose HTML-first with PDF degrading loudly over shipping both back-ends together because the PDF path's design fork is unsettled; falsified by evidence that authors reach for a second index only in print, which would make an HTML-only release useless.
- 2026-08-25: plan gate chose warn-and-fold in books over including book support here because the store's record format and version bump would roughly double this milestone; falsified by evidence that the named-index feature is wanted mainly in books.
- 2026-08-25: plan gate chose "the first declared index is the default" over a reserved default name because a document declaring nothing keeps today's behavior with no reserved word; falsified by evidence that authors reorder the declaration for print order and silently move their default with it.
- 2026-08-25: status in-progress; branch m038-named-indexes-html cut from a synced main. Question gate settled three open implementation choices; recorded below under Decisions.
- 2026-08-25: T1 — `indexes:` metadata read into an ordered name->title table. Two minor task edits: the table lives in a new `modules/indexes.lua` rather than in `core.lua` (core requires nothing and holds constants, not per-document state), and it is read from `passes.Reset` rather than `index.lua`'s `Pandoc`, because the Span passes record marks long before that pass runs. Nine reports cover a non-list, an empty list, a non-map entry, a missing/empty name, a repeated name, a missing/empty title, and a declaration no entry of which is usable; each probed by render. Suite green, 354 checks; warn-distinct's pinned message count 48 -> 61.
- 2026-08-25: T2 — the emitting Span pass and every top-level placement marker read `index=` and report a value naming no declared index; a folded back-end (PDF, or an HTML book) reports each named-index mark and marker and files it in the document's one index. Minor task edit: the three collecting passes read the attribute in T3, where the accumulators they feed are keyed by it, rather than here where the value would have no consumer. Probed by HTML and PDF renders of a two-index fixture; suite green, 354 checks.
- 2026-08-25: T3 — `marked_paths`, `pending_xrefs`, `clamped_paths`, `sort_keys` and `pair_ranges`' pending map are one namespace per index, through a new `qi_core.namespace`; the three collecting passes read `index=` silently and the emitting pass reports it. Probed: a `see=` across indexes dangles while the same target within its own index resolves, and an opening in one index with a closing in the other draws the never-closed and never-opened reports. The M26 pollution probe caught the first cut leaving the module with no index before `reset` ran — a nil accumulator key that failed the synthetic drive and would have made every state-reuse comparison vacuous; the declaration now installs the unnamed index and `reset` restores exactly it. Suite green, 354 checks.
- 2026-08-25: T4 — the first-marker rule is per index: one marker survives per index name, the duplicate report names the index it repeats in a document that declares any, and `place_index` takes a name->blocks map and appends any index no marker names at the end in declared order. Minor task edit: `resolve_markers` keeps its boolean return, since `place_index` reads each surviving marker's index off the marker itself. A marker a folded back-end moves to the document's one index draws its fold report and no duplicate report, so an author is not told of a second marker they never wrote. The suite's duplicate-marker grep key was narrowed from the shared position clause to the half that identifies it, and the new report's key added to the distinctness scan. Suite green, 354 checks.
- 2026-08-25: T5 — `html_index_blocks` returns a name->blocks map, one entry tree and one section per index that has marks, headed with that index's title and identified by `qi-index-<name>`; the entry-id counter runs across every index and every id is checked against the one taken set. Probed on a two-index fixture: two sections, each at its own marker, ids qi-index-authors and qi-index-main, entry ids 1 and 2 across the two. An index with a marker but no marks emits no section rather than a heading over an empty list. Suite green, 354 checks.
- 2026-08-25: T6 — no further code was needed: the fold is one rule, applied where a mark's and a marker's index is resolved, so a LaTeX-derived render and an HTML book both file every named-index mark in the default index and report each. Verified by render — a two-index document to latex leaves exactly one `\printindex` at the first surviving marker, `\index{cat}` and `\index{Knuth}` with their default-index arguments, and no marker residue; a scratch two-chapter HTML book declaring two indexes draws one report for its named mark and one for its named marker, and builds one index carrying all three terms. Suite green, 354 checks.
- 2026-08-25: T7 — `examples/named-indexes.qmd` declares two indexes and carries the cross-index `see=`, the cross-index sort key, the cross-index range pair and three markers; `examples/named-indexes-twin.qmd` is the same terms written by a document that declares none. `examples/book/` gained the declaration, one named mark and one named marker, which is what AC5's book half reads. A folded render now keeps the bare `qi-index` section id: it holds every index's marks, so naming it after one declared index would claim it is that index rather than the union. Suite green, 354 checks, after updating the book's entry manifest (Turing, one.qmd's fifth minted anchor), its letter sweep, its warning count 7 -> 9, the dangling corpus rows for both new fixtures, m29book's duplicate-report pattern and known-warning sets, and the spurious-chapter plant's anchor. The AC1-AC5 manifests themselves are T8's.
- 2026-08-25: T8 — thirteen checks for AC1-AC5, each over a captured artifact. `tests/htmlindex.py` gained `index_sections`/`section_rows`, which read every generated section on a page — id, heading element, heading text, the last authored id before it, and the section's own entry and letter rows — so a page printing the wrong number of sections cannot match a manifest naming each by id; `preceding_authored_id` walks document order rather than siblings, since the writer nests a lower heading's section inside the higher one before it. Two grep keys were added for the fold reports and registered with the distinctness scan, and `check_html_index_links` gained an optional section id. Suite green, 367 checks (was 354).
- 2026-08-25: T9 — eight plants for the section reader, each on a copy of this run's own captured page through the no-op-refusing helper: a section id, a section dropped out of the set, a heading turned into a non-heading element, a heading's text, the authored element a section follows, an entry's text, plus a manifest naming no section and an empty one; a control asserts the reader passes unplanted first. The reader now reports an unreadable section as a finding rather than a traceback. M23's `advance` and `resetmoved` splices were re-anchored on `plan_range`'s new signature. `tests/run-tests.sh --self-test` green, 519 checks.
- 2026-08-25: T10 — README gained a `### Named indexes` section under `## Syntax`, a tenth supported form and a fixture line under Examples; DESIGN gained the per-index scoping convention. The AC6 check reads the section rather than a written-down list: its five claims are compared whitespace-normalized, every `examples/*.qmd` it names must exist, and every command it shows must appear in the suite that runs it. The bibliography-recipe check's section bound was widened from `^## ` to `^#{2,3} `, since the new `###` is the first heading after it. The two follow-up candidate rows the plan added stand as written. Suite green, 368 checks.
- 2026-08-25: T20 — `NAME_SHAPE` drops the dot: `^[A-Za-z][A-Za-z0-9_%-]*$`. A dot is legal in an id and still refused, because `#qi-index-my.index` parses as the id `qi-index-my` carrying the class `index` — a selector that is valid, matches an id this extension never minted, and reports nothing, which is worse than the leading digit the rule already refused for the same reason. The report was reworded to what the rule now admits and its grep key with it. `examples/named-indexes-misuse.qmd` gained a fifth entry naming `my.index`; probed red first — the entry rendered with no report at all — and the M38-R1 check now reads both refusals by the name each refused and counts them 2. A second reader, `check_no_dotted_section_id`, reads the dot over this extension's own section ids alone: Quarto mints ids holding a dot (a heading whose text names a `.qmd`), so the page-wide sweep must not read it. `check_no_invalid_id` returns rather than exiting, which is what let the sibling reader be added beside it; T19 covers the control that change makes real. Suite green, 378 checks.
- 2026-08-25: T19 and T21 — the two readers that raised rather than reported. `check_folded_second` counted its `\printindex` with a bare `str.index`, verified at the return to raise `ValueError: substring not found` naming neither the capture nor what was wanted; it now counts the command and reports a capture carrying anything but one. `check_html_index_links` handed `find_all` a `None` section when the id it was given is not on the page, raising `AttributeError` deep in the walk; it now reports the page and the id it could not find. `check_no_invalid_id` returns rather than calling `fail`, which is what makes its control a control — the reader used to exit the script itself, so the control's own failure branch was unreachable (F9).
- 2026-08-25: T18 — a plant for every clause these readers state and none reached: the folded-site reader on an index standing before every placement site; the second-marker reader on a capture carrying none of the one index and on labels that are not the fixture's two in order; the folded-heading reader on a page carrying two sections; the README reader on each of its four domains that can empty in silence — no section, no yaml block, no fixture path, no command; and the new dotted-id reader on a dot in a section id, shown beside a control asserting the page-wide sweep stays quiet on the same page, since the two readers are only worth having apart. The link reader's new clause is read rather than probed: a traceback and a finding both exit non-zero, and the traceback is what the clause exists to stop, so the finding itself is asserted to name the id and to carry no traceback. The block's two comments now state the clause counts their readers state — four and four, not two and three — and the closing summary was rewritten to what is actually planted. `--self-test` green, 559 checks (was 549); the plain suite 378.
- 2026-08-25: T22 — DESIGN's Architecture section carried the module list and the reset count this milestone made stale. `indexes.lua` joins the module list, `passes.Reset` now reads "the four" it calls with `indexes.lua` first, and `data-index` joins the pass-through residue enumeration, each marked `corrected M38`. Checked against the code rather than recalled: `passes.lua:32-35` calls four resets and its own comment says "First of the four", and the captured gfm render carries `data-index="authors"`.
- 2026-08-25: T23 and T24 — two prose claims the branch made false. `examples/book/last.qmd` said its third marker "places that one instead and says so"; the captured book log says the marker "places nothing", and the fixture's prose is oracle documentation, so it was rewritten to what the report draws. Verified against this run's capture: last.qmd writes the placing marker at line 13, the duplicate at line 20 which is reported as a second marker for the built index, and the `people` marker at line 28 which draws the fold report alone and no duplicate report — which is what the corrected prose now says. README's Syntax paragraph called forms eight and nine "The last two" after a tenth was appended; they are now named. `--self-test` green, 559 checks.
- 2026-08-25: T18-T24 complete; status review. `tests/run-tests.sh --self-test` exit 0, 559 checks; the plain suite 378. Not carried by this round, per the return's triage: F2, F3, F11, F12, F13, F14, F15, F16, F17 and the three blame-history findings stay follow-ups.

- 2026-08-25: review round 3 — AC1-AC6 passed with fresh evidence (full suite --self-test, exit 0, 559 checks, plus direct reads of the captured artifacts) and the consistency gate was clean. AC7 FAILED and returns the milestone to in-progress: `check_folded_heading`'s section-count clause — the one clause round 2 named — is still not shown red, because its plant inserts a heading-less section and `index_sections` raises `ValueError` before the count comparison, while `probe_defect` reads only the exit status; verified here by running the reader over a fabricated two-section page. The three-lens review added G2 (the same reader raises rather than reports) and G3 (three branch-added claims that the clause is planted), plus G5, a README that documents no rule for the name shape T20 tightened. Defect return 3 for this milestone; no amendment return, no criterion reinterpreted. The thrash rule fires on both triggers and the disposition goes to the maintainer.

- 2026-08-25: maintainer disposition at the round-3 return — descope. M38 narrows to AC1-AC6, all six verified this round; AC7 and the reader-proof work it binds (G1, G2, G3, G15) exit the milestone, and G5 rides the narrowed set since AC6 stays. The narrowing runs through the gated criterion-amendment protocol in /milestone-implement, then re-review of the narrowed set. Neither a re-cut nor an escalation was spent.
- 2026-08-25: T25 — amendment gate: the criteria set narrows to AC1-AC6, AC7 deleted whole and its Coverage row with it; no AC1-AC6 wording changed, so nothing was widened and no fresh-reader audit of amended wording was owed. Scope's Out gained the descoped promise: "Proof that every clause of every check this milestone adds is shown red by the defect that clause states — AC7 bound that proof and failed twice, each time by a different mechanism, while the checks themselves ship and run → `candidate` row, promoted with the readers it binds in hand." The work itself was absorbed into the acceptance-suite hardening candidate row rather than filed as a new one (search-first): its section-count clause, that reader's raise-rather-than-report shape, and `ran_clean`'s unplanted clause. Gate also chose to fix G5 and the two false self-test claims (T26, T27) and to skip the fresh reader.
- 2026-08-25: T26 — README's named-index section states the rule T20 tightened: "A name holds ASCII letters, digits, hyphen and underscore and begins with a letter, because it becomes the id of the section that index prints under; an entry declaring any other name is reported and declares no index." Written against `indexes.lua:49`'s `NAME_SHAPE` and the report it draws, not recalled. Pinned as a sixth AC6 claim row (`name shape`); probed by running the README reader over a copy of the shipped README with the character list shortened — red, naming the row — beside the shipped README as its control, green.
- 2026-08-25: T27 — three branch-added claims the artifact does not bear out, corrected to what it does. The folded-heading reader's two-section plant inserts a heading-less section, so `index_sections` raises `ValueError: the generated index section 'qi-index-extra' carries no heading element` before the count comparison — verified here by running the reader over a fabricated two-section page. The plant's block comment, its `probe_defect` label and the block's closing `pass` line now say the page is shown unreadable and the section-count clause is planted by nothing. The same `pass` line attributed a "none of the one index" plant to the folded-site reader, which has none — it belongs to the second-marker reader; the enumeration was corrected against the plants actually written. No plant and no reader behavior changed.
- 2026-08-25: T25-T27 complete; status review. The criteria set is AC1-AC6, all six verified with fresh evidence at round 3 and unchanged in wording since. `tests/run-tests.sh --self-test` exit 0, 559 checks; `cairn_validate` clean but for the task-count advisory this milestone already accepts. The narrowing's own follow-up rides the acceptance-suite hardening candidate row.

## Decisions

- 2026-08-25 (gate): An index is declared as a list entry carrying `name:` and
  `title:`, rather than as a one-key `name: title` pair, so a later per-index
  setting is a third field rather than a change to syntax authors have already
  written. A placement marker naming no index places the first declared index,
  the same index an unnamed mark files in, so one rule covers marks and markers
  alike; a declared index no marker names goes at the end of the document in
  declared order, which is what a marker-less document does today. Each
  section's id is derived from the index's own name — `qi-index-<name>` — so a
  link keeps pointing at the same index when the declaration is reordered; a
  document declaring no indexes keeps the bare `qi-index` it has today.
- 2026-08-25 (return gate): A declared index name must be usable as an HTML id
  fragment — ASCII letters, digits, `-`, `_` and `.`, beginning with a letter —
  and a name that cannot be one is refused with its own report, exactly as an
  empty or repeated name is, so the document keeps the indexes it declared
  usably and never emits a section whose `id` no link resolves against. Under
  fold the one index is placed at the first marker naming the default index
  where the document writes one, and only otherwise at the first folded marker,
  so the author's own default marker is never reported as the duplicate of a
  marker they never wrote; the folded section is headed `Index`, the heading a
  document declaring nothing prints, for the same reason `section_id` keeps its
  id bare — the section holds every index's marks, so one declared index's
  title would claim it is that index. AC6's "runs clean" is read off a ledger
  the suite writes as it renders, each documented command required to appear
  there with exit status 0, rather than off a substring of the suite's own text.

- 2026-08-25: return gate settled four open choices for T11-T17; recorded under Decisions above.
- 2026-08-25: T11 — a declared name must match `^[A-Za-z][A-Za-z0-9._%-]*$`; a name that cannot be an HTML id fragment is refused with its own report, so the document keeps the indexes it declared usably. `examples/named-indexes-misuse.qmd` writes four entries of which two are refused and one has no title; the M38-R1 check reads the refusal by name, matches the two sections the two usable entries leave, and asserts no id on the whole rendered page holds a space, a `#`, a `<` or a `>` — probed red by planting `id="qi-index-my people"` into this run's own capture. warn-distinct's pinned count 62 -> 63. Suite green, 370 checks (was 368).

- 2026-08-25: T12 — `resolve_markers` reads every top-level marker's authored index in a pass of its own, then settles the one place a folded back-end has for its one index: the author's own marker for the index that IS built holds it wherever it stands, and only where the document writes no such marker does the first marker of any name hold it. `placed` is keyed by the authored index rather than the built one, so a marker naming a second index is no longer a duplicate of the first. The fold report for a marker gained a second shape for the marker that does not hold the place, and a third state that stays quiet where a duplicate report says the same thing with the marker it lost to. `examples/named-indexes-foldsite.qmd` writes the `authors` marker before the built index's own, and the M38-R2 check reads off the captured `.tex` that the single `\printindex` follows `site-main` and that no duplicate report of either wording is drawn — the reader probed red on a copy of that capture with `\printindex` moved under `site-authors`. m29book's book-html/book-pdf partition and AC5's marker counts moved to the new shape, which is the one `examples/book/last.qmd` and `named-indexes.qmd` both draw. warn-distinct 63 -> 64. Suite green, 372 checks.

- 2026-08-25: T14 — the duplicate report follows from T12's authored-index keying: a second marker naming the same folded-away index is now the second marker of THAT index rather than a marker of the built one, so it draws the duplicate report naming it instead of being dropped. `examples/named-indexes-foldsecond.qmd` writes two `authors` markers and no marker for the built index, which is also the one fixture drawing the fold shape for the marker that DOES place the one index; the M38-R4 check reads off the captured `.tex` that `\printindex` follows the first site alone, counts the two fold shapes 1 and 0, and reads the one duplicate report by the index it names. Suite green, 375 checks.

- 2026-08-25: T13 — `indexes.title` returns the neutral `Index` wherever a declaring document folds, the same reason `section_id` keeps that section's id bare; the code landed with T11's commit, its check and the DESIGN correction here. `examples/book/`'s first declaration was retitled `Index of Subjects` so the fixture can tell the two apart, and the M38-R3 check reads the one section off the captured book page — one section, bare id, `h1`, headed `Index` — probed red by planting `Index of Subjects` into that heading on a copy of this run's capture. KI10's inventory was corrected against `tests/stateprobe.py`'s `CELLS`: 15 cells there plus `indexes.lua`'s four is 19, not the 17 the entry claimed, whose prose named neither `contested_keys` nor the new four. The entry now also records that M26's probe proves 15 of the 19 — the four new cells are reset per document but sit outside its enumeration, and the fixtures it drives declare no indexes, so a removed reset for them would show nothing to compare; that gap is a follow-up, not a repair this return covers. Suite green, 376 checks.

- 2026-08-25: T15 — `examples/named-indexes-order.qmd` declares three indexes and writes one marker, for the last of them, so the page's section order is Third, First, Second: neither the declared order nor the marker order, and the two appended indexes are in declared order, which is the one place that rule is the rule rather than a coincidence of where the markers were written. The M38-R5 manifest is derived by hand from the fixture and the two documented rules, and the fixture draws no report at all. Note for the record: section order follows marker order wherever markers exist, and declared order only for the appended ones — AC1's evidence stands because its fixture writes its markers in declared order, so both readings agree there. Suite green, 378 checks.

- 2026-08-25: T16 — the two renders README shows now go through `ran_clean`, which runs the argv it is handed, writes that argv and the status it exited with to `$WORK/ran-commands.txt`, and fails loudly on anything but 0; the command text is never copied, so nothing can drift from what ran. AC6's check moved below those renders and reads its "runs clean" off that ledger: a documented command absent from it is unrun, and one present with a non-zero status is dirty. The `indexes:` block is pinned line for line against every yaml fence in the section, since normalizing a YAML block's whitespace throws away the one thing an author copies it for. R12's comment slip went with the rewrite — the check now counts its own claims (5) rather than a comment saying four. Suite green, 378 checks.

- 2026-08-25: T17 — the section reader gained the plant its tag comparison had none of: an `h2` where the manifest states an `h1`, which the earlier non-heading plant could not reach because it exercised the no-heading guard alone. Task refined beyond its one line, since AC7 binds every reader this milestone adds and this return round added four: the R1-R4 and AC6 readers were lifted out of their inline heredocs into `check_no_invalid_id`, `check_folded_site`, `check_folded_second`, `check_folded_heading` and `check_readme_indexes`, each now callable over a planted copy. Nineteen new plants, each on a copy of this run's own capture through the no-op-refusing helper and each preceded by a control: three characters no id may hold; the one index moved to the wrong marker in each of the two fold shapes; a capture with the wrong number of placement sites or of indexes; a union section headed with a declaration's own title, named after one declared index, or headed below an h1; and a README missing a claim, showing a declaration block whose title or indentation is not the pinned one, naming a fixture that does not exist, and a ledger missing a documented command, carrying one with a non-zero status, or empty. `tests/run-tests.sh --self-test` green, 549 checks; the plain suite green, 378.

- 2026-08-25: README's fold section stated what happens to a folded mark and marker but not where the one index goes, which T12 made a question with an answer; one sentence added — "The one index is placed at your own marker for it, wherever that marker stands; only where no marker names it does the first marker of any name place it." — and pinned as a sixth AC6 claim row. A slip caught by reading the run log rather than the exit status: the README reader's claims loop rebound `label`, so every message it prints named the last claim row instead of the check; renamed to `row`.
- 2026-08-25: T11-T17 complete; status review. `tests/run-tests.sh --self-test` exit 0, 549 checks; the plain suite 378. Not carried by this return, per the gate's triage: R8, R9, R10, R11 and R14 stay follow-ups, and KI10 now records that M26's probe proves 15 of the 19 accumulators, the four `indexes.lua` cells being outside its enumeration.

## Review

Reviewed 2026-08-25 on m038-named-indexes-html at d9ac001 (+ this section),
PR #38. `main` had not moved since the branch was cut, so no merge was needed.
Fresh evidence: one full `tests/run-tests.sh --self-test` run, exit 0, 520
checks; plus direct reads of the captured artifacts named below.

### Acceptance criteria

- AC1 — PASS. The captured `named-indexes.html` carries exactly two generated
  sections; `check_index_sections` matched all 18 manifest rows in order
  (`M38-AC1`), and a direct read of `section_rows` over the same capture gives
  `qi-index-main` / h1 / "Index" then `qi-index-authors` / h1 / "Index of
  Authors" — declared order, each heading tag, text, id and top-level entry set
  as the fixture's manifest states. Link and letter-group sweeps over both
  sections passed (4 and 3 links resolved; 8 letter groups in order).
- AC2 — PASS. Over the captured HTML render log, greped by the
  dangling-target report's own key: exactly one such report, and it names
  `Stranger`, the second index's mark whose `see=` targets `Aardvark` — a term
  only the first index carries. The first index's `Neighbour`, whose `see=`
  names that same `Aardvark`, draws none and renders as a resolved
  `see-link`, while `Stranger` renders as `see-plain`.
- AC3 — PASS. Both halves read from the same capture. Sort keys: the direct
  `section_rows` dump shows `Hague` under letter group Z in `qi-index-main`
  (where a mark writes `sort="Zebra"`) and under H in `qi-index-authors` (where
  no mark writes one). Range pairing: the captured log carries exactly one
  never-closed report and exactly one never-opened report, and the section
  manifest AC1 matched lists both `Cantor` marks with an ordinary locator
  (locator count 1 in each section), so neither half printed a range.
- AC4 — PASS. In the same capture each section's `after` field — the last
  author-written id before it, minted ids skipped — is `site-main` for
  `qi-index-main` and `site-authors` for `qi-index-authors`, so each index sits
  at its own marker. The captured log carries exactly one duplicate-marker
  report; a grep by the report's key confirms it names the repeated index, and
  a second grep confirms the unnamed-index wording a declaring document must
  not use is absent.
- AC5 — PASS, both halves. LaTeX: the captured `named-indexes.tex` carries 8
  `\index{}` commands matching all 7 manifest rows, exactly one `\printindex`,
  and zero occurrences of the marker id — read directly off the capture as well
  as by the suite's manifest and token checks. Each named-index mark carries
  the argument the default index gives it, including `Zebra@Hague` for the
  second index's `Hague`, which writes no sort key of its own. The captured log
  carries one fold report per named-index mark (4) and one per named-index
  marker (1), each naming the index the author wrote. Book: the captured
  `book-html/_book/last.html` carries exactly one generated section, keeping the
  bare `qi-index` id since it holds every index's marks, and `Turing` — the
  chapter's `index="people"` mark — is listed in it; the captured book log
  carries one fold report for that mark and one for the named marker.
- AC6 — PASS. Read directly from `README.md`'s `### Named indexes` section: it
  shows the `indexes:` metadata form with `name`/`title` and says what each
  does; shows `index=` on a mark and on a placement marker, each with an
  example; states that a mark or marker naming none takes the first declared
  index; and states under its own subheading that a LaTeX or PDF render and an
  HTML book each build a single index for now, folding and reporting every
  named-index mark and marker. The suite's `M38-AC6` check confirmed the
  section's pinned claims are present, that the 2 fixture paths it names exist,
  and that the 2 commands it shows are commands this suite runs — the suite
  being green is what "runs clean" reports.
- AC7 — PASS. `tests/run-tests.sh --self-test` exited 0 with 520 checks. The
  eight plants for this milestone's section reader each ran red on its own
  clause — a section id, a section dropped from the set, a heading turned into
  a non-heading element, a heading's text, the authored element a section
  follows, an entry's text, plus a manifest naming no section and an empty one
  — and a control asserted the reader passes on the same captured page
  unplanted before any of them. Every plant is applied to a copy of this run's
  own capture through the no-op-refusing helper, so a plant that changed
  nothing would itself fail.

### Consistency gate

- `cairn_validate.py` exit 0 — every check PASS, every advisory OK; the
  `release window` advisory did not fire.
- Toolchain checks: the active `generic` profile names none, so this half is a
  clean no-op.
- `cairn_impact.py` not run: the milestone added a `DESIGN.md` convention
  bullet and changed no numbered principle's text.

### Independent review

Three fresh-context reviewers, each on a distinct evidence base, spawned at the
user's explicit direction (the session carries a standing directive against
spawning subagents unless asked; the directive was put to the user at this
gate and they chose the full fan-out).

- [S] prior-PR-comments lens: no findings. It read the archived `## Review`
  sections touching these files (M03, M04, M05, M08, M17, M19, M20, M22, M23,
  M25, M26, M28, M29, M31) and probed the GitHub inline-comment surface, which
  returned empty, so the per-PR walk was not paid for.
- [S] blame-history lens: one finding (R13 below); no D-entry contradicted, no
  guard weakened, M26's reset invariant intact.
- [O] diff-bug lens: twelve findings (R1-R12 below).

Findings, ranked as reported, with the disposition each was given. R1-R4 were
re-verified in this session by probe renders against the shipped extension in a
scratch copy, never against the reviewer's account of it.

- R1: An index name is never validated as an HTML id fragment, so a declared
  name with a space emits an invalid `id`. Confirmed by probe: a document
  declaring `name: "my index"` renders `<section id="qi-index-my index">`, with
  no report drawn. An id carrying whitespace is invalid HTML and no link to it
  resolves. `#`, `"` and `<` are the same hole.
- R2: In a folded render, a marker naming a second index takes the default
  index's placement slot, and the author's own default marker is then reported
  as its duplicate. Confirmed by probe: a two-index document whose `authors`
  marker precedes its unnamed marker renders `\printindex` under the `authors`
  marker's heading, and the log says the author's single `main` marker "is a
  second marker for the index named main". The comment at `marker.lua:252-256`
  says the design avoids exactly this false report; it avoids it only in the
  marker ordering `examples/named-indexes.qmd` happens to use.
- R3: A folded union index is headed with the first declared index's title,
  contradicting the reason its id is kept neutral. Confirmed by probe: a book
  declaring `people` first and `main` second heads its single union section
  `Index of People` while carrying `main`'s marks, under the neutral id
  `qi-index` that `indexes.lua:264-266` keeps neutral precisely so the section
  does not claim to be one declared index.
- R4: Two markers naming the same non-default index draw no duplicate report at
  all under fold; one is silently dropped. Confirmed by probe: two
  `index="authors"` markers in a LaTeX render draw two fold reports and no
  duplicate report. README's "A second marker for one index is reported and
  places nothing" is false for that shape in PDF and in books.
- R5: AC1's "in declared order" is not what the check asserts. The fixture
  writes its markers in declared order, so section order equals marker order
  and declared order at once and the manifest cannot tell them apart; the
  markerless-append path, the one place declared order is actually the rule,
  is exercised by no fixture.
- R6: AC6's "every command runs clean" is a substring match over the whole
  suite file, comments included, and reads no exit status; the `indexes:` YAML
  block the criterion names is pinned by nothing.
- R7: The self-test's heading-element plant only exercises the no-heading
  guard, not the tag comparison — an `h2` where an `h1` belongs has no plant.
- R8: `index=""` is silently accepted in a document that declares nothing,
  while the same attribute in a declaring document is reported.
- R9: A declared index with a marker and no marks disappears with nothing said.
  A continuation of the pre-M38 whole-document silence, far easier to hit per
  index.
- R10: `latex.lua`'s `contested_keys` is the one accumulator M38 did not
  namespace — unreachable today, the sole exception to the DESIGN bullet's
  "every format-neutral accumulator is one namespace per index", and live the
  day the PDF fork lands.
- R11: Dangling-target reports are now grouped by index rather than emitted in
  document order — deterministic, user-visible, unnoted.
- R12: Bookkeeping — `warn-distinct.py`'s `EXPECTED` is 62 while the T1 work-log
  line records 48 -> 61; the `README_INDEXES_CLAIMS` comment says "four claims"
  over a five-row manifest; T1/T2's task text cites file positions the shipped
  code moved.
- R13: `DESIGN.md`'s KI10 says "M26 resets all 17 per document" and enumerates
  them through M23; `indexes.lua` adds four more module-level per-document cells
  (`order`, `titles`, `declared`, `folded`), all correctly reset by
  `indexes.reset` and confirmed so here, but KI10 is now an incomplete inventory
  of the surface it exists to document.
- R14 (this session, over AC6): the pinned-claim manifest carries no row for
  README's "A mark says which index it belongs to with `index=`" sentence or its
  example, so that claim — one AC6 enumerates — could be deleted from README
  without the check going red.

### Triage

Maintainer at the 2026-08-25 gate: send back, fixing the four confirmed output
defects and the three check gaps that let them through. R1 and R2 qualify under
the return floor as load-bearing defects in what the extension does for an
author — silently invalid HTML, and a wrong placement site paired with a report
accusing the author of a second marker they never wrote. Both sit inside
changes this milestone intentionally made, so the out-of-scope member for an
intentional change does not cover them.

- R1, R2, R3, R4 → fix now, on the branch, as T11-T14.
- R5, R6, R7 → fix now, as T15-T17: the checks that were supposed to fence this
  work and did not.
- R8, R9, R10, R11, R14 → follow-up. Filed as candidate rows or Known issues in
  the hygiene pass of whichever review merges this milestone; R9 is a Known
  issue (a fact about today's behavior, not proposed work).
- R12's comment and count slips → fixed with T15-T17. Its work-log citation
  (48 -> 61 against a shipped 62) is history and is superseded by the T11-T17
  work-log lines, never edited.
- R13 → fix now, with T11-T14, since the entry it corrects is about the state
  this milestone added.
- 2026-08-25: review — PR #38 opened; `main` had not moved. All seven criteria passed with fresh evidence (full suite --self-test, exit 0, 520 checks) and the consistency gate was clean. Returned to in-progress at the merge gate under the return floor: the independent review found, and this session re-verified by probe, that a declared index name is never validated as an HTML id fragment so a name with a space emits an invalid `id` with no report (R1), and that in a folded render a marker naming a second index takes the default index's placement slot while the author's own default marker is reported as its duplicate (R2). R3, R4 and the three check gaps R5-R7 ride the same return. Defect return 1 for this milestone; no amendment return, no criterion reinterpreted. Requested changes logged as T11-T17 at the gate's direction.
- 2026-08-25: the seven added tasks put the plan-owned body 14 lines over the cap; the Tasks section, the heaviest, was compressed in one rewrite — T11-T17 shortened to what each task was alongside T1-T10, their outcomes already standing in the work-log lines above.
- 2026-08-25: maintainer triage at the return — the proposed set stands: the AC7 coverage gap plus F1, F5, F6, F7, F8 and F10 are fixed this round, logged as T18-T24; every other finding stays a follow-up as recorded above.
- 2026-08-25: review round 2 — AC1-AC6 passed with fresh evidence (full suite --self-test, exit 0, 549 checks, plus direct reads of the captured artifacts) and the consistency gate was clean. AC7 FAILED at step 3 and returns the milestone to in-progress: the criterion binds a plant to each clause of each reader this milestone adds, and four of the five readers ship clauses no plant exercises — check_folded_site 3 of 4, check_folded_second 1 of 3, check_folded_heading 3 of 4, check_readme_indexes 6 of 10 — while check_folded_second's \printindex lookup raises ValueError rather than reporting a finding, and check_no_invalid_id's control cannot take its own failure branch. The three-lens review added F1 (a declared name may hold a `.`, minting a section id no `#id` selector can address) and five further defects inside intentional changes: F5, F6, F7, F8, F10. Defect return 2 for this milestone; no amendment return, no criterion reinterpreted.
- 2026-08-25: the seven added tasks put the plan-owned body 4 lines over the cap; the Tasks section, the heaviest, was compressed in one rewrite — T1-T10 shortened to what each task was, their outcomes already standing in the work-log lines above. `cairn_validate` passes; the 17-task split tripwire is an advisory this milestone accepts, the seven added tasks being one round of gate-directed repair rather than new scope.

### Round 2 — 2026-08-25

Reviewed at fc541c8 on m038-named-indexes-html, PR #38 (draft, already open).
`main` had not moved since the branch was cut, so no merge was needed. Fresh
evidence: one full `tests/run-tests.sh --self-test` run, exit 0, 549 checks,
plus direct reads of the captured artifacts named below.

- AC1 — PASS. A direct `index_sections` read of the captured
  `named-indexes.html` gives exactly two generated sections in document order:
  `qi-index-main` / h1 / "Index", then `qi-index-authors` / h1 / "Index of
  Authors" — declared order, each heading tag, text and id as the fixture's
  manifest states, with top-level entry sets {Aardvark, Cantor, Neighbour,
  Hague} and {Babbage, Cantor, Hague, Stranger}. The suite's `M38-AC1` matched
  all 18 manifest rows in order; link and letter sweeps passed (4 and 3 links,
  8 letter groups).
- AC2 — PASS. The captured HTML render log carries exactly one dangling-target
  report, naming `see=` on entry "Stranger" pointing at "Aardvark", a term only
  the first index carries. `Neighbour`, whose `see=` names that same target from
  within the first index, draws none and renders as a resolved link
  (`xrefs=[('see','Aardvark',True,'#qi-entry-1')]`), while `Stranger` renders
  unresolved (`(..., False, None)`).
- AC3 — PASS. Both halves off the same capture. Sort keys: `Hague` sits under
  letter group Z in `qi-index-main`, where a mark writes `sort="Zebra"`, and
  under H in `qi-index-authors`, where none does. Range pairing: the captured
  log carries exactly one never-closed report and one never-opened report, and
  each `Cantor` entry carries a single ordinary locator (`#qi-mark-5`,
  `#qi-mark-6`), so neither half printed a range.
- AC4 — PASS. Each section's `after` — the last author-written id before it —
  is `site-main` for `qi-index-main` and `site-authors` for `qi-index-authors`,
  so each index sits at its own marker. The captured log carries exactly one
  duplicate-marker report, and it names the repeated index ("main").
- AC5 — PASS, both halves. LaTeX: the captured `named-indexes.tex` carries 8
  `\index{}` commands against the manifest's 7 rows, exactly one `\printindex`,
  and zero marker residue. Each named-index mark carries the argument the
  default index gives it, including `Zebra@Hague` for the second index's
  `Hague`, which writes no sort key of its own. The log carries 4 fold reports
  for named-index marks and 1 for the named-index marker, each naming
  "authors". Book: the captured `book-html/_book/last.html` carries exactly one
  generated section under the bare `qi-index` id, headed "Index", listing
  `Turing` — the chapter's `index="people"` mark — among its 14 terms; the book
  log carries one fold report for that mark and one for the named marker.
- AC6 — PASS. Read directly from `README.md`'s `### Named indexes` section: it
  shows the `indexes:` metadata form with `name`/`title` and says what each
  does; shows `index=` on a mark and on a placement marker with an example
  each; states that a mark or marker naming none takes the first declared
  index; and states under its own subheading that a LaTeX or PDF render and an
  HTML book each build one index for now. Both fixture paths it names exist,
  and this run's `ran-commands.txt` ledger carries both documented commands
  with exit status 0.
- AC7 — **FAIL.** `tests/run-tests.sh --self-test` exits 0 with 549 checks, and
  every plant this milestone writes runs red behind a passing control. But the
  criterion requires a plant for *each clause of each reader this milestone
  adds*, and four of the five readers ship clauses no plant exercises. Read off
  the shipped readers against the shipped plants:
  `check_folded_site` states four failure clauses and three are planted — the
  clause for an index standing before every placement site has none;
  `check_folded_second` states three and one is planted — its label-order
  clause has none, and its `\printindex` lookup is a bare `str.index`, verified
  here to raise `ValueError: substring not found` rather than report a finding,
  which is the traceback-not-a-finding defect T9 fixed for the section reader;
  `check_folded_heading` states four and three are planted — the section-count
  clause, which its own comment names first, has none, verified here to fire
  cleanly on a two-section capture; `check_readme_indexes` states ten and six
  are planted — its four empty-domain guards (no section, no yaml fence at all,
  no fixture named at all, no command shown at all) have none, the same
  silently-emptying-domain class the round-1 section reader *did* plant with
  "a manifest naming no section" and "an empty manifest". The block's own
  comments under-count with the readers: it calls the folded-site reader "two
  clauses" against four, and the folded-heading reader "three" against four.
  Its closing `pass` line states that each reader "fails on every clause it
  states planted on its own", which is a branch-added claim the artifact it
  describes does not bear out.

### Consistency gate (round 2)

- `cairn_validate.py` exit 0 — every check PASS, every advisory OK except the
  sizing tripwire (17 tasks), which this milestone's work log already accepts
  as one round of gate-directed repair rather than new scope. The `release
  window` advisory did not fire.
- Toolchain checks: the active `generic` profile names none, so this half is a
  clean no-op.
- `cairn_impact.py` not run: the diff changes no IP/GP principle line in
  `DESIGN.md`.

### Independent review (round 2)

Three fresh-context reviewers on distinct evidence bases, spawned at the user's
explicit direction (the session carries a standing directive against spawning
subagents unless asked; put to the user at this round and they chose the full
fan-out).

- [S] prior-review-record lens: no findings. It read the archived `## Review`
  records for the milestones touching these files (M01-M05, M08, M17, M19, M20,
  M22, M23, M25, M26, M28, M29, M31), `LESSONS.md` and DESIGN's Known issues,
  and probed the GitHub inline-comment surface, which returned empty, so the
  per-PR walk was not paid for. Nothing in the diff reintroduces or contradicts
  a point an earlier review raised.
- [S] blame-history lens: three findings (B1-B3); no D-entry contradicted, no
  guard weakened. It confirmed M23's position-binding guards, M24's
  captured-artifact rule, D-005 and D-009/D-010, and the id-collision guard all
  intact, and each module's own `reset` complete.
- [O] diff-bug lens: seventeen findings (F1-F17).

Findings, ranked as reported, each with its disposition. F1, F4, F5, F6, F7,
F8, F9 and F10 were re-verified in this session against the shipped extension
and the captured artifacts, never against the reviewer's account.

- F1: `NAME_SHAPE` admits `.`, so a declared name mints a section id that no
  plain `#id` selector can address — the same failure the rule's own comment
  gives as its reason for refusing a leading digit. Confirmed by probe render
  in a scratch copy: `name: my.index` is accepted with no report and emits
  `<section id="qi-index-my.index">`, which a CSS or `querySelector` `#id` rule
  parses as `#qi-index-my` plus the class `.index`. `check_no_invalid_id`
  greps only `[[:space:]#<>]`, so it passes. This is the residue T11's
  positive-shape rule left behind, not a re-report of R1.
- F2: `index=""` is accepted in silence on a placement marker as well as on a
  mark, in a document that declares nothing. Extends R8, which named only the
  mark half.
- F3: the Scope line and AC1's headline state an unconditional "in declared
  order", while the shipped rule is marker order first and declared order only
  for indexes no marker names. AC1 as written is satisfied by its fixture,
  whose marker order and declared order coincide; the Scope prose is the loose
  one. Overlaps R5, which T15 answered with a fixture rather than an amendment.
- F4: a second marker naming the same folded-away index draws the
  duplicate-marker report rather than a fold report. Read off the captured
  `named-indexes-foldsecond-latex` log: both markers are reported, and the
  duplicate report names "authors", so README's "each is reported by the index
  it named" holds. What remains is a reporting-shape observation, not a false
  claim.
- F5: `DESIGN.md`'s Architecture section omits `indexes.lua` from "The
  modules, in dependency order" and still says `passes.Reset` calls three
  resets. Confirmed: `passes.lua:32-35` calls four, and its own comment says
  "First of the four". KI10 was corrected by R13; the Architecture prose was
  not.
- F6: DESIGN's pass-through residue enumeration lists six `data-` attributes;
  M38 added a seventh. Confirmed in the captured gfm render, which carries
  `data-index="authors"`.
- F7: `examples/book/last.qmd`'s prose about its third marker describes
  pre-T12 behavior. It says the book "places that one instead and says so";
  the captured book log says "so this marker places nothing". A fixture's
  prose is oracle documentation here.
- F8: `check_html_index_links`'s new section-id argument turns a wrong or
  missing id into a traceback rather than a finding. Confirmed:
  `find_id(doc, 'qi-index-nosuch')` returns `None` and `find_all` raises
  `AttributeError`. Same shape T9 fixed for the section reader.
- F9: `check_no_invalid_id`'s self-test control can never take its own `|| fail`
  branch — the reader calls `fail`, which exits the script, so the control
  string is unreachable and the control cannot tell a broken reader from a bad
  page. It is the one M38 control of the five that is not a real control.
- F10: README's Syntax prose still calls forms 8-9 "The last two" after a tenth
  form was appended.
- F11: `INDEX_ATTR`, `INDEXES_KEY` and `NAME_SHAPE` are not pinned to the
  filter's own constants by any scan, unlike `MARKER_CLASS` and
  `HTML_SECTION_ID`.
- F12: AC6's pinned-claim manifest still carries no row for README's
  "A mark says which index it belongs to with `index=`" sentence. This is R14,
  deliberately deferred.
- F13: the return gate's two rulings live only in the milestone file, not in
  `DECISIONS.md`. A maintainer call, not a defect.
- F14: a name declared as `here` mints `id="qi-index-here"`, byte-identical to
  the literal the marker-residue sweeps grep for. A maintainer hazard, no
  user-facing defect.
- F15: `latex.lua`'s `contested_keys` is the one accumulator M38 did not
  namespace. Restates R10, confirmed still present.
- F16: dangling-target reports are emitted grouped by index rather than in
  document order. Restates R11.
- F17: a mark that indexes nothing carrying an `index=` value naming no
  declared index draws no report. `passes.lua:382-390` reads the attribute
  after the early return, and its comment states the reason: telling an author
  which index a mark was filed in would describe a filing that never happened.
  An intentional consequence of a documented choice.
- B1: M26's state probe still enumerates 15 cells, so `indexes.lua`'s four are
  reset in code but not proven by the probe. Already recorded in KI10 by R13 as
  a follow-up, not a repair that round covered.
- B2: no `DECISIONS.md` entry for the fold policy, unlike its closest
  precedent D-005. Same substance as F13.
- B3: with `clamped_paths` namespaced per index, the contested-path report's
  final sort compares `.path` alone, so two different indexes contesting the
  identical printed path are ordered by nothing pinned. Speculative — the
  reviewer found no fixture reaching it, and neither did this session.

### Triage and disposition (round 2)

AC7 fails, so M38 returns to `in-progress` under step 4's exit. This is defect
return 2 for the milestone; no amendment return, no criterion reinterpreted.

- The AC7 gap → fix now: a plant for each unplanted clause of `check_folded_site`,
  `check_folded_second`, `check_folded_heading` and `check_readme_indexes`;
  `check_folded_second`'s bare `str.index` made to report a finding rather than
  raise; the block's two under-counting comments and its closing `pass` line
  corrected to what the readers state; and F9's decorative control made real.
- F1, F5, F6, F7, F8, F10 → fix now. Each is a defect inside a change this
  milestone intentionally made, so the out-of-scope member for an intentional
  change does not cover them.
- F2, F3, F11, F12, F13, F14, F15, F16, F17, B1, B2, B3 → follow-up. Filed as
  candidate rows or Known issues in the hygiene pass of whichever review merges
  this milestone. F12/F15/F16 and B1 are already-filed follow-ups (R14, R10,
  R11, KI10) and need no new row.

### Round 3 — 2026-08-25

Reviewed at 6654b40 on m038-named-indexes-html, PR #38 (draft, already open).
`main` had not moved since the branch was cut, so no merge was needed. Fresh
evidence: one full `tests/run-tests.sh --self-test` run, exit 0, 559 checks,
plus direct reads of the captured artifacts named below. A first run of the
suite was discarded: the blame-history reviewer ran the suite itself in this
shared checkout, wiping `tests/.work` mid-run, and the re-run below was made
with no other agent working.

- AC1 — PASS. A direct `section_rows` read of the captured `named-indexes.html`
  gives exactly two generated sections in document order: `qi-index-main` / h1 /
  "Index" with top-level entries {Aardvark, Cantor, Neighbour, Hague}, then
  `qi-index-authors` / h1 / "Index of Authors" with {Babbage, Cantor, Hague,
  Stranger} — declared order, each heading tag, text and id as the fixture's
  manifest states. The suite's `M38-AC1` matched all 18 manifest rows in order;
  link and letter sweeps passed (4 and 3 links, 8 letter groups).
- AC2 — PASS. The captured HTML render log carries exactly one dangling-target
  report, and it names `see=` on entry "Stranger" pointing at "Aardvark", a term
  only the first index carries. In the same capture `Neighbour`, whose `see=`
  names that same target from within the first index, renders `see-link
  Aardvark` (resolved) while `Stranger` renders `see-plain Aardvark`.
- AC3 — PASS. Both halves off the same capture. Sort keys: `Hague` sits under
  letter group Z in `qi-index-main`, where a mark writes `sort="Zebra"`, and
  under H in `qi-index-authors`, where none does. Range pairing: the captured
  log carries exactly one never-closed report and exactly one never-opened
  report, both naming "Cantor", and each `Cantor` row in the section dump
  carries a single ordinary locator, so neither half printed a range.
- AC4 — PASS. Each section's `after` — the last author-written id before it — is
  `site-main` for `qi-index-main` and `site-authors` for `qi-index-authors`, so
  each index sits at its own marker. The captured log carries exactly one
  duplicate-marker report (count 1), and it names the repeated index, "main".
- AC5 — PASS, both halves. LaTeX: the captured `named-indexes.tex` carries 8
  `\index{}` commands against the manifest's 7 rows, exactly one `\printindex`,
  and no marker residue — the only `site-` occurrences are `\label{}`s on the
  fixture's own author-written subsection headings, and the one `quarto-index`
  occurrence is the extension's imakeidx preamble guard. Each named-index mark
  carries the argument the default index gives it, including `Zebra@Hague` for
  the second index's `Hague`, which writes no sort key of its own. The log
  carries the fold reports for the named-index marks and the named-index marker,
  each naming "authors". Book: the captured `book-html/_book/last.html` carries
  exactly one generated section under the bare `qi-index` id, headed "Index",
  listing `Turing` — the chapter's `index="people"` mark — among its 14 entries;
  the book log carries one fold report naming `"people"` on term "Turing" and
  one naming `"people"` on an index placement marker.
- AC6 — PASS. Read directly from `README.md`'s `### Named indexes` section: it
  shows the `indexes:` metadata form with `name`/`title` and says what each
  does; shows `index=` on a mark and on a placement marker with an example each;
  states that a mark or marker naming none takes the first declared index; and
  states under its own subheading that a LaTeX or PDF render and an HTML book
  each build one index for now. Both fixture paths it names exist, and this
  run's ledger carries both documented commands with exit status 0.
- AC7 — **FAIL.** `tests/run-tests.sh --self-test` exits 0 with 559 checks, and
  the eleven clauses round 2 left unplanted are now planted: `check_folded_site`
  4 of 4, `check_folded_second` 3 of 3, `check_readme_indexes` 10 of 10, and the
  two id sweeps complete. But `check_folded_heading`'s first clause — the
  section count its own comment names first, the one clause round 2 named — is
  still not shown red. Its plant inserts an empty `<section
  id="qi-index-extra">`, and `htmlindex.index_sections` raises `ValueError: the
  generated index section 'qi-index-extra' carries no heading element` before
  the `len(found) != 1` comparison is ever reached; `probe_defect` discards
  output and reads only the exit status, so the traceback is scored as the
  clause going red. Verified here by running the reader's own heredoc over a
  fabricated two-section page: it exits 1 on the `ValueError` and never prints
  the count finding. The criterion binds a planted defect for each clause shown
  red, and this clause is shown red by a different failure than the one it
  states.

### Consistency gate (round 3)

- `cairn_validate.py` exit 0 — every check PASS, every advisory OK except the
  sizing tripwire (24 tasks), which this milestone's work log already accepts as
  gate-directed repair rather than new scope. The `release window` advisory did
  not fire.
- Toolchain checks: the active `generic` profile names none, so this half is a
  clean no-op.
- `cairn_impact.py` not run: the diff changes no IP/GP principle line in
  `DESIGN.md`.

### Independent review (round 3)

Three fresh-context reviewers on distinct evidence bases, spawned at the user's
explicit direction (the session carries a standing directive against spawning
subagents unless asked; put to the user at this round and they chose the full
fan-out).

- [S] prior-review-record lens: no findings. It read the archived `## Review`
  records for the touched files, `LESSONS.md` and DESIGN's Known issues, and
  probed the GitHub inline-comment surface, which returned empty, so the per-PR
  walk was not paid for. It confirmed each round-2 fix present in code and each
  deferred follow-up untouched.
- [S] blame-history lens: no findings. It confirmed the `NAME_SHAPE` narrowing a
  genuine tightening, the two raise-to-report changes not weakening what they
  check, the corrected `last.qmd` prose matching a hand trace of `resolve_markers`
  and `fold_slot`, `warn-distinct.py`'s pinned 64 matching live code, the M23
  injectors re-anchored on `plan_range`'s new signature, and no D-entry or
  principle contradicted.
- [O] diff-bug lens: seventeen findings (G1-G17 below).

Findings, ranked as reported, each with its disposition. G1, G2, G3 and G5 were
re-verified in this session against the shipped readers and the captured
artifacts, never against the reviewer's account.

- G1: AC7 still fails — `check_folded_heading`'s section-count clause is not
  shown red; its plant fires an uncaught `ValueError` from `index_sections`
  instead. Confirmed by execution, as recorded under AC7 above.
- G2: `check_folded_heading` raises rather than reports — the same
  traceback-not-a-finding defect T19 and T21 repaired in its two sibling
  readers, and which round 2's triage scoped as fix-now. Confirmed by read:
  `tests/run-tests.sh:12195-12223` calls `htmlindex.index_sections` with no
  `try/except ValueError`, while `check_index_sections` and
  `check_html_index_links` both guard it. At its real call site a genuinely
  malformed book page would produce a traceback naming neither the page nor what
  was wanted.
- G3: three branch-added claims the artifact does not bear out — the self-test's
  closing `pass` line, the block comment above the plant, and the T18 work-log
  line each assert the folded-heading reader is shown red on two sections, which
  per G1 it is not. Confirmed by read and execution. The `pass` line separately
  attributes to the folded-site reader a plant for "none of the one index" that
  exists only for the second-marker reader; the folded-site reader's own count
  clause is planted by the two-`\printindex` plant, so the clause is covered and
  only the enumeration over-claims.
- G4: the return-gate Decisions entry still states a declared name may hold a
  `.`, which T20 made false.
- G5: README documents nothing about the shape a declared name may take, so the
  rule T20 tightened is undocumented — an author writing the perfectly ordinary
  `name: my.index` gets a refusal with no rule behind it. Confirmed by reading
  README's whole `### Named indexes` section, which says only that `name` is
  "what a mark writes to file in that index".
- G6: AC6's pinned-claim manifest still carries no row for README's `index=`-on-
  a-mark sentence. This is R14 / F12, deferred both rounds.
- G7: `latex.lua`'s `contested_keys` remains the one un-namespaced accumulator,
  now with DESIGN's new convention bullet stating the general rule without a
  pointer to the recorded exception. Restates R10 / F15.
- G8: `index=""` accepted in silence in a non-declaring document. Restates
  R8 / F2.
- G9: no `DECISIONS.md` entry for the fold policy or the two return-gate
  rulings. Restates F13 / B2.
- G10: `contested` sorts by `.path` alone across per-index namespaces. Restates
  B3, still speculative.
- G11: the Coverage map is stale — AC7 maps to T9 alone though T17-T21 are all
  AC7 work, T11-T16 and T22-T24 map to no criterion, and the Tasks comment still
  says "T1-T17 are done". `cairn_validate`'s coverage check passes, since every
  criterion still maps to an existing task.
- G12: AC7's box is `- [ ]` while the status is `review`. Correct under AC
  fencing — it failed round 2 and has not been re-verified.
- G13: DESIGN's T22 edit breaks the paragraph's wrap (85 and 99 chars in a
  paragraph otherwise near 76).
- G14: `indexes.lua` sits after `latex.lua` in DESIGN's dependency-order module
  list while the sentence added beside it says "`indexes.lua` first".
- G15: `ran_clean`'s one failure clause has no plant. A runner rather than a
  reader, but AC7's wording is over "each reader this milestone adds" and round
  2 read that wording strictly.
- G16: `tests/m29book.py`'s new `DUP_NAMED` alternative adds a matching clause
  with no plant of its own. m29book is modified, not added.
- G17: the two id sweeps are applied only to `named-indexes-misuse.qmd`, a
  narrower domain than the readers' own prose ("No id anywhere on a page").

### Triage and disposition (round 3)

AC7 fails, so M38 returns to `in-progress` under step 4's exit. This is defect
return 3 for the milestone; no amendment return, no criterion reinterpreted.

The thrash rule fires on both triggers. (a) The third return: a mis-planned
milestone, so no further retry is queued under the current plan and the
disposition goes to the maintainer. (b) AC7 failing twice, each by a new
mechanism of the same shape — round 2's clauses with no plant at all, round 3's
clause whose plant is scored red by a different failure than the one it states.
The plan gate recorded alternatives against four design choices (metadata
declaration, HTML-first, warn-and-fold in books, first-declared default); none
is an alternative to how AC7's per-clause proof is obtained, so (b)'s remedy is
an offered escalation rather than a recorded alternative to reconsider. No
re-plan or split has been spent on this milestone, so a same-objective re-cut
remains a present but never-recommended option.

- G1, G2, G3 → the AC7 gap and its two companions. Not carried this round: the
  disposition is the maintainer's under the thrash rule, and any repair rides
  whichever option they choose.
- G4 → reject. The milestone-local Decisions section is history (IP4), never
  edited; the T20 work-log line already supersedes the ruling.
- G5 → follow-up, or fix-now inside a descope that keeps AC6. A user-facing
  documentation gap this round's narrowing created.
- G6, G7, G8, G9, G10, G16, G17 → follow-up, already-filed or newly filed in the
  hygiene pass of whichever review merges this milestone.
- G11, G13, G14 → follow-up. Tracking and wrap hygiene, no runtime surface.
- G12 → reject. The unticked box is what AC fencing requires.
- G15 → follow-up, folded into whatever answers G1.

### Round 4 — 2026-08-25

Reviewed at 7601b16 on m038-named-indexes-html, PR #38 (draft, already open).
`git fetch` first: `main` has not moved since the branch was cut and carries no
unpushed local commits, so no merge was needed; the branch was pushed before
evidence was gathered. The criteria set is the narrowed AC1-AC6 — AC7 and the
per-clause reader proof it bound left the milestone at the T25 amendment gate —
and no AC1-AC6 wording changed at that gate, so each criterion below is the one
round 3 read. Fresh evidence: one full `tests/run-tests.sh --self-test` run,
exit 0, 559 checks, plus direct reads of this run's captured artifacts.

- AC1 — PASS. Read directly off the captured `named-indexes.html`: exactly two
  generated index sections in document order, `qi-index-main` headed by an `h1`
  reading "Index" and `qi-index-authors` headed by an `h1` reading "Index of
  Authors" — declared order, each id and heading as the fixture's manifest
  states. The suite's `M38-AC1` matched all 18 manifest rows in order; the link
  sweeps resolved 4 and 3 index links with every id unique, and the letter sweep
  read 8 letter-group headings in order. The single-index twin still reads as
  one section over 13 rows.
- AC2 — PASS. The captured HTML render log carries exactly one dangling-target
  report and it names `see=` on entry "Stranger" — the second index's mark —
  pointing at "Aardvark", a term only the first index carries; the first index's
  own `see=` on that same target draws no report at all. `M38-AC2` green over
  the same capture.
- AC3 — PASS, both halves off this run's capture. Range pairing: the log carries
  exactly one never-closed report and exactly one never-opened report, both
  naming "Cantor" — the opening in the first index and the closing in the second
  paired in neither — and `M38-AC3` asserts each of the two marks printed the
  ordinary locator its section manifest states. Sort keys: the same term files
  under the letter its own index selects, asserted by the AC1 manifest rows the
  same run matched.
- AC4 — PASS. Each section stands at its own marker: the AC1 section read gives
  `qi-index-main` and `qi-index-authors` each preceded by its own authored
  marker id, and `M38-AC4` asserts that pairing by id. The captured log carries
  exactly one duplicate-marker report and it names the repeated index, "main".
- AC5 — PASS, both halves. LaTeX: the captured `named-indexes.tex` carries 8
  `\index{}` commands (the manifest's 7 rows plus the folded second-index
  duplicate), exactly one `\printindex`, and no marker residue; the captured
  latex log carries four fold reports for named-index marks (Babbage, Hague,
  Stranger, Cantor) and one for the named-index marker, each naming "authors"
  and each saying the mark was indexed in the document's one index instead.
  `M38-AC5` green over that capture, and the same fixture still builds a PDF.
  Book: `M38-AC5`'s book half green — an HTML book folds its named mark and its
  named marker into the one index it builds, reports each once, and lists the
  folded mark's term there — with `M38-R3` reading that section under the bare
  `qi-index` id headed by the neutral "Index".
- AC6 — PASS. Read directly from `README.md`'s `### Named indexes` section: the
  `indexes:` metadata form with `name` and `title`; `index=` shown on a mark and
  on a placement marker; the rule that a mark or marker naming none takes the
  first declared index; the name-shape rule T26 added, stating the characters a
  name may hold and that any other name is reported; and, under its own
  subheading, that a LaTeX or PDF render and an HTML book each build one index
  for now. `M38-AC6` states all 7 pinned claims matched plus the declaration
  block line for line, both named fixture paths exist, and this run's
  `ran-commands.txt` ledger carries both documented commands, each with exit
  status 0.

### Consistency gate (round 4)

- `cairn_validate.py` exit 0 — every check PASS, including `coverage complete`
  and `binding criteria` over the narrowed AC1-AC6 set; every advisory OK except
  the sizing tripwire (27 tasks), which this milestone's work log already
  accepts as gate-directed repair rather than new scope. The `release window`
  advisory did not fire.
- Toolchain checks: the active `generic` profile's `consistency-gate` slot names
  none, so this half is a clean no-op.
- `cairn_impact.py` not run: `git diff main...HEAD -- cairn/DESIGN.md` changes no
  IP/GP principle line.
