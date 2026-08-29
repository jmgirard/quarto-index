# RR02: The language of the words the index back-end picks itself

- **Date:** 2026-08-28
- **Brief:** `cairn/reviews/RB02-index-label-language.md`
- **Reviewer basis:** all Materials read; both probe facts re-run on this
  machine (pandoc 3.10.2) and confirmed; two further probes run, reported
  under Q6 and Beyond the brief.

## Probe confirmations

1. `pandoc --print-default-data-file=translations/fr.yaml` returns a map
   carrying `Index: Index`, `See: Voir`, `SeeAlso: Voir aussi`. Coverage is
   uneven as stated: `ko.yaml` carries `Index: 찾아보기` and neither `See` nor
   `SeeAlso`; `ja.yaml` carries `See: 参照` and `SeaAlso`-key `SeeAlso: 参照` —
   the *same word for both kinds*, where Japanese index convention
   distinguishes 「を見よ」/「も見よ」. No file carries anything for `Symbols`.
2. `pandoc.translations` is nil in 3.10.2, and enumerating `pairs(pandoc)`
   inside a running filter lists exactly the modules the brief names — no
   translations entry. The table is unreachable from Lua at runtime.

The ja fact is new evidence and load-bearing below: pandoc's own data is not
authoritative enough to copy blind even if it were reachable and licensable.

## Answers

### Q1 — Which approach

**Ship (b): read the document's `lang:` against a small table the extension
carries, with an author override.** Reasoning:

- **GP4 is the deciding principle, and it cuts for (b).** Under (a), the
  common case for every non-English author — an index whose labels match the
  document's language — *requires* configuration, three fields per document.
  Worse, a document rendered to both PDF and HTML comes out bilingual: the
  PDF says *Voir* (babel, for free, today) and the HTML says *see*. That is
  not a preference an author chose; it reads as a defect, and (a) and (c)
  both make it permanent. GP4 says the common case works with no
  configuration; for a `lang: fr` document, matching labels *are* the common
  case.
- **The asymmetry argument is real.** The LaTeX back-end already follows the
  document's declared language and cost the author nothing. The extension's
  own comment in `core.lua` (lines 20–23) already frames `label` as "the
  words a reader sees" with LaTeX diverging through `\seename`/`\alsoname` —
  the design has been pointing at per-language labels since that table was
  written. (b) is the only option under which one declared fact (`lang:`)
  drives both back-ends.
- **(c) rejected.** KI26 is a reader-facing defect, and it grows with HTML
  adoption; documenting it fixes no bilingual render. It also forfeits the
  author override, so even a motivated author cannot repair their own index.
- **(a) rejected as the shipped option, but its surface survives inside (b):**
  the override fields (a) would add are exactly (b)'s escape hatch, so
  choosing (b) is choosing (a)-plus-a-default, not a different syntax.

**Strongest argument against (b), stated honestly:** the table is data the
maintainer cannot verify by reading it. A wrong translation ships silently to
readers in a language the maintainer does not speak — worse than English,
because English at least announces itself as a fallback — and coverage will
always be partial, so a `lang: ko` document gets a localized heading and
English cross-reference labels. Every additional language is now a
maintenance obligation the extension owns forever. This is a real cost; it is
bounded (three short strings per language, each checkable against several
public references), and the override plus English fallback keep every
uncovered case exactly where (a) and (c) would have left it, which is why the
cost is worth paying.

### Q2 — Where the table's content comes from

**Both sources the question poses fail; a third succeeds, so Q1 is not
settled against (b).**

- **Vendoring pandoc's `translations/*.yaml`: not acceptable.** A mechanical
  copy of files from a GPL-2-or-later project into an MIT repo is a license
  conflict in the repo's own stated terms, whatever one thinks of the
  copyrightability of individual two-word entries. An MIT `LICENSE` at the
  root that does not cover a directory of copied GPL data is exactly the
  ambiguity a community-grade project (GP1) should not carry. And the ja
  probe shows the data is not worth the trouble: it would ship "参照" for
  both labels.
- **Shelling out through `pandoc.pipe` per render: not acceptable.** It fails
  GP3 in substance, not just letter: the filter would depend on a `pandoc`
  binary being findable on PATH, and under Quarto the running pandoc is
  Quarto's bundled one in its own tools directory, not necessarily on PATH at
  all — so the behavior varies by machine, which is worse than a uniform
  English fallback. It also puts a subprocess failure on the render path
  (IP2 pressure; a pcall guard makes it non-fatal but machine-varying), adds
  a per-render cost, and ties output to whatever pandoc version answers,
  so two machines render one document with different words.
- **The third source: author the table independently.** The strings are
  single common words and short phrases — translations of "see" / "see also"
  are standard index conventions, documented in multiple independent public
  references (babel's caption strings, style manuals, published indexes),
  and can be written down and cross-checked without copying any file.
  Fifteen to twenty-five languages times three strings is a small, auditable
  data asset with a comment naming how each row was checked. A language
  where references disagree or none was checkable is *left out* and falls
  back to English — honest, and strictly no worse than today.

### Q3 — Is `Symbols` different in kind?

**Yes in origin, no in consequence — and consequence should win the surface
design.** The distinction the question draws is real: `Symbols` names a
grouping mechanism this extension invented (DESIGN's Conventions state the
ASCII-only letter-group rule as the extension's own collation policy), and no
upstream source translates it because no upstream has the mechanism. But the
reader does not see a mechanism name; they see a heading in their index, and
an English "Symbols" over a French index is exactly the mixed-language page
this work exists to remove — made *worse* under (b), where *Voir* would sit
beside "Symbols" on one page.

So: treat the three alike on the author surface (one `labels:` map, Q4), and
treat `Symbols` honestly in the data — include it in the shipped table only
where a confident translation exists ("Symboles", "Symbole", "Símbolos" are
as checkable as "voir"), and fall back to English "Symbols" for a language
whose other labels are covered but whose symbols word is not, rather than
dropping the language. The one genuinely different property worth documenting:
`Symbols` has no LaTeX counterpart at all — makeindex does not group — so
this label is HTML/EPUB-only by construction and no back-end asymmetry can
arise from it.

### Q4 — Field names and shape

**Recommend the nested map, disagreeing with the candidate flat spelling:**

```yaml
indexes:
  - name: subjects
    title: Index des sujets
    labels:
      symbols: Symboles
      see: voir
      see-also: voir aussi
```

Grounds:

- **The flat `see:` is a collision in the author's head.** Beside `title:`,
  a flat `see: voir` sits one indentation level from marks where `see=`
  means a *target*. One spelling, two kinds of value (a label word versus an
  entry path), in one extension's documentation — the confusion is cheap to
  avoid and permanent under IP3 if shipped. Inside `labels:`, the keys can
  still match the mark attribute names (`see`, `see-also`), keeping the
  brief's matching argument, while the map name states what kind of thing
  the values are.
- **Room for a fourth string.** Strictly, both shapes extend compatibly — a
  new flat field and a new `labels:` key are each additive, and neither
  needs a deprecation cycle. The real difference is what the *flat namespace*
  is being saved for: future per-index settings that are not reader-facing
  words (placement, columns, whatever comes) will want top-level fields, and
  a declaration whose top level mixes behavioral settings with label words
  ages worse than one where every reader-facing word is under `labels:`.
  The fourth string this extension can already see coming — locale
  punctuation, e.g. the separator comma an Arabic index would set as ⟨،⟩ —
  slots into `labels:` without claiming a top-level name.
- **Flagged disagreement with the plan gate's placement, per the brief's
  invitation:** per-index-only override has a gap. A document that declares
  no `indexes:` — the overwhelmingly common document — has nowhere to write
  an override without adopting a declaration, and adopting one is not free:
  it requires inventing a `name:`, and it changes the section id from
  `qi-index` to `qi-index-<name>` (per `section_id` in `indexes.lua`),
  breaking existing inbound links. Under (b) the override is rare (the
  `lang:` default covers the common case), which shrinks the gap but does
  not close it — the author most likely to need the override is precisely
  the one whose language the table lacks, writing a plain undeclared
  document. Recommend accepting the same `labels:` map at the document's
  top level as the default every index inherits, with a per-index `labels:`
  overriding it. That is one mechanism with nearest-wins scoping, not a
  parallel syntax, so GP5 is satisfied; it is the same relationship `lang:`
  itself (document-level) already has to the per-index override.

### Q5 — The section heading

**Yes: for an index with no `title:`, the heading should follow `lang:` under
the same table, superseding the hard-coded English default.** Consistency is
not the only argument — symmetry with the shipped LaTeX behavior is stronger:
an undeclared document's PDF index is headed by `\indexname` today
(`index.lua:424` emits `\makeindex[intoc]` with no `title=`, so imakeidx
heads it with babel's word), so the heading *already* follows the document's
language in one back-end, exactly like `see`. Leaving the HTML heading
English while localizing `see` would reproduce in miniature the asymmetry
this work removes. `title:` remains the author's absolute override,
unchanged.

**On IP3:** this is a change to a released *default output*, not to a
documented *syntax form*. IP3's text governs syntax forms; no syntax changes
here — every document that renders today renders identically unless it
declares a non-English `lang:`, and such a document's PDF already localizes,
so the change moves HTML toward the output the same source already produces
elsewhere. I read that as outside the deprecation cycle's jurisdiction but
squarely inside changelog duty: record it as a behavior change, and note
that for `fr` and `de` the word is "Index" either way, so the visible change
is confined to languages like es/it/pl/ja/ko. If the maintainer reads IP3
more broadly than I do, the conservative fallback is to gate the heading (not
the labels) behind one release of notice — but I would not ship the labels
localized and the heading not; that halfway state is the worst of the three.

### Q6 — Any shape of genuine agreement?

**No, and it is worth saying plainly.** Every candidate shared source fails:

- Babel's strings live in `.ldf` files inside a TeX distribution. An HTML
  render needs no TeX at all (GP2/GP3), so "derive what babel would print"
  means requiring TeX for HTML or parsing TeX sources the machine may not
  have. Not feasible.
- Pandoc's translation table is unreachable from Lua (probe fact 2), and
  its two reachable forms — vendoring, shelling out — are rejected under Q2.
- Quarto's own language machinery is a dead end twice over, by probe on this
  machine (Quarto's bundled `share/language/_language.yml`): its 111 keys
  include nothing for see/see-also/index, and the `param()` accessor
  Quarto's internal filters read it through is nil inside an extension
  filter. There is nothing to reach and no way to reach it.

The achievable alignment is agreement on the *input*: both back-ends follow
the one declared fact `lang:`, each realized through its own channel — babel
for LaTeX, the shipped table for HTML/EPUB. The documentation should state
the three residual divergences as facts, not apologies: (1) the exact words
can differ where babel's table and this extension's disagree, and nothing
enforces their equality; (2) the author override reaches HTML/EPUB only —
LaTeX has one global `\seename`, per-index redefinition is impossible, and
redefining it from the filter would fight babel's own language switching;
(3) coverage differs — babel covers languages this table will not, and vice
versa. "The two back-ends will always be configured separately at the string
level; `lang:` is the one knob they share" is the sentence the docs need.

## Beyond the brief

- **B1.** KI26's enumeration is incomplete: it names `Index` and the
  `Symbols` group label but not `see`/`see also`, which are equally
  hard-coded English (`core.lua:24–27`, consumed at `html.lua:296`). Per
  D-013 this is stated as a finding about the record, nothing more.
- **B2.** The locator separators (`,` and `;`, `html.lua:263–311`) and the
  digit locator labels are also filter-chosen reader-facing output. Digits
  are language-neutral; the punctuation is a locale convention (Arabic sets
  ⟨،⟩). Not worth acting on now, but it is the concrete "fourth string" that
  makes `labels:`'s extensibility argument non-hypothetical.
- **B3.** Any localization work must touch `site/cross-references.qmd` and
  `site/letter-groups.qmd`, whose examples teach the literal words (`→ cats,
  see Felines`; the `Symbols` bullets), and the acceptance suite pins
  documentation sentences page by page — the doc cost of this change is
  real and should be in the milestone's scope, not discovered during it.
- **B4.** `lang:` values are BCP-47 tags (`fr-CA`); the lookup should try
  the exact tag, then the primary subtag, then English. Trivial, but worth
  stating in the plan so `fr-CA` does not silently miss `fr`.
- **B5.** Reading `lang:` must never break a render (IP2): a malformed
  `lang:` value simply misses the table and falls back to English, with no
  warning — an author who wrote `lang:` for Quarto/babel did not address
  this extension, so silence is correct where a miss occurs.

## Recommendations

1. **Apply.** Take option (b): resolve `symbols`, `see`, `see also`, and the
   untitled-index heading through `lang:` (exact tag, then primary subtag)
   against a table the extension ships, falling back to English; author
   override wins over the table, `title:` continues to win for the heading.
2. **Apply.** Author the table independently — no file copied from pandoc or
   any GPL source, each row cross-checked against public references and the
   check noted in a comment; a language that cannot be confidently covered
   is omitted and falls back to English.
3. **Reject the two posed table sources, with reason.** Vendoring pandoc's
   YAML: GPL-2+ data inside an MIT repo, and the ja probe shows the data is
   not authoritative anyway. Shelling out via `pandoc.pipe`: machine-varying
   behavior against GP3's self-containment and an added render-path failure
   mode against IP2.
4. **Apply.** Spell the override as a nested `labels:` map with keys
   `symbols`, `see`, `see-also` — not three flat fields — for the collision
   and namespace reasons under Q4. This disagrees with the candidate flat
   spelling, as the brief permits.
5. **Consider.** Accept the same `labels:` map at document level as the
   inherited default, per-index `labels:` overriding, so an undeclared
   document can override without inventing an index name and changing its
   section id. The plan gate's per-index placement is marked not fixed;
   this is the disagreement, argued under Q4.
6. **Apply.** Localize the untitled heading together with the labels, record
   the default-output change in the changelog, and do not route it through a
   deprecation cycle — IP3 governs syntax forms and none changes (Q5 states
   the conservative fallback if the maintainer reads IP3 more broadly).
7. **Apply.** Include `Symbols` in the shipped table on the same terms as
   the other two, with English fallback per language where unconfident; note
   in the docs that this label is HTML/EPUB-only by construction.
8. **Apply.** Document the residual back-end divergence in the words Q6
   ends with: the back-ends share `lang:` and nothing else; the override
   reaches HTML/EPUB only; exact words may differ from babel's.
9. **Consider.** Amend KI26's wording to enumerate `see`/`see also` alongside
   `Index` and `Symbols` (B1), in whatever edit next touches that entry.
