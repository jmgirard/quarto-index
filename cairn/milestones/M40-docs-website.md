# M40: The documentation moves into a Quarto website

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, IP3
- **Branch/PR:** —

## Goal

A `site/` Quarto website becomes the documentation's home, README shrinks to a
pointer, and every claim the acceptance suite pins moves with the prose.

## Scope

Surface tier: **user-facing** — the site is the extension's discovery surface,
which GP1 holds to extension-listing quality.

**In:** a `site/` Quarto website project (`_quarto.yml`, navigation,
`site/_extensions` → `../_extensions`, `site/_site` as output dir); README's 17
`## `/`### ` headings other than `## Install`, `## Examples` and `## Tests`
moved into site pages with their prose intact; README rewritten to pitch,
install, pre-release warning and a link to the docs; a **claim-container
registry** in `tests/run-tests.sh` that the suite iterates, so the 16 existing
`README_*` containers plus `SUPPORTED_FORMS` are enumerated by a procedure
rather than by hand, each repointed at the site file that now holds it and each
tagged presence or absence; and a link check over the rendered site.

The site uses Quarto's default output naming — no `output-file:` overrides —
and partials are `_`-prefixed, so a source path determines its output path.

**Out:** the rendered-example gallery → M41. The Actions/Pages workflow and the
published URL in README → M42. The Quarto floor/latest CI matrix and KI79 →
the standing candidate row, which M42 amends with a pointer; pinning one Quarto
version does not fence the floor and must not read as closing KI79.

## Acceptance criteria

- [ ] AC1. `quarto render site` from a clean checkout exits 0, and for every
      tracked path under `site/` ending in `.qmd` whose basename does not begin
      with `_` (enumerated by `git ls-files site`), the file at the same
      relative path with `.html` for `.qmd` exists under `site/_site/`.
- [ ] AC2. Every link the rendered site makes to its own content resolves. For
      each `href` value in each `.html` under `site/_site/`, excluding `<use>`
      hrefs and values whose scheme is `http:`, `https:`, `mailto:`, `tel:`,
      `data:` or `javascript:`: where the value has a path part, that path
      exists under `site/_site/` after the site's configured base path is
      stripped; where it carries a `#fragment`, an element with that `id`
      exists in the file it names, or in the containing page when the value has
      no path part.
- [ ] AC3. No documentation prose is lost: for every line
      `git diff <merge-base>..HEAD -- README.md` reports removed, every run of
      four or more ASCII alphanumerics on that line, lowercased, appears in the
      concatenated lowercased text of the tracked files under `site/` at HEAD.
- [ ] AC4. Every line matching `^#{2,3} ` in the merge-base README.md other
      than `## Install`, `## Examples` and `## Tests` (17 lines) is absent from
      README.md at HEAD, and for each, a tracked file under `site/` carries a
      heading whose text — the line with its leading `#` run and following
      spaces removed — is identical.
- [ ] AC5. README.md at HEAD is under 120 lines and contains the pre-release
      warning paragraph, the `quarto add jmgirard/quarto-index` line, and a
      relative link to `site/index.qmd` that resolves in the repo.
- [ ] AC6. Every exemplar in `SUPPORTED_FORMS` and every entry in every
      presence container the claim-container registry lists appears, under the
      comparison the suite already uses for that container, in exactly one
      tracked `.qmd` file under `site/` that AC1 renders.
- [ ] AC7. Every entry in every absence container the registry lists —
      `README_STALE` (:318), `README_REFS_STALE` (:500) and
      `README_MISUSE_STALE` (:1860) — appears in no tracked file under `site/`
      and not in README.md.
- [ ] AC8. `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T2, T6
- AC2 → T6, T7
- AC3 → T2, T4, T7
- AC4 → T2, T3, T6, T7
- AC5 → T3, T6, T7
- AC6 → T2, T5, T7
- AC7 → T3, T5, T7
- AC8 → T1, T4, T5, T6, T7, T8

## Tasks

- [ ] T1. Create the `site/` project: `_quarto.yml` (website, `output-dir:
      _site`, navigation), `site/index.qmd`, the `site/_extensions` symlink,
      and `site/_site/` + `site/.quarto/` in `.gitignore`.
- [ ] T2. Move the 17 headings and their prose from README.md into site pages,
      one page per `## ` section with its `### ` subsections intact, keeping
      every pinned sentence byte-identical to what the suite compares today.
- [ ] T3. Rewrite README.md: pitch, `## Install`, the pre-release warning, the
      docs link, and short `## Examples` / `## Tests` pointers.
- [ ] T4. Write the prose-move bound of AC3 (the M27 four-character-word rule
      in `cairn/check-design.md`), stating its normalization in the check.
- [ ] T5. Add the claim-container registry to `tests/run-tests.sh`: every
      `README_*` container and `SUPPORTED_FORMS`, each tagged presence or
      absence and each naming the file it is compared against; add a check that
      the registry names every such container the file defines, so the domain
      cannot half-empty (`check-design.md`, M16); repoint each at its site file.
- [ ] T6. Write the render and link-resolution checks (AC1, AC2, AC4, AC5),
      capturing the render and reading the capture (M24; note `suitescan.py`'s
      `pairs` rule binds any `quarto render` line the suite adds).
- [ ] T7. Plant a defect per clause of each new check and record each red
      (`check-design.md`, M32 — a plant per clause, not per reader): a dangling
      relative href, a dangling fragment, a root-relative href under the base
      path, an unrendered `.qmd`, a moved heading whose text drifted, a claim
      sentence deleted from its site file, an absence sentence copied into one,
      a registry missing a container, and a README line whose words reach no
      site file.
- [ ] T8. DESIGN.md: record the docs-home split in Architecture; amend any
      Known-issue the move closes. Verify slot clean.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: [O] criteria audit ran twice, full mode both times (user-facing tier). Round 1 returned findings on all ten drafted criteria across the then-two milestones; round 2, after the question gate re-cut them, returned findings on every criterion but the verify-slot ones. Both rounds' findings were disposed here — none deferred, none silent.
- 2026-08-26: plan gate chose moving the prose into the site over generating the site's docs pages from README.md at build time; the user picked site-primary at the question gate for site structure, against the recommendation, accepting the repoint of 16 claim containers. Falsified by evidence that the pinned-claim discipline cannot survive the move — a claim set with no site file that can hold it verbatim.
- 2026-08-26: plan gate chose the claim-container registry over the criterion naming its containers by hand; the audit showed a hand list already wrong (13 named against 16 defined, `README_STALE` counted as a presence set, `SUPPORTED_FORMS` double-counted). Falsified by a container the registry omits that its own completeness check does not catch.
- 2026-08-26: plan gate kept the criteria bound to the site and left "the suite enforces it" in the tasks, over stating enforcement as a criterion; the audit's cross-cutting finding that the site can rot post-merge with the suite green is real, and the answer is T5-T7, not an instrument-bound promise. Falsified by a post-merge site regression no suite check reaches.
- 2026-08-26: sizing tripwire split this from the two milestones the user chose into three; the docs migration plus the claim repoint is a milestone on its own once the prose moves rather than being generated.

- 2026-08-26: sizing tripwire also flags 8 acceptance criteria (>7). Not split: AC6 (presence containers) and AC7 (absence containers) are two domains with opposite promises, and the claim repoint cannot land in a later milestone than the prose move without leaving the suite red in between.

## Decisions

## Review
