# Decisions

<!-- Append-only cross-cutting decisions. Never renumber; supersede with a new
     entry. D-entries record choices with rationale — including genuine
     rejections ("considered X, rejected because…"). They never record
     deferrals: "not now" is a ROADMAP fact (candidate row or future
     milestone), not a decision. Entry format:

### D-00N (YYYY-MM-DD): Title

**Context:** 1–2 lines.
**Decision:** 1–2 lines.
**Consequences:** 1–2 lines. (Supersedes D-0xx, if any.)
-->

### D-001 (2026-08-16): entry= values are structured format-neutral data, not raw LaTeX

**Context:** M01's plan made `entry="..."` a raw LaTeX pass-through (sub-entries written in imakeidx syntax). The design interview adopted IP1: mark values must be meaningful to every future back-end.
**Decision:** Entry values are structured data the extension parses and realizes per format (e.g., sub-entry separation interpreted by the extension itself, remainder escaped); raw back-end code is never accepted in mark values.
**Consequences:** M01's escaping-design scope needs a gated plan amendment before implementation. Future back-ends consume the same entry semantics. Admitting raw LaTeX later would require an explicit recorded reversal of IP1.

### D-002 (2026-08-18): An empty index level is not a level

**Context:** M11 found that a leading empty level in `entry=` (`entry="!Cats"`) made the LaTeX back-end emit a null field, which makeindex rejects — dropping the whole entry while exiting 0 with no warning. Three semantics had to be settled, and D-001 records this same class of choice about what `entry=` values mean.
**Decision:** An empty level prints nothing and is therefore not a level: it is dropped once, format-neutrally, before any back-end sees it. A value that is only empty levels falls back to the mark's visible text, or indexes nothing where there is none. A sort level is dropped together with the entry level it was written for, never re-aligned onto a level it was not written for; the loss is reported.
**Consequences:** `entry="!Cats"` and `entry="Cats!"` both index as `Cats`, in every back-end, and no entry can file under an empty string. Depth is counted after the drop, so a stray `!` cannot push an entry over the LaTeX three-level ceiling. The rule is format-neutral by its own justification — a level that prints nothing is not a level — and so lives in the shared parse layer, unlike the three-level ceiling, which stays in the back-end that imposes it. From the first tagged release this is IP3-bound syntax.
