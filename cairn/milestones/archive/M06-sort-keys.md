# M06: Sort keys

**Status:** done (2026-08-18, PR #6 https://github.com/jmgirard/quarto-index/pull/6)

**Goal:** An index term can carry a sort key separate from its printed text, via
a format-neutral `sort=` attribute honored by both back-ends and a book index.

**Outcome:** `sort=` parsed with `entry=`'s level syntax, aligned positionally,
each level falling back to its printed text. A key registers against a printed
LEVEL path (`level_path`, `register_sort`, `sort_for`), not a whole entry, so it
applies wherever that level appears; a third pass `CollectSort` resolves keys
before the first mark is emitted. LaTeX writes makeindex `sortkey@printed`, that
`@` the only unquoted one; HTML collates on the key in `number_entries`, node
identity still printed text; the book sidecar holds a per-chapter map of
DECLARED keys (`STORE_VERSION` 3, `book_sort_keys`), so no chapter's fallback
outranks another's. Four reports, each once per rival key. A document with no
sort key emits byte-identical LaTeX. Suite 89 -> 118 checks.

**Decisions:** four, milestone-local — the report texts; the collect pass; the
conflict once per rival key; a self-equal key as filler only before the last.

**Review:** three passes, three-lens each. Two defect returns (keys kept per
entry not per level; a documented workaround discarding a real key). Pass 3
raised eleven findings: one fixed mid-pass, nine at the gate, one confirmed
open. Two ROADMAP follow-ups; three lessons captured, none retired.
