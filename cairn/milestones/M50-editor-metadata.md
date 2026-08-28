<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M50: Editors complete and document the marking syntax

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m050-editor-metadata · https://github.com/jmgirard/quarto-index/pull/49   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1 `_extensions/index/_snippets.json` parses as JSON and every entry in
      it carries a non-empty `prefix`, a non-empty `body` and a non-empty
      `description` — checked by a reader iterating every top-level key of
      that file.
- [x] AC2 For each of the two classes the docs document (`index`,
      `qi-index-here`), the attribute names `_extensions/index/_schema.yml`
      declares on that class equal the names that class's constructs use
      across `site/*.qmd` — enumerated by a reader scanning every `{.index …}`
      span and `{.qi-index-here …}` construct in those files — and the schema
      declares no third class; the values it enumerates for `mention` and for
      `range` equal those the ten forms in the `site/syntax.qmd` table use
      (`principal`; `open`, `close`), read from that table's rows and not from
      every occurrence on the site, which include no-op empty values.
- [x] AC3 Every attribute name AC2's scan enumerates appears in at least one
      snippet body for its own class; no snippet body carries an attribute
      name outside that set; and the bare `[term]{.index}` form, the bare
      `::: {.qi-index-here}` div and the `::: {.qi-index-here index="…"}` div
      each have a snippet — checked by the same reader over the parsed bodies.
- [x] AC4 A fixture generated from every entry of `_snippets.json`, each
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
- [x] AC5 Both files are present in an extension installed from an archive of
      what git tracks — `git archive HEAD _extensions` unzipped by `quarto add`
      into a scratch project — checked by a reader reading the installed path.
- [x] AC6 `site/index.qmd` and `README.md` each state that the extension ships
      editor metadata, naming `_schema.yml` as its Quarto Wizard schema and
      `_snippets.json` as VS Code-format snippets that editors supporting
      those formats read for completion and hover text — checked by a reader
      requiring both filenames in the captured `_site/index.html` and in
      `README.md`.
- [x] AC7 `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass
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
- [x] T2 Author `_extensions/index/_snippets.json`: one snippet per attribute
      per class, plus the bare mark, both placement divs and the `indexes:`
      metadata block. Each snippet's placeholder defaults are its own terms,
      distinct from every other snippet's, so AC4's per-attribute effects land
      on entries of their own.
- [x] T3 Add `tests/editormeta.py` — parses both files, scans `site/*.qmd` for
      the constructs, and runs AC1-AC3's clauses — and wire it into
      `tests/run-tests.sh`. One plant per clause: a dropped snippet, an
      attribute declared on the wrong class, an added enum value, an
      undocumented attribute name in a body, an empty description, a third
      class.
- [x] T4 Add the fixture generator and its render leg for AC4: the generated
      `.qmd` (front matter declaring the index the `index=` snippet names), the
      bare-mark control document, both renders captured per M24's rule, and
      one plant per effect clause.
- [x] T5 Add the install probe for AC5: `git archive` into `$WORK`, `quarto add
      --no-prompt`, read the installed path. Plant: an archive built without
      one of the two files.
- [x] T6 Docs and records: the editor-metadata paragraph in `site/index.qmd`
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
- 2026-08-27: T2-T6 written and wired in one checkpoint, boxes left unticked — the acceptance suite takes about fifteen minutes a run, so one `--self-test` run verifies all five rather than five runs verifying one each; the ticks follow that run's result.
- 2026-08-27: DESIGN.md Known issues gains KI90, that no check holds the schema against the attribute set the filter accepts, which the plan gate chose (T6).
- 2026-08-27: T3's three required-shape clauses moved ahead of the per-class coverage clauses: on `qi-index-here` the docs document one attribute, so the shape and the coverage clause were true together and only the first could be reached by a plant; each of the three shapes now has a plant of its own and the coverage clause keeps one.
- 2026-08-27: T6's README paragraph links the Syntax page rather than the published URL — M42's self-test plant substitutes exactly one occurrence of that URL in README and the paragraph had added a second.
- 2026-08-27: T2-T6 verified in one run each of the profile's two legs after a session crash lost an earlier run: `tests/run-tests.sh` 397 checks, `tests/run-tests.sh --self-test` 760, both exit 0. 44 planted defects across the M50 readers, each shown red on its own clause.
- 2026-08-27: review ran all seven criteria fresh at 669f1db — both verify legs green (397 and 760 checks), consistency gate clean, three review lenses spawned, thirteen findings from the diff lens and none from the other two. Supersedes the line above on one point: the 44 plants each redden their own clause, but they do not cover every clause — `editorfixture.py generate` has none and about ten `editormeta.py` clauses have none (Review F2, F3).

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Fresh evidence, 2026-08-27, branch `m050-editor-metadata` at 669f1db, PR #49.
`tests/run-tests.sh` (the profile's verify slot, first leg) ran green at 397
checks; every AC line below is that run's own named check.

- AC1 — green. `_snippets.json` parses and all 11 snippets carry a prefix, a
  body and a description; the reader iterates every top-level key.
- AC2 — green. The schema declares `index` and `qi-index-here` and no third
  class; its per-class attribute names equal those the 20 tracked `site/*.qmd`
  pages write (entry, index, mention, range, see, see-also, sort on `index`;
  index on `qi-index-here`), and its `mention=`/`range=` enumerations equal the
  10 form rows' values (principal; close, open).
- AC3 — green. The bare mark, the bare placement marker and a marker naming an
  index each have a snippet; every attribute the swept pages write is written
  by a body on its own class (7 on `index`, 1 on `qi-index-here`); no body
  writes one they do not.
- AC4 — green. Fixture and bare-mark control generated from all 11 snippets
  with tab stops replaced by their placeholder text; both render to HTML at
  exit 0 and the fixture to PDF at exit 0. Every attribute shows an effect the
  control does not: `entry=` splits into 2 levels, `see=`/`see-also=` replace
  the locator, `sort=` moves the entry to another letter group, `mention=`
  emphasizes one locator, `range=` prints one locator where two bare marks
  print two, `index=` files the entry in the `qi-index-authors` section alone.
  The PDF prints one index of 9 entry lines carrying both declared indexes'
  entries, as a LaTeX render folds them today.
- AC5 — green. `git archive HEAD _extensions` installed by `quarto add
  --no-prompt` into a scratch project carries both files at
  `_extensions/index`.
- AC6 — green. Both the captured `_site/index.html` and `README.md` name
  `_schema.yml` and `_snippets.json`.
- AC7 — green. `tests/run-tests.sh` 397 checks, exit 0;
  `tests/run-tests.sh --self-test` 760 checks, exit 0. An earlier self-test
  invocation aborted at M34-AC4's no-engine control on a Quarto segmentation
  fault (`quarto: line 210 … Segmentation fault: 11`), an engine crash in a
  pre-existing check with no M50 surface; the re-run recorded here is the
  evidence.

### Consistency gate

`cairn_validate.py` exit 0, every check PASS, the `release window` advisory
silent. No `DESIGN.md` principle changed, so `cairn_impact.py` did not run.
The `generic` profile's `consistency-gate` slot names no toolchain check.

### Independent review

Three fresh-context lenses, user-facing tier and executable surface touched.
Blame-history: no finding — the `M50_`/`m50_` prefixes collide with nothing
earlier in `run-tests.sh`, `capture()` and the `HTML_*` identifiers are read
and never reassigned, and D-011 and D-030 are cited accurately.
Prior-review: no finding — `gh api …/pulls/comments` returns `[]`, so the
GitHub surface is empty, and against the archived `## Review` sections and
`cairn/check-design.md` the diff applies the recorded hazard shapes (tracked-file
domain, no-op-mutation assertion, per-clause granularity) rather than
reintroducing them. Diff-bug reported thirteen, ranked; all logged below.

- F1 `check_folded` cannot tell one printed index from two.
  `pdfindex.read()` collects from the first `Index` heading to the end of the
  document, so a PDF printing two indexes yields one row list carrying both
  terms and passes identically; none of the three plants is a two-index
  artifact. AC4's fold clause holds today — the captured `fixture.pdf` prints
  exactly one `Index` heading, verified at review — but the check would stay
  green when M49 makes a PDF build every declared index. **Follow-up.**
- F2 `editorfixture.py generate` has no planted defect at all: its seven
  refusal clauses (no snippet, no content snippet, no metadata snippet, no
  attribute site, `repeated`, `split`, `missing`) are reddened by nothing.
  Confirmed — `generate` appears once in `run-tests.sh`, as the real
  invocation. **Follow-up.**
- F3 About ten `editormeta.py` clauses have no plant — the empty-object and
  non-dict snippet files, `prefix`/`body` empty as distinct from
  `description`, YAML parse failure, non-mapping top level, a missing
  `classes:`/`attributes:` section, the `attributes:`-side class mismatch, an
  empty per-class attribute block, a missing `enum:`, and `check_bodies`'
  no-attribute guard — so the work log's "44 planted defects … each shown red
  on its own clause" reads as per-clause coverage it does not have. The 44
  plants exist and each is red on its own clause; the coverage is partial.
  **Follow-up**, with a superseding work-log line rather than an edit (IP4).
- F4 `editorfixture.sections()` lets `htmlindex.index_entries` raise:
  `indexdump.py` catches the same `ValueError` and reports it, on the stated
  ground that "a crash exits non-zero for a reason nothing states", and this
  reader does not. Confirmed at review. **Fixed at the gate.**
- F5 PyYAML is not in `require_pdf_tools`, though D-030's Consequences place
  it "beside the TinyTeX, `makeindex`, `pdftotext` and `pdfinfo` it already
  refuses to skip"; the import guard sits at the end of a ~15-minute run.
  Confirmed at review. **Fixed at the gate.**
- F6 Nothing holds `_schema.yml` against the `$schema` it declares — the
  property that decides whether an editor reads the file at all. The reviewer
  fetched the published Quarto Wizard v1 schema and confirmed the file
  conforms today. **Follow-up.**
- F7 AC2's stated ground for reading `mention=`/`range=` values off the
  ten-row table — that the site demonstrates empty values elsewhere — is not
  true of the swept domain: the empty-value constructs live in `examples/`,
  which is not swept. `SYNTAX_FORMS = 10` is a bare pin, so an eleventh
  documented form reddens AC2 for an unrelated reason. **Follow-up.**
- F8 `check_docs` splits paths from filenames by `os.path.isfile`, so a
  missing `$SITE_OUT/index.html` is silently reclassified as a name to look
  for and the run fails naming the wrong thing. **Follow-up.**
- F9 `site/index.qmd` claims more than AC6 sanctions and more than any check
  holds — that Quarto Wizard "in VS Code and Positron" read the files and
  "insert a snippet on its own prefix". **Fixed at the gate** (trimmed to
  what ships).
- F10 README and `site/index.qmd` promise a description on every class;
  `check_schema` requires one only under `attributes:`. **Follow-up.**
- F11 `parse_attrs` stops at the first `"` in a value, so an escaped quote
  would be mis-scanned into an invented attribute name. No tracked page
  writes one. **Follow-up.**
- F12 `attribute_sites` pairs `constructs` and `marks` positionally, and
  `marked_terms` skips a `.index` construct not preceded by `]`, so a skip
  could pair an attribute with the wrong term. Nothing triggers it today.
  **Follow-up.**
- F13 Minor: `$M50_PAGES` expanded unquoted; `capture` not failing on an
  empty capture outside `examples/`, and the PDF slug re-copying the leftover
  HTML artifact; `group_of` reading letter groups off the pooled row list.
  The unquoted expansion is the file's own idiom for passing N paths and no
  tracked page path carries a space — **rejected**; the rest **follow-up**.

Fix-now work, and the criteria re-run over it: `editorfixture.sections()`
raises a module `Unreadable` that `main` reports as a `FAIL:` line (F4);
`require_pdf_tools` names PyYAML, so a machine without it learns so before the
renders rather than after them (F5); and `site/index.qmd`'s editor paragraph
drops the two named editors and the prefix-insertion claim, keeping what AC6
sanctions (F9). Both verify legs re-run over the amended tree: 397 checks and
760 checks, both exit 0, AC6's reader green on the rewritten page.

Return floor: none of the thirteen demonstrates an acceptance criterion
failing — AC4's fold clause was verified directly against the captured PDF —
and none is a defect in what the shipped extension does for an author, the two
files being confirmed conformant to the published schema. Status stays
`review`.
