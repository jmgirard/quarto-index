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

### D-003 (2026-08-19): Output the index tool cannot consume is the extension's, not the toolchain's

**Context:** M15 fixes a term marked both plainly and with a cross-reference, which makes the LaTeX back-end emit two rival encapsulations for one index key; makeindex rejects the pair and Quarto turns that into a failed render. GP2 says the contract ends at correct emitted output and that a toolchain's failure modes are documented, never detected or managed, which reads against fixing it at all.
**Decision:** A pair of commands the documented index tool provably cannot process is incorrect emitted output, not a toolchain failure, so repairing it sits inside GP2 rather than trading against it. The reading is deliberately narrow: it licenses changing what the extension emits when the extension's own output is unusable, never detecting or working around a failure the emission did not cause — a missing font, a distribution quirk, a user's own preamble.
**Consequences:** M15 proceeds without amending GP2. A later proposal to detect or manage a toolchain failure the extension did not cause is still governed by GP2 as written and needs its own justification. GP2's "known failure modes documented" continues to govern what the README says about failures this extension cannot prevent.


### D-004 (2026-08-20): Byte-level output-neutrality evidence is rejected as the refactor oracle

**Context:** `tests/byte-diff.sh` rendered every merge-base fixture twice and diffed the `.tex` byte for byte. Planning M17 (splitting the 2,729-line filter) asked whether to widen it to HTML and to the three book projects, which the 29-of-38 non-recursive fixture list, the non-hermetic base checkout, and the one-file clean-tree guard all left uncovered.
**Decision:** Widening was refused as the checker-regress shape, and the script is deleted rather than simplified: its own header disclaims it as a check, it duplicates coverage the ~100-check acceptance suite has, and a byte-diff fails on invisible whitespace changes — the shape tracking-rules names as a defect in the test ("a test that breaks under a behavior-preserving refactor"). The acceptance suite is the sole oracle for output neutrality.
**Consequences:** M17 verifies the split through the suite's pass/fail set plus an install-parity probe, with no merge-base output comparison; a rendered-output change no check probes would pass. That residual risk is recorded on the acceptance-suite hardening candidate row. Restoring byte-level evidence takes a superseding entry.

### D-005 (2026-08-20): Where a back-end folds levels, it judges cross-reference targets against what it prints

**Context:** M14 made the "target names nothing this document indexes" report format-neutral, resolving targets against the level paths the author wrote, on the grounds that whether a target names an indexed term is a fact about the document rather than about a back-end (IP1). M18 finds the LaTeX three-level fold breaks that in both directions: a target naming the folded path draws that report *and* the fold's own self-reference report, which contradict each other, and a target naming a written path the fold rewrites resolves silently while the printed index contains no such path. D-003 is the governing frame — a cross-reference the documented index tool prints and no reader can follow is incorrect emitted output, not a toolchain failure.
**Decision:** A back-end that folds levels folds cross-reference targets by the same rule and resolves them against the paths its entries print. The format-neutral report stands unchanged for every format that imposes no ceiling, and the format-neutral self-target comparison is untouched — M10's gate choice against moving that comparison into the back-ends still holds. Only the resolution set becomes back-end-relative, and only where a ceiling exists.
**Consequences:** In LaTeX the report no longer fires for the fold-induced shapes in `examples/self-xref.qmd`, superseding the last sentence of M14's AC4 for that back-end alone; HTML and back-end-less formats keep the counts M14 pinned, and the counts themselves live in M18's criteria. A future back-end with a ceiling inherits the rule; one without inherits nothing. D-002's placement rule is unchanged: the ceiling stays in the back-end that imposes it, and the empty-level drop stays shared. Restoring a single format-neutral resolution set takes a superseding entry.

### D-006 (2026-08-21): A reported level count names the levels it is over

**Context:** A value in `entry=`, `sort=` or a cross-reference target has three level counts — what the author wrote, what survives the empty-level drop (D-002), and what the LaTeX three-level fold prints. Three warnings name one of these and say which either not at all or misleadingly: the folded-target report names the post-drop count of a target the author wrote deeper (M18 review F9), and the extra-sort report attaches "before empty levels are dropped" to two counts no drop touches (M13 review F4). M13 shipped this subject once already and left both open.
**Decision:** A warning reporting a count of index levels names which levels the count is over, and gives the count the author wrote alongside it wherever the two differ. This governs what a number is called, never what it is: D-002's rule that depth is counted after the drop is unchanged, and so is every number these reports compute.
**Consequences:** The written count is carried to the two fold reports, which do not hold it today, so what `target_levels` and `drop_empty_levels` already compute travels to the LaTeX back-end. On a mark that both loses an empty level and crosses the ceiling, the empty-level report and the entry-fold report name the same pair of counts on consecutive lines; suppressing one would need the two reports to know about each other, and was refused. The rule binds the three reports M19 names and any later report that comes to name a level count. It was deliberately not mechanized as a sweep, because the message-distinctness scan cuts each message expression at `:format(` and so never reads its numbers — a gap recorded on the acceptance-suite hardening candidate row. A report whose count has no drop to distinguish is outside the rule.

### D-007 (2026-08-21): Per-locator styling leaves makeindex's encapsulation channel

**Context:** M20 gives one occurrence of a term an emphasized locator. Realized as a makeindex encapsulation, that breaks the render: makeindex's conflict predicate is same key, same page, any byte difference in the encapsulation string — bare-versus-encapsulated included — and a Pandoc filter cannot know page numbers. Distinguishing the principal mark through the key, the printed field or the sort field files it as a different entry instead, which corrupts the index rather than styling it. makeindex itself warns at exit 0 and writes a correct `.ind`; Quarto alone fails the render, on a regex over the `.ilg` transcript. RB01/RR01 (`cairn/reviews/archive/`) verified each leg.
**Decision:** Per-locator styling is not expressible through what `\index` commands say, and this back-end realizes it on a second, typeset-time channel instead: every locator mark of a key carrying a role emits one uniform per-key encapsulation, so a conflict is unreachable by construction rather than merely unexercised, and the role is registered from the mark's own position into the `.aux` and applied when the index is typeset. Warning-suppression and engine-swap recoveries are refused — each is blanket, masks the collision class D-003 covers, and is user metadata a filter cannot set anyway.
**Consequences:** M20 builds the subsystem; M21's page ranges inherit both the channel and its one known gap, a registered page folded inside a range printing unemphasized. The impossibility is permanent, so a later proposal to style a locator through the encapsulation channel is answered here rather than re-derived. Refusing the subsystem on cost leaves exactly one fallback — the LaTeX back-end reports the role as unrealized (IP1) — and taking it needs a superseding entry.

### D-008 (2026-08-22): An author-written range registers its own printed page string (annotates D-007)

**Context:** D-007 puts per-locator styling on a typeset-time channel: the principal mark writes its ordinal and `\thepage` to the `.aux`, and `\printindex` looks each printed page up in that registry. A page range prints as one string — `3--7` — which matches no per-page registration, so D-007 recorded a principal page inside a range printing unemphasized as the channel's one known gap and left it to M21.
**Decision:** That gap divides in two, and M21 closes only the half the filter can see. A range the AUTHOR wrote is known to the filter, so its opening and closing marks each register their own page, and the pair is composed into the printed range string and registered against the key's ordinal exactly as a single page is; the opening page is registered alone as well, since makeindex prints a same-page pair as one page rather than as a range. A range makeindex FOLDS out of consecutive pages is not known to the filter at all — no mark says a range exists there — and stays unemphasized.
**Consequences:** D-007's channel is extended, not superseded: the uniform per-key encapsulation, the ordinal and the registry are unchanged, and one further `.aux`-borne command joins the four. The prose recording the gap — README's principal-locator section and `core.lua`'s subsystem comment — narrows to the folded case, which is a correction of current knowledge rather than an addition. The ROADMAP candidate row asking whether a folded range is emphasized whole stands, now naming the only remaining half.
