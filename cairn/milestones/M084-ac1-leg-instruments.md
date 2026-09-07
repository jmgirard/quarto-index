<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M084: The id-census AC1 leg tells apart what it claims to

- **Status:** planned
- **Priority:** normal
- **Depends on:** M083
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — every deliverable is a check, a reader, a fixture case or a plant inside `tests/` and `examples/`, read by no consumer of this repo
- **Branch/PR:** —

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

- [ ] AC1: The M079-AC1 leg reads a contested cross-reference mark's minted
      anchor off that mark's own element rather than off a map keyed by span
      text: a self-test leg feeds the read a hand-written page carrying two
      minted anchors on spans printing one string, requires the repaired read
      to name both marks and the text-keyed read it replaces to lose one, and
      the leg over the rendered fixture stays green.
- [ ] AC2: `tests/htmlindex.py` ends a `<![CDATA[…]]>` written in HTML content
      at its first `>`, as the id census does: the M080-AC2 reader leg gains a
      hand-written case whose `id=` stands between that `>` and the `]]>`, and
      that leg exits non-zero when the repair is reverted.
- [ ] AC3: `examples/id-collision.qmd` writes an `id=` between a CDATA
      construct's first `>` and its `]]>`, its rows land in the M079-AC1
      expectation dicts, and a plant that makes the census end the construct at
      `]]>` makes the leg exit non-zero naming that id.
- [ ] AC4: The M075 plant helper is shown to depend on both repairs it carries:
      over a source in which `# ---` appears inside a comment it drops the block
      the scan's own banner rule names while a copy carrying the pre-repair rule
      drops a different one, and over a source whose first banner block inside
      the wrapper's body is never closed it exits with its own message while a
      copy scanning past that bound does not.
- [ ] AC5: `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T5, T6
- AC4 → T7
- AC5 → T1, T2, T3, T4, T5, T6, T7, T8

## Tasks

- [ ] T1: Factor the AC1 leg's minted-anchor read (`tests/run-tests.sh:4286-4300`)
      into a named function over a parsed page, keyed on each mark's own element
      rather than on `H.text(el).strip()`.
- [ ] T2: Add the hand-written two-anchor page and its leg, keeping the
      text-keyed read beside the repaired one as the case that must fail — the
      M080-AC2 shape, where the reader under test gets its input in markup by
      hand rather than off a render.
- [ ] T3: Repair `tests/htmlindex.py`'s reading of `<![CDATA[…]]>` in HTML
      content to end at the first `>` (`tests/htmlindex.py:90-215`), and run the
      reader's own probes under the local 3.9 and under a 3.12 before trusting
      either green — M082's lesson, where a 3.9-shaped override raised on CI.
- [ ] T4: Extend the M080-AC2 reader leg (`tests/run-tests.sh:3944-3986`) with
      the hand-written CDATA case and a plant that reverts T3's repair.
- [ ] T5: Write the discriminating CDATA case into `examples/id-collision.qmd:333`
      and its rows into the AC1 expectation dicts (`tests/run-tests.sh:4133-4143`),
      carrying the leg's own hand-derived counts and prose with them.
- [ ] T6: Plant the `]]>` reading through `m081_census_plant`
      (`tests/run-tests.sh:4423`) and hold the leg red on it, its report naming
      the planted id.
- [ ] T7: Put the M075 plant helper (`tests/run-tests.sh:27013-27085`) under its
      own plants: a source with `# ---` inside a comment, and one whose first
      banner block in the wrapper's body is unclosed, each run against the
      helper as it stands and against a copy carrying the pre-repair form.
- [ ] T8: Re-read `cairn/DESIGN.md`'s foreign-content CDATA entry against the
      fixture case T5 adds — the new case pins the HTML-content reading and
      leaves the foreign-content one where it was — and correct it where the
      addition has made its text false.

## Work log

- 2026-09-07: created by /milestone-plan.
- 2026-09-07: plan gate chose leaving the "bind M079's cross-reference id shapes to criteria" row standing over absorbing it here, though its own trigger — any pass over the id-collision fixture — fires with T5; falsified by a later pass over that fixture finding the unbound shapes already deleted.
- 2026-09-07: plan chose a hand-written page for AC1's discrimination over a second fixture mark, because two minted anchors on spans printing one string need a printed text that differs from the mark's own term, which the fixture cannot carry without a second `entry=` shape the leg does not read; falsified by a fixture mark reaching that state without one.
- 2026-09-07: reduced criteria audit ([O], fresh context) ran over this milestone's five criteria and returned no finding against them.

## Decisions

## Review
