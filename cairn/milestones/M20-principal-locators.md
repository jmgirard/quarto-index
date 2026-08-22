# M20: A term's principal discussion prints as its principal locator

- **Status:** in-progress
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

Evidence stops at the `.ind` and the `.aux`, which together settle that a key's locators
carry one uniform encapsulation and that the role was registered from the page its mark
sits on. That the registered page then prints emphasized is exercised under T9 and carried
on a ROADMAP candidate row rather than by a criterion, because `pdftotext` cannot see
emphasis — a deliberate GP6 trade, recorded rather than left implicit.

**Out:** page ranges, and a range carrying this role on both its ends → M21. Roles beyond
`principal` (a defining passage, an illustration) → ROADMAP candidate row; the attribute
is shaped to take them as values, and nothing here anticipates one. Shipping CSS for the
HTML class → out of GP3's install story; the locator carries Pandoc-level emphasis so it
reads correctly with no stylesheet at all. Whether a mark's attributes should ride into
pass-through formats at all → the standing ROADMAP row, unchanged by the new attribute.

## Acceptance criteria

- [ ] AC1: The PDF render of `examples/principal.qmd`, begun with its `.ind`, `.ilg` and
      `.aux` absent, produces: a `.ilg` whose own summary reports zero makeindex warnings;
      a `.ind` — read with makeindex's line wrapping collapsed and every group argument
      delimited by brace counting — in which the `basilisk` entry is exactly three
      `\hyperxindexformat{\quartoindexlocator{...}}` groups of one page each, naming one
      identifier between them, no two of those pages consecutive; the `gorgon` entry is
      exactly one such group of one page, carrying `\see{basilisk}{}` folded into the
      entry's printed text ahead of it; and the role-free `faun` entry carries no such
      group at all; and an `.aux` carrying exactly
      four `\quartoindexprincipalpage` lines whose identifiers are exactly the four the
      `.ind`'s `\quartoindexlocator` groups name — those of `basilisk`, `gorgon`, `imp` and
      `kraken`, the four marks writing `mention="principal"` that contribute a locator —
      each line's page being one its own group lists, and `basilisk`'s being the middle of
      the three, where the fixture puts its principal mark.
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
- [ ] AC5: In the gfm render of `examples/principal.qmd`, a scan of the rendered
      file for spans carrying the `index` class enumerates thirteen — one for
      every index mark the fixture writes except the entry-less one, which
      indexes nothing and is removed — and those spans are, in document order
      and byte for byte, the rows of an expected manifest derived by hand from
      the fixture source, each row being that mark's visible text plus exactly
      the `data-` attributes for the mark's own attributes,
      `data-mention="principal"` among them where the mark writes it. No `qi-`
      token, `\index` command, principal-encapsulation command or literal
      `role=` attribute appears anywhere in the file.
- [ ] AC6: In the region before `\begin{document}` of the rendered `.tex` for
      `examples/principal.qmd`, each of `\quartoindexprincipal`, `\quartoindexlocator`,
      `\quartoindexregister` and `\quartoindexprincipalpage` is defined exactly once, with
      `\providecommand*`; the only further control sequence whose name begins `quartoindex`
      defined there is `\quartoindexseeboth`, which the fixture's both-targets mark already
      required before this milestone; and no `\csname quartoindex` occurs in the region at
      all, so a definition cannot hide behind a name built at expansion time. In the same
      region of the rendered `.tex` for `examples/content.qmd`, which carries the extension's
      `\makeindex[intoc]` setup, none of the four is defined — `\quartoindexseeboth` belongs
      to the cross-reference channel and is no part of this subsystem. Both files are present
      and each carries exactly one `\begin{document}`.
- [x] AC7: `tests/run-tests.sh` and `tests/run-tests.sh --self-test` both pass.

## Coverage

- AC1 → T1, T3, T5, T8
- AC2 → T1, T4, T5
- AC3 → T1, T2, T5
- AC4 → T1, T2, T5
- AC5 → T1, T5
- AC6 → T3, T5, T8
- AC7 → T5, T6, T7

## Tasks

- [x] T1: Fixtures `examples/principal.qmd` and its role-free twin (M02 and M11 lessons).
- [x] T2: `core.lua` gains `mention`; `marks.lua` derives the role once, with two reports.
- [x] T3: `latex.lua`/`passes.lua`: the encapsulation, its arbitration against contestation.
- [x] T4: `html.lua`'s principal link and class; `book.lua`'s optional field (M14 lesson).
- [x] T5: The suite's principal section — `.ind`/`.ilg`/`.tex`, HTML, log pins, gfm manifest.
- [x] T6: A planted defect per T5 check, varying form and site; readers in `m20probes.py`.
- [x] T7: README section and byte-pinned claims; DESIGN's pass-through residue enumeration.
- [ ] T8: The typeset-time channel (D-007; mechanism and validation in the archived RR01).
      Every locator mark of a key carrying a principal mark emits one uniform per-key
      `\quartoindexlocator{<ordinal>}`, so two locators of a key can never differ and the
      conflict is unreachable by construction; the ordinal is assigned in document order by
      the pass that already collects keys. The principal mark also emits
      `\quartoindexregister{<ordinal>}`, writing the ordinal and `\thepage` through
      `\protected@write\@auxout` — the mechanism `\@wrindex` itself uses, so the two agree.
      At `\printindex` the injected code splits the page list, wraps registered pages in
      `\quartoindexprincipal` and calls the real `\hyperpage` per item, sniffing its
      argument's token class rather than a hyperref internal. Other keys emit as today. `examples/principal.qmd`
      gains a filler page between each `basilisk` mark so its locators cannot fold into a
      range the registry could not match. The AC1/AC6 readers join `tests/m20probes.py`:
      the `.ind` read with wrapping collapsed and groups brace-counted, both `.tex` reads
      bounded to the preamble and guarded against a missing file (review F7, F10).
- [ ] T9: The regressions IP2's forever clause earns, and the record. A new fixture
      `examples/principal-cases.qmd` whose preamble redefines `\quartoindexprincipal` to a
      marker `pdftotext` can read — both the author-redefinition regression and what makes
      the emphasis legible — carrying a plain and a principal mark of one key ON ONE PAGE
      (the shape the milestone died on), a principal mark in a footnote, a registered page
      folded inside a range, and a role-free control; its PDF text and `.ilg` are read. It
      is separate so AC5's hand-derived manifest is left alone. Plants, form as well as site
      (T6's rule): two ordinals on one key; a registry line deleted, duplicated and moved,
      one in the `\csname` form; an encapsulation leaked onto the role-free key; and for AC6
      a definition below `\begin{document}` and one emitted as `\def` — the axis review F4
      records as unplanted. Correct `latex.lua`'s comments and the ROADMAP premise they
      echo, and give README the one silent degradation.

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
- 2026-08-21: review returned M20 to in-progress. Two floor-qualifying findings: a principal and a plain mark of one key on one page make `quarto render --to pdf` exit 1 with "error generating index" (verified at the gate by direct render), which is the IP2 break M15 exists to eliminate and which the plan gate's makeindex-in-isolation probe missed; and AC5's first clause, a line-for-line gfm manifest, was never implemented. AC5 unticked. Eleven further findings carried in the Review section for triage. Defect returns on this milestone: 1.
- 2026-08-21: resumed after the review return. The break was reproduced, then probed further: makeindex conflicts on ANY encapsulation difference for one key on one page — a bare `\indexentry{cats}{1}` beside `\indexentry{cats|quartoindexprincipal}{1}` warns, while two identical encapsulations fold silently — so per-locator styling through its encap channel is impossible whatever the extension emits, and no emission-level repair exists. Implement gate routed the design question to /milestone-brief and chose the format-neutral findings for repair here.
- 2026-08-21: review F2/F11/F12/F9 repaired. `mention_role` now takes a blocker naming every SURVIVING cross-reference attribute rather than the first declared one, so a target about to be dropped as a self-reference no longer displaces a role (verified against the pre-fix filter: `imp` drew the displacement report and the drop report together, and now draws only the drop), or `unindexed` for a mark that indexes nothing, whose role was dropped in silence. The HTML control now tells a missing entry from an entry with no locators. Fixtures gained `harpy` (both attributes), `imp` (self-referential target) and an entry-less mark; `warn-distinct` 41 -> 42. Suite 223, self-test 279 -> 282.
- 2026-08-21: amendment, AC5 — the criterion promised the gfm render "matches its expected manifest line for line", which taken literally is a 72-line copy of Pandoc's own line-wrapping and is the snapshot the suite's ORACLE RULE and D-004 both refuse; the mini gate chose narrowing it to the render's index spans. Amended-criteria audit ran in full mode twice with two fresh readers (the second on wording revised from the first's findings) and returned seven then seven: "line for line" lost its referent, the reader sorted away the order it promised, the domain was ambiguous between source marks and rendered spans, the manifest defined rather than compared, the document-wide clause was dropped, and no plant covered completeness or order. All folded in, and the final wording went to the user rather than a third revision. The fixture now renders gfm with `wrap: none` so a span is never broken across lines.
- 2026-08-21: T5/T6 — AC5 implemented: manifest 9 in the suite lists all thirteen spans in document order, hand-derived from the fixture; the reader compares byte for byte without sorting or normalizing, enumerates a span whose visible text carries nested inline markup, and pins the count to the fixture's own marks. The render is deleted before the run rewrites it, so no check reads a stale artifact. Four new plants: a dropped mark, an extra mark, two transposed, and the nested markup stripped. Fixtures gained `kraken`. Suite 223, self-test 282 -> 286.
- 2026-08-21: session close. Three of the return's floor findings are settled: F2, F11, F12 and F9 repaired, and AC5 implemented as amended. F1 is not repairable at the emission layer — the probe above settles that makeindex rejects ANY encapsulation difference for one key on one page — so it goes to /milestone-brief as an ip-touching escalation. F4-F8, F10 and F13 stand for triage at the next review gate; most of them are LaTeX-side and their fate depends on the escalated answer. Status stays in-progress.
- 2026-08-21: blocked on RB01 — whether the LaTeX back-end can realize a per-locator role at all, and what to do if it cannot.
- 2026-08-21: RB01 raised and RR01 ingested. The review confirmed the impossibility (question 1) and then falsified the brief's own premise that no mechanism was affordable: it built the deferred-styling subsystem and validated it through Quarto's pipeline, same-page pair included, at exit 0 with zero makeindex warnings. Recommendations triaged — 1 apply (T8), 2 apply (T9 + the ROADMAP correction), 3 apply (recorded below), 4 consider (README line in T9; the whole-range question widened the locator-control candidate row), 5 consider (the fallback, not taken), 6 and 7 reject, matching the session's own reading. Promoted to D-007.
- 2026-08-21: AC1 and AC6 are now stated over an artifact the chosen mechanism no longer produces — the emphasis leaves the `.ind` entirely and appears at typeset time — so both need the step-6 amendment gate at the next implement session, before T8 is worked. Flagged here rather than amended at ingest.
- 2026-08-21: AC1 and AC6 amended at the step-6 mini gate; the user chose to hold the criteria set rather than widen it, so AC1 stays inside the render's own working files and the end-to-end typeset leg goes to T9 and a candidate row. Scope's evidence paragraph, falsified by D-007 (the `.ind` no longer carries any role information), was restated with it. Coverage gained T8 on both, and Tasks was compressed in one pass to hold the 150-line cap, T1-T7's detail staying in this log.
- 2026-08-21: amended-criteria audit ran in full mode twice with two fresh readers and returned ten then thirteen. Round 1: AC1's three `basilisk` marks are on consecutive pages, so the uniform encapsulation folds them to `1--3` and the criterion would have passed green on a render printing no emphasis at all; "the principal term" named four candidates; the control clause was vacuous; there was no freshness pin; and AC6's "every command the subsystem defines" was an unenumerable domain whose blanket `\providecommand` the registry csnames cannot satisfy. Round 2: AC6 was outright unsatisfiable, since `harpy` makes the fixture inject `\quartoindexseeboth`, which the criterion forbade; the `.ind` group argument wraps across lines, the shape a reader has already been caught by once here; the `.aux` count needed its referents pinned, not just its cardinality; and Scope's GP6 trade was falsified. All folded in; the final wording went to the user rather than a third revision.
- 2026-08-21: T8's commands are named `\quartoindexlocator`, `\quartoindexregister` and `\quartoindexprincipalpage`, following the extension's existing `\quartoindex` prefix rather than RR01's `\qiloc` sketch; internals stay `\qi@`-prefixed `\def`s inside `\makeatletter`. The mechanism was probed on this toolchain before the gate: a same-page plain+principal pair at zero makeindex warnings, correct footnote registration, and `cats, [P:1], 2` with the emphasis command redefined to a marker.
- 2026-08-21: T8 checkpoint, half done and green on the plain suite. The typeset-time channel is built: `core.lua` carries the whole injected subsystem (the registry reader, the shipout-deferred registration, the locator command that splits a page list and wraps registered pages, and the `\qi@` helpers, which sniff their argument's token class rather than naming a hyperref internal); `latex.lua` assigns one ordinal per principal-carrying key in document order; `passes.lua` gives EVERY locator mark of such a key that same ordinal and emits the registration beside the principal mark's own `\index`. `examples/principal.qmd` gained filler pages so its three `basilisk` marks are non-adjacent. New AC1 and AC6 readers in `tests/m20probes.py`, the twin comparison strengthened from a set to a positional multiset (a set collapsed `basilisk`'s three commands into one row and would have passed a filter that encapsulated only the principal mark), and the `.ind` plant set replaced with eleven aimed at the two properties that succeeded the emphasis-in-the-`.ind`. Plain suite 223 -> 226; the self-test run is not yet finished, so `--self-test` is UNVERIFIED at this checkpoint.
- 2026-08-21: two clauses of the just-amended criteria were disproved by the artifact and corrected against it. makeindex merges only a RUN of consecutive pages under one encapsulation, so `basilisk`'s non-adjacent locators print as three groups rather than one — which shows the uniform identifier three times over and is better evidence than the merged form both audit rounds assumed. And the subsystem's own `\qi@emit` helper names `\quartoindexprincipal` in its body, so AC6 binds DEFINING FORMS naming a `quartoindex` control sequence, plus the absence of `\csname quartoindex`, rather than occurrences of the string; its control clause dropped `\quartoindexseeboth`, which belongs to the cross-reference channel and which the role-free twin legitimately carries.
- 2026-08-21: T9 in progress — `examples/principal-cases.qmd` written (same-page plain/principal pair, a principal mark in a footnote, a registered page inside a makeindex range, a role-free control, and a preamble redefining the emphasis to a marker `pdftotext` can read). `latex.lua`'s two comment blocks corrected: makeindex warns at exit 0 and writes a correct `.ind`, and Quarto alone fails the render on a regex over the transcript; and the claim that a styled and a plain locator are not rivals is withdrawn as false. The ROADMAP premise was already corrected at the RR01 ingest. README's degradation line, the redefinition recipe (whose `\newcommand*` may error where the extension's definition lands first — unmeasured) and the T9 suite section are not written yet.

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

### 2026-08-21: the `.ilg` warning count is the stable oracle, not Quarto's exit code

RR01 pinned Quarto's escalation to `findIndexError`, which fails a render when
the regex `/^\s\s\s--\s/` matches the makeindex transcript — an implementation
detail, not documented API, and one a future Quarto could widen or drop.
AC1 already reads the `.ilg`'s own warning count as a number rather than
searching for a substring or trusting the exit status, and that is the evidence
base this class of check keeps (RR01 recommendation 3).

### 2026-08-21: the fallback if the subsystem is refused

If the typeset-time channel is ever judged too much LaTeX for this extension to
carry, the one remaining disposition is that the LaTeX back-end reports the role
as unrealized and indexes the mark plainly, which IP1 licenses in so many words
and which leaves the HTML realization whole. Removing `mention=` altogether is
strictly worse: it discards a working back-end to keep the two symmetric, which
IP1 says they need not be. Shipping the colliding emission with the failure
documented is not eligible at all — D-003 classifies the pair as the extension's
own incorrect output, so IP2 governs and documentation cannot discharge it.

## Review

**Findings (three fresh-context reviewers).** The prior-review lens reported no prior-review
evidence bearing on this diff, having checked every archived `## Review` section and `LESSONS.md`;
a probe found the repo has no PR-comment surface. The history lens returned one finding. The
diff-bug lens returned thirteen. Two qualify under the return floor, so the gate returns the
milestone rather than triaging the rest here; every finding is carried below for triage at the
next gate.

**F1 (floor return, and the history lens's one finding independently) — a principal mark and a
plain mark of one key on one page break the render.** `mark_encap` in `latex.lua` excludes the
role, so contestation never sees the pair and `passes.lua` emits `\index{cats}` beside
`\index{cats|quartoindexprincipal}`. Verified directly at the gate, not inferred: a Quarto PDF
render of two marks of one term in one sentence, one principal, gives
`ERROR: compilation failed- error generating index` and `quarto render` exits 1, with
`Conflicting entries: multiple encaps for the same page under same key` in the `.ilg`. hyperref
encapsulates the plain locator as `|hyperpage` too, so the collision is intrinsic once a styled
locator shares a page with any other. This is the IP2 break M15 existed to eliminate and D-003
assigns to the extension. The plan gate's premise — recorded on the ROADMAP as "every misuse here
is a warning at exit 0, so neither carries a break-the-document risk" — was measured on makeindex
in isolation and is wrong about Quarto. The milestone's own recorded falsifier for the clash-rule
choice is therefore already spent. No emission-level repair is obvious: every locator carries an
encapsulation under hyperref, so a key cannot mix a styled and an unstyled locator on one page at
all, which makes this a design question rather than a patch.

**F2 (floor-adjacent, real defect) — a mark whose only cross-reference is dropped as a
self-reference loses its role and draws a false report.** `mention_role` is called before the
self-reference drop, so `[basilisk]{.index mention="principal" see="basilisk"}` emits a real plain
locator while printing "this mark has no locator to emphasize" immediately followed by the
self-reference drop's own report — two consecutive reports contradicting each other about one mark,
the defect class M18 exists to remove.

**F3 (floor return) — AC5's first clause is not implemented.** See the AC5 line above.

**F4–F13, carried for triage at the next gate** (not floor-qualifying):
F4 T6's promised "warning text right but mark wrong" axis is never planted, and the AC6 and
README checks have no planted defect at all. F5 the book sidecar's new optional `role` field has
no fixture, so its round-trip is untested. F6 the `.ilg` mutation bypasses `m20_plant`, contra its
own comment, and fails the reader for two reasons at once. F7 the AC6 negative grep has no
existence guard, so it passes vacuously if `content.tex` is absent, and both AC6 greps read the
whole file rather than the preamble. F8 the M15 emission sweep's new `ALLOWED` rows are inert —
the sweep runs before M20 renders either fixture, so on a clean tree M20's emission is never
swept. F9 the HTML probe's cockatrice control returns None when no entry is found, so it cannot
fail if its domain empties. F10 the PDF is checked by exit status alone, with no size check and no
removal of a stale `.ind`/`.ilg` before the render, so AC1's evidence has no freshness pin. F11
`mention="principal"` on a mark with no source entry drops the role silently, though Scope
describes the report as covering any mark that can contribute no locator. F12 the no-locator
warning names only the first cross-reference attribute. F13 README's redefinition recipe
("yours is kept") is byte-pinned as a normative claim but never exercised by a render.

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
- **AC5** — FAILS as written. Its second clause is verified (the role-carrying spans are exactly
  the five the fixture writes, byte for byte; no span carries a literal `role=`, and no `qi-`,
  `\index{` or command token reaches the format), but its FIRST clause — "matches its expected
  manifest line for line" — is not implemented: no gfm manifest exists for either fixture anywhere
  in the suite, and T1's claim that they are "written inline in the suite's principal section" is
  inaccurate. Unticked.
- **AC6** — `\providecommand*\quartoindexprincipal` is present in the fixture's rendered preamble
  and absent from both `examples/content.tex` and the twin's.
- **AC7** — both suite modes exit 0, as above.

**Discrimination.** Twelve planted defects, each caught: the emphasis on the wrong page, on every
locator, on none, leaked onto the control; a conflicting-encapsulation warning in the transcript;
the HTML emphasis on the wrong mention, its class dropped, its emphasis node dropped; a literal ARIA
role in gfm; plumbing residue in gfm; the role inert; the role reaching the control mark. Both
reports also pass `warn_discrimination` (missing and duplicated) in all three formats.
