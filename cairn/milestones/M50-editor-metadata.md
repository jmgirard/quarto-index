<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M50: Editors complete and document the marking syntax

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m050-editor-metadata   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ship the two editor-metadata files the Quarto extension listing's check asks
for — `_schema.yml` and `_snippets.json` — so an editor completes and
documents this extension's marking syntax.

## Scope
<!-- owner: plan · create/amend-via-gate -->

Surface tier: **user-facing** — both files ship inside `_extensions/index/`
and an author's editor reads them.

**In:** `_extensions/index/_schema.yml` describing the two CSS classes the
filter reads and the attributes each carries; `_extensions/index/_snippets.json`
in VS Code snippet format; readers holding both files against the syntax the
docs site documents; a render of a fixture built from the snippets; a probe
that the files travel on install; the docs, README and changelog lines.

**Out:** an `options:` block, and any change to where the filter reads
`indexes:` — the schema format describes settings only under an `extensions:`
heading, so the extension's one top-level key stays undescribed. That
alternative and the evidence that would falsify this choice are recorded in
the work log rather than as a candidate row, the ROADMAP being one line under
its cap. A release that puts these files in front of the
extension listing → user-declared later, in its own step (the plan gate
declared no window). Holding the schema against the attribute set the FILTER
accepts rather than the set the docs document → a Known issues entry (T6),
since a source-shape scan is what D-011 refuses.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1 `_extensions/index/_snippets.json` parses as JSON and every entry in
      it carries a non-empty `prefix`, a non-empty `body` and a non-empty
      `description` — checked by a reader iterating every top-level key of
      that file.
- [ ] AC2 For each of the two classes the docs document (`index`,
      `qi-index-here`), the attribute names `_extensions/index/_schema.yml`
      declares on that class equal the names that class's constructs use
      across `site/*.qmd` — enumerated by a reader scanning every `{.index …}`
      span and `{.qi-index-here …}` construct in those files — and the schema
      declares no third class; the values it enumerates for `mention` and for
      `range` equal those the ten forms in the `site/syntax.qmd` table use
      (`principal`; `open`, `close`), read from that table's rows and not from
      every occurrence on the site, which include no-op empty values.
- [ ] AC3 Every attribute name AC2's scan enumerates appears in at least one
      snippet body for its own class; no snippet body carries an attribute
      name outside that set; and the bare `[term]{.index}` form, the bare
      `::: {.qi-index-here}` div and the `::: {.qi-index-here index="…"}` div
      each have a snippet — checked by the same reader over the parsed bodies.
- [ ] AC4 A fixture generated from every entry of `_snippets.json`, each
      body's tab stops replaced by their placeholder default text, renders at
      exit 0 to HTML and to PDF, and each attribute produces in the rendered
      index an effect the bare-mark control render does not: `entry=` an entry
      text differing from the marked term, split at `!` into levels; `see=`
      and `see-also=` a cross-reference to their target in place of a locator;
      `sort=` the entry filed at its key's position rather than its term's;
      `mention=` an emphasized locator; `range=` one spanning locator where
      the control prints two; and `index=` the entry under the named index's
      section in the HTML render, the PDF render folding to one index as it
      does today (M49's subject).
- [ ] AC5 Both files are present in an extension installed from an archive of
      what git tracks — `git archive HEAD _extensions` unzipped by `quarto add`
      into a scratch project — checked by a reader reading the installed path.
- [ ] AC6 `site/index.qmd` and `README.md` each state that the extension ships
      editor metadata, naming `_schema.yml` as its Quarto Wizard schema and
      `_snippets.json` as VS Code-format snippets that editors supporting
      those formats read for completion and hover text — checked by a reader
      requiring both filenames in the captured `_site/index.html` and in
      `README.md`.
- [ ] AC7 `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass
      (the profile's verify slot).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T3
- AC2 → T1, T3
- AC3 → T2, T3
- AC4 → T2, T4
- AC5 → T5
- AC6 → T6
- AC7 → T3, T4, T5, T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1 Author `_extensions/index/_schema.yml`: the `classes` block for
      `index` and `qi-index-here`, and an `attributes` block keyed by each
      class name, every attribute carrying a type and a description, with
      `mention` and `range` enumerating their values. Attribute names as
      `passes.lua` and `indexes.lua` read them: entry, see, see-also, sort,
      mention, range, index.
- [ ] T2 Author `_extensions/index/_snippets.json`: one snippet per attribute
      per class, plus the bare mark, both placement divs and the `indexes:`
      metadata block. Each snippet's placeholder defaults are its own terms,
      distinct from every other snippet's, so AC4's per-attribute effects land
      on entries of their own.
- [ ] T3 Add `tests/editormeta.py` — parses both files, scans `site/*.qmd` for
      the constructs, and runs AC1-AC3's clauses — and wire it into
      `tests/run-tests.sh`. One plant per clause: a dropped snippet, an
      attribute declared on the wrong class, an added enum value, an
      undocumented attribute name in a body, an empty description, a third
      class.
- [ ] T4 Add the fixture generator and its render leg for AC4: the generated
      `.qmd` (front matter declaring the index the `index=` snippet names), the
      bare-mark control document, both renders captured per M24's rule, and
      one plant per effect clause.
- [ ] T5 Add the install probe for AC5: `git archive` into `$WORK`, `quarto add
      --no-prompt`, read the installed path. Plant: an archive built without
      one of the two files.
- [ ] T6 Docs and records: the editor-metadata paragraph in `site/index.qmd`
      and `README.md`, its reader for AC6, a `CHANGELOG.md` entry under the
      dev heading, and a DESIGN.md Known issues entry recording that no check
      holds the schema against the attribute set the filter accepts.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-27: created by /milestone-plan. Criteria audit ran in full mode (user-facing tier), fresh [O] reader: twelve findings, eleven fixed at the gate (snippet domain re-based off the ten-row table onto the docs-wide scan, since no table row uses `sort=`; per-class rather than pooled attribute comparison; enum values read from the table's rows, not from the site's no-op `mention=""`/`range=""` examples; the render check's expectation table replaced by per-attribute effects stated in AC4 against a bare-mark control; placeholder substitution stated in AC4; non-empty fields in AC1; the named install page corrected to `site/index.qmd`; the docs promise narrowed from editor behavior to what ships, and given a reader), the twelfth — whether the suite proves the files travel on install — posed at the gate and answered yes (AC5).
- 2026-08-27: plan gate chose describing the marking syntax alone over also teaching the filter to read `extensions: index:` because the second changes filter behavior for the one key the schema format cannot describe; falsified by an author reporting their `indexes:` block gets no editor support.
- 2026-08-27: plan gate chose holding the schema against the attribute set the docs document over a scan of the filter's Lua constants because D-011 refuses widening a source-shape scan and prescribes a render instead; falsified by an attribute the filter accepts and no page documents reaching a release.
- 2026-08-27: plan gate chose archiving and installing the extension over resting on the `examples/_extensions` symlink because that symlink makes the travel question vacuous; falsified by `quarto add` from a local archive diverging from what a GitHub install copies. Probe run at plan time: `git archive HEAD _extensions` + `quarto add --no-prompt` installs on Quarto 1.10.18 at exit 0.
- 2026-08-27: implement gate chose declaring version 1 of the schema vocabulary over version 2 or none, the file being written with no keyword whose spelling differs between the two; falsified by a keyword the file needs that version 1 does not carry.
- 2026-08-27: implement gate chose a distinct example term per snippet over the repeated terms of the `site/syntax.qmd` table, since AC4's per-attribute effects merge into one entry where two snippets mark the same term; T2's wording amended to match.
- 2026-08-27: implement gate chose reading AC4's seven effect comparisons in the HTML render alone, `mention=`'s effect being emphasis that leaves no trace in a PDF's text layer; the PDF is held to exit 0 and to the single folded index AC4 names.
- 2026-08-27: implement gate chose PyYAML for the schema read over an indentation parser of the suite's own — D-030.
- 2026-08-27: T1 done. `_extensions/index/_schema.yml` declares the two classes and the seven/one attributes each carries, `mention` and `range` enumerating their values.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
