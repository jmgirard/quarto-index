# Lessons

<!-- Durable, capped repo lessons (max 50 lines) — captured at milestone end,
     surfaced at plan time. Current knowledge: corrected in place when proven
     false (marked, e.g. "corrected M75"), retired when a test enforces it,
     another file owns it, or a stabilized family graduates. One lesson per
     line. Not for status, decisions, or per-milestone task notes. -->

- 2026-08-16 (M01): Reviewing an escape table character by character cannot establish that a character survives — the failure depends on how the consumer *reads* the argument. Only compiling each one settles survival; only typesetting the result settles that it prints.
- 2026-08-16 (M01): Pandoc consumes one backslash level in a quoted span-attribute value (`\!`→`!`, `\\`→`\`, `\"`→`"`), so an escape defined at the filter layer is not what the author types.
- 2026-08-16 (M01): Inside `\index{}` LaTeX reads under `\@sanitize` (`\` becomes catcode 12, so `\{` escapes nothing), and hyperref rewrites the argument at its first `|` before makeindex runs. Neither is discoverable from the character alone.
- 2026-08-16 (M01): A green suite is evidence about what it covers, not about the code. Three review passes each found defects the passing suite did not reach; probe the interaction that actually broke, not a simpler cousin of it.
- 2026-08-16 (M01): Prove a regression test discriminating by reverting the fix and watching it fail — a grep that matches any instance of a warning fences nothing.
- 2026-08-16 (M02): Quarto turns a makeindex *warning* into a failed render, not just a rejection — "Conflicting entries: multiple encaps" fails the build. Two marks on one index key whose encapsulations differ (a locator against a cross-reference, or see against see-also) clash whenever they land on one page; identical encapsulations are folded together and are safe.
- 2026-08-16 (M02): makeindex parses `!` and `@` inside the encap argument too, so a cross-reference target needs the same quoting an entry key does — braces do not shield it. An unquoted `!` there is rejected outright, which under Quarto means a failed build rather than a lost entry.
- 2026-08-16 (M02): A probe that uses the same value in two slots cannot tell one slot from two. Vary the values across slots, and assert the count of slots, or the check passes on output that dropped one of them.
- 2026-08-17 (M03): An anchor id must never sit inside content a renderer copies elsewhere — Quarto copies heading inlines into the sidebar TOC, duplicating any id inside. Emit anchors on empty elements adjacent to the copied content; borrowing a container's id makes every new shape (author id, second mark, missing id) another special case.
- 2026-08-17 (M03): `<span id=…>` written inline in markdown is nativized by Pandoc into an AST Span, id visible to filters. A fixture probing genuinely raw HTML must use a `{=html}` block, or it exercises nothing.

