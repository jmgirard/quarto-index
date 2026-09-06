# M080: The id census reads a page's raw HTML the way a browser does

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2, GP6
- **Resolves:** —
- **Surface tier:** user-facing — the deliverable is which id an author's mark keeps on their rendered page, and whether a link they wrote to it still lands
- **Branch/PR:** `m080-id-census-raw-html-walk`

## Goal

No `id=` an element of the rendered page actually carries goes uncounted by the
id census, and no `id=` written where the page renders no element is counted
against a mark.

## Scope

**In:** `note_raw` inside `taken_identifiers` (`_extensions/index/modules/html.lua:520-608`),
which today walks a raw HTML string wrongly in four shapes: a closing tag is
re-read as an opening one, so a `script` or `style` element aborts the walk and
every later `id=` goes uncounted; only `script` and `style` have their content
treated as text, so an `id=` inside `xmp`, `iframe`, `noembed`, `noframes` or
`textarea` is counted though the page carries no such element; a closing tag's
attributes are read, so `</p id="x">` counts `x`; and the skip's end-tag search
matches by prefix, so `</scriptx>` ends a script early. The census gains one
declared **skip list** — `script`, `style`, `xmp`, `iframe`, `noembed`,
`noframes`, `textarea` — whose content it steps over. `tests/htmlindex.py`
learns the same seven, its parser today treating only `script` and `style` as
character data. `examples/id-collision.qmd` and the M079-AC1 leg's hand-derived
tables grow the cases; `site/html.qmd` and `CHANGELOG.md` restate the rule.

**Out:** an id Quarto's own writer generates after the filter runs — `fn1`,
`cb1`, `title-block-header` — which needs a reading of the written page rather
than of the AST → KI255 and its candidate row, untouched. `title`, `noscript`
and `plaintext`, which no case can exercise on a rendered page → the narrowed
KI254 entry T10 writes, and the census candidate row. An untagged mark keeping
a contested id → KI253, untouched. Proving the AC1 sweep and the EPUB `unique`
sweep can go red → the suite's self-test-plants candidate row.

## Acceptance criteria

- [ ] AC1: For each of the seven elements of the skip list,
      `examples/id-collision.qmd` writes that element closed and, after it in
      the same raw HTML block, an `id=` attribute of an ordinary tag, plus a
      mark carrying that name. On the rendered page each of the seven names is
      carried by exactly one element, the author's; the yielding mark's anchor
      is a minted id — on its own span, or, for the one case whose mark is
      written inside a heading, on the empty span emitted after that heading —
      and the render log carries one refusal report naming that mark's term and
      the id it gave up.
- [ ] AC2: For each of the seven elements of the skip list,
      `examples/id-collision.qmd` writes an `id=` attribute of a tag inside that
      element's content, and a mark carrying that name. On the rendered page
      each of the seven names is the id of the span printing its mark's term and
      is on no other element, and no refusal report in the render log names any
      of those seven terms.
- [ ] AC3: For `script` and for `textarea`, `examples/id-collision.qmd` writes
      inside that element's content the string `</` + the element's name + a
      further letter + `>`, which is not that element's end tag, followed by an
      `id=` attribute of a tag and a mark carrying that name; and separately
      closes such an element with a real end tag written `</` + the name + a
      space + `>`, followed by an `id=` attribute of a tag and a mark carrying
      that name. On the rendered page each of the first two names is the id of
      the span printing its mark's term with no refusal report naming that term,
      and each of the second two is carried by exactly one element — the
      author's — its mark anchored on a minted id and reported once.
- [ ] AC4: At a point in `examples/id-collision.qmd` where no `p` and no `em`
      element is open, a raw HTML block writes a `</p>` closing tag carrying a
      double-quoted `id=` attribute and an `</em>` closing tag carrying an
      unquoted one, plus a mark carrying each of those two names. On the
      rendered page each of the two names is the id of the span printing its
      mark's term, and no refusal report names either term.
- [ ] AC5: The twenty-two marks `examples/id-collision.qmd` carried before this
      milestone keep their outcome, on the rendered page and in the EPUB the
      same fixture renders to. The twelve printing `alpha`, `beta`, `gamma`,
      `delta`, `epsilon`, `theta`, `lambda`, `psi`, `rho`, `sigma`, `tau` and
      `phi` still yield the author id each was written with and are still each
      reported once; the nine printing `kappa`, `mu`, `nu`, `xi`, `omicron`,
      `pi`, `chi`, `omega` and `upsilon` still carry theirs and draw no report,
      `nu`'s on the empty span after the heading it is written in; and the
      untagged mark's `untagged-in-heading` is still on an element outside its
      heading.
- [ ] AC6: `site/html.qmd` and `CHANGELOG.md` each state that an `id=` written
      in the text content of one of the seven skip-list elements, or on a
      closing tag, is on nothing the rendered page carries and so contests
      nothing, and each names `title` as the one such element the rule does not
      cover; and `site/html.qmd` no longer carries its sentence that a name
      written in a raw HTML block after a `script` or `style` element in that
      same block is not seen.
- [ ] AC7: `tests/run-tests.sh` exits 0, and `tests/run-tests.sh --self-test`
      exits 0.

## Coverage

- AC1 → T1, T3, T5, T8
- AC2 → T1, T2, T4, T6, T8
- AC3 → T1, T4, T6, T8
- AC4 → T1, T3, T7, T8
- AC5 → T5, T6, T7, T8
- AC6 → T10
- AC7 → T2, T8, T9, T10

## Tasks

- [x] T1: Reproduce all four wrong shapes against today's `note_raw`
      (`_extensions/index/modules/html.lua:520-608`) with scratch raw-HTML
      strings; record in the work log the exact string and the wrong answer each
      produces, and which of the four the M079-AC1 leg can already see.
- [ ] T2: Teach `tests/htmlindex.py`'s `_Builder` the same seven-element text-
      content set — `html.parser` treats only `script` and `style` as character
      data (`tests/htmlindex.py:37`), so a planted `<p id=…>` inside a
      `textarea` becomes a real node and the AC2 cases are unreadable without
      this. Plant a page showing the reader reporting that phantom id before the
      change and not after.
- [ ] T3: `note_raw`: distinguish an opening tag from a closing one, so the
      character-data skip fires only on an opening tag (today's re-read of
      `</script` as an opener, `html.lua:592-601`) and a closing tag's
      attributes claim nothing (`html.lua:544-585`).
- [ ] T4: `note_raw`: replace the two-name `script`/`style` test with the
      declared seven-element skip list, and match its end tag as `</` + name
      followed by whitespace, `/` or `>` rather than by prefix
      (`html.lua:596`).
- [ ] T5: Extend `examples/id-collision.qmd` with AC1's seven cases, each
      element and its following `id=` in the SAME raw block — M079's lesson is
      that a fixture writing one case per block cannot see a defect about cases
      interacting within one — and one of the seven marked inside a heading.
- [ ] T6: Extend the fixture with AC2's seven content cases and AC3's four
      end-tag-match cases, two of the eleven written as raw inlines, and the
      four `id=` spellings the census reads distributed across the new cases.
- [ ] T7: Extend the fixture with AC4's two closing-tag cases, written where no
      `p` and no `em` element is open.
- [ ] T8: Extend the M079-AC1 leg's hand-derived tables
      (`tests/run-tests.sh:3971-4006`) with the new terms — refused for AC1's
      seven and AC3's two real end tags, kept for AC2's seven, AC3's two
      non-end-tags and AC4's two — and its whole-log refusal count
      (`tests/run-tests.sh:4172`), in the same commit as the fixture rows.
- [ ] T9: Revert each of T3's two repairs and each of T4's two in turn against
      the extended suite, and record in the work log the check each one reddens.
- [ ] T10: `site/html.qmd` prose and its claim rows (`site/html.qmd:53-61`, row
      at `tests/run-tests.sh:4245`) and `CHANGELOG.md`; strike KI254 from
      `cairn/DESIGN.md`, writing the `title`/`noscript`/`plaintext` residue as
      its replacement; correct the architecture sentence naming three wrong
      shapes; rewrite the census candidate row to what remains.

## Work log

- 2026-09-06: created by /milestone-plan.
- 2026-09-06: criteria audit ran in FULL mode (surface tier user-facing), two rounds, fresh-context [O] readers. Round 1 returned findings on all five drafted criteria — AC2 unsatisfiable against `tests/htmlindex.py`'s parser, AC1's promise under-naming its family, AC4 instrument-bound and fighting the leg's whole-log count, AC3's free element names truncating the parse tree, AC5's unbounded absence claim, CHANGELOG drift — all six fixed and reported at the gate. Round 2, over the post-gate wording, returned nine more: AC1 unsatisfiable for its heading case, AC5 misstating `nu`'s kept-id location, the leg's refusal count contradicting AC1, AC6 contradicting a live claim row, "raw HTML block" excluding the mandated raw inlines, the `title` residue unnamed, AC3 leaving the whitespace-terminated end tag unvaried, AC4's `</em>` placement, and the EPUB co-render unstated. All nine disposed into the wording above and into T2, T8 and T10.
- 2026-09-06: plan gate chose the seven exercisable skip-list elements over the full HTML5 text-content family (adding `title`, `noscript`, `plaintext`) because no case can exercise those three on a rendered page and the criteria would then promise over members no procedure sweeps; falsified by an author reporting an id written in a `title` or `noscript` element lost or contested.
- 2026-09-06: plan gate chose taking the end-tag match rule in scope over recording it as a fresh known issue, because the skip list gaining five members makes the early-close shape live for five more elements at no extra code cost; falsified by the stricter match rejecting an end tag a browser accepts.
- 2026-09-06: plan gate chose distributing the four `id=` spellings, two raw-inline cases and one heading case across the new marks over one shape and one spelling throughout, because a single exemplar standing for a family is the probe blindness M079's own review left behind; falsified by a defect the distributed cases miss that a full cross-product would have caught.
- 2026-09-06: plan chose repairing `tests/htmlindex.py`'s parser over writing the AC2 cases in shapes both readers already agree on, because the suite's reader is meant to model a browser and today reads `textarea` content as markup; falsified by the repair changing an existing leg's reading of any captured page.
- 2026-09-06: T1 reproduced all four wrong shapes against today's `note_raw` in a scratch harness (`pandoc lua`, the function lifted verbatim with a stub `claim`). `<script>var a = 1;</script><p id="after-script">y</p>` claims nothing, want `after-script` (same for `style`); `<textarea><p id="ghost-textarea">x</p></textarea>` claims `ghost-textarea`, want nothing (same for `iframe`, `xmp`, `noembed`, `noframes`); `</p id="on-closing-p">` claims `on-closing-p`, want nothing; `<script>a</scriptx> <p id="early">z</p></script><p id="after-false">w</p>` claims `early`, want `after-false`. A fifth shape falls out of the first: `</script >` with a space is matched by prefix, re-read as an opener, and everything after it goes uncounted. The M079-AC1 leg can see none of the four — the fixture's only skip-list element is the one `<script>` at line 178, whose raw block ends with it, and it writes no closing tag carrying attributes and no end-tag lookalike.
- 2026-09-06: baseline before any change on this branch — `tests/run-tests.sh` exit 0, 773 checks, 21m18s.
- 2026-09-06: question gate chose descriptive names for the twenty new marks (`after-script`, `inside-textarea`) over a second alphabet, one new fixture section per rule over one combined section, and overriding Python's parser list of text-content elements over hand-written skipping in `tests/htmlindex.py`.
- 2026-09-06: plan chose keeping every new case in `examples/id-collision.qmd` over a sibling fixture, because that page's whole-page duplicate-id sweep is the procedure AC1's and AC2's universals name and a second page would sit outside it; falsified by that render becoming a named cost in the suite's timing profile.

## Decisions

## Review
