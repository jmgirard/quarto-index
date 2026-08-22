# M20: A term's principal discussion prints as its principal locator

**Status:** done (2026-08-22, PR #20 https://github.com/jmgirard/quarto-index/pull/20)

**Goal:** An author marks one occurrence of a term as its principal discussion, and both
back-ends print that occurrence's locator emphasized while its others stay plain.

**Outcome:** A format-neutral `mention="principal"`, named for the occurrence not the rendering
(IP1), spelled `mention` because Pandoc emits `role` literally as an ARIA role. HTML marks the
locator link with `qi-principal` and a `Strong`; `book.lua` carries the role through the
sidecar store. LaTeX cannot express it through makeindex's encapsulation channel at all, so it
rides a typeset-time channel (D-007, mechanism in the archived RR01): a uniform per-key
`\quartoindexlocator{<ordinal>}` makes the same-key-same-page conflict unreachable by
construction, `\quartoindexregister` writes the ordinal and `\thepage` to the `.aux`, and an
injected preamble applies the author-redefinable `\quartoindexprincipal` at `\printindex` —
four commands, injected only where used. Contestation counts cross-reference encapsulations
alone; a principal page inside a folded page range prints plain, documented and left to M21.

**Decisions:** `mention=` not `role=`; an empty value is unrecognized, not absent; the `.ilg`
warning count is the stable oracle, not Quarto's exit code. Cross-cutting: D-007.

**Review:** Three rounds, two defect returns — the same-page render break, then a page list
reaching the splitter unbraced so only a first single-character page printed emphasized. Round
3 actioned six, the sharpest being the replacement oracle going self-referential on the `.aux`.
Retired: M05's range-fold lesson, now enforced by four checks that fail without it.
