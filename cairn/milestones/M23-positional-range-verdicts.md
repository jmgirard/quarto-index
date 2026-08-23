<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M23: A range verdict follows its mark's position, not its text

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m23-positional-range-verdicts`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The emitting pass reads each range mark's pairing verdict by document
position, so a mark's rewritten visible text can never move another mark's
verdict.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Replace `marks.lua`'s per-key verdict queues (`range_plan` /
`range_cursor`, read at `marks.lua:404` and consumed at `passes.lua:367`)
with one position-ordinal store both traversals advance at the same span
guard (index class + `range=` attribute), before entry derivation; a nested
`entry=`-less fixture; the AC2 source scan. The deliverable is user-facing —
range pairing in rendered documents — though the desync is latent today: for
an `entry=`-less mark the key derives from stringified visible text, the
emitting pass rewrites inner spans bottom-up, and only the accident that raw
inlines stringify to empty keeps the two traversals' keys equal. Lineage:
promotes the 2026-08-22 candidate row (M21 review round 3 R3-F9).

**Out:** cross-chapter range pairing → standing candidate row (D-009). The
gfm span reader stopping at the first `</span>` → standing acceptance-suite-
hardening row (R2-F10); T1 avoids that reader rather than fixing it here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1 (regression guard: true before this milestone; must stay true): A
      `range=` mark whose span content itself contains another index mark,
      the outer mark carrying no `entry=`, pairs with its closing mark — the
      outer entry prints one page range in the PDF index and records a
      paired range in the HTML index — asserted over a fixture carrying the
      nested shape and a plain non-nested range of a different term in the
      same document, in both back-ends.
- [ ] AC2: The range-verdict store keys on document position: the
      verdict-planning and verdict-reading functions take no entry-key
      argument and advance one shared position counter at the same span
      guard (a span carrying the index class and a `range=` attribute) —
      asserted by a source scan over `modules/marks.lua` and
      `modules/passes.lua` pinned to those functions by name, which fails
      when a pinned name is absent.
- [ ] AC3: The active profile's verify slot (`tests/run-tests.sh`) passes.

## Coverage
<!-- owner: plan · create/amend-via-gate; review reads to fence evidence -->

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Nested fixture: an outer `entry=`-less range mark containing an
      inner index mark, plus a plain non-nested range of a different term in
      the same document; give each new mark a term no other mark in the file
      indexes (M13 lesson). Checks in both back-ends, reading the nested
      span through something other than the gfm reader (its first-`</span>`
      truncation is a standing candidate row). Green today — the
      untouched-shape guard (M11 lesson).
- [ ] T2: Re-key: replace the per-key `range_plan`/`range_cursor` queues
      with a position-ordinal store; both traversals advance the ordinal at
      the same guard (span has the index class and `range=`), before
      derivation, so alignment is independent of key and derivation alike.
      Existing M21 suite sections and T1 stay green.
- [ ] T3: The AC2 source scan, plus proof it discriminates: a spliced
      variant reintroducing a key parameter on the reading path must fail
      it; a renamed pinned function must fail it (name absence); a spliced
      guard divergence (one traversal advancing on a different condition)
      must fail it.
- [ ] T4: Comment and README touch-ups; remove the absorbed candidate row
      from the ROADMAP; work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-22: created by /milestone-plan.
- 2026-08-22: criteria audit (full mode, fresh-context reader) ran twice — pre-gate it returned two load-bearing findings here (AC1 satisfiable at the outset with no acknowledged certifier, AC2 a proxy universal whose scan could pass vacuously on a rename), both repaired; the post-gate re-audit returned one mild finding (AC2 verified counter sharing but not guard agreement), repaired in the wording above.
- 2026-08-22: plan gate chose position-ordinal keying over keeping the per-key queues (with a guarantee that span text never differs between traversals) because the key path depends on what the emitting pass's rewrites stringify to — a property of Pandoc and future emitters, not of this filter; falsified by a document where the two traversals visit range marks in different orders.
- 2026-08-22: plan gate chose the source-scan certifier over behavior-only criteria because no current rendering reaches the latent desync, so behavior alone certifies nothing about the change; falsified by a constructible rendering that fails pre-fix, which would supersede the scan with a behavioral criterion.
- 2026-08-22: implementation started on `m23-positional-range-verdicts`.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
