# M20: A term's principal discussion prints as its principal locator

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP2, GP5, GP6
- **Branch/PR:** m20-principal-locators / https://github.com/jmgirard/quarto-index/pull/20

## Goal

An author can mark one occurrence of a term as its principal discussion, and both
back-ends print that occurrence's locator emphasized while its other locators stay plain.

## Scope

Surface tier: **user-facing** — it adds an authoring attribute, changes what both
back-ends emit, and is documented in README.

**In:** one new format-neutral mark attribute, `mention="principal"`, naming the role a
mention plays rather than a rendering (IP1); the LaTeX encapsulation for it, carried by a
`\providecommand` command injected only into a document that uses it, so an author can
redefine the emphasis without the extension shipping a style; the emphasized locator link
in the HTML back-end, and the record field that carries the role through a book's sidecar
store; the reports for a role written on a mark that can contribute no locator and for an
unrecognized role value; fixtures, suite section, planted-defect entries, README.

Terminology: indexing practice calls the main discussion of a term its *principal
reference* and conventionally sets it in bold; `main` is not used, a *main entry* being
the top-level heading rather than a locator. The attribute is `mention=` and not `role=`:
Pandoc data-prefixes an unknown attribute name but emits `role` literally, so `role=`
would put an invalid ARIA role on every marked term in every HTML-family output (IP2).

Contestation — the bookkeeping M15 added, which folds a key's cross-references into its
printed text when its marks would emit rival encapsulations — is narrowed to count
cross-reference encapsulations alone. A styled locator and a plain one are not rivals:
makeindex prints both, warning only when they share a page, and a term marked principally
in one place and plainly elsewhere is the feature's ordinary case, not a clash.

Evidence stops at the `.ind` makeindex writes rather than at the PDF's text, because
`pdftotext` cannot see emphasis — a deliberate GP6 trade, recorded rather than left
implicit, and the `.ind` is the artifact that settles whether the encapsulation reached
the right locator at all.

**Out:** page ranges, and a range carrying this role on both its ends → M21. Roles beyond
`principal` (a defining passage, an illustration) → ROADMAP candidate row; the attribute
is shaped to take them as values, and nothing here anticipates one. Shipping CSS for the
HTML class → out of GP3's install story; the locator carries Pandoc-level emphasis so it
reads correctly with no stylesheet at all. Whether a mark's attributes should ride into
pass-through formats at all → the standing ROADMAP row, unchanged by the new attribute.

## Acceptance criteria

- [x] AC1: The PDF render of `examples/principal.qmd` produces a `.ind` in which the
      principal term's entry shows exactly one emphasized locator and its remaining
      locators plain, and a `.ilg` carrying no conflicting-encapsulation warning for that
      entry's key.
- [x] AC2: In the HTML render of `examples/principal.qmd`, the index entry for the
      principal term carries exactly one locator link marked as principal, at the position
      of the principal mark, its other locator links unmarked — read structurally by
      `tests/htmlindex.py`.
- [x] AC3: In the LaTeX, HTML and gfm renders of `examples/principal.qmd`, the mark
      writing `mention="principal"` alongside `see=` or `see-also=` draws exactly one
      warning naming the mark and the `mention=` value it ignored, and emits the index
      output it would emit with the `mention=` attribute removed.
- [x] AC4: In the LaTeX, HTML and gfm renders of `examples/principal.qmd`, the mark
      writing an unrecognized `mention=` value draws exactly one warning naming the mark
      and the value, and indexes exactly as it would with the attribute removed. An empty
      `mention=` is unrecognized, not absent.
- [x] AC5: The gfm render of `examples/principal.qmd` matches its expected manifest line
      for line, and each principal-marked span in it carries its visible text and exactly
      the `data-` attributes for the mark's own attributes, `data-mention="principal"`
      included, and no other token.
- [x] AC6: The command the principal encapsulation names is defined with `\providecommand`
      in the preamble of the rendered `.tex` for `examples/principal.qmd`, and absent from
      the preamble of the rendered `.tex` for `examples/content.qmd`.
- [x] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1, T3, T5
- AC2 → T1, T4, T5
- AC3 → T1, T2, T5
- AC4 → T1, T2, T5
- AC5 → T1, T5
- AC6 → T3, T5
- AC7 → T5, T6, T7

## Tasks

- [x] T1: Fixtures `examples/principal.qmd` and `examples/principal-twin.qmd` with their
      expected manifests. The first carries a term marked in three places, one of them
      principal; a principal mark carrying `see=`; a mark with an unrecognized `role=`;
      and a plainly marked control term the new reports must stay silent on (the M11
      lesson). Terms and pages are distinct per slot (the M02 lesson). The twin is the
      same document with every role attribute removed. Their expected manifests are
      written inline in the suite's principal section, where every other fixture's are.
- [x] T2: `core.lua` gains `mention` and its recognized values; `marks.lua` derives the
      role once, before the back-end branch, with the two warnings — a role on a mark
      contributing no locator, and an unrecognized value, the empty string among them — so
      both fire in every format as the other mark warnings do.
- [x] T3: `latex.lua` and `passes.lua`: the principal encapsulation, its arbitration
      against the contested-key bookkeeping — `is_contested` and `record_contest` in
      `latex.lua` count cross-reference encapsulations alone, and `seen.plain` comes to
      mean "some mark of this key contributes a locator" rather than "emits no
      encapsulation" — and the preamble injection flag read by the Pandoc pass.
- [x] T4: `html.lua`: the principal locator link and its class; the role on the HTML mark
      record; `book.lua` carries it in the per-chapter record as an optional field with a
      named fallback, leaving the store version alone (the M14 lesson).
- [x] T5: The suite's principal section: copy `.ind`, `.ilg` and `.tex` to `$WORK` at the
      latex render before the pdf render removes them (the M15 lesson); the structural
      HTML check; the rendered-log pins passed through `warn-distinct`; the no-leak sweep;
      the preamble present/absent pair.
- [x] T6: Planted-defect entries for each check T5 adds, each planting a defect of
      the kind that check names and varying form as well as site — an encapsulation on the
      wrong locator, an encapsulation on none, a warning whose text is right but whose
      mark is wrong, and a mark warning suppressed in the back-end-less format alone, so a
      report that stops being format-neutral is caught. The four readers move to
      `tests/m20probes.py` so the self-test can re-run each against a mutated artifact;
      `tests/plantdefect.py` is not their home, since it plants defects in a
      moved-definition tree for the source-reading scans and these read rendered output.
- [x] T7: README section for `mention="principal"`: what an author writes, what each
      back-end prints, how to redefine the LaTeX command, and that an unusable or
      unrecognized value is reported. Add its authoring forms to the suite's normative
      supported-forms list and its sentences to a README claims array. Extend DESIGN.md's
      pass-through residue enumeration, which names `data-entry`, `data-see`,
      `data-see-also` and `data-sort`, to include `data-mention`.

## Work log

- 2026-08-21: created by /milestone-plan.
- 2026-08-21: plan gate chose `role="principal"` over a boolean `principal="true"` because a later role becomes another value rather than another attribute (GP5); falsified by evidence that no second role is ever wanted, which would leave the indirection dead weight.
- 2026-08-21: plan chose a redefinable `\providecommand` command over emitting `\textbf` directly because it gives an author styling control with no configuration (GP4) and matches the existing inject-only-where-used pattern; falsified by evidence that hyperref's encapsulation rewriting breaks an indirected command where a literal one survives.
- 2026-08-21: plan chose `.ind`/`.ilg` evidence over PDF-text evidence for the emphasis itself because `pdftotext` cannot see it; falsified by a PDF reader in the suite that can distinguish a bold locator from a plain one.
- 2026-08-21: criteria audit ran in full mode (user-facing tier) and returned findings on AC3, AC5 and the drafted README criterion; AC3 gained the named twin, AC5's residue clause was reworded to include the new attribute, and the README criterion was descoped to T7.
- 2026-08-21: implement gate renamed the attribute `role=` -> `mention=` (superseding the plan's spelling in the two entries above) after a Pandoc probe showed `role` emitted literally as an HTML attribute; AC3, AC4, AC5, Scope, T2 and T7 amended.
- 2026-08-21: implement gate chose narrowing contestation to cross-reference encapsulations over suppressing styling on shared keys, because a plain and a styled locator are makeindex's ordinary case; falsified by a makeindex version that rejects the pair rather than warning.
- 2026-08-21: amended-criteria audit ran in full mode and returned findings on all three amended criteria; AC3 and AC4 gained named formats and dropped the twin fixture from their promises, AC4 settled the empty value, AC5 was repinned on the expected manifest, and T6 gained a format-axis planted defect.
- 2026-08-21: T1 — `examples/principal.qmd` (three-page principal/plain spread, a role on a cross-reference mark, an unrecognized value, an empty value, a role-free control pair, and a principal locator on a key a cross-reference also marks) and its role-free twin; gfm render confirms Pandoc keeps `mention=""` as a present attribute, so the empty value is distinguishable from absence in the AST.
- 2026-08-21: T2 — `core.lua` gains `MENTION_ATTR`, `MENTION_ROLES`, `PRINCIPAL_COMMAND`/`PRINCIPAL_DEFINITION` and `HTML_PRINCIPAL_CLASS`; `marks.lua` gains `mention_role`, drawing the unrecognized-value report before the no-locator one so the two never both fire. `warn-distinct` pinned count 39 -> 41, and the scan confirms both new messages distinct and non-prefix.
- 2026-08-21: T3 — the role is applied at emission by `principal_encap` in `passes.lua`, on top of whichever shape contestation chose, and is deliberately absent from `mark_encap`, so a plain and a styled locator of one key are not rivals; `index.lua` injects `PRINCIPAL_DEFINITION` only where the flag is set. End-to-end evidence: the fixture's `.ind` reads `basilisk, \hyperpage{1}, \hyperxindexformat{\quartoindexprincipal}{2}, \hyperpage{3}` with 0 warnings in its `.ilg`, and `examples/content.tex` carries no definition.
- 2026-08-21: T3 — `examples/principal.qmd` gained `latex-clean: false`, since Quarto deletes the `.ind` and `.ilg` on a successful PDF render and they are AC1's evidence; the LaTeX aux family is now gitignored under `examples/`, which also closes the unignored-artifact item on the acceptance-suite candidate row.
- 2026-08-21: T3 — keeping the suite green required registering both fixtures in two existing rosters ahead of their own section: M14's dangling-target corpus (0 each, both targets naming a term the file marks) and M15's contested-key emission sweep (the folded-field shape, which the `gorgon` key writes). Suite 208 -> 211.
- 2026-08-21: T4 — a locator is now `{ target, role }` rather than a bare string, so a reordering cannot separate a role from its destination; the principal link carries `class="qi-principal"` and a Pandoc `Strong`, which is what makes it read as principal with no stylesheet, since the extension ships none. `book.lua` carries `role` as an optional field validated like `context` and left out of the store version. Rendered: `basilisk` prints three locators, the second `<a href="#qi-mark-2" class="qi-principal"><strong>2</strong></a>` and the others plain. Suite still 211.
- 2026-08-21: T5 — the M20 section: the `.ind`/`.ilg` reads (copied to `$WORK` at their own render), the structural HTML read, the per-mark log pins in all three formats with the twin as the zero-expectation control, a command-by-command comparison against the twin's own emission for the counterfactual, the gfm residue set stated exactly, and the preamble present/absent triple. Suite 211 -> 221.
- 2026-08-21: T5 — the twin comparison first passed vacuously: a regex for `\index{...}` matched only to the first `}` inside a folded cross-reference, truncating both sides' `gorgon` command before the encapsulation being compared, so the two read equal. Replaced with a brace counter — the brace-aware scanner the acceptance-suite candidate row already asks for, now built for this one reader.
- 2026-08-21: T7 — README gains a principal-mention section (what it prints in each back-end, how to redefine the LaTeX command, what an unusable or unrecognized value does), a seventh row in the supported-forms table, and a seventh point under where the back-ends differ; the form is in the suite's normative list and six documented claims are byte-pinned. DESIGN's pass-through residue enumeration now names `data-mention` and records why the attribute is not `role`. Suite 221 -> 223.
- 2026-08-21: T6 — the four readers extracted to `tests/m20probes.py` (behaviour-neutral: 223 checks before and after) and re-run by the self-test against twelve planted defects: the emphasis on the wrong page, on every locator, on none, leaked onto the role-free control, a conflicting-encapsulation warning in the transcript, the HTML emphasis on the wrong mention, its class dropped, its emphasis node dropped, a literal ARIA role in gfm, plumbing residue in gfm, the role inert, and the role reaching the control mark; plus `warn_discrimination` over both reports in all three formats. Self-test 248 -> 279.
- 2026-08-21: T6 — one plant was a no-op and the check was wrongly reported as failing to discriminate: gfm wraps a long line inside a tag, so a sed aimed at a whole `<span ...>text</span>` matched nothing. Every mutation now goes through `m20_plant`, which refuses a plant that changes no bytes.
- 2026-08-21: all seven tasks done; `tests/run-tests.sh` passes at 223 checks and `--self-test` at 279 (merge base 208 / 248). Status -> review.

## Decisions

### 2026-08-21: `mention=`, not `role=`

Pandoc data-prefixes an attribute name it does not know but emits `role` literally, so
`role="principal"` reaches every HTML-family output as a real ARIA role, and `principal`
is not a valid one — an artifact on every marked term, which IP2 forbids. `mention=`
probes clean as `data-mention` and is the word indexing practice uses for the occurrence
being marked. The twin fixture stays, as the instrument behind AC3 and AC4 rather than as
their promise.

### 2026-08-21: an empty `mention=` is unrecognized, not absent

`mention=""` is a value the author wrote. Reading it as absence would swallow a typo
silently, which is the class of thing every other report here refuses to do; it draws the
unrecognized-value warning and the mark indexes as though the attribute were gone.

## Review

**Evidence** — `tests/run-tests.sh --self-test`, run fresh on 969f1c4 at review: 279 checks, exit 0
(plain run 223, exit 0; merge base 208 / 248).

- **AC1** — the PDF render's `.ind` shows the basilisk entry with exactly one
  `\hyperxindexformat{\quartoindexprincipal}{2}`, the page the fixture puts the principal mark on,
  and exactly one plain `\hyperpage` for each of pages 1 and 3; the role-free control entry carries
  the command nowhere. The `.ilg` contains no `Conflicting entries` line and its own summary reports
  0 warnings, read as a number rather than by substring absence.
- **AC2** — read structurally by `tests/htmlindex.py`: basilisk's three locator links are
  (plain, class + `<strong>`, plain) in that order, the control entry's two are both plain, and the
  mark whose role was dropped contributes no locator at all.
- **AC3** — the dropped-role report fires exactly once in each of the LaTeX, HTML and gfm renders,
  naming the mark and the attribute that displaced its locator, and zero times in the twin.
- **AC4** — the unrecognized-value report fires exactly twice per format, once naming
  `("paramount")` and once `("")`, and zero times in the twin. Both criteria's counterfactual is
  the same check: of 9 emitted `\index` commands, the fixture and its role-free twin differ on
  exactly the two the role is meant to change and agree on the other seven.
- **AC5** — the gfm render's role-carrying spans are exactly the five the fixture writes, byte for
  byte; no span carries a literal `role=`, and no `qi-`, `\index{` or command token reaches the
  format.
- **AC6** — `\providecommand*\quartoindexprincipal` is present in the fixture's rendered preamble
  and absent from both `examples/content.tex` and the twin's.
- **AC7** — both suite modes exit 0, as above.

**Discrimination.** Twelve planted defects, each caught: the emphasis on the wrong page, on every
locator, on none, leaked onto the control; a conflicting-encapsulation warning in the transcript;
the HTML emphasis on the wrong mention, its class dropped, its emphasis node dropped; a literal ARIA
role in gfm; plumbing residue in gfm; the role inert; the role reaching the control mark. Both
reports also pass `warn_discrimination` (missing and duplicated) in all three formats.
