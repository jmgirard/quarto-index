# M41: The site shows each curated example's source, index and PDF

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M40
- **Driving RR:** —
- **Principles touched:** GP1, GP6
- **Branch/PR:** `m041-example-gallery`

## Goal

Every fixture the site's gallery declares gets a page carrying its `.qmd`
source, the index its HTML render produced, and a link to its built PDF.

## Scope

Surface tier: **user-facing** — the gallery is what a prospective author looks
at before installing, so GP1's extension-listing bar applies to it.

**In:** `site/gallery.yml`, declaring which fixtures the gallery shows and
listing the rest; one gallery page per shown fixture, built by a pre-render
step that **copies the fixture into the site tree and renders it there**, so
the build never writes into `examples/`; each page showing the fixture source
in a code block and embedding the rendered fixture page, with a link to the
PDF the same step builds. Shown fixtures are drawn from those the acceptance
suite already holds hand-derived HTML index manifests for, and those manifests
become addressable per fixture so the gallery reuses them rather than growing a
new oracle over the fixture corpus.

The PDF half means the site build needs the LaTeX toolchain the suite already
requires — TinyTeX, `makeindex`, `pdftotext`, and `stix2-otf` for the
non-Latin-1 recipe fixtures (D-018). M42 inherits that requirement.

**Out:** a source scan over the fixture corpus as the gallery's oracle — D-011
refuses widening source-shape scans, and KI47, KI59 and KI70 record the ones
here already misreading marks; the gallery reads the suite's manifests instead.
Per-fixture exclusion rationales → not planned; `not-shown:` is a bare list.
Book-project fixtures (the 9 chapters under `examples/*/`) → a candidate row.

## Acceptance criteria

- [ ] AC1. Every path `git ls-files examples | grep -E '^examples/[^/]+\.qmd$'`
      returns (55 today) appears exactly once as a sequence item under either
      `shown:` or `not-shown:` in `site/gallery.yml`, and under no other key.
- [ ] AC2. For each fixture under `shown:`, its gallery page under
      `site/_site/` holds a `<pre><code>` element whose concatenated text
      content, HTML-entity-decoded and with a trailing newline normalized, is
      byte-identical to that fixture's `.qmd` file under `examples/`.
- [ ] AC3. Every fixture under `shown:` is one the acceptance suite holds a
      hand-derived HTML index manifest for, and every entry in that manifest
      appears in the index region of the rendered fixture page that fixture's
      gallery page embeds. `shown:` holds at least eight fixtures.
- [ ] AC4. For each fixture under `shown:` that the suite holds a hand-derived
      PDF index manifest for — at least three — its gallery page carries a link
      whose target is a `.pdf` under `site/_site/` whose `pdftotext`
      extraction contains every entry in that manifest.
- [ ] AC5. `quarto render site`, run with no other render in flight, leaves
      `examples/` unchanged: a recursive listing of `examples/` with a sha256
      per file is identical immediately before and immediately after it.
- [ ] AC6. `tests/run-tests.sh --self-test` exits 0.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T5, T6
- AC3 → T3, T4, T5, T6
- AC4 → T3, T4, T5, T6
- AC5 → T2, T5, T6
- AC6 → T1, T2, T3, T4, T5, T6, T7

## Tasks

- [x] T1. Author `site/gallery.yml`: `shown:` (ten fixtures covering the ten
      syntax forms — demo, named-indexes, sortkey, sortkey-paths,
      letter-groups, marker, placement, xref-conflict, html-index,
      empty-levels) and `not-shown:` for the remainder; add the completeness
      check of AC1 over the git-enumerated corpus.
- [x] T2. Write the pre-render step: copy each shown fixture (and its assets)
      into a scratch directory at the repo root, render it to HTML and to PDF
      there, and place the outputs under the site's output tree. Nothing it
      runs may name a path under `examples/` as a render target.
- [x] T3. Make the suite's per-fixture HTML and PDF index manifests addressable
      by fixture name, without changing a single derived row (the ORACLE RULE
      at `tests/run-tests.sh:8-22`).
- [x] T4. Build the gallery pages: source code block, embedded rendered
      fixture, PDF link, and navigation from the site's gallery landing page.
- [x] T5. Write the checks for AC1-AC5, capturing each render and reading the
      capture (M24).
- [x] T6. Plant a defect per clause and record each red (`check-design.md`,
      M32): a fixture in neither list, a fixture in both, a source block one
      byte off, a source block with entity decoding skipped, a manifest entry
      missing from an embedded index, a PDF link resolving to nothing, a PDF
      whose extraction drops one manifest entry, a shown-list shorter than its
      floor, and a render that writes into `examples/`.
- [x] T7. README/DESIGN: point the docs at the gallery; record the site build's
      toolchain requirement in DESIGN Architecture. Verify slot clean.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: [O] criteria audit ran, full mode (user-facing tier), over the round-2 draft; it returned findings on AC1-AC5 and clean on the verify slot. All disposed here.
- 2026-08-26: plan gate chose reusing the suite's hand-derived manifests as the gallery oracle over a new scan of the fixture sources; D-011 refuses widening source-shape scans and KI47/KI59/KI70 record the existing ones misreading marks. Falsified by a shown fixture whose behaviour no manifest covers being worth showing anyway.
- 2026-08-26: plan gate chose embedding the separately-rendered fixture page over including the fixture's markdown into the gallery page; an include would run this extension's own filter over the fixture's marks and placement markers on the gallery page, so the page could not both carry the source and print the fixture's index. Falsified by an embed that cannot be made to show the index region a reader needs to see.
- 2026-08-26: plan gate chose a bare `not-shown:` list over per-fixture exclusion reasons; the audit called 55 rationale strings a bookkeeping surface coupling every future fixture milestone to this file. Falsified by a reviewer unable to tell a deliberate omission from an oversight.
- 2026-08-26: implement gate chose ten shown fixtures over eight or all sixteen eligible; a repo-root scratch directory over one under `site/`, where Quarto finds the website project file walking up and renders each fixture as a page of the site; and a frame around a self-contained render over lifting the index markup into the gallery page.
- 2026-08-26: minor amendment to T1 and T2 wording. T1 named `unicode`, `principal` and `range` among the shown fixtures; AC3 admits only fixtures the suite holds a hand-derived HTML index manifest for, and it holds none for those three (`unicode`'s oracle is a typeset PDF term list, `principal` and `range` have GFM span manifests). Replaced with ten manifest-holding fixtures. T2's scratch directory moved out of `site/` for the reason the gate line above records.
- 2026-08-26: T1 done. `site/gallery.yml` declares all 55 fixtures, 10 shown and 45 not; `tests/gallerycheck.py listing` reads the declaration against `git ls-files examples` and refuses any file shape but `<key>:` and `  - <value>`. Wired into the suite as M41-AC1. Verify slot clean, 386 checks.

- 2026-08-26: T2 done. `site/build_gallery.py` is the site's `pre-render` step: it stages each shown fixture, the extension and the fixture directory's shared assets into `.gallery-build/<name>/` at the repo root, renders that copy to self-contained HTML and to PDF with Quarto's own project variables stripped from the child environment, and places both outputs under `site/gallery/rendered/`, declared as a project resource. `read_gallery` lives there and `tests/gallerycheck.py` imports it, so the build and the check read the declaration through one reader. All ten fixtures render to both formats; the suite's link check now sweeps 30 pages, 876 links, all resolving. Verify slot clean, 386 checks.

- 2026-08-26: T3 done. A table in the suite names each per-fixture manifest by fixture, kind and format — 15 rows, 10 HTML and 5 PDF — and writes each variable's contents to `$WORK/gallery-manifests/<fixture>.<kind>.txt` with a registry beside it. No derived row was copied or re-derived; the table names variables. A row naming an undefined or empty variable fails there. `gallerycheck.py manifests` reads the registry and holds AC3's and AC4's coverage clauses: every shown fixture has an HTML manifest, `shown:` meets its floor of 8, at least 3 shown fixtures have a PDF manifest, and no manifest read for the gallery states zero entries. Verify slot clean, 388 checks.

- 2026-08-26: T4 done. The build writes one `site/gallery/<name>.qmd` per shown fixture — the source verbatim in a backtick fence longer than any run the source carries, a framed `<iframe>` around the self-contained render, and links to that render and to the PDF — plus a `site/gallery/index.qmd` linking to all ten, reached from the sidebar. The whole `site/gallery/` directory is rebuilt each run so a fixture dropped from `shown:` leaves no page behind. One transform on the source: `{{< ... >}}` is escaped to `{{{< ... >}}}`, because Quarto expands a shortcode inside a fenced code block — `examples/xref-conflict.qmd` carries `{{< pagebreak >}}` and its block was 52 bytes short of the fixture until the escape went in. With it, the `<pre><code>` text content of all ten rendered gallery pages equals its fixture's bytes with a trailing newline normalized. Verify slot clean, 388 checks.

- 2026-08-26: T5 done. Three further modes read the CAPTURED site, not `site/_site`: `source` (AC2, the `<pre><code>` text content against the fixture bytes), `embedded` (AC3, the frame's own `src` resolved, then every manifest entry required among the entry terms `htmlindex.section_rows` reads out of that page's generated index sections), and `pdf` (AC4, the page's single `.pdf` href resolved, then every manifest entry required in the `pdftotext` extraction with whitespace runs collapsed, so a column break cannot hide one). AC5 is a sha256-per-file listing of `examples/` taken immediately before and after the suite's one site render, asserted non-empty first and diffed after. Live figures: 10 pages carry their source, 134 HTML index entries checked across 10 embedded pages, 53 PDF entries across 5 PDFs, 172 files under `examples/` unchanged. Verify slot clean, 392 checks.

- 2026-08-26: T6 done. Fifteen planted cases, one per clause, each run against a check first shown green on the same unplanted fixture. Six mutate a copy of the declaration; six mutate a copy of the captured site (three of them through `tests/galleryplant.py`, which re-reads what it changed with the checks' own reader and refuses a mutation that landed elsewhere); three exercise AC5's comparison over a copy of `examples/`, one adding a file, one changing a fixture's bytes, one changing nothing. Two plants were wrong on their first run and were fixed: the one-character source plant landed in the highlighter's own `<span>` markup rather than in the block's text, and the dropped-entry plant's report said the entry count fell when the entry is renamed and the count holds.
- 2026-08-26: the gallery broke the residue sweeps' domain claim, and both halves are repaired here. See the milestone Decisions entry below. `tests/run-tests.sh --self-test` exits 0 at 618 checks, the two sweeps reading 141 captured pages against 100 before.

- 2026-08-26: T7 done. The site's Examples page opens with a link to the gallery, and README's Examples section names it; both describe what the gallery shows procedurally, by what `shown:` declares, rather than by a count. DESIGN Architecture gains a paragraph on the gallery: the declaration, the pre-render step and why its scratch tree is at the repo root, the manifests as the oracle with no source scan, the LaTeX toolchain the site build now needs, and the residue sweeps' move to after the site render. `tests/run-tests.sh --self-test` exits 0 at 618 checks.

## Decisions

### 2026-08-26: The pending-attribute sweep asks the parsed page, not the markup, and runs after the site render

`tests/htmlsweep.py`'s `pending` sweep searched a rendered page's markup for
the string `data-qi-pending`. The gallery prints each shown fixture's source in
a code block, and `examples/html-index.qmd` writes a forged
`data-qi-pending="1"` in its prose, so that string now reaches a rendered page
as text a reader is meant to see — and the substring search reported it as
filter residue that survived. The sweep now asks whether any element of the
parsed page carries the attribute, which is the promise M03-AC3 states and what
the module's own docstring already claimed it did. The planted case the suite
has always run writes the attribute on `<body>`, so it is still caught, and it
is still caught planted into each of the captured pages in turn.

The same collision moved both whole-set sweeps. They sat before the site
render, whose pre-render step renders ten more fixture pages; run there, they
printed their passing line over a set those pages were not in. They now run
after it, and read 141 captured pages where they read 100.

## Review
