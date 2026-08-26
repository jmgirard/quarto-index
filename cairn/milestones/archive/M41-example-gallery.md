# M41: The site shows each curated example's source, index and PDF

**Status:** done (2026-08-26, PR #41 https://github.com/jmgirard/quarto-index/pull/41)

**Goal:** Every fixture the gallery declares gets a page carrying its `.qmd` source, the index its HTML render produced, and a link to its built PDF.

**Outcome:** `site/gallery.yml` declares all 55 `.qmd` under `examples/` — 10
shown, 45 not. `site/build_gallery.py` is the site's `pre-render` step: it
stages each shown fixture (never a render artifact) into `.gallery-build/` at
the REPO ROOT — outside `site/`, or Quarto renders it as a page of the website
— renders that copy to self-contained HTML and PDF with `QUARTO_*` stripped
from the child environment, and writes one `site/gallery/<name>.qmd` per
fixture. The oracle is the suite's hand-derived index manifests, made
addressable by fixture — nothing scans the sources — and `tests/gallerycheck.py`
holds AC1-AC4 over the CAPTURED site. The build needs the suite's LaTeX chain.

**Decisions:** the `pending` residue sweep asks the parsed page for the
attribute, not the markup for the string (a fixture's forged `data-qi-pending`
now prints as text a reader sees); both whole-set sweeps moved after the render, reading 141 captured pages where they read 100.

**Review:** three-lens fan-out; two lenses clean, [O] diff-bug returned 18
ranked findings, none failing a criterion. Six fixed at the gate: AC5's listing
counted per file (GNU `xargs` runs on empty input), `shasum` in preflight,
`git ls-files -z`, `pdftotext` decoded UTF-8, duplicate registry rows refused,
render artifacts unstaged. Twelve to the suite-hardening row.
