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
