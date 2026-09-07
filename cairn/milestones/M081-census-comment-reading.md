# M081: The id census reads a comment where a browser reads one

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the census decides which id an author's mark keeps on the rendered page, and two author-facing pages state the rule.
- **Branch/PR:** m081-census-comment-reading · https://github.com/jmgirard/quarto-index/pull/81

## Goal

Two comment shapes the id census reads wrongly are read the way a browser
reads them in ordinary HTML: a construct a browser makes a comment and this
walk reads as markup (`<!ok>`, `<?ok>`, `<![CDATA[…]]>`, `</ ok>`), and the
three ways a browser ends a comment that this walk does not (`<!-->`,
`<!--->`, a `--!>` close). What a browser does with either inside `svg` or
`math` is outside this, nothing here being checked against a browser.

## Scope

**In:** the comment-open and comment-close reading in `note_raw`
(`_extensions/index/modules/html.lua:545-653`); new cases in
`examples/id-collision.qmd` and their rows in the M079-AC1 expectation dicts
(`tests/run-tests.sh:4043-4103`); the first `--self-test` plants over the
census; the comment paragraphs of `site/html.qmd` and `CHANGELOG.md`, the
M079-AC5 claim rows that pin the retired reading, and the forbidden-phrase
list; striking KI257 and KI260 from `DESIGN.md`.

**Out:** a `template` element's content, a `script` element's double-escape
state, and the missing case for an `id=` on a raw-text element's own opening
tag → M082. A `style` or `script` inside `svg` or `math` → stays KI261 on its
candidate row; confirming it needs a browser this repo does not run. A
text-content element outside the seven (KI254) and an id Quarto's writer makes
after the filter runs (KI255) → their existing candidate rows.

## Acceptance criteria

- [x] AC1: In the HTML render of `examples/id-collision.qmd`, for each of the
      four bogus-comment spellings the fixture writes — `<!ok>`, `<?ok>`,
      `<![CDATA[…]]>`, `</ ok>` — the mark written with the name today's walk
      claims from a quoted `id=` inside that construct keeps that name on its
      own span, and the render log carries no refusal report naming that
      mark's term.
- [x] AC2: In that same render, for each of those four spellings, the mark
      written with the name the fixture puts on a rendered element standing
      after that construct's first `>`, in that same raw block, is anchored on
      a minted `qi-mark-` id and its refusal report is in the render log.
- [x] AC3: In that same render, for each of the three comment-end spellings the
      fixture writes — `<!-->`, `<!--->`, and a `--!>` close — the mark written
      with the name the fixture puts on a rendered element standing after that
      comment, in that same raw block, is anchored on a minted `qi-mark-` id
      and its refusal report is in the render log; and the mark written with
      the name the fixture writes inside a `--!>`-closed comment keeps that
      name on its own span, with no refusal report naming its term.
- [x] AC4: `site/html.qmd` and `CHANGELOG.md` each state that the census reads
      both comment shapes the way a browser reads them in ordinary HTML, and
      the sentence each carries today naming a comment not spelled `<!--` as
      one the reading gets wrong is gone from both.
- [x] AC5: `tests/run-tests.sh` passes, and passes with `--self-test`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T5
- AC5 → T4, T5

## Tasks

- [x] T1: Write the fixture cases into `examples/id-collision.qmd` — for each
      of the four bogus-comment spellings, a quoted `id=` inside the construct
      and a second name on a rendered element after its first `>`, both in one
      raw block; for each of the three comment-end spellings, a name on a
      rendered element after the comment in one raw block; and one name inside
      a `--!>`-closed comment. Each gets its mark. Add their rows to the
      M079-AC1 expectation dicts and rewrite the derivation comment's
      arithmetic whole rather than patching one count (the M080 lesson). Run
      the leg first and record which new rows are red before any repair.
- [x] T2: Repair the comment-open reading in `note_raw`: a `<` beginning `<!`
      other than `<!--`, a `<?`, or a `</` followed by a non-letter ends at the
      next `>`, and the walk resumes after it.
- [x] T3: Repair the comment-close reading: a comment opened by `<!--` also
      ends at an immediate `>`, at an immediate `->`, and at a `--!>`.
- [x] T4: Add one `--self-test` plant per repair — one substitution each into
      `note_raw`, re-rendering the fixture and requiring the M079-AC1 leg red
      with a named string. These are the repo's first plants over the census;
      one per repair, not one for the census (M32's granularity rule).
- [x] T5: Rewrite the comment paragraphs of `site/html.qmd` and `CHANGELOG.md`,
      replace the M079-AC5 claim rows that pin the retired reading
      (`tests/run-tests.sh:4380-4385`), extend the forbidden-phrase list with
      each retired `site/html.qmd` sentence and plant it. `phrase-absent`
      sweeps `site/*.qmd` and `README.md` only, so `CHANGELOG.md` is held by
      its claim row, not by that list.
- [x] T6: Strike KI257 and KI260 from `DESIGN.md`, rewrite the census paragraph
      there (`cairn/DESIGN.md:379-390`), and rewrite the two candidate rows
      pointing at them.

## Work log

- 2026-09-06: created by /milestone-plan.
- 2026-09-06: plan gate chose repairing the walk's own comment reading over widening the skip list or pattern-matching the raw string, because the walk already models a browser shape by shape and the alternatives reintroduce the over-collection M080 removed; falsified by a comment shape whose correct reading needs document-wide state the walk cannot carry across raw strings.
- 2026-09-06: plan gate chose two milestones over one covering all four shapes, because the four repairs are independently shippable and one file risked the 150-line cap; falsified by the two branches proving to need the same `note_raw` rewrite.
- 2026-09-06: criteria audit ran in full mode, twice. First pass: six findings — the goal claimed four shapes where six stand and opened with an unreachable universal; three criteria tested only that a hidden name stops being counted, so an implementation abandoning the rest of the raw string passed all three. All fixed pre-gate. Second pass over the split wording: the goal needed bounding to non-foreign content, AC3 needed the inside-a-`--!>`-comment mark, and AC4's negative half named a domain no procedure enumerates and reached `CHANGELOG.md`, which `phrase-absent` does not sweep. All fixed.
- 2026-09-06: T1 — twelve fixture marks written into `examples/id-collision.qmd` (four `bogus-*` inside a bogus-comment construct, four `beyond-*` after one, three `beyond-*-comment` after a comment-end spelling, one `hidden-bang-close` inside a `--!>`-closed comment) and their rows added to the M079-AC1 dicts as `CONTESTED_COMMENT`/`KEPT_COMMENT`; the derivation comment's arithmetic rewritten whole to fifty-four. Leg run before any repair: red on the four `bogus-*` names counted and their marks yielded, and on the three `beyond-*-comment` names uncounted and left on two elements; the four `beyond-*` bogus-comment names and `hidden-bang-close` already passed.
- 2026-09-06: T1 — the M079-AC1 check moved from a stdin heredoc into `$WORK/id-collision-ids.py`, run from there, so T4's plants can redden that same check rather than a stand-in (question gate).
- 2026-09-06: T2, T3 — `note_raw` now reads a `<!` opening anything but `<!--`, a `<?`, and a `</` before a non-letter as comments running to the next `>`, and ends a `<!--` at an immediate `>`, an immediate `->`, a `-->` or a `--!>`. Checked shape by shape in a `pandoc lua` harness over `note_raw` before the fixture render: all seven new shapes and the `<!-- … -->` control read as a browser reads them.
- 2026-09-06: T4 — two `--self-test` plants over the census, one per repair (bogus-comment opening read as markup; comment ended at `-->` only), each rendering the fixture from a mutated copy of the extension and requiring the same M079-AC1 check red with its own named string, behind a green control on an unmutated copy. Both verified red by hand against a scratch render before being written in.
- 2026-09-06: T5, T6 — comment prose rewritten in `site/html.qmd` and folded into the unreleased `CHANGELOG.md` entry (question gate chose editing that entry over adding a fourth); the retired M079-AC5 claim row replaced by three pinning the new reading; a new M081-AC4 `phrase-absent` sweep with its own list and plant, given its own list rather than a row under the back-end-count list whose FAIL message names that count by hand (minor deviation from T5's wording); KI257 and KI260 struck from `DESIGN.md`, the census paragraph rewritten, KI262's `phrase-absent` clause corrected, and the M079-instruments candidate row narrowed — no candidate row cited KI257 or KI260, so none needed rewriting.
- 2026-09-06: checkpoint with every task box still unticked: the full `tests/run-tests.sh --self-test` run that has to be clean before any of them is ticked was still in flight when this commit was made.
- 2026-09-06: the M24-AC3 pairing check found the two plant renders and the control render uncaptured; each now calls `capture` on the line after its render and the check reads the captured copy. Two suite runs launched back to back both died on a Quarto/Deno segmentation fault in an unrelated LaTeX render; run one at a time both went green, so the crash was the environment and not this branch.
- 2026-09-06: T1-T6 all done, boxes ticked. `tests/run-tests.sh` 774 checks exit 0; `--self-test` 1420 checks exit 0 (773 and 1413 on the default branch). Status set to review.

- 2026-09-06: review — PR #81 opened as a draft; branch level with the default branch, no merge needed. AC1-AC4 verified against a fresh scratch render of the fixture and direct `sitecheck.py` runs, evidence recorded and those four boxes ticked. `cairn_validate` sixteen PASS, no advisory fired; the `generic` profile names no toolchain checks. AC5's two suite runs and the three review lenses were still in flight when this checkpoint was made.

- 2026-09-06: review — plain suite run green, 774 checks, exit 0; the `--self-test` run was still in flight at this checkpoint, so AC5 stays unticked. All three review lenses reported: the prior-review lens none, the blame lens one note, the diff-bug lens seven findings. All eight are recorded in the Review section with no disposition yet — they go to the maintainer at the merge gate.

- 2026-09-06: review — AC5 verified and ticked: 774 checks plain, 1420 with `--self-test`, both exit 0, the two new census plants and the M081-AC4 overlay plant green in the second. Consistency gate clean. Pre-gate checkpoint; the eight findings go to the maintainer at the merge gate undisposed.

- 2026-09-06: review gate — the maintainer chose fix-then-merge. F1, F2, F5, F6 fixed on the branch (a `claims` sweep over `CHANGELOG.md`, the numbering enumeration widened, the doctype no longer called a comment, the hides-a-name-inside over-claim replaced by what the walk does), F7 and F8 with them; F3 recorded as KI263 and F4 absorbed into the standing M079-instruments candidate row. This supersedes the T5 work-log line's claim that `CHANGELOG.md` is held by its claim row: no such row existed until this commit.

## Decisions

## Review

PR #81 (draft). Branch level with the default branch at review start — `git
rev-list --count origin/main ^HEAD` was 0 — so no merge and no re-run.

**AC1 — a name inside a bogus-comment construct stays on its mark, unreported.**
Fresh render of `examples/id-collision.qmd` into a scratch copy of the
extension, checked with a criterion-specific script over the page and the
render log. All four spellings pass: `bogus-bang` (`<!ok>`), `bogus-question`
(`<?ok>`), `bogus-cdata` (`<![CDATA[…]]>`) and `bogus-slash` (`</ ok>`) are each
on exactly one element, that element is the mark's own span printing the term,
each locator is the author's own `#`-id, and no refusal report names any of the
four terms.

**AC2 — a name on a rendered element after the construct's first `>` contests.**
Same render. All four pass: `beyond-bang`, `beyond-question`, `beyond-cdata` and
`beyond-slash` are each on one element that is not the mark; each mark is
anchored on a minted id (`qi-mark-27` … `qi-mark-30`), the locator naming that
minted anchor and the anchor sitting on the span printing the term; each has
exactly one refusal report in the render log naming both the term and the id
given up.

**AC3 — the three comment ends, and the name inside a `--!>`-closed comment.**
Same render. All three contested halves pass: `beyond-empty-comment` (`<!-->`),
`beyond-dash-comment` (`<!--->`) and `beyond-bang-close` (a `--!>` close) are
each on one element that is not the mark, each mark anchored on a minted id
(`qi-mark-31` … `qi-mark-33`) named by its locator, each with one refusal report
naming term and id. The kept half passes too: `hidden-bang-close` is on one
element, the mark's own span, its locator is `#hidden-bang-close`, and no
refusal report names `in-bang-close`.

**AC4 — the prose.** `tests/sitecheck.py claims site/html.qmd` run over the
three new comment claims: all three stated. `tests/sitecheck.py phrase-absent`
over the retired sentence: absent from all 22 swept pages. `CHANGELOG.md` read
directly with whitespace flattened: the three new statements present, the
retired sentence gone.

**AC5 — the suite.** `tests/run-tests.sh` run to completion: "All checks passed
(774 checks)", exit 0. `tests/run-tests.sh --self-test` run to completion: "All
checks passed (1420 checks)", exit 0. The two new census plants are green in
that run — the unmutated control leaves the M079-AC1 check green; the
bogus-comment-as-markup plant reddens it on `the author-written id
'bogus-bang' is on 0 element(s), want 1`; the close-at-`-->`-only plant reddens
it on `the author-written id 'beyond-empty-comment' is on 2 element(s), want
1` — as is the new M081-AC4 overlay plant. Run sequentially, one at a time, per
the profile.

**Consistency gate.** `cairn_validate.py`: sixteen PASS, seven advisories OK,
exit 0 — the `release window` advisory did not fire. No `DESIGN.md` principle
changed, so no `cairn_impact` run. The `generic` profile's `consistency-gate`
slot names no toolchain checks, so that half is a clean no-op.

**PR-conversation read (PR #81).** No reviews, no conversation comments, no
unresolved review threads — an empty read, so nothing to triage from that
surface and no blocking review.

### Review findings (three fresh-context lenses)

Full three-lens fan-out, the milestone's surface tier being user-facing. The
[S] prior-review lens reported no findings: the GitHub inline-comment probe
returned empty, and the diff is consistent with the M079 and M080 archived
review records. The [S] blame-history lens reported no defects and one note
(F8 below). The [O] diff-bug lens exercised `note_raw` in its own `pandoc lua`
harness over 24 shapes, replayed both plant substitutions, and reported seven.

Ranked as the lenses ranked them, most severe first:

- **F1 — `CHANGELOG.md`'s half of AC4 is guarded by nothing, and a work-log
  line says otherwise.** `phrase-absent` sweeps `git ls-files 'site/*.qmd'`
  plus `README.md`; `sitecheck.py claims` is never invoked on `CHANGELOG.md`.
  The T5 work-log line's "`CHANGELOG.md` is held by its claim row" names a row
  that does not exist. Restoring the retired sentence to `CHANGELOG.md`, or
  deleting its new comment paragraph, leaves both suite runs green. Verified:
  `grep -n CHANGELOG tests/run-tests.sh` returns one unrelated comment.
- **F2 — the numbering paragraph still enumerates only `<!--`.**
  `site/html.qmd:114` and the `numbering may mint an unrendered one` claim row
  say the mintable unrendered names are those "inside a comment spelled
  `<!--`, on a closing tag, or in the text content of one of the seven
  elements above". `number_entries` mints from the same `taken` table the
  census fills, so that set now also includes names inside `<!ok …>`,
  `<?ok …>`, `<![CDATA[…]]>` and `</ ok …>`. The claim row keeps the stale
  enumeration green.
- **F3 — `DESIGN.md` asserts a closed list of misread shapes that omits CDATA
  in foreign content.** In `svg` or `math` a browser ends `<![CDATA[…]]>` at
  `]]>`; the new branch ends it at the first `>`. Not a regression — the old
  walk counted it too — but the shortened list "KI256, KI258 and KI261"
  records it nowhere.
- **F4 — the CDATA fixture case cannot discriminate the reading it pins.**
  `tests/htmlindex.py` builds on Python's `html.parser`, which consumes
  `<![CDATA[…]]>` whole to `]]>`; the fixture writes no `id=` between the
  first `>` and `]]>`, so the leg passes whether `note_raw` stops at the first
  `>` or at `]]>`. Raised independently by the blame lens.
- **F5 — `<!DOCTYPE …>` is not a comment, and three places now say it is.**
  `site/html.qmd`, `CHANGELOG.md` and the `comment openings` claim row all say
  a `<!` opening anything else begins a comment. The census behavior is
  identical either way, so this is prose accuracy — now pinned by a claim row.
- **F6 — "hide a name inside them" over-claims.** `<![CDATA[a > <p id="x">]]>`
  ends the bogus comment at the `>` after `a`, so `x` is counted and is not
  hidden. `CHANGELOG.md` and `site/html.qmd` ("a name written inside one is on
  nothing") both carry the over-claim.
- **F7 — reflow artifacts.** `cairn/DESIGN.md:395` at 100 columns with an
  orphaned "(added" line before it, `tests/run-tests.sh:4485` at 105 columns
  inside a block wrapped at ~76, and a short ragged line in `CHANGELOG.md`,
  all in prose otherwise wrapped near 76.
- **F8 — [S] blame lens: an imprecise citation.** The T4 comment cites "M32's
  granularity rule"; the M32 archive uses no such phrase, though its review
  notes do prefer clause-level plants to one plant per feature.

The [O] lens also recorded two non-findings: the `close-at-arrow-only` plant's
pattern depends on the first eight-space `end` after `local data = lt + 4`, but
its own guards turn a mis-splice into a loud failure; and no dangling KI257 or
KI260 reference remains outside the M080 archive and a dated hygiene stamp.

### Triage (maintainer, at the gate)

The maintainer chose to fix the four prose defects on the branch before
merging, the two CDATA gaps becoming records. F7 and F8 were cosmetic
one-liners in files already being edited and went into the same pass.

- **F1 — fixed now.** A new `M081-AC4 — the changelog states the comment
  reading too` section runs `sitecheck.py claims` over `CHANGELOG.md` with
  five rows quoting its own comment sentences. Its `fail` message is written
  without backticks, which a double-quoted shell string would run as a
  command (KI252). The T5 work-log line is superseded by a work-log line here,
  history being append-only.
- **F2 — fixed now.** `site/html.qmd`'s numbering paragraph and its
  `numbering may mint an unrendered one` claim row now say "inside a comment
  of any of the spellings above" rather than naming `<!--` alone; the earlier
  sentence at the top of that section is generalized the same way.
- **F5 — fixed now.** `site/html.qmd`, `CHANGELOG.md` and the `comment
  openings` claim row now say those openings "run to the next `>` and put no
  element on the page — a comment to a browser, or in the `<!` case a
  doctype", rather than calling a doctype a comment.
- **F6 — fixed now.** The over-claim is gone from both pages, replaced by
  what the code does: the construct ends at its first `>` and no further,
  with `<![CDATA[a > <p id="mine">]]>` given as the case where `mine` is
  counted. A new claim row pins that sentence on `site/html.qmd`.
- **F3 — follow-up, recorded.** `DESIGN.md` gains KI263 for the foreign-content
  CDATA divergence, and the census paragraph's list of misread shapes reopens
  to name it.
- **F4 — follow-up, recorded.** Absorbed into the standing "Harden M079's
  id-uniqueness instruments" candidate row rather than adding a row
  (search-first).
- **F7 — fixed now.** The three reflow artifacts rewrapped.
- **F8 — fixed now.** The T4 comment now cites M32's review by what it said
  rather than by a phrase M32 never used.
