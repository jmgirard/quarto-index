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
- 2026-08-17 (M04): imakeidx's `\printindex` closes the `.idx` file it has just read, so an index printed mid-document silently drops every later `\index` — the entries go to the `.log` and the build stays clean. Its `noautomatic` option skips that close.
- 2026-08-17 (M04): Quarto emits `use_latex_package` as `\@ifpackageloaded{pkg}{}{\usepackage[opts]{pkg}}`, so options never reach a document that loads the package itself; and `\PassOptionsToPackage` registers options on an already-loaded package, which defeats an `\@ifpackagewith` check written to detect exactly that case.
- 2026-08-17 (M04): A test runner that pipes its check body to `tee` runs that body in a subshell inheriting `errexit` as it stands at the pipeline — a `set +e` before the pipe (to read PIPESTATUS) makes every exit-status-only check advisory while the run still prints "all passed".
- 2026-08-17 (M05): Quarto renders a book's chapters sequentially in book order, each in its own Pandoc process — `doc.meta.book.render` carries the ordered chapter list and `quarto.project.offset` the page-to-root path, so cross-chapter work needs no guessing about layout, only somewhere to leave data between processes.
- 2026-08-17 (M05): `quarto render --to pdf` on a book replaces the whole output directory, so an HTML artifact and a PDF artifact of one book never coexist — a check must read what it needs before the next format renders.
- 2026-08-17 (M05): makeindex collapses three or more consecutive pages into a range (`3--5`), so a count of printed locator tokens is not a count of pages.
- 2026-08-17 (M05): Quarto normalizes a link target — a percent-escaped href a filter emits reaches output unescaped, matching Quarto's own links — so escaping at the filter layer is a no-op rather than a safety net.
- 2026-08-17 (M05): `pandoc.system.make_directory` raises a Lua error rather than returning a failure, so an unguarded call aborts the whole render; the `io.open` beside it returns nil and err, which is why one of the two was guarded and the other was not.
