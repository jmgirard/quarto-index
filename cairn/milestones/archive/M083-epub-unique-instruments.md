# M083: The EPUB id-uniqueness sweep goes red on what it claims to catch

**Status:** done (2026-09-07, PR #83 https://github.com/jmgirard/quarto-index/pull/83)

**Goal:** Each clause of `tests/epubcheck.py unique` is shown red on the defect class it claims to catch, over a verdict that claims only what the clause swept.

**Outcome:** `cmd_unique` gained `leaves_publication`, skipping and counting an index href opening `//` or `scheme:` rather than joining it to the linking member's directory — the shape it had reported as naming a manifest item the publication does not list. Docstring and verdict name the one index section per document the heading search reads (KI264, cross-referencing KI51), and one `domain` sentence — documents swept, sections read, links resolved, links left unresolved as outside — prints on every failing path, not only the green one; a section whose links all leave the publication now says so rather than claiming no link carries a fragment. `plant.py` repacks the captured `id-collision.epub` member for member, substituting one run of text in one XHTML member and dying unless its pattern matches exactly once. Five plants run through it under `--self-test` (duplicate id and dangling relative href red on their own reports; scheme href, `//` href and a rewrite-nothing repack green on anchored counts), plus one leg over the captured publication pinning the verdict wording and the skipped-link count on every run, so an ordinary run catches a locator the new skip would swallow. Suite green at 1434 checks.

**Decisions:** none.

**Review:** three-lens fan-out, fourteen findings — eight fixed at the gate (the unpinned skip, three unanchored count substrings, the domain going silent on red runs, a false all-links-outside message, an ambiguous plant pattern, the wording leg reading a repack, an over-claiming "the first", and a candidate row missing KI264), four routed to a new candidate row and to KI120, two rejected as pre-existing or conventional. Nothing retired or graduated; no LESSONS line added, the file being at both its caps.
