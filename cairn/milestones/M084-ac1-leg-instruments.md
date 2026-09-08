<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M084: The id-census AC1 leg tells apart what it claims to

- **Status:** review
- **Priority:** normal
- **Depends on:** M083
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — every deliverable is a check, a reader, a fixture case or a plant inside `tests/` and `examples/`, read by no consumer of this repo
- **Branch/PR:** `m084-ac1-leg-instruments` — https://github.com/jmgirard/quarto-index/pull/84

## Goal

Every check, reader and plant this milestone names is shown red on the defect
class it claims to catch.

## Scope

**In:** the M079-AC1 leg's read of where a contested cross-reference mark's
minted anchor landed, keyed on the mark rather than on its text; the suite
reader's reading of a `<![CDATA[…]]>` in HTML content; the fixture case that
tells the census's two candidate readings of that construct apart; the M075
plant helper's two repairs, each put under a plant of its own.

**Out:** the EPUB `unique` sweep → M083. Binding M079's cross-reference id
shapes to criteria → its standing candidate row, left there at the plan gate.
The foreign-content CDATA divergence, where a browser ends the construct at
`]]>` → its own Known issues entry, unchanged here.

## Acceptance criteria

- [x] AC1: The M079-AC1 leg reads a contested cross-reference mark's minted
      anchor off that mark's own element rather than off a map keyed by span
      text: a self-test leg feeds the read a hand-written page carrying two
      minted anchors on spans printing one string, requires the repaired read
      to name both marks and the text-keyed read it replaces to lose one, and
      the leg over the rendered fixture stays green.
- [x] AC2: `tests/htmlindex.py` ends a `<![CDATA[…]]>` written in HTML content
      at its first `>`, as the id census does: the M080-AC2 reader leg gains a
      hand-written case whose `id=` stands between that `>` and the `]]>`, and
      that leg exits non-zero when the repair is reverted.
- [x] AC3: `examples/id-collision.qmd` writes an `id=` between a CDATA
      construct's first `>` and its `]]>`, its rows land in the M079-AC1
      expectation dicts, and a plant that makes the census end the construct at
      `]]>` makes the leg exit non-zero naming that id.
- [x] AC4: The M075 plant helper is shown to depend on both repairs it carries:
      over a source in which `# ---` appears inside a comment it drops the block
      the scan's own banner rule names while a copy carrying the pre-repair rule
      drops a different one, and over a source whose first banner block inside
      the wrapper's body is never closed it exits with its own message while a
      copy scanning past that bound does not.
- [x] AC5: `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T5, T6
- AC4 → T7
- AC5 → T1, T2, T3, T4, T5, T6, T7, T8

## Tasks

- [x] T1: Factor the AC1 leg's minted-anchor read (`tests/run-tests.sh:4286-4300`)
      into a named function over a parsed page, keyed on each mark's own element
      rather than on `H.text(el).strip()`.
- [x] T2: Add the hand-written two-anchor page and its leg, keeping the
      text-keyed read beside the repaired one as the case that must fail — the
      M080-AC2 shape, where the reader under test gets its input in markup by
      hand rather than off a render.
- [x] T3: Repair `tests/htmlindex.py`'s reading of `<![CDATA[…]]>` in HTML
      content to end at the first `>` (`tests/htmlindex.py:90-215`), and run the
      reader's own probes under the local 3.9 and under a 3.12 before trusting
      either green — M082's lesson, where a 3.9-shaped override raised on CI.
- [x] T4: Extend the M080-AC2 reader leg (`tests/run-tests.sh:3944-3986`) with
      the hand-written CDATA case and a plant that reverts T3's repair.
- [x] T5: Write the discriminating CDATA case into `examples/id-collision.qmd:333`
      and its rows into the AC1 expectation dicts (`tests/run-tests.sh:4133-4143`),
      carrying the leg's own hand-derived counts and prose with them.
- [x] T6: Plant the `]]>` reading through `m081_census_plant`
      (`tests/run-tests.sh:4423`) and hold the leg red on it, its report naming
      the planted id.
- [x] T7: Put the M075 plant helper (`tests/run-tests.sh:27013-27085`) under its
      own plants: a source with `# ---` inside a comment, and one whose first
      banner block in the wrapper's body is unclosed, each run against the
      helper as it stands and against a copy carrying the pre-repair form.
- [x] T8: Re-read `cairn/DESIGN.md`'s foreign-content CDATA entry against the
      fixture case T5 adds — the new case pins the HTML-content reading and
      leaves the foreign-content one where it was — and correct it where the
      addition has made its text false.

## Work log

- 2026-09-07: created by /milestone-plan.
- 2026-09-07: plan gate chose leaving the "bind M079's cross-reference id shapes to criteria" row standing over absorbing it here, though its own trigger — any pass over the id-collision fixture — fires with T5; falsified by a later pass over that fixture finding the unbound shapes already deleted.
- 2026-09-07: plan chose a hand-written page for AC1's discrimination over a second fixture mark, because two minted anchors on spans printing one string need a printed text that differs from the mark's own term, which the fixture cannot carry without a second `entry=` shape the leg does not read; falsified by a fixture mark reaching that state without one.
- 2026-09-07: reduced criteria audit ([O], fresh context) ran over this milestone's five criteria and returned no finding against them.
- 2026-09-07: gate chose purpose-written sources for T7's plants over the suite's own source, a plant file written to the run's work directory over a tracked `tests/` file, and an exactly-one minted-anchor assertion in the AC1 leg over today's at-least-one.
- 2026-09-07: T1: `H.minted_anchors` returns one (printed text, id) pair per element carrying a minted id; the AC1 leg groups those by printed text and requires exactly one anchor per cross-reference term.
- 2026-09-07: T2: a `--self-test` leg runs both reads over two hand-written pages; over two minted anchors on spans printing one string the repaired read names both and the replaced text-keyed read names one, and over a page printing a different string on each mark the two agree. Shown red by a planted first-wins `minted_anchors`. T1 and T2 were checked off against one clean `tests/run-tests.sh --self-test` run (1435 checks, exit 0).

- 2026-09-07: T3: `_Builder.parse_html_declaration` ends a `<![CDATA[` at the first `>` after the `<!`, the reading the census takes; the reader's probes run clean under 3.9.6 and under 3.14.7. The plan asked for a 3.12 second interpreter — this machine has 3.9.6 and 3.14.7 only, and 3.14.7 covers the `escapable=` signature change that lesson is about.
- 2026-09-07: T4: the M080-AC2 reader leg gains a CDATA case whose `id=` stands between the construct's first `>` and its `]]>`; the leg is red naming that id under both interpreters when the override is removed, and the stock marked-section reading is shown to lose that id and no other.

- 2026-09-07: T5: `examples/id-collision.qmd` writes `mid-cdata`/`between-cdata`, an `id=` standing between a CDATA construct's first `>` and its `]]>`; the census contests it and the mark yields to `qi-mark-34`. Row added to CONTESTED_COMMENT, the leg's hand-derived count raised from sixty-six to sixty-seven.
- 2026-09-07: T6: the `cdata-to-marked-close` census plant runs a `<![CDATA[` to its `]]>`; the AC1 leg is red on `ids carried by more than one element: between-cdata`.
- 2026-09-07: T5 minor amendment (discovered sub-task): the new mark shifted the minted-anchor numbering, so M083's three EPUB plants stopped matching the `ch018.xhtml#qi-mark-39` they named. The locator is now derived from the member — the first relative index locator whose whole `href="…"` it carries exactly once — and a member carrying none fails loudly.
- 2026-09-07: T7: the M075 plant's python is written to the run's work directory and takes a source and destination; two purpose-written sources and two pre-repair copies (one substitution each, against the plant's own bytes) show it depends on both of its M077 repairs.
- 2026-09-07: T8: KI263 re-read against T5's case. Nothing in it was made false; extended to name `tests/htmlindex.py` as a second artifact carrying the same reading and to say the HTML half is now fenced while the foreign-content half is exercised on neither side.
- 2026-09-08: review opened draft PR #84 and started the AC evidence run; suite self-test and the three fresh-context review lenses in flight.
- 2026-09-08: review recorded fresh evidence for AC1-AC5 from one `--self-test` run (1438 checks, exit 0), ticked the five criteria, and ran the consistency gate clean; three review lenses returned seven findings, all from the diff-bug lens.

## Decisions

## Review

Evidence from one `tests/run-tests.sh --self-test` run at 71300dc on 2026-09-08:
1438 checks, exit 0. The branch carries origin/main; no merge was needed.

**AC1** — the M079-AC1 leg reads `H.minted_anchors(doc, prefix)` and groups the
pairs it returns by the printed string (`tests/run-tests.sh:4363-4365`), one pair
per element. The T2 self-test leg feeds both reads two hand-written pages: over
two minted anchors on spans printing one string the repaired read names both
(`qi-mark-a` and `qi-mark-b`) and the read it replaces names one; over a page
printing a different string on each mark the two agree on both terms. The leg
over the rendered fixture is green in the same run.

**AC2** — the M080-AC2 reader leg carries the hand-written CDATA case and, beside
it, a `_Unrepaired` builder holding the stdlib `parse_html_declaration`. The leg
reports the repaired reader keeping 3 ids on the page there where the stock
marked-section reading keeps 2, and errors if the stock reading were to keep
`between-cdata` — the reverted-repair case AC2 asks for.

**AC3** — `examples/id-collision.qmd:367-377` writes `[mid-cdata]{#between-cdata}`
and a raw block whose `id="between-cdata"` stands between the construct's first
`>` and its `]]>`; the rows are in `CONTESTED_COMMENT` and the leg's hand-derived
mark count is 67 (22 M079, 20 M080, 12 M081, 12 M082, 1 M084). The
`cdata-to-marked-close` census plant makes the leg red on `ids carried by more
than one element: between-cdata`.

**AC4** — over the short-rule source the plant drops Alpha, the first block the
scan's own rule names, leaving Beta; the copy carrying the dash-only rule drops
three lines the scan reads as no block, leaves the declared domain unchanged, and
demonstrably changed the file. Over the unclosed source the plant exits non-zero
with `is never closed by a second rule`; the copy scanning past the wrapper's
body exits 0 and deletes the wrapper's own close, leaving a source the scan finds
no wrapper in.

**AC5** — `tests/run-tests.sh --self-test`: 1438 checks, exit 0.

**Consistency gate** — `cairn_validate.py` exit 0, all checks passed, no advisory
fired. `Principles touched:` is `—` and the DESIGN.md edit is a Known issues
entry, so `cairn_impact.py` did not apply. The `generic` profile's
`consistency-gate` slot names no toolchain checks.

**Independent review** — the diff touches executable surface, so all three
lenses ran fresh-context. [S] blame-history: no findings. [S] prior-review: no
findings (no inline PR review comments exist on this repo; the archived review
sections' still-open code findings are all in `html.lua`, untouched here).
[O] diff-bug: seven findings, listed with their dispositions below.
