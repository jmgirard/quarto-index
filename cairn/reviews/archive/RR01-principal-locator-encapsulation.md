# RR01: Per-locator emphasis in the LaTeX index back-end (M20)

- **Date:** 2026-08-21
- **Answers:** `cairn/reviews/RB01-principal-locator-encapsulation.md`
- **Reviewer basis:** every probe below was run fresh for this review on the
  user's toolchain (makeindex 2.18 / TeX Live 2026 via TinyTeX, Quarto 1.10.18,
  pdflatex), not taken from the milestone's records. Probe files live under the
  session scratchpad (`scratchpad/mi`, `scratchpad/probe`, `scratchpad/qprobe`);
  the failing `.qmd` was written to `examples/rb01-samepage.qmd`, rendered, and
  removed with its artifacts, leaving the tree clean.

## 1. Is any emission-level rule sufficient?

**No. Definitively.** The argument has three legs, each verified here.

**Leg 1 — makeindex's merge unit.** An `.idx` line is a triple
(key string, encapsulation string, page). Entries with the same key string
merge into one `\item`; within it, locators group by encapsulation string.
Reconfirmed by hand: `\indexentry{cats}{1}` beside
`\indexentry{cats|quartoindexprincipal}{1}` draws the conflict warning
(bare-versus-encapsulated counts as a difference); two identical
`\indexentry{cats|hyperpage}{1}` fold silently; two identical *parameterized*
encapsulations `cats|qiloc{k1}` on one page also fold silently. So the
conflict predicate is exactly: same key, same page, any byte difference in the
encapsulation string.

**Leg 2 — the four fields are all the filter has, and three of them split the
entry.** The filter controls key, printed field, sort field, encapsulation.
Distinguishing the principal mark through the key, the printed field, or the
sort field makes makeindex file it as a *different entry* (a second `\item`
line, or a subentry) — a visibly corrupted index, worse than the defect. That
leaves only the encapsulation, and by Leg 1 two locators of one key can carry
different encapsulations only if they are guaranteed never to share a page.

**Leg 3 — page-coincidence is not decidable at emission, and no page-dependent
emission channel exists.** The filter runs before typesetting; any two marks of
a key can land on one page under reflow (font, geometry, engine), and no
document property visible to a Lua filter bounds this. The one theoretical
escape — an encapsulation that *expands to something page-dependent at write
time*, so that same-page rivals would become byte-identical — is closed by
`\index` itself: makeidx/hyperref `\@wrindex` writes the argument after
`\@sanitize` has made its characters inert (verified in `hyperref.sty` lines
7976–8035: the argument travels as catcode-other text into
`\protected@write`), so nothing the filter puts in an `\index` argument can
expand differently per page.

Therefore every rule realizing per-locator emphasis purely through what
`\index{...}` commands say must emit differing encapsulations for one key,
and any such rule has a document that puts the pair on one page. The only
uniformly conflict-free discipline is "identical encapsulation for every
locator of a key document-wide" — which carries zero per-locator information.
Per-locator emphasis in this back-end requires a second, typeset-time channel.
The rest of this report rests on that.

(The brief's framing is confirmed on one more point: the conflict is not
hyperref's doing. It reproduces on hand-written `.idx` files with no hyperref
rewriting at all.)

## 2. The deferred-styling mechanism

**Sound — with one amendment that removes its hardest sub-problem — and I
validated it end to end, including through Quarto's own PDF pipeline.** The
amendment: do not try to reconstruct the entry's identity inside `theindex`
(the shape 2a asks about). Put the identity *in the encapsulation argument*.
Every locator mark of a key that carries a principal mark emits
`\index{<key>|qiloc{<id>}}`, where `<id>` is a filter-assigned csname-safe
ordinal (`qi1`, `qi2`, …) for that key — identical across the key's marks, so
by Q1's Leg 1 no conflict is possible, while *different keys* may differ freely
(conflicts are per key). The principal mark additionally emits one injected
command that does `\protected@write\@auxout{}{\string\qiprincipal{<id>}{\thepage}}`.
At `\printindex` time, `\qiloc{<id>}{<pages>}` looks each page up in the
registry `\csname qi@p@<id>@<page>\endcsname` and wraps the hits in
`\quartoindexprincipal`.

Validated fresh, twice:

- **pdflatex directly** (`scratchpad/probe/d3.tex`): imakeidx + hyperref, a
  plain and a principal mark of one key *on one page*, a plain mark a page
  later, a principal-only key, and a principal mark inside a footnote. Two
  passes plus makeindex: zero makeindex warnings, zero LaTeX errors; a
  marker-variant render (`\quartoindexprincipal` redefined to print `(P:#1)`)
  shows `cats, (P:1), 2 · dogs, (P:3) · ghoul, (P:3)` — emphasis on exactly
  the registered pairs, including the same-page pair the current design dies
  on (the two same-page locators fold into one emphasized locator, which is
  the book convention), and including the footnote registration. All five
  locators carry full-size hyperlink annotations to the right page anchors
  (checked in the PDF's annotation objects with compression off).
- **Quarto's pipeline** (`scratchpad/qprobe/mech.qmd`): the same subsystem via
  `include-in-header`, raw-latex marks, `quarto render --to pdf`. Exit 0, the
  `.ilg` reports 0 warnings on the same-page pair, and the marker variant
  confirms the emphasis landed — so Quarto's default pass structure
  (latex → makeindex → latex) is already sufficient. No pass beyond what
  Quarto runs today is needed: the registry is complete after pass 1, and
  pass 2 typesets the index against it, exactly the schedule `\label`/`\ref`
  already impose.

Answers to the four sub-questions as posed:

**a. Entry identity.** As specified in the brief — uniform encap
document-wide, identity recovered inside `theindex` — the mechanism is
unsound, and I would reject that variant. `theindex`'s `\item` takes no
argument (the entry text merely follows it), so capturing "which entry am I
in" means rebinding `\item` to a delimited scanner reading to the next
`\item`/`\subitem`/`\indexspace`, and then mapping the *printed* text (post
sort-key split, post three-level fold, post cross-reference folding, with
nested markup) back to the *filing* key. Fragile at every joint. The keyed
encapsulation dissolves the whole question: the id rides in the `.ind` next to
the pages, nothing is reconstructed, and the id is an opaque ordinal so no
escaping of key text ever enters a `\csname`. This costs one extra brace group
per locator of the affected keys and nothing anywhere else.

**b. `\thepage` agreement.** Yes. The registration must be written with
`\protected@write\@auxout` — the *same* deferred-to-shipout mechanism
`\@wrindex` itself uses for the `.idx` (verified in the hyperref source; both
writes are whatsits in the same box, shipped on the same page). Footnote case
verified empirically above. Floats and page boundaries follow by the same
mechanism: wherever the `\index` whatsit ships, the adjacent registration
whatsit ships with it. The one known divergence — an `\index` inside a
`\caption` re-processed in a List of Figures — duplicates both writes equally
and is a pre-existing quirk of the current emission, not a new one.

**c. hyperref / imakeidx / Quarto.** All three verified compatible above.
hyperref rewrites the encap `qiloc{qi1}` into
`hyperxindexformat{\qiloc{qi1}}` (source: the `\HyInd@@@wrindex` non-paren
branch reassembles the full encap inside the braces), and
`\hyperxindexformat` then calls `\qiloc{qi1}{\HyOrg@hyperpage{<pages>}}` —
the mechanism intercepts that wrapped list, splits it per page, and calls the
real `\hyperpage` per item, so every locator stays a working hyperlink.
imakeidx is inert here (it only manages index files and `\printindex`).
Quarto: two latex passes suffice and Quarto runs them; `latex-clean` and the
suite's `.ind`/`.ilg` evidence path are untouched. Two real costs to flag:
(i) the probe's dispatch keys on hyperref's *internal* name
`\HyOrg@hyperpage` — a production version should instead test "is the first
token of my second argument a control sequence" generically, falling back to
a bare page list, which removes the name coupling and also covers a document
where hyperindex is off; (ii) makeindex folds 3+ consecutive pages under one
encap into a range — verified: `\qiloc{cats}{1--3}` — and a registry lookup
on the string `1--3` misses, so a principal page *inside* a range renders
unemphasized, silently. Note this is close to typographically forced (no
convention bolds one page inside a printed range) and page ranges are M21's
scope; the honest disposition is to document it now and decide in M21 whether
a range containing a registered page is emphasized whole.

**d. Author redefinition.** Yes — strictly better than the current emission.
`\quartoindexprincipal` is applied by the extension's own typeset-time code,
so it is no longer subject to hyperref's encap rewriting at all;
`\providecommand` semantics ("yours is kept") are preserved unchanged.
Verified: the marker-variant renders redefine it and the redefinition is what
prints.

**Cost summary.** Preamble injection grows by roughly 25 lines (injected only
into a document with a principal mark, the established pattern); the Lua side
needs the set of keys carrying a principal mark before emission — which the
existing CollectKeys pass already provides — an ordinal per such key, the
`qiloc` encap on those keys' locator marks only (every other key's emission is
byte-identical to today), and one registration command after each principal
mark. No new pass, no new toolchain step, no user configuration.

## 3. Is there a third mechanism?

Surveyed as the brief lists them:

- **makeindex `.ist` facilities** — available (makeindex is the documented
  tool), but the style file controls only delimiters, headings and page-number
  composition per encap; it has no per-page conditional and no
  conflict-resolution semantics. Cannot express this. **No.**
- **A different encapsulation discipline** — this is the keyed-uniform
  encapsulation of Q2-as-amended, and it is the answer; it is not a rival to
  the deferred mechanism but its transport. Within GP3 (plain makeindex +
  injected `\providecommand`s). **Yes — as part of Q2.**
- **imakeidx features** — per-index options, `splitidx`/`xindy` hand-off,
  automatic runs; nothing per-locator. **No.**
- **splitidx** — separates *indexes*, not locator styles. **No.**
- **xindy/texindy** — the one tool whose model genuinely fits: location
  attributes (`:attr`) with merge/markup rules express
  definition-versus-usage, including same-page resolution by attribute
  priority. But: verified absent from the user's TinyTeX (no `xindy`, no
  `texindy` binary — TinyTeX ships neither by default, so GP3's "bundled in
  mainstream distributions" holds only for full TeX Live installs);
  effectively unmaintained; its hyperref interoperability is the classically
  fragile spot; and selecting it requires the *user* to set
  `latex-makeindex: texindy` in document metadata — the extension, a Pandoc
  filter, cannot reach Quarto's render options (they are resolved before
  pandoc runs). A feature that only works after the user reconfigures the
  toolchain is not this extension's feature. **Reject.**
- **upmendex** — in TeX Live but likewise absent from this TinyTeX; it is a
  makeindex-compatible reimplementation and there is no reason to expect a
  different conflict rule (unverified here for want of the binary); same
  user-configuration barrier via `latex-makeindex`. **Reject.**
- **A second index entry** (shadow key sorted adjacent) — produces a second
  visible entry line; corrupts the index. **Reject.**

So: no third mechanism outside Q2's, and one genuine but out-of-reach
alternative (xindy) that fails GP3-in-practice and the
extension-cannot-set-it barrier.

## 4. Disposition

The premise "no mechanism is sound at acceptable cost" did not survive the
probes: Q2's amended mechanism is sound, validated through the real pipeline,
and its cost is moderate and contained. My ranking:

1. **(d) Build the deferred-styling subsystem** (keyed uniform encapsulation +
   aux registry), scoped to keys that carry a principal mark. It realizes the
   milestone's stated goal in both back-ends, stays inside GP3 (injected
   `\providecommand`s and plain makeindex — the established pattern), preserves
   hyperlinks and author redefinition, and eliminates the IP2 break by
   construction (identical encapsulation per key ⇒ the conflict is
   unreachable, not merely unexercised). Its two honest weaknesses — one
   hyperref-internal token in the dispatch (hardenable, see 2c) and the silent
   loss of emphasis inside a folded page range — are documentable under GP2
   and small against the alternatives. It is more LaTeX than this extension
   has shipped before, and it earns its regression tests (same-page pair;
   footnote; range fold; redefinition) under IP2's "forever" clause.
2. **(a) Drop the LaTeX realization** — the right fallback if the project
   judges the subsystem's hyperref coupling outside its risk appetite. IP1
   explicitly licenses it, HTML keeps the feature whole, and it is honest.
   It costs two acceptance criteria and the milestone's goal, and it leaves
   the LaTeX index unable to say the one thing print indexes conventionally
   say. Take it only if (1) is refused on cost.
3. **(c) Remove `mention=` entirely** — strictly worse than (a): it discards
   a working, verified HTML realization to keep the back-ends symmetric,
   which IP1 says they need not be.
4. **(b) Keep the emission and document the collision** — **not eligible, and
   I agree with the session's reading.** GP2's "known failure modes
   documented" governs failures the extension's *correct* output meets in a
   user's toolchain; D-003 says output the documented index tool provably
   cannot process is *incorrect emitted output*, and this pair is provably
   unprocessable (Quarto exit 1, reproduced fresh at this review). Documenting
   it would document an IP2 violation, and IP2 is inviolable. Reject.

**Named choice: (1).** If a scope decision is wanted first, (1) with the range
question deferred to M21 is self-contained.

## 5. Is the plan gate's premise recoverable?

**No — and the escalation mechanism is now pinned precisely.** Quarto's
`makeIndexIntermediates` (quarto.js, `findIndexError`) reads the `.ilg` after
running the index engine and fails the render if the regex
`/^\s\s\s--\s(.*)/m` matches — that is, if *any* makeindex warning
continuation line appears, whatever the exit code (makeindex exits 0 here;
verified). There is no Quarto option that narrows this: no warning allowlist,
no severity threshold. The levers that exist are all blanket:

- `latex-makeindex-opts` could pass `-t <other>.log`, so the `.ilg` Quarto
  looks for never exists and the check is skipped entirely;
- `pdf-engine: latexmk` hands index generation to latexmk, which ignores
  makeindex warnings;
- `latex-makeindex: <wrapper>` could launder the transcript.

Every one of these (i) masks the genuine M15-class collision along with this
one — the brief's own disqualifier, (ii) is user-side document metadata the
extension cannot set from a Pandoc filter, and (iii) is exactly "managing a
toolchain failure" — except that D-003 has already ruled this pair is not a
toolchain failure but the extension's own incorrect output, so there is
nothing here for GP2's documentation surface to absorb. No narrower lever
exists in the installed Quarto. Reject the recovery; the premise is spent.

## 6. Is the emission correct at all?

**Yes, the collision aside.** `\index{key|command}` with a
`\providecommand*`-defined one-argument command is the standard makeindex
encapsulation idiom, and the hyperref interaction is exactly as intended:
hyperref rewrites the encap to `hyperxindexformat{\quartoindexprincipal}`,
and `\hyperxindexformat{#1}{#2}` (hyperref.sty line 7928) evaluates
`#1{\HyOrg@hyperpage{#2}}` with plain `\hyperpage` disabled inside — so the
`.ind`'s `\hyperxindexformat{\quartoindexprincipal}{2}` typesets as
`\textbf{<hyperlinked 2>}`: emphasis around a live link, which the
milestone's own AC1/AC2 evidence and my probes both show. Three marginal
notes, none a defect: (i) hyperref's rewriter special-cases a *single-token*
encap (appending `hyperpage` to it) — `quartoindexprincipal` is safely
multi-character, but the rule is worth remembering if a one-letter command is
ever contemplated; (ii) `\providecommand*` (short form) is right for a
locator argument; (iii) makeindex hands a merged page list or a range to one
encap call (`\quartoindexprincipal{\hyperpage{1, 2}}` is possible when two
*emphasized* pages adjoin) — `\hyperpage` parses lists and ranges itself, and
`\textbf` around the lot is acceptable, so this composes; the same fact is
what the deferred mechanism has to split per page.

## Beyond the brief

- **`latex.lua`'s "Contested keys" comment (lines ~88–91) is now inaccurate
  in a load-bearing way.** It says makeindex rejects rival encapsulations
  "and Quarto turns that rejection into a failed render" — but makeindex does
  not reject (exit 0, correct `.ind`); *Quarto alone* escalates, on a
  transcript regex. The `mark_encap` comment block (~199) repeats the older
  reading ("warning only where the two share a page" — true, but the comment
  treats the warning as benign). Whichever disposition is taken, these
  comments should state the true mechanism, since the next design decision
  in this file will otherwise inherit the plan gate's spent premise.
- **The escalation predicate is a Quarto implementation detail.** The regex
  `/^\s\s\s--\s/` is not documented API; a future Quarto could stop or start
  failing on other `.ilg` shapes. The suite's existing practice of reading
  the `.ilg` warning count directly (AC1) is the stable oracle; keep relying
  on it rather than on Quarto's exit code alone.
- **`examples/principal.qmd` cannot keep its terms apart forever.** Its
  three `basilisk` marks sit on three pages only because explicit
  `{{< pagebreak >}}`s hold them there; any future edit that shortens the
  fixture re-creates the same-page pair inside the project's own suite. Under
  disposition (1) this becomes moot — add a deliberately same-page pair to
  the fixture instead, as the regression IP2 demands.
- **If (1) is built:** the registration id must be assigned in document
  order by the pass that already collects keys, and the book (PDF) path needs
  no store change — a PDF book is one merged document, the condition the
  sidecar store exists to work around.

## Recommendations

1. **Apply** — adopt disposition (1): implement the deferred-styling
   subsystem (per-key `qiloc{<ordinal>}` encapsulation on locator marks of
   principal-carrying keys, `\protected@write\@auxout` registration at the
   principal mark, registry-checked emphasis at `\printindex`), hardening the
   dispatch to token-class sniffing rather than the `\HyOrg@hyperpage` name,
   and add same-page, footnote, range-fold and redefinition regressions to
   the suite (IP2's forever clause).
2. **Apply** — whatever the disposition, correct the two comment blocks in
   `latex.lua` (and the plan-gate premise wherever ROADMAP repeats it) to
   state that makeindex warns at exit 0 and Quarto's `.ilg` regex is what
   fails the render.
3. **Apply** — record in the milestone that AC1's evidence base (the
   `.ilg` warning count read as a number) is the stable oracle for this
   class, independent of Quarto's escalation behavior.
4. **Consider** — under (1), document in README the one silent degradation:
   a principal page folded inside a makeindex page range prints unemphasized;
   revisit whole-range emphasis when M21 takes up ranges.
5. **Consider** — if (1) is refused on cost or risk grounds, take (a) —
   LaTeX degrades gracefully to a plain locator with a report, HTML keeps the
   feature — and record the refusal and its reason as a D-entry, since Q1's
   impossibility result is permanent and will be re-derived otherwise.
6. **Reject** — any variant of disposition (b) (ship the colliding emission,
   document it): D-003 classifies the pair as the extension's own incorrect
   output, so IP2 governs and documentation cannot discharge it.
7. **Reject** — warning-suppression or engine-swap recoveries for the current
   emission (`latex-makeindex-opts` transcript redirection,
   `pdf-engine: latexmk`, `latex-makeindex: texindy`/`upmendex`): all are
   blanket, all mask the M15 collision class, none is settable by the
   extension itself, and xindy/upmendex are absent from the TinyTeX Quarto
   installs by default.
