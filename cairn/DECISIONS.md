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
