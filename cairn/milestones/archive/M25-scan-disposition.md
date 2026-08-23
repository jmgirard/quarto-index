# M25: A check that cannot hold its promise is retired, not widened

**Status:** done (2026-08-23, PR #25 https://github.com/jmgirard/quarto-index/pull/25)

**Goal:** The suite's zero-warning controls tell this extension's warnings from any other filter's,
and the source-shape scans are cut back to the properties they actually assert.

**Outcome:** `tests/scans/warn-distinct.py --patterns` emits one extended regular expression per
`warn()` message — 48, placeholders widened (`%d` to digits, others to a wildcard), each anchored to
the `(W) ` prefix — generated only after the scan's own assertions pass; `check_extension_warning_count`
reads that set, and nine bare-`(W)` sites were converted to it. The scan also refuses a message
splicing a value between its literals. Twelve source-reading scans require exactly one match where four
took the first, `latex-escape-table` took its table at the first `split`, and `m15-joined-messages`
asked only for presence. The twelve-scan file-count pin is gone; the M16-AC3 probe counts what it ran
over a non-empty floor and plants a duplicate definition proving the exactly-one clause discriminates.
`filtersrc.defining_lines()` deleted, no caller; each scan's header states what it reads and does not.

**Decisions:** The count pin deleted rather than narrowed; six scans narrowed rather than deleted, each
pinning a filter constant the suite also spells out; `xref-both-definition` kept because no render
distinguishes its property; the consumerless export was `defining_lines()`, not `lines()`.

**Review:** Three-lens fan-out, fifteen findings, eleven fixed on the branch — the missing
duplicate-plant proof for the headline clause, a zero-scan floor, a splice guard and prefix anchor, a
formatted-message probe, and five prose or record corrections the diff falsified, `DESIGN.md`'s
first-match rationale among them. Two to the suite-hardening row, two rejected. Returns 0; three full runs, all green at 397 checks.
